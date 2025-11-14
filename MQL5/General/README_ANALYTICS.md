# TickPhysics Analytics System

**Advanced correlation analytics and threshold optimization for physics-based trade filtering**

## 🎯 What This Does

Transforms baseline trading data into intelligent, physics-optimized strategies by:
1. Identifying which physics metrics predict winning trades
2. Finding optimal threshold values for each metric
3. Testing multi-metric combinations for maximum performance
4. Generating JSON configs for self-learning EA integration
5. Providing visual reports and statistical validation

## 📚 Documentation

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[ANALYTICS_QUICK_REF.md](ANALYTICS_QUICK_REF.md)** | One-page cheat sheet | First time, or quick lookup |
| **[ANALYTICS_WORKFLOW_COMPLETE.md](ANALYTICS_WORKFLOW_COMPLETE.md)** | Complete step-by-step guide | Doing full workflow |
| **[CORRELATION_ANALYTICS_GUIDE.md](CORRELATION_ANALYTICS_GUIDE.md)** | Detailed interpretation guide | Understanding results |
| **[ANALYTICS_FRAMEWORK.md](ANALYTICS_FRAMEWORK.md)** | High-level architecture | Understanding the system |
| **[FAST_TEST_GUIDE.md](FAST_TEST_GUIDE.md)** | Backtest setup reference | Running backtests in MT5 |

## 🚀 Quick Start (5 Minutes)

### Prerequisites
```bash
# Install Python dependencies (one-time)
pip install pandas numpy matplotlib seaborn scipy
```

### Workflow
```bash
# 1. Run baseline backtest in MT5 (use TP_Integrated_EA_Crossover.ex5)
#    - MA entry enabled, physics filters OFF, logging ON

# 2. Copy CSV to project
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_*.csv data/baseline.csv

# 3. Run analytics
python analyze_backtest_advanced.py data/baseline.csv --output-dir reports/baseline

# 4. Review results
open reports/baseline/analytics_report.html

# 5. Implement recommended filter in EA, re-run backtest, compare
python compare_csv_backtests.py data/baseline.csv data/filtered_run1.csv
open comparison_output/comparison_report.html
```

## 🛠️ Tools

### 1. `analyze_backtest_advanced.py`
**Comprehensive analytics engine**

**Features:**
- Winner/loser statistical analysis
- Pearson correlation (metrics vs profit)
- Point-biserial correlation (metrics vs win/loss)
- Statistical significance testing (p-values)
- Threshold optimization (multiple percentiles)
- Win probability tables (by metric ranges)
- Multi-metric combination testing (AND logic)
- JSON config generation (for EA)
- Visual charts (correlation heatmap, distributions, comparisons)
- Interactive HTML dashboard

**Usage:**
```bash
python analyze_backtest_advanced.py <csv_file> [--output-dir DIR]
```

**Output:**
- `analytics_report.html` - Visual dashboard
- `ea_config_optimized.json` - JSON config for self-learning EA
- `figures/` - Charts and graphs

**Example:**
```bash
python analyze_backtest_advanced.py data/baseline_20240115.csv --output-dir reports/baseline_20240115
```

---

### 2. `compare_csv_backtests.py`
**Side-by-side backtest comparison**

**Features:**
- Metric-by-metric comparison (baseline vs optimized)
- Statistical significance testing (t-test)
- Equity curve overlay
- Profit distribution comparison
- Box plots and bar charts
- Dynamic recommendations
- HTML report with visual analysis

**Usage:**
```bash
python compare_csv_backtests.py <baseline.csv> <optimized.csv> [--output FILE]
```

**Output:**
- `comparison_report.html` - Detailed comparison
- `comparison_charts.png` - Visual overlays

**Example:**
```bash
python compare_csv_backtests.py data/baseline.csv data/filtered_run1.csv
```

---

### 3. `compare_backtests.py` *(existing)*
**Multi-JSON report comparison**

**Usage:**
```bash
python compare_backtests.py reports/baseline/report.json reports/filtered/report.json
```

---

## 📊 Understanding Output

### Correlation Analysis
**Correlation coefficient (r):**
- `r > 0.5` - **Strong positive** (higher metric = more profit) → High priority
- `r > 0.3` - **Moderate positive** → Worth testing
- `r < 0.3` - **Weak** → Ignore
- `r < -0.3` - **Moderate negative** (higher metric = less profit) → Reverse threshold
- `r < -0.5` - **Strong negative** → High priority

**p-value:**
- `p < 0.05` - **Statistically significant** (reliable)
- `p ≥ 0.05` - **Not significant** (may be random noise)

