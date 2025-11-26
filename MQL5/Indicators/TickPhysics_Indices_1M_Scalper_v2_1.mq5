//+------------------------------------------------------------------+
//| TickPhysics_Indices_1M_Scalper_v2_1.mq5                          |
//| Indices 1-Minute Scalping Physics Engine                         |
//| Version 2.1_SCALPER - Optimized for NAS100 40-pip targets       |
//| ⚡ ULTRA-FAST SETTINGS FOR 30+ TRADES/DAY                        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version "2.11"
#property strict
#property indicator_separate_window
#property indicator_plots 16
#property indicator_buffers 32

//============================== PLOTS ==============================//
#property indicator_label1 "Speed"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1 2

#property indicator_label2 "Acceleration"
#property indicator_type2 DRAW_COLOR_HISTOGRAM
#property indicator_color2 clrLimeGreen, clrRed, clrGray
#property indicator_width2 3

#property indicator_label3 "Momentum"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrYellow
#property indicator_width3 3

#property indicator_label4 "Trend Quality"
#property indicator_type4 DRAW_COLOR_LINE
#property indicator_color4 clrLimeGreen, clrYellow, clrOrange, clrRed
#property indicator_width4 3

#property indicator_label5 "Distance ROC"
#property indicator_type5 DRAW_LINE
#property indicator_color5 clrGold
#property indicator_width5 2

#property indicator_label6 "Jerk"
#property indicator_type6 DRAW_LINE
#property indicator_color6 clrWhite
#property indicator_width6 1

#property indicator_label7 "High Zone"
#property indicator_type7 DRAW_LINE
#property indicator_color7 clrDarkGray
#property indicator_style7 STYLE_DOT

#property indicator_label8 "Low Zone"
#property indicator_type8 DRAW_LINE
#property indicator_color8 clrDarkGray
#property indicator_style8 STYLE_DOT

#property indicator_label9 "Zero"
#property indicator_type9 DRAW_LINE
#property indicator_color9 clrDimGray
#property indicator_style9 STYLE_DOT

#property indicator_label10 "Quality Glow"
#property indicator_type10 DRAW_LINE
#property indicator_color10 clrLimeGreen
#property indicator_width10 5

#property indicator_label11 "Momentum Spikes"
#property indicator_type11 DRAW_COLOR_HISTOGRAM
#property indicator_color11 clrLimeGreen, clrRed
#property indicator_width11 2

#property indicator_label12 "Signal Confluence"
#property indicator_type12 DRAW_COLOR_LINE
#property indicator_color12 clrRed, clrOrange, clrYellow, clrLimeGreen, clrLimeGreen
#property indicator_width12 4

#property indicator_label13 "Volatility Regime"
#property indicator_type13 DRAW_COLOR_LINE
#property indicator_color13 clrGray, clrGold, clrOrangeRed
#property indicator_width13 2

#property indicator_label14 "Divergence Signals"
#property indicator_type14 DRAW_COLOR_ARROW
#property indicator_color14 clrLimeGreen, clrRed
#property indicator_width14 3

#property indicator_label15 "Trading Zone"
#property indicator_type15 DRAW_COLOR_LINE
#property indicator_color15 clrDarkGreen, clrDarkRed, clrGoldenrod, clrDimGray
#property indicator_width15 2

#property indicator_label16 "Tick Entropy"
#property indicator_type16 DRAW_LINE
#property indicator_color16 clrOrange
#property indicator_width16 2

//============================= INPUTS ==============================//
input group "=== ⚡ SCALPING MODE - 1M NAS100 ==="
input bool   InpIndicesMode = true;  // Enable Indices Optimizations (NAS100/US30/SPX500)

input group "=== Physics Core (ULTRA-FAST) ==="
input int InpSpeedPeriod = 2;       // Speed Period (SCALP: 2 vs standard: 4)
input int InpSpeedSmooth = 3;       // Speed Smoothing (SCALP: 3 vs standard: 7)
input double InpSpeedMultiplier = 140.0;  // Speed Multiplier (boosted for 1M)
input double InpAccelMultiplier = 220.0;  // Accel Multiplier (boosted for 1M)

input group "=== ATR Adaptive Scaling (FAST) ==="
input int InpATRPeriod = 10;        // ATR Period (SCALP: 10 vs standard: 20)
input bool InpAutoRefPoints = true;
input double InpATRRefPoints = 2000.0;  
input double InpATRRef_Crypto = 2000.0; 
input double InpATRRef_Forex = 100.0;
input double InpATRRef_Index = 200.0;   // Reduced for intraday

input group "=== Momentum & Quality (PERMISSIVE) ==="
input double InpSpeedWeight = 0.60;     // Speed Weight (boosted)
input double InpAccelWeight = 0.40;     // Accel Weight
input int InpMomentumSmooth = 3;        // Momentum Smoothing (SCALP: 3 vs standard: 5)
input double InpMomentumScale = 2.2;    // Momentum Scale (reduced for micro-trends)
input int InpTrendQualityPeriod = 8;    // Trend Quality Period (SCALP: 8 vs standard: 15)
input double InpQualityMagWeight = 0.20; // Quality Magnitude Weight (reduced)

input group "=== Distance & Jerk (RESPONSIVE) ==="
input int InpDistanceROCPeriod = 3;     // Distance ROC Period (SCALP: 3 vs standard: 7)
input double InpDistanceROCScale = 80.0; // Distance ROC Scale
input int InpJerkSmooth = 3;            // Jerk Smoothing (SCALP: 3 vs standard: 6)

