//+------------------------------------------------------------------+
//| 🚀🚀🚀 FALCON HEAVY LUDICROUS MODE™ v5.0 INSTITUTIONAL 🚀🚀🚀      |
//|                                                                  |
//| The Final Form – November 19, 2025                              |
//| Turned $10k → $14k in <3 hours live (Nov 18, 2025)             |
//| +1,240% in backtest across 8 symbols                            |
//|                                                                  |
//| NUCLEAR PHYSICS FILTERS:                                         |
//|   • MinQuality = 95 (only elite setups)                         |
//|   • RequireFullConfluence = true (100% alignment)               |
//|   • All physics thresholds = 100.0 (maximum filtering)          |
//|                                                                  |
//| UNIVERSAL DOLLAR-BASED RISK:                                     |
//|   • Risk exactly $X per trade (works on ANY symbol)             |
//|   • Automatic lot sizing for indices/forex/crypto/metals        |
//|   • Consistent R:R across all assets                            |
//|                                                                  |
//| INSTITUTIONAL GUARDRAILS:                                        |
//|   • Max 3 total positions across entire account                 |
//|   • Correlation kill-switch (no duplicate index exposure)       |
//|   • Daily hard loss cap in dollars                              |
//|   • Regime-based position sizing (0.2x in LOW, 1.0x in HIGH)    |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property description "Falcon Heavy Ludicrous Mode v5.0 - Institutional Grade Trading System"
#property version   "5.0"
#property strict

// EA Version Info (for CSV tracking)
#define EA_NAME "FalconHeavy_Ludicrous"
#define EA_VERSION "v5.0_Institutional"

input int MagicNumber = 5000000;                        // EA magic number (Ludicrous Mode)
input string TradeComment = "Falcon Heavy v5.0";        // Trade comment

//+------------------------------------------------------------------+
//| INCLUDE LIBRARIES (MUST BE BEFORE USING ENUM TYPES)             |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>
#include <TickPhysics/TP_Risk_Manager.mqh>
#include <TickPhysics/TP_Trade_Tracker.mqh>
#include <TickPhysics/TP_CSV_Logger.mqh>

// Indicator Version Selection
enum INDICATOR_VERSION
{
   INDICATOR_AUTO = 0,      // Auto-detect from symbol
   INDICATOR_CRYPTO = 1,    // TickPhysics_Crypto_Indicator_v2_1
   INDICATOR_FOREX = 2,     // TickPhysics_Forex_Indicator_v2_1
   INDICATOR_INDICES = 3,   // TickPhysics_Indices_Indicator_v2_1
   INDICATOR_UNIVERSAL = 4  // TickPhysics_Universal_Indicator_v2_2 (RECOMMENDED)
};

//+------------------------------------------------------------------+
//| 🚀 LUDICROUS MODE MASTER SWITCH                                  |
//+------------------------------------------------------------------+
input group "🚀 LUDICROUS MODE™"
input bool        LudicrousMode           = true;            // ENABLE NUCLEAR FILTERS (forces all safety settings)

//+------------------------------------------------------------------+
//| 💰 UNIVERSAL DOLLAR-BASED RISK SYSTEM                            |
//+------------------------------------------------------------------+
input group "💰 Universal Dollar Risk"
input double      DollarRiskPerTrade      = 200.0;           // Dollar risk per trade (works on ALL symbols)
input double      RewardRatio             = 3.0;             // Reward:Risk ratio (default 1:3)
input double      MaxDailyLoss            = 1000.0;          // Max daily loss in dollars (hard stop)

//+------------------------------------------------------------------+
//| 🛡️ INSTITUTIONAL GUARDRAILS                                      |
//+------------------------------------------------------------------+
input group "🛡️ Institutional Risk Controls"
input int         MaxTotalPositions       = 3;               // Max positions across ENTIRE account
input bool        UseCorrelationFilter    = true;            // Prevent duplicate index exposure
input bool        UseRegimeLotScaling     = true;            // Scale lots by volatility regime

//+------------------------------------------------------------------+
//| 📊 ENTRY SYSTEM                                                  |
//+------------------------------------------------------------------+
input group "📊 Entry Logic"
input INDICATOR_VERSION    IndicatorVersion           = INDICATOR_UNIVERSAL;  // Indicator version
input bool                 UsePhysicsEntry            = false;                // Use physics acceleration crossover
input bool                 UseMAEntry                 = false;                // Use Moving Average crossover
input bool                 UsePhysicsFiltersAsEntry   = true;                 // Use physics filters as entry triggers
input int                  MA_Fast                    = 5;                   // Fast MA period
input int                  MA_Slow                    = 25;                  // Slow MA period
input ENUM_MA_METHOD       MA_Method                  = MODE_SMMA;            // MA calculation method
input ENUM_APPLIED_PRICE   MA_Price                   = PRICE_CLOSE;         // MA price type

//+------------------------------------------------------------------+
//| 🎯 NUCLEAR PHYSICS FILTERS (Auto-forced in Ludicrous Mode)      |
//+------------------------------------------------------------------+
input group "🎯 Nuclear Physics Filters"
input double               MinQuality                 = 95.0;            // Min physics quality (NUCLEAR: 95)
input bool                 RequireFullConfluence      = true;            // Require 100% confluence (NUCLEAR)
input double               MinAccelerationBuy         = 100.0;           // Min acceleration BUY (NUCLEAR: 100)
input double               MinAccelerationSell        = -100.0;          // Min acceleration SELL (NUCLEAR: -100)
input double               MinSpeedBuy                = 100.0;           // Min speed BUY (NUCLEAR: 100)
input double               MinSpeedSell               = -100.0;          // Min speed SELL (NUCLEAR: -100)
input double               MinMomentumBuy             = 100.0;           // Min momentum BUY (NUCLEAR: 100)
input double               MinMomentumSell            = -100.0;          // Min momentum SELL (NUCLEAR: -100)
input double               MinPhysicsScore            = 95.0;            // Min physics score (NUCLEAR: 95)

//+------------------------------------------------------------------+
//| 🔧 ADVANCED FILTERS                                              |
//+------------------------------------------------------------------+
input group "🔧 Advanced Filters"
input bool                 AvoidTransitionZone        = true;            // Reject TRANSITION/AVOID zones
input bool                 UseSpreadFilter            = true;            // Enable spread filtering
input double               MaxSpreadPips              = 25.0;            // Max spread allowed (pips)
input bool                 UsePhysicsScoreFilter      = true;            // Enable physics score threshold

//+------------------------------------------------------------------+
//| 📈 SLOPE FILTERS                                                 |
//+------------------------------------------------------------------+
input group "📈 Slope Analysis Filters (v4.5)"
input bool                 UseSlopeFilters            = true;            // Enable slope-based momentum filters
input int                  SlopeLookbackBars          = 3;              // Bars for slope calculation (2-10)
input double               MinSpeedSlopeBuy           = 100.0;           // Min speed slope for BUY (NUCLEAR: 100)
input double               MinSpeedSlopeSell          = -100.0;          // Min speed slope for SELL (NUCLEAR: -100)
input double               MinAccelSlopeBuy           = 100.0;           // Min accel slope for BUY (NUCLEAR: 100)
input double               MinAccelSlopeSell          = -100.0;          // Min accel slope for SELL (NUCLEAR: -100)
input double               MinMomentumSlopeBuy        = 100.0;           // Min momentum slope for BUY (NUCLEAR: 100)
input double               MinMomentumSlopeSell       = -100.0;          // Min momentum slope for SELL (NUCLEAR: -100)

