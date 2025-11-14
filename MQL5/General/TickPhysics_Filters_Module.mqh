//+------------------------------------------------------------------+
//| TickPhysics_Filters_Module.mqh                                    |
//| Physics-based entry filtering for TickPhysics EA                  |
//| ADD THIS CODE TO YOUR EA AFTER THE GLOBAL VARIABLES SECTION      |
//+------------------------------------------------------------------+

//===================================================================//
// PHYSICS FILTER FUNCTIONS - ADD THESE TO YOUR EA
//===================================================================//

//+------------------------------------------------------------------+
//| Check if physics metrics pass entry filters                      |
//| CRITICAL: This function MUST be called before opening trades     |
//+------------------------------------------------------------------+
bool CheckPhysicsFilters(int signal, double quality, double confluence, 
                        double zone, double regime, double entropy,
                        string &rejectReason)
{
   // If physics not enabled, pass all trades
   if(!InpUsePhysics || !InpUseTickPhysicsIndicator)
   {
      rejectReason = "PhysicsDisabled";
      return true;
   }
   
   // Quality filter
   if(quality < InpMinTrendQuality)
   {
      rejectReason = StringFormat("QualityLow_%.1f<%.1f", quality, InpMinTrendQuality);
      Print("❌ Physics Filter REJECT: Quality too low: ", quality, " < ", InpMinTrendQuality);
      return false;
   }
   
   // Confluence filter
   if(confluence < InpMinConfluence)
   {
      rejectReason = StringFormat("ConfluenceLow_%.1f<%.1f", confluence, InpMinConfluence);
      Print("❌ Physics Filter REJECT: Confluence too low: ", confluence, " < ", InpMinConfluence);
      return false;
   }
   
   // Trading Zone filter
   if(InpRequireGreenZone)
   {
      // Zone encoding from indicator:
      // 0 = GREEN (bull high-quality)
      // 1 = RED (bear high-quality)
      // 2 = GOLD (transition)
      // 3 = GRAY (avoid)
      
      if(signal == 1)  // BUY signal
      {
         if(zone != 0)  // Require GREEN zone
         {
            string zoneStr = (zone == 1) ? "RED" : (zone == 2) ? "GOLD" : "GRAY";
            rejectReason = StringFormat("ZoneMismatch_BUY_in_%s", zoneStr);
            Print("❌ Physics Filter REJECT: BUY signal but not in GREEN zone. Zone=", zoneStr);
            return false;
         }
      }
      else if(signal == -1)  // SELL signal
      {
         if(zone != 1)  // Require RED zone
         {
            string zoneStr = (zone == 0) ? "GREEN" : (zone == 2) ? "GOLD" : "GRAY";
            rejectReason = StringFormat("ZoneMismatch_SELL_in_%s", zoneStr);
            Print("❌ Physics Filter REJECT: SELL signal but not in RED zone. Zone=", zoneStr);
            return false;
         }
      }
   }
   
   // Volatility Regime filter
   if(InpTradeOnlyNormalRegime)
   {
      // Regime encoding from indicator:
      // 0 = LOW volatility
      // 1 = NORMAL volatility
      // 2 = HIGH volatility
      
      if(regime != 1)
      {
         string regimeStr = (regime == 0) ? "LOW" : "HIGH";
         rejectReason = StringFormat("RegimeWrong_%s", regimeStr);
         Print("❌ Physics Filter REJECT: Not in NORMAL regime. Regime=", regimeStr);
         return false;
      }
   }
   
   // Entropy (chaos) filter
   if(InpUseEntropyFilter)
   {
      if(entropy > InpMaxEntropy)
      {
         rejectReason = StringFormat("EntropyChaotic_%.2f>%.2f", entropy, InpMaxEntropy);
         Print("❌ Physics Filter REJECT: Entropy too high (market chaos): ", entropy, " > ", InpMaxEntropy);
         return false;
      }
   }
   
   // Momentum filter (optional, if you want to use it)
   // Commented out by default - uncomment if needed
   /*
   if(InpMinMomentum > 0)
   {
      // You'll need to read momentum from indicator buffer
      double momentumBuf[1];
      if(CopyBuffer(indicatorHandle, BUFFER_MOMENTUM, 0, 1, momentumBuf) > 0)
      {
         double momentum = momentumBuf[0];
         if(MathAbs(momentum) < InpMinMomentum)
         {
            rejectReason = StringFormat("MomentumWeak_%.1f<%.1f", momentum, InpMinMomentum);
            Print("❌ Physics Filter REJECT: Momentum too weak: ", momentum, " < ", InpMinMomentum);
            return false;
         }
      }
   }
   */
   
   // All filters passed!
   rejectReason = "PASS";
   Print("✅ Physics Filter PASS: Quality=", quality, " Confluence=", confluence, 
         " Zone=", zone, " Regime=", regime, " Entropy=", entropy);
   return true;
}

//+------------------------------------------------------------------+
//| Enhanced spread check (add to ValidateTrade function)            |
//+------------------------------------------------------------------+
bool CheckSpreadFilter(double &spreadValue)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   if(point <= 0) return false;
   
   spreadValue = (ask - bid) / point;
   
   if(spreadValue > InpMaxSpread)
   {
      Print("❌ SPREAD FILTER REJECT: Spread=", spreadValue, " points > Max=", InpMaxSpread);
      return false;
   }
   
   return true;
}

