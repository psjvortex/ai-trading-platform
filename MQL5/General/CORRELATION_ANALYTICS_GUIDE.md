# TickPhysics Correlation Analytics Guide

## 📚 Overview

The advanced analytics system identifies which physics metrics predict winning trades through:
- **Statistical correlation analysis** (Pearson & point-biserial)
- **Threshold optimization** (find best cutoffs per metric)
- **Win probability tables** (probability by metric ranges)
- **Multi-metric combinations** (synergistic filters)
- **JSON configuration export** (ready for self-learning EA)
- **Interactive HTML dashboard** (visual reports)

---

## 🚀 Quick Start

### 1. Run a Baseline Backtest (MA-Only, No Physics Filters)

```bash
# In MetaTrader 5:
# 1. Load TP_Integrated_EA.mq5
# 2. Set inputs:
#    - UseMAEntry = true
#    - UsePhysicsEntry = false  
#    - UsePhysicsFilters = false  (CRITICAL!)
#    - LogToCSV = true
# 3. Run backtest on desired symbol/timeframe/date range
# 4. Wait for completion
```

### 2. Pull CSV File from MetaTrader

```bash
# CSV is automatically saved to:
# macOS: ~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files/
# Windows: C:\Users\<username>\AppData\Roaming\MetaQuotes\Terminal\<instance>\MQL5\Files\

# Copy to project directory
cp ~/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Files/TP_Integrated_Trades_NAS100.csv ~/ai-trading-platform/MQL5/data/
```

### 3. Run Analytics Script

```bash
cd ~/ai-trading-platform/MQL5

# Install dependencies (first time only)
pip install pandas numpy matplotlib seaborn scipy

# Run analysis
python analyze_backtest_advanced.py data/TP_Integrated_Trades_NAS100.csv --output-dir reports/baseline_run1

# Output:
# ✅ reports/baseline_run1/analytics_report.html
# ✅ reports/baseline_run1/ea_config_optimized.json
# ✅ reports/baseline_run1/figures/*.png
```

### 4. Review Results

```bash
# Open HTML report in browser
open reports/baseline_run1/analytics_report.html

# Review JSON config for recommended filters
cat reports/baseline_run1/ea_config_optimized.json
```

---

## 📊 Understanding the Analytics Output

### 1. **Correlation Analysis**

**What it shows:**
- Which physics metrics correlate with profitable trades
- Direction (positive or negative correlation)
- Statistical significance (p-value < 0.05)
- Correlation strength (weak/moderate/strong)

**Example Output:**
```
EntryAccel          📈 Positive  r= 0.427  Moderate
EntryMomentum       📈 Positive  r= 0.381  Moderate
EntryVelocity       📉 Negative  r=-0.312  Moderate
MAE                 📉 Negative  r=-0.589  Strong
RunUp               📈 Positive  r= 0.721  Strong
```

**How to read:**
- **r > 0**: Higher metric value → More profit (keep trades with high values)
- **r < 0**: Higher metric value → Less profit (keep trades with low values)
- **|r| > 0.5**: Strong predictor (prioritize for filtering)
- **|r| < 0.3**: Weak predictor (may not help much)

**Action:** Focus on metrics with **strong** correlations for your first filters.

---

### 2. **Threshold Optimization**

**What it shows:**
- Optimal cutoff value for each metric
- Win rate improvement vs baseline
- Number of trades remaining after filter
- Expected profit per trade

**Example Output:**
```
EntryAccel           > 0.0012
  Win Rate: 68.3% (+18.3% vs baseline)
  Trades:  247  Expectancy: $12.45

EntryMomentum        > 0.0034
  Win Rate: 65.1% (+15.1% vs baseline)
  Trades:  189  Expectancy: $15.78
```

