//+------------------------------------------------------------------+
//|                          TP_Integrated_EA_Auto_2_7_NEW.mq5       |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|                  Physics-Optimized EA - Regime & Zone Filtering  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "2.5"
#property description "Optimized EA with regime/zone filtering from correlation analysis"

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
input int MA_Slow = 50;                        // Slow MA period (increased for smoother signals)
input ENUM_MA_METHOD MA_Method = MODE_EMA;     // MA calculation method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // MA price type

// === Signal Filters ===
input group "🎯 Physics Filters - OPTIMIZED FROM ANALYSIS"
input bool UsePhysicsFilters = true;           // Enable physics filtering (ENABLED for v2.5)
input double MinQuality = 65.0;                // Min physics quality (baseline)
input double MinConfluence = 70.0;             // Min confluence (baseline)
input bool UseZoneFilter = true;               // Filter by trading zone (ENABLED - avoid BEAR)
input bool UseRegimeFilter = true;             // Filter by volatility regime (ENABLED - prefer HIGH, avoid LOW)

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
// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "2.5"

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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics Integrated EA - Initializing");
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
   
   // 6. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v2.5 PHYSICS-OPTIMIZED!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v2.5 (Physics-Optimized)");
   Print("   Entry System: ", UsePhysicsEntry ? "PHYSICS" : (UseMAEntry ? "MA CROSSOVER" : "NONE"));
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   Print("   Physics Filters: ", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED (logging only)");
   if(UsePhysicsFilters)
   {
      Print("   → Zone Filter: ", UseZoneFilter ? "ENABLED (Avoid BEAR)" : "DISABLED");
      Print("   → Regime Filter: ", UseRegimeFilter ? "ENABLED (Avoid LOW, Prefer HIGH)" : "DISABLED");
      Print("   → Quality Filter: MinQuality=", MinQuality);
      Print("   → Confluence Filter: MinConfluence=", MinConfluence);
   }
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", MaxDailyRisk, "%");
   Print("   Max Concurrent: ", MaxConcurrentTrades, " trades");
   Print("   SL/TP: ", StopLossPips, "/", TakeProfitPips, " pips");
   Print("   Post-Exit Monitor: ", PostExitMonitorBars, " bars");
   Print("   CSV Files: ", "v2.5 (Trades & Signals)");
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
//| New bar handler - Signal generation and trade logic              |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // 1. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 2. Log signal (regardless of quality)
   if(EnableRealTimeLogging)
   {
      LogSignal(signal, quality, confluence, zone, regime);
   }
   
   // 3. Check if we should trade
   if(signal == 0) return;  // No signal
   
   // 4. Apply physics filters (ONLY if enabled)
   string rejectReason = "";
   bool passFilters = true;
   
   if(UsePhysicsFilters)
   {
      // Quality/Confluence filters (baseline - no strong correlation found)
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
      // Zone filter: AVOID BEAR zone (24.4% win rate, -$3.14 avg)
      else if(UseZoneFilter && zone == ZONE_BEAR)
      {
         rejectReason = "BEAR zone (poor performance)";
         passFilters = false;
      }
      // Regime filter: AVOID LOW volatility (21.4% win rate), PREFER HIGH (36.4% win rate)
      else if(UseRegimeFilter && regime == REGIME_LOW)
      {
         rejectReason = "LOW volatility regime (poor performance)";
         passFilters = false;
      }
      
      if(!passFilters)
      {
         if(EnableDebugMode)
            Print("🚫 Signal rejected: ", rejectReason, " (Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime), ")");
         return;
      }
      else if(EnableDebugMode)
      {
         // Log when we ACCEPT a trade due to good filters
         Print("✅ Signal ACCEPTED: Zone=", g_physics.GetZoneName(zone), ", Regime=", g_physics.GetRegimeName(regime));
      }
   }
   else
   {
      // Physics filters disabled - log but don't filter
      if(EnableDebugMode)
         Print("✅ Physics filters DISABLED - accepting all signals (Q=", quality, ", C=", confluence, ")");
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
   
   // Calculate risk money (% of balance)
   double riskMoney = balance * (RiskPercentPerTrade / 100.0);
   
   double lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
   if(lots <= 0)
   {
      Print("❌ Invalid lot size calculated: ", lots);
      return;
   }
   
   if(EnableDebugMode)
      Print("📏 Position size: ", lots, " lots (risk: $", riskMoney, ")");
   
   // 10. Validate R:R ratio
   double rRatio = tpDistance / slDistance;
   if(rRatio < MinRRatio)
   {
      Print("🚫 Trade rejected: R:R ratio too low (", DoubleToString(rRatio, 2), " < ", MinRRatio, ")");
      return;
   }
   
   if(EnableDebugMode)
      Print("✅ R:R ratio OK: ", DoubleToString(rRatio, 2));
   
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
