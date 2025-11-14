//+------------------------------------------------------------------+
//|                         TP_Integrated_EA_Crossover_3_2_05M.mq5   |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|      Physics-Optimized EA - SL/TP + Momentum Threshold           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "3.2"
#property description "v3.2_05M: SL/TP optimization + Momentum filter based on v3.1 analysis"
#property description "NEW: SL 34 pips (75th MAE), TP 195 pips (median MFE - tighter for frequency)"
#property description "NEW: MinMomentum -346.58 (strongest separator, 55.86 point gap)"
#property description "Keeps: Zone/Regime/Time filters from v3.1"

// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "3.2_05M"

input int MagicNumber = 300312;                // EA magic number (v3.2 = 300312)
input string TradeComment = "TP_Integrated 3_2_05M";   // Trade comment

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
input double RiskPercentPerTrade = 1.0;        // Risk per trade (% of balance)
input double MaxDailyRisk = 10.0;              // Max daily risk (% of balance)
input int MaxConcurrentTrades = 1;             // Max concurrent positions
input double MinRRatio = 1.0;                  // Min reward:risk ratio

// === Trade Parameters - v3.2 OPTIMIZED ===
input group "📊 Trade Parameters - v3.2 SL/TP OPTIMIZATION"
input int StopLossPips = 340;                  // Stop loss (pips) - v3.2 OPTIMIZED (34 pips * 10 for 2-digit symbol)
input int TakeProfitPips = 1950;               // Take profit (pips) - v3.2 OPTIMIZED (195 pips * 10 for 2-digit symbol)
input bool UseTrailingStop = false;            // Enable trailing stop
input int TrailingStopPips = 30;               // Trailing stop (pips)

// === Entry System Selection ===
input group "📊 Entry Logic"
input bool UsePhysicsEntry = false;            // Use physics acceleration crossover
input bool UseMAEntry = true;                  // Use Moving Average crossover
input int MA_Fast = 10;                        // Fast MA period
input int MA_Slow = 50;                        // Slow MA period
input ENUM_MA_METHOD MA_Method = MODE_EMA;     // MA calculation method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // MA price type

