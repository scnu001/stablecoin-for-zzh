// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {MockUSDC} from "../../src/MockUSDC.sol";
import {MockWETH} from "../../src/exercises/MockWETH.sol";
import {SimpleStablecoin} from "../../src/SimpleStablecoin.sol";
import {OverCollateralizedVault} from "../../src/exercises/OverCollateralizedVault.sol";
import {RestrictedStablecoin} from "../../src/tier3/RestrictedStablecoin.sol";
import {RestrictedVault} from "../../src/tier3/RestrictedVault.sol";
import {PegStabilityModule} from "../../src/tier3/PegStabilityModule.sol";
import {ChainlinkPriceFeed, AggregatorV3Interface} from "../../src/tier3/ChainlinkPriceFeed.sol";

contract Tier3MockAggregator is AggregatorV3Interface {
    uint8 public immutable feedDecimals;
    int256 public answer;
    uint80 public roundId = 1;
    uint80 public answeredInRound = 1;
    uint256 public updatedAt;

    constructor(uint8 decimals_, int256 answer_) {
        feedDecimals = decimals_;
        answer = answer_;
        updatedAt = block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return feedDecimals;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (roundId, answer, updatedAt, updatedAt, answeredInRound);
    }

    function setAnswer(int256 newAnswer) external {
        answer = newAnswer;
        updatedAt = block.timestamp;
    }

    function setRound(uint80 newRoundId, uint80 newAnsweredInRound) external {
        roundId = newRoundId;
        answeredInRound = newAnsweredInRound;
    }

    function setUpdatedAt(uint256 newUpdatedAt) external {
        updatedAt = newUpdatedAt;
    }
}

