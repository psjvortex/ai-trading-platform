# TickPhysics v3.1_05M Quick Start Guide

## 🎯 Version Overview
**v3.1_05M** applies Zone/Regime/Time filters based on v3.0_05M baseline analysis.

## 📊 v3.0_05M Baseline Results (What We're Fixing)
- **Total Trades:** 1,335
- **Win Rate:** 26.7%
- **Profit Factor:** 1.07
- **Net P&L:** +$24.74

### Problem Areas Identified:
1. **TRANSITION Zone:** 21.8% WR (147 trades) ❌
2. **LOW Regime:** 23.0% WR (122 trades) ❌
3. **Hours 6,7,13,14:** <20% WR avg (16.4%) ❌

## 🎯 v3.1_05M Optimizations Applied

### 1. Zone Filter
```
UseZoneFilter = true
```
- **Avoids:** TRANSITION zone (21.8% WR)
- **Keeps:** BULL (37.2% WR), AVOID (24.4% WR), BEAR (26.4% WR)
- **Impact:** Eliminates 147 trades (11.0%)

### 2. Regime Filter
```
UseRegimeFilter = true
```
- **Avoids:** LOW volatility regime (23.0% WR)
- **Keeps:** HIGH (30.0% WR), NORMAL (26.7% WR)
- **Impact:** Eliminates 122 trades (9.1%)

### 3. Time Filter (NEW in v3.1!)
```
UseTimeFilter = true
BlockedHours = "6,7,13,14"
```
- **Blocks:** Hours 6, 7, 13, 14 (avg 16.4% WR)
- **Why:** Hour 6 (11.1% WR), Hour 7 (19.2% WR), Hour 13 (18.5% WR), Hour 14 (16.9% WR)
- **Allows:** All other hours by default

### Combined Impact:
- **Eliminated:** ~269 trades from Zone + Regime filters (20.1%)
- **Expected Remaining:** ~1,066 trades (before time filter)
- **Time filter will further reduce** based on hour activity
- **Target:** Similar improvement as 15M (28% → 61.5% WR)

## 🚀 Setup Instructions

### 1. File Location
Copy EA to: `MT5/Experts/TickPhysics/TP_Integrated_EA_Crossover_3_1_05M.mq5`

### 2. Key Settings (Pre-configured)
```
MagicNumber = 300311  // v3.1 = 300311
EA_VERSION = "3.1_05M"

// Filters (ENABLED in v3.1)
UsePhysicsFilters = true
UseZoneFilter = true        // ✅ NEW - Avoid TRANSITION
UseRegimeFilter = true      // ✅ NEW - Avoid LOW
UseTimeFilter = true        // ✅ NEW - Block hours 6,7,13,14

// Baseline thresholds (unchanged from v3.0)
MinQuality = 70.0
MinConfluence = 70.0

// Entry system
UseMAEntry = true
MA_Fast = 10
MA_Slow = 50

// Risk management
RiskPercentPerTrade = 1.0
MaxConcurrentTrades = 1
StopLossPips = 0           // BASELINE: No SL/TP
TakeProfitPips = 0
```

### 3. Output Files
- **Trades:** `TP_Integrated_Trades_NAS100_v3.1_05M.csv`
- **Signals:** `TP_Integrated_Signals_NAS100_v3.1_05M.csv`
- **MT5 Report:** `MTBacktest_Report_3.1_05M.csv` (manual export)

## 📈 Expected Results

### Conservative Estimate:
- **Trades:** ~600-800 (vs 1,335 baseline)
- **Win Rate:** 35-45% (vs 26.7% baseline)
- **Profit Factor:** 1.5-2.0 (vs 1.07 baseline)
- **Net P&L:** Significantly positive

### Optimistic (15M-like improvement):
- **Trades:** ~50-150 (aggressive filtering)
- **Win Rate:** 50-65%
- **Profit Factor:** 2.0+
- **Net P&L:** Strong positive

## ⚙️ Advanced Customization

### Time Filter Options:

**Option A: Block only worst hours (default)**
```
UseTimeFilter = true
BlockedHours = "6,7,13,14"
AllowedHours = ""  // Empty = allow all except blocked
```

**Option B: Allow only best hours (aggressive)**
```
UseTimeFilter = true
BlockedHours = ""
AllowedHours = "16,18,19,20,22,23"  // Hours with 32%+ WR
```

**Option C: Disable time filter**
```
UseTimeFilter = false
```

### Zone/Regime Customization:

To test different combinations:
```
UseZoneFilter = false   // Test without zone filter
UseRegimeFilter = false // Test without regime filter
```

## 🔍 What to Monitor

### After backtest completion:
1. **Trade count reduction:** Should see 40-70% fewer trades
2. **Win rate improvement:** Should see +5-15% WR increase
3. **Profit factor:** Should exceed 1.5
4. **Net P&L:** Should be significantly positive

### Red flags:
- ❌ Win rate <30% → Filters may be too restrictive
- ❌ Profit factor <1.2 → May need physics threshold refinement (v3.2)
- ❌ <100 trades → May be over-optimized

## 📋 Next Steps After v3.1_05M Backtest

1. **Copy 3 CSV files** to workspace:
   - MTBacktest_Report_3.1_05M.csv
   - TP_Integrated_Trades_NAS100_v3.1_05M.csv
   - TP_Integrated_Signals_NAS100_v3.1_05M.csv

2. **Run comparison analysis:**
   - Compare v3.1_05M vs v3.0_05M baseline
   - Validate filter effectiveness
   - Identify if further optimization needed

3. **If successful → v3.2_05M:**
   - Analyze physics metrics (Quality, Confluence, Momentum)
   - Set MinMomentum threshold from winner analysis
   - Further refine Quality/Confluence thresholds
   - Target: 50-80% WR with ultra-selective entry

## 🎯 Success Criteria

**v3.1_05M is successful if:**
- ✅ Win rate improves by at least 5% (target: 32%+)
- ✅ Profit factor > 1.5
- ✅ Net P&L positive
- ✅ Trade reduction logical (not over-filtered)
- ✅ Maintains reasonable trade frequency (>100 trades)

**If successful:** Proceed to v3.2_05M physics refinement
**If marginal:** Adjust time filter or zone/regime combinations
**If unsuccessful:** Review baseline data or revert to v3.0_05M

## 📞 Support

For issues or questions, review:
1. Expert log for filter rejection reasons
2. Signals CSV for physics metrics distribution
3. Compare Zone/Regime/Hour distributions vs v3.0_05M

---
**Version:** v3.1_05M  
**Date:** November 8, 2025  
**Based on:** v3.0_05M baseline analysis (1,335 trades, 26.7% WR)
