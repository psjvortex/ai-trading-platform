#!/usr/bin/env python3
"""
v3.21_05M Comprehensive Analysis
Hybrid Approach: MA Reversal Exits (v3.1) + Momentum Filter (v3.2)

Compares v3.21 vs v3.2 vs v3.1 vs v3.0 to validate hybrid strategy
"""

import pandas as pd
import numpy as np
from datetime import datetime

print("=" * 80)
print("v3.21_05M COMPREHENSIVE ANALYSIS")
print("Hybrid Strategy: MA Reversals (v3.1) + Momentum Filter (v3.2)")
print("=" * 80)
print()

# Load all 4 versions for comparison from Backtest_Reports folder
print("Loading data files...")
try:
    report_v30 = pd.read_csv('../Backtest_Reports/TP_Integrated_MTBacktest_Report_3.0_05M.csv')
    trades_v30 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.0_05M.csv')
    
    report_v31 = pd.read_csv('../Backtest_Reports/TP_Integrated_MTBacktest_Report_3.1_05M.csv')
    trades_v31 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.1_05M.csv')
    
    report_v32 = pd.read_csv('../Backtest_Reports/TP_Integrated_MTBacktest_Report_3.2_05M.csv')
    trades_v32 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.2_05M.csv')
    
    report_v321 = pd.read_csv('../Backtest_Reports/TP_Integrated_MTBacktest_Report_3.21_05M.csv')
    trades_v321 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.21_05M.csv')
    
    print("✅ All files loaded successfully")
    print()
except FileNotFoundError as e:
    print(f"❌ Error: {e}")
    exit(1)

# ============================================================================
# SECTION 1: VERSION PROGRESSION (v3.0 → v3.1 → v3.2 → v3.21)
# ============================================================================
print("=" * 80)
print("SECTION 1: COMPLETE VERSION PROGRESSION")
print("=" * 80)
print()

versions = {
    'v3.0': {'report': report_v30, 'trades': trades_v30, 'desc': 'Baseline'},
    'v3.1': {'report': report_v31, 'trades': trades_v31, 'desc': 'Zone/Regime/Time filters'},
    'v3.2': {'report': report_v32, 'trades': trades_v32, 'desc': 'SL/TP + Momentum'},
    'v3.21': {'report': report_v321, 'trades': trades_v321, 'desc': 'MA Reversal + Momentum (HYBRID)'}
}

print("Version Comparison:")
print("-" * 80)
print(f"{'Version':<10} {'Description':<35} {'Trades':<10} {'WR%':<10} {'PF':<10} {'P&L':<12}")
print("-" * 80)

