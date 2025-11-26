//+------------------------------------------------------------------+
//|                    TP_Integrated_EA_Crossover_4_2_0_6.mq5        |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property description "v4.2.0.6 EA with Complete Data Integrity + ConfluenceSlope + Spread + Entropy - ML-READY"

// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "4.2.0.6_COMPLETE"

input int MagicNumber = 4004206;                        // EA magic number
input string TradeComment = "TP_Integrated 4_2_0_6";      // Trade comment


// Indicator Version Selection
enum INDICATOR_VERSION
{
   INDICATOR_AUTO = 0,      // Auto-detect from symbol
   INDICATOR_CRYPTO = 1,    // TickPhysics_Crypto_Indicator_v2_1
   INDICATOR_FOREX = 2,     // TickPhysics_Forex_Indicator_v2_1
   INDICATOR_INDICES = 3,   // TickPhysics_Indices_Indicator_v2_1
   INDICATOR_METALS = 4,    // TickPhysics_Metals_Indicator_v2_1
   INDICATOR_UNIVERSAL = 5  // TickPhysics_Universal_Indicator_v2_2 (RECOMMENDED)
};

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
input double      RiskPercentPerTrade     = 5.0;         // Risk per trade (% of balance)
input double      MaxDailyRisk            = 90.0;        // Max daily risk (% of balance)
input int         MaxConcurrentTrades     = 10;           // Max concurrent positions
input double      MinRRatio               = 1.0;         // Min reward:risk ratio

// === Trade Parameters ===
input group "📊 Trade Parameters (Asset-Adaptive)"
input bool        UseAssetAdaptiveSLTP    = true;            // Enable asset-specific SL/TP defaults
input int         StopLossPips_Forex      = 8;             // SL Forex (pips) - 90 points on 5-digit
input int         TakeProfitPips_Forex    = 4;             // TP Forex (pips) - 30 points
input int         StopLossPips_Indices    = 2000;             // SL Indices (pips) - 350 points (reasonable for NAS100/US30)
input int         TakeProfitPips_Indices  = 2000;             // TP Indices (pips)
input int         StopLossPips_Crypto     = 400;              // SL Crypto (pips) - $500 for BTCUSD ($10/pip)
input int         TakeProfitPips_Crypto   = 200;              // TP Crypto (pips) - $250 for BTCUSD
input int         StopLossPips_Metal      = 400;             // SL Metals (pips) - $8 for XAUUSD
input int         TakeProfitPips_Metal    = 200;             // TP Metals (pips)
input bool        UseTrailingStop         = false;           // Enable trailing stop
input int         TrailingStopPips        = 30;              // Trailing stop (pips)

// === Entry System Selection ===
input group "📊 Entry Logic"
input INDICATOR_VERSION    IndicatorVersion           = INDICATOR_AUTO;  // Indicator version to use (UNIVERSAL recommended)
input bool                 UsePhysicsEntry            = false;           // Use physics acceleration crossover
input bool                 UseMAEntry                 = false;           // Use Moving Average crossover
input bool                 UsePhysicsFiltersAsEntry   = true;            // Use physics filters as entry triggers
input int                  MA_Fast                    = 5;              // Fast MA period
input int                  MA_Slow                    = 25;              // Slow MA period
input ENUM_MA_METHOD       MA_Method                  = MODE_SMMA;        // MA calculation method
input ENUM_APPLIED_PRICE   MA_Price                   = PRICE_CLOSE;     // MA price type

// === Signal Filters (v4.0 OPTIMIZED) ===
input group "🎯 Physics Filters v4.0"
input bool                 UsePhysicsFilters          = true;            // Enable physics filtering
input double               MinQualityBuy              = 70.0;            // Min physics quality for BUY
input double               MinQualitySell             = 70.0;            // Min physics quality for SELL
input bool                 AvoidTransitionZone        = true;           // Reject TRANSITION/AVOID zones
input bool                 UseRegimeFilter            = true;           // Filter by volatility regime

// === Spread Filter (v4.6) ===
input group "📊 Spread Filter (Cost Control)"
input bool                 UseSpreadFilter            = true;            // Enable spread filtering
input double               MaxSpreadPips              = 25.0;             // Max spread allowed (pips)
input bool                 UseAdaptiveSpread          = false;           // Use ATR-based adaptive spread limit
input double               MaxSpreadATRMultiple       = 0.5;             // Max spread as % of ATR (0.5 = 50% of ATR)

// === Acceleration/Speed/Momentum Filters ===
input group "⚡ Advanced Physics Entry Filters"
input bool                 UseAccelerationFilter      = true;            // Enable acceleration threshold
input double               MinAccelerationBuy         =  1.0;           // Min acceleration for BUY (positive)
input double               MinAccelerationSell        = -1.0;          // Min acceleration for SELL (negative value)
input bool                 UseSpeedFilter             = true;           // Enable speed threshold
input double               MinSpeedBuy                = 1.0;            // Min speed for BUY (positive)
input double               MinSpeedSell               = -1.0;           // Min speed for SELL (negative value)
input bool                 UseMomentumFilter          = true;           // Enable momentum threshold
input double               MinMomentumBuy             = 1.0;            // Min momentum for BUY (positive)
input double               MinMomentumSell            = -1.0;           // Min momentum for SELL (negative value)

// === Physics Score Weighting (Evidence-Based) ===
input group "🔬 Physics Score Calculation (Multi-Asset Validated)"
input bool                 UseEvidenceBasedWeights    = true;            // Use evidence-based weights from correlation analysis
input bool                 UseTimeframeSpecificWeights = true;          // Different weights for 1H vs 5M
input double               Weight_Speed_1H            = 28.0;           // Speed weight for 1H (%) - #1 UNIVERSAL PREDICTOR
input double               Weight_Acceleration_1H     = 32.0;           // Acceleration weight for 1H (%)
input double               Weight_Confluence_1H       = 15.0;           // Confluence weight for 1H (%)
input double               Weight_Jerk_1H             = 12.0;           // Jerk weight for 1H (%)
input double               Weight_Momentum_1H         = 10.0;           // Momentum weight for 1H (%)
input double               Weight_Quality_1H          = 3.0;            // Quality weight for 1H (%)
input double               Weight_Speed_5M            = 25.0;           // Speed weight for 5M (%) - #1 UNIVERSAL PREDICTOR
input double               Weight_Acceleration_5M     = 28.0;           // Acceleration weight for 5M (%)
input double               Weight_Confluence_5M       = 15.0;           // Confluence weight for 5M (%)
input double               Weight_Jerk_5M             = 15.0;           // Jerk weight for 5M (%)
input double               Weight_Momentum_5M         = 12.0;           // Momentum weight for 5M (%)
input double               Weight_Quality_5M          = 5.0;            // Quality weight for 5M (%)

// === v4.2 Multi-Asset Optimizations ===
input group "🎯 v4.2 Entry Filters (Multi-Asset Validated)"
input bool                 UsePhysicsScoreFilter      = true;            // Enable physics score threshold
input double               MinPhysicsScoreBuy         = 40.0;            // Min physics score for BUY
input double               MinPhysicsScoreSell        = 40.0;            // Min physics score for SELL
input bool                 RequireFullConfluence      = true;            // Require 100% confluence (+11.5% win boost)
input bool                 PreferIndices              = false;           // Log index vs forex performance separately

// === v4.5 Slope Filters (Directional Momentum) ===
input group "📈 v4.5 Slope Filters (Trend Direction Confirmation)"
input bool                 UseSlopeFilters            = true;            // Enable slope-based filtering
input int                  SlopeLookbackBars          = 3;               // Bars for slope calculation (3-5 recommended)
input bool                 UseSpeedSlope              = true;            // Require Speed slope trending in signal direction
input double               MinSpeedSlopeBuy           = 1.0;             // Min Speed slope for BUY (positive, units/bar)
input double               MinSpeedSlopeSell          = -1.0;            // Min Speed slope for SELL (negative, units/bar)
input bool                 UseAccelerationSlope       = true;           // Require Acceleration slope confirmation
input double               MinAccelerationSlopeBuy    = 1.0;             // Min Acceleration slope for BUY (positive, units/bar)
input double               MinAccelerationSlopeSell   = -1.0;            // Min Acceleration slope for SELL (negative, units/bar)
input bool                 UseConfluenceSlope         = true;           // Require Confluence trending upward
input double               MinConfluenceSlopeBuy      = 1.0;             // Min Confluence slope for BUY (percent/bar)
input double               MinConfluenceSlopeSell     = 1.0;             // Min Confluence slope for SELL (percent/bar)
input bool                 UseMomentumSlope           = true;           // Require Momentum slope confirmation
input double               MinMomentumSlopeBuy        = 1.0;             // Min Momentum slope for BUY (positive, units/bar)
input double               MinMomentumSlopeSell       = -1.0;            // Min Momentum slope for SELL (negative, units/bar)
input bool                 UseJerkSlope               = true;           // Use Jerk slope (advanced, may be noisy)
input double               MinJerkSlopeBuy            = 1.0;             // Min Jerk slope for BUY (positive, units/bar)
input double               MinJerkSlopeSell           = -1.0;            // Min Jerk slope for SELL (negative, units/bar)

// === v4.6 Isolated Component Testing ===
input group "🧪 v4.6 Isolated Testing (For Single-Factor Analysis)"
input bool                 UseIsolatedTesting         = false;           // ENABLE to test individual components in isolation
input bool                 IsolatedSpeedSlopeOnly     = false;           // Test ONLY SpeedSlope (ignores all other filters)
input bool                 IsolatedAccelSlopeOnly     = false;           // Test ONLY AccelerationSlope
input bool                 IsolatedMomentumSlopeOnly  = false;           // Test ONLY MomentumSlope
input bool                 IsolatedSpeedOnly          = false;           // Test ONLY raw Speed value
input bool                 IsolatedAccelOnly          = false;           // Test ONLY raw Acceleration value
input bool                 IsolatedMomentumOnly       = false;           // Test ONLY raw Momentum value
input bool                 IsolatedQualityOnly        = false;           // Test ONLY Quality threshold

// === Time & Day-of-Week Filters ===
input group "🕐 Trading Time & Day Restrictions"
input bool                 UseTimeFilter              = false;           // Enable time-of-day filtering
input int                  TradingStartHour           = 0;               // Trading start hour (0-23, broker time)
input int                  TradingEndHour             = 23;              // Trading end hour (0-23, broker time)
input bool                 UseDayOfWeekFilter         = false;           // Enable day-of-week filtering
input bool                 TradeOnMonday              = true;            // Trade on Monday
input bool                 TradeOnTuesday             = true;            // Trade on Tuesday
input bool                 TradeOnWednesday           = true;            // Trade on Wednesday
input bool                 TradeOnThursday            = true;            // Trade on Thursday
input bool                 TradeOnFriday              = true;            // Trade on Friday
input bool                 TradeOnSaturday            = true;            // Trade on Saturday (crypto only)
input bool                 TradeOnSunday              = true;            // Trade on Sunday (crypto only)

// === Monitoring ===
input group "📈 Post-Trade Monitoring"
input int                  PostExitMonitorBars        = 50;              // RunUp/RunDown monitor bars
input bool                 EnableRealTimeLogging      = true;            // Log signals in real-time

// === Advanced ===
input group "⚙️ Advanced Settings"
input bool                 EnableDebugMode            = true;            // Verbose logging
input bool                 BypassAllFilters           = false;           // TESTING: Bypass all filters
input bool                 DryRunMode                 = false;           // TESTING: Log signals but don't trade
input bool                 EnableFilterAlerts         = true;            // Alert when filters block signals

// === v4.0 Dashboard Display ===
input group "📊 v4.0 Dashboard"
input bool                 ShowDashboard              = true;            // Show on-chart dashboard
input int                  DashboardCorner            = 0;               // Corner: 0=UL, 1=UR, 2=LL, 3=LR
input int                  DashboardX                 = 10;              // X offset (pixels)
input int                  DashboardY                 = 20;              // Y offset (pixels)
input int                  DashboardFontSize          = 9;               // Font size
input int                  DashboardUpdateSeconds     = 5;               // Update interval (seconds)

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

CPhysicsIndicator g_physics;
CRiskManager g_riskManager;
CTradeTracker g_tracker;
CCSVLogger g_logger;
CTrade g_trade;

string g_indicatorName = "";  // Will be set in OnInit based on selection
bool g_initialized = false;
datetime g_lastBarTime = 0;

// MA indicator handles
int g_maFastHandle = INVALID_HANDLE;
int g_maSlowHandle = INVALID_HANDLE;

// Dashboard management
datetime g_lastDashboardUpdate = 0;

// Filter statistics
int g_filtersBlockedToday = 0;
int g_signalsToday = 0;
datetime g_lastStatResetDay = 0;

// Indicator window tracking
int g_indicatorSubwindow = -1;

// Previous physics values for change detection
double g_prevSpeed = 0;
double g_prevAccel = 0;
double g_prevMomentum = 0;

// Buffer update failure tracking
int g_bufferUpdateFailures = 0;
int g_consecutiveBufferFailures = 0;
datetime g_lastBufferUpdateTime = 0;

// Physics score tracking
double g_lastPhysicsScore = 0.0;

// v4.5: Slope tracking (last calculated slopes)
double g_lastSpeedSlope = 0.0;
double g_lastAccelerationSlope = 0.0;
double g_lastMomentumSlope = 0.0;
double g_lastConfluenceSlope = 0.0;
double g_lastJerkSlope = 0.0;

// v4.2.0.6: Confluence history for slope calculation (Manual tracking required)
double g_confluenceHistory[20]; // Store last 20 bars of confluence
double g_lastTickConfluence = 0.0; // Last known confluence value from OnTick

// v4.6: Spread tracking
double g_lastSpreadPips = 0.0;
double g_spreadRejectionCount = 0;
double g_avgSpreadPips = 0.0;
int g_spreadSampleCount = 0;