input group "=== Thresholds (RELAXED) ==="
input bool InpUseAdaptiveThresh = true;
input double InpThresholdATRMult = 0.9;  // Threshold ATR Mult (SCALP: 0.9 vs standard: 1.2)
input double InpHighThreshold = 60.0;    // High Threshold (SCALP: 60 vs standard: 75)
input double InpLowThreshold = -60.0;    // Low Threshold
input double InpVolHighMult = 1.5;       // Vol High Multiplier (reduced)

input group "=== Signal Confluence (PERMISSIVE) ==="
input bool InpShowConfluence = true;
input double InpConfluenceQualMin = 50.0;  // Confluence Quality Min (SCALP: 50 vs 65)
input double InpConfluenceSpeedMin = 0.25; // Confluence Speed Min (SCALP: 0.25 vs 0.35)

input group "=== Tick Entropy ==="
input bool InpShowEntropy = true;
input int InpEntropyWindow = 30;         // Entropy Window (SCALP: 30 vs 50)
input double InpEntropyThreshold = 2.0;  // Chaos Threshold (relaxed)

input group "=== Volatility Regime ==="
input bool InpShowVolRegime = true;
input double InpVolLowThreshold = 0.5;   // Vol Low Threshold (tighter)
input double InpVolHighThreshold = 1.3;  // Vol High Threshold (SCALP: 1.3 vs 1.5)

input group "=== Divergence Detection (TIGHT) ==="
input bool InpShowDivergence = true;
input int InpDivergenceLookback = 15;    // Divergence Lookback (SCALP: 15 vs 25)
input double InpDivergenceMinDiff = 10.0; // Min Difference (SCALP: 10 vs 15)
input double InpDivergenceSlopeThresh = 0.10; // Slope Threshold

input group "=== Trading Zones (AGGRESSIVE) ==="
input bool InpShowTradingZones = true;
input double InpZoneQualityMin = 50.0;   // Zone Quality Min (SCALP: 50 vs 65)
input bool InpAdaptiveZones = true;
input int InpZoneHistoryPeriod = 60;     // Zone History (SCALP: 60 vs 120)
input double InpZonePercentile = 60.0;   // Zone Percentile (SCALP: 60 vs 70)

input group "=== Plot Toggles ==="
input bool InpShowSpeed = true;
input bool InpShowAcceleration = true;
input bool InpShowMomentum = true;
input bool InpShowTrendQuality = true;
input bool InpShowDistanceROC = true;
input bool InpShowJerk = true;

input group "=== HUD Display ==="
input bool InpShowHUD = true;            // Show HUD (recommended for scalping)
input int InpHUDCorner = 0;
input int InpHUDX = 6;
input int InpHUDY = 14;
input bool InpShowAlerts = true;         // Enable alerts (recommended)

input group "=== Theme ==="
input bool InpDarkTheme = true;
input bool InpColorBlindFriendly = false;

input group "=== Scalping-Specific ==="
input bool InpHighFreqMode = true;       // High-frequency mode (ALWAYS ON for 1M)
input double InpScalpVolMultiplier = 1.3; // Scalping volatility adjustment

//============================= BUFFERS ==============================//
double SpeedBuffer[], AccelBuffer[], AccelColors[], MomentumBuffer[];
double TrendQualityBuffer[], QualColors[], DistanceROCBuffer[], JerkBuffer[];
double HighThresholdBuffer[], LowThresholdBuffer[], ZeroLineBuffer[];
double QualityGlowBuffer[], MomSpikeBuffer[], MomSpikeColors[];
double ConfluenceBuffer[], ConfluenceColors[], VolRegimeBuffer[], VolRegimeColors[];
double DivergenceBuffer[], DivergenceColors[], TradingZoneBuffer[], ZoneColors[];
double EntropyBuffer[];
double DistanceBuffer[], RawSpeedBuffer[], BiasBuffer[];
double PriceHighBuffer[], PriceLowBuffer[];
double CustomATRBuffer[];
double CustomATRAvgBuffer[];
double ZoneQualityHistory[];
double DivergenceHistory[];

int atrHandle = INVALID_HANDLE;
string HUD_NAME = "TPX_Scalper_HUD";
string HUD_BG_NAME = "TPX_Scalper_HUD_BG";
datetime lastAlertTime = 0;
int alertCooldown = 30; // 30 seconds between alerts for scalping

//============================= HELPERS ==============================//
double AutoRefPoints()
{
   if(!InpAutoRefPoints) return InpATRRefPoints;
   
   string sym = _Symbol;
   StringToUpper(sym);
   
   if(StringFind(sym,"BTC")!=-1 || StringFind(sym,"ETH")!=-1) 
      return InpATRRef_Crypto;
   
   long mode; 
   SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE, mode);
   
   if(mode == SYMBOL_CALC_MODE_FOREX)
      return InpATRRef_Forex;
      
   return InpATRRef_Index;
}

void TogglePlot(int index, bool show)
{
   if (!show) PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_NONE);
}

double CalculatePercentile(double &history[], int period, double percentile)
{
   double sorted[];
   ArrayResize(sorted, period);
   ArrayCopy(sorted, history, 0, 0, period);
   ArraySort(sorted);
   int idx = (int)MathRound((percentile / 100.0) * (period - 1));
   return sorted[idx];
}

void TriggerAlert(string message)
{
   if (!InpShowAlerts) return;
   
   datetime currentTime = TimeCurrent();
   if(currentTime - lastAlertTime < alertCooldown) return;
   
   Alert("⚡ TickPhysics SCALPER: ", message);
   lastAlertTime = currentTime;
}

