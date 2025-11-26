/**
 * Enhanced Trading Dashboard & Optimization Data Model
 * TypeScript Type Definitions v2.0
 * 
 * Complete type system for processing MT5 backtest reports, EA trades, and EA signals
 */

// ============================================================================
// RAW INPUT DATA STRUCTURES
// ============================================================================

/**
 * MT5 Backtest Report Row (from MetaTrader Strategy Tester)
 * Format: Time, Deal, Symbol, Type, Direction, Volume, Price, Order, Commission, Swap, Profit, Balance
 */
export interface MT5ReportRow {
  Time: string;           // YYYY.MM.DD HH:MM:SS
  Deal: string;           // Deal ID
  Symbol: string;         // Trading symbol (e.g., NAS100)
  Type: string;           // sell/buy
  Direction: string;      // in/out
  Volume: string;         // Trade volume
  Price: string;          // Symbol price
  Order: string;          // Order ID
  Commission: string;     // Commission amount
  Swap: string;           // Swap/overnight fees
  Profit: string;         // Profit/loss
  Balance: string;        // Account balance
  Comment: string;        // Trade comment/notes
}

/**
 * EA Trades CSV Row (from TP_CSV_Logger.mqh dual-row format)
 * 110+ fields with ENTRY and EXIT rows
 */
export interface EATradeRow {
  EAName: string;
  EAVersion: string;
  RowType: 'ENTRY' | 'EXIT';
  Ticket: number;
  Timestamp: string;
  OpenTime: string;
  CloseTime: string;
  Symbol: string;
  Type: string;           // BUY/SELL
  Lots: number;
  Price: number;
  OpenPrice: number;
  ClosePrice: number;
  SL: number;
  TP: number;
  
  // Entry Physics
  Entry_Quality: number;
  Entry_Confluence: number;
  Entry_Momentum: number;
  Entry_Speed: number;
  Entry_Acceleration: number;
  Entry_Entropy: number;
  Entry_Jerk: number;
  Entry_PhysicsScore: number;
  Entry_SpeedSlope: number;
  Entry_AccelerationSlope: number;
  Entry_MomentumSlope: number;
  Entry_ConfluenceSlope: number;
  Entry_JerkSlope: number;
  Entry_Zone: string;
  Entry_Regime: string;
  Entry_Spread: number;
  
  // Exit Physics (EXIT row only)
  ExitReason: string;
  Exit_Quality: number;
  Exit_Confluence: number;
  Exit_Momentum: number;
  Exit_Speed: number;
  Exit_Acceleration: number;
  Exit_Entropy: number;
  Exit_Jerk: number;
  Exit_PhysicsScore: number;
  Exit_SpeedSlope: number;
  Exit_AccelerationSlope: number;
  Exit_MomentumSlope: number;
  Exit_ConfluenceSlope: number;
  Exit_JerkSlope: number;
  Exit_Zone: string;
  Exit_Regime: string;
  Exit_Spread: number;
  
  // Performance Metrics (EXIT row only)
  Profit: number;
  ProfitPercent: number;
  Pips: number;
  HoldTimeBars: number;
  HoldTimeMinutes: number;
  RiskPercent: number;
  RRatio: number;
  Slippage: number;
  Commission: number;
  
  // Excursion Analysis
  MFE: number;
  MAE: number;
  MFE_Percent: number;
  MAE_Percent: number;
  MFE_Pips: number;
  MAE_Pips: number;
  MFE_TimeBars: number;
  MAE_TimeBars: number;
  MFEUtilization: number;
  MAEImpact: number;
  ExcursionEfficiency: number;
  
  // RunUp/RunDown
  RunUp_Price: number;
  RunUp_Pips: number;
  RunUp_Percent: number;
  RunUp_TimeBars: number;
  RunDown_Price: number;
  RunDown_Pips: number;
  RunDown_Percent: number;
  RunDown_TimeBars: number;
  ExitQualityClass: string;
  EarlyExitOpportunityCost: number;
  