contract Tier3Test is Test {
    address internal admin = address(this);
    address internal alice = makeAddr("alice");
    address internal attacker = makeAddr("attacker");

    MockUSDC internal usdc;
    RestrictedStablecoin internal stable;
    RestrictedVault internal restrictedVault;
    PegStabilityModule internal psm;

    function setUp() public {
        usdc = new MockUSDC();
        stable = new RestrictedStablecoin(admin);
        restrictedVault = new RestrictedVault(usdc, stable);
        psm = new PegStabilityModule(usdc, stable, 1_000_000e6, admin);

        stable.grantRole(stable.MINTER_ROLE(), address(restrictedVault));
        stable.grantRole(stable.MINTER_ROLE(), address(psm));
    }

    function test_RestrictedBurnRequiresAllowance() public {
        stable.mint(alice, 100e6);

        vm.prank(attacker);
        vm.expectRevert();
        stable.burnFrom(alice, 1e6);

        assertEq(stable.balanceOf(alice), 100e6);
    }

    function test_RestrictedVault_RedeemUsesAllowance() public {
        usdc.faucet(alice, 100e6);

        vm.startPrank(alice);
        usdc.approve(address(restrictedVault), 100e6);
        restrictedVault.deposit(100e6);
        stable.approve(address(restrictedVault), 40e6);
        restrictedVault.redeem(40e6);
        vm.stopPrank();

        assertEq(stable.balanceOf(alice), 60e6);
        assertEq(usdc.balanceOf(alice), 40e6);
        assertEq(usdc.balanceOf(address(restrictedVault)), 60e6);
    }

    function test_PSM_SwapsAtOneToOneAndHonorsCap() public {
        usdc.faucet(alice, 100e6);

        vm.startPrank(alice);
        usdc.approve(address(psm), 100e6);
        assertEq(psm.swapIn(100e6), 100e6);
        stable.approve(address(psm), 35e6);
        assertEq(psm.swapOut(35e6), 35e6);
        vm.stopPrank();

        assertEq(stable.balanceOf(alice), 65e6);
        assertEq(usdc.balanceOf(alice), 35e6);
        assertEq(usdc.balanceOf(address(psm)), 65e6);
    }

    function test_PSM_NormalizesDifferentDecimals() public {
        MockWETH weth = new MockWETH();
        PegStabilityModule wethPsm = new PegStabilityModule(weth, stable, 2e18, admin);
        stable.grantRole(stable.MINTER_ROLE(), address(wethPsm));

        weth.faucet(alice, 1e18);
        vm.startPrank(alice);
        weth.approve(address(wethPsm), 1e18);
        assertEq(wethPsm.swapIn(1e18), 1e6);
        stable.approve(address(wethPsm), 1e6);
        assertEq(wethPsm.swapOut(1e6), 1e18);
        vm.stopPrank();

        assertEq(weth.balanceOf(alice), 1e18);
        assertEq(stable.balanceOf(alice), 0);
    }

    function test_PSM_RejectsReserveCap() public {
        usdc.faucet(alice, 1_000_001e6);

        vm.startPrank(alice);
        usdc.approve(address(psm), type(uint256).max);
        psm.swapIn(1_000_000e6);
        vm.expectRevert(PegStabilityModule.ReserveCapExceeded.selector);
        psm.swapIn(1);
        vm.stopPrank();
    }

    function test_PSM_RejectsZeroInsufficientReserveAndRoundingToZero() public {
        vm.expectRevert(PegStabilityModule.ZeroAmount.selector);
        psm.swapIn(0);

        vm.expectRevert(PegStabilityModule.ZeroAmount.selector);
        psm.swapOut(0);

        stable.mint(alice, 101e6);
        vm.startPrank(alice);
        stable.approve(address(psm), 101e6);
        vm.expectRevert(PegStabilityModule.InsufficientReserve.selector);
        psm.swapOut(101e6);
        vm.stopPrank();

        MockWETH weth = new MockWETH();
        PegStabilityModule wethPsm = new PegStabilityModule(weth, stable, 2e18, admin);
        stable.grantRole(stable.MINTER_ROLE(), address(wethPsm));
        weth.faucet(alice, 1);

        vm.startPrank(alice);
        weth.approve(address(wethPsm), 1);
        vm.expectRevert(PegStabilityModule.RoundingToZero.selector);
        wethPsm.swapIn(1);
        vm.stopPrank();
    }

    function test_ChainlinkAdapterReadsDecimalsAndRejectsNegativePrice() public {
        Tier3MockAggregator aggregator = new Tier3MockAggregator(18, 2_000e18);
        ChainlinkPriceFeed adapter = new ChainlinkPriceFeed(aggregator, 1 hours);

        assertEq(adapter.decimals(), 18);
        (, int256 answer,,,) = adapter.latestRoundData();
        assertEq(answer, 2_000e18);

        aggregator.setAnswer(-1);
        vm.expectRevert(ChainlinkPriceFeed.InvalidPrice.selector);
        adapter.latestRoundData();

        aggregator.setAnswer(0);
        vm.expectRevert(ChainlinkPriceFeed.InvalidPrice.selector);
        adapter.latestRoundData();

        aggregator.setAnswer(2_000e18);
        aggregator.setUpdatedAt(block.timestamp + 1);
        vm.expectRevert(ChainlinkPriceFeed.StalePrice.selector);
        adapter.latestRoundData();
    }

    function test_ChainlinkAdapterRejectsStaleAndIncompleteRounds() public {
        vm.warp(2 hours);
        Tier3MockAggregator aggregator = new Tier3MockAggregator(8, 2_000e8);
        ChainlinkPriceFeed adapter = new ChainlinkPriceFeed(aggregator, 1 hours);

        aggregator.setUpdatedAt(block.timestamp - 1 hours - 1);
        vm.expectRevert(ChainlinkPriceFeed.StalePrice.selector);
        adapter.latestRoundData();

        aggregator.setUpdatedAt(block.timestamp);
        aggregator.setRound(2, 1);
        vm.expectRevert(ChainlinkPriceFeed.IncompleteRound.selector);
        adapter.latestRoundData();
    }

    function test_OverCollateralizedVaultUsesFeedDecimals() public {
        MockWETH weth = new MockWETH();
        Tier3MockAggregator aggregator = new Tier3MockAggregator(18, 2_000e18);
        ChainlinkPriceFeed adapter = new ChainlinkPriceFeed(aggregator, 1 hours);
        SimpleStablecoin tier1Stable = new SimpleStablecoin(admin);
        OverCollateralizedVault vault = new OverCollateralizedVault(weth, tier1Stable, adapter);

        assertEq(vault.collateralValue(1e18), 2_000e6);
    }

    function test_OverCollateralizedVaultValueAvoidsIntermediateOverflow() public {
        MockWETH weth = new MockWETH();
        Tier3MockAggregator aggregator = new Tier3MockAggregator(36, 1e36);
        ChainlinkPriceFeed adapter = new ChainlinkPriceFeed(aggregator, 1 hours);
        SimpleStablecoin tier1Stable = new SimpleStablecoin(admin);
        OverCollateralizedVault vault = new OverCollateralizedVault(weth, tier1Stable, adapter);

        assertEq(vault.collateralValue(1e42), 1e30);
    }

    function test_OverCollateralizedVaultLiquidationUsesFeedDecimals() public {
        MockWETH weth = new MockWETH();
        Tier3MockAggregator aggregator = new Tier3MockAggregator(18, 2_000e18);
        ChainlinkPriceFeed adapter = new ChainlinkPriceFeed(aggregator, 1 hours);
        SimpleStablecoin tier1Stable = new SimpleStablecoin(admin);
        OverCollateralizedVault vault = new OverCollateralizedVault(weth, tier1Stable, adapter);
        tier1Stable.grantRole(tier1Stable.MINTER_ROLE(), address(vault));

        weth.faucet(alice, 1e18);
        vm.startPrank(alice);
        weth.approve(address(vault), 1e18);
        vault.depositCollateral(1e18);
        vault.mintStable(1000e6);
        tier1Stable.transfer(attacker, 1000e6);
        vm.stopPrank();

        aggregator.setAnswer(1_150e18);
        uint256 expectedSeized = 956521739130434782;
        vm.prank(attacker);
        vault.liquidate(alice);

        assertEq(vault.collateralOf(alice), 1e18 - expectedSeized);
        assertEq(weth.balanceOf(address(vault)), 1e18 - expectedSeized);
        assertEq(weth.balanceOf(attacker), expectedSeized);
        assertEq(tier1Stable.totalSupply(), 0);
    }
}