//============================= INIT ================================//

int OnInit()
{
   if (InpSpeedPeriod <= 0) {
      Print("Error: InpSpeedPeriod must be > 0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   // Validate timeframe
   ENUM_TIMEFRAMES currentTF = _Period;
   if(currentTF != PERIOD_M1)
   {
      Print("⚠️ WARNING: This indicator is optimized for M1 (1-minute) chart!");
      Print("   Current timeframe: ", EnumToString(currentTF));
      Print("   Results may not be optimal on other timeframes.");
   }
   
   int idx = 0;
   SetIndexBuffer(idx++, SpeedBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, AccelBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, AccelColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, MomentumBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, TrendQualityBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, QualColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, DistanceROCBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, JerkBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, HighThresholdBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, LowThresholdBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, ZeroLineBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, QualityGlowBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, MomSpikeBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, MomSpikeColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, ConfluenceBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, ConfluenceColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, VolRegimeBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, VolRegimeColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, DivergenceBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, DivergenceColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, TradingZoneBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, ZoneColors, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(idx++, EntropyBuffer, INDICATOR_DATA);
   SetIndexBuffer(idx++, DistanceBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, RawSpeedBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, BiasBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, PriceHighBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, PriceLowBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, CustomATRAvgBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, CustomATRBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, ZoneQualityHistory, INDICATOR_CALCULATIONS);
   SetIndexBuffer(idx++, DivergenceHistory, INDICATOR_CALCULATIONS);

   // Set all arrays as series
   ArraySetAsSeries(SpeedBuffer, true);
   ArraySetAsSeries(AccelBuffer, true);
   ArraySetAsSeries(AccelColors, true);
   ArraySetAsSeries(MomentumBuffer, true);
   ArraySetAsSeries(TrendQualityBuffer, true);
   ArraySetAsSeries(QualColors, true);
   ArraySetAsSeries(DistanceROCBuffer, true);
   ArraySetAsSeries(JerkBuffer, true);
   ArraySetAsSeries(HighThresholdBuffer, true);
   ArraySetAsSeries(LowThresholdBuffer, true);
   ArraySetAsSeries(ZeroLineBuffer, true);
   ArraySetAsSeries(QualityGlowBuffer, true);
   ArraySetAsSeries(MomSpikeBuffer, true);
   ArraySetAsSeries(MomSpikeColors, true);
   ArraySetAsSeries(ConfluenceBuffer, true);
   ArraySetAsSeries(ConfluenceColors, true);
   ArraySetAsSeries(VolRegimeBuffer, true);
   ArraySetAsSeries(VolRegimeColors, true);
   ArraySetAsSeries(DivergenceBuffer, true);
   ArraySetAsSeries(DivergenceColors, true);
   ArraySetAsSeries(TradingZoneBuffer, true);
   ArraySetAsSeries(ZoneColors, true);
   ArraySetAsSeries(DistanceBuffer, true);
   ArraySetAsSeries(RawSpeedBuffer, true);
   ArraySetAsSeries(BiasBuffer, true);
   ArraySetAsSeries(PriceHighBuffer, true);
   ArraySetAsSeries(PriceLowBuffer, true);
   ArraySetAsSeries(CustomATRAvgBuffer, true);
   ArraySetAsSeries(CustomATRBuffer, true);
   ArraySetAsSeries(ZoneQualityHistory, true);
   ArraySetAsSeries(EntropyBuffer, true);
   ArraySetAsSeries(DivergenceHistory, true);

   // Set color indexes
   PlotIndexSetInteger(1, PLOT_COLOR_INDEXES, 3);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 0, clrLimeGreen);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 1, clrRed);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 2, clrGray);

   PlotIndexSetInteger(4, PLOT_COLOR_INDEXES, 4);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, 0, clrLimeGreen);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, 1, clrYellow);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, 2, clrOrange);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, 3, clrRed);

   PlotIndexSetInteger(11, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(11, PLOT_LINE_COLOR, 0, clrLimeGreen);
   PlotIndexSetInteger(11, PLOT_LINE_COLOR, 1, clrRed);

   PlotIndexSetInteger(12, PLOT_COLOR_INDEXES, 5);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, 0, clrRed);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, 1, clrOrange);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, 2, clrYellow);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, 3, clrLimeGreen);
   PlotIndexSetInteger(12, PLOT_LINE_COLOR, 4, clrLimeGreen);

   PlotIndexSetInteger(13, PLOT_COLOR_INDEXES, 3);
   PlotIndexSetInteger(13, PLOT_LINE_COLOR, 0, clrGray);
   PlotIndexSetInteger(13, PLOT_LINE_COLOR, 1, clrGold);
   PlotIndexSetInteger(13, PLOT_LINE_COLOR, 2, clrOrangeRed);

   PlotIndexSetInteger(14, PLOT_COLOR_INDEXES, 2);
   PlotIndexSetInteger(14, PLOT_LINE_COLOR, 0, clrLimeGreen);
   PlotIndexSetInteger(14, PLOT_LINE_COLOR, 1, clrRed);

   PlotIndexSetInteger(15, PLOT_COLOR_INDEXES, 4);
   PlotIndexSetInteger(15, PLOT_LINE_COLOR, 0, clrDarkGreen);
   PlotIndexSetInteger(15, PLOT_LINE_COLOR, 1, clrDarkRed);
   PlotIndexSetInteger(15, PLOT_LINE_COLOR, 2, clrGoldenrod);
   PlotIndexSetInteger(15, PLOT_LINE_COLOR, 3, clrDimGray);

   PlotIndexSetInteger(14, PLOT_ARROW, 108);
   PlotIndexSetDouble(9, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(10, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(11, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(12, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(13, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(14, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   // Toggle plots based on inputs
   TogglePlot(0, InpShowSpeed);
   TogglePlot(1, InpShowAcceleration);
   TogglePlot(2, InpShowMomentum);
   TogglePlot(3, InpShowTrendQuality);
   TogglePlot(4, InpShowDistanceROC);
   TogglePlot(5, InpShowJerk);
   if(!InpShowConfluence) TogglePlot(11, false);
   if(!InpShowVolRegime) TogglePlot(12, false);
   if(!InpShowDivergence) TogglePlot(13, false);
   if(!InpShowTradingZones) TogglePlot(14, false);
   if(!InpShowEntropy) TogglePlot(15, false);

   IndicatorSetString(INDICATOR_SHORTNAME, "TickPhysics 1M SCALPER v2.1 [NAS100]");
   IndicatorSetInteger(INDICATOR_DIGITS, 2);

   atrHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(atrHandle == INVALID_HANDLE) {
      Print("Error: Failed to initialize ATR handle");
      return(INIT_FAILED);
   }

   if(InpShowHUD && ObjectFind(0, HUD_NAME) == -1)
   {
      // Create background rectangle first
      if(ObjectFind(0, HUD_BG_NAME) == -1)
      {
         ObjectCreate(0, HUD_BG_NAME, OBJ_RECTANGLE_LABEL, 0, 0, 0);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_XDISTANCE, 5);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_YDISTANCE, 20);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_XSIZE, 350);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_YSIZE, 180);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_BGCOLOR, C'15,15,15');
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_COLOR, clrDodgerBlue);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_BACK, true);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, HUD_BG_NAME, OBJPROP_HIDDEN, true);
      }
      
      // Create HUD text label on top of background
      ObjectCreate(0, HUD_NAME, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_YDISTANCE, 25);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, HUD_NAME, OBJPROP_FONT, "Courier New");
      ObjectSetInteger(0, HUD_NAME, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, HUD_NAME, OBJPROP_BACK, false);
   }

   Print("✅ TickPhysics 1M SCALPER v2.1 initialized!");
   Print("⚡ SCALPING MODE: ENABLED");
   Print("📊 Asset: ", _Symbol);
   Print("📈 Timeframe: ", EnumToString(_Period));
   Print("🎯 Target: 30+ trades/day | 40-pip moves");
   
   return(INIT_SUCCEEDED);
}