//===================================================================//
// MODIFIED OnTick() - REPLACE YOUR EXISTING OnTick() WITH THIS
//===================================================================//

void OnTick()
{
   lastTickTime = TimeCurrent();  // Watchdog
   
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;
   
   // Update custom MA lines on new bar
   if(InpShowMALines)
   {
      DrawCustomMALines();
   }
   
   CheckDailyReset();
   
   if(dailyPaused)
   {
      Comment("⏸️ EA PAUSED - Daily limits reached\n",
              "Daily P/L: ", DoubleToString(GetDailyPnL(), 2), "%\n",
              "Resets at midnight");
      return;
   }
   
   if(InpUseSessionFilter && !IsWithinSession())
      return;
   
   // Get MA crossover signals
   int signal = GetMACrossoverSignal();
   
   // Initialize physics metrics (default to 0 when physics is disabled)
   double quality = 0.0;
   double confluence = 0.0;
   double momentum = 0.0;
   double tradingZone = 0.0;
   double volRegime = 0.0;
   double entropy = 0.0;
   
   // If physics is enabled, read from indicator
   if(InpUsePhysics && InpUseTickPhysicsIndicator)
   {
      double qualityBuf[1], confluenceBuf[1], momentumBuf[1], zoneBuf[1], regimeBuf[1], entropyBuf[1];
      if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qualityBuf) > 0)
         quality = qualityBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, confluenceBuf) > 0)
         confluence = confluenceBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_MOMENTUM, 0, 1, momentumBuf) > 0)
         momentum = momentumBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_TRADING_ZONE, 0, 1, zoneBuf) > 0)
         tradingZone = zoneBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_VOL_REGIME, 0, 1, regimeBuf) > 0)
         volRegime = regimeBuf[0];
      if(CopyBuffer(indicatorHandle, BUFFER_ENTROPY, 0, 1, entropyBuf) > 0)
         entropy = entropyBuf[0];
   }
   
   // *** CRITICAL FIX: Apply physics filters BEFORE trading ***
   string rejectReason = "";
   bool physicsPass = CheckPhysicsFilters(signal, quality, confluence, tradingZone, 
                                          volRegime, entropy, rejectReason);
   
   // Log ALL signals (including rejected ones) for analysis
   if(InpEnableSignalLog && signal != 0)
   {
      LogSignal(signal, quality, confluence, momentum, tradingZone, volRegime, entropy, 
                physicsPass, rejectReason);
   }
   
   // Entry logic - NOW WITH PHYSICS FILTER CHECK
   if(signal == 1 && CountPositions() < InpMaxPositions && consecutiveLosses < InpMaxConsecutiveLosses)
   {
      if(physicsPass)  // *** NEW: Only trade if physics filters pass ***
      {
         if(OpenPosition(ORDER_TYPE_BUY))
         {
            dailyTradeCount++;
         }
      }
      else
      {
         Print("⚠️ BUY signal REJECTED by physics filters: ", rejectReason);
      }
   }
   else if(signal == -1 && CountPositions() < InpMaxPositions && consecutiveLosses < InpMaxConsecutiveLosses)
   {
      if(physicsPass)  // *** NEW: Only trade if physics filters pass ***
      {
         if(OpenPosition(ORDER_TYPE_SELL))
         {
            dailyTradeCount++;
         }
      }
      else
      {
         Print("⚠️ SELL signal REJECTED by physics filters: ", rejectReason);
      }
   }
   
   // Exit management
   ManagePositions();
   UpdateDisplay(signal, quality, confluence, tradingZone, volRegime, entropy);
}

//===================================================================//
// ENHANCED SIGNAL LOGGING - ADD THIS FUNCTION
//===================================================================//

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
   
   // Write comprehensive signal data
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

//===================================================================//
// INSTRUCTIONS FOR INTEGRATION
//===================================================================//

/*
TO INTEGRATE THIS MODULE INTO YOUR EA:

1. COPY the CheckPhysicsFilters() function
   - Add AFTER your global variables section
   - Add BEFORE OnTick()

2. COPY the CheckSpreadFilter() function
   - Add after CheckPhysicsFilters()

3. REPLACE your entire OnTick() function
   - With the modified OnTick() from this file
   - This includes the physics filter checks

4. ADD the LogSignal() function
   - Place after your LogTrade() function

5. UPDATE InitSignalLog() function
   - Replace the FileWrite header line with the new comprehensive version
   - See the header in LogSignal() function

6. COMPILE and test on demo

TESTING CHECKLIST:
- [ ] EA compiles with 0 errors
- [ ] Physics filters disabled: Trades execute on crossover only (baseline)
- [ ] Physics filters enabled: Trades require BOTH crossover AND physics pass
- [ ] Signal CSV logs all signals (including rejected ones)
- [ ] RejectReason column shows WHY signals were rejected
- [ ] No trades execute when Quality < threshold
- [ ] No trades execute when Confluence < threshold
- [ ] Zone filter works (if enabled)
- [ ] Regime filter works (if enabled)
- [ ] Entropy filter works (if enabled)

EXPECTED BEHAVIOR:
1. With Physics DISABLED:
   - All crossovers execute (like current behavior)
   - Physics columns in CSV show 0 values
   - RejectReason = "PhysicsDisabled"

2. With Physics ENABLED:
   - Only high-quality crossovers execute
   - Physics columns show actual values
   - Rejected signals logged with reason
   - Expect 30-60% fewer trades but higher win rate

*/
