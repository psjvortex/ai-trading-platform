//+------------------------------------------------------------------+
//|                                          TP_CSV_Logger.mqh        |
//|                      TickPhysics Institutional Framework (ITPF)   |
//|                                   Comprehensive CSV Logging System |
//+------------------------------------------------------------------+
//| Module: CSV Logger                                                |
//| Version: 9.0 (Entry_*/Exit_* Explicit Naming Edition)            |
//| Author: Extracted from v5.0/v6.0 + Enhanced for modular system    |
//| Date: November 17, 2025                                           |
//|                                                                    |
//| Purpose:                                                           |
//|   - Log all signals with full market context (33 fields)          |
//|   - Log all trades with dual-row model (110 fields)               |
//|   - Entry_* and Exit_* explicit naming for ML clarity             |
//|   - Support multi-asset format adaptation                         |
//|   - Enable Python analysis and ML training                        |
//|   - Integrate with Risk Manager and Physics Indicator             |
//|                                                                    |
//| Key Features:                                                      |
//|   ✅ 33-field signal logging                                      |
//|   ✅ 110-field dual-row trade logging                             |
//|   ✅ Entry_* prefix for all entry physics metrics                 |
//|   ✅ Exit_* prefix for all exit physics metrics                   |
//|   ✅ Auto-header creation with field descriptions                 |
//|   ✅ MFE/MAE tracking with timestamps                             |
//|   ✅ Physics decay analysis (SpeedSlopeDecay, etc.)               |
//|   ✅ Multi-asset symbol formatting                                |
//|   ✅ Robust error handling with fallback                          |
//|                                                                    |
//| Dependencies:                                                      |
//|   - TP_Risk_Manager.mqh (optional, for risk metrics)              |
//|   - TP_Physics_Indicator.mqh (optional, for physics metrics)      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "9.0"
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
   bool dedupeEnabled;         // Skip duplicate writes (ticket,rowType fingerprint)
   int dedupeWindowSeconds;    // Time window for considering duplicated logs (seconds)
   int dedupeCacheSize;        // Number of entries in the dedupe LRU cache
};