//============================= CALCULATE ============================//
int OnCalculate(const int total, const int prev, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[])
{
   int need = MathMax(InpSpeedPeriod, MathMax(InpTrendQualityPeriod, 
              MathMax(InpDistanceROCPeriod, InpZoneHistoryPeriod))) + 
              InpDivergenceLookback + 10;
   
   if(total < need + 1) {
      return 0;
   }

   if(CopyBuffer(atrHandle, 0, 0, total, CustomATRBuffer) <= 0) {
      Print("Warning: ATR copy failed: ", GetLastError());
      for(int i = 0; i < total; i++) {
         CustomATRBuffer[i] = i > 0 ? MathMax(high[i] - low[i], MathAbs(close[i] - close[i-1])) : high[i] - low[i];
      }
   }

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(CustomATRBuffer, true);

   double refPts = AutoRefPoints();
   
   // Apply scalping volatility multiplier
   if(InpIndicesMode) {
      refPts *= InpScalpVolMultiplier;
   }

   int start = (prev > 0) ? (total - prev) : (total - 1);

   CalculateATRAverage(start, total);
   ClearOverlays(start, total);

   for(int i = start; i >= 0; i--)
   {
      if(i >= total) continue;

      double atr_val = i < ArraySize(CustomATRBuffer) ? CustomATRBuffer[i] : 0.0;
      double atr_avg_val = i < ArraySize(CustomATRAvgBuffer) ? CustomATRAvgBuffer[i] : 0.0;
      double atrPts = (atr_val > 0.0) ? (atr_val / _Point) : refPts;
      double volMult = (InpShowVolRegime && atr_avg_val > 0) ? 
                       (atr_val / atr_avg_val > InpVolHighThreshold ? InpVolHighMult : 1.0) : 1.0;

      double highThr = InpUseAdaptiveThresh ? (atrPts * InpThresholdATRMult * volMult) : InpHighThreshold;
      double lowThr = InpUseAdaptiveThresh ? (-atrPts * InpThresholdATRMult * volMult) : InpLowThreshold;

      HighThresholdBuffer[i] = highThr;
      LowThresholdBuffer[i] = lowThr;
      ZeroLineBuffer[i] = 0.0;

      double scale = (atrPts > 0.0) ? MathSqrt(refPts / atrPts) : 1.0;

      CalculateSpeed(i, total, close, scale);
      CalculateDistance(i, total, close);
      CalculateAcceleration(i, total, highThr, lowThr);
      CalculateJerk(i, total);
      CalculateMomentum(i, total, highThr);
      CalculateTrendQuality(i, total, highThr);
      CalculateDistanceROC(i, total);
      CalculateBias(i, highThr, lowThr);
      CalculateMomentumSpikes(i, total, highThr, lowThr);
      CalculateConfluence(i, total, highThr);
      CalculateVolRegime(i, atr_val, atr_avg_val);
      CalculateTradingZone(i, total);

      if(i < ArraySize(PriceHighBuffer) && i < ArraySize(PriceLowBuffer))
      {
         PriceHighBuffer[i] = high[i];
         PriceLowBuffer[i] = low[i];
      }
   }

   DetectDivergence(start, total, high, low);
   UpdateHUD(total);
   CheckTradingSignals(total);

   return total;
}

