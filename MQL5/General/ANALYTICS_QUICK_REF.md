# TickPhysics Analytics - Quick Reference Card

## 🚀 One-Page Workflow

### 1️⃣ Run Baseline Backtest (MT5)
```
EA: TP_Integrated_EA_Crossover (compiled from TP_Integrated_EA.mq5)

EA Settings:
  ✅ UseMAEntry = true
  ❌ UsePhysicsFilters = false  ← CRITICAL!
  ✅ LogToCSV = true
  
Run on: NAS100 M1, 3+ months data
```

### 2️⃣ Copy CSV to Project
```bash
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_*.csv ~/ai-trading-platform/MQL5/data/baseline.csv
```

### 3️⃣ Run Analytics
```bash
cd ~/ai-trading-platform/MQL5
pip install pandas numpy matplotlib seaborn scipy  # First time only
python analyze_backtest_advanced.py data/baseline.csv --output-dir reports/baseline
open reports/baseline/analytics_report.html
```

### 4️⃣ Identify Best Filter
**Look for in HTML report:**
- Correlation: |r| > 0.3 (moderate) or >0.5 (strong)
- Win rate improvement: >10%
- Trade count: >50 remaining
- p-value: <0.05 (statistically significant)

**Example result:**
```
EntryAccel > 0.0012
  ✅ r=0.43 (moderate), p=0.002 (significant)
  ✅ Win rate: 68.3% (+18.3% vs baseline)
  ✅ Trades: 247 (49% of baseline)
  → USE THIS!
```

### 5️⃣ Implement Filter in EA
```mql5
// In TP_Integrated_EA.mq5:
input bool UsePhysicsFilters = true;
input double MinEntryAccel = 0.0012;  // From JSON

// In OnNewBar() after signal generation:
if(signal_type != SIGNAL_NONE && UsePhysicsFilters) {
    double entry_accel = physics_indicator.GetAcceleration(0);
    if(entry_accel <= MinEntryAccel) {
        signal_type = SIGNAL_NONE;
    }
}
```

### 6️⃣ Re-Run Backtest & Compare
```bash
# Same date range as baseline!
# Pull CSV, then:
python compare_csv_backtests.py data/baseline.csv data/filtered_run1.csv
open comparison_output/comparison_report.html
```

---

## 📊 Interpreting Results

### Correlation Strength
| r Value | Meaning | Action |
|---------|---------|--------|
| >0.5 | Strong positive | Use `metric > threshold` |
| 0.3-0.5 | Moderate positive | Test it |
| <0.3 | Weak | Ignore |
| <-0.3 | Moderate negative | Use `metric < threshold` |
| <-0.5 | Strong negative | Use `metric < threshold` |

### Filter Quality Checklist
- ✅ Correlation: |r| > 0.3
- ✅ Win rate improvement: >10%
- ✅ Trade count: >50 (>10% of baseline)
- ✅ Statistical significance: p < 0.05
- ✅ Expectancy: Positive and improving

### Decision Matrix
| Win Rate Δ | Trade Count | Action |
|------------|-------------|--------|
| >15% | >50 | ✅ Deploy after validation |
| 10-15% | >50 | ✅ Test out-of-sample |
| 5-10% | >50 | ⚠️ Collect more data |
| <5% | Any | ❌ Try different metric |
| Any | <30 | ❌ Over-filtering, reduce threshold |

---

## 🔧 Common Commands

```bash
# Install dependencies
pip install pandas numpy matplotlib seaborn scipy

# Run analytics
python analyze_backtest_advanced.py data/baseline.csv --output-dir reports/baseline

# Compare two CSVs
python compare_csv_backtests.py data/baseline.csv data/filtered.csv

# Compare JSON reports
python compare_backtests.py reports/baseline/report.json reports/filtered/report.json

# View results
open reports/baseline/analytics_report.html
open comparison_output/comparison_report.html
cat reports/baseline/ea_config_optimized.json
```

---

## 🎯 Key Metrics to Track

### Performance Metrics
- **Win Rate** - % of trades that are profitable
- **Profit Factor** - Gross profit / gross loss (>1.5 is good)
- **Expectancy** - Average profit per trade
- **Sharpe Ratio** - Risk-adjusted return (>1.0 is good)
- **Max Consecutive Losses** - Drawdown risk indicator

### Physics Metrics (Entry)
- **EntryAccel** - Price acceleration at entry
- **EntryVelocity** - Price velocity at entry
- **EntryMomentum** - Combined force metric
- **EntryVolatility** - Market volatility at entry
- **EntryTrend** - Trend strength at entry

### Physics Metrics (Trade Lifecycle)
- **MFE** - Maximum Favorable Excursion (how far into profit)
- **MAE** - Maximum Adverse Excursion (how far into drawdown)
- **RunUp** - Profit peak after entry (winners only)
- **RunDown** - Drawdown depth after entry (losers only)

