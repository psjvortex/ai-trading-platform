//+------------------------------------------------------------------+
//|                       TP_Integrated_EA_Crossover_3_1_0.mq5       |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|             v3.10 - PRODUCTION READY (QA APPROVED)               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "3.10"
#property description "v3.10 EA with Universal Elite v3.1 Indicator Support - QA APPROVED"

// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "3.10_PRODUCTION"

input int MagicNumber = 300310;                       // EA magic number
input string TradeComment = "TP_Integrated 3_10";      // Trade comment

// Indicator Version Selection
enum INDICATOR_VERSION
{
   INDICATOR_AUTO = 0,      // Auto-detect from symbol
   INDICATOR_CRYPTO = 1,    // TickPhysics_Crypto_Indicator_v2_1
   INDICATOR_FOREX = 2,     // TickPhysics_Forex_Indicator_v2_1
   INDICATOR_INDICES = 3,   // TickPhysics_Indices_Indicator_v2_1
   INDICATOR_UNIVERSAL = 4  // TickPhysics_Universal_Elite_v3_1 (RECOMMENDED)
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
input double      RiskPercentPerTrade     = 2.0;         // Risk per trade (% of balance)
input double      MaxDailyRisk            = 10.0;        // Max daily risk (% of balance)
input int         MaxConcurrentTrades     = 1;           // Max concurrent positions
input double      MinRRatio               = 1.0;         // Min reward:risk ratio

// === Trade Parameters ===
input group "📊 Trade Parameters"
input int         StopLossPips            = 5000;        // Stop loss (pips) - REALISTIC DEFAULT
input int         TakeProfitPips          = 10000;       // Take profit (pips) - 2:1 R:R
input bool        UseTrailingStop         = false;       // Enable trailing stop
input int         TrailingStopPips        = 30;          // Trailing stop (pips)

// === Entry System Selection ===
input group "📊 Entry Logic"
input INDICATOR_VERSION    IndicatorVersion           = INDICATOR_AUTO;  // Indicator version to use (UNIVERSAL recommended)
input bool                 UsePhysicsEntry            = false;           // Use physics acceleration crossover
input bool                 UseMAEntry                 = false;           // Use Moving Average crossover
input bool                 UsePhysicsFiltersAsEntry   = true;            // Use physics filters as entry triggers
input int                  MA_Fast                    = 10;              // Fast MA period
input int                  MA_Slow                    = 50;              // Slow MA period
input ENUM_MA_METHOD       MA_Method                  = MODE_EMA;        // MA calculation method
input ENUM_APPLIED_PRICE   MA_Price                   = PRICE_CLOSE;     // MA price type

// === Signal Filters (v4.0 OPTIMIZED) ===
input group "🎯 Physics Filters v4.0"
input bool                 UsePhysicsFilters          = true;            // Enable physics filtering
input double               MinQuality                 = 70.0;            // Min physics quality (v4.0 threshold)
input bool                 AvoidTransitionZone        = false;           // Reject TRANSITION/AVOID zones
input bool                 UseRegimeFilter            = false;           // Filter by volatility regime

// === Acceleration/Speed/Momentum Filters ===
input group "⚡ Advanced Physics Entry Filters"
input bool                 UseAccelerationFilter      = true;            // Enable acceleration threshold
input double               MinAccelerationBuy         = 100.0;           // Min acceleration for BUY (positive)
input double               MinAccelerationSell        = 100.0;           // Min acceleration for SELL (absolute value)
input bool                 UseSpeedFilter             = false;           // Enable speed threshold
input double               MinSpeedBuy                = 55.0;            // Min speed for BUY (positive)
input double               MinSpeedSell               = 55.0;            // Min speed for SELL (absolute value)
input bool                 UseMomentumFilter          = false;           // Enable momentum threshold
input double               MinMomentumBuy             = 40.0;            // Min momentum for BUY (positive)
input double               MinMomentumSell            = 40.0;            // Min momentum for SELL (absolute value)

// === Monitoring ===
input group "📈 Post-Trade Monitoring"
input int                  PostExitMonitorBars        = 50;              // RunUp/RunDown monitor bars
input bool                 EnableRealTimeLogging      = true;            // Log signals in real-time

// === Advanced ===
input group "⚙️ Advanced Settings"
input bool                 EnableDebugMode            = true;            // Verbose logging
input bool                 BypassAllFilters           = false;           // TESTING: Bypass all filters
input bool                 DryRunMode                 = false;           // TESTING: Log signals but don't trade
input bool                 EnableFilterAlerts         = false;           // Alert when filters block signals

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
   Print("📊 Loading indicator on chart: ", indicatorName);
   