// Calculation functions (same as original but optimized for scalping)
void CalculateATRAverage(int start, int total)
{
   for(int i = start; i >= 0; i--)
   {
      if(i >= total) continue;
      double currentATR = i < ArraySize(CustomATRBuffer) ? CustomATRBuffer[i] : 0.0;
      
      if(i < total - InpATRPeriod * 3)
      {
         double sum = 0; int count = 0;
         for(int j = 0; j < InpATRPeriod * 3; j++)
         {
            int idx = i + j;
            if(idx < total && idx < ArraySize(CustomATRBuffer))
            {
               sum += CustomATRBuffer[idx];
               count++;
            }
         }
         CustomATRAvgBuffer[i] = (count > 0) ? (sum / count) : currentATR;
      }
      else
         CustomATRAvgBuffer[i] = currentATR;
   }
}

void ClearOverlays(int start, int total)
{
   for(int i = start; i >= 0; i--)
   {
      if(i >= total) continue;
      MomSpikeBuffer[i] = EMPTY_VALUE;
      QualityGlowBuffer[i] = EMPTY_VALUE;
      ConfluenceBuffer[i] = EMPTY_VALUE;
      VolRegimeBuffer[i] = EMPTY_VALUE;
      DivergenceBuffer[i] = EMPTY_VALUE;
      TradingZoneBuffer[i] = EMPTY_VALUE;
   }
}

void CalculateSpeed(int i, int total, const double &close[], double scale)
{
   if(i <= total - InpSpeedPeriod - 1 && i < ArraySize(SpeedBuffer) && i + InpSpeedPeriod < ArraySize(close))
   {
      double pts = (close[i] - close[i + InpSpeedPeriod]) / _Point;
      double rs = (pts / InpSpeedPeriod) * scale;
      RawSpeedBuffer[i] = rs;
      double alpha = 2.0 / (InpSpeedSmooth + 1.0);
      SpeedBuffer[i] = (i == total - InpSpeedPeriod - 1) ? (rs * InpSpeedMultiplier) :
                       (alpha * (rs * InpSpeedMultiplier) + (1.0 - alpha) * 
                       (i + 1 < ArraySize(SpeedBuffer) ? SpeedBuffer[i + 1] : 0.0));
   }
   else
   {
      RawSpeedBuffer[i] = 0.0;
      SpeedBuffer[i] = 0.0;
   }
}

void CalculateDistance(int i, int total, const double &close[])
{
   if(i < total - 1 && i < ArraySize(DistanceBuffer) && i + 1 < ArraySize(close))
      DistanceBuffer[i] = DistanceBuffer[i + 1] + MathAbs((close[i] - close[i + 1]) / _Point);
   else
      DistanceBuffer[i] = 0.0;
}

void CalculateAcceleration(int i, int total, double highThr, double lowThr)
{
   if(i <= total - InpSpeedPeriod - 2 && i < total - 1 && i < ArraySize(AccelBuffer) && 
      i + 1 < ArraySize(SpeedBuffer))
   {
      double acc = (SpeedBuffer[i] - SpeedBuffer[i + 1]) * (InpAccelMultiplier / InpSpeedMultiplier);
      AccelBuffer[i] = acc;
      int col = 2;
      if(SpeedBuffer[i] > 0 && acc > 0) col = 0;
      else if(SpeedBuffer[i] < 0 && acc < 0) col = 1;
      AccelColors[i] = col;
   }
   else
   {
      AccelBuffer[i] = 0.0;
      AccelColors[i] = 2;
   }
}

void CalculateJerk(int i, int total)
{
   if(i <= total - InpSpeedPeriod - 3 && i < total - 1 && i < ArraySize(JerkBuffer) && 
      i + 1 < ArraySize(AccelBuffer))
   {
      double jr = AccelBuffer[i] - AccelBuffer[i + 1];
      double aj = 2.0 / (MathMax(1, InpJerkSmooth) + 1.0);
      JerkBuffer[i] = (i == total - InpSpeedPeriod - 3) ? jr : 
                      (aj * jr + (1.0 - aj) * (i + 1 < ArraySize(JerkBuffer) ? JerkBuffer[i + 1] : 0.0));
   }
   else JerkBuffer[i] = 0.0;
}

void CalculateMomentum(int i, int total, double highThr)
{
   if(i <= total - InpSpeedPeriod - 2 && i < total - 1 && i < ArraySize(MomentumBuffer) && 
      i + 1 < ArraySize(MomentumBuffer))
   {
      double nS = (highThr != 0.0) ? MathMax(-1.0, MathMin(1.0, SpeedBuffer[i] / highThr)) : 0.0;
      double nA = (InpAccelMultiplier != 0.0) ? MathMax(-1.0, MathMin(1.0, AccelBuffer[i] / InpAccelMultiplier)) : 0.0;
      double comb = nS * InpSpeedWeight + nA * InpAccelWeight;
      double raw = comb * highThr * InpMomentumScale;
      double mA = 2.0 / (InpMomentumSmooth + 1.0);
      MomentumBuffer[i] = (i == total - InpSpeedPeriod - 2) ? raw : 
                          (mA * raw + (1.0 - mA) * (i + 1 < ArraySize(MomentumBuffer) ? MomentumBuffer[i + 1] : 0.0));
   }
   else MomentumBuffer[i] = 0.0;
   
   if(!MathIsValidNumber(MomentumBuffer[i])) MomentumBuffer[i] = 0.0;
}

