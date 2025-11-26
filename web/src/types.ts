export interface Trade {
  IN_Deal: string;
  IN_Trade_ID: string;
  IN_MT_MASTER_DATE_TIME: string;
  Symbol_OP_03: string;
  Strategy_Version_ID_OP_03?: string;
  Chart_TF_OP_01?: string;
  IN_Order_Direction: string;
  Trade_Direction: string; // "Long" or "Short"
  OUT_Profit_OP_01: number;
  OUT_Commission: number;
  OUT_Swap: number;
  OUT_Comment?: string;
  Trade_Result: string; // "WIN" or "LOSS"
  
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

  // Signal Metrics - Entry
  Signal_Entry_Quality: number;
  Signal_Entry_Confluence: number;
  Signal_Entry_Entropy: number;
  Signal_Entry_Speed: number;
  Signal_Entry_Acceleration: number;
  Signal_Entry_Momentum: number;
  Signal_Entry_Jerk: number;
  Signal_Entry_PhysicsScore: number;
  Signal_Entry_SpeedSlope: number;
  Signal_Entry_AccelerationSlope: number;
  Signal_Entry_MomentumSlope: number;
  Signal_Entry_ConfluenceSlope: number;
  Signal_Entry_JerkSlope: number;
  Signal_Entry_Zone: string;
  Signal_Entry_Regime: string;

  // Physics Metrics - Exit
  EA_Exit_Spread: number;
  EA_Exit_ConfluenceSlope: number;
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

  // Signal Metrics - Exit
  Signal_Exit_Quality: number;
  Signal_Exit_Confluence: number;
  Signal_Exit_Entropy: number;
  Signal_Exit_Speed: number;
  Signal_Exit_Acceleration: number;
  Signal_Exit_Momentum: number;
  Signal_Exit_Jerk: number;
  Signal_Exit_PhysicsScore: number;
  Signal_Exit_SpeedSlope: number;
  Signal_Exit_AccelerationSlope: number;
  Signal_Exit_MomentumSlope: number;
  Signal_Exit_ConfluenceSlope: number;
  Signal_Exit_JerkSlope: number;
  Signal_Exit_Zone: string;
  Signal_Exit_Regime: string;
  
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
  
  // Trade timing
  EA_HoldTimeBars?: number;
  EA_HoldTimeMinutes?: number;
  Trade_Duration_Minutes?: number;
  
  // Additional Metrics
  EA_Entry_Quality?: number;
  EA_Entry_SpeedSlope?: number;
  EA_Entry_AccelerationSlope?: number;
  EA_Entry_MomentumSlope?: number;
  EA_Entry_JerkSlope?: number;
  EA_Entry_Zone?: string;
  EA_Entry_Regime?: string;
}

export interface DashboardState {
  trades: Trade[];
  loading: boolean;
  error: string | null;
}
