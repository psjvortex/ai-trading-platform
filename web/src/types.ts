export interface Trade {
  IN_Deal: string | number;
  IN_Trade_ID: string | number;
  IN_MT_MASTER_DATE_TIME: string;
  Symbol_OP_03: string;
  Strategy_Version_ID_OP_03?: string;
  Strategy_ID_OP_03?: string;
  Chart_TF_OP_01?: string;
  IN_Order_Direction: string;
  Trade_Direction: string; // "Long" or "Short"
  OUT_Profit_OP_01: number;
  OUT_Commission: number;
  OUT_Swap: number;
  OUT_Comment?: string;
  Trade_Result: string; // "WIN" or "LOSS"
  
  // Time segments
  Report_Source?: string;
  IN_MT_Date?: string;
  IN_MT_Time?: string;
  IN_MT_Day?: string;
  IN_MT_Month?: string;
  IN_CST_Date_OP_01?: string;
  IN_CST_Time_OP_01?: string;
  IN_CST_Day_OP_01?: string;
  IN_CST_Month_OP_01?: string;
  IN_Segment_15M_OP_01?: string;
  IN_Segment_30M_OP_01?: string;
  IN_Segment_01H_OP_01?: string;
  IN_Segment_02H_OP_01?: string;
  IN_Segment_03H_OP_01?: string;
  IN_Segment_04H_OP_01?: string;
  IN_Session_Name_OP_02?: string;
  IN_Order_Type_OP_01?: string;
  Volume_OP_03?: number;
  IN_Symbol_Price_OP_03?: number;
  IN_Balance_OP_01?: number;
  
  // Exit Data
  OUT_Balance_OP_01?: number;
  OUT_Trade_ID?: number;
  OUT_Deal?: number;
  OUT_CST_Date_OP_03?: string;
  OUT_CST_Time_OP_03?: string;
  OUT_CST_Day_OP_03?: string;
  OUT_CST_Month_OP_03?: string;
  OUT_Segment_15M_OP_03?: string;
  OUT_Segment_30M_OP_03?: string;
  OUT_Segment_01H_OP_03?: string;
  OUT_Segment_02H_OP_03?: string;
  OUT_Segment_03H_OP_03?: string;
  OUT_Segment_04H_OP_03?: string;
  OUT_Session_Name_OP_03?: string;
  OUT_Order_Type?: string;
  OUT_Order_Direction?: string;
  OUT_Symbol_Price_OP_01?: number;
  OUT_Symbol?: string;
  
  // Performance metrics
  Trade_ROI_Percentage?: number;
  Trade_Risk_Reward_Ratio?: number;
  
  // Physics Metrics - Entry
  EA_Entry_Spread: number;
  EA_Entry_ConfluenceSlope: number;
  EA_Entry_Entropy: number;
  EA_Entry_PhysicsScore: number;
  EA_Entry_Speed: number;
  EA_Entry_Acceleration: number;
  EA_Entry_Momentum: number;
  EA_Entry_Jerk: number;
  EA_Entry_Confluence: number;
  EA_Entry_Quality?: number;
  EA_Entry_SpeedSlope?: number;
  EA_Entry_AccelerationSlope?: number;
  EA_Entry_MomentumSlope?: number;
  EA_Entry_JerkSlope?: number;
  EA_Entry_Zone?: string;
  EA_Entry_Regime?: string;

  // Signal Metrics - Entry
  Signal_Entry_Matched?: boolean;
  Signal_Entry_Timestamp?: string | null;
  Signal_Entry_TimeDelta?: number | null;
  Signal_Entry_Quality?: number | null;
  Signal_Entry_Confluence?: number | null;
  Signal_Entry_Entropy?: number | null;
  Signal_Entry_Speed?: number | null;
  Signal_Entry_Acceleration?: number | null;
  Signal_Entry_Momentum?: number | null;
  Signal_Entry_Jerk?: number | null;
  Signal_Entry_PhysicsScore?: number | null;
  Signal_Entry_SpeedSlope?: number | null;
  Signal_Entry_AccelerationSlope?: number | null;
  Signal_Entry_MomentumSlope?: number | null;
  Signal_Entry_ConfluenceSlope?: number | null;
  Signal_Entry_JerkSlope?: number | null;
  Signal_Entry_Zone?: string | null;
  Signal_Entry_Regime?: string | null;
  Signal_Entry_PhysicsPass?: boolean | null;
  Signal_Entry_RejectReason?: string | null;

  // Physics Metrics - Exit
  EA_Exit_Spread: number;
  EA_Exit_ConfluenceSlope?: number;
  EA_Exit_Entropy: number;
  EA_Exit_PhysicsScore: number;
  EA_Exit_Speed: number;
  EA_Exit_Acceleration: number;
  EA_Exit_Momentum: number;
  EA_Exit_Jerk: number;
  EA_Exit_Confluence: number;
  EA_Exit_Quality: number;
  EA_ExitQualityClass: string;
  EA_ExitReason: string;
  EA_Exit_SpeedSlope?: number;
  EA_Exit_AccelerationSlope?: number;
  EA_Exit_MomentumSlope?: number;
  EA_Exit_JerkSlope?: number;
  EA_Exit_Zone?: string;
  EA_Exit_Regime?: string;

  // Signal Metrics - Exit
  Signal_Exit_Matched?: boolean;
  Signal_Exit_Timestamp?: string | null;
  Signal_Exit_TimeDelta?: number | null;
  Signal_Exit_Quality?: number | null;
  Signal_Exit_Confluence?: number | null;
  Signal_Exit_Entropy?: number | null;
  Signal_Exit_Speed?: number | null;
  Signal_Exit_Acceleration?: number | null;
  Signal_Exit_Momentum?: number | null;
  Signal_Exit_Jerk?: number | null;
  Signal_Exit_PhysicsScore?: number | null;
  Signal_Exit_SpeedSlope?: number | null;
  Signal_Exit_AccelerationSlope?: number | null;
  Signal_Exit_MomentumSlope?: number | null;
  Signal_Exit_ConfluenceSlope?: number | null;
  Signal_Exit_JerkSlope?: number | null;
  Signal_Exit_Zone?: string | null;
  Signal_Exit_Regime?: string | null;
  Signal_Exit_PhysicsPass?: boolean | null;
  Signal_Exit_RejectReason?: string | null;
  
  // Calculated
  NetProfit: number;
  
  // Efficiency / Excursion Metrics
  Trade_MAE?: number;
  Trade_MFE?: number;
  EA_MFE?: number;
  EA_MAE?: number;
  EA_MFE_Percent?: number;
  EA_MAE_Percent?: number;
  EA_MFE_Pips?: number;
  EA_MAE_Pips?: number;
  EA_MFE_TimeBars?: number;
  EA_MAE_TimeBars?: number;
  EA_MFEUtilization?: number;
  EA_MAEImpact?: number;
  EA_ExcursionEfficiency?: number;
  
  // Post-Exit Run Up/Down
  EA_RunUp_Price?: number;
  EA_RunUp_Pips?: number;
  EA_RunUp_Percent?: number;
  EA_RunUp_TimeBars?: number;
  EA_RunDown_Price?: number;
  EA_RunDown_Pips?: number;
  EA_RunDown_Percent?: number;
  EA_RunDown_TimeBars?: number;
  EA_EarlyExitOpportunityCost?: number;
  
  // Physics decay metrics
  EA_PhysicsScoreDecay?: number;
  EA_SpeedDecay?: number;
  EA_SpeedSlopeDecay?: number;
  EA_ConfluenceDecay?: number;
  EA_ZoneTransitioned?: boolean;
  
  // Trade timing
  EA_HoldTimeBars?: number;
  EA_HoldTimeMinutes?: number;
  Trade_Duration_Minutes?: number;
  
  // Additional EA metrics
  EA_Profit?: number;
  EA_ProfitPercent?: number;
  EA_Pips?: number;
  EA_RiskPercent?: number;
  EA_RRatio?: number;
}

