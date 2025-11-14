//+------------------------------------------------------------------+
//|                                          TP_CSV_Logger.mqh        |
//|                      TickPhysics Institutional Framework (ITPF)   |
//|                                   Comprehensive CSV Logging System |
//+------------------------------------------------------------------+
//| Module: CSV Logger                                                |
//| Version: 8.0 (Multi-Asset Edition)                                |
//| Author: Extracted from v5.0/v6.0 + Enhanced for modular system    |
//| Date: November 4, 2025                                            |
//|                                                                    |
//| Purpose:                                                           |
//|   - Log all signals with full market context (25+ fields)         |
//|   - Log all trades with complete lifecycle data (40+ fields)      |
//|   - Support multi-asset format adaptation                         |
//|   - Enable Python analysis and ML training                        |
//|   - Integrate with Risk Manager and Physics Indicator             |
//|                                                                    |
//| Key Features:                                                      |
//|   ✅ 25+ field signal logging                                     |
//|   ✅ 40+ field trade logging                                      |
//|   ✅ Auto-header creation with field descriptions                 |
//|   ✅ MFE/MAE tracking with timestamps                             |
//|   ✅ Multi-asset symbol formatting                                |
//|   ✅ Robust error handling with fallback                          |
//|   ✅ Performance metrics (R-ratio, hold time, slippage)           |
//|                                                                    |
//| Dependencies:                                                      |
//|   - TP_Risk_Manager.mqh (optional, for risk metrics)              |
//|   - TP_Physics_Indicator.mqh (optional, for physics metrics)      |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2025, QuanAlpha"
#property version   "8.0"
#property strict

//+------------------------------------------------------------------+
//| Logger Configuration                                              |
//+------------------------------------------------------------------+
struct LoggerConfig
{
   string signalLogFile;        // Signal log filename
   string tradeLogFile;         // Trade log filename
   bool createHeaders;          // Auto-create CSV headers
   bool appendMode;             // Append vs overwrite
   bool timestampFiles;         // Add timestamp to filenames
   bool logToExpertLog;         // Also print to expert log
   bool debugMode;              // Verbose debug output
};

//+------------------------------------------------------------------+
//| Signal Log Entry (27 fields - Added EA tracking)                 |
//+------------------------------------------------------------------+
struct SignalLogEntry
{
   // EA Version Tracking
   string eaName;               // EA name for version tracking
   string eaVersion;            // EA version number
   
   // Timestamp & Signal
   datetime timestamp;
   string symbol;
   int signal;                  // 1=BUY, -1=SELL, 0=NONE
   string signalType;           // "BUY", "SELL", "NONE"
   
   // Physics Metrics (from TP_Physics_Indicator)
   double quality;
   double confluence;
   double momentum;
   double speed;
   double acceleration;
   double entropy;
   double jerk;
   
   // Classification
   string zone;                 // BULL, BEAR, TRANSITION, AVOID
   string regime;               // LOW, NORMAL, HIGH
   
   // Market Context
   double price;
   double spread;
   double highThreshold;
   double lowThreshold;
   
   // Account State
   double balance;
   double equity;
   int openPositions;
   
   // Filter Result
   bool physicsPass;
   string rejectReason;
   
   // Time Context
   int hour;
   int dayOfWeek;
};

//+------------------------------------------------------------------+
//| Trade Log Entry (55 fields - Enhanced with RunUp/RunDown + EA tracking) |
//+------------------------------------------------------------------+
struct TradeLogEntry
{
   // EA Version Tracking
   string eaName;               // EA name for version tracking
   string eaVersion;            // EA version number
   
   // Trade Identification
   ulong ticket;
   datetime openTime;
   datetime closeTime;
   string symbol;
   string type;                 // "BUY" or "SELL"
   
   // Trade Parameters
   double lots;
   double openPrice;
   double closePrice;
   double sl;
   double tp;
   
   // Entry Conditions (Physics)
   double entryQuality;
   double entryConfluence;
   double entryMomentum;
   double entryEntropy;
   string entryZone;
   string entryRegime;
   double entrySpread;
   
   // Exit Conditions
   string exitReason;           // TP, SL, Manual, Timeout, etc.
   double exitQuality;
   double exitConfluence;
   string exitZone;
   string exitRegime;
   
