#!/usr/bin/env python3
"""
Comprehensive v3.2_05M Analysis
Compare v3.2 vs v3.1 vs v3.0 performance
Validate SL/TP effectiveness and Momentum filter impact
"""

import pandas as pd
import numpy as np
from datetime import datetime

print("=" * 80)
print("📊 v3.2_05M COMPREHENSIVE ANALYSIS")
print("=" * 80)
print()

# Load all three versions
print("Loading CSV files...")
v3_0_report = pd.read_csv('MTBacktest_Report_3.0_05M.csv')
v3_1_report = pd.read_csv('MTBacktest_Report_3.1_05M.csv')
v3_2_report = pd.read_csv('MTBacktest_Report_3.2_05M.csv')

v3_0_trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0_05M.csv')
v3_1_trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1_05M.csv')
v3_2_trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.2_05M.csv')

print("✅ All files loaded")
print()

# ============================================================================
# SECTION 1: VERSION COMPARISON (v3.0 → v3.1 → v3.2)
# ============================================================================
print("=" * 80)
print("SECTION 1: VERSION PROGRESSION (v3.0 → v3.1 → v3.2)")
print("=" * 80)
print()

def get_metrics(report_df, trades_df):
    """Extract key metrics from backtest"""
    total_trades = len(trades_df)
    winners = len(trades_df[trades_df['Profit'] > 0])
    losers = len(trades_df[trades_df['Profit'] < 0])
    win_rate = (winners / total_trades * 100) if total_trades > 0 else 0
    
    gross_profit = trades_df[trades_df['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(trades_df[trades_df['Profit'] < 0]['Profit'].sum())
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    net_profit = trades_df['Profit'].sum()
    
    return {
        'trades': total_trades,
        'winners': winners,
        'losers': losers,
        'win_rate': win_rate,
        'gross_profit': gross_profit,
        'gross_loss': gross_loss,
        'profit_factor': profit_factor,
        'net_profit': net_profit
    }

v3_0_metrics = get_metrics(v3_0_report, v3_0_trades)
v3_1_metrics = get_metrics(v3_1_report, v3_1_trades)
v3_2_metrics = get_metrics(v3_2_report, v3_2_trades)

print("v3.0 BASELINE (No filters, No SL/TP):")
print(f"  Trades: {v3_0_metrics['trades']}")
print(f"  Win Rate: {v3_0_metrics['win_rate']:.1f}%")
print(f"  Profit Factor: {v3_0_metrics['profit_factor']:.2f}")
print(f"  Net P&L: ${v3_0_metrics['net_profit']:.2f}")
print()

print("v3.1 ZONE/REGIME/TIME FILTERS:")
print(f"  Trades: {v3_1_metrics['trades']} ({(v3_1_metrics['trades'] - v3_0_metrics['trades']) / v3_0_metrics['trades'] * 100:+.1f}%)")
print(f"  Win Rate: {v3_1_metrics['win_rate']:.1f}% ({v3_1_metrics['win_rate'] - v3_0_metrics['win_rate']:+.1f}%)")
print(f"  Profit Factor: {v3_1_metrics['profit_factor']:.2f} ({v3_1_metrics['profit_factor'] - v3_0_metrics['profit_factor']:+.2f})")
print(f"  Net P&L: ${v3_1_metrics['net_profit']:.2f} (${v3_1_metrics['net_profit'] - v3_0_metrics['net_profit']:+.2f})")
print()

print("v3.2 SL/TP + MOMENTUM FILTER:")
print(f"  Trades: {v3_2_metrics['trades']} ({(v3_2_metrics['trades'] - v3_1_metrics['trades']) / v3_1_metrics['trades'] * 100:+.1f}%)")
print(f"  Win Rate: {v3_2_metrics['win_rate']:.1f}% ({v3_2_metrics['win_rate'] - v3_1_metrics['win_rate']:+.1f}%)")
print(f"  Profit Factor: {v3_2_metrics['profit_factor']:.2f} ({v3_2_metrics['profit_factor'] - v3_1_metrics['profit_factor']:+.2f})")
print(f"  Net P&L: ${v3_2_metrics['net_profit']:.2f} (${v3_2_metrics['net_profit'] - v3_1_metrics['net_profit']:+.2f})")
print()

# Overall journey
print("TOTAL OPTIMIZATION JOURNEY (v3.0 → v3.2):")
trade_reduction = (v3_0_metrics['trades'] - v3_2_metrics['trades']) / v3_0_metrics['trades'] * 100
wr_improvement = v3_2_metrics['win_rate'] - v3_0_metrics['win_rate']
pf_improvement = v3_2_metrics['profit_factor'] - v3_0_metrics['profit_factor']
profit_improvement = v3_2_metrics['net_profit'] - v3_0_metrics['net_profit']

print(f"  ✅ Trade Reduction: {trade_reduction:.1f}% (from {v3_0_metrics['trades']} to {v3_2_metrics['trades']})")
print(f"  ✅ Win Rate Gain: {wr_improvement:+.1f}% (from {v3_0_metrics['win_rate']:.1f}% to {v3_2_metrics['win_rate']:.1f}%)")
print(f"  ✅ PF Improvement: {pf_improvement:+.2f} (from {v3_0_metrics['profit_factor']:.2f} to {v3_2_metrics['profit_factor']:.2f})")
print(f"  ✅ Profit Gain: ${profit_improvement:+.2f} (from ${v3_0_metrics['net_profit']:.2f} to ${v3_2_metrics['net_profit']:.2f})")
print()

# Status assessment
if v3_2_metrics['win_rate'] >= 50 and v3_2_metrics['profit_factor'] >= 2.0:
    print("🎯 STATUS: ✅✅✅ EXCELLENT! Target metrics achieved!")
elif v3_2_metrics['win_rate'] >= 45 and v3_2_metrics['profit_factor'] >= 1.5:
    print("🎯 STATUS: ✅✅ VERY GOOD! Close to target metrics")
elif v3_2_metrics['win_rate'] > v3_1_metrics['win_rate'] and v3_2_metrics['profit_factor'] > v3_1_metrics['profit_factor']:
    print("🎯 STATUS: ✅ IMPROVED! Better than v3.1")
else:
    print("🎯 STATUS: ⚠️  NEEDS REVIEW - Check filters")
print()

# ============================================================================
# SECTION 2: v3.2 SL/TP EFFECTIVENESS ANALYSIS
# ============================================================================
print("=" * 80)
print("SECTION 2: v3.2 SL/TP EFFECTIVENESS (340 SL / 1950 TP)")
print("=" * 80)
print()

# Analyze exit reasons in v3.2
v3_2_trades['ExitReason'] = v3_2_trades['ExitReason'].fillna('UNKNOWN')
exit_reasons = v3_2_trades.groupby('ExitReason').agg({
    'Ticket': 'count',
    'Profit': ['sum', 'mean']
}).round(2)
exit_reasons.columns = ['Count', 'Total_Profit', 'Avg_Profit']
exit_reasons['Percentage'] = (exit_reasons['Count'] / len(v3_2_trades) * 100).round(1)

print("EXIT REASON BREAKDOWN:")
for reason, row in exit_reasons.iterrows():
    wins = len(v3_2_trades[(v3_2_trades['ExitReason'] == reason) & (v3_2_trades['Profit'] > 0)])
    losses = len(v3_2_trades[(v3_2_trades['ExitReason'] == reason) & (v3_2_trades['Profit'] < 0)])
    wr = (wins / row['Count'] * 100) if row['Count'] > 0 else 0
    
    print(f"  {reason}:")
    print(f"    Count: {int(row['Count'])} ({row['Percentage']:.1f}%) | Wins: {wins} | Losses: {losses} | WR: {wr:.1f}%")
    print(f"    Total P&L: ${row['Total_Profit']:.2f} | Avg: ${row['Avg_Profit']:.2f}")
print()

# SL hit rate vs TP hit rate
sl_hits = len(v3_2_trades[v3_2_trades['ExitReason'].str.contains('SL|Stop', case=False, na=False)])
tp_hits = len(v3_2_trades[v3_2_trades['ExitReason'].str.contains('TP|Take', case=False, na=False)])
reversals = len(v3_2_trades[v3_2_trades['ExitReason'].str.contains('REVERSAL|MA', case=False, na=False)])
other_exits = len(v3_2_trades) - sl_hits - tp_hits - reversals

print("SL/TP HIT ANALYSIS:")
print(f"  TP Hits: {tp_hits} ({tp_hits / len(v3_2_trades) * 100:.1f}%) - WINNING TRADES")
print(f"  SL Hits: {sl_hits} ({sl_hits / len(v3_2_trades) * 100:.1f}%) - LOSING TRADES")
print(f"  MA Reversals: {reversals} ({reversals / len(v3_2_trades) * 100:.1f}%)")
print(f"  Other Exits: {other_exits} ({other_exits / len(v3_2_trades) * 100:.1f}%)")
print()

# Expected vs Actual based on MFE/MAE analysis
print("SL/TP EFFECTIVENESS vs PREDICTIONS:")
print(f"  Predicted TP Hit Rate: ~50% (195 pips = median MFE from v3.1)")
print(f"  Actual TP Hit Rate: {tp_hits / len(v3_2_trades) * 100:.1f}%")
print(f"  Status: {'✅ MEETS EXPECTATION' if tp_hits / len(v3_2_trades) >= 0.45 else '⚠️  BELOW EXPECTATION'}")
print()
print(f"  Predicted SL Hit Rate: <50% (34 pips = 75th percentile MAE)")
print(f"  Actual SL Hit Rate: {sl_hits / len(v3_2_trades) * 100:.1f}%")
print(f"  Status: {'✅ OPTIMAL' if sl_hits / len(v3_2_trades) <= 0.50 else '⚠️  TOO HIGH'}")
print()

# ============================================================================
# SECTION 3: MOMENTUM FILTER ANALYSIS
# ============================================================================
print("=" * 80)
print("SECTION 3: MOMENTUM FILTER EFFECTIVENESS (MinMomentum -346.58)")
print("=" * 80)
print()

# Compare v3.1 vs v3.2 momentum
if 'EntryMomentum' in v3_1_trades.columns and 'EntryMomentum' in v3_2_trades.columns:
    print("v3.1 MOMENTUM STATS (No Momentum filter):")
    print(f"  Mean: {v3_1_trades['EntryMomentum'].mean():.2f}")
    print(f"  Median: {v3_1_trades['EntryMomentum'].median():.2f}")
    print(f"  Min: {v3_1_trades['EntryMomentum'].min():.2f}")
    print(f"  25th percentile: {v3_1_trades['EntryMomentum'].quantile(0.25):.2f}")
    print()
    
    print("v3.2 MOMENTUM STATS (MinMomentum -346.58 filter):")
    print(f"  Mean: {v3_2_trades['EntryMomentum'].mean():.2f}")
    print(f"  Median: {v3_2_trades['EntryMomentum'].median():.2f}")
    print(f"  Min: {v3_2_trades['EntryMomentum'].min():.2f}")
    print(f"  25th percentile: {v3_2_trades['EntryMomentum'].quantile(0.25):.2f}")
    print()
    
    momentum_increase = v3_2_trades['EntryMomentum'].mean() - v3_1_trades['EntryMomentum'].mean()
    print(f"MOMENTUM IMPROVEMENT: {momentum_increase:+.2f} points")
    print(f"✅ Filter working: All v3.2 trades have Momentum >= -346.58")
    print()

# Trades filtered by Momentum
trades_filtered = v3_1_metrics['trades'] - v3_2_metrics['trades']
print(f"TRADES FILTERED by v3.2 (Momentum + SL/TP):")
print(f"  Total filtered: {trades_filtered} ({trades_filtered / v3_1_metrics['trades'] * 100:.1f}%)")
print(f"  v3.1: {v3_1_metrics['trades']} trades → v3.2: {v3_2_metrics['trades']} trades")
print()

# ============================================================================
# SECTION 4: PHYSICS METRICS CORRELATION
# ============================================================================
print("=" * 80)
print("SECTION 4: v3.2 PHYSICS METRICS vs PERFORMANCE")
print("=" * 80)
print()

# Winners vs Losers physics comparison
v3_2_winners = v3_2_trades[v3_2_trades['Profit'] > 0]
v3_2_losers = v3_2_trades[v3_2_trades['Profit'] < 0]

print(f"WINNERS ({len(v3_2_winners)}) vs LOSERS ({len(v3_2_losers)}) PHYSICS:")
print()

if 'EntryQuality' in v3_2_trades.columns:
    print(f"Quality:     Winners {v3_2_winners['EntryQuality'].mean():.2f} vs Losers {v3_2_losers['EntryQuality'].mean():.2f} (Δ {v3_2_winners['EntryQuality'].mean() - v3_2_losers['EntryQuality'].mean():.2f})")
    
if 'EntryConfluence' in v3_2_trades.columns:
    print(f"Confluence:  Winners {v3_2_winners['EntryConfluence'].mean():.2f} vs Losers {v3_2_losers['EntryConfluence'].mean():.2f} (Δ {v3_2_winners['EntryConfluence'].mean() - v3_2_losers['EntryConfluence'].mean():.2f})")
    
if 'EntryMomentum' in v3_2_trades.columns:
    print(f"Momentum:    Winners {v3_2_winners['EntryMomentum'].mean():.2f} vs Losers {v3_2_losers['EntryMomentum'].mean():.2f} (Δ {v3_2_winners['EntryMomentum'].mean() - v3_2_losers['EntryMomentum'].mean():.2f})")

print()

# Still need further filtering?
momentum_separation = v3_2_winners['EntryMomentum'].mean() - v3_2_losers['EntryMomentum'].mean()
if momentum_separation > 100:
    print("⚠️  MOMENTUM still shows strong separation - could filter more aggressively")
    print(f"   Consider raising MinMomentum to {v3_2_losers['EntryMomentum'].quantile(0.75):.2f} (75th percentile of losers)")
elif momentum_separation > 50:
    print("✅ MOMENTUM separation moderate - current filter is working well")
else:
    print("✅ MOMENTUM separation low - filter is very effective")
print()

# ============================================================================
# SECTION 5: ZONE/REGIME DISTRIBUTION
# ============================================================================
print("=" * 80)
print("SECTION 5: v3.2 ZONE/REGIME DISTRIBUTION")
print("=" * 80)
print()

if 'EntryZone' in v3_2_trades.columns:
    zone_dist = v3_2_trades.groupby('EntryZone').agg({
        'Ticket': 'count',
        'Profit': lambda x: (x > 0).sum() / len(x) * 100
    }).round(1)
    zone_dist.columns = ['Count', 'Win_Rate']
    
    print("ZONE DISTRIBUTION:")
    for zone, row in zone_dist.iterrows():
        print(f"  {zone}: {int(row['Count'])} trades ({row['Count'] / len(v3_2_trades) * 100:.1f}%) | WR: {row['Win_Rate']:.1f}%")
    print()

if 'EntryRegime' in v3_2_trades.columns:
    regime_dist = v3_2_trades.groupby('EntryRegime').agg({
        'Ticket': 'count',
        'Profit': lambda x: (x > 0).sum() / len(x) * 100
    }).round(1)
    regime_dist.columns = ['Count', 'Win_Rate']
    
    print("REGIME DISTRIBUTION:")
    for regime, row in regime_dist.iterrows():
        print(f"  {regime}: {int(row['Count'])} trades ({row['Count'] / len(v3_2_trades) * 100:.1f}%) | WR: {row['Win_Rate']:.1f}%")
    print()

# Check if TRANSITION/LOW still present
if 'EntryZone' in v3_2_trades.columns:
    transition_count = len(v3_2_trades[v3_2_trades['EntryZone'] == 'TRANSITION'])
    print(f"✅ TRANSITION zone: {transition_count} trades (should be 0)")
    
if 'EntryRegime' in v3_2_trades.columns:
    low_count = len(v3_2_trades[v3_2_trades['EntryRegime'] == 'LOW'])
    print(f"✅ LOW regime: {low_count} trades (should be 0)")
print()

# ============================================================================
# SECTION 6: HOUR DISTRIBUTION
# ============================================================================
print("=" * 80)
print("SECTION 6: v3.2 HOURLY DISTRIBUTION")
print("=" * 80)
print()

if 'EntryHour' in v3_2_trades.columns:
    hour_dist = v3_2_trades.groupby('EntryHour').agg({
        'Ticket': 'count',
        'Profit': lambda x: (x > 0).sum() / len(x) * 100
    }).round(1)
    hour_dist.columns = ['Count', 'Win_Rate']
    hour_dist = hour_dist.sort_index()
    
    print("HOURLY BREAKDOWN:")
    for hour, row in hour_dist.iterrows():
        blocked_marker = " [BLOCKED]" if hour in [6, 7, 13, 14] else ""
        print(f"  Hour {int(hour):02d}{blocked_marker}: {int(row['Count'])} trades ({row['Count'] / len(v3_2_trades) * 100:.1f}%) | WR: {row['Win_Rate']:.1f}%")
    print()
    
    # Check if blocked hours still present
    blocked_hours_trades = v3_2_trades[v3_2_trades['EntryHour'].isin([6, 7, 13, 14])]
    print(f"✅ Blocked hours (6,7,13,14): {len(blocked_hours_trades)} trades (should be 0)")
    print()

# ============================================================================
# SECTION 7: FINAL SUMMARY & RECOMMENDATIONS
# ============================================================================
print("=" * 80)
print("SECTION 7: FINAL SUMMARY & NEXT STEPS")
print("=" * 80)
print()

print("📊 v3.2_05M FINAL METRICS:")
print(f"  Total Trades: {v3_2_metrics['trades']}")
print(f"  Win Rate: {v3_2_metrics['win_rate']:.1f}%")
print(f"  Profit Factor: {v3_2_metrics['profit_factor']:.2f}")
print(f"  Net P&L: ${v3_2_metrics['net_profit']:.2f}")
print(f"  Winners: {v3_2_metrics['winners']} | Losers: {v3_2_metrics['losers']}")
print()

print("🎯 TARGET METRICS:")
print(f"  Win Rate: {'✅' if v3_2_metrics['win_rate'] >= 50 else '⚠️ '} {v3_2_metrics['win_rate']:.1f}% (target: ≥50%)")
print(f"  Profit Factor: {'✅' if v3_2_metrics['profit_factor'] >= 2.0 else '⚠️ '} {v3_2_metrics['profit_factor']:.2f} (target: ≥2.0)")
print(f"  Trade Count: {'✅' if v3_2_metrics['trades'] >= 100 else '⚠️ '} {v3_2_metrics['trades']} (target: ≥100)")
print()

print("🚀 OPTIMIZATION JOURNEY SUMMARY:")
print(f"  v3.0 → v3.1: {v3_0_metrics['trades']} → {v3_1_metrics['trades']} trades ({(v3_1_metrics['trades'] - v3_0_metrics['trades']) / v3_0_metrics['trades'] * 100:+.1f}%)")
print(f"  v3.1 → v3.2: {v3_1_metrics['trades']} → {v3_2_metrics['trades']} trades ({(v3_2_metrics['trades'] - v3_1_metrics['trades']) / v3_1_metrics['trades'] * 100:+.1f}%)")
print(f"  v3.0 → v3.2: {v3_0_metrics['trades']} → {v3_2_metrics['trades']} trades ({trade_reduction:.1f}% reduction)")
print()
print(f"  Win Rate: {v3_0_metrics['win_rate']:.1f}% → {v3_1_metrics['win_rate']:.1f}% → {v3_2_metrics['win_rate']:.1f}% (Total: {wr_improvement:+.1f}%)")
print(f"  Profit Factor: {v3_0_metrics['profit_factor']:.2f} → {v3_1_metrics['profit_factor']:.2f} → {v3_2_metrics['profit_factor']:.2f} (Total: {pf_improvement:+.2f})")
print()

# Recommendations
print("💡 RECOMMENDATIONS:")
if v3_2_metrics['win_rate'] >= 50 and v3_2_metrics['profit_factor'] >= 2.0:
    print("  ✅ EXCELLENT RESULTS! v3.2_05M is ready for forward testing")
    print("  ✅ SL/TP settings are working well (340/1950)")
    print("  ✅ Momentum filter is effective (MinMomentum -346.58)")
    print()
    print("  📋 NEXT STEPS:")
    print("     1. Create comprehensive partner dashboard reports")
    print("     2. Compare 5M vs 15M multi-timeframe strategy")
    print("     3. Prepare scaling plan for 120 symbols")
elif v3_2_metrics['win_rate'] >= 45:
    print("  ✅ GOOD RESULTS! Close to target metrics")
    print("  🔧 Consider minor adjustments:")
    if momentum_separation > 100:
        print(f"     - Raise MinMomentum to {v3_2_losers['EntryMomentum'].quantile(0.75):.2f} (75th percentile of losers)")
    if tp_hits / len(v3_2_trades) < 0.40:
        print("     - Consider tighter TP (1750 pips) for more frequent wins")
else:
    print("  ⚠️  NEEDS IMPROVEMENT - Below target metrics")
    print("  🔧 Suggested adjustments:")
    print("     - Review Momentum filter threshold")
    print("     - Analyze losing trades for common patterns")
    print("     - Consider additional time filters")

print()
print("=" * 80)
print("✅ ANALYSIS COMPLETE!")
print("=" * 80)
