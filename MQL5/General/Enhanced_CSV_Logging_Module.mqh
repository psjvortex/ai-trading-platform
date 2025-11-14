//+------------------------------------------------------------------+
//| Enhanced_CSV_Logging_Module.mqh                                   |
//| Comprehensive trade and signal logging for self-learning          |
//| REPLACES basic CSV logging in your EA                            |
//+------------------------------------------------------------------+

//===================================================================//
// GLOBAL VARIABLES FOR TRACKING - ADD TO YOUR EA
//===================================================================//

// Add these to your global variables section:
struct TradeTracker
{
   ulong ticket;
   datetime openTime;
   double openPrice;
   double sl;
   double tp;
   double lots;
   ENUM_ORDER_TYPE type;
   // Entry conditions
   double entryQuality;
   double entryConfluence;
   double entryZone;
   double entryRegime;
   double entryEntropy;
   double entryMAFast;
   double entryMASlow;
   double entrySpread;
   // MFE/MAE tracking
   double mfe;           // Max Favorable Excursion (best price seen)
   double mae;           // Max Adverse Excursion (worst price seen)
};

TradeTracker currentTrades[];  // Array to track open trades

//===================================================================//
// ENHANCED InitSignalLog() - REPLACE YOUR EXISTING FUNCTION
//===================================================================//