  // Temporal Data
  Hour: number;
  DayOfWeek: number;
  TimeSegment15M: string;
  TimeSegment30M: string;
  TimeSegment1H: string;
  TimeSegment2H: string;
  TimeSegment3H: string;
  TimeSegment4H: string;
  TradingSession: string;
  IsWeekend: boolean;
  IsPreMarket: boolean;
  EntryHour: number;
  EntryDayOfWeek: number;
  ExitHour: number;
  ExitDayOfWeek: number;
  
  // Account State
  Balance: number;
  Equity: number;
  BalanceAfter: number;
  EquityAfter: number;
  DrawdownPercent: number;
  OpenPositions: number;
  
  // Physics Decay
  PhysicsScoreDecay: number;
  SpeedDecay: number;
  SpeedSlopeDecay: number;
  ConfluenceDecay: number;
  ZoneTransitioned: boolean;
  
  // Signal Correlation
  SignalTimestamp: string;
  SignalTimeDelta: number;
  SignalPhysicsPass: boolean;
  SignalRejectReason: string;
  
  // Data Quality
  DataQualityScore: number;
  ValidationFlags: string;
  AIEntryConfidence: number;
  AIExitPrediction: number;
}

/**
 * EA Signals CSV Row (from TP_CSV_Logger.mqh)
 * 33 fields capturing signal generation data
 */
export interface EASignalRow {
  EAName: string;
  EAVersion: string;
  Timestamp: string;      // Signal generation timestamp
  Symbol: string;
  Signal: number;         // Signal value
  SignalType: string;     // BUY/SELL signal
  
  // Physics Metrics
  Quality: number;
  Confluence: number;
  Speed: number;
  Acceleration: number;
  Momentum: number;
  Entropy: number;
  Jerk: number;
  PhysicsScore: number;
  
  // Slope Metrics
  SpeedSlope: number;
  AccelerationSlope: number;
  MomentumSlope: number;
  ConfluenceSlope: number;
  JerkSlope: number;
  
  // Classification
  Zone: string;
  Regime: string;
  
  // Market Context
  Price: number;
  Spread: number;
  HighThreshold: number;
  LowThreshold: number;
  
  // Account State
  Balance: number;
  Equity: number;
  OpenPositions: number;
  
  // Filter Status
  PhysicsPass: string;    // PASS/FAIL
  RejectReason: string;
  
  // Time Context
  Hour: number;
  DayOfWeek: number;
}

// ============================================================================
// ENHANCED DATA MODEL (Output Structure)
// ============================================================================

/**
 * Complete processed trade data with paired entry/exit
 * Implements the Enhanced Trading Dashboard & Optimization Data Model v2.0
 */
export interface ProcessedTradeData {
  // ═══════════════════════════════════════════════════════════
  // ENTRY DATA (Core Identifiers)
  // ═══════════════════════════════════════════════════════════
  IN_Deal: number;                    // MT5: Deal ID
  Report_Source: string;              // Source identifier
  IN_Trade_ID: number;                // Unique trade identifier (pairs entry/exit)
  IN_MT_MASTER_DATE_TIME: string;     // MT5 timestamp (full)
  IN_MT_Date: string;                 // MT5 date portion
  IN_MT_Time: string;                 // MT5 time portion
  IN_MT_Day: string;                  // MT5 day of week
  IN_MT_Month: string;                // MT5 month
  
  // CST Converted Times
  IN_CST_Date_OP_01: string;          // Entry date in CST (MT5 - 8hrs)
  IN_CST_Time_OP_01: string;          // Entry time in CST
  IN_CST_Day_OP_01: string;           // Entry day in CST
  IN_CST_Month_OP_01: string;         // Entry month in CST
  
  // ═══════════════════════════════════════════════════════════
  // TIME WINDOWS (Entry)
  // ═══════════════════════════════════════════════════════════
  IN_Segment_15M_OP_01: string;       // "15-069" format (96 segments/day)
  IN_Segment_30M_OP_01: string;       // "30-035" format (48 segments/day)
  IN_Segment_01H_OP_01: string;       // "1h-018" format (24 segments/day)
  IN_Segment_02H_OP_01: string;       // 2-hour segments (12/day)
  IN_Segment_03H_OP_01: string;       // 3-hour segments (8/day)
  IN_Segment_04H_OP_01: string;       // 4-hour segments (6/day)
  IN_Session_Name_OP_02: string;      // "News"/"Opening Bell"/"Floor Session"/etc.
  
