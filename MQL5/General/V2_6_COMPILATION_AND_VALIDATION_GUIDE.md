# TickPhysics EA v2.6 - Compilation & Validation Guide

## 🎯 Overview
Version 2.6 represents the **self-improving/iterative optimization** phase of the TickPhysics EA:
- **v2.4**: Baseline MA crossover (no filters)
- **v2.5**: Added zone/regime filters (73% signals rejected, +$732 profit improvement)
- **v2.6**: Added time-of-day and day-of-week filters (data-driven from v2.5 analysis)

## 📋 Pre-Flight Checklist

### 1. Verify File Location
```bash
# EA should be in MT5 Experts folder
/Users/patjohnston/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_2_6.mq5
```

### 2. Copy EA to MT5 (if needed)
```bash
# Copy from project to MT5
cp "/Users/patjohnston/ai-trading-platform/MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_2_6.mq5" \
   "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/TickPhysics/"
```

### 3. Verify Dependencies
All required libraries should already be in place:
- `TP_Physics_Indicator.mqh`
- `TP_Risk_Manager.mqh`
- `TP_Trade_Tracker.mqh`
- `TP_CSV_Logger.mqh`

## 🔨 Compilation Steps

### In MetaTrader 5:

1. **Open MetaEditor**
   - Press F4 in MT5, or click Tools → MetaQuotes Language Editor

2. **Navigate to EA**
   - Navigator → MQL5 → Experts → TickPhysics → TP_Integrated_EA_Crossover_2_6.mq5

3. **Compile**
   - Press F7 or click Compile button
   - Check for errors in the Errors tab
   - Expected result: `0 error(s), 0 warning(s)` ✅

4. **Verify Compilation Success**
   - Should see message: `TP_Integrated_EA_Crossover_2_6.mq5 compiled successfully`
   - A `.ex5` file should be created in the same directory

## 🚀 Backtest Configuration

### Strategy Tester Settings:

#### Basic Settings
- **Expert Advisor**: TP_Integrated_EA_Crossover_2_6.mq5
- **Symbol**: NAS100 (or US100)
- **Period**: M15 (15-minute)
- **Date Range**: 2025.01.01 - 2025.09.30 (9 months)
- **Deposit**: $10,000
- **Leverage**: 1:100

#### EA Input Parameters

**Risk Management**
- Risk per trade: 1.0%
- Max daily risk: 3.0%
- Max concurrent trades: 3
- Min R:R ratio: 1.5

**Trade Parameters**
- Stop loss: 50 pips
- Take profit: 100 pips
- Trailing stop: OFF (false)

**Entry Logic**
- Use Physics Entry: FALSE ❌
- Use MA Entry: TRUE ✅
- MA Fast: 10
- MA Slow: 50
- MA Method: EMA
- MA Price: Close

**Physics Filters (v2.5 - Proven)**
- ✅ Use Physics Filters: TRUE
- ✅ Min Quality: **70.0** (increased from 65.0 in v2.5)
- ✅ Min Confluence: 70.0
- ✅ Use Zone Filter: TRUE (avoid BEAR)
- ✅ Use Regime Filter: TRUE (avoid LOW volatility)

**Time Filters (v2.6 - NEW)**
- ✅ Use Time Filter: TRUE
- Allowed Hours: `11,13,14,18,20,21` (best performing hours from v2.5)
- Blocked Hours: `1,12,15` (worst performing hours from v2.5)
- ✅ Use Day Filter: TRUE
- ✅ Avoid Wednesday: TRUE (25.7% win rate in v2.5)

**Monitoring**
- Post-exit monitor bars: 50
- Enable real-time logging: TRUE

**Advanced**
- Debug mode: TRUE
- Magic number: 777888

### Visual Verification
- Visualization: ON (to see MA lines and trade entries)
- Model: Every tick (most accurate)

## 📊 Expected CSV Output

After backtest completes, check for these files:

### Location
```bash
# Backtest CSV files
/Users/patjohnston/Library/Application\ Support/net.metaquotes.wine.metatrader5/drive_c/Program\ Files/MetaTrader\ 5/Tester/Agent-127.0.0.1-3001/MQL5/Files/

# Expected files:
TP_Integrated_Signals_NAS100_v2.6.csv
TP_Integrated_Trades_NAS100_v2.6.csv
```