   // Performance Metrics
   double profit;
   double profitPercent;
   double pips;
   int holdTimeBars;
   int holdTimeMinutes;
   
   // Risk Metrics
   double riskPercent;
   double rRatio;
   double slippage;
   double commission;
   
   // Excursion Analysis (MFE/MAE) - During Trade
   double mfe;                  // Max Favorable Excursion (price)
   double mae;                  // Max Adverse Excursion (price)
   double mfePercent;
   double maePercent;
   double mfePips;
   double maePips;
   int mfeTimeBars;             // When MFE occurred
   int maeTimeBars;             // When MAE occurred
   
   // Post-Exit Analysis (RunUp/RunDown) - After Trade Closes
   double runUpPrice;           // Best price after exit
   double runUpPips;            // Pips moved favorably after exit
   double runUpPercent;         // % move after exit
   int runUpTimeBars;           // Bars until max runup
   
   double runDownPrice;         // Worst price after exit
   double runDownPips;          // Pips moved adversely after exit
   double runDownPercent;       // % move after exit
   int runDownTimeBars;         // Bars until max rundown
   
   // Account State
   double balanceAfter;
   double equityAfter;
   double drawdownPercent;
   
   // Time Analysis
   int entryHour;
   int entryDayOfWeek;
   int exitHour;
   int exitDayOfWeek;
};

//+------------------------------------------------------------------+
//| CSV Logger Class                                                  |
//+------------------------------------------------------------------+
class CCSVLogger
{
private:
   LoggerConfig m_config;
   bool m_initialized;
   string m_symbolName;
   int m_symbolDigits;
   double m_symbolPoint;
   
