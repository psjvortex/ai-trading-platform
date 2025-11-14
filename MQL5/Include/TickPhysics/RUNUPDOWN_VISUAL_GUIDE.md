# RunUp/RunDown Visual Guide

## 📊 What Do These Metrics Measure?

```
MFE/MAE = During Trade (Open → Close)
RunUp/RunDown = After Exit (Close → N bars later)
```

---

## Example 1: Winning Trade (TP Too Early)

```
Price Timeline:
│
│  RunUp Peak (3620) ◄─── This is what we MISSED!
│    ↑ RunUp: +70 pips
│    │ RunUp_TimeBars: 25
│
│  MFE Peak (3570) ◄─── Best price while IN trade
│    ↑
│  TP Exit (3550) ◄══════ We exited here (TP hit)
│    ↑ Profit: +50 pips
│  Entry (3500)
│    ↓
│  MAE Low (3485) ◄─── Worst price while IN trade
│
└────────────────────────────────────────────────────
Time: [Open]  [10 bars]  [45 bars]  [60 bars]  [85 bars]
                MAE         MFE       CLOSE      RunUp

Analysis:
✅ Trade was profitable (+50 pips)
❌ BUT we left 70 pips on table!
💡 Action: Widen TP or use trailing stop
📈 Total potential: 120 pips (3500→3620)
😢 Captured only: 50 pips (41%)
```

**CSV Data:**
```
MFE_Pips: 70.0        # Best during trade
MAE_Pips: -15.0       # Worst during trade
Pips: 50.0            # Actual profit
RunUp_Pips: 70.0      # How far it went AFTER exit
RunUp_TimeBars: 25    # When runup peaked
```

---

## Example 2: Losing Trade (Shaken Out Before Reversal)

```
Price Timeline:
│
│  Entry (3500) ◄══════ SELL position opened
│    ↓
│  MFE Low (3480) ◄─── Best price while IN trade (closer to TP)
│    ↓
│  SL Exit (3530) ◄══════ We got stopped out (-30 pips)
│    ↓
│  MAE High (3550) ◄─── Worst price while IN trade (SL trigger)
│    ↓
│    ↓ RunDown: -70 pips  ◄─── What happened AFTER we exited!
│    ↓ RunDown_TimeBars: 45
│    ↓
│  RunDown Low (3460) ◄─── Price reversed here (would have been profit!)
│
└────────────────────────────────────────────────────
Time: [Open]  [10 bars]  [15 bars]  [CLOSE]  [45 bars]
                MFE         MAE       (SL)    RunDown

Analysis:
❌ Trade was losing (-30 pips)
💔 Price reversed to our TP level AFTER we were stopped!
⚠️ Got "shaken out" before the real move
📉 Actual result: -30 pips
😭 Potential if held: +40 pips (3500→3460 for SELL)
💡 Action: Widen SL or better entry timing
```

**CSV Data:**
```
MFE_Pips: 20.0        # Got within 20 pips of TP
MAE_Pips: -50.0       # SL triggered at -50 pips
Pips: -30.0           # Loss
RunDown_Pips: -70.0   # How far it reversed AFTER SL (in our direction!)
RunDown_TimeBars: 45  # When reversal completed
```

---

## 🎯 Use Cases for Each Metric

### MFE (Max Favorable Excursion) - During Trade
```
Question: Did we give back profits?
Use: If MFE >> Profit → Consider tighter TP or trailing
Example: MFE=100 pips, Profit=30 pips → Gave back 70 pips!
```

### MAE (Max Adverse Excursion) - During Trade
```
Question: How close did we come to SL?
Use: If MAE ≈ SL often → SL too tight
Example: MAE=-45 pips, SL=-50 pips → Almost stopped many times
```

### RunUp (Post-Exit Favorable) - After Trade
```
Question: Did we exit too early?
Use: If RunUp >> MFE → TP too early, use wider TP
Example: Profit=50, RunUp=150 → Left 100 pips on table!
```

### RunDown (Post-Exit Adverse) - After Trade
```
Question: Did we exit at the worst time?
Use: If RunDown favorable after SL → Got shaken out
Example: SL=-30 pips, RunDown would have been +40 → Bad timing!
```

---

## 📈 Python Analysis Examples

