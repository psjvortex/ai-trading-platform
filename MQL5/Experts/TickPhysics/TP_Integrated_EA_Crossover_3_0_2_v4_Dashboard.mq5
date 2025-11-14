//+------------------------------------------------------------------+
//|                       TP_Integrated_EA_Crossover_3_0_2.mq5       |
//|                      TickPhysics Institutional Framework (ITPF)  |
//|             v4.0 Dashboard - Complete Visual Trading Monitor     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "3.02"
#property description "v3.2 EA with v4.0 Dashboard - Real-time filter visualization"

// EA Version Info (for CSV tracking)
#define EA_NAME "TP_Integrated_EA"
#define EA_VERSION "3.02"

input int MagicNumber = 300302;                // EA magic number
input string TradeComment = "TP_Integrated 3_2";   // Trade comment

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
input double RiskPercentPerTrade = 10.0;        // Risk per trade (% of balance)
input double MaxDailyRisk = 10.0;              // Max daily risk (% of balance)
input int MaxConcurrentTrades = 1;             // Max concurrent positions
input double MinRRatio = 1.0;                  // Min reward:risk ratio

// === Trade Parameters ===
input group "📊 Trade Parameters"
input int StopLossPips = 683;                  // Stop loss (pips) - from correlation analysis
input int TakeProfitPips = 1161;               // Take profit (pips) - from correlation analysis
input bool UseTrailingStop = false;            // Enable trailing stop
input int TrailingStopPips = 30;               // Trailing stop (pips)

// === Entry System Selection ===
input group "📊 Entry Logic"
input bool UsePhysicsEntry = true;            // Use physics acceleration crossover
input bool UseMAEntry = false;                  // Use Moving Average crossover
input int MA_Fast = 10;                        // Fast MA period
input int MA_Slow = 50;                        // Slow MA period
input ENUM_MA_METHOD MA_Method = MODE_EMA;     // MA calculation method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // MA price type

// === Signal Filters (v4.0 OPTIMIZED) ===
input group "🎯 Physics Filters v4.0"
input bool UsePhysicsFilters = true;           // Enable physics filtering
input double MinQuality = 80.0;                // Min physics quality (v4.0 threshold)
input bool AvoidTransitionZone = true;         // Reject TRANSITION zone (14.1% WR)
input bool UseRegimeFilter = false;            // Filter by volatility regime (optional)

// === Monitoring ===
input group "📈 Post-Trade Monitoring"
input int PostExitMonitorBars = 50;            // RunUp/RunDown monitor bars
input bool EnableRealTimeLogging = true;       // Log signals in real-time

// === Advanced ===
input group "⚙️ Advanced Settings"
input bool EnableDebugMode = true;            // Verbose logging

// === v4.0 Dashboard Display ===
input group "📊 v4.0 Dashboard"
input bool ShowDashboard = true;               // Show on-chart dashboard
input int DashboardCorner = 0;                 // Corner: 0=UL, 1=UR, 2=LL, 3=LR
input int DashboardX = 10;                     // X offset (pixels)
input int DashboardY = 20;                     // Y offset (pixels)
input int DashboardFontSize = 9;               // Font size

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

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

