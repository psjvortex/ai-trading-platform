//+------------------------------------------------------------------+
//|      TickPhysics_Crypto_SelfHealing_Crossover_EA_v5_5.mq5        |
//|    MA Crossover + Complete Physics Filters + Self-Healing        |
//|    Version 5.5 - CRITICAL FIXES FOR MISSED TRADES & REVERSALS    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "5.5"
#property strict

#include <Trade\Trade.mqh>

//============================= VERSION TRACKING =========================//
string EA_VERSION = "5.5_CriticalFixes";
string EA_NAME = "TickPhysics_Crossover_Complete";

//============================= v5.5 CHANGELOG ===========================//
// CRITICAL FIXES:
// 1. Fixed execution order: ManagePositions() now runs BEFORE entry logic
// 2. Added comprehensive debug logging for all trade decisions
// 3. Fixed reverse entry logic after exit signals
// 4. Added position count verification before each trade attempt
// 5. Split entry conditions with explicit rejection logging
//========================================================================//

//============================= CSV LOGGING ==============================//
input group "=== CSV LOGGING (Self-Healing) ==="
input bool InpEnableSignalLog = true;
input bool InpEnableTradeLog = true;
input string InpSignalLogFile = "TP_Crypto_Signals_Cross_v5_5.csv";
input string InpTradeLogFile = "TP_Crypto_Trades_Cross_v5_5.csv";

//============================= SELF-LEARNING ============================//
input group "=== Self-Learning System (v5.5) ==="
input bool InpEnableLearning = true;
input string InpLearningFile = "TP_Learning_Cross_v5_5.json";

//============================= INDICATOR SETTINGS =======================//
input group "=== TickPhysics Indicator ==="
input string InpIndicatorName = "TickPhysics_Crypto_Indicator_v2_1";

//============================= MA CROSSOVER BASELINE ====================//
input group "=== MA Crossover Baseline (Deterministic Entry/Exit) ==="
input bool InpUseMAEntry = true;              // Use MA crossover for entry
input int InpMAFast_Entry = 10;               // Fast MA for entry
input int InpMASlow_Entry = 30;              // Slow MA for entry
input bool InpUseMAExit = true;               // Use MA crossover for exit
input int InpMAFast_Exit = 10;                // Fast MA for exit
input int InpMASlow_Exit = 25;                // Slow MA for exit
input ENUM_MA_METHOD InpMAMethod = MODE_EMA; // MA calculation method
input ENUM_APPLIED_PRICE InpMAPrice = PRICE_CLOSE; // MA applied price

//============================= RISK MANAGEMENT ==========================//
input group "=== Risk Management (v5.0 SAFE DEFAULTS) ==="
input double InpRiskPerTradePercent = 2.0;     // Risk per trade (% of equity) - SAFER!
input double InpStopLossPercent = 3.0;        // Stop Loss (% of PRICE)
input double InpTakeProfitPercent = 2.0;      // Take Profit (% of PRICE)
input double InpMoveToBEAtPercent = 1.0;      // Move to BE at (% profit)
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
input double InpMaxSpread = 500.0;              // Max spread - SAFER! (was 500)

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
input bool InpPauseOnLimits = false;          

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

//============================= DEBUG MODE (v5.5) ========================//
input group "=== Debug Mode (v5.5 - Comprehensive Logging) ==="
input bool InpEnableDebug = true;             // Enable debug logging for testing

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
//============================= CHUNK 2: CORE FUNCTIONS ==================//
// ADD THIS AFTER CHUNK 1
//========================================================================//

//============================= ROBUST POINT VALUE =======================//
double GetPointMoneyValue()
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Primary method: tickValue and tickSize
   if(tickSize > 0.0 && tickValue > 0.0)
   {
      return tickValue * (point / tickSize);
   }
   
   // Fallback 1: contract size * point
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize > 0.0 && point > 0.0)
   {
      return contractSize * point;
   }
   
   // Fallback 2: price * point (last resort)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = (ask > 0 ? ask : (bid > 0 ? bid : 1.0));
   double approx = price * point;
   if(approx > 0.0) return approx;
   
   // Last resort: failure
   Print("ERROR: GetPointMoneyValue() - Cannot determine point value!");
   return 0.0;
}

//============================= FIXED SL/TP CALCULATION ==================//
bool ComputeSLTPFromPercent(double price, ENUM_ORDER_TYPE orderType, 
                           double stopPercent, double tpPercent,
                           double &out_sl, double &out_tp)
{
   // Use % of PRICE, not equity!
   double slDistance = price * stopPercent / 100.0;
   double tpDistance = price * tpPercent / 100.0;
   
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   // Calculate SL/TP prices
   if(orderType == ORDER_TYPE_BUY)
   {
      out_sl = NormalizeDouble(price - slDistance, digits);
      out_tp = NormalizeDouble(price + tpDistance, digits);
   }
   else
   {
      out_sl = NormalizeDouble(price + slDistance, digits);
      out_tp = NormalizeDouble(price - tpDistance, digits);
   }
   
   // Validate
   if(out_sl <= 0 || out_tp <= 0)
   {
      Print("ERROR: Invalid SL/TP: sl=", out_sl, " tp=", out_tp);
      return false;
   }
   
   return true;
}

//============================= LOT SIZE CALCULATION =====================//
double CalculateLotSize(double riskMoney, double slDistance)
{
   if(slDistance <= 0)
   {
      Print("ERROR: Invalid SL distance: ", slDistance);
      return 0;
   }
   
   double pointMoneyValue = GetPointMoneyValue();
   if(pointMoneyValue <= 0)
   {
      Print("ERROR: Cannot calculate lot size - point value is 0");
      return 0;
   }
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0)
   {
      Print("ERROR: Invalid point size");
      return 0;
   }
   
   double slDistancePoints = slDistance / point;
   if(slDistancePoints <= 0)
   {
      Print("ERROR: SL distance in points is 0");
      return 0;
   }
   
   double lots = riskMoney / (slDistancePoints * pointMoneyValue);
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = NormalizeDouble(lots, 2);
   
   if(lots < minLot)
      lots = minLot;
   
   return lots;
}

//========================================================================//
//========================= v5.0: PHYSICS FILTERS ========================//
//========================================================================//
// *** CRITICAL FIX v5.0: This function now ACTUALLY USED for entries ***
//========================================================================//

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
   
   // All filters passed!
   rejectReason = "PASS";
   Print("✅ Physics Filter PASS: Quality=", quality, " Confluence=", confluence, 
         " Zone=", zone, " Regime=", regime, " Entropy=", entropy);
   return true;
}

