// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {RestrictedStablecoin} from "./RestrictedStablecoin.sol";

/// @title Tier 3 vault with allowance-based redemption
/// @notice Redemption requires the user to approve exactly how much rsUSD the
///         vault may burn.
contract RestrictedVault {
    using SafeERC20 for IERC20;

    IERC20 public immutable collateral;
    RestrictedStablecoin public immutable stable;

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientCollateral();

    constructor(IERC20 collateral_, RestrictedStablecoin stable_) {
        if (address(collateral_) == address(0) || address(stable_) == address(0)) {
            revert ZeroAddress();
        }
        collateral = collateral_;
        stable = stable_;
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        collateral.safeTransferFrom(msg.sender, address(this), amount);
        stable.mint(msg.sender, amount);
    }

    function redeem(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (amount > collateral.balanceOf(address(this))) revert InsufficientCollateral();

        stable.burnFrom(msg.sender, amount);
        collateral.safeTransfer(msg.sender, amount);
    }

    function totalCollateral() external view returns (uint256) {
        return collateral.balanceOf(address(this));
    }
}
