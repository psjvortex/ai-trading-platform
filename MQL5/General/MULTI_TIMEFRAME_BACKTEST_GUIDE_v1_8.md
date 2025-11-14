# Multi-Timeframe Backtest Guide - v1.8a-d

**Date:** November 4, 2025  
**Objective:** Run systematic backtests across M5, M30, H1, H4 timeframes to identify optimal trading timeframe for MA crossover baseline strategy.

---

## 📋 Overview

We will run 4 backtest versions with identical parameters except for timeframe:
- **v1.8a:** M5 (5 minutes)
- **v1.8b:** M30 (30 minutes)
- **v1.8c:** H1 (1 hour)
- **v1.8d:** H4 (4 hours)

### Common Parameters (Baseline MA Crossover)
- **Symbol:** NAS100 (US Tech 100)
- **Period:** 2024.01.01 - 2024.12.31 (full year)
- **Initial Deposit:** $1,000
- **Entry Logic:** MA Crossover (ENABLED)
- **Physics Filters:** DISABLED (baseline)
- **Fast MA Period:** 10
- **Slow MA Period:** 50
- **Risk per Trade:** 1% of equity
- **Stop Loss:** 100 points
- **Take Profit:** 200 points (2:1 R:R)

---

## 🔧 MT5 Setup Instructions

### Step 1: Update EA Version in Code

Before each backtest, update the version string in `TP_Integrated_EA.mq5`:

```mql5
// At the top of TP_Integrated_EA.mq5
#define EA_VERSION "1.8a"  // Change to 1.8b, 1.8c, 1.8d for each run
```

### Step 2: Compile EA

1. Open MetaEditor
2. Open `TP_Integrated_EA.mq5`
3. Press F7 to compile
4. Confirm "0 error(s), 0 warning(s)"

### Step 3: Run Backtest in Strategy Tester

1. **Open Strategy Tester** (Ctrl+R or View → Strategy Tester)
2. **Select Expert Advisor:** TP_Integrated_EA
3. **Configure Settings:**
   - **Symbol:** NAS100
   - **Timeframe:** [M5/M30/H1/H4] ← Change for each version
   - **Period:** 2024.01.01 00:00 to 2024.12.31 23:59
   - **Deposit:** 1000
   - **Execution:** Every tick based on real ticks
   - **Optimization:** Disabled

4. **EA Input Parameters:**
   ```
   UseMAEntry = true
   FastMAPeriod = 10
   SlowMAPeriod = 50
   RiskPercent = 1.0
   StopLossPips = 100
   TakeProfitPips = 200
   UsePhysicsFilters = false
   ```

5. **Click "Start"** and wait for completion

### Step 4: Export Results

After each backtest completes:

1. **Export MT5 Report:**
   - Right-click on backtest result → "Report" → "Save as Detailed Report"
   - Save as: `MTBacktest_Report_1_8[a/b/c/d].html`
   - Also: Right-click → "Open XML" → Save as CSV
   - Save as: `MTBacktest_Report_1_8[a/b/c/d].csv`
   - Location: `/Users/patjohnston/ai-trading-platform/MQL5/MT5 Excel Reports/`