//========================================================================//
//========================= v5.0: SPREAD FILTER ==========================//
//========================================================================//

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

//============================= END OF CHUNK 2 ===========================//
// NEXT: Copy Chunk 3 (JSON learning functions)
//============================= CHUNK 3: JSON LEARNING ===================//
// ADD THIS AFTER CHUNK 2
//========================================================================//

//========================================================================//
//===================== v5.0: JSON LEARNING FUNCTIONS ====================//
//========================================================================//

// Simple JSON value extractor
double ExtractJSONValue(string content, string key)
{
   string searchKey = "\"" + key + "\":";
   int pos = StringFind(content, searchKey);
   if(pos < 0) return 0.0;
   
   pos += StringLen(searchKey);
   
   // Skip whitespace
   while(pos < StringLen(content) && (StringGetCharacter(content, pos) == ' ' || 
         StringGetCharacter(content, pos) == '\t' || StringGetCharacter(content, pos) == '\n'))
      pos++;
   
   // Extract number
   string valueStr = "";
   while(pos < StringLen(content))
   {
      ushort ch = StringGetCharacter(content, pos);
      if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == 'e' || ch == 'E' || ch == '+')
         valueStr += ShortToString(ch);
      else
         break;
      pos++;
   }
   
   return StringToDouble(valueStr);
}

string ExtractJSONString(string content, string key)
{
   string searchKey = "\"" + key + "\":\"";
   int pos = StringFind(content, searchKey);
   if(pos < 0) return "";
   
   pos += StringLen(searchKey);
   
   string value = "";
   while(pos < StringLen(content))
   {
      ushort ch = StringGetCharacter(content, pos);
      if(ch == '"') break;  // End of string
      value += ShortToString(ch);
      pos++;
   }
   
   return value;
}

//+------------------------------------------------------------------+
//| Load learning data from JSON                                     |
//+------------------------------------------------------------------+
bool LoadLearningData()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled in settings");
      return false;
   }
   
   int handle = FileOpen(InpLearningFile, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("No existing learning file found - will create new one");
      return false;
   }
   
   string content = "";
   while(!FileIsEnding(handle))
   {
      content += FileReadString(handle);
   }
   FileClose(handle);
   
   if(StringLen(content) < 10)
   {
      Print("Learning file empty or corrupted");
      return false;
   }
   
   // Extract parameters
   learningData.MinTrendQuality = ExtractJSONValue(content, "MinTrendQuality");
   learningData.MinConfluence = ExtractJSONValue(content, "MinConfluence");
   learningData.MinMomentum = ExtractJSONValue(content, "MinMomentum");
   learningData.StopLossPercent = ExtractJSONValue(content, "StopLossPercent");
   learningData.TakeProfitPercent = ExtractJSONValue(content, "TakeProfitPercent");
   learningData.RiskPerTradePercent = ExtractJSONValue(content, "RiskPerTradePercent");
   
   // Extract performance metrics
   learningData.totalTrades = (int)ExtractJSONValue(content, "totalTrades");
   learningData.winRate = ExtractJSONValue(content, "winRate");
   learningData.profitFactor = ExtractJSONValue(content, "profitFactor");
   learningData.maxDrawdown = ExtractJSONValue(content, "maxDrawdown");
   
   // Extract metadata
   learningData.version = ExtractJSONString(content, "version");
   learningData.learningCycle = (int)ExtractJSONValue(content, "learningCycle");
   
   Print("✅ Learning data loaded: Trades=", learningData.totalTrades, 
         " WinRate=", learningData.winRate, "% Cycle=", learningData.learningCycle);
   
   return true;
}

//+------------------------------------------------------------------+
//| Save learning data to JSON                                       |
//+------------------------------------------------------------------+
bool SaveLearningData()
{
   if(!InpEnableLearning) return false;
   
   int handle = FileOpen(InpLearningFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot create learning file: ", InpLearningFile);
      return false;
   }
   
   // Write JSON structure
   FileWriteString(handle, "{\n");
   FileWriteString(handle, "  \"version\": \"" + learningData.version + "\",\n");
   FileWriteString(handle, "  \"lastUpdate\": \"" + TimeToString(TimeCurrent()) + "\",\n");
   FileWriteString(handle, "  \"learningCycle\": " + IntegerToString(learningData.learningCycle) + ",\n");
   FileWriteString(handle, "  \"totalTrades\": " + IntegerToString(learningData.totalTrades) + ",\n");
   FileWriteString(handle, "  \"parameters\": {\n");
   FileWriteString(handle, "    \"MinTrendQuality\": " + DoubleToString(learningData.MinTrendQuality, 1) + ",\n");
   FileWriteString(handle, "    \"MinConfluence\": " + DoubleToString(learningData.MinConfluence, 1) + ",\n");
   FileWriteString(handle, "    \"MinMomentum\": " + DoubleToString(learningData.MinMomentum, 1) + ",\n");
   FileWriteString(handle, "    \"StopLossPercent\": " + DoubleToString(learningData.StopLossPercent, 1) + ",\n");
   FileWriteString(handle, "    \"TakeProfitPercent\": " + DoubleToString(learningData.TakeProfitPercent, 1) + ",\n");
   FileWriteString(handle, "    \"RiskPerTradePercent\": " + DoubleToString(learningData.RiskPerTradePercent, 1) + "\n");
   FileWriteString(handle, "  },\n");
   FileWriteString(handle, "  \"performance\": {\n");
   FileWriteString(handle, "    \"winRate\": " + DoubleToString(learningData.winRate, 2) + ",\n");
   FileWriteString(handle, "    \"profitFactor\": " + DoubleToString(learningData.profitFactor, 2) + ",\n");
   FileWriteString(handle, "    \"sharpeRatio\": " + DoubleToString(learningData.sharpeRatio, 2) + ",\n");
   FileWriteString(handle, "    \"maxDrawdown\": " + DoubleToString(learningData.maxDrawdown, 2) + ",\n");
   FileWriteString(handle, "    \"avgWin\": " + DoubleToString(learningData.avgWin, 2) + ",\n");
   FileWriteString(handle, "    \"avgLoss\": " + DoubleToString(learningData.avgLoss, 2) + ",\n");
   FileWriteString(handle, "    \"avgRRatio\": " + DoubleToString(learningData.avgRRatio, 2) + "\n");
   FileWriteString(handle, "  },\n");
   FileWriteString(handle, "  \"recommendations\": {\n");
   FileWriteString(handle, "    \"adjustQuality\": \"" + learningData.adjustQuality + "\",\n");
   FileWriteString(handle, "    \"adjustConfluence\": \"" + learningData.adjustConfluence + "\",\n");
   FileWriteString(handle, "    \"adjustSL\": \"" + learningData.adjustSL + "\",\n");
   FileWriteString(handle, "    \"adjustTP\": \"" + learningData.adjustTP + "\",\n");
   FileWriteString(handle, "    \"adjustRisk\": \"" + learningData.adjustRisk + "\",\n");
   FileWriteString(handle, "    \"reason\": \"" + learningData.reason + "\"\n");
   FileWriteString(handle, "  }\n");
   FileWriteString(handle, "}\n");
   
   FileClose(handle);
   
   Print("✅ Learning data saved: Cycle=", learningData.learningCycle);
   return true;
}

