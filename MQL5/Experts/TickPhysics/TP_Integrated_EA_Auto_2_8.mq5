//+------------------------------------------------------------------+
//|                         TP_Integrated_EA_Auto_2_8.mq5            |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|         v2.7: Autonomous Self-Learning EA - JSON-Driven          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "2.8"
#property description "Fully autonomous EA with JSON configuration - Python learning engine updates parameters automatically"

#include <Trade/Trade.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>
#include <TickPhysics/TP_Risk_Manager.mqh>
#include <TickPhysics/TP_Trade_Tracker.mqh>
#include <TickPhysics/TP_CSV_Logger.mqh>
#include <TickPhysics/TP_JSON_Config.mqh>

// EA Version Info
#define EA_NAME "TP_Integrated_EA_Auto"
#define EA_VERSION "2.8"

//+------------------------------------------------------------------+
//| Input Parameters - JSON Configuration + Manual Overrides         |
//+------------------------------------------------------------------+
input group "🧠 Self-Learning Configuration"
input string JSONConfigFile = "EA_Config_v2_8.json";  // JSON config file (primary)
input bool UseJSONConfig = true;                      // Use JSON config (false = use manual inputs)
input int MagicNumber = 777888;                       // EA magic number
input string TradeComment = "TP_Auto_2.8";            // Trade comment

input group "💰 Risk Management (Manual Override)"
input double RiskPercentPerTrade = 1.0;               // Risk % per trade
input double MaxDailyRisk = 3.0;                      // Max daily risk %
input int MaxConcurrentTrades = 3;                    // Max concurrent trades
input double MinRRatio = 1.5;                         // Min R:R ratio
input int StopLossPips = 50;                          // Stop loss (pips)
input int TakeProfitPips = 100;                       // Take profit (pips)

input group "📊 Entry Logic (Manual Override)"
input bool UsePhysicsEntry = false;                   // Use physics-based entry
input bool UseMAEntry = true;                         // Use MA crossover entry
input int MAFastPeriod = 10;                          // Fast MA period
input int MASlowPeriod = 50;                          // Slow MA period

input group "🎯 Physics Filters (Manual Override)"
input bool PhysicsFiltersEnabled = true;              // Enable physics filters
input double MinQuality = 70.0;                       // Min quality threshold
input double MinConfluence = 70.0;                    // Min confluence threshold
input bool ZoneFilterEnabled = true;                  // Zone filter (avoid BEAR)
input bool RegimeFilterEnabled = true;                // Regime filter (avoid LOW)

input group "🕐 Time Filters (Manual Override)"
input bool TimeFilterEnabled = true;                  // Enable time filters
input string AllowedHours = "";                       // Allowed hours (e.g., "8,9,10,14,15,16")
input string BlockedHours = "";                       // Blocked hours (e.g., "12,13")
input bool DayFilterEnabled = true;                   // Enable day filter
input string BlockedDays = "";                        // Blocked days (0=Sun, 3=Wed)

input group "📈 Post-Trade Monitoring (Manual Override)"
input int PostExitMonitorBars = 50;                   // Post-exit monitor bars
input bool EnableRealtimeLogging = true;              // Enable realtime logging
input bool EnableDebugMode = true;                    // Enable debug mode

input group "🧠 Learning Parameters (Manual Override)"
input bool AutoUpdateEnabled = false;                 // Auto-update from Python
input int MinTradesForUpdate = 100;                   // Min trades before update
input int UpdateFrequencyTrades = 50;                 // Update frequency

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

// Configuration objects
CJSONConfig g_jsonConfig;
EAConfig g_config;

// Trading objects
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

