# Tier 3 extensions

Tier 3 is implemented locally and tested; the existing Tier 2 Sepolia
deployment remains the required three-contract deployment from `TIER2-SEPOLIA.md`.

## Ex7 — Unstoppable

`test/challenges/Unstoppable.t.sol:test_unstoppable` sends 1 DVT directly to
the vault. The vault's `totalAssets()` then differs from the share-derived
balance, so the monitor's flash-loan probe fails. The monitor pauses the vault
and transfers ownership back to the deployer.

## Hardened burn

`src/tier3/RestrictedStablecoin.sol` exposes `burn(uint256)` for self-burn and
`burnFrom(address,uint256)` for allowance-authorized burns only. The matching
`RestrictedVault` requires the redeemer to approve the exact burn amount.

## Peg Stability Module

`src/tier3/PegStabilityModule.sol` supports capped, nominal 1:1 swaps in both
directions and normalizes reserve/stablecoin decimal differences. It refuses
zero amounts, reserve-cap violations, insufficient reserves, and conversions
that round to zero.

## Chainlink feed adapter

`src/tier3/ChainlinkPriceFeed.sol` matches the AggregatorV3 shape, reads the
feed's own `decimals()`, and rejects non-positive, stale, future, or incomplete
rounds. Ex5 uses the feed decimal count when converting collateral value.

## Checks

- Ex7: 2 tests passed
- Tier 3 module tests: 11 tests passed
- Tier 1 regression: 27 Forge test cases passed, including 2 invariant properties
- Full suite: 40 tests passed, 0 failed
