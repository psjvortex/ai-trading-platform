//+------------------------------------------------------------------+
//|                         TP_Integrated_EA_Crossover_3_2.mq5       |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|      PHYSICS-REFINED OPTIMIZATION - Winner Analysis Thresholds   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "3.2"
#property description "v3.2: Physics-refined from v3.1 winner analysis (7W/5L, 58.3% WR)"
#property description "KEY FINDING: Momentum separation - Winners avg 292.8 vs Losers 9.6"
#property description "Refined: MinQuality 75.7, MinConfluence 80.0, MinMomentum -437.77"

// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "3.2"

input int MagicNumber = 300302;                // EA magic number (v3.2)
input string TradeComment = "TP_Integrated 3_2";   // Trade comment

#include <Trade/Trade.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>
#include <TickPhysics/TP_Risk_Manager.mqh>
#include <TickPhysics/TP_Trade_Tracker.mqh>
#include <TickPhysics/TP_CSV_Logger.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

// === Risk Management ===
input group "💰 Risk Management"
input double RiskPercentPerTrade = 1.0;        // Risk per trade (% of balance) - BASELINE SAFE
input double MaxDailyRisk = 10.0;              // Max daily risk (% of balance)
input int MaxConcurrentTrades = 1;             // Max concurrent positions - BASELINE ONE AT A TIME
input double MinRRatio = 1.0;                  // Min reward:risk ratio - BASELINE DISABLED

// === Trade Parameters ===
input group "📊 Trade Parameters - BASELINE DISABLED"
input int StopLossPips = 0;                    // Stop loss (pips) - BASELINE DISABLED
input int TakeProfitPips = 0;                  // Take profit (pips) - BASELINE DISABLED
input bool UseTrailingStop = false;            // Enable trailing stop
input int TrailingStopPips = 30;               // Trailing stop (pips)

// === Entry System Selection ===
input group "📊 Entry Logic"
input bool UsePhysicsEntry = false;            // Use physics acceleration crossover
input bool UseMAEntry = true;                  // Use Moving Average crossover
input int MA_Fast = 10;                        // Fast MA period
input int MA_Slow = 50;                        // Slow MA period (increased for smoother signals)
input ENUM_MA_METHOD MA_Method = MODE_EMA;     // MA calculation method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // MA price type

// === Signal Filters ===
input group "🎯 Physics Filters - v3.2 WINNER-REFINED (from v3.1 analysis)"
input bool UsePhysicsFilters = true;            // Enable physics filtering - v3.2 WINNER-TUNED
input double MinQuality = 75.7;                // Min physics quality - v3.2: 75% of winners above this
input double MinConfluence = 80.0;             // Min confluence - v3.2: Winner median (stronger filter)
input double MinMomentum = -437.77;            // Min momentum - v3.2: CRITICAL (Winners 292.8 vs Losers 9.6)
input bool UseZoneFilter = true;                // Filter by trading zone - KEEP (avoid BEAR)
input bool UseRegimeFilter = true;              // Filter by volatility regime - KEEP (avoid LOW)

// === Time Filters ===
input group "⏰ Time Filters - v3.1 DATA-DRIVEN (Hourly Performance)"
input bool UseTimeFilter = true;                // Enable time filtering - v3.1 OPTIMIZED
input string AllowedHoursInput = "2,12,19,23";  // Allowed trading hours (high WR: 45%, 33%, 39%, 35%)
input string BlockedHoursInput = "3,4,5,6,7,8,9,11,14,20"; // Blocked hours (WR < 25%)
input bool UseDayFilter = false;                // Enable day-of-week filter
input bool AvoidWednesday = false;              // Avoid Wednesday trading

// === Monitoring ===
input group "📈 Post-Trade Monitoring"
input int PostExitMonitorBars = 50;            // RunUp/RunDown monitor bars
input bool EnableRealTimeLogging = true;       // Log signals in real-time

// === Advanced ===
input group "⚙️ Advanced Settings"
input bool EnableDebugMode = true;             // Verbose logging


//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+


CPhysicsIndicator g_physics;
CRiskManager g_riskManager;
CTradeTracker g_tracker;
CCSVLogger g_logger;
CTrade g_trade;

string g_indicatorName = "TickPhysics_Crypto_Indicator_v2_1";  // Update per symbol type
bool g_initialized = false;
datetime g_lastBarTime = 0;

