#!/usr/bin/env python3
"""
v3.1_05M Optimization Analysis
===============================
Analyzes Zone/Regime/Time filter effectiveness and calculates optimal SL/TP
from MFE/MAE and RunUp/RunDown data for v3.2_05M
"""
import pandas as pd
import numpy as np

print("\n" + "="*80)
print("  🎯 v3.1_05M OPTIMIZATION ANALYSIS")
print("  Zone/Regime/Time Filter Effectiveness + SL/TP Optimization")
print("="*80 + "\n")

# Load v3.0 baseline and v3.1 optimized data
print("📁 Loading data...")
trades_v30 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0_05M.csv')
trades_v31 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1_05M.csv')

print(f"   v3.0 baseline: {len(trades_v30):,} trades")
print(f"   v3.1 optimized: {len(trades_v31):,} trades\n")

# ===================================================================
# SECTION 1: FILTER EFFECTIVENESS
# ===================================================================
print("="*80)
print("  📊 FILTER EFFECTIVENESS ANALYSIS")
print("="*80 + "\n")

# v3.0 metrics
v30_winners = len(trades_v30[trades_v30['Profit'] > 0])
v30_wr = (v30_winners / len(trades_v30) * 100) if len(trades_v30) > 0 else 0
v30_gp = trades_v30[trades_v30['Profit'] > 0]['Profit'].sum()
v30_gl = abs(trades_v30[trades_v30['Profit'] < 0]['Profit'].sum())
v30_pf = (v30_gp / v30_gl) if v30_gl > 0 else 0
v30_net = trades_v30['Profit'].sum()

# v3.1 metrics
v31_winners = len(trades_v31[trades_v31['Profit'] > 0])
v31_wr = (v31_winners / len(trades_v31) * 100) if len(trades_v31) > 0 else 0
v31_gp = trades_v31[trades_v31['Profit'] > 0]['Profit'].sum()
v31_gl = abs(trades_v31[trades_v31['Profit'] < 0]['Profit'].sum())
v31_pf = (v31_gp / v31_gl) if v31_gl > 0 else 0
v31_net = trades_v31['Profit'].sum()

# Trade reduction
trade_reduction_pct = ((len(trades_v30) - len(trades_v31)) / len(trades_v30) * 100)
wr_improvement = v31_wr - v30_wr
pf_improvement = v31_pf - v30_pf
net_improvement = v31_net - v30_net

print("v3.0 BASELINE (No Filters):")
print(f"   Trades:        {len(trades_v30):,}")
print(f"   Win Rate:      {v30_wr:.1f}%")
print(f"   Profit Factor: {v30_pf:.2f}")
print(f"   Net P&L:       ${v30_net:.2f}")
print()
print("v3.1 OPTIMIZED (Zone/Regime/Time Filters):")
print(f"   Trades:        {len(trades_v31):,}")
print(f"   Win Rate:      {v31_wr:.1f}%")
print(f"   Profit Factor: {v31_pf:.2f}")
print(f"   Net P&L:       ${v31_net:.2f}")
print()
print("IMPROVEMENT:")
print(f"   Trade Reduction: {trade_reduction_pct:.1f}% ({len(trades_v30) - len(trades_v31)} trades eliminated)")
print(f"   Win Rate:        {wr_improvement:+.1f}% ({v30_wr:.1f}% → {v31_wr:.1f}%)")
print(f"   Profit Factor:   {pf_improvement:+.2f} ({v30_pf:.2f} → {v31_pf:.2f})")
print(f"   Net P&L:         ${net_improvement:+.2f} (${v30_net:.2f} → ${v31_net:.2f})")

# Success criteria
print()
if wr_improvement >= 5:
    print("   ✅ Win rate improved by ≥5% - EXCELLENT!")
else:
    print(f"   ⚠️  Win rate improved by {wr_improvement:.1f}% - Target: ≥5%")

if v31_pf >= 1.5:
    print("   ✅ Profit factor ≥1.5 - EXCELLENT!")
else:
    print(f"   ⚠️  Profit factor {v31_pf:.2f} - Target: ≥1.5")

if v31_net > 0:
    print("   ✅ Net P&L positive - EXCELLENT!")
else:
    print("   ⚠️  Net P&L negative - needs improvement")

# ===================================================================
# SECTION 2: OPTIMAL SL/TP CALCULATION (User wants TIGHTER TP)
# ===================================================================
print("\n" + "="*80)
print("  💰 OPTIMAL SL/TP CALCULATION (MFE/MAE Analysis)")
print("  User Preference: TIGHTER TP for win frequency over max runs")
print("="*80 + "\n")