  // ═══════════════════════════════════════════════════════════
  // STRATEGY INFO
  // ═══════════════════════════════════════════════════════════
  Strategy_ID_OP_03: string;          // EA strategy identifier
  Strategy_Version_ID_OP_03: string;  // EA version (e.g., "4.2.0.0_SLOPE")
  Optimization_ID_OP_03: string;      // Optimization parameters ID
  Report_Broker_OP_03: string;        // Broker name
  Symbol_OP_03: string;               // Trading symbol (must match entry/exit)
  Chart_TF_OP_01: string;             // Chart timeframe
  
  // ═══════════════════════════════════════════════════════════
  // ORDER INFO (Entry)
  // ═══════════════════════════════════════════════════════════
  IN_Order_Type_OP_01: string;        // "buy"/"sell"
  IN_Order_Direction: string;         // "in" (always for entry)
  Volume_OP_03: number;               // Lot size (must match entry/exit)
  IN_Symbol_Price_OP_03: number;      // Entry price
  IN_Balance_OP_01: number;           // Account balance at entry
  
  // ═══════════════════════════════════════════════════════════
  // EXIT DATA
  // ═══════════════════════════════════════════════════════════
  OUT_Profit_OP_01: number;           // Profit/loss from trade
  OUT_Balance_OP_01: number;          // Account balance after exit
  OUT_Trade_ID: number;               // Must match IN_Trade_ID
  OUT_Deal: number;                   // Exit deal ID
  OUT_CST_Date_OP_03: string;         // Exit date in CST
  OUT_CST_Time_OP_03: string;         // Exit time in CST
  OUT_CST_Day_OP_03: string;          // Exit day in CST
  OUT_CST_Month_OP_03: string;        // Exit month in CST
  
  // ═══════════════════════════════════════════════════════════
  // EXIT WINDOWS
  // ═══════════════════════════════════════════════════════════
  OUT_Segment_15M_OP_03: string;
  OUT_Segment_30M_OP_03: string;
  OUT_Segment_01H_OP_03: string;
  OUT_Segment_02H_OP_03: string;
  OUT_Segment_03H_OP_03: string;
  OUT_Segment_04H_OP_03: string;
  OUT_Session_Name_OP_03: string;
  
  // ═══════════════════════════════════════════════════════════
  // EXIT DETAILS
  // ═══════════════════════════════════════════════════════════
  OUT_Order_Type: string;             // Exit order type
  OUT_Order_Direction: string;        // "out" (always for exit)
  OUT_Symbol_Price_OP_01: number;     // Exit price
  OUT_Commission: number;             // Commission paid
  OUT_Swap: number;                   // Swap/overnight fees
  OUT_Comment?: string;               // Trade comment (contains [tp]/[sl] flags)
  OUT_Symbol?: string;                // Exit symbol (useful for validation)
  EA_Entry_Symbol?: string;           // Symbol recorded in EA ENTRY row
  EA_Exit_Symbol?: string;            // Symbol recorded in EA EXIT row
  
  // ═══════════════════════════════════════════════════════════
  // RESULT INFO
  // ═══════════════════════════════════════════════════════════
  Trade_Result: 'Win' | 'Loss' | 'Breakeven' | 'DataError';   // Based on profit (DataError = invalid/missing profit)
  Trade_Direction: 'Long' | 'Short';             // Based on order type
  
  // ═══════════════════════════════════════════════════════════
  // EA ENHANCED DATA (from EA CSVs)
  // ═══════════════════════════════════════════════════════════
  