// MA indicator handles
int g_maFastHandle = INVALID_HANDLE;
int g_maSlowHandle = INVALID_HANDLE;

// Chart objects for MA display
string g_maFastName = "MA_Fast";
string g_maSlowName = "MA_Slow";

// Time filter arrays
int g_allowedHours[];
int g_blockedHours[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics Integrated EA v3.2 - PHYSICS-REFINED OPTIMIZATION");
   Print("═══════════════════════════════════════════════════════");
   Print("📊 Based on v3.1 winner analysis (7W/5L, 58.3% WR, 2.30 PF)");
   Print("🎯 KEY INSIGHT: Momentum is critical (Winners 292.8 vs Losers 9.6)");
   Print("🔬 Refined thresholds: Q=75.7, C=80.0, M=-437.77");
   Print("═══════════════════════════════════════════════════════");
   
   // 1. Initialize Physics Indicator
   Print("📊 Initializing Physics Indicator...");
   if(!g_physics.Initialize(g_indicatorName, EnableDebugMode))
   {
      Print("❌ FAILED: Physics Indicator initialization");
      return INIT_FAILED;
   }
   Print("✅ Physics Indicator ready");
   
   // 2. Initialize Risk Manager
   Print("💰 Initializing Risk Manager...");
   if(!g_riskManager.Initialize(_Symbol, EnableDebugMode))
   {
      Print("❌ FAILED: Risk Manager initialization");
      return INIT_FAILED;
   }
   Print("✅ Risk Manager ready");
   
   // 3. Initialize Trade Tracker
   Print("📈 Initializing Trade Tracker...");
   TrackerConfig trackerConfig;
   trackerConfig.trackMFEMAE = true;
   trackerConfig.trackPostExit = true;
   trackerConfig.postExitMonitorBars = PostExitMonitorBars;
   trackerConfig.autoLogTrades = false;  // We'll control logging
   trackerConfig.debugMode = EnableDebugMode;
   
   if(!g_tracker.Initialize(_Symbol, trackerConfig))
   {
      Print("❌ FAILED: Trade Tracker initialization");
      return INIT_FAILED;
   }
   Print("✅ Trade Tracker ready");
   
   // 4. Initialize CSV Logger
   Print("📝 Initializing CSV Logger...");
   LoggerConfig loggerConfig;
   loggerConfig.signalLogFile = "TP_Integrated_Signals_" + _Symbol + "_v" + EA_VERSION + ".csv";
   loggerConfig.tradeLogFile = "TP_Integrated_Trades_" + _Symbol + "_v" + EA_VERSION + ".csv";
   loggerConfig.createHeaders = true;
   loggerConfig.appendMode = true;  // Append for production
   loggerConfig.timestampFiles = false;
   loggerConfig.logToExpertLog = EnableRealTimeLogging;
   loggerConfig.debugMode = EnableDebugMode;
   
   if(!g_logger.Initialize(_Symbol, loggerConfig))
   {
      Print("❌ FAILED: CSV Logger initialization");
      return INIT_FAILED;
   }
   Print("✅ CSV Logger ready");
   
   // 5. Initialize MA indicators (if using MA entry)
   if(UseMAEntry)
   {
      Print("📊 Initializing MA indicators...");
      g_maFastHandle = iMA(_Symbol, PERIOD_CURRENT, MA_Fast, 0, MA_Method, MA_Price);
      g_maSlowHandle = iMA(_Symbol, PERIOD_CURRENT, MA_Slow, 0, MA_Method, MA_Price);
      
      if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
      {
         Print("❌ FAILED: MA indicator initialization");
         return INIT_FAILED;
      }
      Print("✅ MA indicators ready (Fast:", MA_Fast, ", Slow:", MA_Slow, ")");
      
      // Draw MA indicators on chart
      DrawMAIndicators();
   }
   
   // 6. Parse time filter configuration (v3.1 NEW)
   if(UseTimeFilter)
   {
      Print("⏰ Parsing time filter configuration...");
      ParseTimeFilterConfig();
      Print("✅ Time filters configured");
      Print("   Allowed hours: ", AllowedHoursInput);
      Print("   Blocked hours: ", BlockedHoursInput);
   }
   
   // 7. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v3.2 PHYSICS-REFINED OPTIMIZATION!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v3.2 (Physics-Refined from v3.1 Winners)");
   Print("   🎯 OPTIMIZATION: Zone/Regime/Time + Physics Thresholds");
   Print("   Entry System: ", UsePhysicsEntry ? "PHYSICS" : (UseMAEntry ? "MA CROSSOVER" : "NONE"));
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   Print("   Physics Filters: ", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED (logging only)");
   if(UsePhysicsFilters)
   {
      Print("   → Quality Filter: MinQuality=", MinQuality, " (v3.2: 75% of winners above)");
      Print("   → Confluence Filter: MinConfluence=", MinConfluence, " (v3.2: Winner median)");
      Print("   → Momentum Filter: MinMomentum=", MinMomentum, " (v3.2: CRITICAL - Winners 292.8 vs Losers 9.6)");
      Print("   → Zone Filter: ", UseZoneFilter ? "ENABLED (Avoid BEAR)" : "DISABLED");
      Print("   → Regime Filter: ", UseRegimeFilter ? "ENABLED (Avoid LOW)" : "DISABLED");
   }
   if(UseTimeFilter)
   {
      Print("   ⏰ Time Filter: ENABLED (Optimal Hours Only)");
      Print("   → Allowed: ", AllowedHoursInput);
      Print("   → Blocked: ", BlockedHoursInput);
   }
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", MaxDailyRisk, "%");
   Print("   Max Concurrent: ", MaxConcurrentTrades, " trades");
   Print("   SL/TP: ", StopLossPips, "/", TakeProfitPips, " pips (still disabled for v3.2)");
   Print("   Post-Exit Monitor: ", PostExitMonitorBars, " bars");
   Print("   CSV Files: ", "v3.2 (Trades & Signals)");;;
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 TickPhysics Integrated EA - Shutting Down");
   Print("   Reason: ", reason);
   Print("═══════════════════════════════════════════════════════");
   
   // Remove MA chart objects
   if(UseMAEntry)
   {
      ChartIndicatorDelete(0, 0, g_maFastName);
      ChartIndicatorDelete(0, 0, g_maSlowName);
      Print("✅ MA indicators removed from chart");
   }
   
   // Log any completed trades
   ClosedTrade trade;
   int logged = 0;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      LogCompletedTrade(trade);
      logged++;
   }
   
   if(logged > 0)
      Print("✅ Logged ", logged, " completed trades to CSV");
   
   // Print final statistics
   g_tracker.PrintActiveTradesStatus();
   g_tracker.PrintClosedTradesStatus();
   
   Print("═══════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized) return;
   
   // Update trade tracker every tick (MFE/MAE + RunUp/RunDown)
   g_tracker.UpdateTrades();
   
   // Check for completed trades
   ClosedTrade trade;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      Print("");
      Print("✅ TRADE MONITORING COMPLETE!");
      Print("   Ticket: #", trade.ticket);
      Print("   Exit: ", trade.exitReason);
      Print("   Profit: ", trade.profit, " (", trade.pips, " pips)");
      Print("   RunUp: ", trade.runUpPips, " pips");
      Print("   RunDown: ", trade.runDownPips, " pips");
      
      LogCompletedTrade(trade);
   }
   
   // Process new bar
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      OnNewBar();
   }
}