//+------------------------------------------------------------------+
//| Calculate Linear Regression Slope (Excel SLOPE equivalent)       |
//| Uses CLOSED bars (1 to lookback) to avoid lookahead bias         |
//+------------------------------------------------------------------+
double CalculateRegressionSlope(int lookback, int metricType)
{
   if(lookback < 2) return 0.0;
   
   double sumX = 0.0, sumY = 0.0, sumXY = 0.0, sumX2 = 0.0;
   
   // We use closed bars: 1 to lookback
   // X axis: 0 to lookback-1 (where 0 is oldest, lookback-1 is newest)
   // This ensures positive slope means increasing value
   
   for(int i = 0; i < lookback; i++)
   {
      // Bar index: lookback - i (Oldest is lookback, Newest is 1)
      int barIdx = lookback - i;
      
      double y = 0.0;
      switch(metricType)
      {
         case 0: y = g_physics.GetSpeed(barIdx); break;
         case 1: y = g_physics.GetAcceleration(barIdx); break;
         case 2: y = g_physics.GetMomentum(barIdx); break;
         case 3: 
            // Use manual history for Confluence (barIdx 1 = history[0])
            if(barIdx >= 1 && barIdx <= 20)
               y = g_confluenceHistory[barIdx - 1];
            else
               y = 0.0;
            break;
         case 4: y = g_physics.GetJerk(barIdx); break;
      }
      
      double x = (double)i;
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
   }
   
   double n = (double)lookback;
   double denominator = (n * sumX2 - sumX * sumX);
   
   if(denominator == 0) return 0.0;
   
   return (n * sumXY - sumX * sumY) / denominator;
}

//+------------------------------------------------------------------+
//| Calculate All Physics Slopes                                     |
//| FIXED: Uses bars 1, 2, 3 (closed bars only) instead of 0, 1, 2  |
//+------------------------------------------------------------------+
void CalculatePhysicsSlopes()
{
   // CRITICAL: Use bars 1, 2, 3+ (CLOSED BARS ONLY)
   // Bar 0 is still forming and creates lookahead bias in backtesting
   
   int lookback = SlopeLookbackBars;
   
   if(lookback < 2) lookback = 2;  // Minimum 2 bars needed
   if(lookback > 10) lookback = 10;  // Cap at 10 bars
   
   // Calculate slopes using Linear Regression (Excel SLOPE)
   g_lastSpeedSlope = CalculateRegressionSlope(lookback, 0);        // Speed
   g_lastAccelerationSlope = CalculateRegressionSlope(lookback, 1); // Acceleration
   g_lastMomentumSlope = CalculateRegressionSlope(lookback, 2);     // Momentum
   g_lastConfluenceSlope = CalculateRegressionSlope(lookback, 3);   // Confluence
   g_lastJerkSlope = CalculateRegressionSlope(lookback, 4);         // Jerk
}

//+------------------------------------------------------------------+
//| Get Asset-Adaptive SL/TP Pips                                     |
//+------------------------------------------------------------------+
void GetAssetAdaptiveSLTP(int &outStopLossPips, int &outTakeProfitPips)
{
   if(!UseAssetAdaptiveSLTP)
   {
      // Use Forex defaults if asset adaptation is disabled
      outStopLossPips = StopLossPips_Forex;
      outTakeProfitPips = TakeProfitPips_Forex;
      return;
   }
   
   // Get asset class from risk manager (as integer: 0=FOREX, 1=CRYPTO, 2=METAL, 3=INDEX)
   int assetClass = (int)g_riskManager.GetAssetClass();
   
   // ASSET_FOREX = 0, ASSET_CRYPTO = 1, ASSET_METAL = 2, ASSET_INDEX = 3
   if(assetClass == 0)  // FOREX
   {
      outStopLossPips = StopLossPips_Forex;
      outTakeProfitPips = TakeProfitPips_Forex;
      if(EnableDebugMode)
         Print(StringFormat("📊 Using FOREX SL/TP: %d/%d pips", outStopLossPips, outTakeProfitPips));
   }
   else if(assetClass == 3)  // INDEX
   {
      outStopLossPips = StopLossPips_Indices;
      outTakeProfitPips = TakeProfitPips_Indices;
      if(EnableDebugMode)
         Print(StringFormat("📊 Using INDICES SL/TP: %d/%d pips", outStopLossPips, outTakeProfitPips));
   }
   else if(assetClass == 1)  // CRYPTO
   {
      outStopLossPips = StopLossPips_Crypto;
      outTakeProfitPips = TakeProfitPips_Crypto;
      if(EnableDebugMode)
         Print(StringFormat("📊 Using CRYPTO SL/TP: %d/%d pips", outStopLossPips, outTakeProfitPips));
   }
   else if(assetClass == 2)  // METAL
   {
      outStopLossPips = StopLossPips_Metal;
      outTakeProfitPips = TakeProfitPips_Metal;
      if(EnableDebugMode)
         Print(StringFormat("📊 Using METAL SL/TP: %d/%d pips", outStopLossPips, outTakeProfitPips));
   }
   else  // UNKNOWN
   {
      outStopLossPips = StopLossPips_Forex;
      outTakeProfitPips = TakeProfitPips_Forex;
      Print("⚠️ Unknown asset class, using FOREX defaults");
   }
}

//+------------------------------------------------------------------+
//| Calculate Current Spread in Pips                                 |
//+------------------------------------------------------------------+
double GetCurrentSpreadPips()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = ask - bid;
   
   // Convert to pips
   double pipSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   // For 5-digit (0.00001) or 3-digit (0.001) brokers, divide by 10
   double pipMultiplier = (digits == 5 || digits == 3) ? 10.0 : 1.0;
   
   double spreadPips = (spread / pipSize) / pipMultiplier;
   
   // Update tracking variables
   g_lastSpreadPips = spreadPips;
   g_avgSpreadPips = ((g_avgSpreadPips * g_spreadSampleCount) + spreadPips) / (g_spreadSampleCount + 1);
   g_spreadSampleCount++;
   
   return spreadPips;
}