### 1. Find Early Exits (TP Too Soon)
```python
import pandas as pd

df = pd.read_csv('TP_Trades_NAS100.csv')

# Trades with large runup after exit
early_exits = df[df['RunUp_Pips'] > df['Pips'] * 0.5]  # RunUp > 50% of profit

print(f"Early exits: {len(early_exits)} / {len(df)}")
print(f"Average runup: {early_exits['RunUp_Pips'].mean():.1f} pips")
print(f"Money left on table: ${(early_exits['RunUp_Pips'] * lot_value).sum():.2f}")

# Recommendation
avg_profit = df['Pips'].mean()
avg_runup = df['RunUp_Pips'].mean()
optimal_tp = avg_profit + (avg_runup * 0.7)  # Capture 70% of runup
print(f"\nRecommendation: Increase TP from {avg_profit:.1f} to {optimal_tp:.1f} pips")
```

### 2. Find Shake-Outs (SL Hit Before Reversal)
```python
# Losing trades that reversed favorably after SL
losing = df[df['Profit'] < 0]
shaken_out = losing[
    (losing['ExitReason'] == 'SL') &
    (losing['RunDown_Pips'].abs() > losing['Pips'].abs())
]

print(f"Shaken out: {len(shaken_out)} / {len(losing)}")
print(f"Average reversal: {shaken_out['RunDown_Pips'].mean():.1f} pips")
print(f"Average time to reversal: {shaken_out['RunDown_TimeBars'].mean():.0f} bars")

# Recommendation
shake_rate = len(shaken_out) / len(losing) * 100
if shake_rate > 30:
    print(f"\n⚠️ {shake_rate:.1f}% of losses are shake-outs!")
    print("Recommendation: Increase SL by 30-50%")
```

### 3. Optimal Exit Timing
```python
# Compare exit strategies
df['Potential_Profit'] = df['Pips'] + df['RunUp_Pips']
df['Capture_Rate'] = df['Pips'] / df['Potential_Profit'] * 100

print("Exit Performance:")
print(f"Current capture rate: {df['Capture_Rate'].mean():.1f}%")
print(f"Avg profit: {df['Pips'].mean():.1f} pips")
print(f"Avg potential: {df['Potential_Profit'].mean():.1f} pips")

# Strategy comparison
strategies = {
    'Fixed TP (current)': df['Pips'].sum(),
    'Hold until RunUp': df['Potential_Profit'].sum(),
    'Trail 50% of RunUp': (df['Pips'] + df['RunUp_Pips'] * 0.5).sum(),
}

for name, profit in strategies.items():
    print(f"{name}: ${profit:.2f}")
```

---

## 🔍 Real-World Scenarios

### Scenario A: Trending Market
```
Many trades show:
- Large RunUp after exit
- RunUp_TimeBars < 50 (happens quickly)
- Current strategy exits too early

Solution: Implement trailing stop to ride trends
```

### Scenario B: Choppy Market
```
Many trades show:
- Large MAE (almost hit SL many times)
- Small RunUp (no continuation after exit)
- Current SL/TP good for chop

Solution: Keep current exits, add trend filter
```

### Scenario C: Shake-Out Paradise
```
Losing trades show:
- ExitReason = 'SL'
- RunDown_Pips > 2x Pips (massive reversal)
- RunDown_TimeBars > 30 (reversal takes time)

Solution: Wider SL + time-based exit instead of fixed SL
```

---

## 🎓 Integration with TP_Trade_Tracker.mqh (Next Library)

The Trade Tracker will automate RunUp/RunDown collection:

```cpp
// Real-time tracking after exit
class CTradeTracker
{
   struct PostExitTracker
   {
      ulong ticket;
      datetime exitTime;
      double exitPrice;
      bool isBuy;
      double runUpPrice;    // Best price after exit
      double runDownPrice;  // Worst price after exit
      int barsTracked;
      int runUpBar;         // When runup occurred
      int runDownBar;       // When rundown occurred
   };
   
   void StartTracking(ulong ticket, double exitPrice, bool isBuy);
   void UpdatePostExit();  // Call each tick
   void GetRunUpDown(ulong ticket, double &runUpPips, double &runDownPips);
};

// Usage in EA
if(position_closed)
{
   g_tracker.StartTracking(ticket, closePrice, wasBuy);
   
   // Track for 100 bars
   while(g_tracker.GetBarsTracked(ticket) < 100)
   {
      g_tracker.UpdatePostExit();  // Called on each tick
   }
   
   // Get final RunUp/RunDown
   double runUpPips, runDownPips;
   g_tracker.GetRunUpDown(ticket, runUpPips, runDownPips);
   
   // Log to CSV
   trade.runUpPips = runUpPips;
   trade.runDownPips = runDownPips;
   g_logger.LogTrade(trade);
}
```

---

**Summary:** RunUp/RunDown metrics transform trade logging from "what happened during the trade" to "what happened during AND after the trade", enabling data-driven optimization of exit strategies.
