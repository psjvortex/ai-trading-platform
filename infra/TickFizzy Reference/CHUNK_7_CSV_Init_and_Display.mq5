//============================= CHUNK 7: CSV INIT & DISPLAY ==============//
// ADD THIS AFTER CHUNK 6
//========================================================================//

//========================================================================//
//=================== INITIALIZE SIGNAL LOG ==============================//
//========================================================================//

bool InitSignalLog()
{
   signalLogHandle = FileOpen(InpSignalLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(signalLogHandle == INVALID_HANDLE)
   {
      Print("Failed to create signal log: ", InpSignalLogFile);
      return false;
   }
   
   // *** v5.0: COMPREHENSIVE signal logging header (20 columns) ***
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

//========================================================================//
//=================== INITIALIZE TRADE LOG ===============================//
//========================================================================//

bool InitTradeLog()
{
   tradeLogHandle = FileOpen(InpTradeLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(tradeLogHandle == INVALID_HANDLE)
   {
      Print("Failed to create trade log: ", InpTradeLogFile);
      return false;
   }
   
   // *** v5.0: COMPREHENSIVE trade logging header (35 columns) ***
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

//========================================================================//
//=================== UPDATE DISPLAY =====================================//
//========================================================================//

void UpdateDisplay(int signal, double quality, double confluence, 
                   double tradingZone, double volRegime, double entropy)
{
   // Get MA crossover status for display
   double maFastEntry[1], maSlowEntry[1], maFastExit[1], maSlowExit[1];
   CopyBuffer(maFastEntry_Handle, 0, 0, 1, maFastEntry);
   CopyBuffer(maSlowEntry_Handle, 0, 0, 1, maSlowEntry);
   CopyBuffer(maFastExit_Handle, 0, 0, 1, maFastExit);
   CopyBuffer(maSlowExit_Handle, 0, 0, 1, maSlowExit);
   
   string maEntryStatus = (maFastEntry[0] > maSlowEntry[0]) ? "🟢 BULLISH" : "🔴 BEARISH";
   string maExitStatus = (maFastExit[0] > maSlowExit[0]) ? "🟢 ABOVE" : "🔴 BELOW";
   
   // Mode string
   string modeStr = "";
   if(!InpUsePhysics && !InpUseTickPhysicsIndicator)
      modeStr = "MA Crossover ONLY (Baseline)";
   else if(InpUsePhysics && InpUseTickPhysicsIndicator)
      modeStr = "MA Crossover + Physics Filters";
   else
      modeStr = "Hybrid Mode";
   
   // Zone string
   string zoneStr = (tradingZone == 0) ? "🟢 BULL" :
                    (tradingZone == 1) ? "🔴 BEAR" :
                    (tradingZone == 2) ? "🟡 TRANS" : "⚫ AVOID";
   
   string signalStr = (signal == 1) ? "🟢 BUY SIGNAL" :
                      (signal == -1) ? "🔴 SELL SIGNAL" : "⚪ NO SIGNAL";
   
   // Filter status
   string filterStatus = "";
   if(InpUsePhysics)
      filterStatus = "✅ ON";
   else
      filterStatus = "❌ OFF";
   
   // Current price
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double dailyPnL = GetDailyPnL();
   
   Comment(StringFormat(
      "╔═════════════════════════════════════════════════╗\n"
      "║  %s v%s  ║\n"
      "║  MODE: %-36s  ║\n"
      "╠═════════════════════════════════════════════════╣\n"
      "║  📊 MA CROSSOVER STATUS                         ║\n"
      "║  Entry:  %-37s  ║\n"
      "║  Exit:   %-37s  ║\n"
      "║  Signal: %-37s  ║\n"
      "╠═════════════════════════════════════════════════╣\n"
      "║  ⚙️  CONFIGURATION                               ║\n"
      "║  Physics Filters:  %-27s  ║\n"
      "║  TickPhysics Ind:  %-27s  ║\n"
      "║  Entropy Filter:   %-27s  ║\n"
      "║  Zone Filter:      %-27s  ║\n"
      "║  Regime Filter:    %-27s  ║\n"
      "║  Session Filter:   %-27s  ║\n"
      "║  Daily Limits:     %-27s  ║\n"
      "╠═════════════════════════════════════════════════╣\n"
      "║  💰 TRADING STATUS                              ║\n"
      "║  Price:           $%-28.2f  ║\n"
      "║  Positions:       %-2d / %-2d                    ║\n"
      "║  Daily P/L:       %-7.2f%%                     ║\n"
      "║  Daily Trades:    %-3d                          ║\n"
      "║  Consec Losses:   %-2d                           ║\n"
      "║  Status:          %-28s  ║\n"
      "╠═════════════════════════════════════════════════╣\n"
      "║  📈 PHYSICS METRICS (if enabled)                ║\n"
      "║  Quality:    %-6.1f  |  Confluence: %-6.1f    ║\n"
      "║  Zone:       %-28s  ║\n"
      "║  Entropy:    %-7.2f  %-20s  ║\n"
      "╚═════════════════════════════════════════════════╝",
      EA_NAME, EA_VERSION,
      modeStr,
      maEntryStatus,
      maExitStatus,
      signalStr,
      filterStatus,
      (InpUseTickPhysicsIndicator ? "✅ ON" : "❌ OFF"),
      (InpUseEntropyFilter ? "✅ ON" : "❌ OFF"),
      (InpRequireGreenZone ? "✅ ON" : "❌ OFF"),
      (InpTradeOnlyNormalRegime ? "✅ ON" : "❌ OFF"),
      (InpUseSessionFilter ? "✅ ON" : "❌ OFF"),
      (InpPauseOnLimits ? "✅ ON" : "❌ OFF"),
      currentPrice,
      CountPositions(), InpMaxPositions,
      dailyPnL,
      dailyTradeCount,
      consecutiveLosses,
      (dailyPaused ? "⏸️ PAUSED" : "✅ ACTIVE"),
      quality, confluence,
      zoneStr,
      entropy, 
      (entropy > InpMaxEntropy ? "(🔴 CHAOS)" : entropy > InpMaxEntropy * 0.7 ? "(🟡 NOISY)" : "(🟢 CLEAN)")
   ));
}

//============================= END OF CHUNK 7 ===========================//
// NEXT: Copy Chunk 8 (OnInit, OnDeinit, and OnTick - THE FINAL CHUNK!)
