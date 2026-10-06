# Evidence files

## Official Ex3 submission screenshot

Use `screenshotforex3.png`. It is the real terminal capture containing:

- `totalSupply() = 1999998000000`
- `totalCollateral() = 0`
- attacker balance `= 1999998000000`

This directly demonstrates the required condition:
`totalSupply() >> totalCollateral()`.

## Full test-suite screenshots

`pass1.png`, `pass2.png`, and `pass3.png` are consecutive screenshots of the
complete `forge test` run. Together they show the Ex7, Tier 3, core, Ex5,
Ex2/Ex4, and Ex6 suites, ending with:

```text
40 tests passed, 0 failed, 0 skipped
```

`pass3.png` also shows the Ex6 invariant summary:

```text
runs: 256, calls: 128000, reverts: 0
```

## Other screenshots

`screenshot1.png` and `screenshot2.png` show local deployment receipts.
`screenshot3.png` and `screenshot4.png` show the role-grant and mint
transactions. They are useful supporting evidence but are not required for
the Ex3 deliverable, so they are excluded from the final submission archive.

The older `ex3-depeg.png`/`.svg`/`.txt` files are generated explanatory
artifacts, not the official terminal screenshot.