bool InitSignalLog()
{
   signalLogHandle = FileOpen(InpSignalLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(signalLogHandle == INVALID_HANDLE)
   {
      Print("Failed to create signal log: ", InpSignalLogFile);
      return false;
   }
   
   // COMPREHENSIVE signal logging header (17 columns)
   FileWrite(signalLogHandle, 
      // Time & Signal
      "Timestamp", "Signal", "SignalType",
      // MA Values
      "MA_Fast_Entry", "MA_Slow_Entry", "MA_Fast_Exit", "MA_Slow_Exit",
      // Physics Metrics
      "Quality", "Confluence", "Momentum", "TradingZone", "VolRegime", "Entropy",
      // Market Context
      "Price", "Spread", "Hour", "DayOfWeek",
      // Physics Filter Status
      "PhysicsEnabled", "PhysicsPass", "RejectReason"
   );
   
   FileClose(signalLogHandle);
   return true;
}

//===================================================================//
// ENHANCED InitTradeLog() - REPLACE YOUR EXISTING FUNCTION
//===================================================================//

bool InitTradeLog()
{
   tradeLogHandle = FileOpen(InpTradeLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(tradeLogHandle == INVALID_HANDLE)
   {
      Print("Failed to create trade log: ", InpTradeLogFile);
      return false;
   }
   
   // COMPREHENSIVE trade logging header (35 columns)
   FileWrite(tradeLogHandle,
      // Trade Basics
      "Timestamp", "Ticket", "Symbol", "Action", "Type", 
      "Lots", "EntryPrice", "SL", "TP",
      // Entry Conditions
      "EntryQuality", "EntryConfluence", "EntryZone", "EntryRegime", "EntryEntropy",
      "EntryMAFast", "EntryMASlow", "EntrySpread",
      // Exit Conditions (filled on close)
      "ExitPrice", "ExitReason", "Profit", "ProfitPercent", "Pips",
      "ExitQuality", "ExitConfluence", "HoldTimeBars",
      // Performance Metrics
      "MFE", "MAE", "MFEPercent", "MAEPercent", "MFE_Pips", "MAE_Pips",
      // Risk Metrics
      "RiskPercent", "RRatio",
      // Time Analysis
      "EntryHour", "EntryDayOfWeek", "ExitHour"
   );
   
   FileClose(tradeLogHandle);
   return true;
}

//===================================================================//
// TRACK NEW TRADE - CALL THIS AFTER SUCCESSFUL TRADE OPENING
//===================================================================//

void TrackNewTrade(ulong ticket, double quality, double confluence, double zone,
                   double regime, double entropy)
{
   if(ticket == 0) return;
   
   // Select the position
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Cannot select position for tracking: ", ticket);
      return;
   }
   
   // Create new tracker
   int size = ArraySize(currentTrades);
   ArrayResize(currentTrades, size + 1);
   
   // Fill tracker data
   currentTrades[size].ticket = ticket;
   currentTrades[size].openTime = (datetime)PositionGetInteger(POSITION_TIME);
   currentTrades[size].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   currentTrades[size].sl = PositionGetDouble(POSITION_SL);
   currentTrades[size].tp = PositionGetDouble(POSITION_TP);
   currentTrades[size].lots = PositionGetDouble(POSITION_VOLUME);
   currentTrades[size].type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
   
   // Store entry conditions
   currentTrades[size].entryQuality = quality;
   currentTrades[size].entryConfluence = confluence;
   currentTrades[size].entryZone = zone;
   currentTrades[size].entryRegime = regime;
   currentTrades[size].entryEntropy = entropy;
   
   // Get MA values
   double maFast[1], maSlow[1];
   CopyBuffer(maFastEntry_Handle, 0, 0, 1, maFast);
   CopyBuffer(maSlowEntry_Handle, 0, 0, 1, maSlow);
   currentTrades[size].entryMAFast = maFast[0];
   currentTrades[size].entryMASlow = maSlow[0];
   
   // Get spread
   double spread = 0;
   CheckSpreadFilter(spread);
   currentTrades[size].entrySpread = spread;
   
   // Initialize MFE/MAE
   currentTrades[size].mfe = currentTrades[size].openPrice;
   currentTrades[size].mae = currentTrades[size].openPrice;
   
   Print("✅ Trade tracked: #", ticket, " Quality=", quality, " Confluence=", confluence);
}

//===================================================================//
// UPDATE MFE/MAE - CALL THIS IN OnTick() FOR EACH OPEN POSITION
//===================================================================//

void UpdateMFEMAE()
{
   for(int i = 0; i < ArraySize(currentTrades); i++)
   {
      if(!PositionSelectByTicket(currentTrades[i].ticket))
         continue;  // Position closed, will be removed
      
      double currentPrice = (currentTrades[i].type == ORDER_TYPE_BUY) ?
         SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(currentTrades[i].type == ORDER_TYPE_BUY)
      {
         // For BUY: MFE = highest price, MAE = lowest price
         if(currentPrice > currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice < currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
      else  // SELL
      {
         // For SELL: MFE = lowest price, MAE = highest price
         if(currentPrice < currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice > currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
   }
}

//===================================================================//
// LOG TRADE CLOSE - CALL THIS WHEN POSITION CLOSES
//===================================================================//

void LogTradeClose(ulong ticket, string exitReason)
{
   // Find the tracker
   int trackerIndex = -1;
   for(int i = 0; i < ArraySize(currentTrades); i++)
   {
      if(currentTrades[i].ticket == ticket)
      {
         trackerIndex = i;
         break;
      }
   }
   
   if(trackerIndex < 0)
   {
      Print("WARNING: No tracker found for closed trade: ", ticket);
      return;
   }
   
   // Get trade details from history
   if(!HistorySelectByPosition(ticket))
   {
      Print("ERROR: Cannot find trade in history: ", ticket);
      return;
   }
   
   int totalDeals = HistoryDealsTotal();
   ulong closeDeal = 0;
   double profit = 0;
   double exitPrice = 0;
   datetime exitTime = 0;
   
   // Find the closing deal
   for(int i = totalDeals - 1; i >= 0; i--)
   {
      closeDeal = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(closeDeal, DEAL_POSITION_ID) == ticket &&
         HistoryDealGetInteger(closeDeal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         profit = HistoryDealGetDouble(closeDeal, DEAL_PROFIT);
         exitPrice = HistoryDealGetDouble(closeDeal, DEAL_PRICE);
         exitTime = (datetime)HistoryDealGetInteger(closeDeal, DEAL_TIME);
         break;
      }
   }
   
   // Get current physics metrics at exit
   double exitQuality = 0, exitConfluence = 0;
   if(InpUsePhysics && InpUseTickPhysicsIndicator)
   {
      double qBuf[1], cBuf[1];
      if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qBuf) > 0)
         exitQuality = qBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, cBuf) > 0)
         exitConfluence = cBuf[0];
   }
   
   // Calculate metrics
   TradeTracker *t = &currentTrades[trackerIndex];
   
   double profitPercent = (profit / AccountInfoDouble(ACCOUNT_EQUITY)) * 100.0;
   
   double pips = 0;
   if(t.type == ORDER_TYPE_BUY)
      pips = (exitPrice - t.openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   else
      pips = (t.openPrice - exitPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   
   int holdTimeBars = (int)((exitTime - t.openTime) / PeriodSeconds(_Period));
   
   // Calculate MFE/MAE percentages
   double mfePercent = 0, maePercent = 0, mfePips = 0, maePips = 0;
   if(t.type == ORDER_TYPE_BUY)
   {
      mfePercent = ((t.mfe - t.openPrice) / t.openPrice) * 100.0;
      maePercent = ((t.mae - t.openPrice) / t.openPrice) * 100.0;
      mfePips = (t.mfe - t.openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
      maePips = (t.mae - t.openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   }
   else
   {
      mfePercent = ((t.openPrice - t.mfe) / t.openPrice) * 100.0;
      maePercent = ((t.openPrice - t.mae) / t.openPrice) * 100.0;
      mfePips = (t.openPrice - t.mfe) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
      maePips = (t.openPrice - t.mae) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   }
   
   // Calculate risk/reward
   double riskPercent = InpRiskPerTradePercent;
   double rRatio = (riskPercent != 0) ? (profitPercent / riskPercent) : 0;
   
   MqlDateTime entryTime, closeTime;
   TimeToStruct(t.openTime, entryTime);
   TimeToStruct(exitTime, closeTime);
   
   // Write to log
   int handle = FileOpen(InpTradeLogFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Could not open trade log file");
      return;
   }
   
   FileSeek(handle, 0, SEEK_END);
   
   FileWrite(handle,
      // Trade Basics
      TimeToString(t.openTime), ticket, _Symbol, "CLOSE", 
      (t.type == ORDER_TYPE_BUY) ? "BUY" : "SELL",
      t.lots, t.openPrice, t.sl, t.tp,
      // Entry Conditions
      t.entryQuality, t.entryConfluence, t.entryZone, t.entryRegime, t.entryEntropy,
      t.entryMAFast, t.entryMASlow, t.entrySpread,
      // Exit Conditions
      exitPrice, exitReason, profit, profitPercent, pips,
      exitQuality, exitConfluence, holdTimeBars,
      // Performance Metrics
      t.mfe, t.mae, mfePercent, maePercent, mfePips, maePips,
      // Risk Metrics
      riskPercent, rRatio,
      // Time Analysis
      entryTime.hour, entryTime.day_of_week, closeTime.hour
   );
   
   FileClose(handle);
   
   Print("📝 Trade closed and logged: #", ticket, " Profit=", profit, " R=", rRatio);
   
   // Remove from tracker array
   for(int i = trackerIndex; i < ArraySize(currentTrades) - 1; i++)
   {
      currentTrades[i] = currentTrades[i + 1];
   }
   ArrayResize(currentTrades, ArraySize(currentTrades) - 1);
}

//===================================================================//
// MODIFIED OpenPosition() - REPLACE YOUR EXISTING FUNCTION
//===================================================================//

bool OpenPosition(ENUM_ORDER_TYPE orderType)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
   
   // Calculate SL/TP
   double sl, tp;
   if(!ComputeSLTPFromPercent(price, orderType, InpStopLossPercent, InpTakeProfitPercent, sl, tp))
   {
      Print("❌ Failed to compute SL/TP");
      return false;
   }
   
   // Calculate lot size
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPerTradePercent / 100.0;
   double slDistance = MathAbs(price - sl);
   double lots = CalculateLotSize(riskMoney, slDistance);
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size: ", lots);
      return false;
   }
   
   // Validate trade
   if(!ValidateTrade(sl, tp, lots))
   {
      return false;
   }
   
   // Execute
   bool success = false;
   if(orderType == ORDER_TYPE_BUY)
   {
      success = trade.Buy(lots, _Symbol, ask, sl, tp, "MA_Crossover_BUY");
   }
   else
   {
      success = trade.Sell(lots, _Symbol, bid, sl, tp, "MA_Crossover_SELL");
   }
   
   if(success)
   {
      ulong ticket = trade.ResultOrder();
      Print("✅ ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
            " opened: Ticket=", ticket, " Lots=", lots, " SL=", sl, " TP=", tp);
      
      // Get current physics metrics
      double quality = 0, confluence = 0, zone = 0, regime = 0, entropy = 0;
      if(InpUsePhysics && InpUseTickPhysicsIndicator)
      {
         double qBuf[1], cBuf[1], zBuf[1], rBuf[1], eBuf[1];
         if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qBuf) > 0) quality = qBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, cBuf) > 0) confluence = cBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_TRADING_ZONE, 0, 1, zBuf) > 0) zone = zBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_VOL_REGIME, 0, 1, rBuf) > 0) regime = rBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_ENTROPY, 0, 1, eBuf) > 0) entropy = eBuf[0];
      }
      
      // Track the trade with entry conditions
      TrackNewTrade(ticket, quality, confluence, zone, regime, entropy);
   }
   else
   {
      Print("❌ Failed to open position: ", trade.ResultRetcodeDescription());
   }
   
   return success;
}