  // Entry Physics (from EA Trades ENTRY row)
  EA_Entry_Quality: number;
  EA_Entry_Confluence: number;
  EA_Entry_Momentum: number;
  EA_Entry_Speed: number;
  EA_Entry_Acceleration: number;
  EA_Entry_Entropy: number;
  EA_Entry_Jerk: number;
  EA_Entry_PhysicsScore: number;
  EA_Entry_SpeedSlope: number;
  EA_Entry_AccelerationSlope: number;
  EA_Entry_MomentumSlope: number;
  EA_Entry_ConfluenceSlope: number;
  EA_Entry_JerkSlope: number;
  EA_Entry_Zone: string;
  EA_Entry_Regime: string;
  EA_Entry_Spread: number;
  
  // Exit Physics (from EA Trades EXIT row)
  EA_ExitReason: string;
  EA_Exit_Quality: number;
  EA_Exit_Confluence: number;
  EA_Exit_Momentum: number;
  EA_Exit_Speed: number;
  EA_Exit_Acceleration: number;
  EA_Exit_Entropy: number;
  EA_Exit_Jerk: number;
  EA_Exit_PhysicsScore: number;
  EA_Exit_SpeedSlope: number;
  EA_Exit_AccelerationSlope: number;
  EA_Exit_MomentumSlope: number;
  EA_Exit_ConfluenceSlope: number;
  EA_Exit_JerkSlope: number;
  EA_Exit_Zone: string;
  EA_Exit_Regime: string;
  EA_Exit_Spread: number;
  
  // Performance Metrics (from EA Trades EXIT row)
  EA_Profit: number;                  // Dollar profit from EA (for QA reconciliation with MT5)
  EA_ProfitPercent: number;
  EA_Pips: number;
  EA_HoldTimeBars: number;
  EA_HoldTimeMinutes: number;
  EA_RiskPercent: number;
  EA_RRatio: number;
  
  // Excursion Analysis
  EA_MFE: number;
  EA_MAE: number;
  EA_MFE_Percent: number;
  EA_MAE_Percent: number;
  EA_MFE_Pips: number;
  EA_MAE_Pips: number;
  EA_MFE_TimeBars: number;
  EA_MAE_TimeBars: number;
  EA_MFEUtilization: number;
  EA_MAEImpact: number;
  EA_ExcursionEfficiency: number;
  
  // RunUp/RunDown
  EA_RunUp_Price: number;
  EA_RunUp_Pips: number;
  EA_RunUp_Percent: number;
  EA_RunUp_TimeBars: number;
  EA_RunDown_Price: number;
  EA_RunDown_Pips: number;
  EA_RunDown_Percent: number;
  EA_RunDown_TimeBars: number;
  EA_ExitQualityClass: string;
  EA_EarlyExitOpportunityCost: number;
  
  // Physics Decay Analysis
  EA_PhysicsScoreDecay: number;
  EA_SpeedDecay: number;
  EA_SpeedSlopeDecay: number;
  EA_ConfluenceDecay: number;
  EA_ZoneTransitioned: boolean;
  
  // Entry Signal Correlation (from EA Signals CSV - at trade entry)
  Signal_Entry_Matched: boolean;
  Signal_Entry_Timestamp: string | null;
  Signal_Entry_TimeDelta: number | null;   // Minutes between signal and entry
  Signal_Entry_Quality: number | null;
  Signal_Entry_Confluence: number | null;
  Signal_Entry_Speed: number | null;
  Signal_Entry_Acceleration: number | null;
  Signal_Entry_Momentum: number | null;
  Signal_Entry_Entropy: number | null;
  Signal_Entry_Jerk: number | null;
  Signal_Entry_PhysicsScore: number | null;
  Signal_Entry_SpeedSlope: number | null;
  Signal_Entry_AccelerationSlope: number | null;
  Signal_Entry_MomentumSlope: number | null;
  Signal_Entry_ConfluenceSlope: number | null;
  Signal_Entry_JerkSlope: number | null;
  Signal_Entry_Zone: string | null;
  Signal_Entry_Regime: string | null;
  Signal_Entry_PhysicsPass: string | null;
  Signal_Entry_RejectReason: string | null;
  