---

## ⚠️ Common Pitfalls

### Don't:
- ❌ Filter on RunUp/RunDown (post-exit metrics, not available at entry)
- ❌ Use <30 trades to determine thresholds (overfitting)
- ❌ Change date range between baseline and filtered test
- ❌ Stack >3 filters (over-restricts trade count)
- ❌ Ignore statistical significance (p-value)

### Do:
- ✅ Test on out-of-sample data before live deployment
- ✅ Use same date range for baseline vs filtered comparison
- ✅ Require >10% win rate improvement for deployment
- ✅ Keep trade count >50 after filtering
- ✅ Document all filter decisions with rationale

---

## 📁 File Locations

### MetaTrader CSV Output
```
macOS:
~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/

Windows:
C:\Users\<username>\AppData\Roaming\MetaQuotes\Terminal\<instance>\MQL5\Files\
```

### Project Structure
```
MQL5/
├── analyze_backtest_advanced.py       # Main analytics
├── compare_csv_backtests.py           # CSV comparison
├── data/                              # CSV files
│   ├── baseline.csv
│   └── filtered_run1.csv
└── reports/                           # HTML reports
    ├── baseline/
    │   ├── analytics_report.html
    │   ├── ea_config_optimized.json
    │   └── figures/
    └── comparison_output/
        └── comparison_report.html
```

---

## 🔍 Troubleshooting Quick Fixes

| Error | Solution |
|-------|----------|
| `ModuleNotFoundError: pandas` | `pip install pandas numpy` |
| `KeyError: 'EntryAccel'` | Verify EA is logging physics metrics |
| CSV is empty | Check backtest completed, CSV path correct |
| All correlations weak | Collect more data (>100 trades) |
| Too few trades after filter | Lower percentile threshold (70→60→50) |
| Out-of-sample fails | May be overfit; use walk-forward validation |

---

## 📈 Success Criteria

### Phase 1: Baseline
- ✅ 100+ trades
- ✅ All physics columns populated
- ✅ Win rate ~50%

### Phase 2: Analytics
- ✅ 1+ metric with |r| > 0.5
- ✅ Threshold shows >10% WR improvement

### Phase 3: Single Filter
- ✅ Win rate improvement ≥10%
- ✅ Trade count >50
- ✅ Profit factor >1.5

### Phase 4: Validation
- ✅ Out-of-sample WR within 5% of in-sample
- ✅ Walk-forward consistent

### Phase 5: Live Deployment
- ✅ Paper trading validates (2+ weeks)
- ✅ Partner approval
- ✅ Risk management rules defined

---

## 🎓 Example Session

```bash
# 1. After running baseline backtest in MT5:
cd ~/ai-trading-platform/MQL5
cp ~/Library/.../TP_Integrated_Trades_NAS100.csv data/baseline_20240115.csv

# 2. Run analytics
python analyze_backtest_advanced.py data/baseline_20240115.csv --output-dir reports/baseline_20240115

# 3. Review results
open reports/baseline_20240115/analytics_report.html
# → Identify: EntryAccel > 0.0012 gives 68.3% WR (+18.3%)

# 4. Implement filter in EA, re-run backtest, pull CSV
cp ~/Library/.../TP_Integrated_Trades_NAS100.csv data/filtered_run1_20240115.csv

# 5. Compare
python compare_csv_backtests.py data/baseline_20240115.csv data/filtered_run1_20240115.csv
open comparison_output/comparison_report.html
# → Confirm: Win rate improved to 67.8%, profit up 42%

# 6. Validate out-of-sample
# Run same filter on Apr-Jun 2024 data
cp ~/Library/.../TP_Integrated_Trades_NAS100.csv data/filtered_oos_20240415.csv
python compare_csv_backtests.py data/baseline_20240115.csv data/filtered_oos_20240415.csv
# → Confirm: Win rate 66.2% (within 2% of in-sample) ✅

# 7. Deploy to paper trading
```

---

## 📞 When to Ask for Help

- **No metrics show |r| > 0.3** after 200+ trades → May need to tune physics calculations
- **Filters work in-sample but fail out-of-sample** → Potential overfitting
- **Win rate improves but profit decreases** → Filtering out large winners
- **CSV missing columns** → EA configuration issue

---

## 🔗 Full Documentation

- `ANALYTICS_WORKFLOW_COMPLETE.md` - Complete step-by-step guide
- `CORRELATION_ANALYTICS_GUIDE.md` - Detailed interpretation
- `ANALYTICS_FRAMEWORK.md` - High-level overview
- `FAST_TEST_GUIDE.md` - Quick backtest setup

---

**Remember:** Small, validated improvements compound over time. A 10% win rate improvement can transform a break-even strategy into a profitable one! 🚀