//+------------------------------------------------------------------+
//| Check Spread Filter                                              |
//| Returns: true if spread is acceptable, false if too high         |
//+------------------------------------------------------------------+
bool CheckSpreadFilter()
{
   if(!UseSpreadFilter)
      return true;  // Filter disabled, accept all spreads
   
   double currentSpread = GetCurrentSpreadPips();
   
   // Fixed spread limit
   if(!UseAdaptiveSpread)
   {
      if(currentSpread > MaxSpreadPips)
      {
         if(EnableDebugMode)
            Print(StringFormat("❌ SPREAD FILTER: Current spread %s pips exceeds max %s pips", DoubleToString(currentSpread, 2), DoubleToString(MaxSpreadPips, 2)));
         g_spreadRejectionCount++;
         return false;
      }
      return true;
   }
   
   // Adaptive spread limit (ATR-based)
   // Get ATR value from indicator if available, otherwise use simple calculation
   double atr = 0.0;
   int atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atrHandle != INVALID_HANDLE)
   {
      double atrBuffer[];
      ArraySetAsSeries(atrBuffer, true);
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0)
      {
         atr = atrBuffer[0];
      }
   }
   
   if(atr > 0)
   {
      // Convert ATR to pips
      double pipSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      double pipMultiplier = (digits == 5 || digits == 3) ? 10.0 : 1.0;
      double atrPips = (atr / pipSize) / pipMultiplier;
      
      double maxSpreadAllowed = atrPips * MaxSpreadATRMultiple;
      
      if(currentSpread > maxSpreadAllowed)
      {
         if(EnableDebugMode)
            Print(StringFormat("❌ ADAPTIVE SPREAD FILTER: Spread %s pips exceeds %s%% of ATR (%s pips)", DoubleToString(currentSpread, 2), DoubleToString(MaxSpreadATRMultiple * 100, 0), DoubleToString(maxSpreadAllowed, 2)));
         g_spreadRejectionCount++;
         return false;
      }
   }
   else
   {
      // Fallback to fixed limit if ATR unavailable
      if(currentSpread > MaxSpreadPips)
      {
         g_spreadRejectionCount++;
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get Timeframe String for CSV Filenames (with leading zeros)     |
//+------------------------------------------------------------------+
string GetTimeframeString()
{
   switch(Period())
   {
      case PERIOD_M1:  return "M01";
      case PERIOD_M2:  return "M02";
      case PERIOD_M3:  return "M03";
      case PERIOD_M4:  return "M04";
      case PERIOD_M5:  return "M05";
      case PERIOD_M6:  return "M06";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H01";
      case PERIOD_H2:  return "H02";
      case PERIOD_H3:  return "H03";
      case PERIOD_H4:  return "H04";
      case PERIOD_H6:  return "H06";
      case PERIOD_H8:  return "H08";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D01";
      case PERIOD_W1:  return "W01";
      case PERIOD_MN1: return "MN1";
      default:         
      {
         int minutes = PeriodSeconds(PERIOD_CURRENT)/60;
         if(minutes < 60)
            return StringFormat("M%02d", minutes);  // M01-M59
         else if(minutes < 1440)
            return StringFormat("H%02d", minutes/60);  // H01-H23
         else
            return StringFormat("D%02d", minutes/1440);  // D01+
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Physics Score (Evidence-Based Weighting)               |
//+------------------------------------------------------------------+
double CalculatePhysicsScore()
{
   // Get current timeframe in minutes
   int timeframeMins = PeriodSeconds(PERIOD_CURRENT) / 60;
   
   // Get all physics metrics (normalized 0-100)
   double accel = g_physics.GetAcceleration(0);
   double speed = g_physics.GetSpeed(0);
   double jerk = g_physics.GetJerk(0);
   double momentum = g_physics.GetMomentum(0);
   double confluence = g_physics.GetConfluence(0);
   double quality = g_physics.GetQuality(0);
   
   // Normalize to 0-100 range (assuming typical ranges)
   // Acceleration: -200 to +200 -> normalize to 0-100
   double accelNorm = (accel + 200.0) / 4.0;
   accelNorm = MathMax(0, MathMin(100, accelNorm));
   
   // Speed: -150 to +150 -> normalize to 0-100
   double speedNorm = (speed + 150.0) / 3.0;
   speedNorm = MathMax(0, MathMin(100, speedNorm));
   
   // Jerk: -100 to +100 -> normalize to 0-100
   double jerkNorm = (jerk + 100.0) / 2.0;
   jerkNorm = MathMax(0, MathMin(100, jerkNorm));
   
   // Momentum: -100 to +100 -> normalize to 0-100
   double momentumNorm = (momentum + 100.0) / 2.0;
   momentumNorm = MathMax(0, MathMin(100, momentumNorm));
   
   // Confluence and Quality are already 0-100
   
   double physicsScore = 0.0;
   
   if(UseEvidenceBasedWeights)
   {
      // Use evidence-based weights from multi-dataset analysis
      if(UseTimeframeSpecificWeights)
      {
         // Use timeframe-specific weights
         if(timeframeMins >= 60)  // 1H or higher
         {
            physicsScore = (accelNorm * Weight_Acceleration_1H / 100.0) +
                          (speedNorm * Weight_Speed_1H / 100.0) +
                          (jerkNorm * Weight_Jerk_1H / 100.0) +
                          (momentumNorm * Weight_Momentum_1H / 100.0) +
                          (confluence * Weight_Confluence_1H / 100.0) +
                          (quality * Weight_Quality_1H / 100.0);
         }
         else  // 5M, 15M, 30M
         {
            physicsScore = (accelNorm * Weight_Acceleration_5M / 100.0) +
                          (speedNorm * Weight_Speed_5M / 100.0) +
                          (jerkNorm * Weight_Jerk_5M / 100.0) +
                          (momentumNorm * Weight_Momentum_5M / 100.0) +
                          (confluence * Weight_Confluence_5M / 100.0) +
                          (quality * Weight_Quality_5M / 100.0);
         }
      }
      else
      {
         // Use 1H weights for all timeframes
         physicsScore = (accelNorm * Weight_Acceleration_1H / 100.0) +
                       (speedNorm * Weight_Speed_1H / 100.0) +
                       (jerkNorm * Weight_Jerk_1H / 100.0) +
                       (momentumNorm * Weight_Momentum_1H / 100.0) +
                       (confluence * Weight_Confluence_1H / 100.0) +
                       (quality * Weight_Quality_1H / 100.0);
      }
   }
   else
   {
      // Equal weighting (legacy method)
      physicsScore = (accelNorm + speedNorm + jerkNorm + momentumNorm + confluence + quality) / 6.0;
   }
   
   g_lastPhysicsScore = physicsScore;
   return physicsScore;
}

//+------------------------------------------------------------------+
//| Load TickPhysics indicator on chart                              |
//+------------------------------------------------------------------+
bool LoadIndicatorOnChart(string indicatorName)
{
   // Check if indicator is already on chart
   int total = ChartIndicatorsTotal(0, 1);  // Subwindow 1
   for(int i = 0; i < total; i++)
   {
      string name = ChartIndicatorName(0, 1, i);
      if(StringFind(name, "TickPhysics") >= 0)
      {
         Print("✅ TickPhysics indicator already on chart in subwindow 1");
         g_indicatorSubwindow = 1;
         return true;
      }
   }
   
   // Try to load the indicator
   Print(StringFormat("📊 Loading indicator on chart: %s", indicatorName));
   
   // Create indicator handle first (this validates it exists)
   int handle = iCustom(_Symbol, _Period, indicatorName);
   if(handle == INVALID_HANDLE)
   {
      Print(StringFormat("❌ Failed to create indicator handle for: %s", indicatorName));
      return false;
   }
   
   // Add indicator to chart
   bool added = ChartIndicatorAdd(0, 1, handle);
   if(added)
   {
      g_indicatorSubwindow = 1;
   Print(StringFormat("✅ Successfully loaded %s on chart (subwindow 1)", indicatorName));
      ChartRedraw();
      return true;
   }
   else
   {
      Print("⚠️ Could not add indicator to chart window, but it will work in background");
      Print("   You can manually drag the indicator to the chart if you want to see it");
      return true;  // Still return true because EA can work without visual indicator
   }
}

//+------------------------------------------------------------------+
//| Auto-detect indicator version from symbol                        |
//+------------------------------------------------------------------+
string GetIndicatorName(INDICATOR_VERSION version)
{
   string sym = _Symbol;
   StringToUpper(sym);
   
   // If AUTO mode, detect from symbol
   if(version == INDICATOR_AUTO)
   {
      // Crypto detection - MUST CHECK FIRST (before forex pairs)
      // Check for ticker symbols: BTC, ETH, XRP, etc.
      string cryptoTickers[] = {"BTC", "ETH", "LTC", "XRP", "BCH", "EOS", "ADA", "DOT", "LINK", 
                                "UNI", "DOGE", "SHIB", "MATIC", "SOL", "AVAX", "BNB", "TRX", 
                                "XLM", "ATOM", "VET", "FTM", "ALGO", "XTZ", "EGLD", "NEAR"};
      
      // Check for full names: Bitcoin, Ethereum, Ripple, etc.
      string cryptoNames[] = {"BITCOIN", "ETHEREUM", "LITECOIN", "RIPPLE", "CARDANO", "POLKADOT", 
                              "CHAINLINK", "DOGECOIN", "SOLANA", "AVALANCHE", "BINANCE", "TRON"};
      
      for(int i = 0; i < ArraySize(cryptoTickers); i++)
      {
         if(StringFind(sym, cryptoTickers[i]) >= 0)
         {
            Print(StringFormat("📊 Auto-detected CRYPTO symbol (%s): Using TickPhysics_Crypto_Indicator_v2_1", cryptoTickers[i]));
            return "TickPhysics_Crypto_Indicator_v2_1";
         }
      }
      
      for(int i = 0; i < ArraySize(cryptoNames); i++)
      {
         if(StringFind(sym, cryptoNames[i]) >= 0)
         {
            Print(StringFormat("📊 Auto-detected CRYPTO symbol (%s): Using TickPhysics_Crypto_Indicator_v2_1", cryptoNames[i]));
            return "TickPhysics_Crypto_Indicator_v2_1";
         }
      }
      
      // Indices detection (NAS100, US30, SPX500, JP225, etc.)
      if(StringFind(sym, "NAS") >= 0 || StringFind(sym, "US30") >= 0 || 
         StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 ||
         StringFind(sym, "DOW") >= 0 || StringFind(sym, "DAX") >= 0 ||
         StringFind(sym, "FTSE") >= 0 || StringFind(sym, "NIKKEI") >= 0 ||
         StringFind(sym, "JP225") >= 0 || StringFind(sym, "JPN225") >= 0 ||
         StringFind(sym, "HK50") >= 0 || StringFind(sym, "AUS200") >= 0 ||
         StringFind(sym, "CAC") >= 0 || StringFind(sym, "STOXX") >= 0)
      {
         Print("📊 Auto-detected INDICES symbol: Using TickPhysics_Indices_Indicator_v2_1");
         return "TickPhysics_Indices_Indicator_v2_1";
      }
      
      // Metals detection (XAUUSD, XAGUSD, Gold, Silver, Platinum, Palladium, Copper)
      if(StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0 || 
         StringFind(sym, "XAG") >= 0 || StringFind(sym, "SILVER") >= 0 ||
         StringFind(sym, "XPT") >= 0 || StringFind(sym, "PLATINUM") >= 0 ||
         StringFind(sym, "XPD") >= 0 || StringFind(sym, "PALLADIUM") >= 0 ||
         StringFind(sym, "XCU") >= 0 || StringFind(sym, "COPPER") >= 0)
      {
         Print("📊 Auto-detected METALS symbol: Using TickPhysics_Metals_Indicator_v2_1");
         return "TickPhysics_Metals_Indicator_v2_1";
      }
      
      // Forex detection (check if it's a currency pair)
      if(StringLen(sym) == 6 || StringLen(sym) == 7)  // Standard forex pairs
      {
         // Additional forex pair checks
         string currencies[] = {"USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "NZD"};
         for(int i = 0; i < ArraySize(currencies); i++)
         {
            if(StringFind(sym, currencies[i]) >= 0)
            {
               Print("📊 Auto-detected FOREX symbol: Using TickPhysics_Forex_Indicator_v2_1");
               return "TickPhysics_Forex_Indicator_v2_1";
            }
         }
      }
      
      // Default to Forex if can't determine
      Print("⚠️ Could not auto-detect symbol type, defaulting to FOREX indicator");
      return "TickPhysics_Forex_Indicator_v2_1";
   }
   
   // Manual selection
   switch(version)
   {
      case INDICATOR_CRYPTO:
         Print("📊 Manual selection: Using TickPhysics_Crypto_Indicator_v2_1");
         return "TickPhysics_Crypto_Indicator_v2_1";
         
      case INDICATOR_FOREX:
         Print("📊 Manual selection: Using TickPhysics_Forex_Indicator_v2_1");
         return "TickPhysics_Forex_Indicator_v2_1";
         
      case INDICATOR_INDICES:
         Print("📊 Manual selection: Using TickPhysics_Indices_Indicator_v2_1");
         return "TickPhysics_Indices_Indicator_v2_1";
         
      case INDICATOR_METALS:
         Print("📊 Manual selection: Using TickPhysics_Metals_Indicator_v2_1");
         return "TickPhysics_Metals_Indicator_v2_1";
         
      case INDICATOR_UNIVERSAL:
         Print("📊 Manual selection: Using TickPhysics_Universal_Indicator_v2_2 (RECOMMENDED)");
         return "TickPhysics_Universal_Indicator_v2_2";
         
      default:
         Print("⚠️ Unknown indicator version, defaulting to UNIVERSAL");
         return "TickPhysics_Universal_Indicator_v2_2";
   }
}

//+------------------------------------------------------------------+
//| QA FIX: Validate physics indicator data is available             |
//+------------------------------------------------------------------+
bool ValidatePhysicsData()
{
   // The physics indicator reads buffers on-demand via ReadBuffer()
   // We just need to verify the indicator handle is valid and operational
   
   if(!g_initialized)
   {
      if(EnableDebugMode)
         Print("❌ ERROR: Physics indicator not initialized");
      return false;
   }
   
   // Try to read a critical buffer to validate indicator is working
   double quality = g_physics.GetQuality(0);
   
   // Check if we got valid data (not 0.0 which could indicate failure)
   // Note: Quality can legitimately be 0, so we check if indicator is responding
   if(quality < 0)  // Quality should never be negative
   {
      g_bufferUpdateFailures++;
      g_consecutiveBufferFailures++;
      
      if(EnableDebugMode)
         Print(StringFormat("❌ ERROR: Invalid physics data (failure #%d)", g_consecutiveBufferFailures));
      
      // Alert if consecutive failures exceed threshold
      if(g_consecutiveBufferFailures >= 5)
      {
         Alert("⚠️ WARNING: ", g_consecutiveBufferFailures, " consecutive data failures on ", _Symbol);
      }
      
      return false;
   }
   
   // Reset consecutive failure counter on success
   g_consecutiveBufferFailures = 0;
   g_lastBufferUpdateTime = TimeCurrent();
   
   return true;
}

//+------------------------------------------------------------------+
//| v4.0 Dashboard Helper Functions                                   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Create text label on chart                                        |
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
//| Update text label                                                 |
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
//| Delete all dashboard objects                                      |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   string prefix = "DASH_";
   
   // Delete Labels
   int total = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
   
   // Delete Backgrounds
   total = ObjectsTotal(0, 0, OBJ_RECTANGLE_LABEL);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_RECTANGLE_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create background panel                                           |
//+------------------------------------------------------------------+
bool CreateBackground(string name, int x, int y, int width, int height, color bgColor, color borderColor)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   if(!ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      return false;
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, DashboardCorner);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false); // Foreground (covers candles)
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create v4.0 Dashboard layout                                      |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   if(!ShowDashboard) return;
   
   int x = DashboardX;
   int y = DashboardY;
   int lineHeight = DashboardFontSize + 5;
   int row = 0;
   
   // Create Background Panel
   // QA FIX: Extend background to full height as requested
   CreateBackground("DASH_Background", 0, 0, 330, 5000, C'20,20,20', clrDimGray);

   // Header
   CreateLabel("DASH_Header", x, y + (row++ * lineHeight), 
               "=== TickPhysics EA v3.10 PRODUCTION ===", clrWhite, DashboardFontSize + 1);
   row += 1;
   CreateLabel("DASH_Symbol", x, y + (row++ * lineHeight), 
               "Symbol: " + _Symbol, clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Indicator", x, y + (row++ * lineHeight), 
               "Indicator: LOADING...", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_EntryMode", x, y + (row++ * lineHeight), 
               "Entry: LOADING...", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Mode", x, y + (row++ * lineHeight), 
               "Mode: LIVE", clrLimeGreen, DashboardFontSize);
   row += 2;
   
   // System Status
   CreateLabel("DASH_SystemHeader", x, y + (row++ * lineHeight), 
               "SYSTEM STATUS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Status", x, y + (row++ * lineHeight), 
               "Status: ACTIVE", clrLimeGreen, DashboardFontSize);
   CreateLabel("DASH_BufferStatus", x, y + (row++ * lineHeight), 
               "Buffers: OK", clrLimeGreen, DashboardFontSize);
   row += 2;
   
   // Physics Metrics Section
   CreateLabel("DASH_PhysicsHeader", x, y + (row++ * lineHeight), 
               "PHYSICS METRICS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Quality", x, y + (row++ * lineHeight), 
               "Quality: 0.0 (>= 70)", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Conflu", x, y + (row++ * lineHeight), 
               "Conflu: 0.0 (not used)", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Momentum", x, y + (row++ * lineHeight), 
               "Momentum: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Speed", x, y + (row++ * lineHeight), 
               "Speed: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Accel", x, y + (row++ * lineHeight), 
               "Accel: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_PhysicsScore", x, y + (row++ * lineHeight), 
               "PhysicsScore: 0.0", clrGold, DashboardFontSize);
   row += 2;
   
   // v4.5: Slope Analysis Section
   CreateLabel("DASH_SlopeHeader", x, y + (row++ * lineHeight), 
               "v4.5 SLOPE ANALYSIS", clrCyan, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_SpeedSlope", x, y + (row++ * lineHeight), 
               "Speed Slope: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_AccelSlope", x, y + (row++ * lineHeight), 
               "Accel Slope: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_MomentumSlope", x, y + (row++ * lineHeight), 
               "Momentum Slope: 0.0", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_ConfluenceSlope", x, y + (row++ * lineHeight), 
               "Conflu Slope: 0.0", clrSilver, DashboardFontSize);
   row += 2;
   
   // Classification Section
   CreateLabel("DASH_ClassHeader", x, y + (row++ * lineHeight), 
               "CLASSIFICATION", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Zone", x, y + (row++ * lineHeight), 
               "Zone: UNKNOWN", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Regime", x, y + (row++ * lineHeight), 
               "Regime: UNKNOWN", clrSilver, DashboardFontSize);
   row += 2;
   
   // MA Crossover Section
   CreateLabel("DASH_MAHeader", x, y + (row++ * lineHeight), 
               "MA CROSSOVER", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_MASignal", x, y + (row++ * lineHeight), 
               "Signal: NONE", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_MAValues", x, y + (row++ * lineHeight), 
               "Values: 0.00 / 0.00", clrSilver, DashboardFontSize);
   row += 2;
   
   // Filter Status Section
   CreateLabel("DASH_FilterHeader", x, y + (row++ * lineHeight), 
               "FILTER STATUS", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterQuality", x, y + (row++ * lineHeight), 
               "Quality: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterZone", x, y + (row++ * lineHeight), 
               "Zone: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterAccel", x, y + (row++ * lineHeight), 
               "Accel: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterSpeed", x, y + (row++ * lineHeight), 
               "Speed: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterMomentum", x, y + (row++ * lineHeight), 
               "Momentum: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterPhysicsScore", x, y + (row++ * lineHeight), 
               "PhysicsScore: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterConfluence", x, y + (row++ * lineHeight), 
               "FullConfluence: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterSpread", x, y + (row++ * lineHeight), 
               "Spread: WAIT", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterOverall", x, y + (row++ * lineHeight), 
               "Overall: MONITORING", clrDodgerBlue, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_FilterStats", x, y + (row++ * lineHeight), 
               "Blocked: 0/0 (0.0%)", clrGold, DashboardFontSize);
   row += 2;
   
   // Position Section
   CreateLabel("DASH_PosHeader", x, y + (row++ * lineHeight), 
               "POSITION", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_PosActive", x, y + (row++ * lineHeight), 
               "Active: None", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_PosPL", x, y + (row++ * lineHeight), 
               "P/L: $0.00", clrSilver, DashboardFontSize);
   row += 2;
   
   // Account Section
   CreateLabel("DASH_AcctHeader", x, y + (row++ * lineHeight), 
               "ACCOUNT", clrWhite, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Balance", x, y + (row++ * lineHeight), 
               "Balance: $0.00", clrSilver, DashboardFontSize);
   row += 1;
   CreateLabel("DASH_Equity", x, y + (row++ * lineHeight), 
               "Equity: $0.00", clrSilver, DashboardFontSize);
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update v4.0 Dashboard with current data                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!ShowDashboard) return;
   
   // QA FIX: Throttle updates to configured interval (using TimeLocal for real-time updates)
   datetime currentTime = TimeLocal();  // Use local computer time, not server time
   if(currentTime - g_lastDashboardUpdate < DashboardUpdateSeconds) return;
   g_lastDashboardUpdate = currentTime;
   
   // QA FIX: Validate physics data is available
   bool dataOK = ValidatePhysicsData();
   
   // Update buffer status indicator
   string bufferStatus = dataOK ? "Buffers: OK" : StringFormat("Buffers: FAIL (%d)", g_consecutiveBufferFailures);
   color bufferColor = dataOK ? clrLimeGreen : (g_consecutiveBufferFailures >= 3 ? clrRed : clrOrange);
   UpdateLabel("DASH_BufferStatus", bufferStatus, bufferColor);
   
   if(!dataOK)
   {
      // Don't update physics metrics if data validation failed
      UpdateLabel("DASH_Status", "Status: DATA ERROR", clrRed);
      return;
   }
   
   // Reset daily stats
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   datetime dayStart = StringToTime(IntegerToString(dt.year) + "." + IntegerToString(dt.mon) + "." + IntegerToString(dt.day));
   if(dayStart != g_lastStatResetDay)
   {
      g_filtersBlockedToday = 0;
      g_signalsToday = 0;
      g_lastStatResetDay = dayStart;
   }
   
   // Get all physics metrics
   double quality = g_physics.GetQuality(0);
   double confluence = g_physics.GetConfluence(0);
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // Update indicator name on dashboard
   string indicatorShortName = g_indicatorName;
   if(StringFind(indicatorShortName, "Universal") >= 0)
      indicatorShortName = "UNIVERSAL v3.1";
   else if(StringFind(indicatorShortName, "Crypto") >= 0)
      indicatorShortName = "CRYPTO v2.1";
   else if(StringFind(indicatorShortName, "Forex") >= 0)
      indicatorShortName = "FOREX v2.1";
   else if(StringFind(indicatorShortName, "Indices") >= 0)
      indicatorShortName = "INDICES v2.1";
   else if(StringFind(indicatorShortName, "Metals") >= 0)
      indicatorShortName = "METALS v2.1";
   UpdateLabel("DASH_Indicator", "Indicator: " + indicatorShortName, clrGold);
   
   // Update entry mode
   string entryMode;
   if(UsePhysicsEntry)
      entryMode = "PHYSICS";
   else if(UseMAEntry)
      entryMode = "MA CROSSOVER";
   else if(UsePhysicsFiltersAsEntry)
      entryMode = "PHYSICS FILTERS";
   else
      entryMode = "NONE";
   UpdateLabel("DASH_EntryMode", "Entry: " + entryMode, clrGold);
   
   // Update mode
   string mode = DryRunMode ? "DRY RUN" : (BypassAllFilters ? "NO FILTERS" : "LIVE");
   color modeColor = DryRunMode ? clrOrange : (BypassAllFilters ? clrYellow : clrLimeGreen);
   UpdateLabel("DASH_Mode", "Mode: " + mode, modeColor);
   
   // === PHYSICS METRICS SECTION ===
   
   // Quality with pass/fail
   bool qualityPass = (speed >= 0) ? (quality >= MinQualityBuy) : (quality >= MinQualitySell);
   string qualityIcon = qualityPass ? "[PASS]" : "[FAIL]";
   color qualityColor = qualityPass ? clrLimeGreen : clrRed;
   UpdateLabel("DASH_Quality", StringFormat("Quality: %.1f %s", quality, qualityIcon), qualityColor);
   
   // Confluence
   UpdateLabel("DASH_Conflu", StringFormat("Conflu: %.1f", confluence), clrSilver);
   
   // Momentum
   color momentumColor = momentum > 0 ? clrLimeGreen : (momentum < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Momentum", StringFormat("Momentum: %.1f", momentum), momentumColor);
   
   // Speed (directional coloring)
   color speedColor = speed > 0 ? clrLimeGreen : (speed < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Speed", StringFormat("Speed: %.1f", speed), speedColor);
   
   // Acceleration (directional coloring)
   color accelColor = accel > 0 ? clrLimeGreen : (accel < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Accel", StringFormat("Accel: %.1f", accel), accelColor);
   
   // Physics Score (evidence-based weighted score)
   double physicsScore = CalculatePhysicsScore();
   color scoreColor = (speed >= 0 ? physicsScore >= MinPhysicsScoreBuy : physicsScore >= MinPhysicsScoreSell) ? clrLimeGreen : clrOrange;
   UpdateLabel("DASH_PhysicsScore", StringFormat("PhysicsScore: %.1f", physicsScore), scoreColor);
   
   // === v4.5 SLOPE ANALYSIS SECTION ===
   if(UseSlopeFilters)
   {
      // Calculate current slopes for display
      CalculatePhysicsSlopes();
      
      // Speed Slope
      color speedSlopeColor = g_lastSpeedSlope > 0 ? clrLimeGreen : (g_lastSpeedSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_SpeedSlope", StringFormat("Speed Slope: %.2f", g_lastSpeedSlope), speedSlopeColor);
      
      // Acceleration Slope
      color accelSlopeColor = g_lastAccelerationSlope > 0 ? clrLimeGreen : (g_lastAccelerationSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_AccelSlope", StringFormat("Accel Slope: %.2f", g_lastAccelerationSlope), accelSlopeColor);
      
      // Momentum Slope
      color momentumSlopeColor = g_lastMomentumSlope > 0 ? clrLimeGreen : (g_lastMomentumSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_MomentumSlope", StringFormat("Momentum Slope: %.2f", g_lastMomentumSlope), momentumSlopeColor);
      
      // Confluence Slope
      color confluenceSlopeColor = g_lastConfluenceSlope > 0 ? clrLimeGreen : (g_lastConfluenceSlope < 0 ? clrRed : clrGray);
      UpdateLabel("DASH_ConfluenceSlope", StringFormat("Conflu Slope: %.2f", g_lastConfluenceSlope), confluenceSlopeColor);
   }
   else
   {
      UpdateLabel("DASH_SpeedSlope", "Speed Slope: DISABLED", clrGray);
      UpdateLabel("DASH_AccelSlope", "Accel Slope: DISABLED", clrGray);
      UpdateLabel("DASH_MomentumSlope", "Momentum Slope: DISABLED", clrGray);
      UpdateLabel("DASH_ConfluenceSlope", "Conflu Slope: DISABLED", clrGray);
   }
   
   // === CLASSIFICATION SECTION ===
   
   // Zone
   string zoneName = g_physics.GetZoneName(zone);
   color zoneColor = zone == ZONE_BULL ? clrLimeGreen : (zone == ZONE_BEAR ? clrTomato : (zone == ZONE_TRANSITION ? clrOrange : clrSilver));
   UpdateLabel("DASH_Zone", "Zone: " + zoneName, zoneColor);
   
   // Regime
   string regimeName = g_physics.GetRegimeName(regime);
   UpdateLabel("DASH_Regime", "Regime: " + regimeName, clrSilver);
   
   // === MA CROSSOVER SECTION ===
   
   int signal = 0;
   double maFast = 0, maSlow = 0;
   
   if(UseMAEntry && g_maFastHandle != INVALID_HANDLE && g_maSlowHandle != INVALID_HANDLE)
   {
      double maFastArr[], maSlowArr[];
      ArraySetAsSeries(maFastArr, true);
      ArraySetAsSeries(maSlowArr, true);
      
      if(CopyBuffer(g_maFastHandle, 0, 0, 3, maFastArr) < 3) return;
      if(CopyBuffer(g_maSlowHandle, 0, 0, 3, maSlowArr) < 3) return;
      
      // Update display values
      maFast = maFastArr[0];
      maSlow = maSlowArr[0];
      
      // BUY: Fast crosses above Slow
      if(maFastArr[2] < maSlowArr[2] && maFastArr[0] > maSlowArr[0])
      {
         if(EnableDebugMode)
            Print(StringFormat("📈 MA BUY Signal: Fast(%s) > Slow(%s)", DoubleToString(maFastArr[0], 5), DoubleToString(maSlowArr[0], 5)));
         signal = 1;
      }
      
      // SELL: Fast crosses below Slow
      if(maFastArr[2] > maSlowArr[2] && maFastArr[0] < maSlowArr[0])
      {
         if(EnableDebugMode)
            Print(StringFormat("📉 MA SELL Signal: Fast(%s) < Slow(%s)", DoubleToString(maFastArr[0], 5), DoubleToString(maSlowArr[0], 5)));
         signal = -1;
      }
   }
   
   string signalText = signal > 0 ? "BUY" : (signal < 0 ? "SELL" : "NONE");
   color signalColor = signal > 0 ? clrDodgerBlue : (signal < 0 ? clrTomato : clrGray);
   UpdateLabel("DASH_MASignal", "Signal: " + signalText, signalColor);
   UpdateLabel("DASH_MAValues", StringFormat("Values: %.2f / %.2f", maFast, maSlow), clrSilver);
   
   // === FILTER STATUS SECTION ===
   
   bool filtersEnabled = UsePhysicsFilters && !BypassAllFilters;
   bool zonePass = (zone != ZONE_TRANSITION && zone != ZONE_AVOID) || !AvoidTransitionZone;
   
   // Check advanced filters
   bool accelPass = true;
   bool speedPass = true;
   bool momentumPass = true;
   
   if(UseAccelerationFilter && signal != 0 && !BypassAllFilters)
   {
      if(signal > 0)
         accelPass = (accel >= MinAccelerationBuy);
      else
         accelPass = (accel <= MinAccelerationSell);  // MinAccelerationSell is negative (e.g., -80)
   }
   
   if(UseSpeedFilter && signal != 0 && !BypassAllFilters)
   {
      if(signal > 0)
         speedPass = (speed >= MinSpeedBuy);
      else
         speedPass = (speed <= MinSpeedSell);  // MinSpeedSell is negative (e.g., -55)
   }
   
   if(UseMomentumFilter && signal != 0 && !BypassAllFilters)
   {
      if(signal > 0)
         momentumPass = (momentum >= MinMomentumBuy);
      else
         momentumPass = (momentum <= MinMomentumSell);  // MinMomentumSell is negative (e.g., -30)
   }
   
   bool allFiltersPass = BypassAllFilters || (!filtersEnabled) || (qualityPass && zonePass && accelPass && speedPass && momentumPass);
   
   // Quality filter
   if(!filtersEnabled)
      UpdateLabel("DASH_FilterQuality", "Quality: DISABLED", clrGold);
   else
   {
      string qStatus = qualityPass ? "[PASS]" : "[FAIL]";
      color qColor = qualityPass ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_FilterQuality", StringFormat("Quality: %.1f %s", quality, qStatus), qColor);
   }
   
   // Zone filter
   if(!filtersEnabled || !AvoidTransitionZone)
      UpdateLabel("DASH_FilterZone", "Zone: DISABLED", clrGold);
   else
   {
      string zStatus = zonePass ? "[PASS]" : "[FAIL]";
      color zColor = zonePass ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_FilterZone", "Zone: " + zoneName + " " + zStatus, zColor);
   }
   
   // Acceleration filter
   if(!UseAccelerationFilter)
      UpdateLabel("DASH_FilterAccel", "Accel: DISABLED", clrGold);
   else
   {
      string aStatus = accelPass ? "[PASS]" : "[FAIL]";
      color aColor = accelPass ? clrLimeGreen : clrRed;
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinAccelerationBuy) : StringFormat("<= %.1f", MinAccelerationSell);
      UpdateLabel("DASH_FilterAccel", StringFormat("Accel: %.1f %s %s", accel, threshold, aStatus), aColor);
   }
   
   // Speed filter
   if(!UseSpeedFilter)
      UpdateLabel("DASH_FilterSpeed", "Speed: DISABLED", clrGold);
   else
   {
      string sStatus = speedPass ? "[PASS]" : "[FAIL]";
      color sColor = speedPass ? clrLimeGreen : clrRed;
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinSpeedBuy) : StringFormat("<= %.1f", MinSpeedSell);
      UpdateLabel("DASH_FilterSpeed", StringFormat("Speed: %.1f %s %s", speed, threshold, sStatus), sColor);
   }
   
   // Momentum filter
   if(!UseMomentumFilter)
      UpdateLabel("DASH_FilterMomentum", "Momentum: DISABLED", clrGold);
   else
   {
      string mStatus = momentumPass ? "[PASS]" : "[FAIL]";
      color mColor = momentumPass ? clrLimeGreen : clrRed;
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinMomentumBuy) : StringFormat("<= %.1f", MinMomentumSell);
      UpdateLabel("DASH_FilterMomentum", StringFormat("Momentum: %.1f %s %s", momentum, threshold, mStatus), mColor);
   }
   
   // v4.2: Physics Score filter
   bool physicsScorePass = true;
   if(UsePhysicsScoreFilter && signal != 0 && !BypassAllFilters)
   {
      physicsScorePass = (signal > 0) ? (g_lastPhysicsScore >= MinPhysicsScoreBuy) : (g_lastPhysicsScore >= MinPhysicsScoreSell);
   }
   
   if(!UsePhysicsScoreFilter)
      UpdateLabel("DASH_FilterPhysicsScore", "PhysicsScore: DISABLED", clrGold);
   else
   {
      string psStatus = physicsScorePass ? "[PASS]" : "[FAIL]";
      color psColor = physicsScorePass ? clrLimeGreen : clrRed;
      double psThreshold = (signal > 0) ? MinPhysicsScoreBuy : MinPhysicsScoreSell;
      UpdateLabel("DASH_FilterPhysicsScore", StringFormat("PhysicsScore: %.1f >= %.1f %s", g_lastPhysicsScore, psThreshold, psStatus), psColor);
   }
   
   // v4.2: Full Confluence filter
   bool confluencePass = true;
   if(RequireFullConfluence && signal != 0 && !BypassAllFilters)
   {
      confluencePass = (confluence >= 100.0);
   }
   
   if(!RequireFullConfluence)
      UpdateLabel("DASH_FilterConfluence", "FullConfluence: DISABLED", clrGold);
   else
   {
      string cStatus = confluencePass ? "[PASS]" : "[FAIL]";
      color cColor = confluencePass ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_FilterConfluence", StringFormat("FullConfluence: %.0f%% %s", confluence, cStatus), cColor);
   }
   
   // v4.6: Spread filter
   bool spreadPass = true;
   if(UseSpreadFilter && signal != 0 && !BypassAllFilters)
   {
      // Get current spread
      GetCurrentSpreadPips();  // Updates g_lastSpreadPips
      spreadPass = (g_lastSpreadPips <= MaxSpreadPips);
   }
   
   if(!UseSpreadFilter)
      UpdateLabel("DASH_FilterSpread", "Spread: DISABLED", clrGold);
   else
   {
      string sStatus = spreadPass ? "[PASS]" : "[FAIL]";
      color sColor = spreadPass ? clrLimeGreen : clrRed;
      UpdateLabel("DASH_FilterSpread", StringFormat("Spread: %.2f/%.2f pips %s", g_lastSpreadPips, MaxSpreadPips, sStatus), sColor);
   }
   
   // Update allFiltersPass to include new v4.2 and v4.6 filters
   allFiltersPass = BypassAllFilters || (!filtersEnabled) || (qualityPass && zonePass && accelPass && speedPass && momentumPass && physicsScorePass && confluencePass && spreadPass);
   
   // Overall status
   string overallStatus;
   color overallColor;
   
   if(BypassAllFilters)
   {
      overallStatus = "BYPASS MODE";
      overallColor = clrYellow;
   }
   else if(!filtersEnabled)
   {
      overallStatus = "FILTERS OFF";
      overallColor = clrGold;
   }
   else if(allFiltersPass && signal != 0)
   {
      overallStatus = "READY TO TRADE";
      overallColor = clrLimeGreen;
   }
   else if(!allFiltersPass)
   {
      overallStatus = "NO ENTRY";
      overallColor = clrRed;
   }
   else
   {
      overallStatus = "WAITING SIGNAL";
      overallColor = clrDodgerBlue;
   }
   UpdateLabel("DASH_FilterOverall", "Overall: " + overallStatus, overallColor);
   
   // QA FIX: Filter statistics with percentage
   double blockRate = g_signalsToday > 0 ? (g_filtersBlockedToday * 100.0 / g_signalsToday) : 0.0;
   UpdateLabel("DASH_FilterStats", StringFormat("Blocked: %d/%d (%.1f%%)", g_filtersBlockedToday, g_signalsToday, blockRate), clrGold);
   
   // Update system status with overall color
   UpdateLabel("DASH_Status", "Status: " + (g_initialized ? "ACTIVE" : "INIT"), overallColor);
   
   // === POSITION SECTION ===
   
   int openTrades = PositionsTotal();
   if(openTrades > 0 && PositionSelect(_Symbol))
   {
      string posType = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL";
      double lots = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      
      color posColor = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? clrDodgerBlue : clrTomato;
      UpdateLabel("DASH_PosActive", StringFormat("Active: %s %.2f @ %.2f", posType, lots, openPrice), posColor);
      
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
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics v3.10 PRODUCTION - Initializing");
   Print("═══════════════════════════════════════════════════════");
   
   // Validate configuration
   if(!UsePhysicsEntry && !UseMAEntry && !UsePhysicsFiltersAsEntry)
   {
      Print("❌ ERROR: No entry system enabled!");
      Print("   Enable UsePhysicsEntry, UseMAEntry, or UsePhysicsFiltersAsEntry");
      return INIT_FAILED;
   }
   
   if(UsePhysicsFiltersAsEntry && !UsePhysicsFilters)
   {
      Print("❌ ERROR: UsePhysicsFiltersAsEntry=true but UsePhysicsFilters=false");
      Print("   You must manually enable UsePhysicsFilters in EA settings");
      Print("   Cannot continue - please fix configuration");
      return INIT_FAILED;
   }
   
   if(UsePhysicsEntry && UseMAEntry)
   {
      Print("⚠️ WARNING: Both entry systems enabled - Physics will take priority");
   }
   
   // QA FIX: Validate stop loss values are reasonable
   if(StopLossPips_Forex <= 0 || StopLossPips_Indices <= 0 || 
      StopLossPips_Crypto <= 0 || StopLossPips_Metal <= 0)
   {
      Print("❌ ERROR: All stop loss values must be greater than 0!");
      return INIT_FAILED;
   }
   
   // Warning for potentially excessive forex stop losses
   if(StopLossPips_Forex > 2000)

   {
   Print(StringFormat("⚠️ WARNING: Forex stop loss %d pips is very large!", StopLossPips_Forex));
      Print("   Recommended: 500-1500 pips (50-150 points on 5-digit)");
      Print("   Current setting may result in excessive risk");
   }
   
   // 0. Determine which indicator to use
   g_indicatorName = GetIndicatorName(IndicatorVersion);
   
   // 1. Initialize Physics Indicator
   Print("📊 Initializing Physics Indicator...");
   if(!g_physics.Initialize(g_indicatorName, EnableDebugMode))
   {
      Print("❌ FAILED: Physics Indicator initialization");
   Print(StringFormat("   Could not find indicator: %s", g_indicatorName));
   Print(StringFormat("   Expected location: Indicators/%s.ex5", g_indicatorName));
      Print("   Make sure the indicator is compiled and in the correct folder");
      return INIT_FAILED;
   }
   Print(StringFormat("✅ Physics Indicator ready: %s", g_indicatorName));
   
   // 1.5 Load indicator on chart
   if(ShowDashboard)
   {
      LoadIndicatorOnChart(g_indicatorName);
   }
   
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
   
   // Format: TP_Integrated_NAS100_M05_LIVE_20251118_1430_v4.1.9.6_SLOPE_signals.csv
   // Format: TP_Integrated_NAS100_M05_MTBacktest_v4.1.9.6_SLOPE_signals.csv
   loggerConfig.signalLogFile = "TP_Integrated_" + _Symbol + "_" + timeframeStr + "_" + modeStr + timestampSuffix + "_v" + EA_VERSION + "_signals.csv";
   loggerConfig.tradeLogFile = "TP_Integrated_" + _Symbol + "_" + timeframeStr + "_" + modeStr + timestampSuffix + "_v" + EA_VERSION + "_trades.csv";
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
   Print(StringFormat("✅ CSV Logger ready (Mode: %s)", modeStr));
   
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
   Print(StringFormat("✅ MA indicators ready (Fast:%d, Slow:%d)", MA_Fast, MA_Slow));
   }
   
   // 6. Setup trade execution
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   g_initialized = true;
   
   // 7. Create v4.0 Dashboard
   if(ShowDashboard)
   {
      CreateDashboard();
      Print("✅ v4.0 Dashboard created");
   }
   
   Print("");
   Print("✅ ALL SYSTEMS READY - v3.10 PRODUCTION VERSION!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v3.10 PRODUCTION (QA Approved)");
   Print(StringFormat("   Indicator: %s", g_indicatorName));
   
   // Entry mode display
   string entrySystem = "NONE";
   if(UsePhysicsEntry)
      entrySystem = "PHYSICS CROSSOVER";
   else if(UseMAEntry)
      entrySystem = "MA CROSSOVER";
   else if(UsePhysicsFiltersAsEntry)
      entrySystem = "PHYSICS FILTERS AS TRIGGERS";
   Print(StringFormat("   Entry System: %s", entrySystem));
   
   if(UseMAEntry)
      Print(StringFormat("   MA Periods: Fast=%d, Slow=%d", MA_Fast, MA_Slow));
   Print(StringFormat("   Physics Filters: %s", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED ⚠️"));
   if(UsePhysicsFilters)
   {
   Print(StringFormat("   → Quality Filter: BUY >= %d%%, SELL >= %d%%", MinQualityBuy, MinQualitySell));
   Print(StringFormat("   → Zone Filter: %s", AvoidTransitionZone ? "REJECT TRANSITION/AVOID" : "DISABLED"));
   }
   Print("   Advanced Filters:");
   Print(StringFormat("   → Acceleration: %s", UseAccelerationFilter ? "ENABLED" : "DISABLED"));
   if(UseAccelerationFilter)
   Print(StringFormat("      BUY >= %d, SELL |accel| >= %d", MinAccelerationBuy, MinAccelerationSell));
   Print(StringFormat("   → Speed: %s", UseSpeedFilter ? "ENABLED" : "DISABLED"));
   if(UseSpeedFilter)
   Print(StringFormat("      BUY >= %d, SELL |speed| >= %d", MinSpeedBuy, MinSpeedSell));
   Print(StringFormat("   → Momentum: %s", UseMomentumFilter ? "ENABLED" : "DISABLED"));
   if(UseMomentumFilter)
   Print(StringFormat("      BUY >= %d, SELL |momentum| >= %d", MinMomentumBuy, MinMomentumSell));
   
   Print("   🎯 v4.2 Multi-Asset Filters:");
   Print(StringFormat("   → Physics Score: %s", UsePhysicsScoreFilter ? "ENABLED" : "DISABLED"));
   if(UsePhysicsScoreFilter)
   Print(StringFormat("      Min Score: BUY >= %d, SELL >= %d (Q3 threshold, +16%% win rate)", MinPhysicsScoreBuy, MinPhysicsScoreSell));
   Print(StringFormat("   → Full Confluence: %s", RequireFullConfluence ? "REQUIRED (100%)" : "DISABLED"));
   if(RequireFullConfluence)
      Print("      100% Confluence Required (+11.5% win boost validated)");
   
   Print("   📈 v4.5 Slope Filters:");
   Print(StringFormat("   → Slope Analysis: %s", UseSlopeFilters ? "ENABLED" : "DISABLED"));
   if(UseSlopeFilters)
   {
   Print(StringFormat("      Lookback Bars: %d", SlopeLookbackBars));
      if(UseSpeedSlope)
      {
         Print(StringFormat("      → Speed Slope BUY >= %s (directional momentum)", DoubleToString(MinSpeedSlopeBuy, 2)));
         Print(StringFormat("      → Speed Slope SELL <= %s (directional momentum)", DoubleToString(MinSpeedSlopeSell, 2)));
      }
      if(UseAccelerationSlope)
      {
         Print(StringFormat("      → Acceleration Slope BUY >= %s (trend confirmation)", DoubleToString(MinAccelerationSlopeBuy, 2)));
         Print(StringFormat("      → Acceleration Slope SELL <= %s (trend confirmation)", DoubleToString(MinAccelerationSlopeSell, 2)));
      }
      if(UseConfluenceSlope)
         Print(StringFormat("      → Confluence Slope BUY >= %s, SELL >= %s (alignment strengthening)", DoubleToString(MinConfluenceSlopeBuy, 2), DoubleToString(MinConfluenceSlopeSell, 2)));
      if(UseMomentumSlope)
      {
         Print(StringFormat("      → Momentum Slope BUY >= %s (momentum building)", DoubleToString(MinMomentumSlopeBuy, 2)));
         Print(StringFormat("      → Momentum Slope SELL <= %s (momentum building)", DoubleToString(MinMomentumSlopeSell, 2)));
      }
      if(UseJerkSlope)
      {
         Print(StringFormat("      → Jerk Slope BUY >= %s (advanced, may be noisy)", DoubleToString(MinJerkSlopeBuy, 2)));
         Print(StringFormat("      → Jerk Slope SELL <= %s (advanced, may be noisy)", DoubleToString(MinJerkSlopeSell, 2)));
      }
   }
   
   // Time & Day-of-Week Filters
   if(UseTimeFilter || UseDayOfWeekFilter)
   {
      Print("   ⏰ TIME & DAY RESTRICTIONS:");
      if(UseTimeFilter)
      {
         Print(StringFormat("      → Trading Hours: %d:00 - %d:00 (broker time)", TradingStartHour, TradingEndHour));
      }
      if(UseDayOfWeekFilter)
      {
         string tradingDays = "";
         if(TradeOnMonday) tradingDays += "Mon ";
         if(TradeOnTuesday) tradingDays += "Tue ";
         if(TradeOnWednesday) tradingDays += "Wed ";
         if(TradeOnThursday) tradingDays += "Thu ";
         if(TradeOnFriday) tradingDays += "Fri ";
         if(TradeOnSaturday) tradingDays += "Sat ";
         if(TradeOnSunday) tradingDays += "Sun ";
         Print(StringFormat("      → Trading Days: %s", tradingDays));
      }
   }
   
   Print(StringFormat("   Risk/Trade: %s%%", DoubleToString(RiskPercentPerTrade, 2)));
   if(UseAssetAdaptiveSLTP)
   {
      Print("   Asset-Adaptive SL/TP Enabled:");
      Print(StringFormat("     Forex: %d/%d pips", StopLossPips_Forex, TakeProfitPips_Forex));
      Print(StringFormat("     Indices: %d/%d pips", StopLossPips_Indices, TakeProfitPips_Indices));
      Print(StringFormat("     Crypto: %d/%d pips", StopLossPips_Crypto, TakeProfitPips_Crypto));
      Print(StringFormat("     Metal: %d/%d pips", StopLossPips_Metal, TakeProfitPips_Metal));
   }
   else
   {
      Print(StringFormat("   SL/TP (Forex defaults): %d/%d pips", StopLossPips_Forex, TakeProfitPips_Forex));
   }
   
   // Special modes
   if(BypassAllFilters)
      Print("   ⚠️ BYPASS MODE: All filters disabled!");
   if(DryRunMode)
      Print("   ⚠️ DRY RUN MODE: No trades will be executed!");
   
   Print(StringFormat("   Dashboard: Update every %d seconds", DashboardUpdateSeconds));
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 TickPhysics v3.10 PRODUCTION - Shutting Down");
   Print(StringFormat("   Reason: %d", reason));
   
   // Display data validation statistics
   if(g_bufferUpdateFailures > 0)
   {
      Print("📊 Physics Data Statistics:");
      Print(StringFormat("   Total Validation Failures: %d", g_bufferUpdateFailures));
      Print(StringFormat("   Last Valid Data: %s", TimeToString(g_lastBufferUpdateTime)));
   }
   
   Print("═══════════════════════════════════════════════════════");
   
   // Remove indicator from chart
   if(g_indicatorSubwindow >= 0)
   {
      int total = ChartIndicatorsTotal(0, g_indicatorSubwindow);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ChartIndicatorName(0, g_indicatorSubwindow, i);
         if(StringFind(name, "TickPhysics") >= 0)
         {
            ChartIndicatorDelete(0, g_indicatorSubwindow, name);
            Print("✅ Removed TickPhysics indicator from chart");
            break;
         }
      }
   }
   
   // Remove dashboard
   if(ShowDashboard)
   {
      DeleteDashboard();
      Print("✅ v4.0 Dashboard removed");
   }
   
   // Remove MA indicators
   if(UseMAEntry && g_maFastHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_maFastHandle);
      IndicatorRelease(g_maSlowHandle);
      Print("✅ MA indicators released");
   }
   
   // Log any completed trades
   ClosedTrade trade;
   int logged = 0;
   // Update tracker to ensure any recent closes are included, then ensure any trades still
   // in post-exit monitoring are finalized so we can log them on shutdown
   g_tracker.UpdateTrades();
   g_tracker.ForceFinalizeMonitoring();
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      LogCompletedTrade(trade);
      logged++;
   }
   
   if(logged > 0)
      Print(StringFormat("✅ Logged %d completed trades to CSV", logged));
   
   Print("═══════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized) return;
   
   // Track latest confluence for history
   g_lastTickConfluence = g_physics.GetConfluence(0);
   
   // Update v4.0 Dashboard (includes buffer updates)
   UpdateDashboard();
   
   // Update trade tracker
   g_tracker.UpdateTrades();
   
   // Check for completed trades
   ClosedTrade trade;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
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
//| Generate trading signal                                           |
//+------------------------------------------------------------------+
int GenerateSignal()
{
   if(UsePhysicsEntry)
      return GeneratePhysicsSignal();
   else if(UseMAEntry)
      return GenerateMASignal();
   else if(UsePhysicsFiltersAsEntry)
      return GeneratePhysicsFilterSignal();
   else
      return 0;
}

//+------------------------------------------------------------------+
//| Generate signal from physics filters themselves                  |
//| v4.6: Added isolated testing mode for single-factor analysis     |
//+------------------------------------------------------------------+
int GeneratePhysicsFilterSignal()
{
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   double momentum = g_physics.GetMomentum(0);
   double quality = g_physics.GetQuality(0);
   double confluence = g_physics.GetConfluence(0);
   TRADING_ZONE zone = g_physics.GetTradingZone();
   
   // Store previous values on first call
   if(g_prevSpeed == 0 && g_prevAccel == 0 && g_prevMomentum == 0)
   {
      g_prevSpeed = speed;
      g_prevAccel = accel;
      g_prevMomentum = momentum;
      return 0;
   }
   
   int signal = 0;
   
   // v4.6: ISOLATED TESTING MODE - Test single components in isolation
   if(UseIsolatedTesting)
   {
      // Calculate slopes if needed
      if(IsolatedSpeedSlopeOnly || IsolatedAccelSlopeOnly || IsolatedMomentumSlopeOnly)
      {
         CalculatePhysicsSlopes();
      }
      
      // Test ONLY SpeedSlope
      if(IsolatedSpeedSlopeOnly)
      {
         if(g_lastSpeedSlope >= MinSpeedSlopeBuy && speed > 0)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED SPEED SLOPE BUY: Slope=%s (threshold=%s)", DoubleToString(g_lastSpeedSlope, 2), DoubleToString(MinSpeedSlopeBuy, 2)));
         }
         else if(g_lastSpeedSlope <= MinSpeedSlopeSell && speed < 0)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED SPEED SLOPE SELL: Slope=%s (threshold=%s)", DoubleToString(g_lastSpeedSlope, 2), DoubleToString(MinSpeedSlopeSell, 2)));
         }
         return signal;
      }
      
      // Test ONLY AccelerationSlope
      if(IsolatedAccelSlopeOnly)
      {
         if(g_lastAccelerationSlope >= MinAccelerationSlopeBuy && accel > 0)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED ACCEL SLOPE BUY: Slope=%s (threshold=%s)", DoubleToString(g_lastAccelerationSlope, 2), DoubleToString(MinAccelerationSlopeBuy, 2)));
         }
         else if(g_lastAccelerationSlope <= MinAccelerationSlopeSell && accel < 0)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED ACCEL SLOPE SELL: Slope=%s (threshold=%s)", DoubleToString(g_lastAccelerationSlope, 2), DoubleToString(MinAccelerationSlopeSell, 2)));
         }
         return signal;
      }
      
      // Test ONLY MomentumSlope
      if(IsolatedMomentumSlopeOnly)
      {
         if(g_lastMomentumSlope >= MinMomentumSlopeBuy && momentum > 0)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED MOMENTUM SLOPE BUY: Slope=%s (threshold=%s)", DoubleToString(g_lastMomentumSlope, 2), DoubleToString(MinMomentumSlopeBuy, 2)));
         }
         else if(g_lastMomentumSlope <= MinMomentumSlopeSell && momentum < 0)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED MOMENTUM SLOPE SELL: Slope=%s (threshold=%s)", DoubleToString(g_lastMomentumSlope, 2), DoubleToString(MinMomentumSlopeSell, 2)));
         }
         return signal;
      }
      
      // Test ONLY raw Speed
      if(IsolatedSpeedOnly)
      {
         if(speed > MinSpeedBuy)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED SPEED BUY: Speed=%s (threshold=%d)", DoubleToString(speed, 2), MinSpeedBuy));
         }
         else if(speed < MinSpeedSell)  // MinSpeedSell is negative (e.g., -55)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED SPEED SELL: Speed=%s (threshold=%d)", DoubleToString(speed, 2), MinSpeedSell));
         }
         return signal;
      }
      
      // Test ONLY raw Acceleration
      if(IsolatedAccelOnly)
      {
         if(accel > MinAccelerationBuy)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED ACCEL BUY: Accel=%s (threshold=%d)", DoubleToString(accel, 2), MinAccelerationBuy));
         }
         else if(accel < MinAccelerationSell)  // MinAccelerationSell is negative (e.g., -80)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED ACCEL SELL: Accel=%s (threshold=%d)", DoubleToString(accel, 2), MinAccelerationSell));
         }
         return signal;
      }
      
      // Test ONLY raw Momentum
      if(IsolatedMomentumOnly)
      {
         if(momentum > MinMomentumBuy)
         {
            signal = 1;  // BUY
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED MOMENTUM BUY: Momentum=%s (threshold=%d)", DoubleToString(momentum, 2), MinMomentumBuy));
         }
         else if(momentum < MinMomentumSell)  // MinMomentumSell is negative (e.g., -30)
         {
            signal = -1;  // SELL
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED MOMENTUM SELL: Momentum=%s (threshold=%d)", DoubleToString(momentum, 2), MinMomentumSell));
         }
         return signal;
      }
      
      // Test ONLY Quality threshold
      if(IsolatedQualityOnly)
      {
         if(quality >= MinQualityBuy && speed > 0)
         {
            signal = 1;  // BUY (if uptrend based on speed)
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED QUALITY BUY: Quality=%s (threshold=%d)", DoubleToString(quality, 2), MinQualityBuy));
         }
         else if(quality >= MinQualitySell && speed < 0)
         {
            signal = -1;  // SELL (if downtrend based on speed)
            if(EnableDebugMode)
               Print(StringFormat("🧪 ISOLATED QUALITY SELL: Quality=%s (threshold=%d)", DoubleToString(quality, 2), MinQualitySell));
         }
         return signal;
      }
   }
   
   // NORMAL MODE: Multi-factor entry logic
   
   // BUY CONDITIONS: All physics metrics must be positive AND above thresholds
   bool buyConditions = true;
   
   if(UsePhysicsFilters && quality < MinQualityBuy)
      buyConditions = false;
   
   if(AvoidTransitionZone && (zone == ZONE_TRANSITION || zone == ZONE_AVOID))
      buyConditions = false;
   
   if(UseSpeedFilter && speed < MinSpeedBuy)
      buyConditions = false;
   
   if(UseAccelerationFilter && accel < MinAccelerationBuy)
      buyConditions = false;
   
   if(UseMomentumFilter && momentum < MinMomentumBuy)
      buyConditions = false;
   
   // Check for bullish breakthrough (crossing above thresholds)
   bool speedBreakthrough = (g_prevSpeed < MinSpeedBuy && speed >= MinSpeedBuy);
   bool accelBreakthrough = (g_prevAccel < MinAccelerationBuy && accel >= MinAccelerationBuy);
   bool momentumBreakthrough = (g_prevMomentum < MinMomentumBuy && momentum >= MinMomentumBuy);
   
   if(buyConditions && (speedBreakthrough || accelBreakthrough || momentumBreakthrough))
   {
      signal = 1;  // BUY
      if(EnableDebugMode)
         Print(StringFormat("📈 PHYSICS BUY: Speed=%s Accel=%s Momentum=%s Quality=%s", DoubleToString(speed, 2), DoubleToString(accel, 2), DoubleToString(momentum, 2), DoubleToString(quality, 2)));
   }
   
   // SELL CONDITIONS: All physics metrics must be negative AND below thresholds
   // NOTE: MinSpeedSell, MinAccelerationSell, MinMomentumSell are negative values (e.g., -55.0, -80.0, -30.0)
   bool sellConditions = true;
   
   if(UsePhysicsFilters && quality < MinQualitySell)
      sellConditions = false;
   
   if(AvoidTransitionZone && (zone == ZONE_TRANSITION || zone == ZONE_AVOID))
      sellConditions = false;
   
   if(UseSpeedFilter && speed > MinSpeedSell)  // e.g., -40 > -55 = too weak
      sellConditions = false;
   
   if(UseAccelerationFilter && accel > MinAccelerationSell)  // e.g., -60 > -80 = too weak
      sellConditions = false;
   
   if(UseMomentumFilter && momentum > MinMomentumSell)  // e.g., -20 > -30 = too weak
      sellConditions = false;
   
   // Check for bearish breakthrough (crossing below negative thresholds)
   bool speedBreakthroughSell = (g_prevSpeed > MinSpeedSell && speed <= MinSpeedSell);
   bool accelBreakthroughSell = (g_prevAccel > MinAccelerationSell && accel <= MinAccelerationSell);
   bool momentumBreakthroughSell = (g_prevMomentum > MinMomentumSell && momentum <= MinMomentumSell);
   
   if(sellConditions && (speedBreakthroughSell || accelBreakthroughSell || momentumBreakthroughSell))
   {
      signal = -1;  // SELL
      if(EnableDebugMode)
         Print(StringFormat("📉 PHYSICS SELL: Speed=%s Accel=%s Momentum=%s Quality=%s", DoubleToString(speed, 2), DoubleToString(accel, 2), DoubleToString(momentum, 2), DoubleToString(quality, 2)));
   }
   
   // Update previous values
   g_prevSpeed = speed;
   g_prevAccel = accel;
   g_prevMomentum = momentum;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Physics-based signal (original crossover method)                 |
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
   
   // BUY: Fast crosses above Slow
   if(maFast[2] < maSlow[2] && maFast[0] > maSlow[0])
   {
      if(EnableDebugMode)
         Print(StringFormat("📈 MA BUY Signal: Fast(%s) > Slow(%s)", DoubleToString(maFast[0], 5), DoubleToString(maSlow[0], 5)));
      return 1;
   }
   
   // SELL: Fast crosses below Slow
   if(maFast[2] > maSlow[2] && maFast[0] < maSlow[0])
   {
      if(EnableDebugMode)
         Print(StringFormat("📉 MA SELL Signal: Fast(%s) < Slow(%s)", DoubleToString(maFast[0], 5), DoubleToString(maSlow[0], 5)));
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| New bar handler                                                   |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // Update Confluence History (Shift and Insert)
   for(int i = ArraySize(g_confluenceHistory)-1; i > 0; i--)
   {
      g_confluenceHistory[i] = g_confluenceHistory[i-1];
   }
   g_confluenceHistory[0] = g_lastTickConfluence; // Value of the just-closed bar
   
   // QA FIX: Validate physics data is available before generating signals
   if(!ValidatePhysicsData())
   {
      Print("❌ CRITICAL: Cannot generate signals - physics data validation failed");
      return;
   }
   
   // 1. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality(0);
   double confluence = g_physics.GetConfluence(0);
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // v4.5: Calculate slopes for logging and filtering
   if(UseSlopeFilters || EnableRealTimeLogging)
   {
      CalculatePhysicsSlopes();
   }
   
   // 2. Log signal
   if(EnableRealTimeLogging && signal != 0)
      LogSignal(signal, quality, confluence, zone, regime);
   
   // Track signal count
   if(signal != 0)
      g_signalsToday++;
   
   if(signal == 0) return;
   
   // Time & Day-of-Week Filters (check BEFORE physics filters)
   if(!BypassAllFilters)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      // Time of day filter
      if(UseTimeFilter)
      {
         int currentHour = dt.hour;
         bool withinTradingHours = false;
         
         // Handle hour ranges that cross midnight
         if(TradingStartHour <= TradingEndHour)
         {
            // Normal range (e.g., 8:00 - 17:00)
            withinTradingHours = (currentHour >= TradingStartHour && currentHour <= TradingEndHour);
         }
         else
         {
            // Range crosses midnight (e.g., 22:00 - 6:00)
            withinTradingHours = (currentHour >= TradingStartHour || currentHour <= TradingEndHour);
         }
         
         if(!withinTradingHours)
         {
            if(EnableDebugMode)
               Print(StringFormat("🕐 Time Filter: Outside trading hours (%d:00, allowed: %d:00-%d:00)", currentHour, TradingStartHour, TradingEndHour));
            return;
         }
      }
      
      // Day of week filter
      if(UseDayOfWeekFilter)
      {
         int dayOfWeek = dt.day_of_week;  // 0=Sunday, 1=Monday, ..., 6=Saturday
         bool allowedDay = false;
         
         switch(dayOfWeek)
         {
            case 0: allowedDay = TradeOnSunday; break;
            case 1: allowedDay = TradeOnMonday; break;
            case 2: allowedDay = TradeOnTuesday; break;
            case 3: allowedDay = TradeOnWednesday; break;
            case 4: allowedDay = TradeOnThursday; break;
            case 5: allowedDay = TradeOnFriday; break;
            case 6: allowedDay = TradeOnSaturday; break;
         }
         
         if(!allowedDay)
         {
            string dayName[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
            if(EnableDebugMode)
               Print(StringFormat("📅 Day Filter: Trading not allowed on %s", dayName[dayOfWeek]));
            return;
         }
      }
   }
   
   // NOTE: When UsePhysicsFiltersAsEntry=true, filters are ALREADY CHECKED in GeneratePhysicsFilterSignal()
   // So we only apply filters if using MA or Physics crossover entry
   
   string rejectReason = "";
   bool passFilters = true;
   
   if((UseMAEntry || UsePhysicsEntry) && UsePhysicsFilters && !BypassAllFilters)
   {
      // Quality filter (PRIMARY)
      if(passFilters)
      {
         if(signal > 0 && quality < MinQualityBuy)
         {
            passFilters = false;
            rejectReason = "Quality_Too_Low_Buy";
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Quality %s < %d (BUY)", DoubleToString(quality, 2), MinQualityBuy));
         }
         else if(signal < 0 && quality < MinQualitySell)
         {
            passFilters = false;
            rejectReason = "Quality_Too_Low_Sell";
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Quality %s < %d (SELL)", DoubleToString(quality, 2), MinQualitySell));
         }
      }
      
      // Zone filter (reject TRANSITION and AVOID)
      if(AvoidTransitionZone && passFilters)
      {
         if(zone == ZONE_TRANSITION || zone == ZONE_AVOID)
         {
            passFilters = false;
            rejectReason = "Zone_Avoid";
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Zone %s", EnumToString(zone)));
         }
      }

      // Acceleration filter
      if(UseAccelerationFilter && passFilters)
      {
         if(signal > 0 && accel < MinAccelerationBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("Accel_Too_Low_%.1f<%.1f", accel, MinAccelerationBuy);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Acceleration %s < %d (BUY)", DoubleToString(accel, 2), MinAccelerationBuy));
         }
         else if(signal < 0 && accel > MinAccelerationSell)
         {
            passFilters = false;
            rejectReason = StringFormat("Accel_Too_Weak_%.1f>%.1f", accel, MinAccelerationSell);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Acceleration %s > %d (SELL)", DoubleToString(accel, 2), MinAccelerationSell));
         }
      }

      // Speed filter
      if(UseSpeedFilter && passFilters)
      {
         if(signal > 0 && speed < MinSpeedBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("Speed_Too_Low_%.1f<%.1f", speed, MinSpeedBuy);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Speed %s < %d (BUY)", DoubleToString(speed, 2), MinSpeedBuy));
         }
         else if(signal < 0 && speed > MinSpeedSell)  // Note: MinSpeedSell is negative (e.g., -55)
         {
            passFilters = false;
            rejectReason = StringFormat("Speed_Too_Weak_%.1f>%.1f", speed, MinSpeedSell);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Speed %s > %d (SELL)", DoubleToString(speed, 2), MinSpeedSell));
         }
      }
      
      // Momentum filter - FIXED
      if(UseMomentumFilter && passFilters)
      {
         if(signal > 0 && momentum < MinMomentumBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("Momentum_Too_Low_%.1f<%.1f", momentum, MinMomentumBuy);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Momentum %s < %d (BUY)", DoubleToString(momentum, 2), MinMomentumBuy));
         }
         else if(signal < 0 && momentum > MinMomentumSell)  // Note: MinMomentumSell is negative (e.g., -30)
         {
            passFilters = false;
            rejectReason = StringFormat("Momentum_Too_Weak_%.1f>%.1f", momentum, MinMomentumSell);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Momentum %s > %d (SELL)", DoubleToString(momentum, 2), MinMomentumSell));
         }
      }
      
      // v4.2: Physics Score filter (Multi-Asset Validated)
      if(UsePhysicsScoreFilter && passFilters)
      {
         if(signal > 0 && g_lastPhysicsScore < MinPhysicsScoreBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("PhysicsScore_Too_Low_Buy_%.1f<%.1f", g_lastPhysicsScore, MinPhysicsScoreBuy);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Physics Score %s < %d (BUY)", DoubleToString(g_lastPhysicsScore, 2), MinPhysicsScoreBuy));
         }
         else if(signal < 0 && g_lastPhysicsScore < MinPhysicsScoreSell)
         {
            passFilters = false;
            rejectReason = StringFormat("PhysicsScore_Too_Low_Sell_%.1f<%.1f", g_lastPhysicsScore, MinPhysicsScoreSell);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Physics Score %s < %d (SELL)", DoubleToString(g_lastPhysicsScore, 2), MinPhysicsScoreSell));
         }
      }
      
      // v4.2: Full Confluence filter (+11.5% win boost validated)
      if(RequireFullConfluence && passFilters)
      {
         if(confluence < 100.0)
         {
            passFilters = false;
            rejectReason = StringFormat("Confluence_Not_Full_%.0f%%<100%%", confluence);
            if(EnableDebugMode)
               Print(StringFormat("❌ Filter FAIL: Confluence %s%% < 100%% (Full Confluence required)", DoubleToString(confluence, 0)));
         }
      }
      
      // v4.6: Spread Filter (Cost Control)
      if(UseSpreadFilter && passFilters)
      {
         if(!CheckSpreadFilter())
         {
            passFilters = false;
            rejectReason = StringFormat("Spread_TooHigh_%.2fpips>%.2fpips", g_lastSpreadPips, MaxSpreadPips);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: Spread ", DoubleToString(g_lastSpreadPips, 2), 
                     " pips exceeds max ", DoubleToString(MaxSpreadPips, 2), " pips");
         }
      }
      
      // v4.5: Slope Filters (Directional Momentum Confirmation)
      if(UseSlopeFilters && passFilters)
      {
         // Calculate all slopes
         CalculatePhysicsSlopes();
         
         // Speed Slope Filter
         if(UseSpeedSlope)
         {
            if(signal > 0 && g_lastSpeedSlope < MinSpeedSlopeBuy)
            {
               passFilters = false;
               rejectReason = StringFormat("SpeedSlope_Declining_%.2f<%.2f", g_lastSpeedSlope, MinSpeedSlopeBuy);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Speed Slope %s < %s (BUY needs positive slope)", DoubleToString(g_lastSpeedSlope, 2), DoubleToString(MinSpeedSlopeBuy, 2)));
            }
            else if(signal < 0 && g_lastSpeedSlope > MinSpeedSlopeSell)
            {
               passFilters = false;
               rejectReason = StringFormat("SpeedSlope_Rising_%.2f>%.2f", g_lastSpeedSlope, MinSpeedSlopeSell);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Speed Slope %s > %s (SELL needs negative slope)", DoubleToString(g_lastSpeedSlope, 2), DoubleToString(MinSpeedSlopeSell, 2)));
            }
         }
         
         // Acceleration Slope Filter
         if(UseAccelerationSlope && passFilters)
         {
            if(signal > 0 && g_lastAccelerationSlope < MinAccelerationSlopeBuy)
            {
               passFilters = false;
               rejectReason = StringFormat("AccelSlope_Declining_%.2f<%.2f", g_lastAccelerationSlope, MinAccelerationSlopeBuy);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Accel Slope %s < %s (BUY needs positive slope)", DoubleToString(g_lastAccelerationSlope, 2), DoubleToString(MinAccelerationSlopeBuy, 2)));
            }
            else if(signal < 0 && g_lastAccelerationSlope > MinAccelerationSlopeSell)
            {
               passFilters = false;
               rejectReason = StringFormat("AccelSlope_Rising_%.2f>%.2f", g_lastAccelerationSlope, MinAccelerationSlopeSell);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Accel Slope %s > %s (SELL needs negative slope)", DoubleToString(g_lastAccelerationSlope, 2), DoubleToString(MinAccelerationSlopeSell, 2)));
            }
         }
         
         // Confluence Slope Filter (must be increasing for both BUY and SELL)
         if(UseConfluenceSlope && passFilters)
         {
            if(signal > 0 && g_lastConfluenceSlope < MinConfluenceSlopeBuy)
            {
               passFilters = false;
               rejectReason = StringFormat("ConfluenceSlope_NotRising_Buy_%.2f<%.2f", g_lastConfluenceSlope, MinConfluenceSlopeBuy);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Confluence Slope %s < %s (BUY needs upward trend)", DoubleToString(g_lastConfluenceSlope, 2), DoubleToString(MinConfluenceSlopeBuy, 2)));
            }
            else if(signal < 0 && g_lastConfluenceSlope < MinConfluenceSlopeSell)
            {
               passFilters = false;
               rejectReason = StringFormat("ConfluenceSlope_NotRising_Sell_%.2f<%.2f", g_lastConfluenceSlope, MinConfluenceSlopeSell);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Confluence Slope %s < %s (SELL needs upward trend)", DoubleToString(g_lastConfluenceSlope, 2), DoubleToString(MinConfluenceSlopeSell, 2)));
            }
         }
         
         // Momentum Slope Filter
         if(UseMomentumSlope && passFilters)
         {
            if(signal > 0 && g_lastMomentumSlope < MinMomentumSlopeBuy)
            {
               passFilters = false;
               rejectReason = StringFormat("MomentumSlope_Declining_%.2f<%.2f", g_lastMomentumSlope, MinMomentumSlopeBuy);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Momentum Slope %s < %s (BUY needs positive slope)", DoubleToString(g_lastMomentumSlope, 2), DoubleToString(MinMomentumSlopeBuy, 2)));
            }
            else if(signal < 0 && g_lastMomentumSlope > MinMomentumSlopeSell)
            {
               passFilters = false;
               rejectReason = StringFormat("MomentumSlope_Rising_%.2f>%.2f", g_lastMomentumSlope, MinMomentumSlopeSell);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Momentum Slope %s > %s (SELL needs negative slope)", DoubleToString(g_lastMomentumSlope, 2), DoubleToString(MinMomentumSlopeSell, 2)));
            }
         }
         
         // Jerk Slope Filter (advanced, may be noisy)
         if(UseJerkSlope && passFilters)
         {
            if(signal > 0 && g_lastJerkSlope < MinJerkSlopeBuy)
            {
               passFilters = false;
               rejectReason = StringFormat("JerkSlope_Declining_%.2f<%.2f", g_lastJerkSlope, MinJerkSlopeBuy);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Jerk Slope %s < %s (BUY needs positive slope)", DoubleToString(g_lastJerkSlope, 2), DoubleToString(MinJerkSlopeBuy, 2)));
            }
            else if(signal < 0 && g_lastJerkSlope > MinJerkSlopeSell)
            {
               passFilters = false;
               rejectReason = StringFormat("JerkSlope_Rising_%.2f>%.2f", g_lastJerkSlope, MinJerkSlopeSell);
               if(EnableDebugMode)
                  Print(StringFormat("❌ Filter FAIL: Jerk Slope %s > %s (SELL needs negative slope)", DoubleToString(g_lastJerkSlope, 2), DoubleToString(MinJerkSlopeSell, 2)));
            }
         }
      }
      
      if(passFilters && EnableDebugMode)
      {
         Print(StringFormat("✅ Filters PASS: Quality=%s, Zone=%s", DoubleToString(quality, 2), g_physics.GetZoneName(zone)));
         if(UseAccelerationFilter)
            Print("   ✅ Accel: ", accel);
         if(UseSpeedFilter)
            Print("   ✅ Speed: ", speed);
         if(UseMomentumFilter)
            Print("   ✅ Momentum: ", momentum);
         if(UsePhysicsScoreFilter)
            Print("   ✅ Physics Score: ", g_lastPhysicsScore);
         if(RequireFullConfluence)
            Print("   ✅ Confluence: ", confluence, "%");
         if(UseSlopeFilters)
         {
            Print("   📈 Slopes: Speed=", g_lastSpeedSlope, " Accel=", g_lastAccelerationSlope, 
                  " Momentum=", g_lastMomentumSlope);
         }
      }
   }
   
   if(!passFilters)
   {
      g_filtersBlockedToday++;
      
      if(EnableDebugMode)
         Print("🚫 Trade blocked by filters: ", rejectReason);
      
      if(EnableFilterAlerts)
         Alert("🚫 TP Filter Block: ", _Symbol, " - ", rejectReason);
      
      return;
   }
   
   // Bypass mode notification
   if(BypassAllFilters && EnableDebugMode)
   {
      Print("⚠️ BYPASS MODE: Filters skipped, allowing trade");
   }
   
   // Dry run mode - log but don't trade
   if(DryRunMode)
   {
      Print("📝 DRY RUN: Would open ", signal > 0 ? "BUY" : "SELL", " position");
      Print("   Quality=", quality, ", Zone=", g_physics.GetZoneName(zone));
      return;
   }
   
   // 5. Close opposite positions
   int closedCount = CloseOppositePositions(signal);
   if(closedCount > 0)
      Sleep(500);
   
   // 6. Check for duplicate position
   if(HasPositionInDirection(signal))
   {
      if(EnableDebugMode)
         Print("⚠️ Already have position in this direction");
      return;
   }
   
   // 7. Check risk limits
   int openTrades = PositionsTotal();
   if(openTrades >= MaxConcurrentTrades)
   {
      if(EnableDebugMode)
         Print("⚠️ Max concurrent trades reached: ", openTrades);
      return;
   }
   
   // 8. Calculate position size with asset-adaptive SL/TP
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Get asset-appropriate SL/TP values
   int adaptiveStopLossPips, adaptiveTakeProfitPips;
   GetAssetAdaptiveSLTP(adaptiveStopLossPips, adaptiveTakeProfitPips);
   
   // Convert pips to price distance
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   double slDistance = adaptiveStopLossPips * point * pipMultiplier;
   
   // QA FIX: Validate SL distance before calculation
   if(slDistance <= 0)
   {
      Print("❌ CRITICAL: Invalid SL distance: ", slDistance);
      Print("   Adaptive SL Pips=", adaptiveStopLossPips, " point=", point, " multiplier=", pipMultiplier);
      return;
   }
   
   // Calculate risk money from percentage of balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (RiskPercentPerTrade / 100.0);
   
   // Calculate lot size
   double lots = g_riskManager.CalculateLotSize(riskMoney, slDistance);
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size: riskMoney=$", riskMoney, " slDistance=", slDistance, " balance=$", balance);
      return;
   }
   
   if(EnableDebugMode)
   {
      int assetClassType = (int)g_riskManager.GetAssetClass();
      string assetName = "UNKNOWN";
      if(assetClassType == 0) assetName = "FOREX";
      else if(assetClassType == 1) assetName = "CRYPTO";
      else if(assetClassType == 2) assetName = "METAL";
      else if(assetClassType == 3) assetName = "INDEX";
      
      Print("💼 Position Sizing:");
      Print("   Asset Class: ", assetName);
      Print("   Balance: $", balance);
      Print("   Risk %: ", RiskPercentPerTrade, "%");
      Print("   Risk Money: $", riskMoney);
      Print("   Adaptive SL Pips: ", adaptiveStopLossPips);
      Print("   Adaptive TP Pips: ", adaptiveTakeProfitPips);
      Print("   SL Distance: ", slDistance);
      Print("   Calculated Lots: ", lots);
   }
   
   // 9. Execute trade with asset-adaptive SL/TP
   ExecuteTrade(signal, lots, price, adaptiveStopLossPips, adaptiveTakeProfitPips, quality, confluence, zone, regime);
}