//+------------------------------------------------------------------+
//| Analyze performance from CSV                                     |
//+------------------------------------------------------------------+
bool AnalyzePerformance()
{
   if(!InpEnableTradeLog)
   {
      Print("Trade logging disabled - cannot analyze performance");
      return false;
   }
   
   int handle = FileOpen(InpTradeLogFile, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("Cannot open trade log file for analysis");
      return false;
   }
   
   // Skip header
   string header = FileReadString(handle);
   
   int totalTrades = 0;
   int wins = 0;
   double totalProfit = 0;
   double totalLoss = 0;
   double sumWins = 0;
   double sumLosses = 0;
   double maxDD = 0;
   double runningBalance = 0;
   double peak = 0;
   
   // Read all trades
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(StringLen(line) < 10) continue;
      
      // Parse CSV line - profit is column 20 (index 19)
      string parts[];
      int count = StringSplit(line, ',', parts);
      
      if(count < 20) continue;
      
      double profit = StringToDouble(parts[19]);
      totalTrades++;
      
      if(profit > 0)
      {
         wins++;
         sumWins += profit;
         totalProfit += profit;
      }
      else if(profit < 0)
      {
         sumLosses += MathAbs(profit);
         totalLoss += profit;
      }
      
      // Track drawdown
      runningBalance += profit;
      if(runningBalance > peak)
         peak = runningBalance;
      
      double dd = peak - runningBalance;
      if(dd > maxDD)
         maxDD = dd;
   }
   
   FileClose(handle);
   
   if(totalTrades < 5)
   {
      Print("Not enough trades for analysis: ", totalTrades);
      return false;
   }
   
   // Calculate metrics
   learningData.totalTrades = totalTrades;
   learningData.winRate = (totalTrades > 0) ? (wins * 100.0 / totalTrades) : 0;
   learningData.profitFactor = (sumLosses > 0) ? (sumWins / sumLosses) : 0;
   learningData.avgWin = (wins > 0) ? (sumWins / wins) : 0;
   learningData.avgLoss = ((totalTrades - wins) > 0) ? (sumLosses / (totalTrades - wins)) : 0;
   learningData.maxDrawdown = maxDD;
   learningData.avgRRatio = (learningData.avgLoss != 0) ? (learningData.avgWin / learningData.avgLoss) : 0;
   
   // Calculate Sharpe (simplified)
   double avgProfit = (totalProfit + totalLoss) / totalTrades;
   learningData.sharpeRatio = (avgProfit > 0 && totalTrades > 1) ? (avgProfit / MathSqrt(totalTrades)) : 0;
   
   Print("📊 Performance Analysis:");
   Print("   Total Trades: ", totalTrades);
   Print("   Win Rate: ", learningData.winRate, "%");
   Print("   Profit Factor: ", learningData.profitFactor);
   Print("   Avg Win: ", learningData.avgWin);
   Print("   Avg Loss: ", learningData.avgLoss);
   Print("   Max DD: ", learningData.maxDrawdown);
   Print("   R:R Ratio: ", learningData.avgRRatio);
   
   return true;
}

//============================= END OF CHUNK 3 ===========================//
// NEXT: Copy Chunk 4 (More JSON functions + logging functions)
//============================= CHUNK 4: JSON PART 2 & TRACKING ==========//
// ADD THIS AFTER CHUNK 3
//========================================================================//

//+------------------------------------------------------------------+
//| Optimize parameters based on performance                         |
//+------------------------------------------------------------------+
void OptimizeParameters()
{
   // Reset recommendations
   learningData.adjustQuality = "0";
   learningData.adjustConfluence = "0";
   learningData.adjustSL = "0";
   learningData.adjustTP = "0";
   learningData.adjustRisk = "0";
   learningData.reason = "";
   
   // Decision logic based on win rate
   if(learningData.winRate < 45.0)
   {
      // Poor performance - loosen filters
      learningData.adjustQuality = "-5";
      learningData.adjustConfluence = "-5";
      learningData.reason = "WinRate<45%: Loosening filters to find edge";
      Print("💡 Low win rate - recommending looser filters");
   }
   else if(learningData.winRate >= 45.0 && learningData.winRate < 55.0)
   {
      // Baseline - no change
      learningData.reason = "WinRate 45-55%: Testing current parameters";
      Print("💡 Baseline performance - no adjustments");
   }
   else if(learningData.winRate >= 55.0 && learningData.winRate < 65.0)
   {
      // Good - tighten slightly
      learningData.adjustQuality = "+5";
      learningData.reason = "WinRate 55-65%: Tightening slightly to improve quality";
      Print("💡 Good performance - recommending slight tightening");
   }
   else if(learningData.winRate >= 65.0)
   {
      // Excellent - tighten more
      learningData.adjustQuality = "+10";
      learningData.adjustConfluence = "+5";
      learningData.reason = "WinRate>65%: Excellent! Tightening filters for max quality";
      Print("💡 Excellent performance - recommending tighter filters");
   }
   
   // Adjust based on profit factor
   if(learningData.profitFactor < 1.2)
   {
      learningData.adjustTP = "+0.5";
      learningData.reason += " | PF<1.2: Widening TP";
   }
   
   // Adjust based on drawdown
   if(learningData.maxDrawdown > 15.0)
   {
      learningData.adjustSL = "-0.5";
      learningData.adjustRisk = "-0.5";
      learningData.reason += " | DD>15%: Tightening risk";
   }
}