// === Signal Filters - v3.2 PHYSICS REFINEMENT ===
input group "🎯 Physics Filters - v3.2 MOMENTUM OPTIMIZATION"
input bool UsePhysicsFilters = true;            // Enable physics filtering - v3.2 ENABLED
input double MinQuality = 75.67;               // Min physics quality - v3.2 REFINED (25th percentile winners)
input double MinConfluence = 80.00;            // Min confluence - v3.2 REFINED (25th percentile winners)
input double MinMomentum = -346.58;            // Min momentum - v3.2 CRITICAL! (strongest separator, 55.86 gap)
input bool UseZoneFilter = true;                // Filter by trading zone - v3.1 KEEP
input bool UseRegimeFilter = true;              // Filter by volatility regime - v3.1 KEEP
input bool UseTimeFilter = true;                // Filter by time of day - v3.1 KEEP
input string AllowedHours = "";                 // Allowed hours (comma-separated, empty = all except blocked)
input string BlockedHours = "6,7,13,14";       // Blocked hours (<20% WR) - v3.1 KEEP

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
int g_allowedHoursArray[];
int g_blockedHoursArray[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics Integrated EA v3.2_05M - Initializing");
   Print("═══════════════════════════════════════════════════════");
   
   // Parse time filter settings
   if(UseTimeFilter)
   {
      ParseTimeFilter();
   }
   
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
   
   // 6. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v3.2_05M SL/TP + MOMENTUM OPTIMIZATION!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v3.2_05M (SL/TP + Momentum Optimized)");
   Print("   🎯 v3.2 OPTIMIZATION: SL/TP from MFE/MAE + Momentum filter");
   Print("   Entry System: ", UsePhysicsEntry ? "PHYSICS" : (UseMAEntry ? "MA CROSSOVER" : "NONE"));
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   Print("");
   Print("   💥 v3.2 NEW FEATURES:");
   Print("   → Stop Loss: ", StopLossPips, " pips (75th MAE + 10%)");
   Print("   → Take Profit: ", TakeProfitPips, " pips (median MFE - tighter for frequency)");
   Print("   → R:R Ratio: ", DoubleToString((double)TakeProfitPips / StopLossPips, 2), ":1");
   Print("   → MinMomentum: ", MinMomentum, " (CRITICAL - 55.86 point separation!)");
   Print("");
   Print("   Physics Filters: ", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED");
   if(UsePhysicsFilters)
   {
      Print("   → Quality Filter: MinQuality=", MinQuality, " (v3.2 refined)");
      Print("   → Confluence Filter: MinConfluence=", MinConfluence, " (v3.2 refined)");
      Print("   → Momentum Filter: MinMomentum=", MinMomentum, " (v3.2 NEW - strongest separator!)");
      Print("   → Zone Filter: ", UseZoneFilter ? "ENABLED (avoid TRANSITION)" : "DISABLED");
      Print("   → Regime Filter: ", UseRegimeFilter ? "ENABLED (avoid LOW)" : "DISABLED");
      Print("   → Time Filter: ", UseTimeFilter ? "ENABLED (block hours " + BlockedHours + ")" : "DISABLED");
   }
   Print("");
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", MaxDailyRisk, "%");
   Print("   Max Concurrent: ", MaxConcurrentTrades, " trades");
   Print("   Post-Exit Monitor: ", PostExitMonitorBars, " bars");
   Print("   CSV Files: v3.2_05M (Trades & Signals)");
   Print("");
   Print("   📊 Expected Performance (based on v3.1 analysis):");
   Print("   → Estimated Trades: ~154 (71% reduction from v3.1)");
   Print("   → Target WR: 50-80%");
   Print("   → Target PF: 2.0-5.0");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 TickPhysics Integrated EA v3.2_05M - Shutting Down");
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
//| Parse time filter settings                                        |
//+------------------------------------------------------------------+
void ParseTimeFilter()
{
   ArrayResize(g_allowedHoursArray, 0);
   ArrayResize(g_blockedHoursArray, 0);
   
   // Parse blocked hours
   if(BlockedHours != "")
   {
      string blockedParts[];
      int blockedCount = StringSplit(BlockedHours, ',', blockedParts);
      ArrayResize(g_blockedHoursArray, blockedCount);
      
      for(int i = 0; i < blockedCount; i++)
      {
         g_blockedHoursArray[i] = (int)StringToInteger(blockedParts[i]);
      }
      
      Print("⏰ Blocked hours parsed: ", ArraySize(g_blockedHoursArray), " hours");
   }
   
   // Parse allowed hours (if specified)
   if(AllowedHours != "")
   {
      string allowedParts[];
      int allowedCount = StringSplit(AllowedHours, ',', allowedParts);
      ArrayResize(g_allowedHoursArray, allowedCount);
      
      for(int i = 0; i < allowedCount; i++)
      {
         g_allowedHoursArray[i] = (int)StringToInteger(allowedParts[i]);
      }
      
      Print("⏰ Allowed hours parsed: ", ArraySize(g_allowedHoursArray), " hours");
   }
}

//+------------------------------------------------------------------+
//| Check if current hour is allowed for trading                     |
//+------------------------------------------------------------------+
bool IsHourAllowed(int hour)
{
   // If allowed hours specified, check if hour is in the list
   if(ArraySize(g_allowedHoursArray) > 0)
   {
      for(int i = 0; i < ArraySize(g_allowedHoursArray); i++)
      {
         if(g_allowedHoursArray[i] == hour)
            return true;
      }
      return false;  // Hour not in allowed list
   }
   
   // Otherwise, check if hour is in blocked list
   for(int i = 0; i < ArraySize(g_blockedHoursArray); i++)
   {
      if(g_blockedHoursArray[i] == hour)
         return false;  // Hour is blocked
   }
   
   return true;  // Hour not blocked
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
//| New bar handler - Signal generation and trade logic              |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // 1. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 2. Log signal (regardless of quality)
   if(EnableRealTimeLogging)
   {
      LogSignal(signal, quality, confluence, momentum, zone, regime);
   }
   
   // 3. Check if we should trade
   if(signal == 0) return;  // No signal
   
   // 4. Apply v3.2 physics filters (includes v3.1 + new Momentum filter)
   string rejectReason = "";
   bool passFilters = true;
   
   if(UsePhysicsFilters)
   {
      // Quality/Confluence filters (v3.2 refined thresholds)
      if(quality < MinQuality)
      {
         rejectReason = StringFormat("Quality %.2f < %.2f", quality, MinQuality);
         passFilters = false;
      }
      else if(confluence < MinConfluence)
      {
         rejectReason = StringFormat("Confluence %.2f < %.2f", confluence, MinConfluence);
         passFilters = false;
      }
      // v3.2 NEW: Momentum filter (CRITICAL - strongest separator)
      else if(momentum < MinMomentum)
      {
         rejectReason = StringFormat("Momentum %.2f < %.2f (v3.2 FILTER - strongest separator!)", momentum, MinMomentum);
         passFilters = false;
      }
      // v3.1 Zone filter: AVOID TRANSITION zone
      else if(UseZoneFilter && zone == ZONE_TRANSITION)
      {
         rejectReason = "TRANSITION zone (21.8% WR)";
         passFilters = false;
      }
      // v3.1 Regime filter: AVOID LOW volatility
      else if(UseRegimeFilter && regime == REGIME_LOW)
      {
         rejectReason = "LOW volatility regime (23.0% WR)";
         passFilters = false;
      }
      // v3.1 Time filter: Block hours with <20% WR
      else if(UseTimeFilter)
      {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         int currentHour = dt.hour;
         
         if(!IsHourAllowed(currentHour))
         {
            rejectReason = StringFormat("Hour %d blocked (<20%% WR)", currentHour);
            passFilters = false;
         }
      }
      
      if(!passFilters)
      {
         if(EnableDebugMode)
            Print("🚫 v3.2 Signal rejected: ", rejectReason, " (Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime), ", Momentum=", momentum, ")");
         return;
      }
      else if(EnableDebugMode)
      {
         Print("✅ v3.2 Signal ACCEPTED: Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime), ", Momentum=", momentum);
      }
   }
   
   // 5. Close opposite positions if any (for crossover reversal)
   int closedCount = CloseOppositePositions(signal);
   
   if(EnableDebugMode)
      Print("🔍 Pre-delay check: Closed=", closedCount, " | Remaining positions=", PositionsTotal());
   
   // If we closed positions, give MT5 a moment to process
   if(closedCount > 0)
   {
      Sleep(500);
      if(EnableDebugMode)
         Print("⏱️  Waited 500ms for position close to process");
   }
   
   // 6. Double-check position count after delay
   int remainingPositions = PositionsTotal();
   if(EnableDebugMode)
   {
      Print("📊 Post-delay check: Total positions=", remainingPositions);
   }
   
   // 7. Check if we have any existing position in the signal direction
   bool hasSameDirection = HasPositionInDirection(signal);
   
   if(EnableDebugMode)
      Print("🔍 Duplicate check: Signal=", signal > 0 ? "BUY" : "SELL", " | HasSameDirection=", hasSameDirection);
   
   if(hasSameDirection)
   {
      Print("⚠️  BLOCKED: Already have position in ", (signal > 0 ? "BUY" : "SELL"), " direction!");
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
   
   // Calculate lot size based on risk
   double riskMoney = balance * (RiskPercentPerTrade / 100.0);
   double lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
   
   if(EnableDebugMode)
      Print("📏 Position size: ", lots, " lots (risk: $", riskMoney, ", SL distance: ", slDistance, ")");
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size calculated: ", lots);
      return;
   }
   
   // 10. Validate R:R ratio
   double rRatio = tpDistance / slDistance;
   if(rRatio < MinRRatio)
   {
      Print("🚫 Trade rejected: R:R ratio too low (", DoubleToString(rRatio, 2), " < ", MinRRatio, ")");
      return;
   }
   
   if(EnableDebugMode)
      Print("✅ R:R ratio OK: ", DoubleToString(rRatio, 2), ":1");
   
   // 11. Execute trade
   if(EnableDebugMode)
      Print("📊 v3.2 Signal confirmed: ", (signal > 0 ? "BUY" : "SELL"), " | Momentum: ", momentum, " | Closed opposite: ", closedCount);
   
   Print("🚀 v3.2_05M EXECUTING TRADE NOW (SL/TP + MOMENTUM OPTIMIZED)...");
   ExecuteTrade(signal, lots, price, slDistance, tpDistance, quality, confluence, momentum, zone, regime);
}

//+------------------------------------------------------------------+
//| Close positions in opposite direction                            |
//+------------------------------------------------------------------+
int CloseOppositePositions(int newSignal)
{
   if(newSignal == 0) return 0;
   
   int closedCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
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
      
      if(signal > 0 && posType == POSITION_TYPE_BUY)
         return true;
      
      if(signal < 0 && posType == POSITION_TYPE_SELL)
         return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, double lots, double price, double slDistance, double tpDistance,
                  double quality, double confluence, double momentum, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   double sl = 0, tp = 0;
   bool success = false;
   ulong ticket = 0;
   
   sl = (signal > 0) ? (price - slDistance) : (price + slDistance);
   tp = (signal > 0) ? (price + tpDistance) : (price - tpDistance);
   
   if(signal > 0)  // BUY
   {
      Print("🟢 Opening BUY: ", lots, " lots @ ", price, " | SL:", sl, " (", StopLossPips, " pips) | TP:", tp, " (", TakeProfitPips, " pips)");
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
      if(!success)
      {
         Print("❌ BUY execution failed!");
         Print("   Return code: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         return;
      }
   }
   else  // SELL
   {
      Print("🔴 Opening SELL: ", lots, " lots @ ", price, " | SL:", sl, " (", StopLossPips, " pips) | TP:", tp, " (", TakeProfitPips, " pips)");
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
      if(!success)
      {
         Print("❌ SELL execution failed!");
         Print("   Return code: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         return;
      }
   }
   
   Print("✅ v3.2_05M Position opened: #", ticket);
   Print("   💥 v3.2 Features: SL ", StopLossPips, " pips | TP ", TakeProfitPips, " pips | Momentum ", momentum);
   
   // Add to tracker
   if(g_tracker.AddTrade(ticket,
                        quality,
                        confluence,
                        momentum,
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
void LogSignal(int signal, double quality, double confluence, double momentum, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   SignalLogEntry entry;
   
   entry.eaName = EA_NAME;
   entry.eaVersion = EA_VERSION;
   
   entry.timestamp = TimeCurrent();
   entry.symbol = _Symbol;
   entry.signal = signal;
   entry.signalType = signal > 0 ? "BUY" : (signal < 0 ? "SELL" : "NONE");
   
   entry.quality = quality;
   entry.confluence = confluence;
   entry.momentum = momentum;
   entry.speed = g_physics.GetSpeed();
   entry.acceleration = g_physics.GetAcceleration();
   entry.entropy = g_physics.GetEntropy();
   entry.jerk = g_physics.GetJerk();
   
   entry.zone = g_physics.GetZoneName(zone);
   entry.regime = g_physics.GetRegimeName(regime);
   
   entry.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   entry.spread = g_logger.GetCurrentSpread();
   entry.highThreshold = 0.0;
   entry.lowThreshold = 0.0;
   
   entry.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   entry.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   entry.openPositions = PositionsTotal();
   
   entry.physicsPass = (quality >= MinQuality && confluence >= MinConfluence && momentum >= MinMomentum);
   if(!entry.physicsPass)
   {
      if(quality < MinQuality)
         entry.rejectReason = "Quality too low";
      else if(confluence < MinConfluence)
         entry.rejectReason = "Confluence too low";
      else if(momentum < MinMomentum)
         entry.rejectReason = "Momentum too low (v3.2)";
      else
         entry.rejectReason = "Other filter";
   }
   else
   {
      entry.rejectReason = "PASS";
   }
   
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
   
   log.eaName = EA_NAME;
   log.eaVersion = EA_VERSION;
   
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
   if(!ChartIndicatorAdd(0, 0, g_maFastHandle))
   {
      Print("⚠️  Warning: Could not add Fast MA to chart");
   }
   else
   {
      Print("✅ Fast MA (", MA_Fast, ") added to chart - BLUE");
   }
   
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