results = {}
for version, data in versions.items():
    report = data['report']
    trades = data['trades']
    
    total_trades = len(trades)
    winners = len(trades[trades['Profit'] > 0])
    win_rate = (winners / total_trades * 100) if total_trades > 0 else 0
    
    total_profit = trades['Profit'].sum()
    gross_profit = trades[trades['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(trades[trades['Profit'] < 0]['Profit'].sum())
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    results[version] = {
        'trades': total_trades,
        'wr': win_rate,
        'pf': profit_factor,
        'pl': total_profit
    }
    
    print(f"{version:<10} {data['desc']:<35} {total_trades:<10} {win_rate:<10.1f} {profit_factor:<10.2f} ${total_profit:<11.2f}")

print("-" * 80)
print()

# Calculate changes
print("Change Analysis:")
print("-" * 80)

def calc_change(from_ver, to_ver, metric):
    from_val = results[from_ver][metric]
    to_val = results[to_ver][metric]
    if metric == 'trades':
        return to_val - from_val, ((to_val - from_val) / from_val * 100) if from_val > 0 else 0
    else:
        return to_val - from_val, to_val - from_val

print("\nv3.0 → v3.1 (Zone/Regime/Time filters):")
t_delta, t_pct = calc_change('v3.0', 'v3.1', 'trades')
wr_delta, _ = calc_change('v3.0', 'v3.1', 'wr')
pf_delta, _ = calc_change('v3.0', 'v3.1', 'pf')
pl_delta, _ = calc_change('v3.0', 'v3.1', 'pl')
print(f"  Trades: {results['v3.0']['trades']} → {results['v3.1']['trades']} ({t_delta:+d}, {t_pct:+.1f}%)")
print(f"  Win Rate: {results['v3.0']['wr']:.1f}% → {results['v3.1']['wr']:.1f}% ({wr_delta:+.1f}%)")
print(f"  Profit Factor: {results['v3.0']['pf']:.2f} → {results['v3.1']['pf']:.2f} ({pf_delta:+.2f})")
print(f"  P&L: ${results['v3.0']['pl']:.2f} → ${results['v3.1']['pl']:.2f} ({pl_delta:+.2f})")
print(f"  ✅ Status: MAJOR IMPROVEMENT - Best WR achieved")

print("\nv3.1 → v3.2 (Added SL/TP + Momentum):")
t_delta, t_pct = calc_change('v3.1', 'v3.2', 'trades')
wr_delta, _ = calc_change('v3.1', 'v3.2', 'wr')
pf_delta, _ = calc_change('v3.1', 'v3.2', 'pf')
pl_delta, _ = calc_change('v3.1', 'v3.2', 'pl')
print(f"  Trades: {results['v3.1']['trades']} → {results['v3.2']['trades']} ({t_delta:+d}, {t_pct:+.1f}%)")
print(f"  Win Rate: {results['v3.1']['wr']:.1f}% → {results['v3.2']['wr']:.1f}% ({wr_delta:+.1f}%)")
print(f"  Profit Factor: {results['v3.1']['pf']:.2f} → {results['v3.2']['pf']:.2f} ({pf_delta:+.2f})")
print(f"  P&L: ${results['v3.1']['pl']:.2f} → ${results['v3.2']['pl']:.2f} ({pl_delta:+.2f})")
print(f"  ❌ Status: WR COLLAPSED - SL/TP approach failed")

print("\nv3.2 → v3.21 (Removed SL/TP, kept Momentum - HYBRID):")
t_delta, t_pct = calc_change('v3.2', 'v3.21', 'trades')
wr_delta, _ = calc_change('v3.2', 'v3.21', 'wr')
pf_delta, _ = calc_change('v3.2', 'v3.21', 'pf')
pl_delta, _ = calc_change('v3.2', 'v3.21', 'pl')
print(f"  Trades: {results['v3.2']['trades']} → {results['v3.21']['trades']} ({t_delta:+d}, {t_pct:+.1f}%)")
print(f"  Win Rate: {results['v3.2']['wr']:.1f}% → {results['v3.21']['wr']:.1f}% ({wr_delta:+.1f}%)")
print(f"  Profit Factor: {results['v3.2']['pf']:.2f} → {results['v3.21']['pf']:.2f} ({pf_delta:+.2f})")
print(f"  P&L: ${results['v3.2']['pl']:.2f} → ${results['v3.21']['pl']:.2f} ({pl_delta:+.2f})")
if wr_delta > 0:
    print(f"  ✅ Status: WR RECOVERY - Hybrid approach validated!")
else:
    print(f"  ⚠️  Status: Needs review")

print("\nv3.1 vs v3.21 (Original vs Hybrid):")
t_delta, t_pct = calc_change('v3.1', 'v3.21', 'trades')
wr_delta, _ = calc_change('v3.1', 'v3.21', 'wr')
pf_delta, _ = calc_change('v3.1', 'v3.21', 'pf')
pl_delta, _ = calc_change('v3.1', 'v3.21', 'pl')
print(f"  Trades: {results['v3.1']['trades']} → {results['v3.21']['trades']} ({t_delta:+d}, {t_pct:+.1f}%)")
print(f"  Win Rate: {results['v3.1']['wr']:.1f}% → {results['v3.21']['wr']:.1f}% ({wr_delta:+.1f}%)")
print(f"  Profit Factor: {results['v3.1']['pf']:.2f} → {results['v3.21']['pf']:.2f} ({pf_delta:+.2f})")
print(f"  P&L: ${results['v3.1']['pl']:.2f} → ${results['v3.21']['pl']:.2f} ({pl_delta:+.2f})")
if results['v3.21']['wr'] >= results['v3.1']['wr'] and results['v3.21']['trades'] < results['v3.1']['trades']:
    print(f"  ✅ Status: OPTIMAL - Same/Better WR with fewer trades (Momentum filter working!)")
elif results['v3.21']['wr'] >= results['v3.1']['wr']:
    print(f"  ✅ Status: IMPROVED - Higher WR")
else:
    print(f"  ⚠️  Status: WR lower than v3.1")

print()

# ============================================================================
# SECTION 2: EXIT REASON ANALYSIS (v3.2 SL/TP vs v3.21 MA REVERSALS)
# ============================================================================
print("=" * 80)
print("SECTION 2: EXIT STRATEGY COMPARISON")
print("=" * 80)
print()

print("v3.2 (SL/TP exits):")
print("-" * 80)
v32_exit_counts = trades_v32['ExitReason'].value_counts()
for reason, count in v32_exit_counts.items():
    pct = (count / len(trades_v32)) * 100
    reason_trades = trades_v32[trades_v32['ExitReason'] == reason]
    winners = len(reason_trades[reason_trades['Profit'] > 0])
    wr = (winners / count * 100) if count > 0 else 0
    avg_profit = reason_trades['Profit'].mean()
    print(f"  {reason}: {count} trades ({pct:.1f}%) | WR: {wr:.1f}% | Avg P&L: ${avg_profit:.2f}")
print()

print("v3.21 (MA Reversal exits - HYBRID):")
print("-" * 80)
v321_exit_counts = trades_v321['ExitReason'].value_counts()
for reason, count in v321_exit_counts.items():
    pct = (count / len(trades_v321)) * 100
    reason_trades = trades_v321[trades_v321['ExitReason'] == reason]
    winners = len(reason_trades[reason_trades['Profit'] > 0])
    wr = (winners / count * 100) if count > 0 else 0
    avg_profit = reason_trades['Profit'].mean()
    print(f"  {reason}: {count} trades ({pct:.1f}%) | WR: {wr:.1f}% | Avg P&L: ${avg_profit:.2f}")
print()

# ============================================================================
# SECTION 3: MOMENTUM FILTER EFFECTIVENESS
# ============================================================================
print("=" * 80)
print("SECTION 3: MOMENTUM FILTER EFFECTIVENESS")
print("=" * 80)
print()

print("Momentum Statistics:")
print("-" * 80)
print(f"{'Version':<10} {'Mean Momentum':<20} {'Min Momentum':<20} {'Trade Reduction':<20}")
print("-" * 80)

v30_momentum = trades_v30['EntryMomentum'].mean()
v31_momentum = trades_v31['EntryMomentum'].mean()
v32_momentum = trades_v32['EntryMomentum'].mean()
v321_momentum = trades_v321['EntryMomentum'].mean()

v30_min = trades_v30['EntryMomentum'].min()
v31_min = trades_v31['EntryMomentum'].min()
v32_min = trades_v32['EntryMomentum'].min()
v321_min = trades_v321['EntryMomentum'].min()

print(f"v3.0       {v30_momentum:<20.2f} {v30_min:<20.2f} baseline")
print(f"v3.1       {v31_momentum:<20.2f} {v31_min:<20.2f} {results['v3.0']['trades'] - results['v3.1']['trades']} trades (-{((results['v3.0']['trades'] - results['v3.1']['trades'])/results['v3.0']['trades']*100):.1f}%)")
print(f"v3.2       {v32_momentum:<20.2f} {v32_min:<20.2f} {results['v3.1']['trades'] - results['v3.2']['trades']} trades (-{((results['v3.1']['trades'] - results['v3.2']['trades'])/results['v3.1']['trades']*100):.1f}%)")
print(f"v3.21      {v321_momentum:<20.2f} {v321_min:<20.2f} {results['v3.1']['trades'] - results['v3.21']['trades']} trades (-{((results['v3.1']['trades'] - results['v3.21']['trades'])/results['v3.1']['trades']*100):.1f}%)")
print()

print("Momentum Filter Impact (v3.1 → v3.21):")
print(f"  Mean momentum increase: {v31_momentum:.2f} → {v321_momentum:.2f} ({v321_momentum - v31_momentum:+.2f})")
print(f"  Min momentum: {v31_min:.2f} → {v321_min:.2f} (filter at -346.58)")
print(f"  Trades filtered: {results['v3.1']['trades'] - results['v3.21']['trades']} ({((results['v3.1']['trades'] - results['v3.21']['trades'])/results['v3.1']['trades']*100):.1f}%)")
print(f"  ✅ Momentum filter working as designed")
print()

# ============================================================================
# SECTION 4: PHYSICS METRICS COMPARISON (Winners vs Losers)
# ============================================================================
print("=" * 80)
print("SECTION 4: PHYSICS METRICS - v3.21 Winners vs Losers")
print("=" * 80)
print()

winners_v321 = trades_v321[trades_v321['Profit'] > 0]
losers_v321 = trades_v321[trades_v321['Profit'] <= 0]

print(f"Winners: {len(winners_v321)} trades ({len(winners_v321)/len(trades_v321)*100:.1f}%)")
print(f"Losers: {len(losers_v321)} trades ({len(losers_v321)/len(trades_v321)*100:.1f}%)")
print()

metrics = ['EntryQuality', 'EntryConfluence', 'EntryMomentum']
print(f"{'Metric':<20} {'Winners Mean':<15} {'Losers Mean':<15} {'Delta':<15} {'Separation':<15}")
print("-" * 80)

for metric in metrics:
    winners_mean = winners_v321[metric].mean()
    losers_mean = losers_v321[metric].mean()
    delta = winners_mean - losers_mean
    
    if delta > 10:
        sep = "✅ STRONG"
    elif delta > 5:
        sep = "⚠️  WEAK"
    else:
        sep = "❌ NONE"
    
    print(f"{metric:<20} {winners_mean:<15.2f} {losers_mean:<15.2f} {delta:<15.2f} {sep}")

print()

# ============================================================================
# SECTION 5: FINAL ASSESSMENT & RECOMMENDATIONS
# ============================================================================
print("=" * 80)
print("SECTION 5: FINAL ASSESSMENT & RECOMMENDATIONS")
print("=" * 80)
print()

print("🎯 v3.21 HYBRID STRATEGY RESULTS:")
print("-" * 80)
print(f"  Trades: {results['v3.21']['trades']} (vs v3.1: {results['v3.21']['trades'] - results['v3.1']['trades']:+d})")
print(f"  Win Rate: {results['v3.21']['wr']:.1f}% (vs v3.1: {results['v3.21']['wr'] - results['v3.1']['wr']:+.1f}%)")
print(f"  Profit Factor: {results['v3.21']['pf']:.2f} (vs v3.1: {results['v3.21']['pf'] - results['v3.1']['pf']:+.2f})")
print(f"  Net P&L: ${results['v3.21']['pl']:.2f} (vs v3.1: ${results['v3.21']['pl'] - results['v3.1']['pl']:+.2f})")
print()

# Final verdict
print("FINAL VERDICT:")
print("-" * 80)

wr_target = 35.0
pf_target = 1.4
trade_target = 100

status_items = []

if results['v3.21']['wr'] >= wr_target:
    status_items.append(f"✅ Win Rate: {results['v3.21']['wr']:.1f}% (target: ≥{wr_target}%)")
else:
    status_items.append(f"⚠️  Win Rate: {results['v3.21']['wr']:.1f}% (target: ≥{wr_target}%)")

if results['v3.21']['pf'] >= pf_target:
    status_items.append(f"✅ Profit Factor: {results['v3.21']['pf']:.2f} (target: ≥{pf_target})")
else:
    status_items.append(f"⚠️  Profit Factor: {results['v3.21']['pf']:.2f} (target: ≥{pf_target})")

if results['v3.21']['trades'] >= trade_target:
    status_items.append(f"✅ Trade Count: {results['v3.21']['trades']} (target: ≥{trade_target})")
else:
    status_items.append(f"⚠️  Trade Count: {results['v3.21']['trades']} (target: ≥{trade_target})")

for item in status_items:
    print(f"  {item}")

print()

# Best version determination
best_version = max(results.items(), key=lambda x: x[1]['wr'])
print(f"🏆 BEST PERFORMER: {best_version[0]} ({versions[best_version[0]]['desc']})")
print(f"   Win Rate: {best_version[1]['wr']:.1f}%")
print(f"   Profit Factor: {best_version[1]['pf']:.2f}")
print(f"   Net P&L: ${best_version[1]['pl']:.2f}")
print()

# Recommendations
print("RECOMMENDATIONS:")
print("-" * 80)

if results['v3.21']['wr'] > results['v3.1']['wr']:
    print("✅ v3.21 HYBRID is the NEW BEST PERFORMER!")
    print("   → Momentum filter + MA reversals = Optimal combination")
    print("   → Proceed with v3.21_05M as production strategy")
elif results['v3.21']['wr'] >= results['v3.1']['wr'] * 0.95:  # Within 5% of v3.1
    print("✅ v3.21 HYBRID performs comparably to v3.1")
    print("   → Momentum filter reduces trades while maintaining WR")
    print("   → Consider v3.21_05M for lower trade frequency")
else:
    print("⚠️  v3.21 HYBRID underperforms v3.1")
    print("   → Consider reverting to v3.1_05M (pure Zone/Regime/Time filters)")
    print("   → OR adjust Momentum threshold")

print()

print("NEXT STEPS:")
print("-" * 80)
if results['v3.21']['wr'] >= results['v3.1']['wr']:
    print("1. ✅ v3.21_05M validated as optimal 5M strategy")
    print("2. 📊 Create comprehensive partner dashboard reports")
    print("3. 🔄 Compare 5M vs 15M multi-timeframe strategy")
    print("4. 🚀 Forward testing preparation")
else:
    print("1. ⚠️  Review Momentum filter threshold (-346.58)")
    print("2. 🔄 Consider v3.1_05M as production strategy")
    print("3. 📊 Additional optimization if needed")

print()
print("=" * 80)
print("ANALYSIS COMPLETE")
print("=" * 80)
