# AI Trading Platform - Context for Claude

## Project Overview
AI-powered trading platform featuring a custom MQL5 Expert Advisor (EA) called **TickPhysics** that uses physics-based indicators (Speed, Acceleration, Momentum) to identify high-quality trade entries.

## Current Status (November 26, 2025)

### v5.0.0.0 - MASTER RELEASE (Granular Inputs)
**Status**: Production Ready / Master Version

#### Key Features:
- **Granular Buy/Sell Inputs**: All major physics filters now have separate thresholds for Buy and Sell directions.
  - `MinQualityBuy` / `MinQualitySell`
  - `MinPhysicsScoreBuy` / `MinPhysicsScoreSell`
  - `MinConfluenceSlopeBuy` / `MinConfluenceSlopeSell`
- **Dashboard Integration**: Web Dashboard Generator fully synchronized to produce v5.0.0.0 compatible code.
- **Data Integrity**: Inherits all data integrity fixes from v4.2.0.6.

### Phase 2 Optimization Complete (NAS100)
**v4.1.8.1 - OPTIMIZED THRESHOLDS**

#### NAS100 Results:
- **Phase 1 Baseline** (v4.1.8.0): 1,009 trades @ 59.6% WR, $69.19 profit, $0.07 expectancy
- **Phase 2 Optimized** (v4.1.8.1): 635 trades @ 52.4% WR, $79.39 profit, $0.13 expectancy
- **Improvement**: +$10.20 (+14.7%), +$0.06 expectancy (+86%), 9.4x better avg win

#### Optimization Method:
1. Signal-to-trade correlation analysis (100% match rate on 1,009 trades)
2. Winner vs loser physics comparison
3. Used median of losers as conservative threshold
4. Resulted in 10-100x stricter thresholds targeting high-momentum setups

#### Optimized Thresholds:
```cpp
MinSpeedBuy         = 4031.0;   // was 55.0 (73x stricter)
MinSpeedSell        = -3797.0;  // was -55.0 (69x stricter)
MinAccelerationBuy  = 1170.7;   // was 80.0 (15x stricter)
MinAccelerationSell = -1534.1;  // was -80.0 (19x stricter)
MinMomentumBuy      = 214.8;    // was 30.0 (7x stricter)
MinMomentumSell     = -215.5;   // was -30.0 (7x stricter)
```

### In Progress: Multi-Symbol Validation

#### US30 Phase 1 Baseline (Completed):
- 773 trades @ 43.2% WR, $-328.33 loss, $-0.42 expectancy
- Shows negative expectancy with relaxed filters (unlike NAS100)
- **Next**: Run Phase 2 with optimized thresholds (expecting positive results)

#### Pending:
- US30 Phase 2 test (v4.1.8.1)
- GER40 Phase 1 baseline (v4.1.8.0)
- GER40 Phase 2 test (v4.1.8.1)
- Multi-symbol validation report

## Key Files

### MQL5 Expert Advisors
- **`MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_5_0_0_0.mq5`**: **MASTER VERSION** (Granular Buy/Sell Inputs)
- **`MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_4_2_1_2.mq5`**: Previous stable (Granular Inputs backported)
- **`MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_4_1_8_1.mq5`**: Phase 2 optimized (Legacy)

### Python Analysis Scripts
- **`MQL5/General/v418_signal_correlation.py`**: Signal-to-trade matching, threshold optimization
- **`MQL5/General/phase1_vs_phase2_comparison.py`**: Side-by-side performance comparison
- **`MQL5/General/us30_phase1_analysis.py`**: US30 baseline analysis
- **`MQL5/General/quick_validate.py`**: EA CSV vs MT5 report validation

### Include Files (Core Logic)
- **`MQL5/Include/TickPhysics/TP_Physics_Indicator.mqh`**: Physics calculations
- **`MQL5/Include/TickPhysics/TP_CSV_Logger.mqh`**: Signal and trade logging
- **`MQL5/Include/TickPhysics/TP_Trade_Tracker.mqh`**: Trade state management
- **`MQL5/Include/TickPhysics/TP_Risk_Manager.mqh`**: Position sizing and risk