### Verify CSV Creation
```bash
# List CSV files
ls -lh "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3001/MQL5/Files/"TP_*v2.6*

# Copy to working directory for analysis
cp "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3001/MQL5/Files/TP_Integrated_"*"_v2.6.csv" \
   /Users/patjohnston/ai-trading-platform/MQL5/
```

## 📈 Export MT5 Report

### Manual Export Steps:
1. Right-click on backtest result in Strategy Tester
2. Select "Report" → "Save as Detailed Report"
3. Save as: `MTBacktest_Report_2.6.csv`
4. Copy to: `/Users/patjohnston/Desktop/MT5 Backtest CSV's/`

## ✅ Validation Steps

### 1. Quick Validation
```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
python3 quick_validate.py
```

This will:
- Locate all v2.6 CSV files
- Count trades in TickPhysics CSV
- Count trades in MT5 report
- Show any discrepancies

### 2. Detailed Comparison (v2.5 vs v2.6)
```bash
python3 compare_v25_v26.py
```

Expected to create:
- `V2_5_vs_V2_6_COMPARISON.md`

Should show:
- Reduced number of trades (more filtering)
- Higher win rate
- Better profit factor
- Improved total P&L

### 3. MT5 Report Comparison
```bash
python3 quick_compare_mt5_reports.py
```

This will compare:
- v2.4 baseline (no filters)
- v2.5 (zone/regime filters)
- v2.6 (zone/regime + time filters)

## 🎯 Success Criteria

### v2.6 should outperform v2.5:
- ✅ Higher Win Rate (target: >50%)
- ✅ Better Profit Factor (target: >1.3)
- ✅ Positive Total P&L (target: >$1,000)
- ✅ Fewer total trades (more selective)
- ✅ Lower max drawdown

### Data Integrity:
- ✅ CSV trade count matches MT5 report (±2 trades acceptable)
- ✅ All trades have complete physics metrics
- ✅ All trades have hour/day-of-week stamps
- ✅ All rejected signals are logged

## 📝 Troubleshooting

### If Compilation Fails:
1. Check that all `.mqh` library files are present in `Include/TickPhysics/`
2. Verify no syntax errors in v2.6 EA
3. Try compiling dependencies first (libraries)
4. Check MetaEditor Errors tab for specific line numbers

### If CSVs Not Created:
1. Check EA initialization messages in Journal tab
2. Verify "Enable real-time logging" is TRUE
3. Check file permissions on MQL5/Files directory
4. Look for error messages about file creation

### If Trade Count Mismatch:
- Small discrepancies (1-3 trades) are acceptable
- Check for trades opened but not closed before backtest end
- Verify magic number matches (777888)
- Check if duplicate close attempts are logged twice

### If v2.6 Doesn't Outperform v2.5:
- Review time filter configuration (hours might be too restrictive)
- Check that physics filters are still enabled
- Verify Wednesday blocking is active
- Consider adjusting MinQuality threshold

## 📁 File Organization

After successful validation, organize files:

```bash
# Create v2.6 results folder
mkdir -p /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/

# Move CSV files
mv TP_Integrated_*v2.6.csv /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/

# Move MT5 report
mv /Users/patjohnston/Desktop/MT5\ Backtest\ CSV\'s/MTBacktest_Report_2.6.csv \
   /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/

# Move comparison reports
mv V2_5_vs_V2_6_COMPARISON.md /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/
```

## 🔄 Next Steps (After v2.6 Validation)

If v2.6 outperforms v2.5:

### Phase 1: JSON Configuration Layer
1. Create `TickPhysics_Config_v2.7.json` with all EA parameters
2. Implement JSON reader in EA
3. Test dynamic parameter loading

### Phase 2: Automated Learning
1. Create Python service to analyze trade results
2. Generate updated JSON config automatically
3. Implement EA config refresh (after N trades or daily)

### Phase 3: Full Autonomy
1. EA reads JSON → executes trades → logs results
2. Python analyzes → generates new JSON → EA reloads
3. Document learning loop metrics (improvement rate, convergence)

### Phase 4: Partner Presentation
1. Create executive summary of v2.4 → v2.5 → v2.6 progression
2. Demonstrate self-learning capability
3. Show roadmap to full automation

## 📞 Support

If issues persist:
- Review conversation history for similar problems/solutions
- Check MT5 Journal and Experts tabs for detailed error messages
- Verify all file paths are correct for macOS/Wine MT5 installation
- Ensure Python environment has required libraries (pandas, etc.)

---
**Version**: 2.6  
**Last Updated**: 2025-01-XX  
**Status**: Ready for compilation and backtest  
