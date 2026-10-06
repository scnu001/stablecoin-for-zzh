# COMP 7810A Assignment Two — Submission Sheet

Student submission package for the Stablecoin Lab. All four required hand-in
items are listed below with their location inside this archive.

## 1. Link to the repository + screenshot of `forge test` passing

**Repository:** https://github.com/scnu001/stablecoin-for-zzh

Command used to produce the evidence (from the repository root):

```bash
forge test --offline
# or, if the cached compiler is not picked up automatically:
forge test --use "$HOME/.foundry/solc/solc-v0.8.24" --offline
```

Result: **40 tests passed, 0 failed, 0 skipped**. The Ex6 invariant suite ran
256 runs / 128,000 handler calls with 0 reverts.

Screenshots (three consecutive captures of the same passing run), also
embedded in `README.md`:

| File | What it shows |
|---|---|
| `evidence/pass1.png` | Test-passing screenshot 1/3 — Ex7 Unstoppable + Tier 3 suites, all green |
| `evidence/pass2.png` | Test-passing screenshot 2/3 — core, Ex2/Ex4, Ex5, Ex6 invariant suite, all green |
| `evidence/pass3.png` | Test-passing screenshot 3/3 — final line `40 tests passed, 0 failed, 0 skipped` |

Per-area counts: core 7, Ex2/Ex4 7, Ex5 12, Ex6 invariants (256 runs /
128,000 calls), Ex7 2, Tier 3 modules 11.

## 2. Tier 2 — Sepolia contract addresses + Etherscan links

Network: Sepolia (chain ID `11155111`). RPC:
`https://ethereum-sepolia-rpc.publicnode.com`. Deploy script:
`script/Deploy.s.sol`.

| Contract | Address | Etherscan |
|---|---|---|
| MockUSDC | `0xAe4f266A2fC2911e59f991539017dd1597c4d9B3` | https://sepolia.etherscan.io/address/0xAe4f266A2fC2911e59f991539017dd1597c4d9B3 |
| SimpleStablecoin | `0x831AFEced33D71471eD5f7124Ef9Fc344b78f815` | https://sepolia.etherscan.io/address/0x831AFEced33D71471eD5f7124Ef9Fc344b78f815 |
| Vault | `0x1900a4F371CC001eF6371b6F2Ee5c5b82cD18314` | https://sepolia.etherscan.io/address/0x1900a4F371CC001eF6371b6F2Ee5c5b82cD18314 |

Deployment transactions:

- MockUSDC: https://sepolia.etherscan.io/tx/0xf346dc4d25fdafe61db67889c6802cfa195df36fc1597ddb7463f1df0597ede8
- SimpleStablecoin: https://sepolia.etherscan.io/tx/0x38f65065cba8076f9f1ff54a28067bc8d9907800da73386ddc1e6f07da48b97c
- Vault: https://sepolia.etherscan.io/tx/0x67008d13794969484796cfa52af3ec93f31a9f66cadac9cfed01ea03f2631715

All three contracts are verified on Etherscan and Sourcify
(`forge verify-check` returned `already verified` for each).

## 3. Answers to the discussion questions (`STUDENT-QUESTIONS.md`)

The full answers are in **`STUDENT-QUESTIONS.md`** (sections A, B, C, D and
E). The identical text is reproduced inside `README.md` so the repository
front page is self-contained.

- A — Permission design: `MINTER_ROLE` burn risk and how to remove it; how to
  split `DEFAULT_ADMIN_ROLE` / `MINTER_ROLE` / `PAUSER_ROLE` in production.
- B — Pausing and redemption: how to pause transfers while allowing
  redemption; 2008 money-market fund vs 2023 USDC redemption responses.
- C — Depeg analysis: solvency/accounting vs liquidity/access failures and how
  each shows up in `totalCollateral() >= totalSupply()`; flow of funds if an
  attacker obtains `MINTER_ROLE`.
- D — Toward RWA: US Treasuries and a building as collateral; valuation,
  custody, SPV and legal structures required.
- E — Test function names for the five required Ex4 scenarios, plus the
  scenario judged most likely to be attacked (unauthorized `MINTER_ROLE`
  grant) and why.

## 4. Architecture diagram

**`docs/architecture.svg`** — the architecture diagram, embedded at the top of
`README.md` and included in this archive as a standalone file. It shows:

```text
                    approve + deposit
user ─────────────────────────────────────▶ Vault
 ▲                                           │
 │                                           │ transferFrom
 │                                           ▼
 │                                      MockUSDC reserve
 │                                           │
 │                                           │ mint 1:1
 │                                           ▼
 └────────────── sUSD balance ◀──── SimpleStablecoin
                │
                │ redeem: burn sUSD
                └────────────── Vault returns collateral
```

Solid arrows are the happy path (deposit/mint, redeem/burn), the dashed purple
path is redemption, and the dashed red path is the Ex3 attack that grants
`MINTER_ROLE` to an attacker, mints with zero collateral and breaks the backing
invariant.

## Archive contents

```text
SUBMISSION.md             This sheet (repo link, screenshots, Tier 2, answers, diagram)
README.md                 Full README with everything embedded
STUDENT-QUESTIONS.md      Discussion answers A–D and E
TIER2-SEPOLIA.md          Sepolia deployment records
TIER3.md                  Optional Tier 3 extensions
EX3-EVIDENCE.md           Ex3 break-the-peg evidence
EXERCISES.md              Ex1 manual loop walkthrough
docs/architecture.svg     Architecture diagram
evidence/                 pass1-3.png (forge test passing), screenshotforex3.png (Ex3)
src/                      Contracts (core, exercises, tier3, challenges)
test/                     Forge tests (6 suites, 40 tests)
script/Deploy.s.sol       Deployment script
lib/                      Vendored forge-std + OpenZeppelin (needed for offline build)
```

No `.env` and no private key is included. The generated Foundry directories
(`cache/`, `out/`, `broadcast/`) are excluded; they are recreated by
`forge build` / `forge test`.