//+------------------------------------------------------------------+
//| Generate trading signal - Switchable entry systems               |
//| Returns: 1 = BUY, -1 = SELL, 0 = NONE                            |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   if(UsePhysicsEntry)
      return GeneratePhysicsSignal();
   else if(UseMAEntry)
      return GenerateMASignal();
   else
      return 0;  // No entry system enabled
}

//+------------------------------------------------------------------+
//| Physics-based signal (acceleration crossover)                    |
//+------------------------------------------------------------------+
int GeneratePhysicsSignal()
{
   // Get current and previous physics metrics
   double accel_0 = g_physics.GetAcceleration(0);
   double accel_1 = g_physics.GetAcceleration(1);
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   
   // BUY Signal: Acceleration crosses above zero with positive momentum
   if(accel_1 < 0 && accel_0 > 0 && momentum > 0 && speed > 0)
   {
      return 1;  // BUY
   }
   
   // SELL Signal: Acceleration crosses below zero with negative momentum
   if(accel_1 > 0 && accel_0 < 0 && momentum < 0 && speed < 0)
   {
      return -1;  // SELL
   }
   
   return 0;  // No signal
}

//+------------------------------------------------------------------+
//| Moving Average crossover signal                                  |
//+------------------------------------------------------------------+
int GenerateMASignal()
{
   if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
      return 0;
   
   // Get MA values - need 3 bars (0, 1, 2) to check crossover on closed bars
   double maFast[], maSlow[];
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   
   if(CopyBuffer(g_maFastHandle, 0, 0, 3, maFast) < 3) return 0;
   if(CopyBuffer(g_maSlowHandle, 0, 0, 3, maSlow) < 3) return 0;
   
   // BUY Signal: Fast MA crosses above Slow MA on CLOSED bars (bar 1 vs bar 2)
   if(maFast[2] <= maSlow[2] && maFast[1] > maSlow[1])
   {
      if(EnableDebugMode)
         Print("🟢 MA BUY SIGNAL: Fast(", maFast[1], ") crossed above Slow(", maSlow[1], ") [bar 1 vs bar 2]");
      return 1;  // BUY
   }
   
   // SELL Signal: Fast MA crosses below Slow MA on CLOSED bars (bar 1 vs bar 2)
   if(maFast[2] >= maSlow[2] && maFast[1] < maSlow[1])
   {
      if(EnableDebugMode)
         Print("🔴 MA SELL SIGNAL: Fast(", maFast[1], ") crossed below Slow(", maSlow[1], ") [bar 1 vs bar 2]");
      return -1;  // SELL
   }
   
   return 0;  // No crossover
}

