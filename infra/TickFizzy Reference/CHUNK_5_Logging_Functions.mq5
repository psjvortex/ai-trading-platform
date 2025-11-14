//============================= CHUNK 5: LOGGING FUNCTIONS ===============//
// ADD THIS AFTER CHUNK 4
//========================================================================//

//========================================================================//
//=================== v5.0: LOG TRADE CLOSE ==============================//
//========================================================================//

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
      if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qBuf) > 0) exitQuality = qBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, cBuf) > 0) exitConfluence = cBuf[0];
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
   
   // Write to log (35 columns)
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

//========================================================================//
//===================== v5.0: ENHANCED SIGNAL LOGGING ====================//
//========================================================================//

void LogSignal(int signal, double quality, double confluence, double momentum,
               double zone, double regime, double entropy,
               bool physicsPass, string rejectReason)
{
   int handle = FileOpen(InpSignalLogFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Could not open signal log file: ", InpSignalLogFile);
      return;
   }
   
   FileSeek(handle, 0, SEEK_END);
   
   // Get current MA values
   double maFastEntry[1], maSlowEntry[1], maFastExit[1], maSlowExit[1];
   CopyBuffer(maFastEntry_Handle, 0, 0, 1, maFastEntry);
   CopyBuffer(maSlowEntry_Handle, 0, 0, 1, maSlowEntry);
   CopyBuffer(maFastExit_Handle, 0, 0, 1, maFastExit);
   CopyBuffer(maSlowExit_Handle, 0, 0, 1, maSlowExit);
   
   // Get current market data
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = 0;
   CheckSpreadFilter(spread);
   
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   // Write comprehensive signal data (20 columns)
   FileWrite(handle,
      // Time & Signal
      TimeToString(TimeCurrent()), 
      signal,
      (signal == 1) ? "BUY" : (signal == -1) ? "SELL" : "NONE",
      // MA Values
      maFastEntry[0], maSlowEntry[0], maFastExit[0], maSlowExit[0],
      // Physics Metrics
      quality, confluence, momentum, zone, regime, entropy,
      // Market Context
      price, spread, timeStruct.hour, timeStruct.day_of_week,
      // Physics Filter Status
      (InpUsePhysics && InpUseTickPhysicsIndicator) ? "YES" : "NO",
      physicsPass ? "PASS" : "REJECT",
      rejectReason
   );
   
   FileClose(handle);
   
   if(!physicsPass)
   {
      Print("📝 Signal logged: REJECTED - ", rejectReason);
   }
}

//========================================================================//
//=================== VALIDATE TRADE =====================================//
//========================================================================//

bool ValidateTrade(double sl, double tp, double lots)
{
   // Check SL/TP validity
   if(sl <= 0 || tp <= 0)
   {
      Print("❌ REJECTED: Invalid SL/TP: sl=", sl, " tp=", tp);
      return false;
   }
   
   // *** v5.0 FIX: Use new spread filter function ***
   double spread = 0;
   if(!CheckSpreadFilter(spread))
   {
      return false;
   }
   
   // Check lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   if(lots < minLot)
   {
      Print("❌ REJECTED: Lot size too small: ", lots, " < ", minLot);
      return false;
   }
   
   if(lots > maxLot)
   {
      Print("❌ REJECTED: Lot size too large: ", lots, " > ", maxLot);
      return false;
   }
   
   return true;
}

//============================= END OF CHUNK 5 ===========================//
// NEXT: Copy Chunk 6 (OpenPosition, trading logic, and helper functions)