//+------------------------------------------------------------------+
//| Apply optimized parameters                                       |
//+------------------------------------------------------------------+
void ApplyOptimizedParameters()
{
   // NOTE: In MQL5, we cannot directly modify input parameters at runtime
   // So we store the recommendations in the JSON file for manual application
   
   // Apply Quality adjustment
   double qualityAdj = StringToDouble(learningData.adjustQuality);
   if(qualityAdj != 0)
   {
      double newQuality = InpMinTrendQuality + qualityAdj;
      newQuality = MathMax(50.0, MathMin(90.0, newQuality));
      
      if(newQuality != InpMinTrendQuality)
      {
         Print("📈 Adjusting MinTrendQuality: ", InpMinTrendQuality, " → ", newQuality);
         learningData.MinTrendQuality = newQuality;
      }
   }
   
   // Apply Confluence adjustment
   double confluenceAdj = StringToDouble(learningData.adjustConfluence);
   if(confluenceAdj != 0)
   {
      double newConfluence = InpMinConfluence + confluenceAdj;
      newConfluence = MathMax(40.0, MathMin(80.0, newConfluence));
      
      if(newConfluence != InpMinConfluence)
      {
         Print("📈 Adjusting MinConfluence: ", InpMinConfluence, " → ", newConfluence);
         learningData.MinConfluence = newConfluence;
      }
   }
   
   // Apply SL adjustment
   double slAdj = StringToDouble(learningData.adjustSL);
   if(slAdj != 0)
   {
      double newSL = InpStopLossPercent + slAdj;
      newSL = MathMax(2.0, MathMin(5.0, newSL));
      
      if(newSL != InpStopLossPercent)
      {
         Print("📈 Adjusting StopLossPercent: ", InpStopLossPercent, " → ", newSL);
         learningData.StopLossPercent = newSL;
      }
   }
   
   // Apply TP adjustment
   double tpAdj = StringToDouble(learningData.adjustTP);
   if(tpAdj != 0)
   {
      double newTP = InpTakeProfitPercent + tpAdj;
      newTP = MathMax(1.0, MathMin(4.0, newTP));
      
      if(newTP != InpTakeProfitPercent)
      {
         Print("📈 Adjusting TakeProfitPercent: ", InpTakeProfitPercent, " → ", newTP);
         learningData.TakeProfitPercent = newTP;
      }
   }
   
   // Apply Risk adjustment
   double riskAdj = StringToDouble(learningData.adjustRisk);
   if(riskAdj != 0)
   {
      double newRisk = InpRiskPerTradePercent + riskAdj;
      newRisk = MathMax(0.5, MathMin(5.0, newRisk));
      
      if(newRisk != InpRiskPerTradePercent)
      {
         Print("📈 Adjusting RiskPerTradePercent: ", InpRiskPerTradePercent, " → ", newRisk);
         learningData.RiskPerTradePercent = newRisk;
      }
   }
   
   Print("💡 RECOMMENDED ADJUSTMENTS:");
   Print("   Quality: ", InpMinTrendQuality, " → ", learningData.MinTrendQuality);
   Print("   Confluence: ", InpMinConfluence, " → ", learningData.MinConfluence);
   Print("   Stop Loss: ", InpStopLossPercent, " → ", learningData.StopLossPercent);
   Print("   Take Profit: ", InpTakeProfitPercent, " → ", learningData.TakeProfitPercent);
   Print("   Risk: ", InpRiskPerTradePercent, " → ", learningData.RiskPerTradePercent);
   Print("   Reason: ", learningData.reason);
}

//+------------------------------------------------------------------+
//| Run learning cycle                                               |
//+------------------------------------------------------------------+
void RunLearningCycle()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled");
      return;
   }
   
   Print("🧠 ========== LEARNING CYCLE START ==========");
   
   // 1. Analyze recent performance
   if(!AnalyzePerformance())
   {
      Print("❌ Learning cycle aborted - analysis failed");
      return;
   }
   
   // 2. Determine optimal adjustments
   OptimizeParameters();
   
   // 3. Apply adjustments (store recommendations)
   ApplyOptimizedParameters();
   
   // 4. Save learning data
   learningData.version = EA_VERSION;
   learningData.lastUpdate = TimeCurrent();
   learningData.learningCycle++;
   
   if(!SaveLearningData())
   {
      Print("❌ Failed to save learning data");
      return;
   }
   
   Print("🧠 ========== LEARNING CYCLE COMPLETE ==========");
   Print("📊 Next cycle after 20 more trades");
}

//+------------------------------------------------------------------+
//| Initialize learning system                                       |
//+------------------------------------------------------------------+
bool InitLearningSystem()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled in EA settings");
      return true;
   }
   
   // Try to load existing learning data
   if(LoadLearningData())
   {
      Print("✅ Continuing from learning cycle ", learningData.learningCycle);
      Print("   Current parameters will be used for next ", 20 - (learningData.totalTrades % 20), " trades");
      return true;
   }
   
   // No existing data - initialize with current EA settings
   learningData.MinTrendQuality = InpMinTrendQuality;
   learningData.MinConfluence = InpMinConfluence;
   learningData.MinMomentum = InpMinMomentum;
   learningData.StopLossPercent = InpStopLossPercent;
   learningData.TakeProfitPercent = InpTakeProfitPercent;
   learningData.RiskPerTradePercent = InpRiskPerTradePercent;
   learningData.totalTrades = 0;
   learningData.learningCycle = 0;
   learningData.version = EA_VERSION;
   
   Print("✅ Learning system initialized - starting baseline data collection");
   return true;
}

//+------------------------------------------------------------------+
//| Check if learning trigger should fire                            |
//+------------------------------------------------------------------+
void CheckLearningTrigger()
{
   if(!InpEnableLearning) return;
   
   // Count closed trades
   static int lastTradeCount = 0;
   int currentTradeCount = 0;
   
   // Count trades from CSV
   int handle = FileOpen(InpTradeLogFile, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(handle != INVALID_HANDLE)
   {
      while(!FileIsEnding(handle))
      {
         string line = FileReadString(handle);
         if(StringFind(line, "CLOSE") >= 0)
            currentTradeCount++;
      }
      FileClose(handle);
   }
   
   // Trigger learning every 20 trades
   if(currentTradeCount >= lastTradeCount + 20 && currentTradeCount >= 20)
   {
      Print("🔔 Learning trigger: ", currentTradeCount, " trades completed");
      RunLearningCycle();
      lastTradeCount = currentTradeCount;
   }
}

//========================================================================//
//=================== v5.0: TRACK NEW TRADE ==============================//
//========================================================================//

void TrackNewTrade(ulong ticket, double quality, double confluence, double zone,
                   double regime, double entropy)
{
   if(ticket == 0) return;
   
   // Select the position
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Cannot select position for tracking: ", ticket);
      return;
   }
   
   // Create new tracker
   int size = ArraySize(currentTrades);
   ArrayResize(currentTrades, size + 1);
   
   // Fill tracker data
   currentTrades[size].ticket = ticket;
   currentTrades[size].openTime = (datetime)PositionGetInteger(POSITION_TIME);
   currentTrades[size].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   currentTrades[size].sl = PositionGetDouble(POSITION_SL);
   currentTrades[size].tp = PositionGetDouble(POSITION_TP);
   currentTrades[size].lots = PositionGetDouble(POSITION_VOLUME);
   currentTrades[size].type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
   
   // Store entry conditions
   currentTrades[size].entryQuality = quality;
   currentTrades[size].entryConfluence = confluence;
   currentTrades[size].entryZone = zone;
   currentTrades[size].entryRegime = regime;
   currentTrades[size].entryEntropy = entropy;
   
   // Get MA values
   double maFast[1], maSlow[1];
   CopyBuffer(maFastEntry_Handle, 0, 0, 1, maFast);
   CopyBuffer(maSlowEntry_Handle, 0, 0, 1, maSlow);
   currentTrades[size].entryMAFast = maFast[0];
   currentTrades[size].entryMASlow = maSlow[0];
   
   // Get spread
   double spread = 0;
   CheckSpreadFilter(spread);
   currentTrades[size].entrySpread = spread;
   
   // Initialize MFE/MAE
   currentTrades[size].mfe = currentTrades[size].openPrice;
   currentTrades[size].mae = currentTrades[size].openPrice;
   
   Print("✅ Trade tracked: #", ticket, " Quality=", quality, " Confluence=", confluence);
}