//+------------------------------------------------------------------+
//| Parse time filter configuration from input strings               |
//+------------------------------------------------------------------+
void ParseTimeFilterConfig()
{
   // Parse allowed hours
   ArrayResize(g_allowedHours, 0);
   string allowed_parts[];
   int allowed_count = StringSplit(AllowedHoursInput, ',', allowed_parts);
   
   if(allowed_count > 0 && AllowedHoursInput != "")
   {
      ArrayResize(g_allowedHours, allowed_count);
      for(int i = 0; i < allowed_count; i++)
      {
         g_allowedHours[i] = (int)StringToInteger(allowed_parts[i]);
      }
   }
   
   // Parse blocked hours
   ArrayResize(g_blockedHours, 0);
   string blocked_parts[];
   int blocked_count = StringSplit(BlockedHoursInput, ',', blocked_parts);
   
   if(blocked_count > 0 && BlockedHoursInput != "")
   {
      ArrayResize(g_blockedHours, blocked_count);
      for(int i = 0; i < blocked_count; i++)
      {
         g_blockedHours[i] = (int)StringToInteger(blocked_parts[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if current time passes time filters                        |
//+------------------------------------------------------------------+
bool PassTimeFilters()
{
   if(!UseTimeFilter) return true;  // Filters disabled
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int current_hour = dt.hour;
   int current_dow = dt.day_of_week;
   
   // Check blocked hours first (highest priority)
   if(ArraySize(g_blockedHours) > 0)
   {
      for(int i = 0; i < ArraySize(g_blockedHours); i++)
      {
         if(current_hour == g_blockedHours[i])
         {
            if(EnableDebugMode)
               Print("⏰ Time filter REJECT: Hour ", current_hour, " is blocked");
            return false;
         }
      }
   }
   
   // Check allowed hours (if specified)
   if(ArraySize(g_allowedHours) > 0)
   {
      bool found = false;
      for(int i = 0; i < ArraySize(g_allowedHours); i++)
      {
         if(current_hour == g_allowedHours[i])
         {
            found = true;
            break;
         }
      }
      
      if(!found)
      {
         if(EnableDebugMode)
            Print("⏰ Time filter REJECT: Hour ", current_hour, " not in allowed list");
         return false;
      }
   }
   
   // Check day filter
   if(UseDayFilter && AvoidWednesday && current_dow == 3)  // Wednesday = 3
   {
      if(EnableDebugMode)
         Print("⏰ Time filter REJECT: Wednesday trading disabled");
      return false;
   }
   
   return true;  // All time filters passed
}

//+------------------------------------------------------------------+
//| New bar handler - Signal generation and trade logic              |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // 1. Check time filters FIRST (before generating signals)
   if(!PassTimeFilters())
   {
      return;  // Outside allowed trading hours
   }
   
   // 2. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 3. Log signal (regardless of quality)
   if(EnableRealTimeLogging)
   {
      LogSignal(signal, quality, confluence, zone, regime);
   }
   
   // 4. Check if we should trade
   if(signal == 0) return;  // No signal
   
   // 5. Apply physics filters (v3.2 WINNER-REFINED)
   string rejectReason = "";
   bool passFilters = true;
   
   if(UsePhysicsFilters)
   {
      // Quality filter (v3.2: 75.7 = 75% of winners above this)
      if(quality < MinQuality)
      {
         rejectReason = "Quality too low (v3.2: need " + DoubleToString(MinQuality, 1) + "+)";
         passFilters = false;
      }
      // Confluence filter (v3.2: 80.0 = winner median)
      else if(confluence < MinConfluence)
      {
         rejectReason = "Confluence too low (v3.2: need " + DoubleToString(MinConfluence, 1) + "+)";
         passFilters = false;
      }
      // Momentum filter (v3.2: CRITICAL - Winners avg 292.8 vs Losers 9.6)
      else if(momentum < MinMomentum)
      {
         rejectReason = "Momentum too low (v3.2: need " + DoubleToString(MinMomentum, 2) + "+ | Winners avg 292.8 vs Losers 9.6)";
         passFilters = false;
      }
      // Zone filter: AVOID BEAR zone (v3.0 analysis: 19.0% WR, -$0.36 avg)
      else if(UseZoneFilter && zone == ZONE_BEAR)
      {
         rejectReason = "BEAR zone (v3.0: 19.0% WR - WORST PERFORMER)";
         passFilters = false;
      }
      // Regime filter: AVOID LOW volatility (v3.0 analysis: 21.2% WR, -$0.02 avg)
      else if(UseRegimeFilter && regime == REGIME_LOW)
      {
         rejectReason = "LOW volatility regime (v3.0: 21.2% WR - POOR PERFORMER)";
         passFilters = false;
      }
      
      if(!passFilters)
      {
         if(EnableDebugMode)
            Print("🚫 Signal rejected: ", rejectReason, 
                  " | Q=", quality, " C=", confluence, " M=", momentum,
                  " Zone=", g_physics.GetZoneName(zone), " Regime=", g_physics.GetRegimeName(regime));
         return;
      }
      else if(EnableDebugMode)
      {
         // Log when we ACCEPT a trade due to good filters
         Print("✅ Signal ACCEPTED (v3.2 physics-refined):");
         Print("   Quality:    ", quality, " >= ", MinQuality, " ✓");
         Print("   Confluence: ", confluence, " >= ", MinConfluence, " ✓");
         Print("   Momentum:   ", momentum, " >= ", MinMomentum, " ✓ (CRITICAL)");
         Print("   Zone:       ", g_physics.GetZoneName(zone), " (BEAR filtered) ✓");
         Print("   Regime:     ", g_physics.GetRegimeName(regime), " (LOW filtered) ✓");
      }
   }
   else
   {
      // Physics filters disabled - log but don't filter
      if(EnableDebugMode)
         Print("✅ Physics filters DISABLED - accepting all signals (Q=", quality, ", C=", confluence, ", M=", momentum, ")");
   }
   
   // 5. Close opposite positions if any (for crossover reversal)
   int closedCount = CloseOppositePositions(signal);
   
   if(EnableDebugMode)
      Print("🔍 Pre-delay check: Closed=", closedCount, " | Remaining positions=", PositionsTotal());
   
   // If we closed positions, give MT5 a moment to process (avoid race condition)
   if(closedCount > 0)
   {
      Sleep(500);  // 500ms delay to ensure position is fully closed
      if(EnableDebugMode)
         Print("⏱️  Waited 500ms for position close to process");
   }
   
   // 6. Double-check position count after delay
   int remainingPositions = PositionsTotal();
   if(EnableDebugMode)
   {
      Print("📊 Post-delay check: Total positions=", remainingPositions);
      
      // Show what positions remain
      if(remainingPositions > 0)
      {
         for(int i = 0; i < remainingPositions; i++)
         {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket))
            {
               string posSymbol = PositionGetString(POSITION_SYMBOL);
               int posMagic = (int)PositionGetInteger(POSITION_MAGIC);
               ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               
               Print("   Position #", ticket, ": ", 
                     posType == POSITION_TYPE_BUY ? "BUY" : "SELL",
                     " | Symbol=", posSymbol,
                     " | Magic=", posMagic,
                     " | OurMagic=", MagicNumber);
            }
         }
      }
   }
   
   // 7. Check if we have any existing position in the signal direction
   // (Don't open duplicate positions)
   bool hasSameDirection = HasPositionInDirection(signal);
   
   if(EnableDebugMode)
      Print("🔍 Duplicate check: Signal=", signal > 0 ? "BUY" : "SELL", " | HasSameDirection=", hasSameDirection);
   
   if(hasSameDirection)
   {
      Print("⚠️  BLOCKED: Already have position in ", (signal > 0 ? "BUY" : "SELL"), " direction!");
      Print("   Signal: ", signal > 0 ? "BUY" : "SELL");
      Print("   Total positions: ", PositionsTotal());
      
      // Debug: Show all positions
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            Print("   Position #", PositionGetInteger(POSITION_TICKET), 
                  ": ", PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL",
                  " on ", PositionGetString(POSITION_SYMBOL),
                  " | Magic=", PositionGetInteger(POSITION_MAGIC));
         }
      }
      return;
   }
   
   // 8. Check risk limits
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   int openTrades = PositionsTotal();
   
   if(EnableDebugMode)
      Print("💰 Risk check: ", openTrades, " / ", MaxConcurrentTrades, " positions");
   
   if(openTrades >= MaxConcurrentTrades)
   {
      Print("🚫 Cannot open trade: Max concurrent trades reached (", openTrades, "/", MaxConcurrentTrades, ")");
      return;
   }
   
   // 9. Calculate position size
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   double slDistance = StopLossPips * point * pipMultiplier;
   double tpDistance = TakeProfitPips * point * pipMultiplier;
   
   // BASELINE MODE: If SL/TP disabled (0), use fixed lot size instead of risk-based
   double lots = 0.0;
   
   if(StopLossPips == 0 || slDistance <= 0)
   {
      // No stop loss - use minimal fixed lot size for BASELINE testing
      lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      
      if(EnableDebugMode)
         Print("📏 BASELINE MODE: Fixed lot size ", lots, " (no SL/TP)");
   }
   else
   {
      // Normal mode: Calculate lot size based on risk
      double riskMoney = balance * (RiskPercentPerTrade / 100.0);
      lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
      
      if(EnableDebugMode)
         Print("📏 Position size: ", lots, " lots (risk: $", riskMoney, ")");
   }
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size calculated: ", lots);
      return;
   }
   
   // 10. Validate R:R ratio (SKIP if SL/TP disabled)
   if(StopLossPips > 0 && TakeProfitPips > 0 && slDistance > 0)
   {
      double rRatio = tpDistance / slDistance;
      if(rRatio < MinRRatio)
      {
         Print("🚫 Trade rejected: R:R ratio too low (", DoubleToString(rRatio, 2), " < ", MinRRatio, ")");
         return;
      }
      
      if(EnableDebugMode)
         Print("✅ R:R ratio OK: ", DoubleToString(rRatio, 2));
   }
   else if(EnableDebugMode)
   {
      Print("✅ BASELINE MODE: R:R validation skipped (no SL/TP)");
   };
   
   // 11. Execute trade
   if(EnableDebugMode)
      Print("📊 Signal confirmed: ", (signal > 0 ? "BUY" : "SELL"), " | Closed opposite: ", closedCount);
   
   Print("🚀 EXECUTING TRADE NOW...");
   ExecuteTrade(signal, lots, price, slDistance, tpDistance, quality, confluence, zone, regime);
}