   // Create indicator handle first (this validates it exists)
   int handle = iCustom(_Symbol, _Period, indicatorName);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Failed to create indicator handle for: ", indicatorName);
      return false;
   }
   
   // Add indicator to chart
   bool added = ChartIndicatorAdd(0, 1, handle);
   if(added)
   {
      g_indicatorSubwindow = 1;
      Print("✅ Successfully loaded ", indicatorName, " on chart (subwindow 1)");
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
      // Crypto detection (BTC, ETH, crypto pairs)
      if(StringFind(sym, "BTC") >= 0 || StringFind(sym, "ETH") >= 0 || 
         StringFind(sym, "XRP") >= 0 || StringFind(sym, "SOL") >= 0 ||
         StringFind(sym, "ADA") >= 0 || StringFind(sym, "DOGE") >= 0)
      {
         Print("📊 Auto-detected CRYPTO symbol: Using TickPhysics_Crypto_Indicator_v2_1");
         return "TickPhysics_Crypto_Indicator_v2_1";
      }
      
      // Indices detection (NAS100, US30, SPX500, etc.)
      if(StringFind(sym, "NAS") >= 0 || StringFind(sym, "US30") >= 0 || 
         StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 ||
         StringFind(sym, "DOW") >= 0 || StringFind(sym, "DAX") >= 0 ||
         StringFind(sym, "FTSE") >= 0 || StringFind(sym, "NIKKEI") >= 0)
      {
         Print("📊 Auto-detected INDICES symbol: Using TickPhysics_Indices_Indicator_v2_1");
         return "TickPhysics_Indices_Indicator_v2_1";
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
         
      case INDICATOR_UNIVERSAL:
         Print("📊 Manual selection: Using TickPhysics_Universal_Elite_v3_1 (RECOMMENDED)");
         return "TickPhysics_Universal_Elite_v3_1";
         
      default:
         Print("⚠️ Unknown indicator version, defaulting to UNIVERSAL");
         return "TickPhysics_Universal_Elite_v3_1";
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
         Print("❌ ERROR: Invalid physics data (failure #", g_consecutiveBufferFailures, ")");
      
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
   int total = ObjectsTotal(0, 0, OBJ_LABEL);
   
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
   
   ChartRedraw();
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
   
   // QA FIX: Throttle updates to configured interval
   datetime currentTime = TimeCurrent();
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
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
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
   bool qualityPass = (quality >= MinQuality);
   string qualityIcon = qualityPass ? "[PASS]" : "[FAIL]";
   color qualityColor = qualityPass ? clrLimeGreen : clrRed;
   UpdateLabel("DASH_Quality", StringFormat("Quality: %.1f %s", quality, qualityIcon), qualityColor);
   
   // Confluence
   UpdateLabel("DASH_Conflu", StringFormat("Conflu: %.1f", confluence), clrSilver);
   
   // Momentum
   color momentumColor = momentum > 0 ? clrLimeGreen : (momentum < 0 ? clrRed : clrGray);
   UpdateLabel("DASH_Momentum", StringFormat("Momentum: %.1f", momentum), momentumColor);
   
   // Speed
   UpdateLabel("DASH_Speed", StringFormat("Speed: %.1f", speed), clrSilver);
   
   // Acceleration
   UpdateLabel("DASH_Accel", StringFormat("Accel: %.1f", accel), clrSilver);
   
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
      
      if(CopyBuffer(g_maFastHandle, 0, 0, 1, maFastArr) > 0 && 
         CopyBuffer(g_maSlowHandle, 0, 0, 1, maSlowArr) > 0)
      {
         maFast = maFastArr[0];
         maSlow = maSlowArr[0];
         signal = maFast > maSlow ? 1 : (maFast < maSlow ? -1 : 0);
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
         accelPass = (MathAbs(accel) >= MinAccelerationSell);
   }
   
   if(UseSpeedFilter && signal != 0 && !BypassAllFilters)
   {
      if(signal > 0)
         speedPass = (speed >= MinSpeedBuy);
      else
         speedPass = (MathAbs(speed) >= MinSpeedSell);
   }
   
   if(UseMomentumFilter && signal != 0 && !BypassAllFilters)
   {
      if(signal > 0)
         momentumPass = (momentum >= MinMomentumBuy);
      else
         momentumPass = (MathAbs(momentum) >= MinMomentumSell);
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
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinAccelerationBuy) : StringFormat("|accel| >= %.1f", MinAccelerationSell);
      UpdateLabel("DASH_FilterAccel", StringFormat("Accel: %.1f %s %s", accel, threshold, aStatus), aColor);
   }
   
   // Speed filter
   if(!UseSpeedFilter)
      UpdateLabel("DASH_FilterSpeed", "Speed: DISABLED", clrGold);
   else
   {
      string sStatus = speedPass ? "[PASS]" : "[FAIL]";
      color sColor = speedPass ? clrLimeGreen : clrRed;
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinSpeedBuy) : StringFormat("|speed| >= %.1f", MinSpeedSell);
      UpdateLabel("DASH_FilterSpeed", StringFormat("Speed: %.1f %s %s", speed, threshold, sStatus), sColor);
   }
   
   // Momentum filter
   if(!UseMomentumFilter)
      UpdateLabel("DASH_FilterMomentum", "Momentum: DISABLED", clrGold);
   else
   {
      string mStatus = momentumPass ? "[PASS]" : "[FAIL]";
      color mColor = momentumPass ? clrLimeGreen : clrRed;
      string threshold = signal > 0 ? StringFormat(">= %.1f", MinMomentumBuy) : StringFormat("|momentum| >= %.1f", MinMomentumSell);
      UpdateLabel("DASH_FilterMomentum", StringFormat("Momentum: %.1f %s %s", momentum, threshold, mStatus), mColor);
   }
   
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
   
   // QA FIX: Validate stop loss is reasonable
   if(StopLossPips <= 0)
   {
      Print("❌ ERROR: Stop loss must be greater than 0!");
      return INIT_FAILED;
   }
   
   if(StopLossPips > 500)
   {
      string symLower = _Symbol;
      StringToLower(symLower);
      if(StringFind(symLower, "usd") >= 0 && StringFind(symLower, "btc") < 0)
      {
         Print("⚠️ WARNING: Stop loss ", StopLossPips, " pips is very large for forex!");
         Print("   Recommended: 20-150 pips for forex pairs");
         Print("   Current setting may result in excessive risk");
      }
   }
   
   // 0. Determine which indicator to use
   g_indicatorName = GetIndicatorName(IndicatorVersion);
   
   // 1. Initialize Physics Indicator
   Print("📊 Initializing Physics Indicator...");
   if(!g_physics.Initialize(g_indicatorName, EnableDebugMode))
   {
      Print("❌ FAILED: Physics Indicator initialization");
      Print("   Could not find indicator: ", g_indicatorName);
      Print("   Expected location: Indicators/", g_indicatorName, ".ex5");
      Print("   Make sure the indicator is compiled and in the correct folder");
      return INIT_FAILED;
   }
   Print("✅ Physics Indicator ready: ", g_indicatorName);
   
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
   Print("   Indicator: ", g_indicatorName);
   
   // Entry mode display
   string entrySystem = "NONE";
   if(UsePhysicsEntry)
      entrySystem = "PHYSICS CROSSOVER";
   else if(UseMAEntry)
      entrySystem = "MA CROSSOVER";
   else if(UsePhysicsFiltersAsEntry)
      entrySystem = "PHYSICS FILTERS AS TRIGGERS";
   Print("   Entry System: ", entrySystem);
   
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   Print("   Physics Filters: ", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED ⚠️");
   if(UsePhysicsFilters)
   {
      Print("   → Quality Filter: >= ", MinQuality, "%");
      Print("   → Zone Filter: ", AvoidTransitionZone ? "REJECT TRANSITION/AVOID" : "DISABLED");
   }
   Print("   Advanced Filters:");
   Print("   → Acceleration: ", UseAccelerationFilter ? "ENABLED" : "DISABLED");
   if(UseAccelerationFilter)
      Print("      BUY >= ", MinAccelerationBuy, ", SELL |accel| >= ", MinAccelerationSell);
   Print("   → Speed: ", UseSpeedFilter ? "ENABLED" : "DISABLED");
   if(UseSpeedFilter)
      Print("      BUY >= ", MinSpeedBuy, ", SELL |speed| >= ", MinSpeedSell);
   Print("   → Momentum: ", UseMomentumFilter ? "ENABLED" : "DISABLED");
   if(UseMomentumFilter)
      Print("      BUY >= ", MinMomentumBuy, ", SELL |momentum| >= ", MinMomentumSell);
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   SL/TP: ", StopLossPips, "/", TakeProfitPips, " pips");
   
   // Special modes
   if(BypassAllFilters)
      Print("   ⚠️ BYPASS MODE: All filters disabled!");
   if(DryRunMode)
      Print("   ⚠️ DRY RUN MODE: No trades will be executed!");
   
   Print("   Dashboard: Update every ", DashboardUpdateSeconds, " seconds");
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
   Print("   Reason: ", reason);
   
   // Display data validation statistics
   if(g_bufferUpdateFailures > 0)
   {
      Print("📊 Physics Data Statistics:");
      Print("   Total Validation Failures: ", g_bufferUpdateFailures);
      Print("   Last Valid Data: ", TimeToString(g_lastBufferUpdateTime));
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
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      LogCompletedTrade(trade);
      logged++;
   }
   
   if(logged > 0)
      Print("✅ Logged ", logged, " completed trades to CSV");
   
   Print("═══════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized) return;
   
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
//+------------------------------------------------------------------+
int GeneratePhysicsFilterSignal()
{
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   double momentum = g_physics.GetMomentum(0);
   double quality = g_physics.GetQuality();
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
   
   // BUY CONDITIONS: All physics metrics must be positive AND above thresholds
   bool buyConditions = true;
   
   if(UsePhysicsFilters && quality < MinQuality)
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
         Print("📈 PHYSICS BUY: Speed=", speed, " Accel=", accel, " Momentum=", momentum, " Quality=", quality);
   }
   
   // SELL CONDITIONS: All physics metrics must be negative AND below thresholds (in absolute terms)
   bool sellConditions = true;
   
   if(UsePhysicsFilters && quality < MinQuality)
      sellConditions = false;
   
   if(AvoidTransitionZone && (zone == ZONE_TRANSITION || zone == ZONE_AVOID))
      sellConditions = false;
   
   if(UseSpeedFilter && MathAbs(speed) < MinSpeedSell)
      sellConditions = false;
   
   if(UseAccelerationFilter && MathAbs(accel) < MinAccelerationSell)
      sellConditions = false;
   
   if(UseMomentumFilter && MathAbs(momentum) < MinMomentumSell)
      sellConditions = false;
   
   // Check for bearish breakthrough (crossing below negative thresholds)
   bool speedBreakthroughSell = (MathAbs(g_prevSpeed) < MinSpeedSell && MathAbs(speed) >= MinSpeedSell && speed < 0);
   bool accelBreakthroughSell = (MathAbs(g_prevAccel) < MinAccelerationSell && MathAbs(accel) >= MinAccelerationSell && accel < 0);
   bool momentumBreakthroughSell = (MathAbs(g_prevMomentum) < MinMomentumSell && MathAbs(momentum) >= MinMomentumSell && momentum < 0);
   
   if(sellConditions && (speedBreakthroughSell || accelBreakthroughSell || momentumBreakthroughSell))
   {
      signal = -1;  // SELL
      if(EnableDebugMode)
         Print("📉 PHYSICS SELL: Speed=", speed, " Accel=", accel, " Momentum=", momentum, " Quality=", quality);
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
         Print("📈 MA BUY Signal: Fast(", maFast[0], ") > Slow(", maSlow[0], ")");
      return 1;
   }
   
   // SELL: Fast crosses below Slow
   if(maFast[2] > maSlow[2] && maFast[0] < maSlow[0])
   {
      if(EnableDebugMode)
         Print("📉 MA SELL Signal: Fast(", maFast[0], ") < Slow(", maSlow[0], ")");
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| New bar handler                                                   |
//+------------------------------------------------------------------+
void OnNewBar()
{
   // QA FIX: Validate physics data is available before generating signals
   if(!ValidatePhysicsData())
   {
      Print("❌ CRITICAL: Cannot generate signals - physics data validation failed");
      return;
   }
   
   // 1. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 2. Log signal
   if(EnableRealTimeLogging && signal != 0)
      LogSignal(signal, quality, confluence, zone, regime);
   
   // Track signal count
   if(signal != 0)
      g_signalsToday++;
   
   if(signal == 0) return;
   
   // NOTE: When UsePhysicsFiltersAsEntry=true, filters are ALREADY CHECKED in GeneratePhysicsFilterSignal()
   // So we only apply filters if using MA or Physics crossover entry
   
   string rejectReason = "";
   bool passFilters = true;
   
   if((UseMAEntry || UsePhysicsEntry) && UsePhysicsFilters && !BypassAllFilters)
   {
      // Quality filter (PRIMARY)
      if(quality < MinQuality)
      {
         passFilters = false;
         rejectReason = "Quality_Too_Low";
         if(EnableDebugMode)
            Print("❌ Filter FAIL: Quality ", quality, " < ", MinQuality);
      }
      
      // Zone filter (reject TRANSITION and AVOID)
      if(AvoidTransitionZone && (zone == ZONE_TRANSITION || zone == ZONE_AVOID))
      {
         passFilters = false;
         rejectReason = zone == ZONE_TRANSITION ? "TRANSITION_Zone" : "AVOID_Zone";
         if(EnableDebugMode)
            Print("❌ Filter FAIL: ", rejectReason, " detected");
      }
      
      // Acceleration filter - FIXED
      if(UseAccelerationFilter && passFilters)
      {
         if(signal > 0 && accel < MinAccelerationBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("Accel_Too_Low_%.1f<%.1f", accel, MinAccelerationBuy);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: Acceleration ", accel, " < ", MinAccelerationBuy, " (BUY)");
         }
         else if(signal < 0 && MathAbs(accel) < MinAccelerationSell)
         {
            passFilters = false;
            rejectReason = StringFormat("Accel_Too_Weak_|%.1f|<%.1f", accel, MinAccelerationSell);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: |Acceleration| ", MathAbs(accel), " < ", MinAccelerationSell, " (SELL)");
         }
      }
      
      // Speed filter - FIXED
      if(UseSpeedFilter && passFilters)
      {
         if(signal > 0 && speed < MinSpeedBuy)
         {
            passFilters = false;
            rejectReason = StringFormat("Speed_Too_Low_%.1f<%.1f", speed, MinSpeedBuy);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: Speed ", speed, " < ", MinSpeedBuy, " (BUY)");
         }
         else if(signal < 0 && MathAbs(speed) < MinSpeedSell)
         {
            passFilters = false;
            rejectReason = StringFormat("Speed_Too_Weak_|%.1f|<%.1f", speed, MinSpeedSell);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: |Speed| ", MathAbs(speed), " < ", MinSpeedSell, " (SELL)");
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
               Print("❌ Filter FAIL: Momentum ", momentum, " < ", MinMomentumBuy, " (BUY)");
         }
         else if(signal < 0 && MathAbs(momentum) < MinMomentumSell)
         {
            passFilters = false;
            rejectReason = StringFormat("Momentum_Too_Weak_|%.1f|<%.1f", momentum, MinMomentumSell);
            if(EnableDebugMode)
               Print("❌ Filter FAIL: |Momentum| ", MathAbs(momentum), " < ", MinMomentumSell, " (SELL)");
         }
      }
      
      if(passFilters && EnableDebugMode)
      {
         Print("✅ Filters PASS: Quality=", quality, ", Zone=", g_physics.GetZoneName(zone));
         if(UseAccelerationFilter)
            Print("   ✅ Accel: ", accel);
         if(UseSpeedFilter)
            Print("   ✅ Speed: ", speed);
         if(UseMomentumFilter)
            Print("   ✅ Momentum: ", momentum);
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
   
   // 8. Calculate position size
   double price = signal > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Convert pips to price distance
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   double slDistance = StopLossPips * point * pipMultiplier;
   
   // QA FIX: Validate SL distance before calculation
   if(slDistance <= 0)
   {
      Print("❌ CRITICAL: Invalid SL distance: ", slDistance);
      Print("   StopLossPips=", StopLossPips, " point=", point, " multiplier=", pipMultiplier);
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
      Print("💼 Position Sizing:");
      Print("   Balance: $", balance);
      Print("   Risk %: ", RiskPercentPerTrade, "%");
      Print("   Risk Money: $", riskMoney);
      Print("   SL Pips: ", StopLossPips);
      Print("   SL Distance: ", slDistance);
      Print("   Calculated Lots: ", lots);
   }
   
   // 9. Execute trade
   ExecuteTrade(signal, lots, price, StopLossPips, TakeProfitPips, quality, confluence, zone, regime);
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
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, double lots, double price, double slPips, double tpPips,
                  double quality, double confluence, TRADING_ZONE zone, VOLATILITY_REGIME regime)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipMultiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   double slDistance = slPips * point * pipMultiplier;
   double tpDistance = tpPips * point * pipMultiplier;
   
   double sl = 0, tp = 0;
   bool success = false;
   ulong ticket = 0;
   
   if(signal > 0)  // BUY
   {
      if(slPips > 0) sl = price - slDistance;
      if(tpPips > 0) tp = price + tpDistance;
      
      success = g_trade.Buy(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   else  // SELL
   {
      if(slPips > 0) sl = price + slDistance;
      if(tpPips > 0) tp = price - tpDistance;
      
      success = g_trade.Sell(lots, _Symbol, price, sl, tp, TradeComment);
      ticket = g_trade.ResultOrder();
   }
   
   if(!success)
   {
      Print("❌ Trade execution failed: ", g_trade.ResultRetcodeDescription());
      return;
   }
   
   Print("✅ Position opened: #", ticket, " | ", signal > 0 ? "BUY" : "SELL", " ", lots, " lots @ ", price);
   
   // Add to tracker
   g_tracker.AddTrade(ticket, quality, confluence, g_physics.GetMomentum(), 
                     g_physics.GetEntropy(), g_physics.GetZoneName(zone), 
                     g_physics.GetRegimeName(regime), RiskPercentPerTrade);
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
   
   bool zonePass = (zone != ZONE_TRANSITION && zone != ZONE_AVOID) || !AvoidTransitionZone;
   entry.physicsPass = BypassAllFilters || (quality >= MinQuality && zonePass);
   entry.rejectReason = entry.physicsPass ? "PASS" : (quality < MinQuality ? "Quality_Too_Low" : (zone == ZONE_TRANSITION ? "TRANSITION_Zone" : "AVOID_Zone"));
   
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
   
   g_logger.LogTrade(log);
}

//+------------------------------------------------------------------+