  // Exit Signal Correlation (from EA Signals CSV - at trade exit)
  Signal_Exit_Matched: boolean;
  Signal_Exit_Timestamp: string | null;
  Signal_Exit_TimeDelta: number | null;   // Minutes between signal and exit
  Signal_Exit_Quality: number | null;
  Signal_Exit_Confluence: number | null;
  Signal_Exit_Speed: number | null;
  Signal_Exit_Acceleration: number | null;
  Signal_Exit_Momentum: number | null;
  Signal_Exit_Entropy: number | null;
  Signal_Exit_Jerk: number | null;
  Signal_Exit_PhysicsScore: number | null;
  Signal_Exit_SpeedSlope: number | null;
  Signal_Exit_AccelerationSlope: number | null;
  Signal_Exit_MomentumSlope: number | null;
  Signal_Exit_ConfluenceSlope: number | null;
  Signal_Exit_JerkSlope: number | null;
  Signal_Exit_Zone: string | null;
  Signal_Exit_Regime: string | null;
  Signal_Exit_PhysicsPass: string | null;
  Signal_Exit_RejectReason: string | null;
  
  // ═══════════════════════════════════════════════════════════
  // ENHANCED MARKET CONTEXT (Future: Polygon.io integration)
  // ═══════════════════════════════════════════════════════════
  IN_Market_Volatility?: number;
  IN_Market_Volume?: number;
  IN_Market_Trend?: string;
  IN_Economic_Events?: string;
  OUT_Market_Volatility?: number;
  OUT_Market_Volume?: number;
  
  // ═══════════════════════════════════════════════════════════
  // AI ANALYSIS (Future: Claude API integration)
  // ═══════════════════════════════════════════════════════════
  AI_Entry_Signal_Confidence?: number;
  AI_Exit_Signal_Confidence?: number;
  AI_Market_Sentiment?: string;
  AI_Risk_Score?: number;
  AI_Trade_Rationale?: string;
  AI_Pattern_Detected?: string;
  
  // ═══════════════════════════════════════════════════════════
  // PERFORMANCE METRICS (Calculated)
  // ═══════════════════════════════════════════════════════════
  Trade_Duration_Minutes: number;
  Trade_ROI_Percentage: number;
  Trade_Risk_Reward_Ratio: number;
  Trade_MAE: number;
  Trade_MFE: number;
  
  // ═══════════════════════════════════════════════════════════
  // DATA QUALITY & METADATA
  // ═══════════════════════════════════════════════════════════
  DataQuality: {
    score: number;                    // 0-100
    missingFields: string[];
    validationFlags: string[];
  };
  ProcessingTimestamp: string;        // ISO timestamp
  SourceFiles: {
    mt5Report: string;
    eaTradesCSV: string;
    eaSignalsCSV: string;
  };
}

// ============================================================================
// SUPPORTING TYPES
// ============================================================================

export interface TimeSegments {
  segment15m: string;
  segment30m: string;
  segment1h: string;
  segment2h: string;
  segment3h: string;
  segment4h: string;
}

export interface ProcessedTimeData extends TimeSegments {
  mt5DateTime: string;
  mt5Date: string;
  mt5Time: string;
  mt5Day: string;
  mt5Month: string;
  cstDate: string;
  cstTime: string;
  cstDay: string;
  cstMonth: string;
  session: string;
}

export interface ValidationError {
  type: string;
  field?: string;
  tradeIndex?: number;
  message: string;
  severity: 'CRITICAL' | 'WARNING';
}

export interface ValidationResult {
  isValid: boolean;
  criticalErrors: ValidationError[];
  warnings: ValidationError[];
}

export interface ProcessingStatistics {
  totalMT5Trades: number;
  pairedTrades: number;
  unmatchedTrades: number;
  eaTradesMatched: number;
  eaSignalsMatched: number;
  processingTimeMs: number;
  dataQualityScore: number;
}

export interface ProcessedDataset {
  metadata: {
    processingTimestamp: string;
    dataModelVersion: string;
    totalTrades: number;
    sourceFiles: {
      mt5Report: string;
      eaTradesCSV: string;
      eaSignalsCSV: string;
    };
  };
  trades: ProcessedTradeData[];
  statistics: ProcessingStatistics;
  validation: ValidationResult;
}
