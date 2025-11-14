//+------------------------------------------------------------------+
//|                         TP_Integrated_EA_Crossover_2_6.mq5       |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|         v2.6: Self-Improving EA - Time Filters + Physics         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "2.6"
#property description "Iterative optimization: v2.5 filters + Time-of-Day filtering (self-learning)"

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
input double MaxDailyRisk = 3.0;               // Max daily risk (% of balance)
input int MaxConcurrentTrades = 3;             // Max concurrent positions
input double MinRRatio = 1.5;                  // Min reward:risk ratio

// === Trade Parameters ===
input group "📊 Trade Parameters"
input int StopLossPips = 50;                   // Stop loss (pips)
input int TakeProfitPips = 100;                // Take profit (pips)
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

// === Physics Filters (from v2.5) ===
input group "🎯 Physics Filters - V2.5 (Proven)"
input bool UsePhysicsFilters = true;           // Enable physics filtering
input double MinQuality = 70.0;                // Min physics quality (INCREASED from 65)
input double MinConfluence = 70.0;             // Min confluence
input bool UseZoneFilter = true;               // Filter by trading zone (avoid BEAR)
input bool UseRegimeFilter = true;             // Filter by volatility regime (avoid LOW)

// === Time Filters (NEW in v2.6 - Self-Learning) ===
input group "🕐 Time Filters - V2.6 (NEW - Data-Driven)"
input bool UseTimeFilter = true;               // Enable time-of-day filtering
input string AllowedHoursInput = "11,13,14,18,20,21";  // High-performance hours (comma-separated)
input string BlockedHoursInput = "1,12,15";    // Low-performance hours to avoid
input bool UseDayFilter = true;                // Enable day-of-week filtering
input bool AvoidWednesday = true;              // Avoid Wednesday (25.7% WR in v2.5)

// === Monitoring ===
input group "📈 Post-Trade Monitoring"
input int PostExitMonitorBars = 50;            // RunUp/RunDown monitor bars
input bool EnableRealTimeLogging = true;       // Log signals in real-time

// === Advanced ===
input group "⚙️ Advanced Settings"
input bool EnableDebugMode = true;             // Verbose logging
input int MagicNumber = 777888;                // EA magic number
input string TradeComment = "TP_Integrated";   // Trade comment

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
// EA Version Info
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "2.6"

CPhysicsIndicator g_physics;
CRiskManager g_riskManager;
CTradeTracker g_tracker;
CCSVLogger g_logger;
CTrade g_trade;

string g_indicatorName = "TickPhysics_Crypto_Indicator_v2_1";
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
//| Parse comma-separated hours string into array                     |
//+------------------------------------------------------------------+
void ParseHoursString(string hoursStr, int &output[])
{
   ArrayResize(output, 0);
   
   string parts[];
   ushort separator = StringGetCharacter(",", 0);  // Get comma character code
   int count = StringSplit(hoursStr, separator, parts);
   
   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(parts[i]);
      StringTrimRight(parts[i]);
      int hour = (int)StringToInteger(parts[i]);
      if(hour >= 0 && hour <= 23)
      {
         int size = ArraySize(output);
         ArrayResize(output, size + 1);
         output[size] = hour;
      }
   }
}

