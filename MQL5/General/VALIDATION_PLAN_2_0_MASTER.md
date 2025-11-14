# 2_0_Master Validation Plan - November 5, 2025

## ✅ Code Updates Applied

### 1. **EA Version Updated**
- Property version: `1.2` → `2.0`
- EA_VERSION: `"1.2"` → `"2_0"`

### 2. **Timeframe Tracking Added**
- Added `GetTimeframeName()` function
- CSV filenames now include timeframe: `TP_Integrated_Trades_NAS100_M15_v2_0.csv`
- OnInit() now displays timeframe in configuration

### 3. **CSV Logging Enhanced**
- Trade CSV includes timeframe in filename
- Signal CSV includes timeframe in filename
- Full EA name/version tracking in both CSVs

---

## 📋 Validation Workflow

### **STEP 1: Short Backtest (Validation)**

**MT5 Setup:**
```
Expert Advisor: TP_Integrated_EA_Crossover_2_0_Master
Symbol:         NAS100
Timeframe:      M15
Period:         2024.01.01 - 2024.01.31 (1 month)
Deposit:        $1,000
Execution:      Every tick based on real ticks

Parameters:
  - UseMAEntry = true
  - UsePhysicsFilters = false
  - MA_Fast = 10
  - MA_Slow = 50
  - RiskPercentPerTrade = 10.0
  - StopLossPips = 5000
  - TakeProfitPips = 10000
```

**After Backtest:**
1. Export MT5 report → Save as `MTBacktest_Report_2_0_validation.html`
2. Export MT5 CSV → Right-click backtest → Open XML → Save as `MTBacktest_Report_2_0_validation.csv`
3. Copy both to: `/Users/patjohnston/ai-trading-platform/MQL5/MT5 Excel Reports/`

---

### **STEP 2: Copy CSV Files from MT5 Tester**

**MT5 CSV Location (macOS via Wine):**
```
~/Library/Application Support/com.metaquotes.metatrader5/Bottles/
  metatrader5/drive_c/users/[user]/AppData/Roaming/MetaQuotes/
  Terminal/[TERMINAL_ID]/MQL5/Files/
```

**Files to Copy:**
- `TP_Integrated_Trades_NAS100_M15_v2_0.csv`
- `TP_Integrated_Signals_NAS100_M15_v2_0.csv`

**Copy to:**
```
/Users/patjohnston/ai-trading-platform/MQL5/analytics_output/data/backtest/
```

**Terminal Command:**
```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
# Find your Terminal ID first
ls ~/Library/Application\ Support/com.metaquotes.metatrader5/Bottles/metatrader5/drive_c/users/*/AppData/Roaming/MetaQuotes/Terminal/

# Then copy (replace [TERMINAL_ID] with actual ID)
cp ~/Library/Application\ Support/com.metaquotes.metatrader5/Bottles/metatrader5/drive_c/users/*/AppData/Roaming/MetaQuotes/Terminal/[TERMINAL_ID]/MQL5/Files/TP_Integrated*.csv analytics_output/data/backtest/
```

---

### **STEP 3: Run Validation Script**

```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
python validate_2_0_master.py
```

**What This Checks:**
- ✅ CSV file structure (all required columns)
- ✅ EA name/version tracking
- ✅ Trade count (TP vs MT5)
- ✅ P&L accuracy (TP vs MT5)
- ✅ Exit reason distribution (SL/TP/REVERSAL)
- ✅ MFE/MAE/RunUp/RunDown logging
- ✅ Signal logging (BUY/SELL/NONE distribution)

**Expected Output:**
```
✅ ✅ ✅  PERFECT! All validations passed!

🚀 Ready for full year 2024 backtest!
```

---

### **STEP 4: Review and Confirm**

Once validation passes:
1. Share validation script output with me
2. Share MT5 HTML report screenshot (first 10 trades)
3. I'll confirm everything looks good
4. Proceed to full year 2024 backtest

---

## 📊 Expected CSV Structure

### **Trade CSV Columns:**
```
eaName, eaVersion, ticket, openTime, closeTime, symbol, type, lots, 
openPrice, closePrice, sl, tp, entryQuality, entryConfluence, 
entryMomentum, entryEntropy, entryZone, entryRegime, entrySpread,
exitReason, exitQuality, exitConfluence, exitZone, exitRegime,
profit, profitPercent, pips, holdTimeBars, holdTimeMinutes,
riskPercent, rRatio, slippage, commission,
mfe, mae, mfePercent, maePercent, mfePips, maePips, mfeTimeBars, maeTimeBars,
runUpPrice, runUpPips, runUpPercent, runUpTimeBars,
runDownPrice, runDownPips, runDownPercent, runDownTimeBars,
balanceAfter, equityAfter, drawdownPercent,
entryHour, entryDayOfWeek, exitHour, exitDayOfWeek
```

### **Signal CSV Columns:**
```
eaName, eaVersion, timestamp, symbol, signal, signalType,
quality, confluence, momentum, speed, acceleration, entropy, jerk,
zone, regime, price, spread, highThreshold, lowThreshold,
balance, equity, openPositions, physicsPass, rejectReason,
hour, dayOfWeek
```

---

## 🎯 Success Criteria

### **Must Pass:**
- [x] EA compiles without errors
- [x] CSV files generated with correct names
- [x] Trade count matches MT5 report
- [x] P&L matches MT5 report (within $1.00)
- [x] All exit reasons logged correctly
- [x] MFE/MAE/RunUp/RunDown all populated
- [x] EA name/version in every row

### **Once Validated:**
- [ ] Run full year backtest (2024.01.01 - 2024.12.31)
- [ ] Generate comprehensive analytics report
- [ ] Compare against baseline expectations

---

## 📝 Notes

### **MA Crossover Logic (Your Improvement):**
```cpp
// Uses bar[2] and bar[0] to avoid simultaneous crossovers
if(maFast[2] < maSlow[2] && maFast[0] > maSlow[0])  // BUY
if(maFast[2] >= maSlow[2] && maFast[0] < maSlow[0]) // SELL
```

**Benefits:**
- Eliminates bars where both MAs cross simultaneously
- Cleaner entry/exit signals
- Consistent with your 90-trade validation observation

### **Post-Exit Monitoring:**
- RunUp/RunDown tracking enabled (50 bars)
- Captures how far price moves after exit
- Critical for identifying premature exits

### **Risk Parameters:**
- 10% risk per trade (very aggressive for validation)
- 5000/10000 pip SL/TP (very wide for NAS100)
- Should adjust for production (1% risk, 50/100 pips)

---

## 🚀 Ready for Validation!

**Next Steps:**
1. Compile `TP_Integrated_EA_Crossover_2_0_Master` in MT5
2. Run 1-month backtest (Jan 2024)
3. Export MT5 reports
4. Copy CSVs to workspace
5. Run validation script
6. Share results with me

**I'm ready to walk through each step with you!** 🎯