**Example output:**
```
Top Correlated Metrics:
  RunUp:           r= 0.721  Strong   ✅ Significant (p=0.001)
  EntryAccel:      r= 0.427  Moderate ✅ Significant (p=0.003)
  MAE:             r=-0.589  Strong   ✅ Significant (p=0.002)
  EntryVelocity:   r= 0.145  Weak     ❌ Not significant (p=0.234)
```

**Action:** Focus on RunUp, EntryAccel, and MAE.

---

### Threshold Optimization
**What it shows:**
- Optimal cutoff value for each metric
- Expected win rate after filtering
- Number of trades remaining
- Expected profit per trade (expectancy)

**Example:**
```
EntryAccel       > 0.0012
  Win Rate: 68.3% (+18.3% vs baseline 50.0%)
  Trades:  247 (49% of baseline 500)
  Expectancy: $12.45
```

**Decision criteria:**
- ✅ Win rate improvement >10% AND trades >50 → Deploy
- ✅ Win rate improvement 5-10% → Test out-of-sample
- ⚠️ Win rate improvement <5% → Try different metric
- ❌ Trades <30 → Over-filtering, reduce threshold

---

### Win Probability Tables
**Example (EntryAccel):**
```
Range                  Count  WinRate%  Expectancy
(-0.002, -0.0005]        98     32.7%      -$8.45
(-0.0005, 0.0001]       102     45.1%      -$2.12
(0.0001, 0.0008]        105     55.2%       $5.23
(0.0008, 0.0015]         97     67.0%      $12.67
(0.0015, 0.0050]         88     75.0%      $18.34
```

**Interpretation:**
- Clear progression from low to high = reliable predictor
- Use threshold where win rate jumps significantly
- In this case: `EntryAccel > 0.0008` gives 67% WR, `> 0.0015` gives 75% WR

---

### Multi-Metric Combinations
**Example:**
```
Baseline Win Rate: 50.0%

1. EntryAccel > 0.0012 AND RunUp > 15.0
   Trades:   87  Win Rate: 78.2% (+28.2%)
   Total: $1,234.56  Avg: $14.19

2. EntryAccel > 0.0012 AND MAE < -8.0
   Trades:  112  Win Rate: 71.4% (+21.4%)
   Total: $1,567.89  Avg: $14.00

3. EntryAccel > 0.0012
   Trades:  247  Win Rate: 68.3% (+18.3%)
   Total: $3,075.15  Avg: $12.45
```

**Trade-offs:**
- **Combo #1:** Highest win rate (78%), but only 87 trades (selective)
- **Combo #2:** Good win rate (71%), more trades (112) (balanced)
- **Single filter:** Moderate win rate (68%), most trades (247) (volume)

**Choose based on strategy:**
- High-frequency trading → Single filter
- Quality over quantity → Multi-filter combo

---

## 🔧 EA Integration

### Manual Implementation
```mql5
// In TP_Integrated_EA.mq5:

// Add inputs from JSON recommendations
input bool UsePhysicsFilters = true;
input double MinEntryAccel = 0.0012;  // From ea_config_optimized.json

// In OnNewBar() after signal generation:
if(signal_type != SIGNAL_NONE && UsePhysicsFilters) {
    double entry_accel = physics_indicator.GetAcceleration(0);
    
    if(entry_accel <= MinEntryAccel) {
        signal_type = SIGNAL_NONE;  // Filter out low-accel trades
        Print("Trade filtered: EntryAccel (", entry_accel, ") <= ", MinEntryAccel);
    }
}
```

### JSON-Based (Future Self-Learning)
```mql5
// Load JSON config at startup
string json_file = "MQL5/Files/ea_config_optimized.json";
CJSONValue config;
if(FileLoad(json_file, config)) {
    CJSONArray filters = config["recommended_filters"];
    for(int i = 0; i < filters.Size(); i++) {
        // Apply filters dynamically
        ApplyFilter(filters[i]);
    }
}
```

---

## 📁 File Structure

```
MQL5/
├── README_ANALYTICS.md                    # This file
├── ANALYTICS_QUICK_REF.md                 # One-page cheat sheet
├── ANALYTICS_WORKFLOW_COMPLETE.md         # Complete guide
├── CORRELATION_ANALYTICS_GUIDE.md         # Interpretation guide
├── ANALYTICS_FRAMEWORK.md                 # Architecture overview
├── FAST_TEST_GUIDE.md                     # Backtest setup
│
├── analyze_backtest_advanced.py           # Main analytics tool
├── compare_csv_backtests.py               # CSV comparison tool
├── compare_backtests.py                   # JSON comparison tool (existing)
│
├── data/
│   ├── baseline_YYYYMMDD.csv              # Baseline backtests
│   ├── filtered_run1_YYYYMMDD.csv         # Filtered backtests
│   └── ...
│
└── reports/
    ├── baseline_YYYYMMDD/
    │   ├── analytics_report.html          # Interactive dashboard
    │   ├── ea_config_optimized.json       # JSON config
    │   └── figures/                       # Charts
    │       ├── correlation_heatmap.png
    │       ├── profit_distribution.png
    │       └── top_metrics_comparison.png
    │
    ├── filtered_run1_YYYYMMDD/
    └── comparison_output/
        ├── comparison_report.html         # Side-by-side comparison
        └── comparison_charts.png          # Visual overlays
```