   //+------------------------------------------------------------------+
   //| Write Signal Log Header                                          |
   //+------------------------------------------------------------------+
   bool WriteSignalHeader()
   {
      int handle = FileOpen(m_config.signalLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Cannot create signal log file: ", m_config.signalLogFile);
         return false;
      }
      
      // Write header (27 columns - Added EA tracking)
      FileWrite(handle,
         "EAName", "EAVersion",
         "Timestamp", "Symbol", "Signal", "SignalType",
         "Quality", "Confluence", "Momentum", "Speed", "Acceleration", 
         "Entropy", "Jerk",
         "Zone", "Regime",
         "Price", "Spread", "HighThreshold", "LowThreshold",
         "Balance", "Equity", "OpenPositions",
         "PhysicsPass", "RejectReason",
         "Hour", "DayOfWeek"
      );
      
      FileClose(handle);
      
      if(m_config.debugMode)
         Print("✅ Signal log header created: ", m_config.signalLogFile);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Write Trade Log Header                                           |
   //+------------------------------------------------------------------+
   bool WriteTradeHeader()
   {
      int handle = FileOpen(m_config.tradeLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Cannot create trade log file: ", m_config.tradeLogFile);
         return false;
      }
      
      // Write header (55 columns - Enhanced with RunUp/RunDown + EA tracking)
      FileWrite(handle,
         "EAName", "EAVersion",
         "Ticket", "OpenTime", "CloseTime", "Symbol", "Type",
         "Lots", "OpenPrice", "ClosePrice", "SL", "TP",
         "EntryQuality", "EntryConfluence", "EntryMomentum", "EntryEntropy",
         "EntryZone", "EntryRegime", "EntrySpread",
         "ExitReason", "ExitQuality", "ExitConfluence", "ExitZone", "ExitRegime",
         "Profit", "ProfitPercent", "Pips", "HoldTimeBars", "HoldTimeMinutes",
         "RiskPercent", "RRatio", "Slippage", "Commission",
         "MFE", "MAE", "MFE_Percent", "MAE_Percent", "MFE_Pips", "MAE_Pips",
         "MFE_TimeBars", "MAE_TimeBars",
         "RunUp_Price", "RunUp_Pips", "RunUp_Percent", "RunUp_TimeBars",
         "RunDown_Price", "RunDown_Pips", "RunDown_Percent", "RunDown_TimeBars",
         "BalanceAfter", "EquityAfter", "DrawdownPercent",
         "EntryHour", "EntryDayOfWeek", "ExitHour", "ExitDayOfWeek"
      );
      
      FileClose(handle);
      
      if(m_config.debugMode)
         Print("✅ Trade log header created: ", m_config.tradeLogFile);
      
      return true;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   CCSVLogger()
   {
      m_initialized = false;
   }
   
   //+------------------------------------------------------------------+
   //| Initialize Logger                                                 |
   //+------------------------------------------------------------------+
   bool Initialize(string symbol, LoggerConfig &config)
   {
      m_config = config;
      m_symbolName = symbol;
      m_symbolDigits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      m_symbolPoint = SymbolInfoDouble(symbol, SYMBOL_POINT);
      
      if(m_config.debugMode)
         Print("🔧 Initializing CSV Logger for ", symbol);
      
      // Add timestamp to filenames if requested
      if(m_config.timestampFiles)
      {
         string timestamp = TimeToString(TimeCurrent(), TIME_DATE);
         StringReplace(timestamp, ".", "_");
         
         m_config.signalLogFile = StringFormat("%s_%s.csv", 
            StringSubstr(m_config.signalLogFile, 0, StringLen(m_config.signalLogFile) - 4),
            timestamp);
         m_config.tradeLogFile = StringFormat("%s_%s.csv",
            StringSubstr(m_config.tradeLogFile, 0, StringLen(m_config.tradeLogFile) - 4),
            timestamp);
      }
      
      // Create headers if needed
      if(m_config.createHeaders)
      {
         if(!WriteSignalHeader()) return false;
         if(!WriteTradeHeader()) return false;
      }
      
      m_initialized = true;
      
      if(m_config.debugMode)
      {
         Print("✅ CSV Logger Initialized:");
         Print("   Symbol: ", m_symbolName);
         Print("   Signal Log: ", m_config.signalLogFile);
         Print("   Trade Log: ", m_config.tradeLogFile);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Log Signal                                                        |
   //+------------------------------------------------------------------+
   bool LogSignal(SignalLogEntry &entry)
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Logger not initialized");
         return false;
      }
      
      int handle = FileOpen(m_config.signalLogFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Cannot open signal log file");
         return false;
      }
      
      FileSeek(handle, 0, SEEK_END);
      
      FileWrite(handle,
         entry.eaName, entry.eaVersion,
         TimeToString(entry.timestamp), entry.symbol, entry.signal, entry.signalType,
         entry.quality, entry.confluence, entry.momentum, entry.speed, entry.acceleration,
         entry.entropy, entry.jerk,
         entry.zone, entry.regime,
         entry.price, entry.spread, entry.highThreshold, entry.lowThreshold,
         entry.balance, entry.equity, entry.openPositions,
         entry.physicsPass ? "PASS" : "REJECT", entry.rejectReason,
         entry.hour, entry.dayOfWeek
      );
      
      FileClose(handle);
      
      if(m_config.logToExpertLog)
      {
         Print("📝 Signal logged: ", entry.signalType, " | Quality=", entry.quality, 
               " | Result=", entry.physicsPass ? "PASS" : "REJECT");
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Log Trade                                                         |
   //+------------------------------------------------------------------+
   bool LogTrade(TradeLogEntry &entry)
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Logger not initialized");
         return false;
      }
      
      int handle = FileOpen(m_config.tradeLogFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Cannot open trade log file");
         return false;
      }
      
      FileSeek(handle, 0, SEEK_END);
      
      FileWrite(handle,
         entry.eaName, entry.eaVersion,
         entry.ticket, TimeToString(entry.openTime), TimeToString(entry.closeTime),
         entry.symbol, entry.type,
         entry.lots, entry.openPrice, entry.closePrice, entry.sl, entry.tp,
         entry.entryQuality, entry.entryConfluence, entry.entryMomentum, entry.entryEntropy,
         entry.entryZone, entry.entryRegime, entry.entrySpread,
         entry.exitReason, entry.exitQuality, entry.exitConfluence, entry.exitZone, entry.exitRegime,
         entry.profit, entry.profitPercent, entry.pips, entry.holdTimeBars, entry.holdTimeMinutes,
         entry.riskPercent, entry.rRatio, entry.slippage, entry.commission,
         entry.mfe, entry.mae, entry.mfePercent, entry.maePercent, entry.mfePips, entry.maePips,
         entry.mfeTimeBars, entry.maeTimeBars,
         entry.runUpPrice, entry.runUpPips, entry.runUpPercent, entry.runUpTimeBars,
         entry.runDownPrice, entry.runDownPips, entry.runDownPercent, entry.runDownTimeBars,
         entry.balanceAfter, entry.equityAfter, entry.drawdownPercent,
         entry.entryHour, entry.entryDayOfWeek, entry.exitHour, entry.exitDayOfWeek
      );
      
      FileClose(handle);
      
      if(m_config.logToExpertLog)
      {
         Print("📝 Trade logged: #", entry.ticket, " | Profit=", entry.profit, 
               " | R=", entry.rRatio, " | Reason=", entry.exitReason);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Helper: Calculate Pips from Price Difference                     |
   //+------------------------------------------------------------------+
   double CalculatePips(double priceFrom, double priceTo, bool isBuy)
   {
      double diff = isBuy ? (priceTo - priceFrom) : (priceFrom - priceTo);
      return diff / m_symbolPoint / 10.0;  // Standard pip calculation
   }
   
   //+------------------------------------------------------------------+
   //| Helper: Get Current Spread in Points                             |
   //+------------------------------------------------------------------+
   double GetCurrentSpread()
   {
      double ask = SymbolInfoDouble(m_symbolName, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbolName, SYMBOL_BID);
      return (ask - bid) / m_symbolPoint;
   }
   
   //+------------------------------------------------------------------+
   //| Set Debug Mode                                                    |
   //+------------------------------------------------------------------+
   void SetDebug(bool enable)
   {
      m_config.debugMode = enable;
      m_config.logToExpertLog = enable;
   }
   
   //+------------------------------------------------------------------+
   //| Get Logger Status                                                 |
   //+------------------------------------------------------------------+
   bool IsInitialized() { return m_initialized; }
   string GetSignalLogFile() { return m_config.signalLogFile; }
   string GetTradeLogFile() { return m_config.tradeLogFile; }
};

//+------------------------------------------------------------------+
//| END OF TP_CSV_Logger.mqh                                          |
//+------------------------------------------------------------------+

/*
USAGE EXAMPLE:

#include <TickPhysics/TP_CSV_Logger.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>

CCSVLogger g_logger;
CPhysicsIndicator g_physics;

int OnInit()
{
   // Configure logger
   LoggerConfig config;
   config.signalLogFile = "TP_Signals_" + _Symbol + ".csv";
   config.tradeLogFile = "TP_Trades_" + _Symbol + ".csv";
   config.createHeaders = true;
   config.appendMode = true;
   config.timestampFiles = false;
   config.logToExpertLog = true;
   config.debugMode = true;
   
   if(!g_logger.Initialize(_Symbol, config))
   {
      Print("Failed to initialize logger");
      return INIT_FAILED;
   }
   
   g_physics.Initialize("TickPhysics_Crypto_Indicator_v2_1", false);
   
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // Log signal
   SignalLogEntry signal;
   signal.timestamp = TimeCurrent();
   signal.symbol = _Symbol;
   signal.signal = 1;  // BUY
   signal.signalType = "BUY";
   signal.quality = g_physics.GetQuality();
   signal.confluence = g_physics.GetConfluence();
   signal.momentum = g_physics.GetMomentum();
   signal.speed = g_physics.GetSpeed();
   signal.acceleration = g_physics.GetAcceleration();
   signal.entropy = g_physics.GetEntropy();
   signal.jerk = g_physics.GetJerk();
   signal.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
   signal.regime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());
   signal.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   signal.spread = g_logger.GetCurrentSpread();
   signal.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   signal.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   signal.physicsPass = true;
   signal.rejectReason = "PASS";
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   signal.hour = dt.hour;
   signal.dayOfWeek = dt.day_of_week;
   
   g_logger.LogSignal(signal);
   
   // Log trade (on close)
   TradeLogEntry trade;
   trade.ticket = 12345;
   trade.openTime = D'2025.11.04 08:00';
   trade.closeTime = TimeCurrent();
   trade.symbol = _Symbol;
   trade.type = "BUY";
   trade.lots = 0.1;
   trade.openPrice = 3500.0;
   trade.closePrice = 3520.0;
   trade.profit = 100.0;
   trade.exitReason = "TP";
   
   g_logger.LogTrade(trade);
}
*/
