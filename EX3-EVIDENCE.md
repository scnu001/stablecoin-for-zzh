# Ex3 evidence — unbacked mint breaks the peg

This evidence was produced on a local Anvil chain only. It is not a Sepolia
deployment and contains no private key. The official terminal screenshot for
submission is `evidence/screenshotforex3.png`.

![Ex3 local depeg evidence](evidence/screenshotforex3.png)

## Deployment

- MockUSDC: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- SimpleStablecoin: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- Vault: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`

## Attack observation

After granting `MINTER_ROLE` to the attacker and minting raw sUSD units
without depositing collateral, the terminal showed:

```text
totalSupply:     1999998000000
totalCollateral: 0
attackerBalance: 1999998000000
```

The stablecoin supply is therefore much greater than the collateral held by
the vault. This is the deliberate Ex3 depeg demonstration: the ERC-20
operations succeed, but the backing invariant is false.