//========================================================================//
//=================== v5.0: UPDATE MFE/MAE ===============================//
//========================================================================//

void UpdateMFEMAE()
{
   for(int i = 0; i < ArraySize(currentTrades); i++)
   {
      if(!PositionSelectByTicket(currentTrades[i].ticket))
         continue;
      
      double currentPrice = (currentTrades[i].type == ORDER_TYPE_BUY) ?
         SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(currentTrades[i].type == ORDER_TYPE_BUY)
      {
         // For BUY: MFE = highest price, MAE = lowest price
         if(currentPrice > currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice < currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
      else  // SELL
      {
         // For SELL: MFE = lowest price, MAE = highest price
         if(currentPrice < currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice > currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
   }
}

//============================= END OF CHUNK 4 ===========================//
// NEXT: Copy Chunk 5 (LogTradeClose and LogSignal functions)
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
   
   // Calculate metrics (access struct directly, no pointers in MQL5)
   
   double profitPercent = (profit / AccountInfoDouble(ACCOUNT_EQUITY)) * 100.0;
   
   double pips = 0;
   if(currentTrades[trackerIndex].type == ORDER_TYPE_BUY)
      pips = (exitPrice - currentTrades[trackerIndex].openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   else
      pips = (currentTrades[trackerIndex].openPrice - exitPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   
   int holdTimeBars = (int)((exitTime - currentTrades[trackerIndex].openTime) / PeriodSeconds(_Period));
   
   // Calculate MFE/MAE percentages
   double mfePercent = 0, maePercent = 0, mfePips = 0, maePips = 0;
   if(currentTrades[trackerIndex].type == ORDER_TYPE_BUY)
   {
      mfePercent = ((currentTrades[trackerIndex].mfe - currentTrades[trackerIndex].openPrice) / currentTrades[trackerIndex].openPrice) * 100.0;
      maePercent = ((currentTrades[trackerIndex].mae - currentTrades[trackerIndex].openPrice) / currentTrades[trackerIndex].openPrice) * 100.0;
      mfePips = (currentTrades[trackerIndex].mfe - currentTrades[trackerIndex].openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
      maePips = (currentTrades[trackerIndex].mae - currentTrades[trackerIndex].openPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   }
   else
   {
      mfePercent = ((currentTrades[trackerIndex].openPrice - currentTrades[trackerIndex].mfe) / currentTrades[trackerIndex].openPrice) * 100.0;
      maePercent = ((currentTrades[trackerIndex].openPrice - currentTrades[trackerIndex].mae) / currentTrades[trackerIndex].openPrice) * 100.0;
      mfePips = (currentTrades[trackerIndex].openPrice - currentTrades[trackerIndex].mfe) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
      maePips = (currentTrades[trackerIndex].openPrice - currentTrades[trackerIndex].mae) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10;
   }
   
   // Calculate risk/reward
   double riskPercent = InpRiskPerTradePercent;
   double rRatio = (riskPercent != 0) ? (profitPercent / riskPercent) : 0;
   
   MqlDateTime entryTime, closeTime;
   TimeToStruct(currentTrades[trackerIndex].openTime, entryTime);
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
      TimeToString(currentTrades[trackerIndex].openTime), ticket, _Symbol, "CLOSE", 
      (currentTrades[trackerIndex].type == ORDER_TYPE_BUY) ? "BUY" : "SELL",
      currentTrades[trackerIndex].lots, currentTrades[trackerIndex].openPrice, currentTrades[trackerIndex].sl, currentTrades[trackerIndex].tp,
      // Entry Conditions
      currentTrades[trackerIndex].entryQuality, currentTrades[trackerIndex].entryConfluence, currentTrades[trackerIndex].entryZone, currentTrades[trackerIndex].entryRegime, currentTrades[trackerIndex].entryEntropy,
      currentTrades[trackerIndex].entryMAFast, currentTrades[trackerIndex].entryMASlow, currentTrades[trackerIndex].entrySpread,
      // Exit Conditions
      exitPrice, exitReason, profit, profitPercent, pips,
      exitQuality, exitConfluence, holdTimeBars,
      // Performance Metrics
      currentTrades[trackerIndex].mfe, currentTrades[trackerIndex].mae, mfePercent, maePercent, mfePips, maePips,
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
//============================= CHUNK 6: TRADING FUNCTIONS ===============//
// ADD THIS AFTER CHUNK 5
//========================================================================//

//========================================================================//
//=================== OPEN POSITION ======================================//
//========================================================================//

bool OpenPosition(ENUM_ORDER_TYPE orderType)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
   
   // Calculate SL/TP
   double sl, tp;
   if(!ComputeSLTPFromPercent(price, orderType, InpStopLossPercent, InpTakeProfitPercent, sl, tp))
   {
      Print("❌ Failed to compute SL/TP");
      return false;
   }
   
   // Calculate lot size
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPerTradePercent / 100.0;
   double slDistance = MathAbs(price - sl);
   double lots = CalculateLotSize(riskMoney, slDistance);
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size: ", lots);
      return false;
   }
   
   // Validate trade
   if(!ValidateTrade(sl, tp, lots))
   {
      return false;
   }
   
   // Execute
   bool success = false;
   if(orderType == ORDER_TYPE_BUY)
   {
      success = trade.Buy(lots, _Symbol, ask, sl, tp, "MA_Crossover_BUY");
   }
   else
   {
      success = trade.Sell(lots, _Symbol, bid, sl, tp, "MA_Crossover_SELL");
   }
   
   if(success)
   {
      ulong ticket = trade.ResultOrder();
      Print("✅ ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
            " opened: Ticket=", ticket, " Lots=", lots, " SL=", sl, " TP=", tp);
      
      // *** v5.0: Track trade with entry conditions ***
      double quality = 0, confluence = 0, zone = 0, regime = 0, entropy = 0;
      if(InpUsePhysics && InpUseTickPhysicsIndicator)
      {
         double qBuf[1], cBuf[1], zBuf[1], rBuf[1], eBuf[1];
         if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qBuf) > 0) quality = qBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, cBuf) > 0) confluence = cBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_TRADING_ZONE, 0, 1, zBuf) > 0) zone = zBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_VOL_REGIME, 0, 1, rBuf) > 0) regime = rBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_ENTROPY, 0, 1, eBuf) > 0) entropy = eBuf[0];
      }
      
      TrackNewTrade(ticket, quality, confluence, zone, regime, entropy);
   }
   else
   {
      Print("❌ Failed to open position: ", trade.ResultRetcodeDescription());
   }
   
   return success;
}

