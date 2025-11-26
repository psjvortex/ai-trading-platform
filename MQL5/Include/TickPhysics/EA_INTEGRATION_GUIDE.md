# EA Integration Guide - Dual-Row Trade Logging

## Quick Reference: How to Call the New Logger

### **At Trade Open (ENTRY Row)**

```cpp
// In your trade opening logic (OnTick or OnNewBar)
void OnTradeOpen(ulong ticket)
{
   TradeLogEntry entry;
   
   // Core identification
   entry.eaName = EA_NAME;
   entry.eaVersion = EA_VERSION;
   entry.rowType = "ENTRY";           // ← CRITICAL!
   entry.ticket = ticket;
   entry.timestamp = TimeCurrent();   // Current time
   entry.openTime = TimeCurrent();
   entry.closeTime = 0;               // Not closed yet
   entry.symbol = _Symbol;
   entry.type = OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY ? "BUY" : "SELL";
   
   // Trade parameters
   entry.lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
   entry.price = OrderGetDouble(ORDER_PRICE_CURRENT);  // Entry price
   entry.openPrice = entry.price;
   entry.closePrice = 0;  // Not closed yet
   entry.sl = OrderGetDouble(ORDER_SL);
   entry.tp = OrderGetDouble(ORDER_TP);
   
   // CAPTURE CURRENT PHYSICS (from indicator)
   entry.quality = g_physics.GetQuality(0);
   entry.confluence = g_physics.GetConfluence(0);
   entry.momentum = g_physics.GetMomentum(0);
   entry.speed = g_physics.GetSpeed(0);
   entry.acceleration = g_physics.GetAcceleration(0);
   entry.entropy = g_physics.GetEntropy(0);
   entry.jerk = g_physics.GetJerk(0);
   entry.physicsScore = g_physics.GetPhysicsScore(0);
   
   // Slopes (YOUR KEY FINDINGS!)
   entry.speedSlope = CalculateSlope(g_physics.GetSpeed(1), g_physics.GetSpeed(2), g_physics.GetSpeed(3), 3);
   entry.accelerationSlope = CalculateSlope(g_physics.GetAcceleration(1), g_physics.GetAcceleration(2), g_physics.GetAcceleration(3), 3);
   entry.momentumSlope = CalculateSlope(g_physics.GetMomentum(1), g_physics.GetMomentum(2), g_physics.GetMomentum(3), 3);
   entry.confluenceSlope = CalculateSlope(g_physics.GetConfluence(1), g_physics.GetConfluence(2), g_physics.GetConfluence(3), 3);
   entry.jerkSlope = CalculateSlope(g_physics.GetJerk(1), g_physics.GetJerk(2), g_physics.GetJerk(3), 3);
   
   // Market context
   entry.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
   entry.regime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());
   entry.spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   
   // Legacy entry fields (for backward compatibility)
   entry.entryQuality = entry.quality;
   entry.entryConfluence = entry.confluence;
   entry.entryMomentum = entry.momentum;
   entry.entryEntropy = entry.entropy;
   entry.entryPhysicsScore = entry.physicsScore;
   entry.entryZone = entry.zone;
   entry.entryRegime = entry.regime;
   entry.entrySpread = entry.spread;
   
   // Account state
   entry.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   entry.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   entry.balanceAfter = entry.balance;  // Same at entry
   entry.equityAfter = entry.equity;
   entry.drawdownPercent = 0;
   entry.openPositions = PositionsTotal();
   
   // Zero out EXIT-only fields
   entry.profit = 0;
   entry.pips = 0;
   entry.holdTimeBars = 0;
   entry.holdTimeMinutes = 0;
   entry.exitReason = "";
   entry.mfe = 0;
   entry.mae = 0;
   entry.runUpPips = 0;
   entry.runDownPips = 0;
   
   // Calculate time segments (AUTOMATIC!)
   g_logger.CalculateTimeSegments(entry.timestamp, entry);
   
   // Log ENTRY row
   g_logger.LogTrade(entry);
   
   // Store entry snapshot in tracker for exit comparison
   g_tracker.StoreEntryPhysics(ticket, entry);
}
```

---

### **At Trade Close (EXIT Row)**