// Time filter arrays (populated from JSON)
int g_allowedHours[];
int g_blockedHours[];
int g_blockedDays[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics Integrated EA - Initializing");
   Print("═══════════════════════════════════════════════════════");
   
   // 1. Load Configuration (JSON or Manual)
   Print("📁 Loading configuration...");
   
   if(UseJSONConfig)
   {
      // Load from JSON file
      if(!g_jsonConfig.Initialize(JSONConfigFile, true))
      {
         Print("❌ FAILED: JSON Config initialization");
         Print("   Falling back to manual input parameters...");
         LoadManualConfig(g_config);
      }
      else if(!g_jsonConfig.LoadConfig(g_config))
      {
         Print("❌ FAILED: Could not load config from ", JSONConfigFile);
         Print("   Make sure file exists in: MQL5/Files/", JSONConfigFile);
         Print("   Falling back to manual input parameters...");
         LoadManualConfig(g_config);
      }
      else
      {
         Print("✅ Configuration loaded from JSON");
         g_jsonConfig.PrintConfig(g_config);
      }
   }
   else
   {
      // Use manual input parameters
      Print("📝 Using manual input parameters (JSON disabled)");
      LoadManualConfig(g_config);
      PrintManualConfig(g_config);
   }
   
   // Copy time filter arrays to globals
   ArrayResize(g_allowedHours, g_config.allowedHoursCount);
   for(int i = 0; i < g_config.allowedHoursCount; i++)
      g_allowedHours[i] = g_config.allowedHours[i];
   
   ArrayResize(g_blockedHours, g_config.blockedHoursCount);
   for(int i = 0; i < g_config.blockedHoursCount; i++)
      g_blockedHours[i] = g_config.blockedHours[i];
   
   ArrayResize(g_blockedDays, g_config.blockedDaysCount);
   for(int i = 0; i < g_config.blockedDaysCount; i++)
      g_blockedDays[i] = g_config.blockedDays[i];
   
   Print("");
   
   // 2. Initialize Physics Indicator
   Print("📊 Initializing Physics Indicator...");
   if(!g_physics.Initialize(g_indicatorName, g_config.enableDebugMode))
   {
      Print("❌ FAILED: Physics Indicator initialization");
      return INIT_FAILED;
   }
   Print("✅ Physics Indicator ready");
   
   // 3. Initialize Risk Manager
   Print("💰 Initializing Risk Manager...");
   if(!g_riskManager.Initialize(_Symbol, g_config.enableDebugMode))
   {
      Print("❌ FAILED: Risk Manager initialization");
      return INIT_FAILED;
   }
   Print("✅ Risk Manager ready");
   
   // 4. Initialize Trade Tracker
   Print("📈 Initializing Trade Tracker...");
   TrackerConfig trackerConfig;
   trackerConfig.trackMFEMAE = true;
   trackerConfig.trackPostExit = true;
   trackerConfig.postExitMonitorBars = g_config.postExitMonitorBars;
   trackerConfig.autoLogTrades = false;  // We'll control logging
   trackerConfig.debugMode = g_config.enableDebugMode;
   
   if(!g_tracker.Initialize(_Symbol, trackerConfig))
   {
      Print("❌ FAILED: Trade Tracker initialization");
      return INIT_FAILED;
   }
   Print("✅ Trade Tracker ready");
   
   // 5. Initialize CSV Logger
   Print("📝 Initializing CSV Logger...");
   LoggerConfig loggerConfig;
   loggerConfig.signalLogFile = "TP_Integrated_Signals_" + _Symbol + "_v" + EA_VERSION + ".csv";
   loggerConfig.tradeLogFile = "TP_Integrated_Trades_" + _Symbol + "_v" + EA_VERSION + ".csv";
   loggerConfig.createHeaders = true;
   loggerConfig.appendMode = true;  // Append for production
   loggerConfig.timestampFiles = false;
   loggerConfig.logToExpertLog = g_config.enableRealtimeLogging;
   loggerConfig.debugMode = g_config.enableDebugMode;
   
   if(!g_logger.Initialize(_Symbol, loggerConfig))
   {
      Print("❌ FAILED: CSV Logger initialization");
      return INIT_FAILED;
   }
   Print("✅ CSV Logger ready");
   
   // 6. Initialize MA indicators (if using MA entry)
   if(g_config.useMAEntry)
   {
      Print("📊 Initializing MA indicators...");
      g_maFastHandle = iMA(_Symbol, PERIOD_CURRENT, g_config.maFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
      g_maSlowHandle = iMA(_Symbol, PERIOD_CURRENT, g_config.maSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
      
      if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
      {
         Print("❌ FAILED: MA indicator initialization");
         return INIT_FAILED;
      }
      Print("✅ MA indicators ready (Fast:", g_config.maFastPeriod, ", Slow:", g_config.maSlowPeriod, ")");
      
      // Draw MA indicators on chart
      DrawMAIndicators();
   }
   
   // 7. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v2.8 JSON-DRIVEN!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v2.8 (JSON-Driven Self-Learning)");
   Print("   Entry System: ", g_config.usePhysicsEntry ? "PHYSICS" : (g_config.useMAEntry ? "MA CROSSOVER" : "NONE"));
   if(g_config.useMAEntry)
      Print("   MA Periods: Fast=", g_config.maFastPeriod, ", Slow=", g_config.maSlowPeriod);
   Print("   Physics Filters: ", g_config.physicsFiltersEnabled ? "ENABLED ✅" : "DISABLED (logging only)");
   if(g_config.physicsFiltersEnabled)
   {
      Print("   → Zone Filter: ", g_config.zoneFilterEnabled ? "ENABLED (Avoid BEAR)" : "DISABLED");
      Print("   → Regime Filter: ", g_config.regimeFilterEnabled ? "ENABLED (Avoid LOW, Prefer HIGH)" : "DISABLED");
      Print("   → Quality Filter: MinQuality=", g_config.minQuality);
      Print("   → Confluence Filter: MinConfluence=", g_config.minConfluence);
   }
   Print("   Risk/Trade: ", g_config.riskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", g_config.maxDailyRisk, "%");
   Print("   Max Concurrent: ", g_config.maxConcurrentTrades, " trades");
   Print("   SL/TP: ", g_config.stopLossPips, "/", g_config.takeProfitPips, " pips");
   Print("   Post-Exit Monitor: ", g_config.postExitMonitorBars, " bars");
   Print("   CSV Files: v2.8 (JSON-Driven - Trades & Signals)");
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
   if(g_config.useMAEntry)
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
   if(g_config.usePhysicsEntry)
      return GeneratePhysicsSignal();
   else if(g_config.useMAEntry)
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
      if(g_config.enableDebugMode)
         Print("🟢 MA BUY SIGNAL: Fast(", maFast[1], ") crossed above Slow(", maSlow[1], ") [bar 1 vs bar 2]");
      return 1;  // BUY
   }
   
   // SELL Signal: Fast MA crosses below Slow MA on CLOSED bars (bar 1 vs bar 2)
   if(maFast[2] >= maSlow[2] && maFast[1] < maSlow[1])
   {
      if(g_config.enableDebugMode)
         Print("🔴 MA SELL SIGNAL: Fast(", maFast[1], ") crossed below Slow(", maSlow[1], ") [bar 1 vs bar 2]");
      return -1;  // SELL
   }
   
   return 0;  // No crossover
}

//+------------------------------------------------------------------+
//| Check time filters                                                |
//+------------------------------------------------------------------+
bool PassTimeFilters()
{
   if(!g_config.timeFilterEnabled)
      return true;  // Time filters disabled
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Check blocked hours
   if(g_config.blockedHoursCount > 0)
   {
      for(int i = 0; i < g_config.blockedHoursCount; i++)
      {
         if(dt.hour == g_config.blockedHours[i])
         {
            if(g_config.enableDebugMode)
               Print("🚫 TIME FILTER: Hour ", dt.hour, " is BLOCKED");
            return false;
         }
      }
   }
   
   // Check allowed hours (if specified)
   if(g_config.allowedHoursCount > 0)
   {
      bool found = false;
      for(int i = 0; i < g_config.allowedHoursCount; i++)
      {
         if(dt.hour == g_config.allowedHours[i])
         {
            found = true;
            break;
         }
      }
      if(!found)
      {
         if(g_config.enableDebugMode)
            Print("🚫 TIME FILTER: Hour ", dt.hour, " not in allowed list");
         return false;
      }
   }
   
   // Check blocked days
   if(g_config.dayFilterEnabled && g_config.blockedDaysCount > 0)
   {
      for(int i = 0; i < g_config.blockedDaysCount; i++)
      {
         if(dt.day_of_week == g_config.blockedDays[i])
         {
            if(g_config.enableDebugMode)
            {
               string dayNames[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
               Print("🚫 DAY FILTER: ", dayNames[dt.day_of_week], " is blocked");
            }
            return false;
         }
      }
   }
   
   return true;  // Passed all time filters
}

//+------------------------------------------------------------------+
//| New bar handler - Signal generation and trade logic              |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // 1. Check time filters FIRST
   if(!PassTimeFilters())
      return;
   
   // 2. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 2. Log signal (regardless of quality)
   if(g_config.enableRealtimeLogging)
   {
      LogSignal(signal, quality, confluence, zone, regime);
   }
   
   // 3. Check if we should trade
   if(signal == 0) return;  // No signal
   
   // 4. Apply physics filters (ONLY if enabled)
   string rejectReason = "";
   bool passFilters = true;
   
   if(g_config.physicsFiltersEnabled)
   {
      // Quality/Confluence filters (baseline - no strong correlation found)
      if(quality < g_config.minQuality)
      {
         rejectReason = "Quality too low";
         passFilters = false;
      }
      else if(confluence < g_config.minConfluence)
      {
         rejectReason = "Confluence too low";
         passFilters = false;
      }
      // Zone filter: AVOID BEAR zone (24.4% win rate, -$3.14 avg)
      else if(g_config.zoneFilterEnabled && zone == ZONE_BEAR)
      {
         rejectReason = "BEAR zone (poor performance)";
         passFilters = false;
      }
      // Regime filter: AVOID LOW volatility (21.4% win rate), PREFER HIGH (36.4% win rate)
      else if(g_config.regimeFilterEnabled && regime == REGIME_LOW)
      {
         rejectReason = "LOW volatility regime (poor performance)";
         passFilters = false;
      }
      
      if(!passFilters)
      {
         if(g_config.enableDebugMode)
            Print("🚫 Signal rejected: ", rejectReason, " (Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime), ")");
         return;
      }
      else if(g_config.enableDebugMode)
      {
         // Log when we ACCEPT a trade due to good filters
         Print("✅ Signal ACCEPTED: Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime));
      }
   }
   else
   {
      // Physics filters disabled - log but don't filter
      if(g_config.enableDebugMode)
         Print("✅ Physics filters DISABLED - accepting all signals (Q=", quality, ", C=", confluence, ")");
   }
   
   // 5. Close opposite positions if any (for crossover reversal)
   int closedCount = CloseOppositePositions(signal);
   
   if(g_config.enableDebugMode)
      Print("🔍 Pre-delay check: Closed=", closedCount, " | Remaining positions=", PositionsTotal());
   
   // If we closed positions, give MT5 a moment to process (avoid race condition)
   if(closedCount > 0)
   {
      Sleep(500);  // 500ms delay to ensure position is fully closed
      if(g_config.enableDebugMode)
         Print("⏱️  Waited 500ms for position close to process");
   }
   
   // 6. Double-check position count after delay
   int remainingPositions = PositionsTotal();
   if(g_config.enableDebugMode)
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
   
   if(g_config.enableDebugMode)
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
   
   if(g_config.enableDebugMode)
      Print("💰 Risk check: ", openTrades, " / ", g_config.maxConcurrentTrades, " positions");
   
   if(openTrades >= g_config.maxConcurrentTrades)
   {
      Print("🚫 Cannot open trade: Max concurrent trades reached (", openTrades, "/", g_config.maxConcurrentTrades, ")");
      return;
   }
   
   // 9. Calculate position size
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   double slDistance = g_config.stopLossPips * point * pipMultiplier;
   double tpDistance = g_config.takeProfitPips * point * pipMultiplier;
   
   // Calculate risk money (% of balance)
   double riskMoney = balance * (g_config.riskPercentPerTrade / 100.0);
   
   double lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
   if(lots <= 0)
   {
      Print("❌ Invalid lot size calculated: ", lots);
      return;
   }
   
   if(g_config.enableDebugMode)
      Print("📏 Position size: ", lots, " lots (risk: $", riskMoney, ")");
   
   // 10. Validate R:R ratio
   double rRatio = tpDistance / slDistance;
   if(rRatio < g_config.minRRatio)
   {
      Print("🚫 Trade rejected: R:R ratio too low (", DoubleToString(rRatio, 2), " < ", g_config.minRRatio, ")");
      return;
   }
   
   if(g_config.enableDebugMode)
      Print("✅ R:R ratio OK: ", DoubleToString(rRatio, 2));
   
   // 11. Execute trade
   if(g_config.enableDebugMode)
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
   
   if(signal > 0)  // BUY
   {
      sl = price - slDistance;
      tp = price + tpDistance;
      
      Print("🟢 Opening BUY: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp);
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
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
      sl = price + slDistance;
      tp = price - tpDistance;
      
      Print("🔴 Opening SELL: ", lots, " lots @ ", price, " | SL:", sl, " | TP:", tp);
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
      
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
                        g_config.riskPercentPerTrade))
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
   
   entry.physicsPass = (quality >= g_config.minQuality && confluence >= g_config.minConfluence);
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
      Print("✅ Fast MA (", g_config.maFastPeriod, ") added to chart - BLUE");
   }
   
   // Add Slow MA to chart (Red/Orange)
   if(!ChartIndicatorAdd(0, 0, g_maSlowHandle))
   {
      Print("⚠️  Warning: Could not add Slow MA to chart");
   }
   else
   {
      Print("✅ Slow MA (", g_config.maSlowPeriod, ") added to chart - RED");
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Load manual configuration from input parameters                  |
//+------------------------------------------------------------------+
void LoadManualConfig(EAConfig &config)
{
   // Risk Management
   config.riskPercentPerTrade = RiskPercentPerTrade;
   config.maxDailyRisk = MaxDailyRisk;
   config.maxConcurrentTrades = MaxConcurrentTrades;
   config.minRRatio = MinRRatio;
   config.stopLossPips = StopLossPips;
   config.takeProfitPips = TakeProfitPips;
   
   // Entry System
   config.usePhysicsEntry = UsePhysicsEntry;
   config.useMAEntry = UseMAEntry;
   config.maFastPeriod = MAFastPeriod;
   config.maSlowPeriod = MASlowPeriod;
   
   // Physics Filters
   config.physicsFiltersEnabled = PhysicsFiltersEnabled;
   config.minQuality = MinQuality;
   config.minConfluence = MinConfluence;
   config.zoneFilterEnabled = ZoneFilterEnabled;
   config.regimeFilterEnabled = RegimeFilterEnabled;
   
   // Time Filters
   config.timeFilterEnabled = TimeFilterEnabled;
   config.allowedHoursCount = ParseIntString(AllowedHours, config.allowedHours);
   config.blockedHoursCount = ParseIntString(BlockedHours, config.blockedHours);
   config.dayFilterEnabled = DayFilterEnabled;
   config.blockedDaysCount = ParseIntString(BlockedDays, config.blockedDays);
   
   // Monitoring
   config.postExitMonitorBars = PostExitMonitorBars;
   config.enableRealtimeLogging = EnableRealtimeLogging;
   config.enableDebugMode = EnableDebugMode;
   
   // Learning Parameters
   config.autoUpdateEnabled = AutoUpdateEnabled;
   config.minTradesForUpdate = MinTradesForUpdate;
   config.updateFrequencyTrades = UpdateFrequencyTrades;
}

//+------------------------------------------------------------------+
//| Parse comma-separated integer string                             |
//+------------------------------------------------------------------+
int ParseIntString(string str, int &output[])
{
   if(str == "") return 0;
   
   string parts[];
   int count = StringSplit(str, StringGetCharacter(",", 0), parts);
   
   ArrayResize(output, count);
   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(parts[i]);
      StringTrimRight(parts[i]);
      output[i] = (int)StringToInteger(parts[i]);
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Print manual configuration                                        |
//+------------------------------------------------------------------+
void PrintManualConfig(const EAConfig &config)
{
   Print("═══════════════════════════════════════════════════════");
   Print("📋 MANUAL CONFIGURATION (from input parameters)");
   Print("═══════════════════════════════════════════════════════");
   
   Print("💰 Risk Management:");
   Print("   Risk/Trade: ", config.riskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", config.maxDailyRisk, "%");
   Print("   Max Concurrent: ", config.maxConcurrentTrades);
   Print("   SL/TP: ", config.stopLossPips, "/", config.takeProfitPips, " pips");
   
   Print("");
   Print("📊 Entry System:");
   Print("   Physics Entry: ", config.usePhysicsEntry ? "YES" : "NO");
   Print("   MA Entry: ", config.useMAEntry ? "YES" : "NO");
   if(config.useMAEntry)
      Print("   MA Periods: Fast=", config.maFastPeriod, ", Slow=", config.maSlowPeriod);
   
   Print("");
   Print("🎯 Physics Filters:");
   Print("   Enabled: ", config.physicsFiltersEnabled ? "YES" : "NO");
   Print("   Min Quality: ", config.minQuality);
   Print("   Min Confluence: ", config.minConfluence);
   Print("   Zone Filter: ", config.zoneFilterEnabled ? "YES" : "NO");
   Print("   Regime Filter: ", config.regimeFilterEnabled ? "YES" : "NO");
   
   Print("═══════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