//===================================================================//
// ADD TO OnTick() - Update MFE/MAE every tick
//===================================================================//

/*
Add this line in your OnTick() function, before ManagePositions():

   UpdateMFEMAE();  // Track max favorable/adverse excursion
*/

//===================================================================//
// MODIFIED ManagePositions() - Update to log closes
//===================================================================//

/*
In your CheckExitSignal section where you close positions, replace:

   if(trade.PositionClose(ticket))
   {
      Print("✅ Position closed on MA exit signal: #", ticket);
   }

With:

   if(trade.PositionClose(ticket))
   {
      Print("✅ Position closed on MA exit signal: #", ticket);
      LogTradeClose(ticket, "MA_Exit_Signal");
      continue;
   }

And in your TP hit section (if you have one):
   LogTradeClose(ticket, "TP_Hit");

And in your SL hit section:
   LogTradeClose(ticket, "SL_Hit");
*/

//===================================================================//
// INTEGRATION INSTRUCTIONS
//===================================================================//

/*
TO INTEGRATE THIS MODULE:

1. Add TradeTracker struct to global variables section

2. Replace InitSignalLog() with enhanced version

3. Replace InitTradeLog() with enhanced version

4. Add TrackNewTrade() function

5. Add UpdateMFEMAE() function

6. Add LogTradeClose() function

7. Modify OpenPosition() to call TrackNewTrade()

8. Add UpdateMFEMAE() call in OnTick()

9. Modify ManagePositions() to call LogTradeClose()

10. Compile and test

TESTING CHECKLIST:
- [ ] Signal CSV has 20 columns
- [ ] Trade CSV has 35 columns
- [ ] MFE/MAE values update during trade
- [ ] Trade close logs complete entry/exit data
- [ ] All physics metrics captured at entry
- [ ] Exit reason logged correctly
- [ ] Profit/loss calculated correctly
- [ ] R:R ratio calculated correctly

CSV ANALYSIS CAPABILITIES:
With this data you can analyze:
- Which Quality levels perform best
- Which Confluence levels perform best
- Best time of day for entries
- Best day of week
- MFE/MAE ratios (exit efficiency)
- Zone/Regime performance
- Entropy impact on success
- Entry spread vs outcome
- Hold time vs profitability
*/