// Dashboard management
datetime g_lastDashboardUpdate = 0;
int g_dashboardUpdateInterval = 1;  // Update every second

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
   int lineHeight = DashboardFontSize + 5;  // Increased spacing
   int row = 0;
   
   // Header
   CreateLabel("DASH_Header", x, y + (row++ * lineHeight), 
               "=== TickPhysics EA v3.0 ===", clrWhite, DashboardFontSize + 1);
   row += 1;  // Empty line after header               
   CreateLabel("DASH_Symbol", x, y + (row++ * lineHeight), 
               "Symbol: " + _Symbol, clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_EntryMode", x, y + (row++ * lineHeight), 
               "Entry: MA CROSSOVER", clrSilver, DashboardFontSize);
   row += 2;  // Empty lines after header
   
   // System Status
   CreateLabel("DASH_SystemHeader", x, y + (row++ * lineHeight), 
               "SYSTEM STATUS", clrWhite, DashboardFontSize);
   row += 1;  // Empty lines after header
   CreateLabel("DASH_Status", x, y + (row++ * lineHeight), 
               "Status: ACTIVE", clrLimeGreen, DashboardFontSize);
   row += 2;  // Empty lines after status
   
   // Physics Metrics Section
   CreateLabel("DASH_PhysicsHeader", x, y + (row++ * lineHeight), 
               "PHYSICS METRICS", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Quality", x, y + (row++ * lineHeight), 
               "Quality: 0.0 (>= 70)", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Conflu", x, y + (row++ * lineHeight), 
               "Conflu: 0.0 (not used)", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Momentum", x, y + (row++ * lineHeight), 
               "Momentum: 0.0", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Speed", x, y + (row++ * lineHeight), 
               "Speed: 0.0", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Accel", x, y + (row++ * lineHeight), 
               "Accel: 0.0", clrSilver, DashboardFontSize);
   row += 2;  // Empty lines after physics
   
   // Classification Section
   CreateLabel("DASH_ClassHeader", x, y + (row++ * lineHeight), 
               "CLASSIFICATION", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Zone", x, y + (row++ * lineHeight), 
               "Zone: UNKNOWN", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Regime", x, y + (row++ * lineHeight), 
               "Regime: UNKNOWN", clrSilver, DashboardFontSize);
   row += 2;  // Empty lines after classification
   
   // MA Crossover Section
   CreateLabel("DASH_MAHeader", x, y + (row++ * lineHeight), 
               "MA CROSSOVER", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_MASignal", x, y + (row++ * lineHeight), 
               "Signal: NONE", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_MAValues", x, y + (row++ * lineHeight), 
               "Values: 0.00 / 0.00", clrSilver, DashboardFontSize);
   row += 2;  // Empty lines after MA
   
   // Filter Status Section (KEY FEATURE!)
   CreateLabel("DASH_FilterHeader", x, y + (row++ * lineHeight), 
               "FILTER STATUS", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_FilterQuality", x, y + (row++ * lineHeight), 
               "Quality: WAIT", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_FilterZone", x, y + (row++ * lineHeight), 
               "Zone: WAIT", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_FilterOverall", x, y + (row++ * lineHeight), 
               "Overall: MONITORING", clrDodgerBlue, DashboardFontSize);
   row += 2;  // Empty lines after filters
   
   // Position Section
   CreateLabel("DASH_PosHeader", x, y + (row++ * lineHeight), 
               "POSITION", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_PosActive", x, y + (row++ * lineHeight), 
               "Active: None", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_PosPL", x, y + (row++ * lineHeight), 
               "P/L: $0.00", clrSilver, DashboardFontSize);
   row += 2;  // Empty lines after position
   
   // Account Section
   CreateLabel("DASH_AcctHeader", x, y + (row++ * lineHeight), 
               "ACCOUNT", clrWhite, DashboardFontSize);
   row += 1;  // Empty line after header
   CreateLabel("DASH_Balance", x, y + (row++ * lineHeight), 
               "Balance: $0.00", clrSilver, DashboardFontSize);
   row += 1;  // Empty line after header
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
   
   // Throttle updates to once per second
   datetime currentTime = TimeCurrent();
   if(currentTime == g_lastDashboardUpdate) return;
   g_lastDashboardUpdate = currentTime;
   
   // Get all physics metrics
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double momentum = g_physics.GetMomentum(0);
   double speed = g_physics.GetSpeed(0);
   double accel = g_physics.GetAcceleration(0);
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // ===PHYSICS METRICS SECTION ===
   
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
   
   bool filtersEnabled = UsePhysicsFilters;
   bool zonePass = (zone != ZONE_TRANSITION || !AvoidTransitionZone);
   bool allFiltersPass = (!filtersEnabled) || (qualityPass && zonePass);
   
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
   
   // Overall status
   string overallStatus;
   color overallColor;
   
   if(!filtersEnabled)
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
//| Helper: Create string of repeated character                      |
//+------------------------------------------------------------------+
string StringFill(int count, string chr)
{
   if(count <= 0) return "";
   string result = "";
   for(int i = 0; i < count; i++)
      result += chr;
   return result;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🚀 TickPhysics v4.0 Dashboard - Initializing");
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
   Print("✅ ALL SYSTEMS READY - v4.0 DASHBOARD ACTIVE!");
   Print("═══════════════════════════════════════════════════════");
   Print("📋 Configuration:");
   Print("   EA Version: v3.0 with v4.0 Dashboard");
   Print("   Entry System: ", UsePhysicsEntry ? "PHYSICS" : (UseMAEntry ? "MA CROSSOVER" : "NONE"));
   if(UseMAEntry)
      Print("   MA Periods: Fast=", MA_Fast, ", Slow=", MA_Slow);
   Print("   Physics Filters: ", UsePhysicsFilters ? "ENABLED ✅" : "DISABLED ⚠️");
   if(UsePhysicsFilters)
   {
      Print("   → Quality Filter: >= ", MinQuality, "%");
      Print("   → Transition Filter: ", AvoidTransitionZone ? "ENABLED (reject 14.1% WR)" : "DISABLED");
   }
   Print("   Risk/Trade: ", RiskPercentPerTrade, "%");
   Print("   SL/TP: ", StopLossPips, "/", TakeProfitPips, " pips");
   Print("   Dashboard: Corner ", DashboardCorner, " @ (", DashboardX, ",", DashboardY, ")");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 TickPhysics v4.0 Dashboard - Shutting Down");
   Print("   Reason: ", reason);
   Print("═══════════════════════════════════════════════════════");
   
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
   
   // Update v4.0 Dashboard
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
   else
      return 0;
}