# Analyze v3.1 winners and losers
winners_v31 = trades_v31[trades_v31['Profit'] > 0].copy()
losers_v31 = trades_v31[trades_v31['Profit'] <= 0].copy()

print(f"Analyzing {len(winners_v31)} winners and {len(losers_v31)} losers from v3.1...\n")

# MFE Analysis (Max Favorable Excursion) - for TP
if len(winners_v31) > 0:
    mfe_pips = winners_v31['MFE_Pips'].dropna()
    
    if len(mfe_pips) > 0:
        mfe_mean = mfe_pips.mean()
        mfe_median = mfe_pips.median()
        mfe_75th = mfe_pips.quantile(0.75)
        mfe_90th = mfe_pips.quantile(0.90)
        mfe_max = mfe_pips.max()
        
        print("📈 WINNER MFE ANALYSIS (for Take Profit):")
        print(f"   Mean MFE:      {mfe_mean:.1f} pips")
        print(f"   Median (50th): {mfe_median:.1f} pips")
        print(f"   75th %ile:     {mfe_75th:.1f} pips  ⭐ RECOMMENDED (tighter TP)")
        print(f"   90th %ile:     {mfe_90th:.1f} pips  (balanced)")
        print(f"   Max MFE:       {mfe_max:.1f} pips  (too aggressive)")
        print()
        print("   💡 RECOMMENDATION: Use 75th percentile for TIGHTER TP")
        print(f"   → Captures 75% of winner's best moves")
        print(f"   → Favors frequency of wins over catching longest runs")
        recommended_tp = mfe_75th
        print(f"   → Take Profit: {recommended_tp:.0f} pips")
    else:
        print("   ⚠️  No MFE data available for winners")
        recommended_tp = 50  # Default fallback
else:
    print("   ⚠️  No winners in v3.1 to analyze")
    recommended_tp = 50

print()

# MAE Analysis (Max Adverse Excursion) - for SL
if len(losers_v31) > 0:
    mae_pips = losers_v31['MAE_Pips'].dropna().abs()  # Absolute value for easier reading
    
    if len(mae_pips) > 0:
        mae_mean = mae_pips.mean()
        mae_median = mae_pips.median()
        mae_75th = mae_pips.quantile(0.75)
        mae_90th = mae_pips.quantile(0.90)
        mae_max = mae_pips.max()
        
        print("📉 LOSER MAE ANALYSIS (for Stop Loss):")
        print(f"   Mean MAE:      {mae_mean:.1f} pips")
        print(f"   Median (50th): {mae_median:.1f} pips")
        print(f"   75th %ile:     {mae_75th:.1f} pips  ⭐ RECOMMENDED")
        print(f"   90th %ile:     {mae_90th:.1f} pips  (looser)")
        print(f"   Max MAE:       {mae_max:.1f} pips  (too loose)")
        print()
        print("   💡 RECOMMENDATION: Use 75th percentile + buffer")
        print(f"   → Protects against 75% of loser's worst moves")
        print(f"   → Allows some breathing room for winning trades")
        
        # Add 10% buffer to account for volatility
        buffer = mae_75th * 0.10
        recommended_sl = mae_75th + buffer
        print(f"   → Stop Loss: {recommended_sl:.0f} pips (75th %ile + 10% buffer)")
    else:
        print("   ⚠️  No MAE data available for losers")
        recommended_sl = 40  # Default fallback
else:
    print("   ⚠️  No losers in v3.1 to analyze")
    recommended_sl = 40

print()

# Calculate R:R ratio
rr_ratio = recommended_tp / recommended_sl if recommended_sl > 0 else 0

print("="*80)
print("  🎯 OPTIMAL SL/TP RECOMMENDATION FOR v3.2_05M")
print("="*80)
print()
print(f"   Stop Loss:     {recommended_sl:.0f} pips")
print(f"   Take Profit:   {recommended_tp:.0f} pips")
print(f"   R:R Ratio:     {rr_ratio:.2f}:1")
print()
print("   Strategy: TIGHTER TP for win frequency")
print(f"   → TP captures 75% of winner MFE distribution")
print(f"   → SL protects against 75% of loser MAE + 10% buffer")
print()

if rr_ratio >= 2.0:
    print("   ✅ Excellent R:R ratio (≥2:1)")
elif rr_ratio >= 1.5:
    print("   ✅ Good R:R ratio (≥1.5:1)")
elif rr_ratio >= 1.0:
    print("   ⚠️  Marginal R:R ratio (need higher TP or tighter SL)")
else:
    print("   ❌ Poor R:R ratio (<1:1)")

# ===================================================================
# SECTION 3: PHYSICS METRICS FOR v3.2
# ===================================================================
print("\n" + "="*80)
print("  🔬 PHYSICS METRICS ANALYSIS FOR v3.2_05M")
print("="*80 + "\n")

