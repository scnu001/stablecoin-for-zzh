# Assign2 submission checklist

## Tier 1

- [x] Ex0 core tests pass: 7 tests
- [x] Ex2 decimals tests pass
- [x] Ex3 local depeg evidence and real terminal image: `evidence/screenshotforex3.png`
- [x] Full `forge test` evidence: `evidence/pass1.png`, `evidence/pass2.png`, `evidence/pass3.png`
- [x] Ex4 permission and pause tests pass
- [x] Ex5 over-collateralized vault tests pass, including partial-liquidation and dynamic-feed-decimal regressions
- [x] Ex6 invariant tests pass: 256 runs, 128,000 handler calls
- [x] Threat-model answers A–D in `STUDENT-QUESTIONS.md`
- [x] Section E test names and attack scenario in `STUDENT-QUESTIONS.md`
- [x] Architecture diagram in `README.md`

## Tier 2

- [x] MockUSDC deployed to Sepolia
- [x] SimpleStablecoin deployed to Sepolia
- [x] Vault deployed to Sepolia
- [x] Contract addresses and transaction hashes recorded in `TIER2-SEPOLIA.md`
- [x] All three contracts confirmed fully verified by Sourcify
- [x] All three contracts confirmed verified by Etherscan

## Tier 3 (optional)

- [x] Ex7 Unstoppable challenge: 2 tests pass
- [x] Hardened burn implementation and tests
- [x] Peg Stability Module and tests
- [x] Chainlink-compatible feed adapter and tests
- [x] Ex5 dynamic feed-decimal conversion test

## Packaging

- `lib/` must remain in the submission zip.
- [x] `cache/`, `out/`, and `broadcast/` are included in the final archive as generated project artifacts.
- `.env` must not be included.
- [x] The final archive was checked for secret files and does not include `.env`.