//+------------------------------------------------------------------+
//| Physics-based signal                                              |
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
   // 1. Generate signal
   int signal = GenerateSignal();
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // 2. Log signal
   if(EnableRealTimeLogging)
      LogSignal(signal, quality, confluence, zone, regime);
   
   // 3. Check if we should trade
   if(signal == 0) return;
   
   // 4. Apply v4.0 filters
   string rejectReason = "";
   bool passFilters = true;
   
   if(UsePhysicsFilters)
   {
      // Quality filter (PRIMARY)
      if(quality < MinQuality)
      {
         passFilters = false;
         rejectReason = "Quality_Too_Low";
         if(EnableDebugMode)
            Print("❌ Filter FAIL: Quality ", quality, " < ", MinQuality);
      }
      
      // Zone filter (reject TRANSITION)
      if(AvoidTransitionZone && zone == ZONE_TRANSITION)
      {
         passFilters = false;
         rejectReason = "TRANSITION_Zone";
         if(EnableDebugMode)
            Print("❌ Filter FAIL: TRANSITION zone (14.1% WR)");
      }
      
      if(passFilters && EnableDebugMode)
         Print("✅ Filters PASS: Quality=", quality, ", Zone=", g_physics.GetZoneName(zone));
   }
   
   if(!passFilters)
   {
      if(EnableDebugMode)
         Print("🚫 Trade blocked by filters: ", rejectReason);
      return;
   }
   
   // 5. Close opposite positions
   int closedCount = CloseOppositePositions(signal);
   if(closedCount > 0)
      Sleep(500);  // Give MT5 time to process
   
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
   double lots = g_riskManager.CalculateLotSize(RiskPercentPerTrade, StopLossPips);
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size calculated");
      return;
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
   
   entry.physicsPass = (quality >= MinQuality && (zone != ZONE_TRANSITION || !AvoidTransitionZone));
   entry.rejectReason = entry.physicsPass ? "PASS" : (quality < MinQuality ? "Quality_Too_Low" : "TRANSITION_Zone");
   
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
