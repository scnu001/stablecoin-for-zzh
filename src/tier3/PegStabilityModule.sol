// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {RestrictedStablecoin} from "./RestrictedStablecoin.sol";

/// @title Tier 3 Peg Stability Module
/// @notice Exchanges a reserve token and rsUSD at a fixed 1:1 nominal rate,
///         normalizing the two ERC-20 decimal scales.
contract PegStabilityModule is Ownable {
    using SafeERC20 for IERC20;

    IERC20Metadata public immutable reserve;
    RestrictedStablecoin public immutable stable;
    uint8 public immutable reserveDecimals;
    uint8 public immutable stableDecimals;
    uint256 public maxReserve;

    error ZeroAddress();
    error ZeroAmount();
    error UnsupportedDecimals();
    error ReserveCapExceeded();
    error InsufficientReserve();
    error RoundingToZero();

    event SwappedIn(address indexed user, uint256 reserveAmount, uint256 stableAmount);
    event SwappedOut(address indexed user, uint256 stableAmount, uint256 reserveAmount);
    event MaxReserveUpdated(uint256 maxReserve);

    constructor(IERC20Metadata reserve_, RestrictedStablecoin stable_, uint256 maxReserve_, address owner_)
        Ownable(owner_)
    {
        if (address(reserve_) == address(0) || address(stable_) == address(0) || owner_ == address(0)) {
            revert ZeroAddress();
        }
        reserve = reserve_;
        stable = stable_;
        reserveDecimals = reserve_.decimals();
        stableDecimals = stable_.decimals();
        if (reserveDecimals > 36 || stableDecimals > 36) revert UnsupportedDecimals();
        maxReserve = maxReserve_;
    }

    function swapIn(uint256 reserveAmount) external returns (uint256 stableAmount) {
        if (reserveAmount == 0) revert ZeroAmount();

        uint256 currentReserve = reserve.balanceOf(address(this));
        if (currentReserve > maxReserve || reserveAmount > maxReserve - currentReserve) {
            revert ReserveCapExceeded();
        }

        stableAmount = _toStable(reserveAmount);
        if (stableAmount == 0) revert RoundingToZero();

        IERC20(address(reserve)).safeTransferFrom(msg.sender, address(this), reserveAmount);
        stable.mint(msg.sender, stableAmount);
        emit SwappedIn(msg.sender, reserveAmount, stableAmount);
    }

    function swapOut(uint256 stableAmount) external returns (uint256 reserveAmount) {
        if (stableAmount == 0) revert ZeroAmount();

        reserveAmount = _toReserve(stableAmount);
        if (reserveAmount == 0) revert RoundingToZero();
        if (reserveAmount > reserve.balanceOf(address(this))) revert InsufficientReserve();

        stable.burnFrom(msg.sender, stableAmount);
        IERC20(address(reserve)).safeTransfer(msg.sender, reserveAmount);
        emit SwappedOut(msg.sender, stableAmount, reserveAmount);
    }

    function setMaxReserve(uint256 newMaxReserve) external onlyOwner {
        if (newMaxReserve < reserve.balanceOf(address(this))) revert ReserveCapExceeded();
        maxReserve = newMaxReserve;
        emit MaxReserveUpdated(newMaxReserve);
    }

    function _toStable(uint256 amount) internal view returns (uint256) {
        if (reserveDecimals == stableDecimals) return amount;
        if (reserveDecimals > stableDecimals) {
            return amount / 10 ** (reserveDecimals - stableDecimals);
        }
        return amount * 10 ** (stableDecimals - reserveDecimals);
    }

    function _toReserve(uint256 amount) internal view returns (uint256) {
        if (reserveDecimals == stableDecimals) return amount;
        if (stableDecimals > reserveDecimals) {
            return amount / 10 ** (stableDecimals - reserveDecimals);
        }
        return amount * 10 ** (reserveDecimals - stableDecimals);
    }
}
