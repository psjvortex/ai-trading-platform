# TP_CSV_Logger RunUp/RunDown Analytics Guide

**Version:** 8.0  
**Date:** November 4, 2025  
**Enhancement:** Post-Exit Trade Analysis

---

## 🎯 Purpose

The RunUp/RunDown analytics enhancement adds **8 new fields** to the trade log to track how far price moves in both directions **after a trade exits**. This provides critical insights for:

- **TP Optimization:** Did we exit too early? (RunUp shows money left on table)
- **SL Optimization:** Were we shaken out before reversal? (RunDown shows what happened after stop)
- **Exit Timing:** Quantify the cost of early/late exits
- **Strategy Improvement:** Identify patterns in post-exit behavior

---

## 📊 New Fields Added to Trade Log

### RunUp Analytics (Favorable Direction)
1. **RunUp_Price** - Best price reached after exit
2. **RunUp_Pips** - Pips moved favorably after exit
3. **RunUp_Percent** - Percentage move after exit
4. **RunUp_TimeBars** - Bars until max runup occurred

### RunDown Analytics (Adverse Direction)
5. **RunDown_Price** - Worst price reached after exit
6. **RunDown_Pips** - Pips moved adversely after exit
7. **RunDown_Percent** - Percentage move after exit
8. **RunDown_TimeBars** - Bars until max rundown occurred

---

## 🔍 Key Differences: MFE/MAE vs RunUp/RunDown

| Metric | When Measured | Purpose |
|--------|---------------|---------|
| **MFE/MAE** | **During trade** (open → close) | Shows best/worst during trade lifecycle |
| **RunUp/RunDown** | **After exit** (close → N bars later) | Shows what happened AFTER we exited |

### Example: Winning Trade That Could Have Won More

```
Trade: BUY @ 3500, TP Hit @ 3550 (+50 pips profit)

During Trade (MFE/MAE):
  MFE = 3570 (best price while in trade)
  MAE = 3485 (worst price while in trade)

After Exit (RunUp/RunDown):
  RunUp_Price = 3620 (price continued +70 pips AFTER we exited!)
  RunUp_Pips = +70 pips (money left on table)
  RunDown_Price = 3545 (minor pullback after exit)
```

**Analysis:** TP was hit too early - price ran another 70 pips after exit. Consider wider TP or trailing stop.

### Example: Losing Trade That Would Have Reversed

```
Trade: SELL @ 3500, SL Hit @ 3530 (-30 pips loss)

During Trade (MFE/MAE):
  MFE = 3480 (got close to TP)
  MAE = 3550 (SL triggered)

After Exit (RunUp/RunDown):
  RunUp_Price = 3520 (minor favorable move)
  RunDown_Price = 3460 (reversed to where TP was!)
  RunDown_Pips = -70 pips (would have been profit)
  RunDown_TimeBars = 45 (reversal happened 45 bars later)
```

**Analysis:** Got shaken out before reversal. SL too tight or need better entry timing.

---

## 💻 Code Structure

### TradeLogEntry Struct (New Fields)

```cpp
struct TradeLogEntry
{
   // ... existing 45 fields ...
   
   // Post-Exit Analysis (RunUp/RunDown) - After Trade Closes
   double runUpPrice;           // Best price after exit
   double runUpPips;            // Pips moved favorably after exit
   double runUpPercent;         // % move after exit
   int runUpTimeBars;           // Bars until max runup
   
   double runDownPrice;         // Worst price after exit
   double runDownPips;          // Pips moved adversely after exit
   double runDownPercent;       // % move after exit
   int runDownTimeBars;         // Bars until max rundown
   
   // ... remaining fields ...
};
```

### CSV Header (53 Columns Total)

```
Ticket, OpenTime, CloseTime, Symbol, Type,
Lots, OpenPrice, ClosePrice, SL, TP,
EntryQuality, EntryConfluence, EntryMomentum, EntryEntropy,
EntryZone, EntryRegime, EntrySpread,
ExitReason, ExitQuality, ExitConfluence, ExitZone, ExitRegime,
Profit, ProfitPercent, Pips, HoldTimeBars, HoldTimeMinutes,
RiskPercent, RRatio, Slippage, Commission,
MFE, MAE, MFE_Percent, MAE_Percent, MFE_Pips, MAE_Pips,
MFE_TimeBars, MAE_TimeBars,
RunUp_Price, RunUp_Pips, RunUp_Percent, RunUp_TimeBars,
RunDown_Price, RunDown_Pips, RunDown_Percent, RunDown_TimeBars,
BalanceAfter, EquityAfter, DrawdownPercent,
EntryHour, EntryDayOfWeek, ExitHour, ExitDayOfWeek
```

---

## 📝 Usage Example

### Logging a Trade with RunUp/RunDown

```cpp
TradeLogEntry trade;

// ... set all standard fields ...

// Calculate RunUp/RunDown (in real EA, track after exit)
trade.runUpPrice = 3620.0;
trade.runUpPips = g_logger.CalculatePips(trade.closePrice, trade.runUpPrice, isBuy);
trade.runUpPercent = (trade.runUpPrice - trade.closePrice) / trade.closePrice * 100.0;
trade.runUpTimeBars = 25;

trade.runDownPrice = 3460.0;
trade.runDownPips = g_logger.CalculatePips(trade.closePrice, trade.runDownPrice, isBuy);
trade.runDownPercent = (trade.runDownPrice - trade.closePrice) / trade.closePrice * 100.0;
trade.runDownTimeBars = 45;

g_logger.LogTrade(trade);
```