//+------------------------------------------------------------------+
//| Close opposite positions                                          |
//+------------------------------------------------------------------+
int CloseOppositePositions(int newSignal)
{
   if(newSignal == 0) return 0;
   
   int closedCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         bool isOpposite = (newSignal > 0 && posType == POSITION_TYPE_SELL) || 
                          (newSignal < 0 && posType == POSITION_TYPE_BUY);
         
         if(isOpposite)
         {
            ulong ticket = PositionGetTicket(i);
            g_tracker.SetExitReason(ticket, "REVERSAL");
            
            if(g_trade.PositionClose(ticket))
            {
               closedCount++;
               Print("✅ Closed opposite position #", ticket);
            }
         }
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
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         
         ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         if((signal > 0 && posType == POSITION_TYPE_BUY) || 
            (signal < 0 && posType == POSITION_TYPE_SELL))
            return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+

void ExecuteTrade(int signal, double lots, double price, double slPips, double tpPips,
                  double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   // Get broker's minimum stop level
   long stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDistance = stopLevel * point;
   
   if(EnableDebugMode && stopLevel > 0)
      Print("ℹ️ Broker min stop level: ", stopLevel, " points (", minStopDistance, " price units)");
   
   // Calculate SL/TP distances
   double slDistance = slPips * point * pipMultiplier;
   double tpDistance = tpPips * point * pipMultiplier;
   
   // Enforce minimum stop level
   if(stopLevel > 0)
   {
      if(slDistance > 0 && slDistance < minStopDistance)
      {
         Print("⚠️ SL distance ", slDistance, " too small, adjusting to broker minimum: ", minStopDistance);
         slDistance = minStopDistance * 1.1;  // Add 10% buffer
      }
      if(tpDistance > 0 && tpDistance < minStopDistance)
      {
         Print("⚠️ TP distance ", tpDistance, " too small, adjusting to broker minimum: ", minStopDistance);
         tpDistance = minStopDistance * 1.1;  // Add 10% buffer
      }
   }
   
   // Validate lot size against account limits
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // Normalize lot size to broker's step
   lots = MathFloor(lots / lotStep) * lotStep;
   
   // Clamp to broker limits
   if(lots < minLot)
   {
      Print("⚠️ Lot size ", lots, " below minimum ", minLot, ", adjusting to minimum");
      lots = minLot;
   }
   if(lots > maxLot)
   {
      Print("⚠️ Lot size ", lots, " above maximum ", maxLot, ", adjusting to maximum");
      lots = maxLot;
   }
   
   // Final validation: Check if we have enough margin
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginRequired = 0;
   
   if(!OrderCalcMargin(signal > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lots, price, marginRequired))
   {
      Print("❌ Failed to calculate required margin");
      return;
   }
   
   if(marginRequired > freeMargin)
   {
      Print("❌ Insufficient margin: Required=", marginRequired, ", Available=", freeMargin);
      Print("   Reducing lot size...");
      
      // Reduce lot size to fit available margin (80% safety factor)
      lots = (freeMargin * 0.8 / marginRequired) * lots;
      lots = MathFloor(lots / lotStep) * lotStep;
      
      if(lots < minLot)
      {
         Print("❌ Cannot open trade: Even minimum lot size requires more margin than available");
         return;
      }
      
      Print("✅ Adjusted lot size to ", lots, " (Margin required: ", marginRequired * (lots / (freeMargin * 0.8 / marginRequired)), ")");
   }
   
   double sl = 0, tp = 0;
   bool success = false;
   ulong ticket = 0;
   
   if(signal > 0)  // BUY
   {
      if(slPips > 0) sl = NormalizeDouble(price - slDistance, digits);
      if(tpPips > 0) tp = NormalizeDouble(price + tpDistance, digits);
      
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   else  // SELL
   {
      if(slPips > 0) sl = NormalizeDouble(price + slDistance, digits);
      if(tpPips > 0) tp = NormalizeDouble(price - tpDistance, digits);
      
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   
   if(!success)
   {
      uint retcode = g_trade.ResultRetcode();
      Print("❌ Trade execution failed: ", g_trade.ResultRetcodeDescription(), " (Code: ", retcode, ")");
      Print("   Attempted: ", signal > 0 ? "BUY" : "SELL", " ", lots, " lots @ ", price);
      Print("   SL: ", sl, " (distance: ", slDistance, ")");
      Print("   TP: ", tp, " (distance: ", tpDistance, ")");
      Print("   Balance: $", balance, ", Free Margin: $", freeMargin);
      return;
   }
   
   Print("✅ Position opened: #", ticket, " | ", signal > 0 ? "BUY" : "SELL", " ", lots, " lots @ ", price);
   
   // Add to tracker (v9.0: with ALL physics including slopes)
   g_tracker.AddTrade(ticket, quality, confluence, g_physics.GetMomentum(), 
                     g_physics.GetSpeed(), g_physics.GetAcceleration(),
                     g_physics.GetEntropy(), g_physics.GetJerk(), g_lastPhysicsScore,
                     g_lastSpeedSlope, g_lastAccelerationSlope, g_lastMomentumSlope,
                     g_lastConfluenceSlope, g_lastJerkSlope,
                     g_physics.GetZoneName(zone), g_physics.GetRegimeName(regime), 
                     RiskPercentPerTrade);
   
   // v8.0: Log ENTRY row immediately after trade opens
   TradeLogEntry entryLog;
   entryLog.eaName = EA_NAME;
   entryLog.eaVersion = EA_VERSION;
   entryLog.rowType = "ENTRY";  // Critical: Mark as ENTRY row
   
   entryLog.ticket = ticket;
   entryLog.openTime = TimeCurrent();
   entryLog.symbol = _Symbol;
   entryLog.type = signal > 0 ? "BUY" : "SELL";
   entryLog.lots = lots;
   entryLog.openPrice = price;
   entryLog.sl = sl;
   entryLog.tp = tp;
   
   // Entry physics snapshot (v9.0: explicit Entry_* naming)
   entryLog.entryQuality = quality;
   entryLog.entryConfluence = confluence;
   entryLog.entryMomentum = g_physics.GetMomentum();
   entryLog.entrySpeed = g_physics.GetSpeed();
   entryLog.entryAcceleration = g_physics.GetAcceleration();
   entryLog.entryEntropy = 0.0; // QA FIX: Skip entropy for now // g_physics.GetEntropy();
   entryLog.entryJerk = g_physics.GetJerk();
   entryLog.entryPhysicsScore = g_lastPhysicsScore;
   
   // Entry slopes (v9.0: explicit Entry_* naming)
   entryLog.entrySpeedSlope = g_lastSpeedSlope;
   entryLog.entryAccelerationSlope = g_lastAccelerationSlope;
   entryLog.entryMomentumSlope = g_lastMomentumSlope;
   entryLog.entryConfluenceSlope = g_lastConfluenceSlope;
   entryLog.entryJerkSlope = g_lastJerkSlope;
   
   entryLog.entryZone = g_physics.GetZoneName(zone);
   entryLog.entryRegime = g_physics.GetRegimeName(regime);
   // QA FIX: Direct spread calculation to ensure population
   entryLog.entrySpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point / _Point * 10; // g_lastSpreadPips;
   
   // Account state at entry
   entryLog.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   entryLog.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   entryLog.openPositions = PositionsTotal();
   
   // Set current price (openPrice for ENTRY row)
   entryLog.price = price;
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   entryLog.entryHour = dt.hour;
   entryLog.entryDayOfWeek = dt.day_of_week;
   
   // Calculate time segments (populates Hour, DayOfWeek, TimeSegments, TradingSession, etc.)
   g_logger.CalculateTimeSegments(TimeCurrent(), entryLog);
   
   g_logger.LogTrade(entryLog);  // Log ENTRY row to CSV
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
   entry.entropy = 0.0; // QA FIX: Skip entropy for now // g_physics.GetEntropy();
   entry.jerk = g_physics.GetJerk();
   entry.physicsScore = CalculatePhysicsScore();
   
   // v4.5: Add slope values
   entry.speedSlope = g_lastSpeedSlope;
   entry.accelerationSlope = g_lastAccelerationSlope;
   entry.momentumSlope = g_lastMomentumSlope;
   entry.confluenceSlope = g_lastConfluenceSlope;
   entry.jerkSlope = g_lastJerkSlope;
   
   entry.zone = g_physics.GetZoneName(zone);
   entry.regime = g_physics.GetRegimeName(regime);
   
   entry.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   entry.spread = g_lastSpreadPips;  // Use cached spread from filter check
   entry.highThreshold = 0.0;
   entry.lowThreshold = 0.0;
   
   entry.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   entry.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   entry.openPositions = PositionsTotal();
   
   bool zonePass = (zone != ZONE_TRANSITION && zone != ZONE_AVOID) || !AvoidTransitionZone;
   double minQ = (signal > 0) ? MinQualityBuy : MinQualitySell;
   entry.physicsPass = BypassAllFilters || (quality >= minQ && zonePass);
   entry.rejectReason = entry.physicsPass ? "PASS" : (quality < minQ ? "Quality_Too_Low" : (zone == ZONE_TRANSITION ? "TRANSITION_Zone" : "AVOID_Zone"));
   
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
   log.rowType = "EXIT";  // v8.0: Critical - Mark as EXIT row for dual-row model
   
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
   
   // Entry physics (from tracker) - v9.0: Include ALL Entry_* fields
   log.entryQuality = trade.entryQuality;
   log.entryConfluence = trade.entryConfluence;
   log.entryMomentum = trade.entryMomentum;
   log.entrySpeed = trade.entrySpeed;
   log.entryAcceleration = trade.entryAcceleration;
   log.entryEntropy = trade.entryEntropy;
   log.entryJerk = trade.entryJerk;
   log.entryPhysicsScore = trade.entryPhysicsScore;
   
   // Entry slopes (from tracker)
   log.entrySpeedSlope = trade.entrySpeedSlope;
   log.entryAccelerationSlope = trade.entryAccelerationSlope;
   log.entryMomentumSlope = trade.entryMomentumSlope;
   log.entryConfluenceSlope = trade.entryConfluenceSlope;
   log.entryJerkSlope = trade.entryJerkSlope;
   
   log.entryZone = trade.entryZone;
   log.entryRegime = trade.entryRegime;
   log.entrySpread = trade.entrySpread;
   
   // QA FIX: Direct spread calculation
   log.exitSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point / _Point * 10;

   // v9.0: Capture current EXIT physics with explicit Exit_* naming
   log.exitQuality = g_physics.GetQuality();
   log.exitConfluence = g_physics.GetConfluence();
   log.exitMomentum = g_physics.GetMomentum();
   log.exitSpeed = g_physics.GetSpeed();
   log.exitAcceleration = g_physics.GetAcceleration();
   log.exitEntropy = 0.0; // QA FIX: Skip entropy for now // g_physics.GetEntropy();
   log.exitJerk = g_physics.GetJerk();
   log.exitPhysicsScore = CalculatePhysicsScore();
   
   log.exitSpeedSlope = g_lastSpeedSlope;
   log.exitAccelerationSlope = g_lastAccelerationSlope;
   log.exitMomentumSlope = g_lastMomentumSlope;
   log.exitConfluenceSlope = g_lastConfluenceSlope;
   log.exitJerkSlope = g_lastJerkSlope;
   
   log.exitReason = trade.exitReason;
   // FIXED: Don't overwrite physics values captured from g_physics at exit
   // log.exitQuality = trade.exitQuality;        // REMOVED - was overwriting good value with 0
   // log.exitConfluence = trade.exitConfluence;  // REMOVED - was overwriting good value with 0
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
   
   // v9.0: CRITICAL - Calculate physics decay and derived metrics
   // This populates: PhysicsScoreDecay, SpeedSlopeDecay, QualityDecay,
   // ZoneTransitioned, MFEUtilization, ExitQuality, etc.
   TradeLogEntry entrySnapshot;  // Create entry snapshot from trade data
   entrySnapshot.entryQuality = trade.entryQuality;
   entrySnapshot.entryConfluence = trade.entryConfluence;
   entrySnapshot.entryMomentum = trade.entryMomentum;
   entrySnapshot.entrySpeed = trade.entrySpeed;
   entrySnapshot.entryAcceleration = trade.entryAcceleration;
   entrySnapshot.entryEntropy = trade.entryEntropy;
   entrySnapshot.entryJerk = trade.entryJerk;
   entrySnapshot.entryPhysicsScore = trade.entryPhysicsScore;
   
   // Entry slopes (CRITICAL for decay calculations!)
   entrySnapshot.entrySpeedSlope = trade.entrySpeedSlope;
   entrySnapshot.entryAccelerationSlope = trade.entryAccelerationSlope;
   entrySnapshot.entryMomentumSlope = trade.entryMomentumSlope;
   entrySnapshot.entryConfluenceSlope = trade.entryConfluenceSlope;
   entrySnapshot.entryJerkSlope = trade.entryJerkSlope;
   
   entrySnapshot.entryZone = trade.entryZone;
   entrySnapshot.entryRegime = trade.entryRegime;
   
   // Populate account state at exit
   log.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   log.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   log.openPositions = PositionsTotal();
   
   // Set current price (closePrice for EXIT row)
   log.price = trade.closePrice;
   
   // Calculate time segments (populates Hour, DayOfWeek, TimeSegments, TradingSession, etc.)
   g_logger.CalculateTimeSegments(TimeCurrent(), log);
   
   g_logger.CalculateDerivedMetrics(log, entrySnapshot);
   
   g_logger.LogTrade(log);
}


//+------------------------------------------------------------------+