**How to read:**
- **Threshold**: The value to use in your EA filter (e.g., `if(EntryAccel > 0.0012)`)
- **Win Rate**: Percentage of winning trades when filter is applied
- **Trades**: How many trades remain (check this isn't too low!)
- **Expectancy**: Average profit per trade

**Action:** 
- Pick thresholds with **>10% win rate improvement** AND **>50 trades remaining**
- Avoid filters that reduce trade count below ~30 (overfitting risk)

---

### 3. **Win Probability Tables**

**What it shows:**
- Win rate across different metric ranges (quintiles)
- Where the "sweet spot" is for each metric

**Example Table (EntryAccel):**
```
Range                  Count  AvgProfit  WinRate%  Expectancy
(-0.002, -0.0005]        98      -8.45     32.7%      -8.45
(-0.0005, 0.0001]       102      -2.12     45.1%      -2.12
(0.0001, 0.0008]        105       5.23     55.2%       5.23
(0.0008, 0.0015]         97      12.67     67.0%      12.67
(0.0015, 0.0050]         88      18.34     75.0%      18.34
```

**How to read:**
- **Top range has highest win rate** → Use that range's lower bound as threshold
- **Progressive improvement** → Metric is a good predictor
- **Random distribution** → Metric is not useful

**Action:** If you see a clear progression (like above), use the threshold where win rate jumps significantly.

---

### 4. **Multi-Metric Combinations**

**What it shows:**
- Performance when combining multiple filters (AND logic)
- Best synergistic pairs or triplets

**Example Output:**
```
Baseline Win Rate: 50.0%

1. EntryAccel > 0.0012 AND RunUp > 15.0
   Trades:   87  Win Rate: 78.2% (+28.2%)
   Total: $1,234.56  Avg: $14.19

2. EntryMomentum > 0.0034 AND MAE < -8.0
   Trades:  112  Win Rate: 71.4% (+21.4%)
   Total: $1,567.89  Avg: $14.00

3. EntryAccel > 0.0012
   Trades:  247  Win Rate: 68.3% (+18.3%)
   Total: $3,075.15  Avg: $12.45
```

**How to read:**
- **Higher in list = better performance**
- **Trade-off**: Combining filters increases win rate BUT reduces trade count
- **#1 is best combo** by win rate (but check trade count!)

**Decision Matrix:**
| Combination | Win Rate | Trade Count | Best For |
|-------------|----------|-------------|----------|
| Single filter | Good | High | Volume trading, conservative |
| 2 filters | Better | Medium | Balanced approach |
| 3+ filters | Best | Low | Selective, high-confidence trades |

**Action:** Start with top single filter, then test top 2-filter combo if trade count is still healthy.

---

### 5. **JSON Configuration**

**What it shows:**
- Machine-readable config for self-learning EA
- Recommended filters with expected performance
- Baseline vs optimized comparison

**Example JSON:**
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

**Action:** 
- Use `recommended_filters` to update EA inputs manually
- Feed entire JSON to self-learning module for automated optimization

---

## 🎯 Step-by-Step Workflow

### Phase 1: Baseline (No Physics Filters)

1. **Backtest with MA entry only**
   - All physics metrics logged but not used for filtering
   - Establishes baseline performance

2. **Run analytics script**
   ```bash
   python analyze_backtest_advanced.py data/baseline.csv --output-dir reports/baseline
   ```

3. **Identify top 3 predictive metrics**
   - Look at correlation analysis
   - Check threshold optimization
   - Note recommended filters

### Phase 2: Single-Filter Test

4. **Enable best single filter in EA**
   - Open `TP_Integrated_EA.mq5`
   - Set `UsePhysicsFilters = true`
   - Add recommended threshold to code (or make it an input)
   
   Example:
   ```mql5
   // In OnNewBar() after signal generation:
   if(signal_type != SIGNAL_NONE) {
       // Apply physics filter
       if(UsePhysicsFilters) {
           double accel = physics_indicator.GetAcceleration(0);
           if(accel <= 0.0012) {  // From JSON recommendation
               signal_type = SIGNAL_NONE;  // Filter out this trade
           }
       }
   }
   ```

5. **Re-run backtest with same date range**
   - CRITICAL: Use exact same period as baseline
   - This ensures apples-to-apples comparison

6. **Compare results**
   ```bash
   python analyze_backtest_advanced.py data/filtered_run1.csv --output-dir reports/filtered_run1
   python compare_backtests.py reports/baseline reports/filtered_run1
   ```

### Phase 3: Multi-Filter Test (If Single Filter Works)

7. **Add second filter from best combination**
   - Use top 2-metric combo from analytics
   
8. **Re-run backtest and compare**
   ```bash
   python analyze_backtest_advanced.py data/filtered_run2.csv --output-dir reports/filtered_run2
   ```

### Phase 4: Documentation & Partner Review

9. **Generate comparison report**
   - Baseline vs Single Filter vs Multi-Filter
   - Include all HTML reports
   - Highlight improvements

10. **Create presentation deck**
    - Show correlation matrices
    - Display threshold optimization results
    - Present best combinations
    - Include before/after equity curves

---

## 📈 Interpretation Guide

### What Makes a Good Filter?

✅ **Strong Filter Criteria:**
- Correlation: |r| > 0.5 (strong) or > 0.3 (moderate)
- Win rate improvement: >10% vs baseline
- Trades remaining: >50 (or >10% of baseline)
- Statistical significance: p-value < 0.05
- Consistent across date ranges (test multiple periods!)

❌ **Red Flags:**
- Win rate improvement <5% (not worth the complexity)
- Trades remaining <30 (overfitting risk)
- Large threshold changes between date ranges (unstable)
- Correlation flips sign on different data (unreliable)

### Sample Decision Tree

```
IF correlation is STRONG (|r| > 0.5) AND trades > 50:
    → Implement filter immediately
    
ELSE IF correlation is MODERATE (|r| > 0.3) AND win rate improvement > 15%:
    → Test on out-of-sample data first
    
ELSE IF multi-metric combo shows >25% improvement:
    → Test combo carefully (watch for overfitting)
    
ELSE:
    → Keep logging, wait for more data
```

---

## 🔬 Advanced Usage

### Custom Percentiles for Threshold Optimization

```python
# In analyze_backtest_advanced.py, modify:
analytics = TradeAnalytics(csv_path, output_dir)
analytics.run_full_analysis()

# Or call specific functions:
analytics.load_data()
analytics.correlation_analysis()

# Test custom percentiles
custom_opt = analytics.threshold_optimization('EntryAccel', percentiles=[5, 15, 25, 35, 50, 65, 75, 85, 95])
```

### Separate Winners/Losers Analysis

```python
# After loading data:
print("\n=== WINNER PHYSICS ===")
print(analytics.winners[['EntryAccel', 'EntryMomentum', 'RunUp']].describe())

print("\n=== LOSER PHYSICS ===")
print(analytics.losers[['EntryAccel', 'EntryMomentum', 'RunDown']].describe())
```

### Time-Based Analysis

```python
# Add to script:
analytics.df['Hour'] = pd.to_datetime(analytics.df['EntryTime']).dt.hour
hourly_stats = analytics.df.groupby('Hour').agg({
    'NetProfit': ['count', 'mean', 'sum'],
    'IsWinner': 'mean'
})
print(hourly_stats)
```

---

## 🤖 JSON Self-Learning Integration (Future)

The JSON config is designed to be read by the EA for automated optimization:

**Planned EA Logic:**
```mql5
// Load JSON config at startup
string json_file = "MQL5/Files/ea_config_optimized.json";
CJSONValue config;
config.Deserialize(FileReadString(json_file));

// Extract recommended filters
CJSONArray filters = config["recommended_filters"];
for(int i = 0; i < filters.Size(); i++) {
    string metric = filters[i]["metric"].ToStr();
    string op = filters[i]["operator"].ToStr();
    double threshold = filters[i]["threshold"].ToDbl();
    
    // Apply filter dynamically
    ApplyFilter(metric, op, threshold);
}

// Compare actual vs expected performance
double expected_wr = config["best_combination"]["win_rate"].ToDbl();
double actual_wr = CalculateCurrentWinRate();

if(actual_wr < expected_wr - 5.0) {
    // Performance degraded, trigger re-optimization
    RequestNewAnalytics();
}
```

---

## 📁 File Structure

```
MQL5/
├── analyze_backtest_advanced.py          ← Main analytics script
├── CORRELATION_ANALYTICS_GUIDE.md        ← This guide
├── compare_backtests.py                  ← (Future) Compare multiple runs
├── data/
│   ├── baseline.csv                      ← Baseline backtest (no filters)
│   ├── filtered_run1.csv                 ← Single-filter backtest
│   └── filtered_run2.csv                 ← Multi-filter backtest
└── reports/
    ├── baseline/
    │   ├── analytics_report.html         ← Visual report
    │   ├── ea_config_optimized.json      ← JSON config
    │   └── figures/                      ← Charts (correlation, distribution)
    ├── filtered_run1/
    └── filtered_run2/
```

---

## 🎓 Example Interpretation Session

**Scenario:** You ran a baseline backtest with 500 trades, 50% win rate.

**Step 1: Review Correlations**
```
Top Correlations:
  RunUp:           r= 0.721  Strong   ✅
  EntryAccel:      r= 0.427  Moderate ✅
  EntryMomentum:   r= 0.381  Moderate ✅
  MAE:             r=-0.589  Strong   ✅
  EntryVelocity:   r= 0.145  Weak     ❌
```
**Decision:** Focus on RunUp, EntryAccel, EntryMomentum, MAE.

**Step 2: Check Thresholds**
```
RunUp > 15.0
  Win Rate: 72.1% (+22.1%)
  Trades: 203

EntryAccel > 0.0012
  Win Rate: 68.3% (+18.3%)
  Trades: 247
```
**Decision:** Both look good! EntryAccel has more trades, RunUp has higher win rate.

**Step 3: Test Combination**
```
RunUp > 15.0 AND EntryAccel > 0.0012
  Win Rate: 78.2% (+28.2%)
  Trades: 87
```
**Decision:** Combo is powerful but reduces trades to 87 (17% of baseline). May be too aggressive.

**Step 4: Choose Implementation**
- **Conservative:** Start with `EntryAccel > 0.0012` (247 trades, 68.3% WR)
- **Balanced:** Add `RunUp > 15.0` if EntryAccel test succeeds (87 trades, 78.2% WR)
- **Research:** Test `MAE < -8.0` as exit filter instead of entry filter

**Step 5: Backtest & Validate**
- Run filtered backtest on SAME date range
- Run filtered backtest on DIFFERENT date range (out-of-sample)
- If both show improvement → Deploy to live
- If out-of-sample fails → May be overfitting, collect more data

---

## ⚠️ Common Pitfalls

1. **Overfitting on Small Sample**
   - Solution: Require >100 trades for threshold optimization
   - Cross-validate on multiple date ranges

2. **P-Hacking (Testing Too Many Metrics)**
   - Solution: Limit to pre-defined physics metrics only
   - Use Bonferroni correction for multiple comparisons

3. **Survivorship Bias**
   - Solution: Include all trades (winners AND losers)
   - Never filter CSV before analytics

4. **Changing Market Conditions**
   - Solution: Re-run analytics monthly
   - Monitor "expected vs actual" performance drift

5. **Combining Correlated Filters**
   - Solution: Check correlation matrix between metrics
   - Avoid combining highly correlated filters (redundant)

---

## 🚀 Next Steps

1. **Run baseline backtest** (physics logged, filters OFF)
2. **Execute analytics script** on baseline CSV
3. **Review HTML report** and identify top metrics
4. **Implement best single filter** in EA
5. **Re-run backtest** and compare
6. **Document results** for partner review
7. **Test multi-metric combos** if single filter works
8. **Build self-learning module** to automate this loop

---

## 📞 Questions?

Review the HTML report for visual explanations and refer to:
- `ANALYTICS_FRAMEWORK.md` - High-level workflow
- `FAST_TEST_GUIDE.md` - Backtest setup instructions
- JSON config - Recommended filter settings

**Goal:** Find filters that consistently improve win rate by >10% across multiple date ranges, with >50 trades remaining.

Once validated, these filters become your EA's "intelligence layer" for trade selection! 🧠✨