```cpp
// In OnTradeTransaction when deal type is DEAL_ENTRY_OUT
void OnTradeClose(ulong ticket, double closePrice, double profit, string exitReason)
{
   // Get stored entry physics from tracker
   TradeLogEntry entrySnapshot = g_tracker.GetEntryPhysics(ticket);
   
   TradeLogEntry exit;
   
   // Core identification
   exit.eaName = EA_NAME;
   exit.eaVersion = EA_VERSION;
   exit.rowType = "EXIT";             // ← CRITICAL!
   exit.ticket = ticket;
   exit.timestamp = TimeCurrent();    // Exit time
   exit.openTime = entrySnapshot.openTime;  // Copy from entry
   exit.closeTime = TimeCurrent();
   exit.symbol = _Symbol;
   exit.type = entrySnapshot.type;    // Copy from entry
   
   // Trade parameters
   exit.lots = entrySnapshot.lots;
   exit.price = closePrice;           // Exit price
   exit.openPrice = entrySnapshot.openPrice;
   exit.closePrice = closePrice;
   exit.sl = entrySnapshot.sl;
   exit.tp = entrySnapshot.tp;
   
   // CAPTURE CURRENT PHYSICS AT EXIT (from indicator)
   exit.quality = g_physics.GetQuality(0);
   exit.confluence = g_physics.GetConfluence(0);
   exit.momentum = g_physics.GetMomentum(0);
   exit.speed = g_physics.GetSpeed(0);
   exit.acceleration = g_physics.GetAcceleration(0);
   exit.entropy = g_physics.GetEntropy(0);
   exit.jerk = g_physics.GetJerk(0);
   exit.physicsScore = g_physics.GetPhysicsScore(0);
   
   // Slopes at exit
   exit.speedSlope = CalculateSlope(g_physics.GetSpeed(1), g_physics.GetSpeed(2), g_physics.GetSpeed(3), 3);
   exit.accelerationSlope = CalculateSlope(g_physics.GetAcceleration(1), g_physics.GetAcceleration(2), g_physics.GetAcceleration(3), 3);
   exit.momentumSlope = CalculateSlope(g_physics.GetMomentum(1), g_physics.GetMomentum(2), g_physics.GetMomentum(3), 3);
   exit.confluenceSlope = CalculateSlope(g_physics.GetConfluence(1), g_physics.GetConfluence(2), g_physics.GetConfluence(3), 3);
   exit.jerkSlope = CalculateSlope(g_physics.GetJerk(1), g_physics.GetJerk(2), g_physics.GetJerk(3), 3);
   
   // Market context at exit
   exit.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
   exit.regime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());
   exit.spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   
   // Copy legacy entry fields from snapshot
   exit.entryQuality = entrySnapshot.quality;
   exit.entryConfluence = entrySnapshot.confluence;
   exit.entryMomentum = entrySnapshot.momentum;
   exit.entryEntropy = entrySnapshot.entropy;
   exit.entryPhysicsScore = entrySnapshot.physicsScore;
   exit.entryZone = entrySnapshot.zone;
   exit.entryRegime = entrySnapshot.regime;
   exit.entrySpread = entrySnapshot.spread;
   
   // Exit physics
   exit.exitReason = exitReason;
   exit.exitQuality = exit.quality;
   exit.exitConfluence = exit.confluence;
   exit.exitZone = exit.zone;
   exit.exitRegime = exit.regime;
   
   // Performance metrics (from tracker)
   ClosedTrade closedTrade = g_tracker.GetClosedTrade(ticket);
   exit.profit = closedTrade.profit;
   exit.profitPercent = closedTrade.profitPercent;
   exit.pips = closedTrade.pips;
   exit.holdTimeBars = closedTrade.holdTimeBars;
   exit.holdTimeMinutes = (int)((exit.closeTime - exit.openTime) / 60);
   exit.riskPercent = closedTrade.riskPercent;
   exit.rRatio = closedTrade.rRatio;
   exit.slippage = closedTrade.slippage;
   exit.commission = closedTrade.commission;
   
   // Excursion analysis (from tracker)
   exit.mfe = closedTrade.mfe;
   exit.mae = closedTrade.mae;
   exit.mfePercent = closedTrade.mfePercent;
   exit.maePercent = closedTrade.maePercent;
   exit.mfePips = closedTrade.mfePips;
   exit.maePips = closedTrade.maePips;
   exit.mfeTimeBars = closedTrade.mfeTimeBars;
   exit.maeTimeBars = closedTrade.maeTimeBars;
   
   // Post-exit analysis (from tracker)
   exit.runUpPrice = closedTrade.runUpPrice;
   exit.runUpPips = closedTrade.runUpPips;
   exit.runUpPercent = closedTrade.runUpPercent;
   exit.runUpTimeBars = closedTrade.runUpTimeBars;
   exit.runDownPrice = closedTrade.runDownPrice;
   exit.runDownPips = closedTrade.runDownPips;
   exit.runDownPercent = closedTrade.runDownPercent;
   exit.runDownTimeBars = closedTrade.runDownTimeBars;
   
   // Account state at exit
   exit.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   exit.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   exit.balanceAfter = exit.balance;
   exit.equityAfter = exit.equity;
   exit.drawdownPercent = ((exit.equity - exit.balance) / exit.balance) * 100;
   exit.openPositions = PositionsTotal();
   
   // Calculate time segments for exit time (AUTOMATIC!)
   g_logger.CalculateTimeSegments(exit.timestamp, exit);
   
   // Calculate derived metrics (AUTOMATIC! Physics decay, exit quality, etc.)
   g_logger.CalculateDerivedMetrics(exit, entrySnapshot);
   
   // Log EXIT row
   g_logger.LogTrade(exit);
   
   // Clean up entry snapshot from tracker
   g_tracker.RemoveEntryPhysics(ticket);
}
```