//========================================================================//
//=================== GET MA CROSSOVER SIGNAL ============================//
//========================================================================//

int GetMACrossoverSignal()
{
   if(!InpUseMAEntry)
      return 0;
   
   if(InpEnableDebug)
      Print("🔍 DEBUG: GetMACrossoverSignal() called");
   
   double maFastEntry[2], maSlowEntry[2];
   ArraySetAsSeries(maFastEntry, true);
   ArraySetAsSeries(maSlowEntry, true);
   
   if(CopyBuffer(maFastEntry_Handle, 0, 0, 2, maFastEntry) < 2)
   {
      if(InpEnableDebug)
         Print("❌ DEBUG: Failed to copy Fast MA Entry buffer");
      return 0;
   }
   
   if(CopyBuffer(maSlowEntry_Handle, 0, 0, 2, maSlowEntry) < 2)
   {
      if(InpEnableDebug)
         Print("❌ DEBUG: Failed to copy Slow MA Entry buffer");
      return 0;
   }
   
   if(InpEnableDebug)
   {
      Print("✅ DEBUG: InpUseMAEntry = TRUE");
      Print("🔍 DEBUG: Fast MA copied 2 bars (need 2)");
      Print("🔍 DEBUG: Slow MA copied 2 bars (need 2)");
      Print("📊 DEBUG: MA VALUES:");
      Print("   Fast[1]=", maFastEntry[1], " | Fast[0]=", maFastEntry[0]);
      Print("   Slow[1]=", maSlowEntry[1], " | Slow[0]=", maSlowEntry[0]);
   }
   
   // ✅ BULLISH CROSSOVER: Fast crosses ABOVE Slow
   // [1] = previous completed bar, [0] = current bar
   bool bullishCross = (maFastEntry[1] < maSlowEntry[1] && maFastEntry[0] > maSlowEntry[0]);
   
   if(InpEnableDebug)
   {
      Print("🔍 DEBUG BULLISH: Fast[1] < Slow[1]? ", maFastEntry[1] < maSlowEntry[1] ? "YES" : "NO");
      Print("🔍 DEBUG BULLISH: Fast[0] > Slow[0]? ", maFastEntry[0] > maSlowEntry[0] ? "YES" : "NO");
   }
   
   if(bullishCross)
   {
      Print("🔵 BULLISH CROSSOVER DETECTED!");
      Print("   Fast crossed from ", maFastEntry[1], " to ", maFastEntry[0]);
      Print("   Slow stayed at ", maSlowEntry[1], " to ", maSlowEntry[0]);
      return 1;
   }
   
   // ❌ BEARISH CROSSOVER: Fast crosses BELOW Slow
   bool bearishCross = (maFastEntry[1] > maSlowEntry[1] && maFastEntry[0] < maSlowEntry[0]);
   
   if(InpEnableDebug)
   {
      Print("🔍 DEBUG BEARISH: Fast[1] > Slow[1]? ", maFastEntry[1] > maSlowEntry[1] ? "YES" : "NO");
      Print("🔍 DEBUG BEARISH: Fast[0] < Slow[0]? ", maFastEntry[0] < maSlowEntry[0] ? "YES" : "NO");
   }
   
   if(bearishCross)
   {
      Print("🔴 BEARISH CROSSOVER DETECTED!");
      Print("   Fast crossed from ", maFastEntry[1], " to ", maFastEntry[0]);
      Print("   Slow stayed at ", maSlowEntry[1], " to ", maSlowEntry[0]);
      return -1;
   }
   
   if(InpEnableDebug)
      Print("⚪ DEBUG: No crossover detected this bar");
   
   return 0;
}

//========================================================================//
//=================== CHECK EXIT SIGNAL ==================================//
//========================================================================//

bool CheckExitSignal(ENUM_ORDER_TYPE posType)
{
   if(!InpUseMAExit)
      return false;
   
   double maFastExit[2], maSlowExit[2];
   
   if(CopyBuffer(maFastExit_Handle, 0, 0, 2, maFastExit) < 2)
      return false;
   if(CopyBuffer(maSlowExit_Handle, 0, 0, 2, maSlowExit) < 2)
      return false;
   
   if(posType == ORDER_TYPE_BUY)
   {
      // Exit BUY when Fast crosses BELOW Slow
      if(maFastExit[0] < maSlowExit[0] && maFastExit[1] > maSlowExit[1])
      {
         Print("🚪 Exit signal: BUY position (Fast crossed below Slow)");
         return true;
      }
   }
   else if(posType == ORDER_TYPE_SELL)
   {
      // Exit SELL when Fast crosses ABOVE Slow
      if(maFastExit[0] > maSlowExit[0] && maFastExit[1] < maSlowExit[1])
      {
         Print("🚪 Exit signal: SELL position (Fast crossed above Slow)");
         return true;
      }
   }
   
   return false;
}

//========================================================================//
//=================== MANAGE POSITIONS ===================================//
//========================================================================//

