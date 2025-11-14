# 🎯 TickPhysics Multi-Version Backtest Tracking System

This system allows you to run multiple backtest versions and compare results systematically.

---

## 📁 Directory Structure

```
MQL5/
├── analytics_output/
│   ├── data/
│   │   └── backtest/
│   │       ├── TP_Integrated_Trades_NAS100_M15_v1_7.csv
│   │       ├── TP_Integrated_Signals_NAS100_M15_v1_7.csv
│   │       ├── TP_Integrated_Trades_NAS100_M15_v1_8.csv  (future)
│   │       └── ... (more versions)
│   │
│   ├── charts/
│   │   ├── v1_7/  (baseline)
│   │   ├── v1_8/  (optimization 1)
│   │   └── ...
│   │
│   └── reports/
│       ├── v1_7/
│       ├── v1_8/
│       └── comparison/  (multi-version comparisons)
│
└── MT5 Excel Reports/
    ├── MTBacktest_Report_1_7.csv
    ├── MTBacktest_Report_1_8.csv
    └── ...
```

---

## 🔄 Workflow for Each Backtest Run

### 1. Update EA Version in Code
```mql5
// In TP_Integrated_EA.mq5
#property version   "1.8"  // Increment version
#define EA_VERSION "1_8"   // Update for CSV filenames
```

### 2. Configure Strategy Parameters
Update input parameters for the new test:
- MA periods (e.g., 20/50 instead of 10/50)
- SL/TP levels
- Physics filters (enable/disable)
- Timeframe (M5, M15, M30, H1, H4)

### 3. Run Backtest in MT5
- Compile EA
- Run backtest on desired period
- Export PDF report
- Save as `MTBacktest_Report_1_8.csv`

### 4. Copy CSVs to Workspace
```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
python3 copy_backtest_csvs.py NAS100 M15 1_8
```

### 5. Generate Analytics
```bash
python3 analyze_backtest_comprehensive.py NAS100 M15 1_8
```

### 6. Compare Versions
```bash
python3 compare_versions.py 1_7 1_8 1_9
```

---

## 📊 Version Tracking Log

### v1.7 - Baseline (COMPLETE) ✅
**Date:** 2025-11-04  
**Config:**
- Strategy: MA Crossover (10/50 EMA)
- Timeframe: M15
- Physics Filters: DISABLED
- SL/TP: 50/100 pips
- Period: Sept 2025

**Results:**
- Total Trades: 46 (47 in MT5, 1 missing at boundary)
- Win Rate: 8.70%
- Total P&L: -$312.02
- Profit Factor: 0.18
- Max Drawdown: -$312.02

**Status:** Baseline established, needs optimization

---

### v1.8 - [PLANNED] Multi-Timeframe Test
**Plan:**
- Test same MA (10/50) on different timeframes
- Run: M5, M30, H1, H4
- Compare performance
- Identify optimal timeframe

**Versions:**
- v1_8a: M5
- v1_8b: M30
- v1_8c: H1
- v1_8d: H4

---

### v1.9 - [PLANNED] MA Period Optimization
**Plan:**
- Keep best timeframe from v1.8
- Test different MA combinations:
  - 20/50 EMA
  - 50/200 EMA
  - 10/20 EMA (faster)
- Compare win rates

---

### v2.0 - [PLANNED] Physics Filter Integration
**Plan:**
- Enable physics quality filtering
- MinQuality: 65
- MinConfluence: 70
- Compare to pure MA baseline
- Measure improvement

---

## 🎯 Comparison Metrics

For each version, track:
- Total Trades
- Win Rate %
- Total P&L
- Profit Factor
- Max Drawdown
- Avg Win / Avg Loss
- SL Rate
- TP Rate
- Sharpe Ratio
- MFE/MAE averages

---

## 📈 Dashboard Features (Coming)

### Single Version Dashboard
- Equity curve
- Trade distribution
- Time analysis (hour/day of week)
- MFE/MAE scatter plots
- RunUp/RunDown analysis
- Exit reason breakdown

### Multi-Version Comparison Dashboard
- Side-by-side equity curves
- Win rate comparison bar chart
- Profit factor comparison
- Drawdown comparison
- Metric radar chart
- Performance summary table

---

## 🔧 Scripts Reference

### Data Management
- `copy_backtest_csvs.py <symbol> <timeframe> <version>` - Copy CSVs from MT5
- `parse_mt5_report_v1_7.py` - Validate CSV vs MT5 report

### Analytics
- `analyze_backtest_comprehensive.py <symbol> <tf> <version>` - Full analytics
- `compare_versions.py <v1> <v2> <v3>` - Multi-version comparison
- `quick_validate_v1_7.py` - Quick CSV check

### Configuration
- `analytics_config.py` - Paths and defaults
- Update `DEFAULT_VERSION` as you progress

---

## 📝 Best Practices

### Version Naming Convention
```
Format: X_Y[letter]

X = Major version (strategy change)
Y = Minor version (parameter tweak)
[letter] = Sub-version (timeframe/minor variation)

Examples:
- 1_7  = Version 1.7
- 1_8a = Version 1.8, variant A
- 2_0  = Version 2.0 (major strategy change)
```

### Documentation
For each version, document:
1. **What changed** from previous version
2. **Why** you made the change
3. **Expected outcome**
4. **Actual results**
5. **Next steps**

### Git Commits
Commit after each backtest:
```bash
git add .
git commit -m "Backtest v1_8a: MA 10/50 on M5 timeframe"
git tag v1_8a
```

---

## 🎯 Current Status

**Completed:**
- ✅ v1.7 baseline (10/50 EMA, M15, no filters)
- ✅ CSV validation (97.9% accuracy)
- ✅ Analytics pipeline working
- ✅ Version tracking system established

**Next:**
- [ ] Run v1_8 multi-timeframe tests
- [ ] Generate comparison reports
- [ ] Identify optimal timeframe
- [ ] Proceed to MA optimization

---

**Last Updated:** 2025-11-04  
**Current Version:** v1_7 (Baseline)  
**Next Version:** v1_8 (Multi-TF Test)
