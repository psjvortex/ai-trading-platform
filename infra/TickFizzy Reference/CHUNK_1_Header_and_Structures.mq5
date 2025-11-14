//+------------------------------------------------------------------+
//|      TickPhysics_Crypto_SelfHealing_Crossover_EA_v5_0.mq5        |
//|    MA Crossover + Complete Physics Filters + Self-Healing        |
//|    Version 5.0 - PRODUCTION READY - Complete Integration         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "5.0"
#property strict

#include <Trade\Trade.mqh>

//============================= VERSION TRACKING =========================//
string EA_VERSION = "5.0_Complete";
string EA_NAME = "TickPhysics_Crossover_Complete";

//============================= CSV LOGGING ==============================//
input group "=== CSV LOGGING (Self-Healing) ==="
input bool InpEnableSignalLog = true;
input bool InpEnableTradeLog = true;
input string InpSignalLogFile = "TP_Crypto_Signals_Cross_v5_0.csv";
input string InpTradeLogFile = "TP_Crypto_Trades_Cross_v5_0.csv";

//============================= SELF-LEARNING ============================//
input group "=== Self-Learning System (v5.0) ==="
input bool InpEnableLearning = true;
input string InpLearningFile = "TP_Learning_Cross_v5_0.json";

//============================= INDICATOR SETTINGS =======================//
input group "=== TickPhysics Indicator ==="
input string InpIndicatorName = "TickPhysics_Crypto_Indicator_v2_1";

//============================= MA CROSSOVER BASELINE ====================//
input group "=== MA Crossover Baseline (Deterministic Entry/Exit) ==="
input bool InpUseMAEntry = true;              // Use MA crossover for entry
input int InpMAFast_Entry = 25;               // Fast MA for entry
input int InpMASlow_Entry = 100;              // Slow MA for entry
input bool InpUseMAExit = true;               // Use MA crossover for exit
input int InpMAFast_Exit = 25;                // Fast MA for exit
input int InpMASlow_Exit = 75;                // Slow MA for exit
input ENUM_MA_METHOD InpMAMethod = MODE_LWMA; // MA calculation method
input ENUM_APPLIED_PRICE InpMAPrice = PRICE_CLOSE; // MA applied price

//============================= RISK MANAGEMENT ==========================//
input group "=== Risk Management (v5.0 SAFE DEFAULTS) ==="
input double InpRiskPerTradePercent = 2.0;     // Risk per trade (% of equity) - SAFER!
input double InpStopLossPercent = 3.0;        // Stop Loss (% of PRICE)
input double InpTakeProfitPercent = 2.0;      // Take Profit (% of PRICE)
input double InpMoveToBEAtPercent = 1.5;      // Move to BE at (% profit)
input int InpMaxPositions = 1;
input int InpMaxConsecutiveLosses = 3;

//============================= ENTRY FILTERS ============================//
input group "=== Entry Filters (Self-Optimizing) ==="
input double InpMinTrendQuality = 70.0;
input double InpMinConfluence = 60.0;
input double InpMinMomentum = 50.0;
input bool InpRequireGreenZone = false;
input bool InpTradeOnlyNormalRegime = false;
input int InpDisallowAfterDivergence = 5;
input double InpMaxSpread = 50.0;              // Max spread - SAFER! (was 500)

//============================= ENTROPY FILTER ===========================//
input group "=== Entropy Filter (Chaos Detection) ==="
input bool InpUseEntropyFilter = false;        // Enable chaos detection
input double InpMaxEntropy = 2.5;             // Max allowed entropy

//============================= ADAPTIVE SL/TP ===========================//
input group "=== Adaptive SL/TP (ATR-based) ==="
input bool InpUseAdaptiveSLTP = false;         // ATR-based adjustment
input double InpATRMultiplierSL = 2.0;        // ATR multiplier for SL
input double InpATRMultiplierTP = 4.0;        // ATR multiplier for TP

//============================= DAILY GOVERNANCE =========================//
input group "=== Daily Governance ==="
input double InpDailyProfitTarget = 10.0;
input double InpDailyDrawdownLimit = 10.0;
input bool InpPauseOnLimits = true;           // SAFER! (was false)