void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Check for MA exit signal
      if(CheckExitSignal(orderType))
      {
         if(trade.PositionClose(ticket))
         {
            Print("✅ Position closed on MA exit signal: #", ticket);
            LogTradeClose(ticket, "MA_Exit_Signal");  // *** v5.0: Log the close
         }
         continue;
      }
      
      // Move to breakeven logic
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentPrice = (orderType == ORDER_TYPE_BUY) ? 
         SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double profitPercent = 0;
      if(orderType == ORDER_TYPE_BUY)
         profitPercent = ((currentPrice - openPrice) / openPrice) * 100.0;
      else
         profitPercent = ((openPrice - currentPrice) / openPrice) * 100.0;
      
      if(profitPercent >= InpMoveToBEAtPercent)
      {
         bool needUpdate = false;
         
         if(orderType == ORDER_TYPE_BUY && currentSL < openPrice)
            needUpdate = true;
         else if(orderType == ORDER_TYPE_SELL && currentSL > openPrice)
            needUpdate = true;
         
         if(needUpdate)
         {
            if(trade.PositionModify(ticket, openPrice, PositionGetDouble(POSITION_TP)))
            {
               Print("✅ Moved to breakeven: #", ticket);
            }
         }
      }
   }
}

//========================================================================//
//=================== COUNT POSITIONS ====================================//
//========================================================================//

int CountPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         count++;
   }
   return count;
}

//========================================================================//
//=================== GET DAILY P/L ======================================//
//========================================================================//

double GetDailyPnL()
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(dailyStartBalance <= 0) return 0;
   return ((currentBalance - dailyStartBalance) / dailyStartBalance) * 100.0;
}

//========================================================================//
//=================== CHECK DAILY RESET ==================================//
//========================================================================//

void CheckDailyReset()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   MqlDateTime lastCheckStruct;
   TimeToStruct(lastDayCheck, lastCheckStruct);
   
   if(timeStruct.day != lastCheckStruct.day)
   {
      Print("📅 Daily reset - New trading day");
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      dailyTradeCount = 0;
      consecutiveLosses = 0;
      dailyPaused = false;
      lastDayCheck = TimeCurrent();
   }
   
   double pnl = GetDailyPnL();
   
   if(InpPauseOnLimits)
   {
      if(pnl >= InpDailyProfitTarget)
      {
         Print("✅ Daily profit target reached: ", pnl, "%");
         dailyPaused = true;
      }
      else if(pnl <= -InpDailyDrawdownLimit)
      {
         Print("⛔ Daily drawdown limit reached: ", pnl, "%");
         dailyPaused = true;
      }
   }
}

//========================================================================//
//=================== CHECK SESSION ======================================//
//========================================================================//

bool IsWithinSession()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   
   string startParts[];
   string endParts[];
   StringSplit(InpSessionStart, ':', startParts);
   StringSplit(InpSessionEnd, ':', endParts);
   
   int startMinutes = (int)StringToInteger(startParts[0]) * 60 + (int)StringToInteger(startParts[1]);
   int endMinutes = (int)StringToInteger(endParts[0]) * 60 + (int)StringToInteger(endParts[1]);
   
   if(startMinutes <= endMinutes)
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
   else
      return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
}

//============================= END OF CHUNK 6 ===========================//
// NEXT: Copy Chunk 7 (CSV init functions and UpdateDisplay)
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
//============================= CHUNK 8: MAIN EVENT FUNCTIONS ============//
// ADD THIS AFTER CHUNK 7 - THIS IS THE FINAL CHUNK!
//========================================================================//

//========================================================================//
//=================== OnInit() ===========================================//
//========================================================================//

int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 Initializing ", EA_NAME, " v", EA_VERSION);
   Print("═══════════════════════════════════════════════════════");
   
   // Initialize MA handles for entry
   maFastEntry_Handle = iMA(_Symbol, _Period, InpMAFast_Entry, 0, InpMAMethod, InpMAPrice);
   maSlowEntry_Handle = iMA(_Symbol, _Period, InpMASlow_Entry, 0, InpMAMethod, InpMAPrice);
   
   if(maFastEntry_Handle == INVALID_HANDLE || maSlowEntry_Handle == INVALID_HANDLE)
   {
      Print("❌ ERROR: Failed to create Entry MA indicators");
      return INIT_FAILED;
   }
   
   // Initialize MA handles for exit
   if(InpUseMAExit)
   {
      maFastExit_Handle = iMA(_Symbol, _Period, InpMAFast_Exit, 0, InpMAMethod, InpMAPrice);
      maSlowExit_Handle = iMA(_Symbol, _Period, InpMASlow_Exit, 0, InpMAMethod, InpMAPrice);
      
      if(maFastExit_Handle == INVALID_HANDLE || maSlowExit_Handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Failed to create Exit MA indicators");
         return INIT_FAILED;
      }
   }
   
   // Initialize TickPhysics indicator if enabled
   if(InpUseTickPhysicsIndicator)
   {
      indicatorHandle = iCustom(_Symbol, _Period, InpIndicatorName);
      
      if(indicatorHandle == INVALID_HANDLE)
      {
         Print("⚠️ WARNING: TickPhysics indicator not found!");
         Print("   Indicator name: ", InpIndicatorName);
         Print("   Physics filters will be disabled");
      }
      else
      {
         Print("✅ TickPhysics indicator loaded successfully");
      }
   }
   
   // Initialize CSV logging
   if(InpEnableSignalLog)
   {
      if(!InitSignalLog())
      {
         Print("⚠️ WARNING: Signal log initialization failed");
      }
      else
      {
         Print("✅ Signal log initialized: ", InpSignalLogFile);
      }
   }
   
   if(InpEnableTradeLog)
   {
      if(!InitTradeLog())
      {
         Print("⚠️ WARNING: Trade log initialization failed");
      }
      else
      {
         Print("✅ Trade log initialized: ", InpTradeLogFile);
      }
   }
   
   // *** v5.0: Initialize learning system ***
   if(InpEnableLearning)
   {
      if(!InitLearningSystem())
      {
         Print("⚠️ WARNING: Learning system initialization failed");
      }
      else
      {
         Print("✅ Learning system initialized");
      }
   }
   
   // Initialize daily tracking
   dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   lastDayCheck = TimeCurrent();
   
   // Configuration summary
   Print("═══════════════════════════════════════════════════════");
   Print("⚙️  CONFIGURATION:");
   Print("   MA Entry: ", InpMAFast_Entry, "/", InpMASlow_Entry);
   Print("   MA Exit: ", InpMAFast_Exit, "/", InpMASlow_Exit);
   Print("   Risk: ", InpRiskPerTradePercent, "%");
   Print("   SL: ", InpStopLossPercent, "% | TP: ", InpTakeProfitPercent, "%");
   Print("   Physics: ", (InpUsePhysics ? "ENABLED" : "DISABLED"));
   Print("   Indicator: ", (InpUseTickPhysicsIndicator ? "ENABLED" : "DISABLED"));
   Print("   Learning: ", (InpEnableLearning ? "ENABLED" : "DISABLED"));
   Print("   Max Spread: ", InpMaxSpread, " points");
   Print("═══════════════════════════════════════════════════════");
   Print("✅ EA initialized successfully - Ready to trade!");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//========================================================================//
