// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPriceFeed} from "../exercises/IPriceFeed.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/// @title Chainlink AggregatorV3 adapter
/// @notice Reads feed decimals and rejects negative, stale, or incomplete
///         oracle observations before exposing them to the vault.
contract ChainlinkPriceFeed is IPriceFeed {
    AggregatorV3Interface public immutable feed;
    uint256 public immutable maxAge;

    error ZeroAddress();
    error InvalidPrice();
    error StalePrice();
    error IncompleteRound();

    constructor(AggregatorV3Interface feed_, uint256 maxAge_) {
        if (address(feed_) == address(0)) revert ZeroAddress();
        if (maxAge_ == 0) revert StalePrice();
        feed = feed_;
        maxAge = maxAge_;
    }

    function decimals() external view returns (uint8) {
        return feed.decimals();
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = feed.latestRoundData();
        if (answer <= 0) revert InvalidPrice();
        if (updatedAt == 0 || updatedAt > block.timestamp || block.timestamp - updatedAt > maxAge) {
            revert StalePrice();
        }
        if (answeredInRound < roundId) revert IncompleteRound();
    }
}
