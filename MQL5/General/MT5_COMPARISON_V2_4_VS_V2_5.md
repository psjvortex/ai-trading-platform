# MT5 Backtest Comparison: v2.4 vs v2.5

## Configuration

- **v2.4:** MA Crossover (no physics filters)
- **v2.5:** MA Crossover + Physics filters (BEAR zone + LOW regime rejection)
- **Symbol:** NAS100 M15
- **Period:** Jan 2025 - Sep 2025 (9 months)

## Results

| Metric | v2.4 | v2.5 | Change |
|--------|------|------|--------|
| Trades | 454 | 121 | -333 (-73.3%) |
| Win Rate | 27.8% | 34.7% | +7.0% |
| Total P&L | $-454.39 | $277.96 | $+732.35 |
| Avg Trade | $-1.00 | $2.30 | $+3.30 |
| Profit Factor | 0.89 | 1.18 | +0.29 |
| Max DD | 58.48% | 59.18% | +0.71% |
| ROI | -45.44% | 27.80% | +73.23% |

## Filter Impact

- Physics filters rejected 333 signals (73.3%)
- Filters avoided BEAR trading zones and LOW volatility regimes
- Metrics improved: 4/4

## Conclusion

✅ **Physics optimization was successful.** The regime and zone filters significantly improved trading performance by filtering out low-quality setups.