//=================== OnDeinit() =========================================//
//========================================================================//

void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 Shutting down ", EA_NAME, " v", EA_VERSION);
   Print("   Reason: ", reason);
   
   // Release indicator handles
   if(maFastEntry_Handle != INVALID_HANDLE) IndicatorRelease(maFastEntry_Handle);
   if(maSlowEntry_Handle != INVALID_HANDLE) IndicatorRelease(maSlowEntry_Handle);
   if(maFastExit_Handle != INVALID_HANDLE) IndicatorRelease(maFastExit_Handle);
   if(maSlowExit_Handle != INVALID_HANDLE) IndicatorRelease(maSlowExit_Handle);
   if(indicatorHandle != INVALID_HANDLE) IndicatorRelease(indicatorHandle);
   
   // Final summary
   Print("   Total daily trades: ", dailyTradeCount);
   Print("   Daily P/L: ", GetDailyPnL(), "%");
   
   Print("═══════════════════════════════════════════════════════");
   Print("✅ EA shutdown complete");
   Print("═══════════════════════════════════════════════════════");
   
   Comment("");
}

//========================================================================//
//=================== OnTick() ===========================================//
//========================================================================//
// *** v5.0: COMPLETE ONTICK WITH ALL INTEGRATIONS ***
//========================================================================//

void OnTick()
{
   lastTickTime = TimeCurrent();  // Watchdog
   
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;
   
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
   
   // *** v5.0: Update MFE/MAE tracking ***
   UpdateMFEMAE();
   
   // ========================================================================
   // *** v5.5 CRITICAL FIX #1: MANAGE POSITIONS FIRST (BEFORE ENTRY LOGIC)
   // This ensures exit signals are processed before checking for new entries
   // ========================================================================
   if(InpEnableDebug)
   {
      Print("🔍 DEBUG: Starting OnTick() - Current positions: ", PositionsTotal());
   }
   
   ManagePositions();  // ✅ EXIT LOGIC RUNS FIRST
   
   if(InpEnableDebug)
   {
      Print("🔍 DEBUG: After ManagePositions() - Current positions: ", PositionsTotal());
   }
   
   // ========================================================================
   // Get MA crossover signals
   // ========================================================================
   int signal = GetMACrossoverSignal();
   
   if(InpEnableDebug && signal != 0)
   {
      Print("🔍 DEBUG: Signal detected: ", signal == 1 ? "BUY" : "SELL");
   }
   
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
   
   // *** v5.0 CRITICAL FIX: Apply physics filters BEFORE trading ***
   string rejectReason = "";
   bool physicsPass = CheckPhysicsFilters(signal, quality, confluence, tradingZone, 
                                          volRegime, entropy, rejectReason);
   
   // *** v5.0: Log ALL signals (including rejected ones) for analysis ***
   if(InpEnableSignalLog && signal != 0)
   {
      LogSignal(signal, quality, confluence, momentum, tradingZone, volRegime, entropy, 
                physicsPass, rejectReason);
   }
   
   // ========================================================================
   // *** v5.5 CRITICAL FIX #2: COMPREHENSIVE DEBUG BEFORE TRADE DECISION ***
   // ========================================================================
   int currentPositions = CountPositions();
   
   if(signal != 0 && InpEnableDebug)
   {
      Print("💡 DEBUG: ", signal == 1 ? "BUY" : "SELL", " signal detected, checking conditions...");
      Print("   CountPositions: ", currentPositions, " / ", InpMaxPositions);
      Print("   Consecutive Losses: ", consecutiveLosses, " / ", InpMaxConsecutiveLosses);
      Print("   Physics Pass: ", physicsPass ? "YES" : "NO");
      if(!physicsPass)
         Print("   Physics Reject Reason: ", rejectReason);
   }
   
   // ========================================================================
   // *** v5.5: Entry logic - WITH EXPLICIT REJECTION LOGGING ***
   // ========================================================================
   if(signal == 1)
   {
      if(currentPositions >= InpMaxPositions)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: BUY blocked - Max positions reached (", currentPositions, "/", InpMaxPositions, ")");
      }
      else if(consecutiveLosses >= InpMaxConsecutiveLosses)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: BUY blocked - Max consecutive losses (", consecutiveLosses, "/", InpMaxConsecutiveLosses, ")");
      }
      else if(!physicsPass)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: BUY blocked by physics filters: ", rejectReason);
         Print("⚠️ BUY signal REJECTED by physics filters: ", rejectReason);
      }
      else
      {
         if(InpEnableDebug)
            Print("✅ DEBUG: All conditions met, attempting to open BUY...");
         
         if(OpenPosition(ORDER_TYPE_BUY))
         {
            dailyTradeCount++;
            if(InpEnableDebug)
               Print("🎉 DEBUG: BUY position opened successfully!");
         }
         else
         {
            if(InpEnableDebug)
               Print("❌ DEBUG: Failed to open BUY position");
         }
      }
   }
   else if(signal == -1)
   {
      if(currentPositions >= InpMaxPositions)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: SELL blocked - Max positions reached (", currentPositions, "/", InpMaxPositions, ")");
      }
      else if(consecutiveLosses >= InpMaxConsecutiveLosses)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: SELL blocked - Max consecutive losses (", consecutiveLosses, "/", InpMaxConsecutiveLosses, ")");
      }
      else if(!physicsPass)
      {
         if(InpEnableDebug)
            Print("❌ DEBUG: SELL blocked by physics filters: ", rejectReason);
         Print("⚠️ SELL signal REJECTED by physics filters: ", rejectReason);
      }
      else
      {
         if(InpEnableDebug)
            Print("✅ DEBUG: All conditions met, attempting to open SELL...");
         
         if(OpenPosition(ORDER_TYPE_SELL))
         {
            dailyTradeCount++;
            if(InpEnableDebug)
               Print("🎉 DEBUG: SELL position opened successfully!");
         }
         else
         {
            if(InpEnableDebug)
               Print("❌ DEBUG: Failed to open SELL position");
         }
      }
   }
   
   // Update display
   UpdateDisplay(signal, quality, confluence, tradingZone, volRegime, entropy);
   
   // *** v5.0: Check if learning cycle should run ***
   CheckLearningTrigger();
}