---

## ⚠️ Important Notes

### CSV Requirements
**Must have these columns:**
- `NetProfit` - Trade profit/loss
- `EntryAccel`, `EntryVelocity`, `EntryMomentum`, etc. - Physics metrics at entry
- `MFE`, `MAE` - Maximum favorable/adverse excursion
- `RunUp`, `RunDown` - Post-exit metrics (winners/losers)
- `EntryTime`, `ExitTime` - Timestamps

**Verified by:** `TP_CSV_Logger.mqh` in TickPhysics EA

---

### Common Pitfalls
❌ **Don't:**
- Filter on `RunUp`/`RunDown` (only available after trade closes)
- Use <100 trades for threshold optimization (overfitting risk)
- Change date range between baseline and filtered test
- Stack >3 filters (over-restricts trade count)

✅ **Do:**
- Test on out-of-sample data before live deployment
- Require >10% win rate improvement for deployment
- Keep trade count >50 after filtering
- Document all decisions with rationale
- Validate with walk-forward analysis

---

## 📈 Success Metrics

### Baseline Phase
- ✅ 100+ trades collected
- ✅ All physics columns populated
- ✅ Win rate ~50% (typical for MA crossover)

### Analytics Phase
- ✅ 1+ metric with |r| > 0.5 (strong correlation)
- ✅ Threshold shows >10% WR improvement
- ✅ Statistical significance (p < 0.05)

### Implementation Phase
- ✅ Single filter: WR +10%, >50 trades, PF >1.5
- ✅ Multi-filter: WR +15%, >30 trades, PF >2.0

### Validation Phase
- ✅ Out-of-sample WR within 5% of in-sample
- ✅ Walk-forward shows consistency
- ✅ Paper trading confirms (2+ weeks)

---

## 🎓 Learning Path

1. **New to analytics?** → Start with `ANALYTICS_QUICK_REF.md`
2. **First full run?** → Follow `ANALYTICS_WORKFLOW_COMPLETE.md`
3. **Understanding results?** → Read `CORRELATION_ANALYTICS_GUIDE.md`
4. **System architecture?** → Review `ANALYTICS_FRAMEWORK.md`
5. **Backtest setup?** → See `FAST_TEST_GUIDE.md`

---

## 🔗 External Resources

- **Python Pandas:** https://pandas.pydata.org/docs/
- **Correlation Analysis:** https://en.wikipedia.org/wiki/Pearson_correlation_coefficient
- **Statistical Significance:** https://en.wikipedia.org/wiki/P-value
- **Backtesting Best Practices:** https://www.investopedia.com/terms/b/backtesting.asp

---

## 🤝 Contributing

When adding new analytics features:
1. Update `analyze_backtest_advanced.py` with new analysis methods
2. Document in `CORRELATION_ANALYTICS_GUIDE.md`
3. Add examples to `ANALYTICS_WORKFLOW_COMPLETE.md`
4. Update this README

---

## 📞 Support

**Common issues:**
- **No correlations found:** Collect more data (>100 trades) or try different symbol/timeframe
- **Over-filtering (<30 trades):** Lower percentile threshold (75→60→50)
- **Out-of-sample fails:** May be overfit; use walk-forward or collect more baseline
- **CSV missing columns:** Verify EA is logging all physics metrics

**Questions?** Review documentation in order:
1. `ANALYTICS_QUICK_REF.md` - Quick answers
2. `ANALYTICS_WORKFLOW_COMPLETE.md` - Detailed workflow
3. `CORRELATION_ANALYTICS_GUIDE.md` - Interpretation help

---

## 🚀 Next Steps

1. **Run baseline backtest** in MT5 (MA-only, filters OFF)
2. **Run analytics** with `analyze_backtest_advanced.py`
3. **Review HTML report** and identify top filter
4. **Implement filter** in EA
5. **Re-test and compare** using `compare_csv_backtests.py`
6. **Validate out-of-sample** before live deployment

---

**Remember:** Even a 10% win rate improvement can transform a break-even strategy into a consistently profitable one. The key is systematic, data-driven optimization! 🎯

---

**Version:** 1.0  
**Last Updated:** 2024-01-15  
**Part of:** TickPhysics AI Trading Platform
