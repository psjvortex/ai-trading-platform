# TickPhysics Analytics Workflow - Complete Guide

## 🎯 Mission

Transform baseline MA-crossover backtest data into intelligent, physics-optimized trading through systematic correlation analysis, threshold optimization, and iterative testing.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Phase 1: Baseline Collection](#phase-1-baseline-collection)
3. [Phase 2: Analytics & Discovery](#phase-2-analytics--discovery)
4. [Phase 3: Single-Filter Testing](#phase-3-single-filter-testing)
5. [Phase 4: Multi-Filter Optimization](#phase-4-multi-filter-optimization)
6. [Phase 5: Validation & Documentation](#phase-5-validation--documentation)
7. [Tools Reference](#tools-reference)
8. [Interpretation Guide](#interpretation-guide)
9. [Troubleshooting](#troubleshooting)

---

## Quick Start

**Complete workflow in 5 steps:**

```bash
# 1. Run baseline backtest in MT5 (MA-only, no physics filters)
# 2. Pull CSV from MT5
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_*.csv ~/ai-trading-platform/MQL5/data/baseline.csv

# 3. Run analytics
cd ~/ai-trading-platform/MQL5
python analyze_backtest_advanced.py data/baseline.csv --output-dir reports/baseline

# 4. Review results & implement top filter
open reports/baseline/analytics_report.html

# 5. Re-test with filter enabled & compare
python compare_csv_backtests.py data/baseline.csv data/filtered_run1.csv
```

---

## Phase 1: Baseline Collection

### Objective
Establish a clean baseline with MA crossover entry, physics metrics logged but NOT used for filtering.

### Steps

#### 1.1 Configure EA for Baseline
```mql5
// In TP_Integrated_EA.mq5 inputs:
input bool UseMAEntry = true;           // ✅ Enable MA crossover
input bool UsePhysicsEntry = false;     // ❌ Disable physics entry
input bool UsePhysicsFilters = false;   // ❌ CRITICAL: No filtering!
input bool LogToCSV = true;             // ✅ Enable CSV logging

// MA settings (example):
input int FastMA_Period = 10;
input int SlowMA_Period = 20;
input ENUM_MA_METHOD MA_Method = MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;
```

#### 1.2 Run Backtest
- **Symbol:** NAS100 (or your target)
- **Timeframe:** M1 (or your preference)
- **Date Range:** At least 3 months of recent data
- **Spread:** Realistic (e.g., 2-5 points for NAS100)
- **Slippage:** Consider real-world slippage (3-5 points)

**Expected Results:**
- 100-500+ trades (depending on date range)
- ~50% win rate (MA crossover is typically break-even without filters)
- CSV file saved to: `MQL5/Files/TP_Integrated_Trades_<Symbol>.csv`

#### 1.3 Verify CSV Output
```bash
# Check CSV was generated
ls ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_*.csv

# Verify column structure
head -n 2 TP_Integrated_Trades_NAS100.csv
```

Expected columns:
```
Ticket,Symbol,TradeType,EntryTime,ExitTime,EntryPrice,ExitPrice,NetProfit,
MaxDrawdown,MFE,MAE,RunUp,RunDown,ExitReason,EntryAccel,EntryVelocity,
EntryMomentum,EntryVolatility,EntryTrend,EntryForce,AvgAccel,AvgVelocity,
AvgMomentum,MaxAccel,MaxVelocity,MinAccel,MinVelocity
```

#### 1.4 Copy to Project
```bash
# Create data directory
mkdir -p ~/ai-trading-platform/MQL5/data

# Copy baseline CSV
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_NAS100.csv ~/ai-trading-platform/MQL5/data/baseline_$(date +%Y%m%d).csv
```

---

## Phase 2: Analytics & Discovery

### Objective
Identify which physics metrics correlate with winning trades and determine optimal thresholds.

### Steps

#### 2.1 Install Python Dependencies
```bash
cd ~/ai-trading-platform/MQL5

# Install required packages (one-time)
pip install pandas numpy matplotlib seaborn scipy
```

#### 2.2 Run Advanced Analytics
```bash
python analyze_backtest_advanced.py data/baseline_20240115.csv --output-dir reports/baseline_20240115
```

**What it does:**
1. Loads CSV and separates winners/losers
2. Calculates Pearson correlation for each physics metric vs profit
3. Performs threshold optimization (tests multiple percentiles)
4. Builds win probability tables by metric ranges
5. Tests multi-metric combinations (AND logic)
6. Generates JSON config for EA
7. Creates visual charts (distribution, correlation heatmap, comparison)
8. Produces interactive HTML report

**Expected Runtime:** 10-30 seconds for 500 trades

#### 2.3 Review HTML Report
```bash
open reports/baseline_20240115/analytics_report.html
```

**Key sections to review:**

##### A. Performance Summary
- Total trades, win rate, profit factor
- Establishes baseline metrics

##### B. Top Correlated Metrics
Look for:
- **Strong correlations** (|r| > 0.5): High priority
- **Moderate correlations** (|r| > 0.3): Worth testing
- **Statistical significance** (p < 0.05): Reliable

Example output:
```
Top Correlations:
  RunUp:           r= 0.721  Strong   ✅ Significant
  EntryAccel:      r= 0.427  Moderate ✅ Significant
  MAE:             r=-0.589  Strong   ✅ Significant
  EntryMomentum:   r= 0.381  Moderate ✅ Significant
  EntryVelocity:   r= 0.145  Weak     ❌ Not significant
```

**Action:** Focus on RunUp, EntryAccel, MAE, EntryMomentum.

##### C. Threshold Optimization
For each significant metric, shows:
- **Optimal threshold value**
- **Expected win rate improvement**
- **Number of trades remaining**
- **Expected profit per trade (expectancy)**

Example:
```
EntryAccel       > 0.0012
  Win Rate: 68.3% (+18.3% vs baseline)
  Trades:  247  Expectancy: $12.45
```

**Decision criteria:**
- ✅ Win rate improvement >10% AND trades >50
- ✅ Expectancy significantly positive
- ❌ Win rate improvement <5% (not worth complexity)
- ❌ Trades <30 (overfitting risk)

##### D. Win Probability Tables
Shows win rate across metric ranges (quintiles).

Example (EntryAccel):
```
Range                  Count  WinRate%
(-0.002, -0.0005]        98     32.7%    ← Low accel = low win rate
(-0.0005, 0.0001]       102     45.1%
(0.0001, 0.0008]        105     55.2%
(0.0008, 0.0015]         97     67.0%    ← Medium-high accel = good
(0.0015, 0.0050]         88     75.0%    ← High accel = excellent!
```

**Interpretation:** Clear progression = reliable filter. Use threshold where win rate jumps significantly.

##### E. Multi-Metric Combinations
Top combinations of 2-3 metrics (AND logic).

Example:
```
1. EntryAccel > 0.0012 AND RunUp > 15.0
   Trades:   87  Win Rate: 78.2% (+28.2%)
   
2. EntryAccel > 0.0012
   Trades:  247  Win Rate: 68.3% (+18.3%)
```

**Trade-off:** Higher combo win rate but fewer trades. Choose based on your strategy (volume vs selectivity).

#### 2.4 Review JSON Config
```bash
cat reports/baseline_20240115/ea_config_optimized.json
```

**Structure:**
```json
{
  "baseline_performance": {
    "total_trades": 500,
    "win_rate": 50.0,
    "profit_factor": 1.23
  },
  "recommended_filters": [
    {
      "metric": "EntryAccel",
      "operator": ">",
      "threshold": 0.0012,
      "expected_win_rate": 68.3,
      "improvement_vs_baseline": 18.3
    }
  ],
  "best_combination": {
    "conditions": "EntryAccel > 0.0012 AND RunUp > 15.0",
    "win_rate": 78.2,
    "count": 87
  }
}
```

**Use cases:**
1. Manual EA configuration (copy threshold values)
2. Future self-learning module (load JSON at runtime)
3. Documentation for partner review

---

## Phase 3: Single-Filter Testing

### Objective
Test the single best filter on the same date range to validate improvement.

### Steps

#### 3.1 Identify Best Single Filter
From analytics report, choose the filter with:
- Highest win rate improvement (>10% ideal)
- Adequate trade count (>50 trades)
- Strong statistical significance

**Example decision:**
```
EntryAccel > 0.0012
  ✅ Win rate: 68.3% (+18.3%)
  ✅ Trades: 247 (49% of baseline)
  ✅ Expectancy: $12.45
  → This is our test filter
```

#### 3.2 Implement Filter in EA

##### Option A: Hardcode Threshold (Quick Test)
```mql5
// In TP_Integrated_EA.mq5, in OnNewBar() after signal generation:

if(signal_type != SIGNAL_NONE && UsePhysicsFilters) {
    double entry_accel = physics_indicator.GetAcceleration(0);
    
    // Apply EntryAccel > 0.0012 filter
    if(entry_accel <= 0.0012) {
        signal_type = SIGNAL_NONE;  // Filter out low-accel trades
        Print("Trade filtered: EntryAccel (", entry_accel, ") <= 0.0012");
    }
}
```

##### Option B: Add Input Parameter (Flexible)
```mql5
// Add to input parameters section:
input bool UsePhysicsFilters = true;
input double MinEntryAccel = 0.0012;  // From analytics

// In OnNewBar():
if(signal_type != SIGNAL_NONE && UsePhysicsFilters) {
    double entry_accel = physics_indicator.GetAcceleration(0);
    
    if(entry_accel <= MinEntryAccel) {
        signal_type = SIGNAL_NONE;
        Print("Trade filtered: EntryAccel (", entry_accel, ") <= ", MinEntryAccel);
    }
}
```

#### 3.3 Configure EA for Filtered Run
```mql5
// EA Inputs:
input bool UseMAEntry = true;           // ✅ Same as baseline
input bool UsePhysicsEntry = false;     // ❌ Same as baseline
input bool UsePhysicsFilters = true;    // ✅ ENABLE FILTERS
input bool LogToCSV = true;             // ✅ Still logging

// Filter settings:
input double MinEntryAccel = 0.0012;    // From JSON recommendation
```

#### 3.4 Run Backtest on SAME Date Range
**CRITICAL:** Use identical settings to baseline:
- Same symbol
- Same timeframe
- **Same start/end dates** (apples-to-apples comparison)
- Same spread/slippage

#### 3.5 Pull Filtered CSV
```bash
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_NAS100.csv ~/ai-trading-platform/MQL5/data/filtered_run1_$(date +%Y%m%d).csv
```

#### 3.6 Compare Results
```bash
cd ~/ai-trading-platform/MQL5

python compare_csv_backtests.py \
  data/baseline_20240115.csv \
  data/filtered_run1_20240115.csv \
  --output comparison_filtered_run1.html

open comparison_output/comparison_filtered_run1.html
```

**Expected Output:**
- Side-by-side metrics table (baseline vs filtered)
- Equity curve overlay
- Profit distribution comparison
- Statistical significance test (t-test)
- Recommendations (improvement/degradation analysis)

#### 3.7 Decision Point
**If filtered run shows:**
- ✅ **Win rate improvement ≥ 10%** → Proceed to multi-filter testing
- ✅ **Win rate improvement 5-10%** → Test on out-of-sample data first
- ⚠️ **Win rate improvement <5%** → Try next-best filter or collect more baseline data
- ❌ **Win rate degradation** → Filter may be overfit; revert and try different metric

---

## Phase 4: Multi-Filter Optimization

### Objective
Test combining multiple filters to maximize win rate while maintaining adequate trade count.

### Steps

#### 4.1 Review Best Combinations
From `analytics_report.html`, section "Multi-Metric Combinations":
```
1. EntryAccel > 0.0012 AND RunUp > 15.0
   Trades:   87  Win Rate: 78.2% (+28.2%)
   
2. EntryAccel > 0.0012 AND MAE < -8.0
   Trades:  112  Win Rate: 71.4% (+21.4%)
```

**Choose based on:**
- **High-selectivity approach:** Combo #1 (fewer trades, higher win rate)
- **Balanced approach:** Combo #2 (more trades, good win rate)

#### 4.2 Implement Multi-Filter
```mql5
// In TP_Integrated_EA.mq5:

input bool UsePhysicsFilters = true;
input double MinEntryAccel = 0.0012;
input double MinRunUp = 15.0;  // For post-exit analytics (not real-time)

// NOTE: RunUp is calculated AFTER trade closes, so we can't filter on it pre-entry.
// Use real-time metrics only (EntryAccel, EntryMomentum, etc.)

// Better multi-filter example:
if(signal_type != SIGNAL_NONE && UsePhysicsFilters) {
    double entry_accel = physics_indicator.GetAcceleration(0);
    double entry_momentum = physics_indicator.GetMomentum(0);
    
    // Filter 1: Minimum acceleration
    if(entry_accel <= MinEntryAccel) {
        signal_type = SIGNAL_NONE;
        Print("Filtered by EntryAccel");
    }
    // Filter 2: Minimum momentum
    else if(entry_momentum <= MinEntryMomentum) {
        signal_type = SIGNAL_NONE;
        Print("Filtered by EntryMomentum");
    }
}
```

#### 4.3 Run Multi-Filter Backtest
```bash
# Same date range as baseline and filtered_run1!
# Pull CSV:
cp ~/Library/.../TP_Integrated_Trades_NAS100.csv ~/ai-trading-platform/MQL5/data/filtered_run2_20240115.csv
```

#### 4.4 Compare All Runs
```bash
# Compare run2 to baseline
python compare_csv_backtests.py data/baseline_20240115.csv data/filtered_run2_20240115.csv

# Or compare run2 to run1
python compare_csv_backtests.py data/filtered_run1_20240115.csv data/filtered_run2_20240115.csv
```

#### 4.5 Decision Matrix
| Run | Win Rate | Total Profit | Trade Count | Verdict |
|-----|----------|--------------|-------------|---------|
| Baseline | 50% | $500 | 500 | Reference |
| Single Filter | 68% | $850 | 247 | ✅ Good improvement |
| Multi-Filter | 78% | $680 | 87 | ⚠️ High WR but low count |

**Choose:**
- Single filter if you want more trades (volume strategy)
- Multi-filter if you want higher win rate (selective strategy)

---

## Phase 5: Validation & Documentation

### Objective
Validate filters aren't overfit, prepare for live deployment, and document for partner review.

### Steps

#### 5.1 Out-of-Sample Testing
**Run backtest on a DIFFERENT date range:**
```
Baseline period: Jan-Mar 2024
Out-of-sample:   Apr-Jun 2024
```

**Expected results:**
- Win rate within ±5% of in-sample results → ✅ Not overfit
- Win rate drops >10% → ⚠️ May be overfit, collect more data
- Win rate improves → 🎉 Lucky or filter is very robust

#### 5.2 Walk-Forward Analysis
1. Split data into sequential periods (e.g., 3 months each)
2. Run analytics on period 1 → Get thresholds
3. Test thresholds on period 2
4. Repeat for periods 2→3, 3→4, etc.
5. Check consistency of results

#### 5.3 Generate Final Report Package
```bash
mkdir -p reports/final_package

# Copy key reports
cp reports/baseline_20240115/analytics_report.html reports/final_package/
cp reports/baseline_20240115/ea_config_optimized.json reports/final_package/
cp comparison_output/comparison_filtered_run1.html reports/final_package/

# Generate summary document
cat > reports/final_package/SUMMARY.md << 'EOF'
# TickPhysics Optimization Results

## Executive Summary
- **Baseline Win Rate:** 50.0%
- **Optimized Win Rate:** 68.3%
- **Improvement:** +18.3 percentage points
- **Filter Used:** EntryAccel > 0.0012
- **Trade Count:** 247 (49% of baseline)
- **Profit Factor:** 1.85 (vs 1.23 baseline)

## Validation
- Out-of-sample test: 66.8% win rate (within 1.5% of in-sample)
- Walk-forward: Consistent across 4 sequential periods
- Live paper trading: 2 weeks, 65.2% win rate (12 trades)

## Recommendation
✅ Deploy to live with conservative position sizing (0.5% risk per trade).
EOF
```

#### 5.4 Create Partner Presentation
```bash
# Generate comprehensive comparison for all runs
python generate_partner_report.py \
  --baseline data/baseline_20240115.csv \
  --filtered data/filtered_run1_20240115.csv \
  --out-of-sample data/filtered_run1_oos_20240415.csv \
  --output reports/final_package/partner_presentation.html
```

**Include:**
- Executive summary (key metrics)
- Correlation analysis (top predictive metrics)
- Threshold optimization results
- In-sample vs out-of-sample comparison
- Equity curves (baseline vs optimized)
- Recommended next steps

---

## Tools Reference

### 1. `analyze_backtest_advanced.py`
**Purpose:** Comprehensive correlation and threshold analysis

**Usage:**
```bash
python analyze_backtest_advanced.py <csv_file> [--output-dir DIR]
```

**Outputs:**
- `analytics_report.html` - Interactive visual report
- `ea_config_optimized.json` - JSON config for EA
- `figures/` - Charts (correlation, distribution, comparison)

**Key Features:**
- Pearson correlation analysis
- Point-biserial correlation with win/loss
- Statistical significance testing (p-values)
- Threshold optimization (multiple percentiles)
- Win probability tables
- Multi-metric combination testing

---

### 2. `compare_csv_backtests.py`
**Purpose:** Side-by-side comparison of two backtests

**Usage:**
```bash
python compare_csv_backtests.py <baseline.csv> <optimized.csv> [--output FILE]
```

**Outputs:**
- `comparison_report.html` - Detailed comparison report
- `comparison_charts.png` - Visual overlays

**Key Features:**
- Metric-by-metric comparison
- Statistical significance (t-test)
- Equity curve overlay
- Profit distribution comparison
- Dynamic recommendations (improvement/degradation analysis)

---

### 3. `compare_backtests.py` (existing JSON tool)
**Purpose:** Compare multiple JSON report files

**Usage:**
```bash
python compare_backtests.py reports/*.json
```

**Use when:** You have JSON reports from different strategies (baseline, physics-enhanced, etc.)

---

## Interpretation Guide

### Understanding Correlation Coefficients

| Correlation (r) | Interpretation | Action |
|----------------|----------------|--------|
| r > 0.5 | Strong positive | High priority filter |
| r > 0.3 | Moderate positive | Worth testing |
| -0.3 < r < 0.3 | Weak | Ignore or combine with others |
| r < -0.3 | Moderate negative | Use threshold reversal (keep if BELOW) |
| r < -0.5 | Strong negative | High priority (filter out high values) |

**Example:**
- `EntryAccel` r=0.43 → Higher accel = more profit → Keep trades with `EntryAccel > threshold`
- `MAE` r=-0.59 → Higher MAE (more adverse) = less profit → Keep trades with `MAE > threshold` (less negative)

---

### Win Probability Tables

**Look for:**
1. **Progressive improvement** across ranges (indicates reliable predictor)
2. **Clear "sweet spot"** (one range with much higher win rate)
3. **Sufficient sample size** in each range (>20 trades minimum)

**Red flags:**
- Random distribution (no clear pattern)
- All ranges have similar win rates (metric not useful)
- One range has 100% but only 3 trades (noise)

---

### Statistical Significance

**p-value < 0.05:** 
- Less than 5% chance the correlation is due to randomness
- ✅ Reliable for filtering

**p-value ≥ 0.05:**
- Could be random noise
- ⚠️ Don't rely on this metric alone
- Collect more data or test on out-of-sample

---

## Troubleshooting

### Issue 1: No Significant Correlations Found
**Symptoms:** All metrics show |r| < 0.3 or p > 0.05

**Possible causes:**
- Too few trades (<100)
- Market is truly random for this symbol/timeframe
- Physics metrics not capturing relevant dynamics

**Solutions:**
1. Collect more data (longer backtest period)
2. Try different symbol or timeframe
3. Review physics calculation (may need tuning for symbol's volatility)

---

### Issue 2: Thresholds Cause <30 Trades
**Symptoms:** Optimized threshold filters out >90% of trades

**Possible causes:**
- Overly aggressive percentile (e.g., 90th percentile)
- Combining too many filters (AND logic is restrictive)

**Solutions:**
1. Use lower percentile (e.g., 60th instead of 80th)
2. Test single filter first before combining
3. Use OR logic for some filters instead of AND

**Example fix:**
```mql5
// Instead of: Accel > X AND Momentum > Y (very restrictive)
// Try: (Accel > X) OR (Momentum > Y AND Trend > Z)
```

---

### Issue 3: Out-of-Sample Win Rate Drops Significantly
**Symptoms:** In-sample 70%, out-of-sample 52%

**Diagnosis:** Likely overfit to training data

**Solutions:**
1. Use more conservative threshold (e.g., 50th percentile instead of 75th)
2. Combine with time-based analysis (maybe filter only works in certain market conditions)
3. Collect more baseline data (increase sample size)
4. Use walk-forward analysis to find stable thresholds

---

### Issue 4: Analytics Script Errors

**Error: `ModuleNotFoundError: No module named 'pandas'`**
```bash
pip install pandas numpy matplotlib seaborn scipy
```

**Error: `KeyError: 'EntryAccel'`**
- CSV missing expected columns
- Verify EA is logging all physics metrics
- Check CSV header row

**Error: `ValueError: not enough values to unpack`**
- CSV may be empty or malformed
- Check last backtest completed successfully
- Verify CSV path is correct

---

## Next Steps

### Immediate Actions
1. ✅ Run baseline backtest (MA-only, physics logged)
2. ✅ Run `analyze_backtest_advanced.py`
3. ✅ Review analytics report and identify top filter
4. ✅ Implement single filter and re-test
5. ✅ Compare baseline vs filtered using `compare_csv_backtests.py`

### If Results Are Good (>10% Win Rate Improvement)
6. Test on out-of-sample data
7. Implement multi-filter combo
8. Walk-forward validation
9. Live paper trading (2-4 weeks)
10. Partner review and approval
11. Live deployment with conservative sizing

### If Results Are Mixed (5-10% Improvement)
6. Collect more baseline data (longer period)
7. Test on multiple symbols
8. Fine-tune thresholds using probability tables
9. Consider time-of-day or session filters

### Future Enhancements
- **Self-learning module:** EA reads JSON and applies filters automatically
- **Automated walk-forward:** Script runs sequential optimizations
- **Real-time monitoring:** Compare live results to expected performance
- **Drift detection:** Alert when actual diverges from expected
- **Multi-symbol optimization:** Find universal thresholds across symbols

---

## File Organization

```
MQL5/
├── analyze_backtest_advanced.py          # Main analytics tool
├── compare_csv_backtests.py              # CSV comparison tool
├── compare_backtests.py                  # JSON comparison tool (existing)
├── CORRELATION_ANALYTICS_GUIDE.md        # Detailed interpretation guide
├── ANALYTICS_WORKFLOW_COMPLETE.md        # This file
├── ANALYTICS_FRAMEWORK.md                # High-level workflow doc
│
├── data/
│   ├── baseline_20240115.csv
│   ├── filtered_run1_20240115.csv
│   ├── filtered_run2_20240115.csv
│   └── filtered_run1_oos_20240415.csv
│
└── reports/
    ├── baseline_20240115/
    │   ├── analytics_report.html
    │   ├── ea_config_optimized.json
    │   └── figures/
    │       ├── correlation_heatmap.png
    │       ├── profit_distribution.png
    │       └── top_metrics_comparison.png
    │
    ├── filtered_run1_20240115/
    └── comparison_output/
        ├── comparison_filtered_run1.html
        └── comparison_charts.png
```

---

## Success Metrics

**Phase 1 (Baseline):**
- ✅ 100+ trades collected
- ✅ All physics metrics populated in CSV
- ✅ Baseline win rate ~45-55% (typical for MA crossover)

**Phase 2 (Analytics):**
- ✅ 3+ metrics with |r| > 0.3
- ✅ 1+ metric with |r| > 0.5
- ✅ Threshold optimization shows >10% WR improvement

**Phase 3 (Single Filter):**
- ✅ Win rate improvement ≥10%
- ✅ Trade count >50
- ✅ Profit factor >1.5

**Phase 4 (Multi-Filter):**
- ✅ Win rate improvement ≥15%
- ✅ Trade count >30
- ✅ Profit factor >2.0

**Phase 5 (Validation):**
- ✅ Out-of-sample WR within 5% of in-sample
- ✅ Walk-forward shows consistency
- ✅ Live paper trading validates results

---

## Questions & Support

**Common questions:**
- "How many trades do I need for reliable analytics?" → Minimum 100, ideal 300+
- "What if two metrics have similar correlation?" → Test both, may indicate they measure same thing
- "Can I use RunUp as an entry filter?" → No, RunUp is post-exit. Use EntryAccel, EntryMomentum, etc.
- "What's a good profit factor?" → >1.5 is good, >2.0 is excellent
- "How often should I re-run analytics?" → Monthly, or when market conditions change significantly

**Additional resources:**
- `CORRELATION_ANALYTICS_GUIDE.md` - Detailed metric interpretation
- `FAST_TEST_GUIDE.md` - Quick backtest setup
- `ANALYTICS_FRAMEWORK.md` - High-level overview

---

**Remember:** The goal is not to find THE perfect filter, but to systematically improve win rate through data-driven decision-making. Even a 10% improvement can dramatically change profitability! 🚀
