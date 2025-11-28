# TickPhysics EA Functional Requirements Document (FRD)
## Version 5.0.0.5 - Living Document

> **Purpose**: This document serves as a comprehensive reference for the TickPhysics EA system.
> It should be updated with each significant change so any Claude session can understand the current state.
> 
> **Last Updated**: 2025-11-28
> **Current EA Version**: 5.0.0.5 (Time Segment Filters + Ceiling Filters)

---

## 🔄 UPDATE PROTOCOL

**To update this document, simply type: `update FRD`**

When triggered, Claude will:
1. Read this FRD document
2. Check recent git commits (`git log -5 --oneline`)
3. Review changes made in the current session
4. Update relevant sections (version history, inputs, handoff notes, etc.)
5. Commit the updated FRD

---

## Table of Contents
1. [System Overview](#1-system-overview)
2. [EA Version History](#2-ea-version-history)
3. [Current EA Inputs Reference](#3-current-ea-inputs-reference)
4. [Filter System Architecture](#4-filter-system-architecture)
5. [Data Model & CSV Processing](#5-data-model--csv-processing)
6. [Optimization Dashboard](#6-optimization-dashboard)
7. [Key Algorithms](#7-key-algorithms)
8. [File Locations](#8-file-locations)
9. [Pending Improvements](#9-pending-improvements)
10. [Session Handoff Notes](#10-session-handoff-notes)

---

## 1. System Overview

### What is TickPhysics?
TickPhysics is an institutional-grade trading framework that applies physics concepts to price movement analysis:
- **Speed**: Rate of price change
- **Acceleration**: Rate of speed change  
- **Momentum**: Mass-weighted velocity
- **Jerk**: Rate of acceleration change
- **Confluence**: Alignment of multiple physics metrics

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    MT5 Platform                             │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │  TP Indicators   │───▶│  TP_Integrated_EA_Crossover  │  │
│  │  (v3.0)          │    │  (v5.0.0.5)                  │  │
│  └──────────────────┘    └──────────────────────────────┘  │
│           │                          │                      │
│           ▼                          ▼                      │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │  Physics Buffers │    │  CSV Trade Logger            │  │
│  └──────────────────┘    └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                CSV Processing Pipeline                       │
│  analytics/csv_processing/                                  │
│  ├── csvProcessor.ts (main processor)                       │
│  ├── timeSegmentCalculator.ts (MT5→CST conversion)          │
│  └── types.ts (ProcessedTrade interface)                    │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                Optimization Dashboard                        │
│  web/src/components/                                        │
│  ├── OptimizationEngine.tsx (filter tuning + MQL5 output)   │
│  ├── Dashboard.tsx (main view)                              │
│  └── PassComparison.tsx (multi-run analysis)                │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. EA Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| **5.0.0.5** | 2025-11-28 | Time segment filters (CST-based), Ceiling (Max) anti-spike filters |
| 5.0.0.4 | 2025-11-27 | TP Analysis optimized filter values applied |
| 5.0.0.3 | 2025-11-26 | Baseline with slope filters, physics score |
| 4.2.0.6 | 2025-11-25 | Manual confluence history tracking for slope calc |
| 4.1.6 | 2025-11-20 | Spread filter implementation |
| 4.0 | 2025-11-15 | Physics filters as entry system, dashboard |

### v5.0.0.5 Changelog (Current)
```
- Added CST-based time segment filters matching CSV data model
- Day of Week filter (UseDayFilter, AllowSunday...AllowSaturday)  
- 15M/30M/1H/2H/3H/4H segment range filters (Segment*_Min/Max)
- Added ceiling (Max) filters for all physics metrics (anti-spike protection)
- New functions: CalculateCSTSegments(), CheckTimeSegmentFilters()
- Time segments use MT5 broker time - 8 hours = CST
```

---

## 3. Current EA Inputs Reference

### 3.1 EA Identification
```mql5
input int MagicNumber = 500005;                    // EA magic number
input string TradeComment = "TP_Integrated 5_0_0_5"; // Trade comment
```

### 3.2 Risk Management
```mql5
input double RiskPercentPerTrade = 1.0;            // Risk per trade (% of balance)
input double MaxDailyRisk = 90.0;                  // Max daily risk (% of balance)
input int MaxConcurrentTrades = 10;                // Max concurrent positions
```

### 3.3 Trade Parameters (Asset-Adaptive)
```mql5
input bool UseAssetAdaptiveSLTP = true;            // Enable asset-specific SL/TP
input double RiskRewardRatio = 1.0;                // TP:SL ratio
input int StopLossPips_Forex = 8;                  // SL Forex (pips)
input int StopLossPips_Indices = 1000;             // SL Indices (pips)
input int StopLossPips_Crypto = 5000;              // SL Crypto (pips)
input int StopLossPips_Metal = 400;                // SL Metals (pips)
```

### 3.4 Physics Filters (v4.0)
```mql5
input bool UsePhysicsFilters = true;               // Enable physics filtering
input double MinQualityBuy = 60.0;                 // Min quality for BUY
input double MinQualitySell = 60.0;                // Min quality for SELL
input bool AvoidTransitionZone = true;             // Reject TRANSITION/AVOID zones
input bool UseRegimeFilter = true;                 // Filter by volatility regime
```

### 3.5 Advanced Physics Entry Filters (Floor + Ceiling)
```mql5
// Acceleration
input bool UseAccelerationFilter = true;
input double MinAccelerationBuy = 1.0;             // Floor (min)
input double MaxAccelerationBuy = 99999.0;         // Ceiling (max, anti-spike)
input double MinAccelerationSell = -1.0;           // Floor (negative)
input double MaxAccelerationSell = -99999.0;       // Ceiling (negative)

// Speed  
input bool UseSpeedFilter = true;
input double MinSpeedBuy = 1.0;
input double MaxSpeedBuy = 99999.0;
input double MinSpeedSell = -1.0;
input double MaxSpeedSell = -99999.0;

// Momentum
input bool UseMomentumFilter = true;
input double MinMomentumBuy = 1.0;
input double MaxMomentumBuy = 99999.0;
input double MinMomentumSell = -1.0;
input double MaxMomentumSell = -99999.0;
```

### 3.6 Slope Filters (v4.5) - All have Floor + Ceiling
```mql5
input bool UseSlopeFilters = true;
input int SlopeLookbackBars = 3;                   // Bars for slope calculation

// Speed Slope
input bool UseSpeedSlope = true;
input double MinSpeedSlopeBuy = 1.0;
input double MaxSpeedSlopeBuy = 99999.0;
input double MinSpeedSlopeSell = -1.0;
input double MaxSpeedSlopeSell = -99999.0;

// Acceleration Slope, Momentum Slope, Confluence Slope, Jerk Slope...
// (same pattern for each)
```

### 3.7 Time Segment Filters (v5.0.0.5) - NEW
```mql5
// Day of Week Filter (IN_CST_Day_OP_01)
input bool UseDayFilter = false;                   // Enable day-of-week filtering
input bool AllowSunday = true;                     // Trade on Sunday (0)
input bool AllowMonday = true;                     // Trade on Monday (1)
input bool AllowTuesday = true;                    // Trade on Tuesday (2)
input bool AllowWednesday = true;                  // Trade on Wednesday (3)
input bool AllowThursday = true;                   // Trade on Thursday (4)
input bool AllowFriday = true;                     // Trade on Friday (5)
input bool AllowSaturday = true;                   // Trade on Saturday (6)

// 15-Min Segment Filter (IN_Segment_15M_OP_01: 15-001 to 15-096)
input bool UseSegment15M = false;
input int Segment15M_Min = 1;                      // Min segment (1-96)
input int Segment15M_Max = 96;                     // Max segment (1-96)

// 30-Min Segment Filter (IN_Segment_30M_OP_01: 30-001 to 30-048)
input bool UseSegment30M = false;
input int Segment30M_Min = 1;
input int Segment30M_Max = 48;

// 1-Hour Segment Filter (IN_Segment_01H_OP_01: 1h-001 to 1h-024)
input bool UseSegment01H = false;
input int Segment01H_Min = 1;
input int Segment01H_Max = 24;

// 2-Hour Segment Filter (IN_Segment_02H_OP_01: 2h-001 to 2h-012)
input bool UseSegment02H = false;
input int Segment02H_Min = 1;
input int Segment02H_Max = 12;

// 3-Hour Segment Filter (IN_Segment_03H_OP_01: 3h-001 to 3h-008)
input bool UseSegment03H = false;
input int Segment03H_Min = 1;
input int Segment03H_Max = 8;

// 4-Hour Segment Filter (IN_Segment_04H_OP_01: 4h-001 to 4h-006)
input bool UseSegment04H = false;
input int Segment04H_Min = 1;
input int Segment04H_Max = 6;
```

#### Time Segment Calculation (CST = MT5 - 8 hours)
```
15M: hour * 4 + floor(minute / 15) + 1  → 1-96
30M: hour * 2 + floor(minute / 30) + 1  → 1-48
1H:  hour + 1                            → 1-24
2H:  floor(hour / 2) + 1                 → 1-12
3H:  floor(hour / 3) + 1                 → 1-8
4H:  floor(hour / 4) + 1                 → 1-6
```

---

## 4. Filter System Architecture

### 4.1 Filter Processing Order (in ProcessSignal)
```
1. Generate signal (physics crossover OR MA trend OR physics filters as entry)
2. Time Segment Filters ← NEW in v5.0.0.5
   - Day of week check
   - Segment range checks (15M, 30M, 1H, 2H, 3H, 4H)
3. Physics Filters (only if not using PhysicsFiltersAsEntry)
   - Quality floor check
   - Zone filter (avoid Transition/Avoid)
   - Acceleration floor + ceiling checks
   - Speed floor + ceiling checks
   - Momentum floor + ceiling checks
   - Physics Score threshold
   - Slope filters (Speed, Accel, Momentum, Confluence, Jerk)
4. Execute trade if all filters pass
```

### 4.2 Ceiling Filter Logic (Anti-Spike Protection)
```mql5
// BUY: Value must be >= Min AND <= Max
if(accel < MinAccelerationBuy || accel > MaxAccelerationBuy) {
   passFilters = false;
   rejectReason = "ACCEL_CEILING_FAIL";
}

// SELL: Value must be <= Min (negative) AND >= Max (more negative)
if(accel > MinAccelerationSell || accel < MaxAccelerationSell) {
   passFilters = false;
   rejectReason = "ACCEL_CEILING_FAIL";
}
```

### 4.3 Analysis Results (from outlier_ceiling_analysis.py)
```
Multi-Outlier Loss Analysis:
- 322 losses (10.2%) had 2+ metrics spiking above 99th percentile
- Total loss from these trades: $14,203 (20.6% of all losses)
- Recommendation: Set ceiling filters to avoid extreme spikes
```

### 4.4 Time Segment Analysis Results (from time_segment_analysis.py)
```
Best Filter Potential:
- 15-Min Segments: Avoid 39 worst → $14,630 savings (turns loss to +$2,535 profit!)
- 30-Min Segments: Avoid 20 worst → $12,399 savings
- 1-Hour Segments: Avoid 9 worst → $9,288 savings
- Day of Week: Avoid Friday+Tuesday → $5,704 savings

Key Finding: Sunday is ONLY profitable day. Wednesday BUY profitable, Wednesday SELL disaster.
```

---

## 5. Data Model & CSV Processing

### 5.1 Time Column Naming Convention
```
IN_CST_Day_OP_01      → Day name ("Sunday", "Monday", etc.)
IN_CST_Month_OP_01    → Month name
IN_Segment_15M_OP_01  → "15-001" to "15-096"
IN_Segment_30M_OP_01  → "30-001" to "30-048"
IN_Segment_01H_OP_01  → "1h-001" to "1h-024"
IN_Segment_02H_OP_01  → "2h-001" to "2h-012"
IN_Segment_03H_OP_01  → "3h-001" to "3h-008"
IN_Segment_04H_OP_01  → "4h-001" to "4h-006"
```

### 5.2 Physics Signal Columns
```
Signal_Entry_Quality        → Quality score at entry
Signal_Entry_Confluence     → Confluence percentage
Signal_Entry_Speed          → Speed value
Signal_Entry_Acceleration   → Acceleration value
Signal_Entry_Momentum       → Momentum value
Signal_Entry_Jerk           → Jerk value
Signal_Entry_PhysicsScore   → Weighted composite score
Signal_Entry_SpeedSlope     → Speed slope (regression)
Signal_Entry_AccelerationSlope
Signal_Entry_MomentumSlope
Signal_Entry_ConfluenceSlope
Signal_Entry_JerkSlope
Signal_Entry_Zone           → STRONG_BUY, MOMENTUM_BUY, etc.
Signal_Entry_Regime         → HIGH_VOL, LOW_VOL, etc.
```

### 5.3 Processed Trade JSON Structure
```json
{
  "meta": { "version": "5.0.0.5", "symbol": "NAS100", ... },
  "summary": { "totalTrades": 4744, "winRate": 33.5, ... },
  "trades": [
    {
      "Trade_ID": 12345,
      "Trade_Direction": "Long",
      "Trade_Result": "Win",
      "EA_Profit": 123.45,
      "IN_CST_Day_OP_01": "Wednesday",
      "IN_Segment_15M_OP_01": "15-045",
      "Signal_Entry_Speed": 5.23,
      ...
    }
  ]
}
```

---

## 6. Optimization Dashboard

### 6.1 Available Metrics for Filtering
```typescript
// Physics Metrics
Signal_Entry_Quality, Signal_Entry_Confluence, Signal_Entry_Momentum,
Signal_Entry_Speed, Signal_Entry_Acceleration, Signal_Entry_Jerk,
Signal_Entry_PhysicsScore, Signal_Entry_SpeedSlope, Signal_Entry_AccelerationSlope,
Signal_Entry_MomentumSlope, Signal_Entry_ConfluenceSlope, Signal_Entry_JerkSlope,
Signal_Entry_Zone, Signal_Entry_Regime, EA_Entry_Spread

// Time Segment Metrics (NEW in v5.0.0.5)
IN_CST_Day_OP_01 (categorical - checkbox selection)
IN_Segment_15M_OP_01 (numeric range 1-96)
IN_Segment_30M_OP_01 (numeric range 1-48)
IN_Segment_01H_OP_01 (numeric range 1-24)
IN_Segment_02H_OP_01 (numeric range 1-12)
IN_Segment_03H_OP_01 (numeric range 1-8)
IN_Segment_04H_OP_01 (numeric range 1-6)
```

### 6.2 MQL5 Code Generation
The optimizer generates EA input values:
```
// Physics filters
MinQualityBuy = 65.00
MinSpeedBuy = 2.50
MaxSpeedBuy = 150.00  // Ceiling

// Time segment filters
UseDayFilter = 1.00
AllowSunday = 1.00
AllowMonday = 1.00
AllowTuesday = 0.00   // Disabled
AllowFriday = 0.00    // Disabled

UseSegment15M = 1.00
Segment15M_Min = 25.00
Segment15M_Max = 75.00
```

---

## 7. Key Algorithms

### 7.1 CST Time Segment Calculation
```mql5
CSTTimeSegments CalculateCSTSegments()
{
   CSTTimeSegments seg;
   datetime mt5Time = TimeCurrent();
   datetime cstTime = mt5Time - (8 * 3600);  // MT5 - 8 hours
   
   MqlDateTime cstDt;
   TimeToStruct(cstTime, cstDt);
   
   seg.dayOfWeek = cstDt.day_of_week;
   seg.cstHour = cstDt.hour;
   seg.cstMinute = cstDt.min;
   
   seg.segment15M = seg.cstHour * 4 + (seg.cstMinute / 15) + 1;
   seg.segment30M = seg.cstHour * 2 + (seg.cstMinute / 30) + 1;
   seg.segment01H = seg.cstHour + 1;
   seg.segment02H = (seg.cstHour / 2) + 1;
   seg.segment03H = (seg.cstHour / 3) + 1;
   seg.segment04H = (seg.cstHour / 4) + 1;
   
   return seg;
}
```

### 7.2 Linear Regression Slope (Excel SLOPE equivalent)
```mql5
double CalculateRegressionSlope(int lookback, int metricType)
{
   // Uses CLOSED bars (1 to lookback) to avoid lookahead bias
   // X axis: 0 to lookback-1 (oldest to newest)
   // Returns slope in units/bar
}
```

### 7.3 Physics Score Calculation
```mql5
// Weighted composite of physics metrics
// Weights differ by timeframe (1H vs 5M)
// Speed is #1 universal predictor
```

---

## 8. File Locations

### EA Files
```
MQL5/Experts/TickPhysics/
├── TP_Integrated_EA_Crossover_5_0_0_5.mq5  ← CURRENT
├── TP_Integrated_EA_Crossover_5_0_0_4.mq5
├── TP_Integrated_EA_Crossover_5_0_0_3.mq5
└── ...
```

### Indicator Files
```
MQL5/Indicators/TickPhysics/
├── TickPhysics_Universal_Indicator_v3_0.mq5  ← RECOMMENDED
├── TickPhysics_Forex_Indicator_v3_0.mq5
├── TickPhysics_Indices_Indicator_v3_0.mq5
├── TickPhysics_Crypto_Indicator_v3_0.mq5
└── TickPhysics_Metals_Indicator_v3_0.mq5
```

### Include Files
```
MQL5/Include/TickPhysics/
├── TP_Physics_Indicator.mqh
├── TP_Risk_Manager.mqh
├── TP_Trade_Tracker.mqh
└── TP_CSV_Logger.mqh
```

### Analytics & Dashboard
```
analytics/
├── csv_processing/
│   ├── csvProcessor.ts
│   ├── timeSegmentCalculator.ts
│   └── types.ts
├── outlier_ceiling_analysis.py
└── time_segment_analysis.py

web/src/components/
├── OptimizationEngine.tsx
├── Dashboard.tsx
├── PassComparison.tsx
└── RunSelector.tsx

web/public/data/runs/
├── index.json
├── BL_IS.json
├── BL_OOS1-BL.json
├── BL_OOS2-BL.json
└── BL_OOS3-BL.json
```

---

## 9. Pending Improvements

### High Priority
- [ ] Run backtest with time segment filters enabled to validate savings
- [ ] Optimize ceiling filter values using analysis results
- [ ] Test direction-specific day filters (BUY only on Wed/Sun, SELL restrictions)

### Medium Priority
- [ ] Add session-based filters (News, Opening Bell, Floor Session, etc.)
- [ ] Implement adaptive ceiling filters based on recent volatility
- [ ] Add multi-symbol support to optimizer

### Low Priority
- [ ] Create visual heatmap for time segment performance
- [ ] Add Monte Carlo simulation for filter validation
- [ ] Implement walk-forward optimization framework

---

## 10. Session Handoff Notes

### Current State (2025-11-28)
- EA v5.0.0.5 compiled successfully with time segment + ceiling filters
- Web dashboard build successful, dev server works at localhost:5173
- All changes committed to git
- Analysis shows 15M segment filter could turn -$12k to +$2.5k profit

### Key Context for Next Session
1. **Time segments match CSV exactly** - Column names like `IN_Segment_15M_OP_01`
2. **CST = MT5 - 8 hours** - Broker time conversion for segment calculation
3. **Ceiling filters default to 99999** - Set to actual values after optimization
4. **Day filter shows Friday/Tuesday worst** - Consider disabling for first test

### Quick Start Commands
```bash
# Start dev server
cd /Volumes/Vortex_Trading/ai-trading-platform && pnpm dev

# Run time segment analysis
cd analytics && python3 time_segment_analysis.py

# Run ceiling filter analysis  
cd analytics && python3 outlier_ceiling_analysis.py
```

### Files to Review First
1. `MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_5_0_0_5.mq5`
2. `web/src/components/OptimizationEngine.tsx`
3. `analytics/time_segment_analysis.py`

---

*This document should be updated after each significant EA modification.*
*Last commit: `feat(EA): v5.0.0.5 with Time Segment Filters & Ceiling Filters`*
