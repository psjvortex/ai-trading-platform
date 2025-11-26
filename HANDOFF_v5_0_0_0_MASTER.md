# v5.0.0.0 Master Release Handoff

**Date**: November 26, 2025
**Version**: 5.0.0.0
**Status**: MASTER / PRODUCTION

## Overview
Version 5.0.0.0 represents a major architectural shift in the EA's input parameter structure. It introduces granular control over Buy and Sell thresholds for all key physics metrics, allowing for independent optimization of Long and Short strategies.

## Key Features

### 1. Granular Buy/Sell Inputs
All global thresholds have been split into directional pairs:
- `MinQuality` → `MinQualityBuy` / `MinQualitySell`
- `MinPhysicsScore` → `MinPhysicsScoreBuy` / `MinPhysicsScoreSell`
- `MinConfluenceSlope` → `MinConfluenceSlopeBuy` / `MinConfluenceSlopeSell`

### 2. Logic Updates
- **Entry Logic**: Validates signals against the specific directional threshold (e.g., Buy signals check `MinQualityBuy`).
- **Dashboard**: Visualizes Pass/Fail status based on the current trend direction.
- **Logging**: Records the specific threshold used for rejection/acceptance.

### 3. Web Dashboard Integration
- The React-based Dashboard Generator has been updated to produce code compatible with v5.0.0.0.
- Optimization Engine now supports independent Long/Short parameter tuning.

## File Locations
- **Master EA**: `MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_5_0_0_0.mq5`
- **Previous Stable**: `MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_4_2_1_2.mq5`

## Migration Notes
- **Set files**: Old `.set` files will need to be updated. `MinQuality` will no longer be recognized; you must specify `MinQualityBuy` and `MinQualitySell`.
- **Optimization**: When running optimizations, ensure you select both Buy and Sell parameters if you want them to move together, or optimize them independently for asymmetric strategies.

## Validation
- [x] Code compiles without errors.
- [x] Granular inputs are visible in MT5 Strategy Tester.
- [x] Dashboard correctly displays directional Pass/Fail status.