//+------------------------------------------------------------------+
//| Close positions in opposite direction                            |
//| Returns: number of positions closed                              |
//+------------------------------------------------------------------+
int CloseOppositePositions(int newSignal)
{
   if(newSignal == 0) return 0;  // No signal, nothing to close
   
   int closedCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Close BUY positions if new signal is SELL
      if(newSignal < 0 && posType == POSITION_TYPE_BUY)
      {
         Print("🔄 MA CROSSOVER REVERSAL: Closing BUY position #", ticket, " to open SELL");
         
         g_trade.SetExpertMagicNumber(MagicNumber);
         if(g_trade.PositionClose(ticket))
         {
            Print("✅ Position #", ticket, " closed successfully (REVERSAL)");
            closedCount++;
         }
         else
         {
            Print("❌ Failed to close position #", ticket, ": ", g_trade.ResultRetcodeDescription());
         }
      }
      // Close SELL positions if new signal is BUY
      else if(newSignal > 0 && posType == POSITION_TYPE_SELL)
      {
         Print("🔄 MA CROSSOVER REVERSAL: Closing SELL position #", ticket, " to open BUY");
         
         g_trade.SetExpertMagicNumber(MagicNumber);
         if(g_trade.PositionClose(ticket))
         {
            Print("✅ Position #", ticket, " closed successfully (REVERSAL)");
            closedCount++;
         }
         else
         {
            Print("❌ Failed to close position #", ticket, ": ", g_trade.ResultRetcodeDescription());
         }
      }
   }
   
   return closedCount;
}