//============================= SESSION TIMES ============================//
input group "=== Trading Hours ==="
input bool InpUseSessionFilter = false;
input string InpSessionStart = "00:00";
input string InpSessionEnd = "23:59";

//============================= PHYSICS & SELF-HEALING ===================//
input group "=== Physics & Self-Healing (Toggle for Controlled QA) ==="
input bool InpUsePhysics = false;             // Enable physics filters
input bool InpUseSelfHealing = false;         // Enable self-healing optimization
input bool InpUseTickPhysicsIndicator = false; // Use TickPhysics indicator signals

//============================= CHART DISPLAY ============================//
input group "=== Chart Display ==="
input bool InpShowMALines = true;             // Show MA lines on chart
input color InpColorFastEntry = clrBlue;      // Fast Entry MA color (Blue)
input color InpColorSlowEntry = clrYellow;    // Slow Entry MA color (Yellow)
input color InpColorExit = clrWhite;          // Exit MA color (White)
input int InpMALineWidth = 2;                 // MA line width

//============================= GLOBAL VARIABLES =========================//
CTrade trade;
int indicatorHandle = INVALID_HANDLE;
datetime lastBarTime = 0;
datetime lastSignalLogTime = 0;

// MA handles for baseline crossover
int maFastEntry_Handle = INVALID_HANDLE;
int maSlowEntry_Handle = INVALID_HANDLE;
int maFastExit_Handle = INVALID_HANDLE;
int maSlowExit_Handle = INVALID_HANDLE;

// Chart window for MA display
int chartWindow = 0;

// Custom MA drawing buffers (for visual overlay)
bool useCustomMADrawing = true;

// Daily tracking
double dailyStartBalance = 0;
int dailyTradeCount = 0;
int consecutiveLosses = 0;
bool dailyPaused = false;
datetime lastDayCheck = 0;

// CSV handles
int signalLogHandle = INVALID_HANDLE;
int tradeLogHandle = INVALID_HANDLE;

// Watchdog
datetime lastTickTime = 0;

//============================= v5.0: TRADE TRACKER =======================//
// NEW v5.0: Comprehensive trade tracking structure
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

//============================= v5.0: LEARNING STRUCTURE =================//
// NEW v5.0: Complete JSON learning structure
struct LearningParameters
{
   // Current optimized parameters
   double MinTrendQuality;
   double MinConfluence;
   double MinMomentum;
   double StopLossPercent;
   double TakeProfitPercent;
   double RiskPerTradePercent;
   
   // Performance metrics
   int totalTrades;
   double winRate;
   double profitFactor;
   double sharpeRatio;
   double maxDrawdown;
   double avgWin;
   double avgLoss;
   double avgRRatio;
   
   // Recommendations
   string adjustQuality;
   string adjustConfluence;
   string adjustSL;
   string adjustTP;
   string adjustRisk;
   string reason;
   
   // Metadata
   datetime lastUpdate;
   string version;
   int learningCycle;
};

LearningParameters learningData;

// Indicator buffer indices
#define BUFFER_SPEED 0
#define BUFFER_ACCEL 1
#define BUFFER_ACCEL_COLOR 2
#define BUFFER_MOMENTUM 3
#define BUFFER_QUALITY 4
#define BUFFER_QUALITY_COLOR 5
#define BUFFER_DISTANCE_ROC 6
#define BUFFER_JERK 7
#define BUFFER_HIGH_THRESHOLD 8
#define BUFFER_LOW_THRESHOLD 9
#define BUFFER_ZERO_LINE 10
#define BUFFER_QUALITY_GLOW 11
#define BUFFER_MOM_SPIKE 12
#define BUFFER_MOM_SPIKE_COLOR 13
#define BUFFER_CONFLUENCE 14
#define BUFFER_CONFLUENCE_COLOR 15
#define BUFFER_VOL_REGIME 16
#define BUFFER_VOL_REGIME_COLOR 17
#define BUFFER_DIVERGENCE 18
#define BUFFER_DIVERGENCE_COLOR 19
#define BUFFER_TRADING_ZONE 20
#define BUFFER_ZONE_COLOR 21
#define BUFFER_ENTROPY 22

//============================= END OF CHUNK 1 ===========================//
// NEXT: Copy Chunk 2 (Core calculation functions)