---

## 🎓 Analysis Use Cases

### 1. TP Optimization
```python
# Python analysis
import pandas as pd

df = pd.read_csv('TP_Trades_NAS100.csv')

# Find trades with large runup (left money on table)
early_exits = df[df['RunUp_Pips'] > 50]
print(f"Trades with >50 pip runup: {len(early_exits)}")
print(f"Average runup: {early_exits['RunUp_Pips'].mean():.1f} pips")
print(f"Money left on table: ${(early_exits['RunUp_Pips'] * lot_value).sum():.2f}")
```

### 2. SL Shake-Out Detection
```python
# Find losing trades that reversed after SL
losing_trades = df[df['Profit'] < 0]
shaken_out = losing_trades[
    (losing_trades['ExitReason'] == 'SL') & 
    (losing_trades['RunDown_Pips'].abs() > losing_trades['Pips'].abs())
]
print(f"Shaken out before reversal: {len(shaken_out)}")
```

### 3. Exit Timing Analysis
```python
# Compare MFE vs RunUp (during vs after)
df['Left_OnTable'] = df['RunUp_Pips'] - df['MFE_Pips']
print(f"Average extra pips after exit: {df['Left_OnTable'].mean():.1f}")

# Runup timing
print(f"Average bars to runup: {df['RunUp_TimeBars'].mean():.1f}")
print(f"Runup occurs within 10 bars: {(df['RunUp_TimeBars'] <= 10).sum()} trades")
```

---

## ✅ Test Scenarios

### Scenario 1: TP Too Early (Test_CSVLogger.mq5)
```
BUY @ 3500, Exit @ 3550 (TP)
✅ MFE = 3570 (during trade)
✅ RunUp = 3620 (+70 pips AFTER exit)
📊 Analysis: Left 70 pips on table, TP too conservative
```

### Scenario 2: SL Shake-Out (Test_CSVLogger.mq5)
```
SELL @ 3500, Exit @ 3530 (SL = -30 pips)
✅ MAE = 3550 (during trade)
✅ RunDown = 3460 (reversed AFTER exit)
📊 Analysis: Would have been +40 pip profit, SL too tight
```

---

## 🔧 Implementation in Real EA

### TP_Trade_Tracker.mqh (Next Library)

The next library will provide **real-time RunUp/RunDown tracking**:

```cpp
class CTradeTracker
{
   void StartTracking(ulong ticket);
   void UpdatePostExit();  // Call on each tick after exit
   double GetRunUpPips(ulong ticket);
   double GetRunDownPips(ulong ticket);
   int GetRunUpTimeBars(ulong ticket);
};
```

### Integration Pattern

```cpp
// In EA
if(position_closed)
{
   ulong ticket = last_ticket;
   
   // Start tracking post-exit
   g_tracker.StartTracking(ticket);
   
   // Wait N bars (e.g., 100)
   int track_bars = 100;
   
   // On tick, update tracker
   g_tracker.UpdatePostExit();
   
   // After N bars, log trade
   if(g_tracker.GetBarsTracked(ticket) >= track_bars)
   {
      trade.runUpPrice = g_tracker.GetRunUpPrice(ticket);
      trade.runUpPips = g_tracker.GetRunUpPips(ticket);
      trade.runUpTimeBars = g_tracker.GetRunUpTimeBars(ticket);
      
      trade.runDownPrice = g_tracker.GetRunDownPrice(ticket);
      trade.runDownPips = g_tracker.GetRunDownPips(ticket);
      trade.runDownTimeBars = g_tracker.GetRunDownTimeBars(ticket);
      
      g_logger.LogTrade(trade);
      g_tracker.StopTracking(ticket);
   }
}
```

---

## 📈 Expected Insights

After collecting trade data with RunUp/RunDown analytics:

1. **Quantified Exit Quality**
   - How often do we exit too early? (large runup)
   - How often do we exit too late? (large mfe_pips vs small profit)

2. **SL Optimization**
   - Shake-out rate (SL hit but price reversed)
   - Optimal SL distance (balance protection vs shake-outs)

3. **TP Optimization**
   - Average money left on table (runup after TP)
   - Optimal TP distance or trailing stop strategy

4. **Strategy Selection**
   - Which exit strategy performs best?
   - Fixed TP vs Trailing vs Dynamic physics-based exit?

---

## 🚀 Next Steps

1. ✅ **Test CSV Logger** - Compile Test_CSVLogger.mq5 and verify output
2. ⏳ **Build Trade Tracker** - TP_Trade_Tracker.mqh for real-time tracking
3. ⏳ **Integration EA** - Combine Risk Manager + Indicator + Logger + Tracker
4. ⏳ **Python Analysis** - Build dashboard to visualize RunUp/RunDown patterns

---

## 📚 References

- **Code:** `TP_CSV_Logger.mqh` (lines 141-166)
- **Test:** `Test_CSVLogger.mq5` (lines 178-273)
- **Original:** `CHUNK_5_Logging_Functions.mq5`
- **FRD:** `TickPhysics_Complete_FRD_v6_0.md` (Enhanced for v8.0)

---

**Status:** ✅ Code Complete | ⏳ Awaiting MetaEditor Compilation & CSV Validation