export interface DashboardState {
  trades: Trade[];
  loading: boolean;
  error: string | null;
}

/**
 * Optimization Run Metadata - parsed from v5.0.0.3+ filenames
 */
export interface OptimizationRunMeta {
  symbol: string;           // NAS100, EURUSD, BTCUSD
  timeframe: string;        // M05, H01, D01
  broker: string;           // FTMO, APEX, ICM
  pass: string;             // BL, P1, P2, P3, FN
  passNumber: number;       // 0=Baseline, 1-3=Passes, 4=Final
  sampleType: string;       // IS, OOS1, OOS2, OOS3
  isInSample: boolean;      // true for IS, false for OOS
  oosNumber: number | null; // null for IS, 1-3 for OOS
  dateRange: string;        // 2025JanOct, 2020JanMar
  eaVersion: string;        // 5.0.0.3
  fileType: string;         // trades, signals
  rawFilename: string;      // Original filename
}

/**
 * Get display label for optimization pass
 */
export function getPassLabel(pass: string): string {
  const labels: Record<string, string> = {
    'BL': 'Baseline',
    'P1': 'Pass 1',
    'P2': 'Pass 2', 
    'P3': 'Pass 3',
    'FN': 'Final'
  };
  return labels[pass] || pass;
}

/**
 * Get display label for sample type
 */
export function getSampleLabel(sampleType: string): string {
  if (sampleType === 'IS') return 'In-Sample';
  if (sampleType.startsWith('OOS')) return `Out-of-Sample ${sampleType.slice(3)}`;
  return sampleType;
}

/**
 * Get color class for pass badge
 */
export function getPassColor(pass: string): string {
  const colors: Record<string, string> = {
    'BL': 'bg-gray-500/20 text-gray-400',
    'P1': 'bg-blue-500/20 text-blue-400',
    'P2': 'bg-purple-500/20 text-purple-400',
    'P3': 'bg-orange-500/20 text-orange-400',
    'FN': 'bg-green-500/20 text-green-400'
  };
  return colors[pass] || 'bg-gray-500/20 text-gray-400';
}

/**
 * Get color class for sample type badge
 */
export function getSampleColor(sampleType: string): string {
  if (sampleType === 'IS') return 'bg-emerald-500/20 text-emerald-400';
  return 'bg-amber-500/20 text-amber-400';
}