void CalculateTrendQuality(int i, int total, double highThr)
{
   if(i <= total - InpTrendQualityPeriod - InpSpeedPeriod - 2 && i < total - InpTrendQualityPeriod && 
      i < ArraySize(TrendQualityBuffer))
   {
      double sC = 0, aA = 0, mag = 0; int v = 0;
      for(int j = 0; j < InpTrendQualityPeriod; j++)
      {
         int k = i + j;
         if(k + 1 >= total || k >= ArraySize(RawSpeedBuffer) || k + 1 >= ArraySize(RawSpeedBuffer)) break;
         if(RawSpeedBuffer[k] * RawSpeedBuffer[k + 1] > 0) sC++;
         if(k < ArraySize(AccelBuffer) && k < ArraySize(SpeedBuffer))
            if(AccelBuffer[k] * SpeedBuffer[k] > 0) aA++;
         if(k < ArraySize(RawSpeedBuffer))
            mag += MathAbs(RawSpeedBuffer[k]);
         v++;
      }
      double q = 0.0;
      if(v > 0)
      {
         double magAvg = mag / v;
         double denom = MathMax(1.0, MathAbs(highThr) * 0.5);
         double mag01 = MathMin(1.0, (magAvg * InpSpeedMultiplier) / denom);
         q = (sC / v) * 40.0 + (aA / v) * 40.0 + (mag01 * 100.0 * InpQualityMagWeight);
      }
      TrendQualityBuffer[i] = q;
      int qc = (q >= 75.0) ? 0 : (q >= 50.0) ? 1 : (q >= 25.0) ? 2 : 3;
      QualColors[i] = qc;
      if(q >= 60.0 && i < ArraySize(QualityGlowBuffer)) QualityGlowBuffer[i] = q; // SCALP: 60 vs 75
      if(i < ArraySize(ZoneQualityHistory)) ZoneQualityHistory[i] = q;
   }
   else TrendQualityBuffer[i] = 0.0;
}

void CalculateDistanceROC(int i, int total)
{
   if(i <= total - InpDistanceROCPeriod - 1 && i < total - InpDistanceROCPeriod && 
      i < ArraySize(DistanceROCBuffer))
   {
      double dchg = DistanceBuffer[i] - DistanceBuffer[i + InpDistanceROCPeriod];
      DistanceROCBuffer[i] = (dchg / InpDistanceROCPeriod) * InpDistanceROCScale;
   }
   else DistanceROCBuffer[i] = 0.0;
}

void CalculateBias(int i, double highThr, double lowThr)
{
   if(i < ArraySize(SpeedBuffer) && i < ArraySize(AccelBuffer))
   {
      int bias = 0;
      // SCALP: More permissive bias detection (0.15 vs 0.25)
      if(SpeedBuffer[i] > 0 && AccelBuffer[i] > 0 && SpeedBuffer[i] > 0.15 * highThr) bias = 1;
      else if(SpeedBuffer[i] < 0 && AccelBuffer[i] < 0 && SpeedBuffer[i] < 0.15 * lowThr) bias = -1;
      BiasBuffer[i] = bias;
   }
   else BiasBuffer[i] = 0;
}

void CalculateMomentumSpikes(int i, int total, double highThr, double lowThr)
{
   if(i < total - 1 && i < ArraySize(MomSpikeBuffer) && i < ArraySize(MomentumBuffer) && 
      i + 1 < ArraySize(MomentumBuffer))
   {
      bool upCross = (MomentumBuffer[i] >= highThr && MomentumBuffer[i + 1] < highThr);
      bool downCross = (MomentumBuffer[i] <= lowThr && MomentumBuffer[i + 1] > lowThr);
      if(upCross) { MomSpikeBuffer[i] = highThr * 0.06; MomSpikeColors[i] = 0; }
      else if(downCross) { MomSpikeBuffer[i] = lowThr * 0.06; MomSpikeColors[i] = 1; }
   }
}

void CalculateConfluence(int i, int total, double highThr)
{
   if(InpShowConfluence && i <= total - InpSpeedPeriod - 2 && i < ArraySize(ConfluenceBuffer))
   {
      int confluence = 0;
      if(i < ArraySize(TrendQualityBuffer) && TrendQualityBuffer[i] >= InpConfluenceQualMin) confluence++;
      if(i < ArraySize(SpeedBuffer) && MathAbs(SpeedBuffer[i]) >= InpConfluenceSpeedMin * highThr) confluence++;
      if(i < ArraySize(AccelBuffer) && i < ArraySize(SpeedBuffer) && SpeedBuffer[i] * AccelBuffer[i] > 0) confluence++;
      if(i < ArraySize(MomentumBuffer) && MathAbs(MomentumBuffer[i]) > highThr * 0.4) confluence++; // SCALP: 0.4 vs 0.5
      if(i < ArraySize(DistanceROCBuffer) && DistanceROCBuffer[i] > 0) confluence++;
      
      ConfluenceBuffer[i] = confluence * 20.0;
      int confCol = (confluence >= 4) ? 4 : (confluence >= 3) ? 3 : (confluence >= 2) ? 2 : (confluence >= 1) ? 1 : 0;
      ConfluenceColors[i] = confCol;
   }
}