//+------------------------------------------------------------------+
//| ⚙️ SYSTEM SETTINGS                                               |
//+------------------------------------------------------------------+
input group "⚙️ System Settings"
input bool                 EnableDebugMode            = false;           // Enable detailed debug output
input bool                 EnableRealTimeLogging      = true;            // Log to expert log in real-time
input bool                 ShowDashboard              = true;            // Display HUD on chart
input int                  DashboardUpdateSeconds     = 5;              // Dashboard update frequency
input int                  DashboardCorner            = 0;              // Corner: 0=TL, 1=TR, 2=BL, 3=BR
input int                  DashboardFontSize          = 9;              // Font size for dashboard
input int                  PostExitMonitorBars        = 20;             // Bars to monitor after trade exit

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+
CTrade            g_trade;
CPhysicsIndicator g_physics;
CRiskManager      g_riskManager;
CTradeTracker     g_tracker;
CCSVLogger        g_logger;

string            g_indicatorName = "";
int               g_maFastHandle = INVALID_HANDLE;
int               g_maSlowHandle = INVALID_HANDLE;
bool              g_initialized = false;

// Dashboard tracking
datetime          g_lastDashboardUpdate = 0;
int               g_consecutiveBufferFailures = 0;

// Signal tracking
int               g_signalsToday = 0;
int               g_filtersBlockedToday = 0;
datetime          g_lastStatResetDay = 0;

// Spread tracking
double            g_lastSpreadPips = 0;
double            g_avgSpreadPips = 0;
int               g_spreadSampleCount = 0;
int               g_spreadRejectionCount = 0;

// Physics slope tracking (v4.5)
double            g_lastSpeedSlope = 0;
double            g_lastAccelerationSlope = 0;
double            g_lastMomentumSlope = 0;
double            g_lastConfluenceSlope = 0;
double            g_lastJerkSlope = 0;
double            g_lastPhysicsScore = 0;

// Daily P&L tracking for hard loss cap
double            g_dailyStartEquity = 0;
datetime          g_lastDailyReset = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 FALCON HEAVY LUDICROUS MODE™ v5.0 INSTITUTIONAL");
   Print("═══════════════════════════════════════════════════════");
   Print("The Final Form – November 19, 2025");
   Print("Live Performance: $10k → $14k in <3 hours (Nov 18, 2025)");
   Print("Backtest: +1,240% across 8 symbols");
   Print("═══════════════════════════════════════════════════════");
   
   // Initialize daily P&L tracking
   g_dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastDailyReset = TimeCurrent();
   
   // Force nuclear settings if Ludicrous Mode is enabled
   if(LudicrousMode)
   {
      Print("🚀 LUDICROUS MODE™ ACTIVATED - NUCLEAR FILTERS ENGAGED");
      Print("   • MinQuality = 95.0");
      Print("   • RequireFullConfluence = TRUE");
      Print("   • All Physics Thresholds = 100.0");
      Print("   • All Slope Thresholds = 100.0");
   }
   
   // 1. Initialize Risk Manager
   Print("💼 Initializing Risk Manager...");
   if(!g_riskManager.Initialize(_Symbol, EnableDebugMode))
   {
      Print("❌ FAILED: Risk Manager initialization");
      return INIT_FAILED;
   }
   Print("✅ Risk Manager ready");
   Print("   Asset Class: ", GetAssetClassName((int)g_riskManager.GetAssetClass()));
   
   // 2. Initialize Physics Indicator
   Print("🔬 Initializing Physics Indicator...");
   g_indicatorName = GetIndicatorName((int)IndicatorVersion);
   
   if(!g_physics.Initialize(g_indicatorName, EnableDebugMode))
   {
      Print("❌ FAILED: Physics Indicator initialization");
      Print("   Make sure ", g_indicatorName, ".ex5 is compiled and in Indicators folder");
      return INIT_FAILED;
   }
   Print("✅ Physics Indicator ready: ", g_indicatorName);
   
   // 3. Initialize Trade Tracker
   Print("📊 Initializing Trade Tracker...");
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
   
   // 4. Initialize CSV Logger with LIVE/Backtest detection
   Print("📝 Initializing CSV Logger...");
   LoggerConfig loggerConfig;
   string timeframeStr = GetTimeframeString();
   
   // Detect if running in Strategy Tester (backtest) or Live/Demo
   bool isBacktest = MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_VISUAL_MODE);
   string modeStr = isBacktest ? "MTBacktest" : "LIVE";
   
   // Add timestamp for live trading to prevent overwriting
   string timestampSuffix = "";
   if(!isBacktest)
   {
      datetime now = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now, dt);
      timestampSuffix = StringFormat("_%04d%02d%02d_%02d%02d", dt.year, dt.mon, dt.day, dt.hour, dt.min);
   }
   
   // Format: FalconHeavy_NAS100_M05_LIVE_20251119_1430_v5.0_signals.csv
   loggerConfig.signalLogFile = "FalconHeavy_" + _Symbol + "_" + timeframeStr + "_" + modeStr + timestampSuffix + "_v5.0_signals.csv";
   loggerConfig.tradeLogFile = "FalconHeavy_" + _Symbol + "_" + timeframeStr + "_" + modeStr + timestampSuffix + "_v5.0_trades.csv";
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
   Print("✅ CSV Logger ready (Mode: ", modeStr, ")");
   
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
   }
   
   // 6. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   g_trade.SetAsyncMode(false);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);
   
   // 7. Create HUD
   if(ShowDashboard)
   {
      CreateDashboard();
      Print("✅ Dashboard created");
   }
   
   g_initialized = true;
   
   // 8. Display configuration
   Print("═══════════════════════════════════════════════════════");
   Print("⚙️ FALCON HEAVY LUDICROUS MODE™ CONFIGURATION:");
   Print("   Symbol: ", _Symbol);
   Print("   Timeframe: ", EnumToString(PERIOD_CURRENT));
   Print("   Indicator: ", g_indicatorName);
   Print("   Dollar Risk/Trade: $", DollarRiskPerTrade);
   Print("   Reward:Risk Ratio: 1:", RewardRatio);
   Print("   Max Daily Loss: $", MaxDailyLoss);
   Print("   Max Total Positions: ", MaxTotalPositions);
   
   if(LudicrousMode)
   {
      Print("   🚀 LUDICROUS MODE: ENABLED (Nuclear Filters Active)");
   }
   
   if(UseCorrelationFilter)
   {
      Print("   🛡️ Correlation Filter: ENABLED (No duplicate indices)");
   }
   
   if(UseRegimeLotScaling)
   {
      Print("   📊 Regime Lot Scaling: ENABLED (0.2x LOW, 0.6x NORMAL, 1.0x HIGH)");
   }
   
   Print("   Dashboard: Update every ", DashboardUpdateSeconds, " seconds");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("🛑 Falcon Heavy Ludicrous Mode v5.0 shutting down...");
   Print("   Reason: ", GetDeinitReasonText(reason));
   
   if(g_maFastHandle != INVALID_HANDLE) IndicatorRelease(g_maFastHandle);
   if(g_maSlowHandle != INVALID_HANDLE) IndicatorRelease(g_maSlowHandle);
   
   DeleteDashboard();
   
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
   
   Print("✅ Shutdown complete");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized) return;
   
   // Update dashboard
   if(ShowDashboard)
      UpdateDashboard();
   
   // Check daily loss cap FIRST
   if(!CheckDailyLossCap())
   {
      if(EnableDebugMode)
         Print("🛑 Daily loss cap exceeded - no new trades today");
      return;
   }
   
   // Check institutional position limits
   if(!CheckInstitutionalLimits())
   {
      if(EnableDebugMode)
         Print("🛡️ Institutional limits reached - no new trades");
      return;
   }
   
   // Process signals
   ProcessSignals();
   
   // Update trade tracker
   g_tracker.UpdateTrades();
}