print(f"Analyzing physics metrics from {len(winners_v31)} v3.1 winners...\n")

# Quality analysis
if 'EntryQuality' in winners_v31.columns:
    quality_25th = winners_v31['EntryQuality'].quantile(0.25)
    quality_median = winners_v31['EntryQuality'].median()
    quality_75th = winners_v31['EntryQuality'].quantile(0.75)
    
    print(f"📊 QUALITY DISTRIBUTION (Winners):")
    print(f"   25th %ile: {quality_25th:.1f}")
    print(f"   Median:    {quality_median:.1f}")
    print(f"   75th %ile: {quality_75th:.1f}")
    print(f"   → Recommended MinQuality: {quality_25th:.1f} (25th %ile)")
    print()

# Confluence analysis
if 'EntryConfluence' in winners_v31.columns:
    confluence_25th = winners_v31['EntryConfluence'].quantile(0.25)
    confluence_median = winners_v31['EntryConfluence'].median()
    confluence_75th = winners_v31['EntryConfluence'].quantile(0.75)
    
    print(f"📊 CONFLUENCE DISTRIBUTION (Winners):")
    print(f"   25th %ile: {confluence_25th:.1f}")
    print(f"   Median:    {confluence_median:.1f}")
    print(f"   75th %ile: {confluence_75th:.1f}")
    print(f"   → Recommended MinConfluence: {confluence_25th:.1f} (25th %ile)")
    print()

# Momentum analysis (KEY SEPARATOR!)
if 'EntryMomentum' in winners_v31.columns and 'EntryMomentum' in losers_v31.columns:
    winner_momentum = winners_v31['EntryMomentum'].mean()
    loser_momentum = losers_v31['EntryMomentum'].mean()
    momentum_separation = winner_momentum - loser_momentum
    
    momentum_25th = winners_v31['EntryMomentum'].quantile(0.25)
    momentum_median = winners_v31['EntryMomentum'].median()
    
    print(f"🚀 MOMENTUM ANALYSIS (Critical Separator!):")
    print(f"   Winner Avg:    {winner_momentum:.2f}")
    print(f"   Loser Avg:     {loser_momentum:.2f}")
    print(f"   Separation:    {momentum_separation:.2f}  {'✅ STRONG' if abs(momentum_separation) > 40 else '⚠️  WEAK'}")
    print()
    print(f"   Winners 25th %ile: {momentum_25th:.2f}")
    print(f"   Winners Median:    {momentum_median:.2f}")
    print(f"   → Recommended MinMomentum: {momentum_25th:.2f} (25th %ile)")
    print()

# ===================================================================
# SECTION 4: v3.2_05M CONFIGURATION PREVIEW
# ===================================================================
print("="*80)
print("  🎯 v3.2_05M CONFIGURATION PREVIEW")
print("="*80)
print()
print("Based on v3.1 analysis, v3.2_05M should use:")
print()
print("FILTERS (Keep from v3.1):")
print("   UseZoneFilter = true        // Avoid TRANSITION")
print("   UseRegimeFilter = true      // Avoid LOW")
print("   UseTimeFilter = true        // Block hours 6,7,13,14")
print()
print("PHYSICS THRESHOLDS (New for v3.2):")
if 'EntryQuality' in winners_v31.columns:
    print(f"   MinQuality = {quality_25th:.1f}        // 25th %ile of winners")
if 'EntryConfluence' in winners_v31.columns:
    print(f"   MinConfluence = {confluence_25th:.1f}  // 25th %ile of winners")
if 'EntryMomentum' in winners_v31.columns:
    print(f"   MinMomentum = {momentum_25th:.2f}      // 25th %ile of winners (KEY!)")
print()
print("SL/TP SETTINGS (Based on MFE/MAE):")
print(f"   StopLossPips = {int(recommended_sl)}      // 75th %ile MAE + 10% buffer")
print(f"   TakeProfitPips = {int(recommended_tp)}    // 75th %ile MFE (tighter for frequency)")
print(f"   R:R Ratio: {rr_ratio:.2f}:1")
print()
print("EXPECTED RESULTS:")
print(f"   Further trade reduction from v3.1 ({len(trades_v31)} → ~{int(len(trades_v31) * 0.3)}-{int(len(trades_v31) * 0.5)})")
print(f"   Win rate improvement (target: 50-70%)")
print(f"   Profit factor >2.0")
print(f"   Consistent profitability with tighter TP")

print("\n" + "="*80)
print("  ✅ ANALYSIS COMPLETE - READY FOR v3.2_05M CREATION")
print("="*80 + "\n")