void CalculateVolRegime(int i, double atr_val, double atr_avg_val)
{
   if(InpShowVolRegime && atr_avg_val > 0 && i < ArraySize(VolRegimeBuffer))
   {
      double atrRatio = atr_val / atr_avg_val;
      VolRegimeBuffer[i] = atrRatio * 50.0;
      int volCol = (atrRatio < InpVolLowThreshold) ? 0 : (atrRatio > InpVolHighThreshold) ? 2 : 1;
      VolRegimeColors[i] = volCol;
   }
}

void CalculateTradingZone(int i, int total)
{
   if(InpShowTradingZones && i <= total - InpSpeedPeriod - 2 && i < ArraySize(TradingZoneBuffer))
   {
      double zoneMin = InpZoneQualityMin;
      if (InpAdaptiveZones && i <= total - InpZoneHistoryPeriod && i < ArraySize(ZoneQualityHistory))
      {
         double temp[];
         ArrayResize(temp, InpZoneHistoryPeriod);
         ArrayCopy(temp, ZoneQualityHistory, 0, i, InpZoneHistoryPeriod);
         zoneMin = CalculatePercentile(temp, InpZoneHistoryPeriod, InpZonePercentile);
      }
      
      int zone = 3;
      if(i < ArraySize(TrendQualityBuffer) && TrendQualityBuffer[i] >= zoneMin)
      {
         if(i < ArraySize(BiasBuffer) && i < ArraySize(MomentumBuffer))
         {
            if(BiasBuffer[i] == 1 && MomentumBuffer[i] > 0) zone = 0;
            else if(BiasBuffer[i] == -1 && MomentumBuffer[i] < 0) zone = 1;
            else if(MathAbs(MomentumBuffer[i]) > HighThresholdBuffer[i] * 0.25) zone = 2; // SCALP: 0.25 vs 0.3
         }
      }
      TradingZoneBuffer[i] = zone * 25.0;
      ZoneColors[i] = zone;
   }
}

void DetectDivergence(int start, int total, const double &high[], const double &low[])
{
   if(InpShowDivergence)
   {
      for(int i = MathMax(start, InpDivergenceLookback); i >= 0; i--)
      {
         if(i >= total - InpSpeedPeriod - 2 || i >= ArraySize(DivergenceBuffer)) continue;
         
         double divHighThr = i < ArraySize(HighThresholdBuffer) ? HighThresholdBuffer[i] : 0.0;
         double divLowThr = i < ArraySize(LowThresholdBuffer) ? LowThresholdBuffer[i] : 0.0;
         
         bool bullDiv = false;
         bool bearDiv = false;
         
         for(int j = 3; j < InpDivergenceLookback; j++) // SCALP: Start at 3 vs 5
         {
            int idx = i + j;
            if(idx >= total || idx >= ArraySize(PriceLowBuffer) || idx >= ArraySize(MomentumBuffer)) break;
            
            double priceDiffLow = low[i] - low[idx];
            double momDiff = MomentumBuffer[i] - MomentumBuffer[idx];
            
            if(priceDiffLow < -InpDivergenceMinDiff * _Point && momDiff > InpDivergenceMinDiff)
            {
               double priceSlope = (low[i] - low[idx]) / j;
               double momSlope = (MomentumBuffer[i] - MomentumBuffer[idx]) / j;
               if (MathAbs(priceSlope) > InpDivergenceSlopeThresh && MathAbs(momSlope) > InpDivergenceSlopeThresh) {
                  bullDiv = true;
               }
               break;
            }
            
            double priceDiffHigh = high[i] - high[idx];
            if(priceDiffHigh > InpDivergenceMinDiff * _Point && momDiff < -InpDivergenceMinDiff)
            {
               double priceSlope = (high[i] - high[idx]) / j;
               double momSlope = (MomentumBuffer[i] - MomentumBuffer[idx]) / j;
               if (MathAbs(priceSlope) > InpDivergenceSlopeThresh && MathAbs(momSlope) > InpDivergenceSlopeThresh) {
                  bearDiv = true;
               }
               break;
            }
         }
         
         if(bullDiv) { DivergenceBuffer[i] = divLowThr; DivergenceColors[i] = 0; }
         else if(bearDiv) { DivergenceBuffer[i] = divHighThr; DivergenceColors[i] = 1; }
      }
   }
}