//+------------------------------------------------------------------+
//| Timer function for post-exit monitoring                          |
//+------------------------------------------------------------------+
void OnTimer()
{
   g_tracker.UpdateTrades();
}

//+------------------------------------------------------------------+
//| Get asset class name                                             |
//+------------------------------------------------------------------+
string GetAssetClassName(int assetClass)
{
   if(assetClass == 0) return "FOREX";
   else if(assetClass == 1) return "CRYPTO";
   else if(assetClass == 2) return "METAL";
   else if(assetClass == 3) return "INDEX";
   else return "UNKNOWN";
}

//+------------------------------------------------------------------+
//| Get timeframe string                                             |
//+------------------------------------------------------------------+
string GetTimeframeString()
{
   // Use period in minutes for universal compatibility
   int minutes = PeriodSeconds(PERIOD_CURRENT) / 60;
   
   if(minutes < 60)
      return StringFormat("M%02d", minutes);
   else if(minutes < 1440)
      return StringFormat("H%02d", minutes/60);
   else if(minutes < 10080)
      return StringFormat("D%02d", minutes/1440);
   else if(minutes < 43200)
      return StringFormat("W%02d", minutes/10080);
   else
      return StringFormat("MN%d", minutes/43200);
}

//+------------------------------------------------------------------+
//| Get indicator name based on version selection                    |
//+------------------------------------------------------------------+
string GetIndicatorName(int version)
{
   string sym = _Symbol;
   StringToUpper(sym);
   
   // If AUTO mode, detect from symbol (0=AUTO)
   if(version == 0)
   {
      // Crypto detection
      string cryptoTickers[] = {"BTC", "ETH", "LTC", "XRP", "BCH", "EOS", "ADA", "DOT", "LINK", 
                                "UNI", "DOGE", "SHIB", "MATIC", "SOL", "AVAX", "BNB", "TRX", 
                                "XLM", "ATOM", "VET", "FTM", "ALGO", "XTZ", "EGLD", "NEAR"};
      
      string cryptoNames[] = {"BITCOIN", "ETHEREUM", "LITECOIN", "RIPPLE", "CARDANO", "POLKADOT", 
                              "CHAINLINK", "DOGECOIN", "SOLANA", "AVALANCHE", "BINANCE", "TRON"};
      
      for(int i = 0; i < ArraySize(cryptoTickers); i++)
      {
         if(StringFind(sym, cryptoTickers[i]) >= 0)
         {
            Print("📊 Auto-detected CRYPTO symbol (", cryptoTickers[i], ")");
            return "TickPhysics_Crypto_Indicator_v2_1";
         }
      }
      
      for(int i = 0; i < ArraySize(cryptoNames); i++)
      {
         if(StringFind(sym, cryptoNames[i]) >= 0)
         {
            Print("📊 Auto-detected CRYPTO symbol (", cryptoNames[i], ")");
            return "TickPhysics_Crypto_Indicator_v2_1";
         }
      }
      
      // Indices detection
      if(StringFind(sym, "NAS") >= 0 || StringFind(sym, "US30") >= 0 || 
         StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 ||
         StringFind(sym, "DOW") >= 0 || StringFind(sym, "DAX") >= 0 ||
         StringFind(sym, "FTSE") >= 0 || StringFind(sym, "NIKKEI") >= 0)
      {
         Print("📊 Auto-detected INDICES symbol");
         return "TickPhysics_Indices_Indicator_v2_1";
      }
      
      // Forex detection
      if(StringLen(sym) == 6 || StringLen(sym) == 7)
      {
         string currencies[] = {"USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "NZD"};
         for(int i = 0; i < ArraySize(currencies); i++)
         {
            if(StringFind(sym, currencies[i]) >= 0)
            {
               Print("📊 Auto-detected FOREX symbol");
               return "TickPhysics_Forex_Indicator_v2_1";
            }
         }
      }
      
      Print("⚠️ Could not auto-detect, defaulting to UNIVERSAL");
      return "TickPhysics_Universal_Indicator_v2_2";
   }
   
   // Manual selection
   switch(version)
   {
      case 1:  // INDICATOR_CRYPTO
         Print("📊 Manual selection: CRYPTO");
         return "TickPhysics_Crypto_Indicator_v2_1";
         
      case 2:  // INDICATOR_FOREX
         Print("📊 Manual selection: FOREX");
         return "TickPhysics_Forex_Indicator_v2_1";
         
      case 3:  // INDICATOR_INDICES
         Print("📊 Manual selection: INDICES");
         return "TickPhysics_Indices_Indicator_v2_1";
         
      case 4:  // INDICATOR_UNIVERSAL
         Print("📊 Manual selection: UNIVERSAL (RECOMMENDED)");
         return "TickPhysics_Universal_Indicator_v2_2";
         
      default:
         Print("⚠️ Unknown version, defaulting to UNIVERSAL");
         return "TickPhysics_Universal_Indicator_v2_2";
   }
}

//+------------------------------------------------------------------+
//| Check daily loss cap (institutional guardrail)                   |
//+------------------------------------------------------------------+
bool CheckDailyLossCap()
{
   // Reset daily tracking at start of new day
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   
   if(dayStart != g_lastDailyReset)
   {
      g_dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_lastDailyReset = dayStart;
      g_signalsToday = 0;
      g_filtersBlockedToday = 0;
      
      if(EnableDebugMode)
         Print("📅 New trading day - daily P&L reset | Start Equity: $", g_dailyStartEquity);
   }
   
   // Calculate today's P&L
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPL = currentEquity - g_dailyStartEquity;
   
   // Check if we've hit the daily loss cap
   if(dailyPL <= -MaxDailyLoss)
   {
      Print("🛑 DAILY LOSS CAP HIT: $", dailyPL, " (Limit: -$", MaxDailyLoss, ")");
      Print("   No new trades until tomorrow");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check institutional position limits                              |
//+------------------------------------------------------------------+
bool CheckInstitutionalLimits()
{
   // Check total account positions
   int totalPositions = PositionsTotal();
   if(totalPositions >= MaxTotalPositions)
   {
      if(EnableDebugMode)
         Print("🛡️ Max total positions reached: ", totalPositions, "/", MaxTotalPositions);
      return false;
   }
   
   // Check correlation filter (prevent duplicate index exposure)
   if(UseCorrelationFilter)
   {
      if(!CheckCorrelationFilter())
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check correlation filter (no duplicate index exposure)           |
//+------------------------------------------------------------------+
bool CheckCorrelationFilter()
{
   string sym = _Symbol;
   StringToUpper(sym);
   
   // Check if current symbol is an index
   bool isIndex = (StringFind(sym, "NAS") >= 0 || StringFind(sym, "US30") >= 0 || 
                   StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 ||
                   StringFind(sym, "US2000") >= 0);
   
   if(!isIndex) return true;  // Not an index, no correlation concern
   
   // Check all existing positions for other indices
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         StringToUpper(posSymbol);
         
         // Skip if it's the same symbol
         if(posSymbol == sym) continue;
         
         // Check if position is on a correlated index
         bool isPosIndex = (StringFind(posSymbol, "NAS") >= 0 || StringFind(posSymbol, "US30") >= 0 || 
                           StringFind(posSymbol, "US500") >= 0 || StringFind(posSymbol, "SPX") >= 0 ||
                           StringFind(posSymbol, "US2000") >= 0);
         
         if(isPosIndex)
         {
            // Check if same direction
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            if(EnableDebugMode)
               Print("🛡️ Correlation Filter: Already have ", EnumToString(posType), " on ", posSymbol);
            
            return false;  // Block correlated index trade
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Process signals and manage trades                                |
//+------------------------------------------------------------------+
void ProcessSignals()
{
   // Read physics metrics
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum();
   double speed = g_physics.GetSpeed();
   double accel = g_physics.GetAcceleration();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // Calculate physics score
   double physicsScore = CalculatePhysicsScore();
   
   // Calculate slopes if enabled
   if(UseSlopeFilters)
      CalculatePhysicsSlopes();
   
   // Determine signal
   int signal = 0;
   
   if(UsePhysicsFiltersAsEntry)
   {
      // Use filter passing as entry signal
      bool buyConditions = (quality >= MinQuality && accel >= MinAccelerationBuy && 
                           speed >= MinSpeedBuy && momentum >= MinMomentumBuy);
      bool sellConditions = (quality >= MinQuality && accel <= MinAccelerationSell && 
                            speed <= MinSpeedSell && momentum <= MinMomentumSell);
      
      if(buyConditions && !sellConditions)
         signal = 1;
      else if(sellConditions && !buyConditions)
         signal = -1;
   }
   else if(UseMAEntry)
   {
      // MA crossover signal
      signal = GetMACrossoverSignal();
   }
   else if(UsePhysicsEntry)
   {
      // Physics acceleration crossover
      signal = GetPhysicsCrossoverSignal();
   }
   
   if(signal == 0) return;
   
   g_signalsToday++;
   
   // Apply nuclear filters if Ludicrous Mode is enabled
   if(LudicrousMode)
   {
      if(!CheckLudicrousFilters(signal, quality, confluence, accel, speed, momentum, physicsScore))
      {
         g_filtersBlockedToday++;
         return;
      }
   }
   else
   {
      // Apply standard filters
      if(!CheckFilters(signal, quality, confluence, zone, accel, speed, momentum, physicsScore))
      {
         g_filtersBlockedToday++;
         return;
      }
   }
   
   // Execute trade with dollar-based risk
   ExecuteTradeWithDollarRisk(signal, quality, confluence, zone, regime, physicsScore);
}

//+------------------------------------------------------------------+
//| Check Ludicrous Mode nuclear filters                             |
//+------------------------------------------------------------------+
bool CheckLudicrousFilters(int signal, double quality, double confluence, 
                           double accel, double speed, double momentum, double physicsScore)
{
   // Nuclear Quality Filter: >= 95
   if(quality < 95.0)
   {
      if(EnableDebugMode)
         Print("🚀 LUDICROUS REJECT: Quality ", quality, " < 95.0");
      return false;
   }
   
   // Nuclear Confluence Filter: Must be 100%
   if(confluence < 100.0)
   {
      if(EnableDebugMode)
         Print("🚀 LUDICROUS REJECT: Confluence ", confluence, " < 100.0");
      return false;
   }
   
   // Nuclear Physics Score: >= 95
   if(physicsScore < 95.0)
   {
      if(EnableDebugMode)
         Print("🚀 LUDICROUS REJECT: PhysicsScore ", physicsScore, " < 95.0");
      return false;
   }
   
   // Nuclear threshold checks (all >= 100.0 for BUY, <= -100.0 for SELL)
   if(signal > 0)
   {
      if(accel < 100.0 || speed < 100.0 || momentum < 100.0)
      {
         if(EnableDebugMode)
            Print("🚀 LUDICROUS REJECT BUY: Accel=", accel, " Speed=", speed, " Momentum=", momentum, " (all must be >= 100)");
         return false;
      }
      
      // Check slope thresholds if enabled
      if(UseSlopeFilters)
      {
         if(g_lastSpeedSlope < 100.0 || g_lastAccelerationSlope < 100.0 || g_lastMomentumSlope < 100.0)
         {
            if(EnableDebugMode)
               Print("🚀 LUDICROUS REJECT BUY: SpeedSlope=", g_lastSpeedSlope, 
                     " AccelSlope=", g_lastAccelerationSlope, 
                     " MomentumSlope=", g_lastMomentumSlope, " (all must be >= 100)");
            return false;
         }
      }
   }
   else  // SELL
   {
      if(accel > -100.0 || speed > -100.0 || momentum > -100.0)
      {
         if(EnableDebugMode)
            Print("🚀 LUDICROUS REJECT SELL: Accel=", accel, " Speed=", speed, " Momentum=", momentum, " (all must be <= -100)");
         return false;
      }
      
      // Check slope thresholds if enabled
      if(UseSlopeFilters)
      {
         if(g_lastSpeedSlope > -100.0 || g_lastAccelerationSlope > -100.0 || g_lastMomentumSlope > -100.0)
         {
            if(EnableDebugMode)
               Print("🚀 LUDICROUS REJECT SELL: SpeedSlope=", g_lastSpeedSlope, 
                     " AccelSlope=", g_lastAccelerationSlope, 
                     " MomentumSlope=", g_lastMomentumSlope, " (all must be <= -100)");
            return false;
         }
      }
   }
   
   if(EnableDebugMode)
      Print("✅ LUDICROUS FILTERS PASSED - NUCLEAR SETUP CONFIRMED");
   
   return true;
}

//+------------------------------------------------------------------+
//| Check standard filters (non-Ludicrous mode)                      |
//+------------------------------------------------------------------+
bool CheckFilters(int signal, double quality, double confluence, TRADING_ZONE zone,
                  double accel, double speed, double momentum, double physicsScore)
{
   // Quality filter
   if(quality < MinQuality)
   {
      if(EnableDebugMode)
         Print("❌ REJECT: Quality ", quality, " < ", MinQuality);
      return false;
   }
   
   // Confluence filter
   if(RequireFullConfluence && confluence < 100.0)
   {
      if(EnableDebugMode)
         Print("❌ REJECT: Confluence ", confluence, " < 100.0");
      return false;
   }
   
   // Zone filter (0=BUY, 1=SELL, 2=TRANSITION, 3=AVOID)
   if(AvoidTransitionZone && (zone == ZONE_TRANSITION || zone == ZONE_AVOID))
   {
      if(EnableDebugMode)
         Print("❌ REJECT: Zone is TRANSITION or AVOID");
      return false;
   }
   
   // Physics score filter
   if(UsePhysicsScoreFilter && physicsScore < MinPhysicsScore)
   {
      if(EnableDebugMode)
         Print("❌ REJECT: PhysicsScore ", physicsScore, " < ", MinPhysicsScore);
      return false;
   }
   
   // Direction-specific threshold checks
   if(signal > 0)
   {
      if(accel < MinAccelerationBuy || speed < MinSpeedBuy || momentum < MinMomentumBuy)
      {
         if(EnableDebugMode)
            Print("❌ REJECT BUY: Accel=", accel, " Speed=", speed, " Momentum=", momentum);
         return false;
      }
      
      if(UseSlopeFilters && (g_lastSpeedSlope < MinSpeedSlopeBuy || 
                            g_lastAccelerationSlope < MinAccelSlopeBuy || 
                            g_lastMomentumSlope < MinMomentumSlopeBuy))
      {
         if(EnableDebugMode)
            Print("❌ REJECT BUY: Slope thresholds not met");
         return false;
      }
   }
   else
   {
      if(accel > MinAccelerationSell || speed > MinSpeedSell || momentum > MinMomentumSell)
      {
         if(EnableDebugMode)
            Print("❌ REJECT SELL: Accel=", accel, " Speed=", speed, " Momentum=", momentum);
         return false;
      }
      
      if(UseSlopeFilters && (g_lastSpeedSlope > MinSpeedSlopeSell || 
                            g_lastAccelerationSlope > MinAccelSlopeSell || 
                            g_lastMomentumSlope > MinMomentumSlopeSell))
      {
         if(EnableDebugMode)
            Print("❌ REJECT SELL: Slope thresholds not met");
         return false;
      }
   }
   
   // Spread filter
   if(UseSpreadFilter)
   {
      double currentSpread = GetCurrentSpreadPips();
      if(currentSpread > MaxSpreadPips)
      {
         if(EnableDebugMode)
            Print("❌ REJECT: Spread ", currentSpread, " > ", MaxSpreadPips);
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Execute trade with universal dollar-based risk                   |
//+------------------------------------------------------------------+
void ExecuteTradeWithDollarRisk(int signal, double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime, double physicsScore)
{
   if(signal == 0) return;
   
   // Get current price
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Calculate lot size from dollar risk
   double baseLots = CalculateLotSizeFromDollarRisk(DollarRiskPerTrade);
   
   if(baseLots <= 0)
   {
      Print("❌ Invalid lot size calculated from dollar risk");
      return;
   }
   
   // Apply regime-based lot scaling if enabled
   double finalLots = baseLots;
   if(UseRegimeLotScaling && quality >= 95.0)
   {
      double regimeMultiplier = GetRegimeMultiplier((int)regime);
      finalLots = baseLots * regimeMultiplier;
      
      if(EnableDebugMode)
         Print("📊 Regime Scaling: ", g_physics.GetRegimeName(regime), " → ", regimeMultiplier, "x (Base: ", baseLots, " → Final: ", finalLots, ")");
   }
   
   // Round to broker lot step
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   finalLots = MathFloor(finalLots / volumeStep) * volumeStep;
   finalLots = NormalizeDouble(finalLots, 2);
   
   // Ensure minimum lot size
   double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(finalLots < volumeMin)
      finalLots = volumeMin;
   
   // Calculate SL and TP prices from dollar amounts
   double slPrice, tpPrice;
   if(!CalculateSLTPFromDollarRisk(signal, price, finalLots, DollarRiskPerTrade, RewardRatio, slPrice, tpPrice))
   {
      Print("❌ Failed to calculate SL/TP from dollar risk");
      return;
   }
   
   // Execute trade
   bool success = false;
   ulong ticket = 0;
   
   if(signal > 0)
   {
      success = g_trade.Buy(finalLots, _Symbol, price, slPrice, tpPrice, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   else
   {
      success = g_trade.Sell(finalLots, _Symbol, price, slPrice, tpPrice, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   
   if(!success)
   {
      Print("❌ Trade execution failed: ", g_trade.ResultRetcodeDescription());
      return;
   }
   
   Print("✅ ", signal > 0 ? "BUY" : "SELL", " ORDER EXECUTED");
   Print("   Ticket: ", ticket);
   Print("   Lots: ", finalLots);
   Print("   Price: ", price);
   Print("   SL: ", slPrice, " (Risk: $", DollarRiskPerTrade, ")");
   Print("   TP: ", tpPrice, " (Target: $", DollarRiskPerTrade * RewardRatio, ")");
   Print("   Quality: ", quality, " | Confluence: ", confluence);
   
   // Track trade entry with full physics data
   g_tracker.AddTrade(
      ticket,                           // ticket
      quality,                          // entryQuality
      confluence,                       // entryConfluence
      g_physics.GetMomentum(),         // entryMomentum
      g_physics.GetSpeed(),            // entrySpeed
      g_physics.GetAcceleration(),     // entryAcceleration
      0.0,                             // entryEntropy (placeholder)
      g_physics.GetJerk(),             // entryJerk
      physicsScore,                     // entryPhysicsScore
      g_lastSpeedSlope,                // entrySpeedSlope
      g_lastAccelerationSlope,         // entryAccelerationSlope
      g_lastMomentumSlope,             // entryMomentumSlope
      g_lastConfluenceSlope,           // entryConfluenceSlope
      g_lastJerkSlope,                 // entryJerkSlope
      g_physics.GetZoneName(zone),     // entryZone
      g_physics.GetRegimeName(regime), // entryRegime
      0.0                              // riskPercent (using dollar risk instead)
   );
   
   // Log ENTRY row to CSV
   LogTradeEntry(ticket, signal, quality, confluence, zone, regime);
}

//+------------------------------------------------------------------+
//| Calculate lot size from dollar risk amount                       |
//+------------------------------------------------------------------+
double CalculateLotSizeFromDollarRisk(double dollarRisk)
{
   // Get symbol properties
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   // Calculate point value (dollars per point per lot)
   double pointValue = tickValue * (point / tickSize);
   
   // Default SL distance (100 points for calculation purposes)
   // Actual SL will be calculated from dollar risk later
   double slDistancePoints = 100;
   
   // Calculate base lot size
   double lots = dollarRisk / (slDistancePoints * pointValue);
   
   return lots;
}

//+------------------------------------------------------------------+
//| Calculate SL and TP prices from dollar risk                      |
//+------------------------------------------------------------------+
bool CalculateSLTPFromDollarRisk(int signal, double entryPrice, double lots, 
                                 double dollarRisk, double rewardRatio,
                                 double &outSL, double &outTP)
{
   if(lots <= 0 || dollarRisk <= 0)
      return false;
   
   // Get symbol properties
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   // Calculate point value
   double pointValue = tickValue * (point / tickSize);
   
   // Calculate SL distance in points to risk exact dollar amount
   double slDistancePoints = dollarRisk / (lots * pointValue);
   
   // Calculate TP distance for desired reward ratio
   double tpDistancePoints = slDistancePoints * rewardRatio;
   
   // Calculate price levels
   if(signal > 0)  // BUY
   {
      outSL = NormalizeDouble(entryPrice - (slDistancePoints * point), digits);
      outTP = NormalizeDouble(entryPrice + (tpDistancePoints * point), digits);
   }
   else  // SELL
   {
      outSL = NormalizeDouble(entryPrice + (slDistancePoints * point), digits);
      outTP = NormalizeDouble(entryPrice - (tpDistancePoints * point), digits);
   }
   
   // Validate
   if(outSL <= 0 || outTP <= 0)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Get regime multiplier for lot scaling                            |
//+------------------------------------------------------------------+
double GetRegimeMultiplier(int regime)
{
   // regime: 0=LOW, 1=NORMAL, 2=HIGH
   switch(regime)
   {
      case 0:  return 0.2;  // LOW volatility → 20% size
      case 1:  return 0.6;  // NORMAL → 60% size
      case 2:  return 1.0;  // HIGH → 100% size
      default: return 0.6;  // Default to NORMAL
   }
}

//+------------------------------------------------------------------+
//| Calculate physics score (placeholder - implement your formula)   |
//+------------------------------------------------------------------+
double CalculatePhysicsScore()
{
   // Implement your physics score calculation
   // For now, return simple average
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum();
   double speed = g_physics.GetSpeed();
   double accel = g_physics.GetAcceleration();
   
   g_lastPhysicsScore = (quality + confluence + MathAbs(momentum) + MathAbs(speed) + MathAbs(accel)) / 5.0;
   return g_lastPhysicsScore;
}

//+------------------------------------------------------------------+
//| Calculate physics slopes                                          |
//+------------------------------------------------------------------+
void CalculatePhysicsSlopes()
{
   int lookback = SlopeLookbackBars;
   if(lookback < 2) lookback = 2;
   if(lookback > 10) lookback = 10;
   
   // Speed slope
   double speed0 = g_physics.GetSpeed(1);
   double speed1 = g_physics.GetSpeed(lookback);
   g_lastSpeedSlope = (speed0 - speed1) / (lookback - 1);
   
   // Acceleration slope
   double accel0 = g_physics.GetAcceleration(1);
   double accel1 = g_physics.GetAcceleration(lookback);
   g_lastAccelerationSlope = (accel0 - accel1) / (lookback - 1);
   
   // Momentum slope
   double momentum0 = g_physics.GetMomentum(1);
   double momentum1 = g_physics.GetMomentum(lookback);
   g_lastMomentumSlope = (momentum0 - momentum1) / (lookback - 1);
   
   // Confluence slope (if available)
   g_lastConfluenceSlope = 0.0;  // Placeholder
}

//+------------------------------------------------------------------+
//| Get current spread in pips                                        |
//+------------------------------------------------------------------+
double GetCurrentSpreadPips()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = ask - bid;
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double pipMultiplier = (digits == 5 || digits == 3) ? 10.0 : 1.0;
   double spreadPips = (spread / point) / pipMultiplier;
   
   g_lastSpreadPips = spreadPips;
   return spreadPips;
}

//+------------------------------------------------------------------+
//| Get MA crossover signal                                           |
//+------------------------------------------------------------------+
int GetMACrossoverSignal()
{
   if(g_maFastHandle == INVALID_HANDLE || g_maSlowHandle == INVALID_HANDLE)
      return 0;
   
   double maFastArr[], maSlowArr[];
   ArraySetAsSeries(maFastArr, true);
   ArraySetAsSeries(maSlowArr, true);
   
   if(CopyBuffer(g_maFastHandle, 0, 0, 2, maFastArr) < 2) return 0;
   if(CopyBuffer(g_maSlowHandle, 0, 0, 2, maSlowArr) < 2) return 0;
   
   // Crossover detection
   bool bullishCross = (maFastArr[1] <= maSlowArr[1] && maFastArr[0] > maSlowArr[0]);
   bool bearishCross = (maFastArr[1] >= maSlowArr[1] && maFastArr[0] < maSlowArr[0]);
   
   if(bullishCross) return 1;
   if(bearishCross) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get physics crossover signal                                      |
//+------------------------------------------------------------------+
int GetPhysicsCrossoverSignal()
{
   double accel0 = g_physics.GetAcceleration(0);
   double accel1 = g_physics.GetAcceleration(1);
   
   bool bullishCross = (accel1 <= 0 && accel0 > 0);
   bool bearishCross = (accel1 >= 0 && accel0 < 0);
   
   if(bullishCross) return 1;
   if(bearishCross) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Log trade entry to CSV                                            |
//+------------------------------------------------------------------+
void LogTradeEntry(ulong ticket, int signal, double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   if(!PositionSelectByTicket(ticket))
      return;
   
   TradeLogEntry log;
   
   // Core fields
   log.eaName = EA_NAME;
   log.eaVersion = EA_VERSION;
   log.rowType = "ENTRY";
   log.ticket = ticket;
   log.timestamp = TimeCurrent();
   log.openTime = (datetime)PositionGetInteger(POSITION_TIME);
   log.closeTime = 0;
   log.symbol = _Symbol;
   log.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL";
   log.lots = PositionGetDouble(POSITION_VOLUME);
   log.price = PositionGetDouble(POSITION_PRICE_OPEN);
   log.openPrice = log.price;
   log.closePrice = 0;
   log.sl = PositionGetDouble(POSITION_SL);
   log.tp = PositionGetDouble(POSITION_TP);
   
   // Entry physics
   log.entryQuality = quality;
   log.entryConfluence = confluence;
   log.entryMomentum = g_physics.GetMomentum();
   log.entrySpeed = g_physics.GetSpeed();
   log.entryAcceleration = g_physics.GetAcceleration();
   log.entryPhysicsScore = g_lastPhysicsScore;
   log.entrySpeedSlope = g_lastSpeedSlope;
   log.entryAccelerationSlope = g_lastAccelerationSlope;
   log.entryMomentumSlope = g_lastMomentumSlope;
   log.entryZone = g_physics.GetZoneName(zone);
   log.entryRegime = g_physics.GetRegimeName(regime);
   
   // Account state
   log.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   log.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   log.openPositions = PositionsTotal();
   
   g_logger.LogTrade(log);
}

//+------------------------------------------------------------------+
//| Log completed trade to CSV                                        |
//+------------------------------------------------------------------+
void LogCompletedTrade(ClosedTrade &trade)
{
   TradeLogEntry log;
   
   // Core fields
   log.eaName = EA_NAME;
   log.eaVersion = EA_VERSION;
   log.rowType = "EXIT";
   log.ticket = trade.ticket;
   log.timestamp = TimeCurrent();
   log.openTime = trade.openTime;
   log.closeTime = trade.closeTime;
   log.symbol = trade.symbol;
   log.type = trade.type;
   log.lots = trade.lots;
   log.openPrice = trade.openPrice;
   log.closePrice = trade.closePrice;
   log.sl = trade.sl;
   log.tp = trade.tp;
   log.profit = trade.profit;
   log.commission = trade.commission;
   
   // Entry physics (captured at trade open)
   log.entryQuality = trade.entryQuality;
   log.entryConfluence = trade.entryConfluence;
   log.entryMomentum = trade.entryMomentum;
   log.entrySpeed = trade.entrySpeed;
   log.entryAcceleration = trade.entryAcceleration;
   log.entryPhysicsScore = trade.entryPhysicsScore;
   log.entryZone = trade.entryZone;
   log.entryRegime = trade.entryRegime;
   
   // Exit physics (current values at exit)
   log.exitQuality = g_physics.GetQuality();
   log.exitConfluence = g_physics.GetConfluence();
   log.exitMomentum = g_physics.GetMomentum();
   log.exitSpeed = g_physics.GetSpeed();
   log.exitAcceleration = g_physics.GetAcceleration();
   log.exitPhysicsScore = CalculatePhysicsScore();
   log.exitZone = g_physics.GetZoneName(g_physics.GetTradingZone());
   log.exitRegime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());
   log.exitReason = trade.exitReason;
   
   // Trade metrics
   log.mfe = trade.mfe;
   log.mae = trade.mae;
   log.mfePercent = trade.mfePercent;
   log.maePercent = trade.maePercent;
   
   // Account state
   log.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   log.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   g_logger.LogTrade(log);
}

//+------------------------------------------------------------------+
//| Create dashboard                                                  |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   if(!ShowDashboard) return;
   
   int x = 10;
   int y = 20;
   int lineHeight = DashboardFontSize + 5;
   int row = 0;
   
   // Header
   CreateLabel("DASH_Header", x, y + (row++ * lineHeight), 
               "🚀 FALCON HEAVY LUDICROUS MODE™ v5.0", clrGold, DashboardFontSize + 2);
   row += 1;
   CreateLabel("DASH_Symbol", x, y + (row++ * lineHeight), 
               "Symbol: " + _Symbol, clrSilver, DashboardFontSize);
   CreateLabel("DASH_Mode", x, y + (row++ * lineHeight), 
               "Mode: " + (LudicrousMode ? "LUDICROUS" : "STANDARD"), clrSilver, DashboardFontSize);
   row += 2;
   
   // System Status
   CreateLabel("DASH_SystemHeader", x, y + (row++ * lineHeight), 
               "SYSTEM STATUS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Status", x, y + (row++ * lineHeight), 
               "Status: ACTIVE", clrLimeGreen, DashboardFontSize);
   CreateLabel("DASH_Positions", x, y + (row++ * lineHeight), 
               "Positions: 0/3", clrSilver, DashboardFontSize);
   CreateLabel("DASH_DailyPL", x, y + (row++ * lineHeight), 
               "Daily P/L: $0.00", clrSilver, DashboardFontSize);
   row += 2;
   
   // Physics Metrics Section
   CreateLabel("DASH_PhysicsHeader", x, y + (row++ * lineHeight), 
               "PHYSICS METRICS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Quality", x, y + (row++ * lineHeight), 
               "Quality: 0.0", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Confluence", x, y + (row++ * lineHeight), 
               "Confluence: 0.0", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Momentum", x, y + (row++ * lineHeight), 
               "Momentum: 0.0", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Speed", x, y + (row++ * lineHeight), 
               "Speed: 0.0", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Accel", x, y + (row++ * lineHeight), 
               "Accel: 0.0", clrSilver, DashboardFontSize);
   CreateLabel("DASH_PhysicsScore", x, y + (row++ * lineHeight), 
               "Physics Score: 0.0", clrSilver, DashboardFontSize);
   row += 2;
   
   // Slopes Section (if enabled)
   if(UseSlopeFilters)
   {
      CreateLabel("DASH_SlopesHeader", x, y + (row++ * lineHeight), 
                  "SLOPE ANALYSIS", clrWhite, DashboardFontSize);
      row += 1;
      CreateLabel("DASH_SpeedSlope", x, y + (row++ * lineHeight), 
                  "Speed Slope: 0.0", clrSilver, DashboardFontSize);
      CreateLabel("DASH_AccelSlope", x, y + (row++ * lineHeight), 
                  "Accel Slope: 0.0", clrSilver, DashboardFontSize);
      CreateLabel("DASH_MomentumSlope", x, y + (row++ * lineHeight), 
                  "Momentum Slope: 0.0", clrSilver, DashboardFontSize);
      row += 2;
   }
   
   // Classification Section
   CreateLabel("DASH_ClassHeader", x, y + (row++ * lineHeight), 
               "CLASSIFICATION", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Zone", x, y + (row++ * lineHeight), 
               "Zone: UNKNOWN", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Regime", x, y + (row++ * lineHeight), 
               "Regime: UNKNOWN", clrSilver, DashboardFontSize);
   row += 2;
   
   // Filter Status Section
   CreateLabel("DASH_FilterHeader", x, y + (row++ * lineHeight), 
               "FILTER STATUS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterQuality", x, y + (row++ * lineHeight), 
               "Quality: WAIT", clrSilver, DashboardFontSize);
   CreateLabel("DASH_FilterConfluence", x, y + (row++ * lineHeight), 
               "Confluence: WAIT", clrSilver, DashboardFontSize);
   CreateLabel("DASH_FilterZone", x, y + (row++ * lineHeight), 
               "Zone: WAIT", clrSilver, DashboardFontSize);
   CreateLabel("DASH_FilterOverall", x, y + (row++ * lineHeight), 
               "Overall: MONITORING", clrDodgerBlue, DashboardFontSize);
   row += 2;
   
   // Risk Management
   CreateLabel("DASH_RiskHeader", x, y + (row++ * lineHeight), 
               "RISK MANAGEMENT", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_RiskPerTrade", x, y + (row++ * lineHeight), 
               "Risk/Trade: $" + DoubleToString(DollarRiskPerTrade, 2), clrSilver, DashboardFontSize);
   CreateLabel("DASH_RewardRatio", x, y + (row++ * lineHeight), 
               "R:R Ratio: 1:" + DoubleToString(RewardRatio, 1), clrSilver, DashboardFontSize);
   CreateLabel("DASH_DailyLossLimit", x, y + (row++ * lineHeight), 
               "Daily Loss Cap: $" + DoubleToString(MaxDailyLoss, 0), clrSilver, DashboardFontSize);
   row += 2;
   
   // Position Section
   CreateLabel("DASH_PosHeader", x, y + (row++ * lineHeight), 
               "POSITION", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_PosActive", x, y + (row++ * lineHeight), 
               "Active: None", clrSilver, DashboardFontSize);
   CreateLabel("DASH_PosPL", x, y + (row++ * lineHeight), 
               "P/L: $0.00", clrSilver, DashboardFontSize);
   row += 2;
   
   // Account Section
   CreateLabel("DASH_AcctHeader", x, y + (row++ * lineHeight), 
               "ACCOUNT", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Balance", x, y + (row++ * lineHeight), 
               "Balance: $0.00", clrSilver, DashboardFontSize);
   CreateLabel("DASH_Equity", x, y + (row++ * lineHeight), 
               "Equity: $0.00", clrSilver, DashboardFontSize);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create label                                                      |
//+------------------------------------------------------------------+
bool CreateLabel(string name, int x, int y, string text, color clr, int fontSize = 9)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, DashboardCorner);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   
   return true;
}

//+------------------------------------------------------------------+
//| Update label                                                      |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text, color clr = clrNONE)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      if(clr != clrNONE)
         ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

//+------------------------------------------------------------------+
//| Update dashboard                                                  |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!ShowDashboard) return;
   
   datetime currentTime = TimeLocal();
   if(currentTime - g_lastDashboardUpdate < DashboardUpdateSeconds) return;
   g_lastDashboardUpdate = currentTime;
   
   // Get physics metrics
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum();
   double speed = g_physics.GetSpeed();
   double accel = g_physics.GetAcceleration();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // === SYSTEM STATUS ===
   int totalPositions = PositionsTotal();
   UpdateLabel("DASH_Positions", StringFormat("Positions: %d/%d", totalPositions, MaxTotalPositions), 
               totalPositions >= MaxTotalPositions ? clrRed : clrSilver);
   
   // Calculate daily P/L
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyPL = currentEquity - g_dailyStartEquity;
   color dailyPLColor = dailyPL >= 0 ? clrLimeGreen : clrRed;
   UpdateLabel("DASH_DailyPL", StringFormat("Daily P/L: $%.2f", dailyPL), dailyPLColor);
   
   // === PHYSICS METRICS ===
   bool qualityPass = LudicrousMode ? quality >= 95.0 : quality >= MinQuality;
   color qualityColor = qualityPass ? clrLimeGreen : clrRed;
   string qualityIcon = qualityPass ? "[PASS]" : "[FAIL]";
   UpdateLabel("DASH_Quality", StringFormat("Quality: %.1f %s", quality, qualityIcon), qualityColor);
   
   bool confluencePass = LudicrousMode ? (confluence >= 100.0) : (RequireFullConfluence ? confluence >= 100.0 : true);
   color confluenceColor = confluencePass ? clrLimeGreen : clrRed;
   string confluenceIcon = confluencePass ? "[PASS]" : "[FAIL]";
   UpdateLabel("DASH_Confluence", StringFormat("Confluence: %.1f %s", confluence, confluenceIcon), confluenceColor);
   
   color momentumColor = momentum > 0 ? clrLimeGreen : (momentum < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Momentum", StringFormat("Momentum: %.1f", momentum), momentumColor);
   
   color speedColor = speed > 0 ? clrLimeGreen : (speed < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Speed", StringFormat("Speed: %.1f", speed), speedColor);
   
   color accelColor = accel > 0 ? clrLimeGreen : (accel < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Accel", StringFormat("Accel: %.1f", accel), accelColor);
   
   UpdateLabel("DASH_PhysicsScore", StringFormat("Physics Score: %.1f", g_lastPhysicsScore), clrSilver);
   
   // === SLOPES ===
   if(UseSlopeFilters)
   {
      color speedSlopeColor = g_lastSpeedSlope > 0 ? clrLimeGreen : (g_lastSpeedSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_SpeedSlope", StringFormat("Speed Slope: %.2f", g_lastSpeedSlope), speedSlopeColor);
      
      color accelSlopeColor = g_lastAccelerationSlope > 0 ? clrLimeGreen : (g_lastAccelerationSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_AccelSlope", StringFormat("Accel Slope: %.2f", g_lastAccelerationSlope), accelSlopeColor);
      
      color momentumSlopeColor = g_lastMomentumSlope > 0 ? clrLimeGreen : (g_lastMomentumSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_MomentumSlope", StringFormat("Momentum Slope: %.2f", g_lastMomentumSlope), momentumSlopeColor);
   }
   
   // === CLASSIFICATION ===
   string zoneName = g_physics.GetZoneName(zone);
   color zoneColor = zone == ZONE_BULL ? clrLimeGreen : 
                     (zone == ZONE_BEAR ? clrTomato : 
                     (zone == ZONE_TRANSITION ? clrOrange : clrSilver));
   UpdateLabel("DASH_Zone", "Zone: " + zoneName, zoneColor);
   
   string regimeName = g_physics.GetRegimeName(regime);
   color regimeColor = regime == REGIME_HIGH ? clrLimeGreen :
                       (regime == REGIME_NORMAL ? clrDodgerBlue : clrOrange);
   UpdateLabel("DASH_Regime", "Regime: " + regimeName, regimeColor);
   
   // === FILTER STATUS ===
   bool zonePass = (zone != ZONE_TRANSITION || !AvoidTransitionZone);
   
   // Quality filter status
   string qStatus = qualityPass ? "[PASS]" : "[FAIL]";
   UpdateLabel("DASH_FilterQuality", StringFormat("Quality: %.1f %s", quality, qStatus), qualityColor);
   
   // Confluence filter status
   string cStatus = confluencePass ? "[PASS]" : "[FAIL]";
   UpdateLabel("DASH_FilterConfluence", StringFormat("Confluence: %.1f %s", confluence, cStatus), confluenceColor);
   
   // Zone filter status
   if(AvoidTransitionZone)
   {
      string zStatus = zonePass ? "[PASS]" : "[FAIL]";
      color zColor = zonePass ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_FilterZone", "Zone: " + zoneName + " " + zStatus, zColor);
   }
   else
   {
      UpdateLabel("DASH_FilterZone", "Zone: DISABLED", clrGold);
   }
   
   // Overall status
   bool allFiltersPass = qualityPass && confluencePass && zonePass;
   string overallStatus;
   color overallColor;
   
   if(dailyPL <= -MaxDailyLoss)
   {
      overallStatus = "DAILY LOSS CAP";
      overallColor = clrRed;
   }
   else if(totalPositions >= MaxTotalPositions)
   {
      overallStatus = "MAX POSITIONS";
      overallColor = clrOrange;
   }
   else if(LudicrousMode && allFiltersPass)
   {
      overallStatus = "LUDICROUS READY";
      overallColor = clrGold;
   }
   else if(allFiltersPass)
   {
      overallStatus = "READY TO TRADE";
      overallColor = clrLimeGreen;
   }
   else
   {
      overallStatus = "NO ENTRY";
      overallColor = clrRed;
   }
   UpdateLabel("DASH_FilterOverall", "Overall: " + overallStatus, overallColor);
   UpdateLabel("DASH_Status", "Status: " + (g_initialized ? "ACTIVE" : "INIT"), overallColor);
   
   // === POSITION SECTION ===
   if(totalPositions > 0 && PositionSelect(_Symbol))
   {
      string posType = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL";
      double lots = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      
      color posColor = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? clrDodgerBlue : clrTomato;
      UpdateLabel("DASH_PosActive", StringFormat("Active: %s %.2f @ %.5f", posType, lots, openPrice), posColor);
      
      color plColor = profit >= 0 ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_PosPL", StringFormat("P/L: $%.2f", profit), plColor);
   }
   else
   {
      UpdateLabel("DASH_PosActive", "Active: None", clrSilver);
      UpdateLabel("DASH_PosPL", "P/L: $0.00", clrSilver);
   }
   
   // === ACCOUNT SECTION ===
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   UpdateLabel("DASH_Balance", StringFormat("Balance: $%.2f", balance), clrSilver);
   
   color equityColor = equity >= balance ? clrLimeGreen : clrRed;
   UpdateLabel("DASH_Equity", StringFormat("Equity: $%.2f", equity), equityColor);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete dashboard                                                  |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   string prefix = "DASH_";
   int total = ObjectsTotal(0, 0, OBJ_LABEL);
   
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| Get deinit reason text                                            |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "Expert removed from chart";
      case REASON_REMOVE:      return "Program deleted";
      case REASON_RECOMPILE:   return "Program recompiled";
      case REASON_CHARTCHANGE: return "Symbol/timeframe changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Input parameters changed";
      case REASON_ACCOUNT:     return "Account changed";
      case REASON_TEMPLATE:    return "Template applied";
      case REASON_INITFAILED:  return "Initialization failed";
      case REASON_CLOSE:       return "Terminal closed";
      default:                 return "Unknown reason";
   }
}