### Documentation
- **`infra/TickFizzy Reference/TickPhysics_Complete_FRD_v6_0.md`**: Functional requirements
- **`docs/STATUS.md`**: Development status tracking
- **`CONTEXT_PROMPT_FOR_CLAUDE.md`**: Original project context

## Recent Major Changes

### SELL Threshold Logic Fix (v4.1.8.0)
**Problem**: SELL thresholds used positive values with `MathAbs()` comparison, causing confusion in CSV analysis.

**Solution**:
- Changed SELL input parameters to negative values (`MinSpeedSell = -55.0`)
- Removed `MathAbs()` calls in SELL entry logic
- Direct comparison: `speed < MinSpeedSell` (e.g., -60 < -55 = PASS)
- Fixed 6 locations in main EA + 3 in Isolated Testing Mode

**Impact**: Clear CSV analysis, symmetric BUY/SELL logic, intuitive threshold interpretation

## Technical Architecture

### Physics-Based Entry System
1. **Speed**: Rate of price change (points/bar)
2. **Acceleration**: Rate of speed change (change in momentum)
3. **Momentum**: Cumulative directional force

### Entry Logic Flow
1. Crossover signal (Fast MA crosses Slow MA)
2. Physics filters (Speed, Accel, Momentum must exceed thresholds)
3. Quality filters (MinPhysicsScore, MinQuality)
4. Risk filters (MaxSpreadPips, position sizing)
5. Time filters (session windows)

### CSV Output Structure
- **signals.csv**: All generated signals with physics metrics
- **trades.csv**: Executed trades with entry/exit details
- **MT5Backtest.csv**: MT5 native report for validation

## Validation Methodology

### Phase 1 (Baseline):
- Relaxed thresholds to generate statistically significant sample (500-1000 trades)
- Purpose: Collect data for optimization

### Phase 2 (Optimized):
- Data-driven thresholds from correlation analysis
- Filter for high-momentum setups only
- Quality over quantity approach

### Multi-Symbol Validation:
- Test on NAS100, US30, GER40 (different market hours/volatility)
- Validate thresholds are universal, not symbol-specific overfitting
- Decision criteria: All symbols should show +10-15% profit improvement

## Performance Metrics

### Key Indicators:
- **Win Rate**: % of profitable trades (target: 40%+ for 2:1 R:R)
- **Expectancy**: Average profit per trade (primary metric)
- **Avg Win**: Average profit on winning trades
- **Avg Loss**: Average loss on losing trades
- **Execution Rate**: % of signals that become trades

### Success Criteria:
- Positive expectancy (> $0 per trade)
- Win rate ≥ 40% (for 2:1 reward/risk)
- Avg win > Avg loss (preferably 2:1+)
- Consistent performance across multiple symbols

## How to Use This Context

### For Development Questions:
1. Check relevant EA version (v4.1.8.0 for baseline, v4.1.8.1 for optimized)
2. Review include files for core logic
3. Run analysis scripts on backtest CSVs for insights

### For Performance Analysis:
1. Use `quick_validate.py` to validate EA CSV vs MT5 report
2. Use `phase1_vs_phase2_comparison.py` for version comparison
3. Check expectancy as primary metric (not just win rate)

### For Optimization:
1. Phase 1: Relax filters to collect data
2. Run `v418_signal_correlation.py` to find optimal thresholds
3. Phase 2: Apply optimized thresholds and validate improvement

## Next Steps

1. ✅ NAS100 optimization validated (+$10.20 profit, +86% expectancy)
2. 🔄 US30 Phase 2 test (pending - expecting positive results from negative baseline)
3. ⏳ GER40 Phase 1 & Phase 2 tests
4. ⏳ Multi-symbol validation report
5. ⏳ Production deployment decision

## Questions or Issues?

Contact: patjohnston (project owner)

Last Updated: November 14, 2025