//+------------------------------------------------------------------+
//| Check if we already have a position in the signal direction     |
//+------------------------------------------------------------------+
bool HasPositionInDirection(int signal)
{
   if(signal == 0) return false;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Check if we have a BUY position and signal is BUY
      if(signal > 0 && posType == POSITION_TYPE_BUY)
         return true;
      
      // Check if we have a SELL position and signal is SELL
      if(signal < 0 && posType == POSITION_TYPE_SELL)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, double lots, double price, double slDistance, double tpDistance,
                  double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   double sl = 0, tp = 0;
   bool success = false;
   ulong ticket = 0;
   
   // BASELINE MODE: Only set SL/TP if distances are non-zero
   if(StopLossPips > 0 && slDistance > 0)
   {
      sl = (signal > 0) ? (price - slDistance) : (price + slDistance);
   }
   
   if(TakeProfitPips > 0 && tpDistance > 0)
   {
      tp = (signal > 0) ? (price + tpDistance) : (price - tpDistance);
   }
   
   if(signal > 0)  // BUY
   {
      Print("🟢 Opening BUY: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp, " (BASELINE MODE)");
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();;
      
      if(!success)
      {
         Print("❌ BUY execution failed!");
         Print("   Return code: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         Print("   Lots: ", lots, " | Price: ", price, " | SL: ", sl, " | TP: ", tp);
         Print("   Current Ask: ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
         Print("   Current Bid: ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
         return;
      }
   }
   else  // SELL
   {
      Print("🔴 Opening SELL: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp, " (BASELINE MODE)");
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();;
      
      if(!success)
      {
         Print("❌ SELL execution failed!");
         Print("   Return code: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         Print("   Lots: ", lots, " | Price: ", price, " | SL: ", sl, " | TP: ", tp);
         Print("   Current Ask: ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
         Print("   Current Bid: ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
         return;
      }
   }
   
   Print("✅ Position opened: #", ticket);
   
   // Add to tracker
   if(g_tracker.AddTrade(ticket,
                        quality,
                        confluence,
                        g_physics.GetMomentum(),
                        g_physics.GetEntropy(),
                        g_physics.GetZoneName(zone),
                        g_physics.GetRegimeName(regime),
                        RiskPercentPerTrade))
   {
      Print("✅ Trade added to tracker");
   }
   else
   {
      Print("⚠️  Failed to add trade to tracker");
   }
}

//+------------------------------------------------------------------+
//| Log signal to CSV                                                 |
//+------------------------------------------------------------------+
void LogSignal(int signal, double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   SignalLogEntry entry;
   
   // EA version tracking
   entry.eaName = EA_NAME;
   entry.eaVersion = EA_VERSION;
   
   entry.timestamp = TimeCurrent();
   entry.symbol = _Symbol;
   entry.signal = signal;
   entry.signalType = signal > 0 ? "BUY" : (signal < 0 ? "SELL" : "NONE");
   
   entry.quality = quality;
   entry.confluence = confluence;
   entry.momentum = g_physics.GetMomentum();
   entry.speed = g_physics.GetSpeed();
   entry.acceleration = g_physics.GetAcceleration();
   entry.entropy = g_physics.GetEntropy();
   entry.jerk = g_physics.GetJerk();
   
   entry.zone = g_physics.GetZoneName(zone);
   entry.regime = g_physics.GetRegimeName(regime);
   
   entry.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   entry.spread = g_logger.GetCurrentSpread();
   entry.highThreshold = 0.0;  // Add if available
   entry.lowThreshold = 0.0;
   
   entry.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   entry.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   entry.openPositions = PositionsTotal();
   
   entry.physicsPass = (quality >= MinQuality && confluence >= MinConfluence);
   entry.rejectReason = entry.physicsPass ? "PASS" : "Quality/Confluence too low";
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   entry.hour = dt.hour;
   entry.dayOfWeek = dt.day_of_week;
   
   g_logger.LogSignal(entry);
}

//+------------------------------------------------------------------+
//| Log completed trade to CSV                                        |
//+------------------------------------------------------------------+
void LogCompletedTrade(ClosedTrade &trade)
{
   TradeLogEntry log;
   
   // EA version tracking
   log.eaName = EA_NAME;
   log.eaVersion = EA_VERSION;
   
   // Copy all trade data to log entry
   log.ticket = trade.ticket;
   log.openTime = trade.openTime;
   log.closeTime = trade.closeTime;
   log.symbol = trade.symbol;
   log.type = trade.type;
   log.lots = trade.lots;
   log.openPrice = trade.openPrice;
   log.closePrice = trade.closePrice;
   log.sl = trade.sl;
   log.tp = trade.tp;
   
   log.entryQuality = trade.entryQuality;
   log.entryConfluence = trade.entryConfluence;
   log.entryMomentum = trade.entryMomentum;
   log.entryEntropy = trade.entryEntropy;
   log.entryZone = trade.entryZone;
   log.entryRegime = trade.entryRegime;
   log.entrySpread = trade.entrySpread;
   
   log.exitReason = trade.exitReason;
   log.exitQuality = trade.exitQuality;
   log.exitConfluence = trade.exitConfluence;
   log.exitZone = trade.exitZone;
   log.exitRegime = trade.exitRegime;
   
   log.profit = trade.profit;
   log.profitPercent = trade.profitPercent;
   log.pips = trade.pips;
   log.holdTimeBars = trade.holdTimeBars;
   log.holdTimeMinutes = trade.holdTimeMinutes;
   log.riskPercent = trade.riskPercent;
   log.rRatio = trade.rRatio;
   log.slippage = trade.slippage;
   log.commission = trade.commission;
   
   log.mfe = trade.mfe;
   log.mae = trade.mae;
   log.mfePercent = trade.mfePercent;
   log.maePercent = trade.maePercent;
   log.mfePips = trade.mfePips;
   log.maePips = trade.maePips;
   log.mfeTimeBars = trade.mfeTimeBars;
   log.maeTimeBars = trade.maeTimeBars;
   
   log.runUpPrice = trade.runUpPrice;
   log.runUpPips = trade.runUpPips;
   log.runUpPercent = trade.runUpPercent;
   log.runUpTimeBars = trade.runUpTimeBars;
   log.runDownPrice = trade.runDownPrice;
   log.runDownPips = trade.runDownPips;
   log.runDownPercent = trade.runDownPercent;
   log.runDownTimeBars = trade.runDownTimeBars;
   
   log.balanceAfter = trade.balanceAfter;
   log.equityAfter = trade.equityAfter;
   log.drawdownPercent = trade.drawdownPercent;
   
   log.entryHour = trade.entryHour;
   log.entryDayOfWeek = trade.entryDayOfWeek;
   log.exitHour = trade.exitHour;
   log.exitDayOfWeek = trade.exitDayOfWeek;
   
   if(g_logger.LogTrade(log))
   {
      Print("✅ Trade #", trade.ticket, " logged to CSV");
   }
   else
   {
      Print("❌ Failed to log trade #", trade.ticket);
   }
}

//+------------------------------------------------------------------+
//| Draw MA indicators on chart                                      |
//+------------------------------------------------------------------+
void DrawMAIndicators()
{
   // Add Fast MA to chart (Blue)
   if(!ChartIndicatorAdd(0, 0, g_maFastHandle))
   {
      Print("⚠️  Warning: Could not add Fast MA to chart");
   }
   else
   {
      Print("✅ Fast MA (", MA_Fast, ") added to chart - BLUE");
   }
   
   // Add Slow MA to chart (Red/Orange)
   if(!ChartIndicatorAdd(0, 0, g_maSlowHandle))
   {
      Print("⚠️  Warning: Could not add Slow MA to chart");
   }
   else
   {
      Print("✅ Slow MA (", MA_Slow, ") added to chart - RED");
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