---

## Key Points to Remember

### ✅ **DO:**
1. Set `rowType = "ENTRY"` at trade open
2. Set `rowType = "EXIT"` at trade close
3. Capture physics from indicator at BOTH times
4. Call `CalculateTimeSegments()` for each row
5. Call `CalculateDerivedMetrics()` only for EXIT row
6. Store entry snapshot in tracker for decay calculation

### ❌ **DON'T:**
1. Forget to set `rowType` - it's critical for analysis!
2. Skip physics capture at exit - that's where the edge is!
3. Hardcode time segments - use `CalculateTimeSegments()`
4. Calculate decay metrics manually - use `CalculateDerivedMetrics()`

---

## TP_Trade_Tracker.mqh Additions Needed

Add these methods to track entry physics:

```cpp
class CTradeTracker
{
private:
   TradeLogEntry m_entrySnapshots[];  // Store entry physics by ticket
   
public:
   //+------------------------------------------------------------------+
   //| Store entry physics for later comparison                         |
   //+------------------------------------------------------------------+
   void StoreEntryPhysics(ulong ticket, TradeLogEntry &entry)
   {
      int size = ArraySize(m_entrySnapshots);
      ArrayResize(m_entrySnapshots, size + 1);
      m_entrySnapshots[size] = entry;
      m_entrySnapshots[size].ticket = ticket;  // Index by ticket
   }
   
   //+------------------------------------------------------------------+
   //| Retrieve entry physics for exit comparison                       |
   //+------------------------------------------------------------------+
   TradeLogEntry GetEntryPhysics(ulong ticket)
   {
      for(int i = 0; i < ArraySize(m_entrySnapshots); i++)
      {
         if(m_entrySnapshots[i].ticket == ticket)
            return m_entrySnapshots[i];
      }
      
      // Return empty if not found
      TradeLogEntry empty;
      return empty;
   }
   
   //+------------------------------------------------------------------+
   //| Remove entry physics after trade closed                          |
   //+------------------------------------------------------------------+
   void RemoveEntryPhysics(ulong ticket)
   {
      for(int i = 0; i < ArraySize(m_entrySnapshots); i++)
      {
         if(m_entrySnapshots[i].ticket == ticket)
         {
            // Shift array elements
            for(int j = i; j < ArraySize(m_entrySnapshots) - 1; j++)
               m_entrySnapshots[j] = m_entrySnapshots[j + 1];
            
            ArrayResize(m_entrySnapshots, ArraySize(m_entrySnapshots) - 1);
            break;
         }
      }
   }
};
```

---

## Testing Checklist

After implementing:

1. ✅ Run 10-trade backtest
2. ✅ Open CSV in Excel/Python
3. ✅ Verify exactly 2 rows per trade (ENTRY + EXIT)
4. ✅ Verify ENTRY rows have physics but no profit/MFE/MAE
5. ✅ Verify EXIT rows have physics + full outcomes
6. ✅ Verify physics decay fields populated on EXIT rows
7. ✅ Verify time segments match timestamps
8. ✅ Verify ZoneTransitioned = TRUE when zone changes
9. ✅ Verify no leading apostrophes or excessive decimals
10. ✅ Verify DataQualityScore > 80 for most trades

---

## Expected Output Example

```csv
EAName,EAVersion,RowType,Ticket,Timestamp,Speed,SpeedSlope,Zone,PhysicsScore,Profit,Pips,SpeedSlopeDecay,ZoneTransitioned
TP_Integrated,4.186,ENTRY,12345,2025.11.16 10:05,1820.45,1.52,BULL,84.20,0,0,0,FALSE
TP_Integrated,4.186,EXIT,12345,2025.11.16 10:12,910.22,0.81,TRANSITION,71.80,14.70,14.7,0.71,TRUE
```

**Analysis Unlocked:**
- Entry: Speed=1820, Slope=1.52, BULL zone, Physics=84.2
- Exit: Speed=910 (-50%), Slope=0.81 (-47%), TRANSITION zone, Physics=71.8 (-12.4)
- Physics deteriorated but still won (+14.7 pips)
- Zone transitioned (BULL → TRANSITION) - **37% loss predictor!**

---

**Ready to integrate! This will transform your optimization workflow.** 🚀
