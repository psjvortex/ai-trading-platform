# Backtest Run Tracking & Analytics Workflow

## Problem: Multiple Backtests Mixing Data

### Current State (v1.2)
**Filename Format:**
```
TP_Integrated_Trades_NAS100_v1.2.csv
TP_Integrated_Signals_NAS100_v1.2.csv
```

**What's Tracked:**
- ✅ Symbol (NAS100)
- ✅ EA Version (1.2)

**What's NOT Tracked:**
- ❌ Timeframe (M5, H1, H4, etc.)
- ❌ Backtest run date/time
- ❌ Backtest period (Aug vs Sep)
- ❌ Configuration changes (MA 10/50 vs 20/100)

**Problem Scenario:**
```
Run 1: NAS100, M5,  MA 10/50, Aug 1-29  → 145 trades written
Run 2: NAS100, H1,  MA 10/50, Aug 1-29  → APPENDS 80 trades  = 225 mixed!
Run 3: NAS100, M5,  MA 20/100, Aug 1-29 → APPENDS 98 trades  = 323 mixed!
```

Your analytics will see 323 trades but can't tell which came from which configuration!

---

## Solution Options

### Option 1: Add Timeframe to Filename (Recommended)
**Filename Format:**
```
TP_Integrated_Trades_NAS100_M5_v1.2.csv
TP_Integrated_Trades_NAS100_H1_v1.2.csv
TP_Integrated_Trades_NAS100_H4_v1.2.csv
```

**Pros:**
- ✅ Separates different timeframes automatically
- ✅ Easy to identify and compare
- ✅ Minimal code changes

**Cons:**
- ⚠️ Still mixes multiple runs on same timeframe
- ⚠️ Can't distinguish MA 10/50 vs MA 20/100

**Code Change Required:**
```cpp
// In OnInit()
string timeframe = GetTimeframeName();
loggerConfig.signalLogFile = "TP_Integrated_Signals_" + _Symbol + "_" + timeframe + "_v" + EA_VERSION + ".csv";
loggerConfig.tradeLogFile = "TP_Integrated_Trades_" + _Symbol + "_" + timeframe + "_v" + EA_VERSION + ".csv";
```

---

### Option 2: Add Full Timestamp (Most Precise)
**Filename Format:**
```
TP_Integrated_Trades_NAS100_M5_v1.2_20251104_143022.csv
                                      └── YYYYMMDD_HHMMSS
```

**Pros:**
- ✅ Every backtest run = unique file
- ✅ Never mix data
- ✅ Full audit trail

**Cons:**
- ⚠️ Lots of files to manage
- ⚠️ Need to specify which file to analyze

**Code Change:**
```cpp
// In OnInit()
string timeframe = GetTimeframeName();
string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
StringReplace(timestamp, ":", "");
StringReplace(timestamp, ".", "");
StringReplace(timestamp, " ", "_");

loggerConfig.signalLogFile = "TP_Integrated_Signals_" + _Symbol + "_" + timeframe + "_v" + EA_VERSION + "_" + timestamp + ".csv";
```

---

### Option 3: Use Overwrite Mode (Simple)
**Change:**
```cpp
loggerConfig.appendMode = false;  // Overwrite instead of append
```

**Pros:**
- ✅ Simple - one line change
- ✅ Latest run always replaces old data

**Cons:**
- ⚠️ Loses historical runs
- ⚠️ Can't compare different configurations

---

### Option 4: Add Config Hash (Advanced)
**Filename Format:**
```
TP_Integrated_Trades_NAS100_M5_v1.2_cfg_A3F2.csv
                                          └── Hash of MA_Fast, MA_Slow, etc.
```

**Pros:**
- ✅ Different configs = different files
- ✅ Can compare MA 10/50 vs MA 20/100
- ✅ Timestamp-independent

**Cons:**
- ⚠️ More complex to implement
- ⚠️ Need to track config parameters

---

## Recommended Approach: Option 1 + Metadata

### Implementation:

1. **Add Timeframe to Filename**
   ```
   TP_Integrated_Trades_NAS100_M5_v1.2.csv
   ```

2. **Add Metadata Columns to CSV**
   Already have:
   - ✅ EAName
   - ✅ EAVersion
   
   Add to both Signal and Trade CSVs:
   - `Timeframe` (M5, H1, etc.)
   - `BacktestStartDate` (first bar)
   - `BacktestEndDate` (last bar)
   - `MA_Fast` (10)
   - `MA_Slow` (50)

3. **Python Analytics Detects Multiple Runs**
   ```python
   # Group by backtest period
   runs = df.groupby(['BacktestStartDate', 'BacktestEndDate', 'MA_Fast', 'MA_Slow'])
   
   print(f"Found {len(runs)} separate backtest runs in this file:")
   for (start, end, fast, slow), group in runs:
       print(f"  Run: {start} to {end} | MA {fast}/{slow} | {len(group)} trades")
   ```

---

## Quick Fix for Your Next Run

### Before Next Backtest:
**Option A - Manual rename (Quick):**
```bash
# Rename current files to archive them
mv TP_Integrated_Trades_NAS100_v1.2.csv \
   TP_Integrated_Trades_NAS100_M5_v1.2_Aug_baseline.csv

mv TP_Integrated_Signals_NAS100_v1.2.csv \
   TP_Integrated_Signals_NAS100_M5_v1.2_Aug_baseline.csv
```

**Option B - Change to overwrite mode:**
```cpp
// In TP_Integrated_EA.mq5, OnInit()
loggerConfig.appendMode = false;  // Change from true to false
```

**Option C - Update to v1.3 with timeframe:**
```cpp
#property version   "1.3"
#define EA_VERSION "1.3"

// Add helper function
string GetTimeframeName()
{
   switch(_Period)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default: return "UNKNOWN";
   }
}

// In OnInit()
string timeframe = GetTimeframeName();
loggerConfig.signalLogFile = "TP_Integrated_Signals_" + _Symbol + "_" + timeframe + "_v" + EA_VERSION + ".csv";
loggerConfig.tradeLogFile = "TP_Integrated_Trades_" + _Symbol + "_" + timeframe + "_v" + EA_VERSION + ".csv";
```

---

## Long-term Solution: Backtest Run Registry

Create a **backtest_runs.csv** that tracks:
```csv
RunID,Date,Symbol,Timeframe,Version,MA_Fast,MA_Slow,StartDate,EndDate,TotalTrades,Profit,TradeFile,SignalFile
1,2025-11-04,NAS100,M5,1.2,10,50,2025-08-01,2025-08-29,145,3.77,TP_..._run1.csv,TP_..._run1.csv
2,2025-11-04,NAS100,H1,1.2,10,50,2025-08-01,2025-08-29,87,12.45,TP_..._run2.csv,TP_..._run2.csv
3,2025-11-05,NAS100,M5,1.3,20,100,2025-08-01,2025-08-29,98,-5.23,TP_..._run3.csv,TP_..._run3.csv
```

This gives you a **master index** of all backtest runs for comparison and analysis.

---

## Immediate Action Required

**For your next backtest run, do ONE of:**

1. ✅ **Manually rename current CSV files** (add `_M5_Aug_baseline` suffix)
2. ✅ **Change `appendMode = false`** to overwrite
3. ✅ **Update EA to v1.3** with timeframe in filename

**Recommendation:** Go with Option 3 (update to v1.3) for institutional-grade tracking.

Would you like me to implement the v1.3 update now?