//+------------------------------------------------------------------+
//| Signal Log Entry (33 fields - Added Slopes v4.5)                 |
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
   double physicsScore;         // Evidence-based weighted physics score (0-100)
   
   // v4.5: Slope Analysis (Directional Momentum)
   double speedSlope;           // Speed trend direction (units/bar)
   double accelerationSlope;    // Acceleration trend direction (units/bar)
   double momentumSlope;        // Momentum trend direction (units/bar)
   double confluenceSlope;      // Confluence trend direction (%/bar)
   double jerkSlope;            // Jerk trend direction (units/bar)
   
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
   
   // ═══════════════════════════════════════════════════════════
   // ROW TYPE IDENTIFIER (NEW!)
   // ═══════════════════════════════════════════════════════════
   string rowType;              // "ENTRY" or "EXIT" - enables dual-row model
   datetime timestamp;          // Current row timestamp (entry time or exit time)
   
   // Trade Identification
   ulong ticket;
   datetime openTime;           // Trade open time (same on both rows)
   datetime closeTime;          // Trade close time (only on EXIT row)
   string symbol;
   string type;                 // "BUY" or "SELL"
   
   // Trade Parameters
   double lots;
   double price;                // Current price (entry price on ENTRY row, exit price on EXIT row)
   double openPrice;            // Entry price (same on both rows)
   double closePrice;           // Exit price (only on EXIT row)
   double sl;
   double tp;
   
   // ═══════════════════════════════════════════════════════════
   // ENTRY PHYSICS METRICS (Captured at trade entry on ENTRY row)
   // ═══════════════════════════════════════════════════════════
   double entryQuality;
   double entryConfluence;
   double entryMomentum;
   double entrySpeed;
   double entryAcceleration;
   double entryEntropy;
   double entryJerk;
   double entryPhysicsScore;
   
   // Entry Slopes
   double entrySpeedSlope;
   double entryAccelerationSlope;
   double entryMomentumSlope;
   double entryConfluenceSlope;
   double entryJerkSlope;
   
   // Entry Market Context
   string entryZone;            // BULL/BEAR/TRANSITION/AVOID
   string entryRegime;          // TRENDING/NORMAL/HIGH/LOW
   double entrySpread;
   
   // ═══════════════════════════════════════════════════════════
   // EXIT PHYSICS METRICS (Captured at trade exit on EXIT row)
   // ═══════════════════════════════════════════════════════════
   double exitQuality;
   double exitConfluence;
   double exitMomentum;
   double exitSpeed;
   double exitAcceleration;
   double exitEntropy;
   double exitJerk;
   double exitPhysicsScore;
   
   // Exit Slopes
   double exitSpeedSlope;
   double exitAccelerationSlope;
   double exitMomentumSlope;
   double exitConfluenceSlope;
   double exitJerkSlope;
   
   // Exit Market Context
   string exitZone;             // BULL/BEAR/TRANSITION/AVOID
   string exitRegime;           // TRENDING/NORMAL/HIGH/LOW
   double exitSpread;
   
   // ═══════════════════════════════════════════════════════════
   // EXIT CONDITIONS (EXIT row only)
   // ═══════════════════════════════════════════════════════════
   string exitReason;           // TP, SL, Manual, Timeout, etc.
   
   // ═══════════════════════════════════════════════════════════
   // PERFORMANCE METRICS (EXIT row only)
   // ═══════════════════════════════════════════════════════════
   double profit;
   double profitPercent;
   double pips;
   int holdTimeBars;
   int holdTimeMinutes;         // Duration in minutes
   
   // Risk Metrics
   double riskPercent;
   double rRatio;
   double slippage;
   double commission;
   
   // ═══════════════════════════════════════════════════════════
   // EXCURSION ANALYSIS (EXIT row only)
   // ═══════════════════════════════════════════════════════════
   double mfe;                  // Max Favorable Excursion (price)
   double mae;                  // Max Adverse Excursion (price)
   double mfePercent;
   double maePercent;
   double mfePips;              // MFE in pips
   double maePips;              // MAE in pips
   int mfeTimeBars;             // When MFE occurred
   int maeTimeBars;             // When MAE occurred
   double mfeUtilization;       // (profit / mfe) * 100 - how much of potential captured?
   double maeImpact;            // (mae / profit) * 100 - drawdown impact
   double excursionEfficiency;  // mfe / (mfe + mae) - trade quality metric
   
   // ═══════════════════════════════════════════════════════════
   // POST-EXIT ANALYSIS (EXIT row only)
   // ═══════════════════════════════════════════════════════════
   double runUpPrice;           // Best price after exit
   double runUpPips;            // Pips moved favorably after exit
   double runUpPercent;         // % move after exit
   int runUpTimeBars;           // Bars until max runup
   
   double runDownPrice;         // Worst price after exit
   double runDownPips;          // Pips moved adversely after exit
   double runDownPercent;       // % move after exit
   int runDownTimeBars;         // Bars until max rundown
   
   string exitQualityClass;     // "Early" | "Optimal" | "Late" | "Good"
   double earlyExitOpportunityCost; // Pips lost if exited too early
   
   // ═══════════════════════════════════════════════════════════
   // TEMPORAL INTELLIGENCE (Both rows)
   // ═══════════════════════════════════════════════════════════
   int hour;                    // Current hour (0-23)
   int dayOfWeek;               // Current day (0=Sunday, 6=Saturday)
   string timeSegment15M;       // "09:15-09:30"
   string timeSegment30M;       // "09:00-09:30"
   string timeSegment1H;        // "09:00-10:00"
   string timeSegment2H;        // "08:00-10:00"
   string timeSegment3H;        // "09:00-12:00"
   string timeSegment4H;        // "08:00-12:00"
   string tradingSession;       // "Asian" | "London" | "NewYork" | "Overlap" | "OffHours"
   bool isWeekend;              // Is weekend?
   bool isPreMarket;            // Is pre-market hour?
   
   // Legacy time fields
   int entryHour;
   int entryDayOfWeek;
   int exitHour;
   int exitDayOfWeek;
   
   // ═══════════════════════════════════════════════════════════
   // ACCOUNT STATE (Both rows)
   // ═══════════════════════════════════════════════════════════
   double balance;              // Current balance
   double equity;               // Current equity
   double balanceAfter;         // Balance after trade (legacy)
   double equityAfter;          // Equity after trade (legacy)
   double drawdownPercent;
   int openPositions;           // Number of open positions
   
   // ═══════════════════════════════════════════════════════════
   // PHYSICS DECAY ANALYSIS (EXIT row only - CRITICAL!)
   // ═══════════════════════════════════════════════════════════
   double physicsScoreDecay;    // Entry physics - Exit physics (positive = deterioration)
   double speedDecay;           // Entry speed - Exit speed
   double speedSlopeDecay;      // Entry slope - Exit slope (YOUR KEY FINDING!)
   double confluenceDecay;      // Entry confluence - Exit confluence
   bool zoneTransitioned;       // Did zone change from entry to exit? (37% edge!)
   
   // ═══════════════════════════════════════════════════════════
   // SIGNAL CORRELATION (ENTRY row only)
   // ═══════════════════════════════════════════════════════════
   datetime signalTimestamp;    // When signal was generated
   double signalTimeDelta;      // Minutes between signal and trade open
   bool signalPhysicsPass;      // Did signal pass physics filters?
   string signalRejectReason;   // Why signal was rejected (if applicable)
   
   // ═══════════════════════════════════════════════════════════
   // DATA QUALITY & ML READINESS
   // ═══════════════════════════════════════════════════════════
   double dataQualityScore;     // 0-100 quality score
   string validationFlags;      // Comma-separated validation issues
   double aiEntryConfidence;    // Future: ML model confidence score
   double aiExitPrediction;     // Future: ML predicted outcome
   
   // ═══════════════════════════════════════════════════════════
   // CONSTRUCTOR - Initialize all numeric fields to prevent garbage values
   // ═══════════════════════════════════════════════════════════
   TradeLogEntry()
   {
      // Trade identification
      ticket = 0;
      openTime = 0;
      closeTime = 0;
      timestamp = 0;
      
      // Trade parameters
      lots = 0.0;
      price = 0.0;
      openPrice = 0.0;
      closePrice = 0.0;
      sl = 0.0;
      tp = 0.0;
      
      // Entry physics metrics
      entryQuality = 0.0;
      entryConfluence = 0.0;
      entryMomentum = 0.0;
      entrySpeed = 0.0;
      entryAcceleration = 0.0;
      entryEntropy = 0.0;
      entryJerk = 0.0;
      entryPhysicsScore = 0.0;
      entrySpeedSlope = 0.0;
      entryAccelerationSlope = 0.0;
      entryMomentumSlope = 0.0;
      entryConfluenceSlope = 0.0;
      entryJerkSlope = 0.0;
      entrySpread = 0.0;
      
      // Exit physics metrics
      exitQuality = 0.0;
      exitConfluence = 0.0;
      exitMomentum = 0.0;
      exitSpeed = 0.0;
      exitAcceleration = 0.0;
      exitEntropy = 0.0;
      exitJerk = 0.0;
      exitPhysicsScore = 0.0;
      exitSpeedSlope = 0.0;
      exitAccelerationSlope = 0.0;
      exitMomentumSlope = 0.0;
      exitConfluenceSlope = 0.0;
      exitJerkSlope = 0.0;
      exitSpread = 0.0;
      
      // Performance metrics
      profit = 0.0;
      profitPercent = 0.0;
      pips = 0.0;
      holdTimeBars = 0;
      holdTimeMinutes = 0;
      
      // Risk metrics
      riskPercent = 0.0;
      rRatio = 0.0;
      slippage = 0.0;
      commission = 0.0;
      
      // Excursion analysis
      mfe = 0.0;
      mae = 0.0;
      mfePercent = 0.0;
      maePercent = 0.0;
      mfePips = 0.0;
      maePips = 0.0;
      mfeTimeBars = 0;
      maeTimeBars = 0;
      mfeUtilization = 0.0;
      maeImpact = 0.0;
      excursionEfficiency = 0.0;
      
      // Post-exit analysis (CRITICAL - prevents overflow in ENTRY rows!)
      runUpPrice = 0.0;
      runUpPips = 0.0;
      runUpPercent = 0.0;
      runUpTimeBars = 0;
      runDownPrice = 0.0;
      runDownPips = 0.0;
      runDownPercent = 0.0;
      runDownTimeBars = 0;
      earlyExitOpportunityCost = 0.0;
      
      // Temporal intelligence
      hour = 0;
      dayOfWeek = 0;
      isWeekend = false;
      isPreMarket = false;
      entryHour = 0;
      entryDayOfWeek = 0;
      exitHour = 0;
      exitDayOfWeek = 0;
      
      // Account state
      balance = 0.0;
      equity = 0.0;
      balanceAfter = 0.0;
      equityAfter = 0.0;
      drawdownPercent = 0.0;
      openPositions = 0;
      
      // Physics decay analysis
      physicsScoreDecay = 0.0;
      speedDecay = 0.0;
      speedSlopeDecay = 0.0;
      confluenceDecay = 0.0;
      zoneTransitioned = false;
      
      // Signal correlation
      signalTimestamp = 0;
      signalTimeDelta = 0.0;
      signalPhysicsPass = false;
      
      // Data quality
      dataQualityScore = 0.0;
      aiEntryConfidence = 0.0;
      aiExitPrediction = 0.0;
   }
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
   // Dedupe cache storage
   ulong m_dedupeTickets[];
   string m_dedupeRowTypes[];
   string m_dedupeFingerprint[];
   datetime m_dedupeTimestamp[];
   int m_dedupeIndex;
   int m_dedupeSize;
   
   //+------------------------------------------------------------------+
   //| Write Signal Log Header                                          |
   //+------------------------------------------------------------------+
   bool WriteSignalHeader()
   {
      int handle = FileOpen(m_config.signalLogFile, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print(StringFormat("❌ ERROR: Cannot create signal log file: %s", m_config.signalLogFile));
         return false;
      }
      
      // Write header (33 columns - Added Slopes v4.5)
      FileWrite(handle,
         "EAName", "EAVersion",
         "Timestamp", "Symbol", "Signal", "SignalType",
         "Quality", "Confluence", "Momentum", "Speed", "Acceleration", 
         "Entropy", "Jerk", "PhysicsScore",
         "SpeedSlope", "AccelerationSlope", "MomentumSlope", "ConfluenceSlope", "JerkSlope",
         "Zone", "Regime",
         "Price", "Spread", "HighThreshold", "LowThreshold",
         "Balance", "Equity", "OpenPositions",
         "PhysicsPass", "RejectReason",
         "Hour", "DayOfWeek"
      );
      
      FileClose(handle);
      
      if(m_config.debugMode)
         Print(StringFormat("✅ Signal log header created: %s", m_config.signalLogFile));
      
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
         Print(StringFormat("❌ ERROR: Cannot create trade log file: %s", m_config.tradeLogFile));
         return false;
      }
      
      // NEW: Comprehensive header with 110 columns - Entry_* and Exit_* physics explicit
      // Chunk 1: Core ID fields (15 fields)
      FileWriteString(handle, "EAName,EAVersion,RowType,Ticket,Timestamp,OpenTime,CloseTime,Symbol,Type,Lots,Price,OpenPrice,ClosePrice,SL,TP,");
      
      // Chunk 2: Entry Physics (19 fields)
      FileWriteString(handle, "Entry_Quality,Entry_Confluence,Entry_Momentum,Entry_Speed,Entry_Acceleration,Entry_Entropy,Entry_Jerk,Entry_PhysicsScore,");
      FileWriteString(handle, "Entry_SpeedSlope,Entry_AccelerationSlope,Entry_MomentumSlope,Entry_ConfluenceSlope,Entry_JerkSlope,Entry_Zone,Entry_Regime,Entry_Spread,");
      
      // Chunk 3: Exit Physics (20 fields)
      FileWriteString(handle, "ExitReason,Exit_Quality,Exit_Confluence,Exit_Momentum,Exit_Speed,Exit_Acceleration,Exit_Entropy,Exit_Jerk,Exit_PhysicsScore,");
      FileWriteString(handle, "Exit_SpeedSlope,Exit_AccelerationSlope,Exit_MomentumSlope,Exit_ConfluenceSlope,Exit_JerkSlope,Exit_Zone,Exit_Regime,Exit_Spread,");
      
      // Chunk 4: Performance + Excursion (20 fields)
      FileWriteString(handle, "Profit,ProfitPercent,Pips,HoldTimeBars,HoldTimeMinutes,RiskPercent,RRatio,Slippage,Commission,");
      FileWriteString(handle, "MFE,MAE,MFE_Percent,MAE_Percent,MFE_Pips,MAE_Pips,MFE_TimeBars,MAE_TimeBars,MFEUtilization,MAEImpact,ExcursionEfficiency,");
      
      // Chunk 5: Post-Exit + Temporal (25 fields)
      FileWriteString(handle, "RunUp_Price,RunUp_Pips,RunUp_Percent,RunUp_TimeBars,RunDown_Price,RunDown_Pips,RunDown_Percent,RunDown_TimeBars,ExitQualityClass,EarlyExitOpportunityCost,");
      FileWriteString(handle, "Hour,DayOfWeek,TimeSegment15M,TimeSegment30M,TimeSegment1H,TimeSegment2H,TimeSegment3H,TimeSegment4H,TradingSession,IsWeekend,IsPreMarket,");
      FileWriteString(handle, "EntryHour,EntryDayOfWeek,ExitHour,ExitDayOfWeek,");
      
      // Chunk 6: Account + Decay + Signal + Quality (17 fields - no trailing comma on last)
      FileWriteString(handle, "Balance,Equity,BalanceAfter,EquityAfter,DrawdownPercent,OpenPositions,");
      FileWriteString(handle, "PhysicsScoreDecay,SpeedDecay,SpeedSlopeDecay,ConfluenceDecay,ZoneTransitioned,");
      FileWriteString(handle, "SignalTimestamp,SignalTimeDelta,SignalPhysicsPass,SignalRejectReason,");
      FileWriteString(handle, "DataQualityScore,ValidationFlags,AIEntryConfidence,AIExitPrediction\n");
      
      FileClose(handle);
      
      if(m_config.debugMode)
         Print(StringFormat("✅ Trade log header created: %s", m_config.tradeLogFile));
      
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
   //| Calculate Time Segments (PUBLIC for EA access)                   |
   //+------------------------------------------------------------------+
   void CalculateTimeSegments(datetime dt, TradeLogEntry &entry)
   {
      MqlDateTime mdt;
      TimeToStruct(dt, mdt);
      
      entry.hour = mdt.hour;
      entry.dayOfWeek = mdt.day_of_week;
      entry.isWeekend = (mdt.day_of_week == 0 || mdt.day_of_week == 6);
      
      // 15-minute segments
      int min15 = (mdt.min / 15) * 15;
      int nextMin15 = (min15 + 15) % 60;
      int nextHour15 = (nextMin15 == 0) ? (mdt.hour + 1) % 24 : mdt.hour;
      entry.timeSegment15M = StringFormat("%02d:%02d-%02d:%02d", 
         mdt.hour, min15, nextHour15, nextMin15);
      
      // 30-minute segments
      int min30 = (mdt.min / 30) * 30;
      int nextMin30 = (min30 + 30) % 60;
      int nextHour30 = (nextMin30 == 0) ? (mdt.hour + 1) % 24 : mdt.hour;
      entry.timeSegment30M = StringFormat("%02d:%02d-%02d:%02d", 
         mdt.hour, min30, nextHour30, nextMin30);
      
      // 1-hour segments
      entry.timeSegment1H = StringFormat("%02d:00-%02d:00", 
         mdt.hour, (mdt.hour + 1) % 24);
      
      // 2-hour segments
      int hour2 = (mdt.hour / 2) * 2;
      entry.timeSegment2H = StringFormat("%02d:00-%02d:00", 
         hour2, (hour2 + 2) % 24);
      
      // 3-hour segments
      int hour3 = (mdt.hour / 3) * 3;
      entry.timeSegment3H = StringFormat("%02d:00-%02d:00", 
         hour3, (hour3 + 3) % 24);
      
      // 4-hour segments
      int hour4 = (mdt.hour / 4) * 4;
      entry.timeSegment4H = StringFormat("%02d:00-%02d:00", 
         hour4, (hour4 + 4) % 24);
      
      // Trading session (Broker time - adjust if needed)
      // Asian: 18:00-03:00, London: 02:00-11:00, NewYork: 08:00-17:00
      if(mdt.hour >= 18 || mdt.hour < 3)
         entry.tradingSession = "Asian";
      else if(mdt.hour >= 2 && mdt.hour < 8)
         entry.tradingSession = "London";
      else if(mdt.hour >= 8 && mdt.hour < 11)
         entry.tradingSession = "Overlap";  // London + NY
      else if(mdt.hour >= 11 && mdt.hour < 17)
         entry.tradingSession = "NewYork";
      else
         entry.tradingSession = "OffHours";
      
      // Pre-market (1 hour before major session open)
      entry.isPreMarket = (mdt.hour == 1 || mdt.hour == 7);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate Derived Metrics (PUBLIC for EA access)                 |
   //| IMPORTANT: Must be called AFTER CalculateTimeSegments()          |
   //| IMPORTANT: entryRow parameter must be the ENTRY snapshot         |
   //+------------------------------------------------------------------+
   void CalculateDerivedMetrics(TradeLogEntry &entry, TradeLogEntry &entryRow)
   {
      // ═══════════════════════════════════════════════════════════
      // CRITICAL: Only calculate derived metrics on EXIT rows
      // ENTRY rows should skip this function entirely
      // ═══════════════════════════════════════════════════════════
      if(entry.rowType != "EXIT") return;
      
      // MFE Utilization - what % of max potential profit was captured?
      entry.mfeUtilization = (entry.mfe > 0) ? (entry.profit / entry.mfe) * 100 : 0;
      
      // MAE Impact - how much drawdown relative to profit?
      entry.maeImpact = (entry.profit > 0) ? (MathAbs(entry.mae) / entry.profit) * 100 : 0;
      
      // Excursion Efficiency - ratio of favorable vs total excursion
      double totalExcursion = entry.mfe + MathAbs(entry.mae);
      entry.excursionEfficiency = (totalExcursion > 0) ? entry.mfe / totalExcursion : 0;
      
      // Exit Quality Classification
      if(entry.profit > 0 && entry.runUpPips > entry.pips * 0.5)
         entry.exitQualityClass = "Early";  // Left significant money on table
      else if(entry.profit > 0 && entry.runUpPips <= entry.pips * 0.2)
         entry.exitQualityClass = "Optimal"; // Exited near peak
      else if(entry.profit < 0 && entry.runDownPips < entry.pips * 0.3)
         entry.exitQualityClass = "Late";    // Should have exited earlier
      else
         entry.exitQualityClass = "Good";    // Reasonable exit
      
      // Early Exit Opportunity Cost
      entry.earlyExitOpportunityCost = (entry.exitQualityClass == "Early") ? entry.runUpPips - entry.pips : 0;
      
      // ═══════════════════════════════════════════════════════════
      // PHYSICS DECAY ANALYSIS (KEY INSIGHT FROM YOUR RESEARCH!)
      // ═══════════════════════════════════════════════════════════
      entry.physicsScoreDecay = entryRow.entryPhysicsScore - entry.exitPhysicsScore;
      entry.speedDecay = entryRow.entrySpeed - entry.exitSpeed;
      entry.speedSlopeDecay = entryRow.entrySpeedSlope - entry.exitSpeedSlope;  // YOUR -0.31 vs -1.11 finding!
      
      // FIX: ConfluenceDecay should always be calculated, even when values are same
      // A confluence of 80 at entry and 80 at exit still represents decay over time
      // (the system worked to maintain that level through changing conditions)
      entry.confluenceDecay = entryRow.entryConfluence - entry.exitConfluence;
      
      entry.zoneTransitioned = (entryRow.entryZone != entry.exitZone);  // 37% edge predictor!
      
      // Data Quality Score
      entry.dataQualityScore = 100;
      if(entry.profit == 0) entry.dataQualityScore -= 10;
      if(entry.mfe == 0) entry.dataQualityScore -= 10;
      if(entry.holdTimeBars < 1) entry.dataQualityScore -= 20;
      if(entry.exitPhysicsScore == 0) entry.dataQualityScore -= 15;
      if(entry.exitSpeedSlope == 0) entry.dataQualityScore -= 10;
      
      // Validation Flags (semicolon delimiter to prevent CSV parsing errors)
      entry.validationFlags = "";
      if(entry.holdTimeMinutes < 1) entry.validationFlags += "SHORT_DURATION;";
      if(entry.zoneTransitioned) entry.validationFlags += "ZONE_TRANSITION;";
      if(entry.speedSlopeDecay < -1.0) entry.validationFlags += "STEEP_SLOPE_DECAY;";
      if(entry.exitQualityClass == "Early") entry.validationFlags += "EARLY_EXIT;";
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
         Print(StringFormat("🔧 Initializing CSV Logger for %s", symbol));
      
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
   // Initialize dedupe cache
   m_dedupeIndex = 0;
   m_dedupeSize = (config.dedupeCacheSize > 0) ? config.dedupeCacheSize : 128;
   ArrayResize(m_dedupeTickets, m_dedupeSize);
   ArrayResize(m_dedupeRowTypes, m_dedupeSize);
   ArrayResize(m_dedupeFingerprint, m_dedupeSize);
   ArrayResize(m_dedupeTimestamp, m_dedupeSize);
      
      if(m_config.debugMode)
      {
         Print(StringFormat("✅ CSV Logger Initialized: Symbol=%s | SignalLog=%s | TradeLog=%s", m_symbolName, m_config.signalLogFile, m_config.tradeLogFile));
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
      
      // Format numeric values to 2 decimal places to prevent CSV issues
      FileWrite(handle,
         entry.eaName, entry.eaVersion,
         TimeToString(entry.timestamp), entry.symbol, entry.signal, entry.signalType,
         DoubleToString(entry.quality, 2), 
         DoubleToString(entry.confluence, 2), 
         DoubleToString(entry.momentum, 2), 
         DoubleToString(entry.speed, 2), 
         DoubleToString(entry.acceleration, 2),
         DoubleToString(entry.entropy, 2), 
         DoubleToString(entry.jerk, 2), 
         DoubleToString(entry.physicsScore, 2),
         DoubleToString(entry.speedSlope, 2), 
         DoubleToString(entry.accelerationSlope, 2), 
         DoubleToString(entry.momentumSlope, 2), 
         DoubleToString(entry.confluenceSlope, 2), 
         DoubleToString(entry.jerkSlope, 2),
         entry.zone, entry.regime,
         DoubleToString(entry.price, m_symbolDigits), 
         DoubleToString(entry.spread, 2), 
         DoubleToString(entry.highThreshold, m_symbolDigits), 
         DoubleToString(entry.lowThreshold, m_symbolDigits),
         DoubleToString(entry.balance, 2), 
         DoubleToString(entry.equity, 2), 
         entry.openPositions,
         entry.physicsPass ? "PASS" : "REJECT", entry.rejectReason,
         entry.hour, entry.dayOfWeek
      );
      
      FileClose(handle);
      
      if(m_config.logToExpertLog)
      {
         string dbg = StringFormat("📝 Signal logged: %s | Quality=%s | Result=%s",
                                  entry.signalType,
                                  DoubleToString(entry.quality,2),
                                  entry.physicsPass ? "PASS" : "REJECT");
         Print(dbg);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Log Trade (Comprehensive - ENTRY and EXIT rows)                  |
   //+------------------------------------------------------------------+
   bool LogTrade(TradeLogEntry &entry)
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Logger not initialized");
         return false;
      }
      
      // Auto-calculate pips if not already set (EXIT rows only)
      if(entry.rowType == "EXIT" && entry.pips == 0 && entry.openPrice > 0 && entry.closePrice > 0)
      {
         entry.pips = CalculatePips(entry.openPrice, entry.closePrice, entry.type == "BUY");
      }

      // Dedupe check (if enabled)
      if(m_config.dedupeEnabled)
      {
         string fp = GenerateTradeFingerprint(entry);
         string rowTypeUpper = entry.rowType;
         StringToUpper(rowTypeUpper);
         if(IsDuplicateWithinWindow(entry.ticket, rowTypeUpper, fp, m_config.dedupeWindowSeconds))
         {
            if(m_config.debugMode)
            {
               Print(StringFormat("⚠️  Skipping duplicate trade log: #%I64u rowType=%s fp=%s", entry.ticket, entry.rowType, fp));
            }
            return true; // Considered successful to calling code; no duplicate written
         }
      }
      
      int handle = FileOpen(m_config.tradeLogFile, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Cannot open trade log file");
         return false;
      }
      
      FileSeek(handle, 0, SEEK_END);
      
      // Build CSV row as string (MQL5 FileWrite has parameter limit)
      string row = "";
      
      // Chunk 1: Core ID fields (15 fields)
      row += entry.eaName + "," + entry.eaVersion + "," + entry.rowType + "," + StringFormat("%I64u", entry.ticket) + ",";
      row += TimeToString(entry.timestamp) + "," + TimeToString(entry.openTime) + "," + TimeToString(entry.closeTime) + ",";
      row += entry.symbol + "," + entry.type + "," + DoubleToString(entry.lots, 2) + ",";
      row += DoubleToString(entry.price, m_symbolDigits) + "," + DoubleToString(entry.openPrice, m_symbolDigits) + ",";
      row += DoubleToString(entry.closePrice, m_symbolDigits) + "," + DoubleToString(entry.sl, m_symbolDigits) + "," + DoubleToString(entry.tp, m_symbolDigits) + ",";
      
      // Chunk 2: Entry Physics (19 fields)
      row += DoubleToString(entry.entryQuality, 2) + "," + DoubleToString(entry.entryConfluence, 2) + ",";
      row += DoubleToString(entry.entryMomentum, 2) + "," + DoubleToString(entry.entrySpeed, 2) + ",";
      row += DoubleToString(entry.entryAcceleration, 2) + "," + DoubleToString(entry.entryEntropy, 2) + ",";
      row += DoubleToString(entry.entryJerk, 2) + "," + DoubleToString(entry.entryPhysicsScore, 2) + ",";
      row += DoubleToString(entry.entrySpeedSlope, 2) + "," + DoubleToString(entry.entryAccelerationSlope, 2) + ",";
      row += DoubleToString(entry.entryMomentumSlope, 2) + "," + DoubleToString(entry.entryConfluenceSlope, 2) + ",";
      row += DoubleToString(entry.entryJerkSlope, 2) + "," + entry.entryZone + "," + entry.entryRegime + ",";
      row += DoubleToString(entry.entrySpread, 2) + ",";
      
      // Chunk 3: Exit Physics (20 fields)
      row += entry.exitReason + "," + DoubleToString(entry.exitQuality, 2) + "," + DoubleToString(entry.exitConfluence, 2) + ",";
      row += DoubleToString(entry.exitMomentum, 2) + "," + DoubleToString(entry.exitSpeed, 2) + ",";
      row += DoubleToString(entry.exitAcceleration, 2) + "," + DoubleToString(entry.exitEntropy, 2) + ",";
      row += DoubleToString(entry.exitJerk, 2) + "," + DoubleToString(entry.exitPhysicsScore, 2) + ",";
      row += DoubleToString(entry.exitSpeedSlope, 2) + "," + DoubleToString(entry.exitAccelerationSlope, 2) + ",";
      row += DoubleToString(entry.exitMomentumSlope, 2) + "," + DoubleToString(entry.exitConfluenceSlope, 2) + ",";
      row += DoubleToString(entry.exitJerkSlope, 2) + "," + entry.exitZone + "," + entry.exitRegime + ",";
      row += DoubleToString(entry.exitSpread, 2) + ",";
      
      // Chunk 4: Performance + Excursion (20 fields)
      row += DoubleToString(entry.profit, 2) + "," + DoubleToString(entry.profitPercent, 2) + "," + DoubleToString(entry.pips, 2) + ",";
      row += IntegerToString(entry.holdTimeBars) + "," + IntegerToString(entry.holdTimeMinutes) + ",";
      row += DoubleToString(entry.riskPercent, 2) + "," + DoubleToString(entry.rRatio, 2) + ",";
      row += DoubleToString(entry.slippage, 2) + "," + DoubleToString(entry.commission, 2) + ",";
      
      row += DoubleToString(entry.mfe, 2) + "," + DoubleToString(entry.mae, 2) + ",";
      row += DoubleToString(entry.mfePercent, 2) + "," + DoubleToString(entry.maePercent, 2) + ",";
      row += DoubleToString(entry.mfePips, 2) + "," + DoubleToString(entry.maePips, 2) + ",";
      row += IntegerToString(entry.mfeTimeBars) + "," + IntegerToString(entry.maeTimeBars) + ",";
      row += DoubleToString(entry.mfeUtilization, 2) + "," + DoubleToString(entry.maeImpact, 2) + "," + DoubleToString(entry.excursionEfficiency, 2) + ",";
      
      // Chunk 4: Post-Exit + Temporal (25 fields)
      row += DoubleToString(entry.runUpPrice, m_symbolDigits) + "," + DoubleToString(entry.runUpPips, 2) + ",";
      row += DoubleToString(entry.runUpPercent, 2) + "," + IntegerToString(entry.runUpTimeBars) + ",";
      row += DoubleToString(entry.runDownPrice, m_symbolDigits) + "," + DoubleToString(entry.runDownPips, 2) + ",";
      row += DoubleToString(entry.runDownPercent, 2) + "," + IntegerToString(entry.runDownTimeBars) + ",";
      row += entry.exitQualityClass + "," + DoubleToString(entry.earlyExitOpportunityCost, 2) + ",";
      
      row += IntegerToString(entry.hour) + "," + IntegerToString(entry.dayOfWeek) + ",";
      row += entry.timeSegment15M + "," + entry.timeSegment30M + "," + entry.timeSegment1H + ",";
      row += entry.timeSegment2H + "," + entry.timeSegment3H + "," + entry.timeSegment4H + ",";
   row += entry.tradingSession;
   row += ",";
   row += (entry.isWeekend ? "TRUE" : "FALSE");
   row += ",";
   row += (entry.isPreMarket ? "TRUE" : "FALSE");
   row += ",";
      
      row += IntegerToString(entry.entryHour) + "," + IntegerToString(entry.entryDayOfWeek) + ",";
      row += IntegerToString(entry.exitHour) + "," + IntegerToString(entry.exitDayOfWeek) + ",";
      
      // Chunk 6: Account + Decay + Signal + Quality (17 fields)
      row += DoubleToString(entry.balance, 2) + "," + DoubleToString(entry.equity, 2) + ",";
      row += DoubleToString(entry.balanceAfter, 2) + "," + DoubleToString(entry.equityAfter, 2) + ",";
      row += DoubleToString(entry.drawdownPercent, 2) + "," + IntegerToString(entry.openPositions) + ",";
      
      row += DoubleToString(entry.physicsScoreDecay, 2) + "," + DoubleToString(entry.speedDecay, 2) + ",";
      row += DoubleToString(entry.speedSlopeDecay, 2) + "," + DoubleToString(entry.confluenceDecay, 2) + ",";
   row += (entry.zoneTransitioned ? "TRUE" : "FALSE");
   row += ",";
      
      row += TimeToString(entry.signalTimestamp) + "," + DoubleToString(entry.signalTimeDelta, 2) + ",";
   row += (entry.signalPhysicsPass ? "TRUE" : "FALSE");
   row += ",";
   row += entry.signalRejectReason;
   row += ",";
      
      row += DoubleToString(entry.dataQualityScore, 2) + "," + entry.validationFlags + ",";
      row += DoubleToString(entry.aiEntryConfidence, 2) + "," + DoubleToString(entry.aiExitPrediction, 2);
      
      // Write complete row
      FileWriteString(handle, row + "\n");
      
      FileClose(handle);
      
      if(m_config.logToExpertLog)
      {
         double physicsScore = (entry.rowType == "ENTRY") ? entry.entryPhysicsScore : entry.exitPhysicsScore;
         string dbg = StringFormat("📝 %s logged: #%I64u | Type=%s | Physics=%s", 
                                  entry.rowType, 
                                  entry.ticket, 
                                  entry.type, 
                                  DoubleToString(physicsScore,2));
         Print(dbg);
      }

      // Update dedupe cache on successful write
      if(m_config.dedupeEnabled)
      {
         string fp = GenerateTradeFingerprint(entry);
         m_dedupeTickets[m_dedupeIndex] = entry.ticket;
         string rowTypeUpper = entry.rowType;
         StringToUpper(rowTypeUpper);
         m_dedupeRowTypes[m_dedupeIndex] = rowTypeUpper;
         m_dedupeFingerprint[m_dedupeIndex] = fp;
         m_dedupeTimestamp[m_dedupeIndex] = entry.timestamp;
         m_dedupeIndex = (m_dedupeIndex + 1) % m_dedupeSize;
      }
      
      return true;
   }

     //+------------------------------------------------------------------+
     //| Generate fingerprint for dedupe checks                             |
     //+------------------------------------------------------------------+
     string GenerateTradeFingerprint(TradeLogEntry &entry)
     {
        // fingerprint ignores timestamp and only takes significant fields
        string rowTypeUpper = entry.rowType;
        StringToUpper(rowTypeUpper);
        string fp = StringFormat("%I64u:%s:%s:%s:%s", 
                                  entry.ticket, 
                                  rowTypeUpper,
                                  DoubleToString(entry.openPrice, m_symbolDigits),
                                  DoubleToString(entry.closePrice, m_symbolDigits),
                                  DoubleToString(entry.profit, 2));
        return fp;
     }

     //+------------------------------------------------------------------+
     //| Check whether given ticket/rowType/fingerprint was logged within   |
     //| the dedupe window                                                    |
     //+------------------------------------------------------------------+
     bool IsDuplicateWithinWindow(ulong ticket, string rowType, string fingerprint, int windowSeconds)
     {
        if(m_dedupeSize == 0) return false;
        datetime now = TimeCurrent();
        for(int i = 0; i < m_dedupeSize; ++i)
        {
           if(m_dedupeTickets[i] == ticket && m_dedupeRowTypes[i] == rowType && m_dedupeFingerprint[i] == fingerprint)
           {
              int dt = (int)MathAbs(now - m_dedupeTimestamp[i]);
              if(dt <= windowSeconds)
                 return true; // duplicate within window
           }
        }
        return false;
     }

     //+------------------------------------------------------------------+
     //| Configure deduplication options                                    |
     //+------------------------------------------------------------------+
     void SetDeduplication(bool enabled, int windowSeconds = 2, int cacheSize = 128)
     {
        m_config.dedupeEnabled = enabled;
        m_config.dedupeWindowSeconds = windowSeconds;
        m_config.dedupeCacheSize = cacheSize;
        m_dedupeSize = cacheSize;
        ArrayResize(m_dedupeTickets, m_dedupeSize);
        ArrayResize(m_dedupeRowTypes, m_dedupeSize);
        ArrayResize(m_dedupeFingerprint, m_dedupeSize);
        ArrayResize(m_dedupeTimestamp, m_dedupeSize);
        m_dedupeIndex = 0;

        if(m_config.debugMode)
        {
            Print(StringFormat("🔧 Dedupe configured: enabled=%s windowSeconds=%d cacheSize=%d", 
                              (enabled ? "TRUE" : "FALSE"), 
                              windowSeconds, 
                              cacheSize));
        }
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
═══════════════════════════════════════════════════════════════════
DUAL-ROW TRADE LOGGING - EA INTEGRATION PATTERN
═══════════════════════════════════════════════════════════════════

STEP 1: Log ENTRY row when trade opens
────────────────────────────────────────────────────────────────────
void OnTradeOpen(ulong ticket)
{
   TradeLogEntry entry;
   entry.rowType = "ENTRY";
   entry.ticket = ticket;
   entry.timestamp = TimeCurrent();
   entry.openTime = TimeCurrent();
   
   // Capture current physics from indicator
   entry.quality = g_physics.GetQuality();
   entry.confluence = g_physics.GetConfluence();
   entry.speed = g_physics.GetSpeed();
   entry.speedSlope = CalculateSlope(g_physics.GetSpeed(1/2/3), 3);
   entry.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
   entry.physicsScore = g_physics.GetPhysicsScore();
   
   // Time segments auto-calculated
   g_logger.CalculateTimeSegments(entry.timestamp, entry);
   
   // Log ENTRY row
   g_logger.LogTrade(entry);
   
   // Store snapshot for decay analysis later
   g_tracker.StoreEntryPhysics(ticket, entry);
}

STEP 2: Log EXIT row when trade closes
────────────────────────────────────────────────────────────────────
void OnTradeClose(ulong ticket)
{
   // Retrieve ENTRY snapshot
   TradeLogEntry entryRow = g_tracker.GetEntryPhysics(ticket);
   
   // Create EXIT row
   TradeLogEntry exitRow;
   exitRow.rowType = "EXIT";
   exitRow.ticket = ticket;
   exitRow.timestamp = TimeCurrent();
   exitRow.closeTime = TimeCurrent();
   
   // Copy entry fields from snapshot
   exitRow.openTime = entryRow.openTime;
   exitRow.entryQuality = entryRow.quality;
   exitRow.entryPhysicsScore = entryRow.physicsScore;
   exitRow.entryZone = entryRow.zone;
   
   // Capture current exit physics
   exitRow.quality = g_physics.GetQuality();
   exitRow.speedSlope = CalculateSlope(g_physics.GetSpeed(1/2/3), 3);
   exitRow.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
   
   // Populate performance metrics
   exitRow.profit = ClosedTrade.profit;
   exitRow.pips = 0;  // Auto-calculated by LogTrade()
   exitRow.mfe = ClosedTrade.mfe;
   exitRow.mae = ClosedTrade.mae;
   
   // Calculate time segments and derived metrics
   g_logger.CalculateTimeSegments(exitRow.timestamp, exitRow);
   g_logger.CalculateDerivedMetrics(exitRow, entryRow);  // Computes decay!
   
   // Log EXIT row
   g_logger.LogTrade(exitRow);
   
   // Cleanup
   g_tracker.RemoveEntryPhysics(ticket);
}

KEY FEATURES:
────────────────────────────────────────────────────────────────────
✅ Auto-calculates pips if not set (EXIT rows)
✅ Auto-calculates time segments (15M-4H)
✅ Auto-calculates physics decay (speedSlopeDecay, zoneTransitioned)
✅ Auto-calculates exit quality (Early/Optimal/Late/Good)
✅ 2-decimal formatting (no CSV corruption)
✅ 90+ field comprehensive logging

RESEARCH-VALIDATED PREDICTORS:
────────────────────────────────────────────────────────────────────
🎯 Exit PhysicsScore: Winners 76.1 vs Losers 48.2 (+27.9 edge)
🎯 Zone Transitions: 31% winners vs 68% losers (+37% edge)
🎯 SpeedSlope Decay: -0.31 winners vs -1.11 losers (3.5x)
🎯 Confluence Decay: -8.2% winners vs -31.4% losers

═══════════════════════════════════════════════════════════════════
*/

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
   config.dedupeEnabled = true;           // Enable file-level dedupe by default in example
   config.dedupeWindowSeconds = 2;         // 2 second dedupe window
   config.dedupeCacheSize = 128;           // Keep last 128 entries for duplicate detection
   
   if(!g_logger.Initialize(_Symbol, config))
   {
      Print("Failed to initialize logger");
      return INIT_FAILED;
   }
   // Configure dedup - this is optional and alternative to config flags
   g_logger.SetDeduplication(true, 2, 128);
   
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