2. **Locate CSV Files:**
   - CSV files are auto-generated in MT5 Tester directory
   - Path: `C:\Users\[User]\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Files\`
   - Or: `~/Library/Application Support/com.metaquotes.metatrader5/Bottles/metatrader5/drive_c/users/[user]/AppData/Roaming/MetaQuotes/Terminal/[ID]/MQL5/Files/` (macOS)
   - Files will be named:
     - `TP_Integrated_Trades_NAS100_M5_v1_8a.csv`
     - `TP_Integrated_Signals_NAS100_M5_v1_8a.csv`
     - (etc. for each version/timeframe)

---

## 📊 Backtest Execution Checklist

### v1.8a - M5 (5 Minutes)
- [ ] Update EA_VERSION to "1.8a"
- [ ] Compile EA (F7)
- [ ] Set timeframe to M5 in Strategy Tester
- [ ] Run backtest (2024.01.01 - 2024.12.31)
- [ ] Export MT5 report to `MTBacktest_Report_1_8a.html` and `.csv`
- [ ] Copy CSV files from MT5 Tester directory to workspace
- [ ] Run analytics script: `python copy_backtest_csvs.py 1.8a M5`

### v1.8b - M30 (30 Minutes)
- [ ] Update EA_VERSION to "1.8b"
- [ ] Compile EA (F7)
- [ ] Set timeframe to M30 in Strategy Tester
- [ ] Run backtest (2024.01.01 - 2024.12.31)
- [ ] Export MT5 report to `MTBacktest_Report_1_8b.html` and `.csv`
- [ ] Copy CSV files from MT5 Tester directory to workspace
- [ ] Run analytics script: `python copy_backtest_csvs.py 1.8b M30`

### v1.8c - H1 (1 Hour)
- [ ] Update EA_VERSION to "1.8c"
- [ ] Compile EA (F7)
- [ ] Set timeframe to H1 in Strategy Tester
- [ ] Run backtest (2024.01.01 - 2024.12.31)
- [ ] Export MT5 report to `MTBacktest_Report_1_8c.html` and `.csv`
- [ ] Copy CSV files from MT5 Tester directory to workspace
- [ ] Run analytics script: `python copy_backtest_csvs.py 1.8c H1`

### v1.8d - H4 (4 Hours)
- [ ] Update EA_VERSION to "1.8d"
- [ ] Compile EA (F7)
- [ ] Set timeframe to H4 in Strategy Tester
- [ ] Run backtest (2024.01.01 - 2024.12.31)
- [ ] Export MT5 report to `MTBacktest_Report_1_8d.html` and `.csv`
- [ ] Copy CSV files from MT5 Tester directory to workspace
- [ ] Run analytics script: `python copy_backtest_csvs.py 1.8d H4`

---

## 🔄 Copy CSVs to Workspace

After each backtest, use the automated copy script:

```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
python copy_backtest_csvs.py [version] [timeframe]
```

Examples:
```bash
python copy_backtest_csvs.py 1.8a M5
python copy_backtest_csvs.py 1.8b M30
python copy_backtest_csvs.py 1.8c H1
python copy_backtest_csvs.py 1.8d H4
```

This will copy files to:
- `analytics_output/data/backtest/TP_Integrated_Trades_NAS100_[TF]_v[VER].csv`
- `analytics_output/data/backtest/TP_Integrated_Signals_NAS100_[TF]_v[VER].csv`

---

## 📈 Analytics Pipeline

After all 4 backtests are complete and CSVs copied:

### 1. Individual Analysis
Run comprehensive analysis for each version:

```bash
python analyze_backtest_comprehensive.py 1.8a M5
python analyze_backtest_comprehensive.py 1.8b M30
python analyze_backtest_comprehensive.py 1.8c H1
python analyze_backtest_comprehensive.py 1.8d H4
```

### 2. Multi-Version Comparison
Create comparison report across all timeframes:

```bash
python compare_multi_timeframe.py  # (to be created)
```

### 3. Dashboard Generation
Generate partner-ready dashboard with all results:

```bash
python generate_dashboard_v1_8.py  # (to be created)
```

---

## 📝 Expected Outcomes

### Key Metrics to Track
- **Total Trades:** How many signals generated?
- **Win Rate:** % profitable trades
- **Profit Factor:** Gross profit / Gross loss
- **Sharpe Ratio:** Risk-adjusted returns
- **Max Drawdown:** Worst peak-to-trough decline
- **Net P&L:** Total profit/loss
- **Avg Trade Duration:** How long are positions held?

### Timeframe Expectations
- **M5:** More trades, more noise, potentially overtrading
- **M30:** Balanced frequency, reduced noise
- **H1:** Fewer trades, more significant moves
- **H4:** Lowest trade frequency, strongest trends

### Success Criteria
- At least one timeframe achieves positive net P&L
- Identify timeframe with best Sharpe ratio
- Understand trade frequency vs quality tradeoff
- Establish baseline for MA period optimization (v1.9)

---

## 🎯 Next Steps After v1.8 Series

1. **Analyze Results:** Identify best-performing timeframe
2. **Document Findings:** Create comparison report
3. **Optimize MA Periods (v1.9):** Run parameter sweep on best timeframe
4. **Integrate Physics Filters (v2.0):** Add momentum/acceleration logic
5. **Partner Presentation:** Build institutional-grade dashboard

---

## 📌 Important Notes

- **Version Tracking:** Each EA version MUST have correct version string in code
- **CSV Naming:** Automatic - EA handles filename generation
- **MT5 Terminal ID:** Find yours by checking MT5 Tester folder path
- **Backtest Duration:** Each run may take 10-30 minutes depending on timeframe
- **Data Quality:** Ensure you have full year of historical data for NAS100
- **Validation:** Always cross-check CSV vs MT5 report for accuracy

---

## ✅ Quick Reference

| Version | Timeframe | CSV Files Expected |
|---------|-----------|-------------------|
| v1.8a   | M5        | `TP_Integrated_Trades_NAS100_M5_v1_8a.csv` <br> `TP_Integrated_Signals_NAS100_M5_v1_8a.csv` |
| v1.8b   | M30       | `TP_Integrated_Trades_NAS100_M30_v1_8b.csv` <br> `TP_Integrated_Signals_NAS100_M30_v1_8b.csv` |
| v1.8c   | H1        | `TP_Integrated_Trades_NAS100_H1_v1_8c.csv` <br> `TP_Integrated_Signals_NAS100_H1_v1_8c.csv` |
| v1.8d   | H4        | `TP_Integrated_Trades_NAS100_H4_v1_8d.csv` <br> `TP_Integrated_Signals_NAS100_H4_v1_8d.csv` |

---

**Status:** Ready to execute  
**Estimated Time:** 2-3 hours (including all backtests and data transfer)  
**Prerequisites:** MT5 installed, EA compiled, historical data available  

---

*Last Updated: November 4, 2025*