//+------------------------------------------------------------------+
//| Check if current hour is in array                                 |
//+------------------------------------------------------------------+
bool IsHourInArray(int hour, const int &arr[])
{
   for(int i = 0; i < ArraySize(arr); i++)
   {
      if(arr[i] == hour)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics Integrated EA v2.6 - SELF-IMPROVING");
   Print("═══════════════════════════════════════════════════════");
   
   // Declare strings outside the if block so they're available later
   string allowedStr = "";
   string blockedStr = "";
   
   // Parse time filter hours
   if(UseTimeFilter)
   {
      ParseHoursString(AllowedHoursInput, g_allowedHours);
      ParseHoursString(BlockedHoursInput, g_blockedHours);
      
      Print("🕐 Time Filter Configuration:");
      
      for(int i = 0; i < ArraySize(g_allowedHours); i++)
      {
         if(i > 0) allowedStr += ", ";
         allowedStr += IntegerToString(g_allowedHours[i]);
      }
      Print("   Allowed Hours: ", allowedStr);
      
      for(int i = 0; i < ArraySize(g_blockedHours); i++)
      {
         if(i > 0) blockedStr += ", ";
         blockedStr += IntegerToString(g_blockedHours[i]);
      }
      Print("   Blocked Hours: ", blockedStr);
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
   trackerConfig.autoLogTrades = false;
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
   loggerConfig.appendMode = true;
   loggerConfig.timestampFiles = false;
   loggerConfig.logToExpertLog = EnableRealTimeLogging;
   loggerConfig.debugMode = EnableDebugMode;
   
   if(!g_logger.Initialize(_Symbol, loggerConfig))
   {
      Print("❌ FAILED: CSV Logger initialization");
      return INIT_FAILED;
   }
   Print("✅ CSV Logger ready");
   
   // 5. Initialize MA indicators
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
      
      DrawMAIndicators();
   }
   
   // 6. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v2.6 SELF-IMPROVING MODE!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v2.6 (Self-Learning/Iterative Optimization)");
   Print("   Entry System: ", UsePhysicsEntry ? "PHYSICS" : (UseMAEntry ? "MA CROSSOVER" : "NONE"));
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   
   Print("");
   Print("   🎯 PHYSICS FILTERS (v2.5 - Proven):");
   Print("   → Zone Filter: ", UseZoneFilter ? "✅ ENABLED (Avoid BEAR)" : "❌ DISABLED");
   Print("   → Regime Filter: ", UseRegimeFilter ? "✅ ENABLED (Avoid LOW)" : "❌ DISABLED");
   Print("   → Quality Filter: MinQuality=", MinQuality, " (increased from v2.5)");
   
   Print("");
   Print("   🕐 TIME FILTERS (v2.6 - NEW - Data-Driven):");
   Print("   → Time-of-Day Filter: ", UseTimeFilter ? "✅ ENABLED" : "❌ DISABLED");
   if(UseTimeFilter)
   {
      Print("      • Allowed Hours: ", allowedStr);
      Print("      • Blocked Hours: ", blockedStr);
   }
   Print("   → Day-of-Week Filter: ", UseDayFilter ? "✅ ENABLED" : "❌ DISABLED");
   if(UseDayFilter && AvoidWednesday)
      Print("      • Avoiding: Wednesday (25.7% WR in v2.5)");
   
   Print("");
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   SL/TP: ", StopLossPips, "/", TakeProfitPips, " pips");
   Print("   CSV Files: v2.6 (Trades & Signals)");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 TickPhysics v2.6 - Shutting Down");
   Print("   Reason: ", reason);
   Print("═══════════════════════════════════════════════════════");
   
   if(UseMAEntry)
   {
      ChartIndicatorDelete(0, 0, g_maFastName);
      ChartIndicatorDelete(0, 0, g_maSlowName);
   }
   
   ClosedTrade trade;
   int logged = 0;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      LogCompletedTrade(trade);
      logged++;
   }
   
   if(logged > 0)
      Print("✅ Logged ", logged, " completed trades to CSV");
   
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
   
   g_tracker.UpdateTrades();
   
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
   
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      OnNewBar();
   }
}

//+------------------------------------------------------------------+
//| Generate trading signal                                          |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   if(UsePhysicsEntry)
      return GeneratePhysicsSignal();
   else if(UseMAEntry)
      return GenerateMASignal();
   else
      return 0;
}

//+------------------------------------------------------------------+
//| Physics-based signal                                             |
//+------------------------------------------------------------------+
int GeneratePhysicsSignal()
{
   double accel_0 = g_physics.GetAcceleration(0);
   double accel_1 = g_physics.GetAcceleration(1);
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   
   if(accel_1 < 0 && accel_0 > 0 && momentum > 0 && speed > 0)
      return 1;  // BUY
   
   if(accel_1 > 0 && accel_0 < 0 && momentum < 0 && speed < 0)
      return -1;  // SELL
   
   return 0;
}