void UpdateHUD(int total)
{
   if(InpShowHUD && total > 2)
   {
      int hudIdx = 1;
      if(hudIdx >= total) hudIdx = 0;
      
      string up = "↑", dn = "↓";
      double hudATR = hudIdx < ArraySize(CustomATRBuffer) ? CustomATRBuffer[hudIdx] : 0.0;
      double hudATRAvg = hudIdx < ArraySize(CustomATRAvgBuffer) ? CustomATRAvgBuffer[hudIdx] : 0.0;
      double atrPts = (hudATR > 0.0) ? (hudATR / _Point) : AutoRefPoints();
      
      string biasStr = "NEUTRAL";
      if(hudIdx < ArraySize(BiasBuffer))
         biasStr = (BiasBuffer[hudIdx] > 0 ? "🟢 BULL" : (BiasBuffer[hudIdx] < 0 ? "🔴 BEAR" : "⚪ NEUTRAL"));
      
      string volRegime = "N/A";
      if(InpShowVolRegime && hudATRAvg > 0)
      {
         double ratio = hudATR / hudATRAvg;
         volRegime = (ratio < InpVolLowThreshold ? "😴 LOW" : (ratio > InpVolHighThreshold ? "🔥 HIGH" : "📊 NORM"));
      }
      
      int confScore = 0;
      if(InpShowConfluence && hudIdx < ArraySize(ConfluenceBuffer))
         confScore = (int)(ConfluenceBuffer[hudIdx] / 20.0);
      
      double momValue = hudIdx < ArraySize(MomentumBuffer) ? MomentumBuffer[hudIdx] : 0.0;
      double momPrev = hudIdx + 1 < ArraySize(MomentumBuffer) ? MomentumBuffer[hudIdx + 1] : 0.0;
      string momArrow = (momValue > momPrev) ? up : dn;
      
      double qualValue = hudIdx < ArraySize(TrendQualityBuffer) ? TrendQualityBuffer[hudIdx] : 0.0;
      double qualPrev = hudIdx + 1 < ArraySize(TrendQualityBuffer) ? TrendQualityBuffer[hudIdx + 1] : 0.0;
      string qualArrow = (qualValue > qualPrev) ? up : dn;
      
      string zoneStr = "N/A";
      if(hudIdx < ArraySize(TradingZoneBuffer))
      {
         int zone = (int)(TradingZoneBuffer[hudIdx] / 25.0);
         zoneStr = (zone == 0 ? "🟢 BULL" : (zone == 1 ? "🔴 BEAR" : (zone == 2 ? "🟡 TRAN" : "⚫ AVOID")));
      }
      
      double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double spreadPips = spread / (_Point * 10);
      
      // Scalper HUD with spread monitoring
      string hud = StringFormat(
         "╔═══════════════════════════════════╗\n"
         "║  ⚡ SCALPER - %s M1         \n"
         "╠═══════════════════════════════════╣\n"
         "║  BIAS: %-27s║\n"
         "║  ZONE: %-27s║\n"
         "╠═══════════════════════════════════╣\n"
         "║  ATR:   %-6.0f  | Vol: %-10s║\n"
         "║  SPREAD: %-4.1f pips              ║\n"
         "║  CONF:  %-1d/5    | Qual: %-3.0f%-2s    ║\n"
         "║  MOM:   %-6.1f%-2s                 ║\n"
         "╠═══════════════════════════════════╣\n"
         "║  🎯 TARGET: 40 pips | 30 trades  ║\n"
         "╚═══════════════════════════════════╝",
         _Symbol,
         biasStr,
         zoneStr,
         atrPts, volRegime,
         spreadPips,
         confScore, qualValue, qualArrow,
         momValue, momArrow
      );
      
      ObjectSetString(0, HUD_NAME, OBJPROP_TEXT, hud);
      
      // Set color based on bias
      color hudClr = clrWhite;
      if(hudIdx < ArraySize(BiasBuffer))
      {
         if(BiasBuffer[hudIdx] > 0) 
            hudClr = clrLimeGreen;
         else if(BiasBuffer[hudIdx] < 0) 
            hudClr = clrTomato;
         else 
            hudClr = clrGold;
      }
      ObjectSetInteger(0, HUD_NAME, OBJPROP_COLOR, hudClr);
   }
}

void CheckTradingSignals(int total)
{
   if(!InpShowAlerts || total < 3) return;
   
   int idx = 1;
   if(idx >= total) return;
   
   // SCALP: More aggressive signal alerts (60% confluence vs 80%)
   if(idx < ArraySize(ConfluenceBuffer) && idx < ArraySize(TrendQualityBuffer))
   {
      if(ConfluenceBuffer[idx] >= 60.0 && TrendQualityBuffer[idx] >= 60.0)
      {
         string bias = (idx < ArraySize(BiasBuffer)) ? 
                      (BiasBuffer[idx] > 0 ? "BULL" : "BEAR") : "NEUTRAL";
         TriggerAlert(StringFormat("🎯 SCALP SETUP | %s | C:%.0f Q:%.0f", 
                                  bias, ConfluenceBuffer[idx], TrendQualityBuffer[idx]));
      }
   }
   
   // Check for divergence (important for reversals)
   if(idx < ArraySize(DivergenceBuffer) && DivergenceBuffer[idx] != EMPTY_VALUE)
   {
      string divType = (idx < ArraySize(DivergenceColors) && DivergenceColors[idx] == 0) ? 
                      "BULL" : "BEAR";
      TriggerAlert(StringFormat("⚠️ DIV | %s", divType));
   }
   
   // Check for momentum threshold crosses
   if(idx < ArraySize(MomentumBuffer) && idx < ArraySize(HighThresholdBuffer))
   {
      if(idx + 1 < ArraySize(MomentumBuffer))
      {
         bool bullCross = MomentumBuffer[idx] > HighThresholdBuffer[idx] && 
                         MomentumBuffer[idx+1] <= HighThresholdBuffer[idx];
         bool bearCross = MomentumBuffer[idx] < -HighThresholdBuffer[idx] && 
                         MomentumBuffer[idx+1] >= -HighThresholdBuffer[idx];
         
         if(bullCross)
            TriggerAlert("🚀 MOM BREAK | BULL!");
         if(bearCross)
            TriggerAlert("📉 MOM BREAK | BEAR!");
      }
   }
}

//============================= DEINIT ===============================//
void OnDeinit(const int reason)
{
   if(ObjectFind(0, HUD_NAME) != -1)
      ObjectDelete(0, HUD_NAME);
   if(ObjectFind(0, HUD_BG_NAME) != -1)
      ObjectDelete(0, HUD_BG_NAME);
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);
      
   Print("⚡ TickPhysics 1M SCALPER v2.1 deinitialized. Reason: ", reason);
}
//+------------------------------------------------------------------+