//+------------------------------------------------------------------+
//| Moving Average crossover signal                                  |
//+------------------------------------------------------------------+
int GenerateMASignal()
{
   if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
      return 0;
   
   double maFast[], maSlow[];
   ArraySetAsSeries(maFast, true);
   ArraySetAsSeries(maSlow, true);
   
   if(CopyBuffer(g_maFastHandle, 0, 0, 3, maFast) < 3) return 0;
   if(CopyBuffer(g_maSlowHandle, 0, 0, 3, maSlow) < 3) return 0;
   
   // BUY Signal
   if(maFast[2] <= maSlow[2] && maFast[1] > maSlow[1])
   {
      if(EnableDebugMode)
         Print("🟢 MA BUY SIGNAL: Fast(", maFast[1], ") crossed above Slow(", maSlow[1], ")");
      return 1;
   }
   
   // SELL Signal
   if(maFast[2] >= maSlow[2] && maFast[1] < maSlow[1])
   {
      if(EnableDebugMode)
         Print("🔴 MA SELL SIGNAL: Fast(", maFast[1], ") crossed below Slow(", maSlow[1], ")");
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Check time filters (NEW in v2.6)                                 |
//+------------------------------------------------------------------+
bool PassTimeFilters()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   
   // Check time-of-day filter
   if(UseTimeFilter)
   {
      // If blocked hours list is not empty, check if current hour is blocked
      if(ArraySize(g_blockedHours) > 0)
      {
         if(IsHourInArray(dt.hour, g_blockedHours))
         {
            if(EnableDebugMode)
               Print("🚫 TIME FILTER: Hour ", dt.hour, " is BLOCKED (low performance in v2.5)");
            return false;
         }
      }
      
      // If allowed hours list is not empty, check if current hour is allowed
      if(ArraySize(g_allowedHours) > 0)
      {
         if(!IsHourInArray(dt.hour, g_allowedHours))
         {
            if(EnableDebugMode)
               Print("🚫 TIME FILTER: Hour ", dt.hour, " not in allowed list");
            return false;
         }
      }
   }
   
   // Check day-of-week filter
   if(UseDayFilter && AvoidWednesday)
   {
      if(dt.day_of_week == 3)  // Wednesday
      {
         if(EnableDebugMode)
            Print("🚫 DAY FILTER: Wednesday avoided (25.7% WR in v2.5 analysis)");
         return false;
      }
   }
   
   return true;  // Passed all time filters
}

//+------------------------------------------------------------------+
//| New bar handler                                                   |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // 1. Check time filters FIRST (v2.6 new feature)
   if(!PassTimeFilters())
      return;
   
   // 2. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 3. Log signal
   if(EnableRealTimeLogging)
   {
      LogSignal(signal, quality, confluence, zone, regime);
   }
   
   if(signal == 0) return;
   
   // 4. Apply physics filters (v2.5 proven filters)
   string rejectReason = "";
   bool passFilters = true;
   
   if(UsePhysicsFilters)
   {
      if(quality < MinQuality)
      {
         rejectReason = "Quality too low";
         passFilters = false;
      }
      else if(confluence < MinConfluence)
      {
         rejectReason = "Confluence too low";
         passFilters = false;
      }
      else if(UseZoneFilter && zone == ZONE_BEAR)
      {
         rejectReason = "BEAR zone (poor performance)";
         passFilters = false;
      }
      else if(UseRegimeFilter && regime == REGIME_LOW)
      {
         rejectReason = "LOW volatility regime (poor performance)";
         passFilters = false;
      }
      
      if(!passFilters)
      {
         if(EnableDebugMode)
            Print("🚫 PHYSICS FILTER: ", rejectReason);
         return;
      }
   }
   
   // 5. Close opposite positions
   int closedCount = CloseOppositePositions(signal);
   
   if(closedCount > 0)
   {
      Sleep(500);
      if(EnableDebugMode)
         Print("⏱️  Waited 500ms after closing ", closedCount, " position(s)");
   }
   
   // 6. Check for duplicate positions
   if(HasPositionInDirection(signal))
   {
      if(EnableDebugMode)
         Print("⚠️  Already have position in ", (signal > 0 ? "BUY" : "SELL"), " direction");
      return;
   }
   
   // 7. Check risk limits
   int openTrades = PositionsTotal();
   if(openTrades >= MaxConcurrentTrades)
   {
      Print("🚫 Max concurrent trades reached (", openTrades, "/", MaxConcurrentTrades, ")");
      return;
   }
   
   // 8. Calculate position size
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   double slDistance = StopLossPips * point * pipMultiplier;
   double tpDistance = TakeProfitPips * point * pipMultiplier;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (RiskPercentPerTrade / 100.0);
   
   double lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
   if(lots <= 0)
   {
      Print("❌ Invalid lot size: ", lots);
      return;
   }
   
   // 9. Validate R:R ratio
   double rRatio = tpDistance / slDistance;
   if(rRatio < MinRRatio)
   {
      Print("🚫 R:R ratio too low (", DoubleToString(rRatio, 2), " < ", MinRRatio, ")");
      return;
   }
   
   // 10. Execute trade
   if(EnableDebugMode)
      Print("🚀 EXECUTING TRADE: All filters passed (Physics + Time)");
   
   ExecuteTrade(signal, lots, price, slDistance, tpDistance, quality, confluence, zone, regime);
}

//+------------------------------------------------------------------+
//| Close opposite positions                                         |
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
         Print("🔄 REVERSAL: Closing BUY #", ticket, " to open SELL");
         if(g_trade.PositionClose(ticket))
            closedCount++;
      }
      else if(newSignal > 0 && posType == POSITION_TYPE_SELL)
      {
         Print("🔄 REVERSAL: Closing SELL #", ticket, " to open BUY");
         if(g_trade.PositionClose(ticket))
            closedCount++;
      }
   }
   
   return closedCount;
}

//+------------------------------------------------------------------+
//| Check if position exists in direction                            |
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
                  double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   double sl = 0, tp = 0;
   bool success = false;
   ulong ticket = 0;
   
   if(signal > 0)  // BUY
   {
      sl = price - slDistance;
      tp = price + tpDistance;
      
      Print("🟢 Opening BUY: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp);
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
      if(!success)
      {
         Print("❌ BUY execution failed: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         return;
      }
   }
   else  // SELL
   {
      sl = price + slDistance;
      tp = price - tpDistance;
      
      Print("🔴 Opening SELL: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp);
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
      if(!success)
      {
         Print("❌ SELL execution failed: ", g_trade.ResultRetcode(), " - ", g_trade.ResultRetcodeDescription());
         return;
      }
   }
   
   Print("✅ Position opened: #", ticket);
   
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
}

//+------------------------------------------------------------------+
//| Log signal to CSV                                                 |
//+------------------------------------------------------------------+
void LogSignal(int signal, double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
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
   entry.momentum = g_physics.GetMomentum();
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
}

//+------------------------------------------------------------------+
//| Draw MA indicators on chart                                      |
//+------------------------------------------------------------------+
void DrawMAIndicators()
{
   if(!ChartIndicatorAdd(0, 0, g_maFastHandle))
      Print("⚠️  Could not add Fast MA to chart");
   else
      Print("✅ Fast MA (", MA_Fast, ") added to chart - BLUE");
   
   if(!ChartIndicatorAdd(0, 0, g_maSlowHandle))
      Print("⚠️  Could not add Slow MA to chart");
   else
      Print("✅ Slow MA (", MA_Slow, ") added to chart - RED");
   
   ChartRedraw();
}
//+------------------------------------------------------------------+
