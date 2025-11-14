#!/usr/bin/env python3
"""
TickPhysics v3.1 Optimization Analysis
Compare v3.1 (Zone/Regime/Time filters) vs v3.0 (Pure baseline)
Validate data-driven optimization effectiveness
"""
import pandas as pd
import numpy as np
from pathlib import Path

print("\n" + "="*80)
print("  🔬 TICKPHYSICS v3.1 OPTIMIZATION ANALYSIS")
print("  Zone/Regime/Time Filters vs Pure Baseline")
print("="*80 + "\n")

# Load v3.0 baseline data
mt5_v30 = pd.read_csv('MTBacktest_Report_3.0.csv')
trades_v30 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0.csv')
signals_v30 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.0.csv')

# Load v3.1 optimization data
mt5_v31 = pd.read_csv('MTBacktest_Report_3.1.csv')
trades_v31 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1.csv')
signals_v31 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.1.csv')

print(f"📊 Data Loaded:")
print(f"   v3.0 Baseline:   {len(trades_v30)} trades, {len(signals_v30)} signals")
print(f"   v3.1 Optimized:  {len(trades_v31)} trades, {len(signals_v31)} signals\n")

# ===================================================================
# SECTION 1: PERFORMANCE COMPARISON
# ===================================================================
print("="*80)
print("  📈 PERFORMANCE COMPARISON: v3.0 BASELINE vs v3.1 OPTIMIZED")
print("="*80 + "\n")

# Parse MT5 data for both versions
def analyze_mt5(df, version):
    exit_deals = df[df['Direction'] == 'out'].copy()
    exit_deals['Profit'] = exit_deals['Profit'].str.replace(' ', '').str.replace(',', '').astype(float)
    exit_deals['Balance'] = exit_deals['Balance'].str.replace(' ', '').str.replace(',', '').astype(float)
    
    total_trades = len(exit_deals)
    wins = len(exit_deals[exit_deals['Profit'] > 0])
    losses = len(exit_deals[exit_deals['Profit'] < 0])
    win_rate = (wins / total_trades * 100) if total_trades > 0 else 0
    
    gross_profit = exit_deals[exit_deals['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(exit_deals[exit_deals['Profit'] < 0]['Profit'].sum())
    net_profit = exit_deals['Profit'].sum()
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    avg_win = exit_deals[exit_deals['Profit'] > 0]['Profit'].mean() if wins > 0 else 0
    avg_loss = abs(exit_deals[exit_deals['Profit'] < 0]['Profit'].mean()) if losses > 0 else 0
    rr_ratio = (avg_win / avg_loss) if avg_loss > 0 else 0
    
    ending_balance = exit_deals['Balance'].iloc[-1] if len(exit_deals) > 0 else 1000.0
    
    return {
        'version': version,
        'trades': total_trades,
        'wins': wins,
        'losses': losses,
        'win_rate': win_rate,
        'gross_profit': gross_profit,
        'gross_loss': gross_loss,
        'net_profit': net_profit,
        'profit_factor': profit_factor,
        'avg_win': avg_win,
        'avg_loss': avg_loss,
        'rr_ratio': rr_ratio,
        'ending_balance': ending_balance
    }

v30_stats = analyze_mt5(mt5_v30, 'v3.0')
v31_stats = analyze_mt5(mt5_v31, 'v3.1')

# Print comparison table
print(f"{'Metric':<25} {'v3.0 Baseline':<20} {'v3.1 Optimized':<20} {'Change':<15}")
print("-" * 80)

def print_metric(label, v30_val, v31_val, is_currency=False, is_percent=False, is_ratio=False):
    if is_currency:
        v30_str = f"${v30_val:,.2f}"
        v31_str = f"${v31_val:,.2f}"
        diff = v31_val - v30_val
        diff_str = f"${diff:+,.2f}"
    elif is_percent:
        v30_str = f"{v30_val:.1f}%"
        v31_str = f"{v31_val:.1f}%"
        diff = v31_val - v30_val
        diff_str = f"{diff:+.1f}%"
    elif is_ratio:
        v30_str = f"{v30_val:.2f}:1"
        v31_str = f"{v31_val:.2f}:1"
        diff = v31_val - v30_val
        diff_str = f"{diff:+.2f}"
    else:
        v30_str = f"{int(v30_val)}"
        v31_str = f"{int(v31_val)}"
        diff = v31_val - v30_val
        diff_str = f"{diff:+,.0f}"
    
    # Add status emoji
    if diff > 0:
        status = "✅" if label in ["Win Rate", "Profit Factor", "Net P&L", "Gross Profit", "Avg Win", "R:R Ratio", "Ending Balance"] else "📊"
    elif diff < 0:
        status = "✅" if label in ["Total Trades", "Losses", "Gross Loss", "Avg Loss"] else "❌"
    else:
        status = "➖"
    
    print(f"{label:<25} {v30_str:<20} {v31_str:<20} {diff_str:<12} {status}")

print_metric("Total Trades", v30_stats['trades'], v31_stats['trades'])
print_metric("Wins", v30_stats['wins'], v31_stats['wins'])
print_metric("Losses", v30_stats['losses'], v31_stats['losses'])
print_metric("Win Rate", v30_stats['win_rate'], v31_stats['win_rate'], is_percent=True)
print()
print_metric("Gross Profit", v30_stats['gross_profit'], v31_stats['gross_profit'], is_currency=True)
print_metric("Gross Loss", v30_stats['gross_loss'], v31_stats['gross_loss'], is_currency=True)
print_metric("Net P&L", v30_stats['net_profit'], v31_stats['net_profit'], is_currency=True)
print_metric("Profit Factor", v30_stats['profit_factor'], v31_stats['profit_factor'], is_ratio=True)
print()
print_metric("Avg Win", v30_stats['avg_win'], v31_stats['avg_win'], is_currency=True)
print_metric("Avg Loss", v30_stats['avg_loss'], v31_stats['avg_loss'], is_currency=True)
print_metric("R:R Ratio", v30_stats['rr_ratio'], v31_stats['rr_ratio'], is_ratio=True)
print()
print_metric("Ending Balance", v30_stats['ending_balance'], v31_stats['ending_balance'], is_currency=True)

# ===================================================================
# SECTION 2: TARGETS ACHIEVEMENT
# ===================================================================
print("\n" + "="*80)
print("  🎯 OPTIMIZATION TARGETS ACHIEVEMENT")
print("="*80 + "\n")

targets = {
    'Win Rate': {'target': 35.0, 'v30': v30_stats['win_rate'], 'v31': v31_stats['win_rate'], 'unit': '%'},
    'Profit Factor': {'target': 1.15, 'v30': v30_stats['profit_factor'], 'v31': v31_stats['profit_factor'], 'unit': ''},
    'Net P&L': {'target': 100.0, 'v30': v30_stats['net_profit'], 'v31': v31_stats['net_profit'], 'unit': '$'},
    'Trade Reduction': {'target': 0.30, 'v30': 0, 'v31': 1 - (v31_stats['trades'] / v30_stats['trades']), 'unit': '%'},
}

print(f"{'Target':<20} {'Goal':<15} {'v3.0':<15} {'v3.1':<15} {'Status'}")
print("-" * 75)

for metric, data in targets.items():
    if data['unit'] == '%':
        goal_str = f"{data['target']:.1f}%"
        v30_str = f"{data['v30']:.1f}%"
        v31_str = f"{data['v31']:.1f}%"
    elif data['unit'] == '$':
        goal_str = f">${data['target']:.0f}"
        v30_str = f"${data['v30']:.2f}"
        v31_str = f"${data['v31']:.2f}"
    else:
        goal_str = f"{data['target']:.2f}"
        v30_str = f"{data['v30']:.2f}"
        v31_str = f"{data['v31']:.2f}"
    
    if metric == 'Trade Reduction':
        achieved = data['v31'] >= data['target']
        v31_str = f"{data['v31']*100:.1f}%"
    else:
        achieved = data['v31'] >= data['target']
    
    status = "✅ MET" if achieved else "❌ MISSED"
    print(f"{metric:<20} {goal_str:<15} {v30_str:<15} {v31_str:<15} {status}")

# ===================================================================
# SECTION 3: FILTER EFFECTIVENESS ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🔬 FILTER EFFECTIVENESS ANALYSIS")
print("="*80 + "\n")

print("Signal Reduction (filtering working):")
total_signals_v30 = len(signals_v30)
total_signals_v31 = len(signals_v31)
print(f"  v3.0 Total Signals: {total_signals_v30}")
print(f"  v3.1 Total Signals: {total_signals_v31}")
print(f"  Signal Reduction:   {total_signals_v30 - total_signals_v31} ({(1 - total_signals_v31/total_signals_v30)*100:.1f}%)")

print(f"\nTrade Reduction (fewer, better trades):")
print(f"  v3.0 Total Trades:  {v30_stats['trades']}")
print(f"  v3.1 Total Trades:  {v31_stats['trades']}")
print(f"  Trade Reduction:    {v30_stats['trades'] - v31_stats['trades']} ({(1 - v31_stats['trades']/v30_stats['trades'])*100:.1f}%)")

# Analyze what got filtered
print(f"\n📊 Zone Filter Impact:")
zone_counts_v30 = trades_v30['EntryZone'].value_counts()
zone_counts_v31 = trades_v31['EntryZone'].value_counts() if len(trades_v31) > 0 else pd.Series()

for zone in ['BEAR', 'AVOID', 'BULL', 'TRANSITION']:
    v30_count = zone_counts_v30.get(zone, 0)
    v31_count = zone_counts_v31.get(zone, 0)
    reduction = v30_count - v31_count
    pct = (reduction / v30_count * 100) if v30_count > 0 else 0
    status = "✅ FILTERED" if zone == 'BEAR' and reduction > 0 else "📊 Active"
    print(f"  {zone:<12} v3.0: {v30_count:>3} → v3.1: {v31_count:>3} (Δ {reduction:+3}, {pct:>5.1f}%) {status}")

print(f"\n📊 Regime Filter Impact:")
regime_counts_v30 = trades_v30['EntryRegime'].value_counts()
regime_counts_v31 = trades_v31['EntryRegime'].value_counts() if len(trades_v31) > 0 else pd.Series()

for regime in ['LOW', 'NORMAL', 'HIGH']:
    v30_count = regime_counts_v30.get(regime, 0)
    v31_count = regime_counts_v31.get(regime, 0)
    reduction = v30_count - v31_count
    pct = (reduction / v30_count * 100) if v30_count > 0 else 0
    status = "✅ FILTERED" if regime == 'LOW' and reduction > 0 else "📊 Active"
    print(f"  {regime:<12} v3.0: {v30_count:>3} → v3.1: {v31_count:>3} (Δ {reduction:+3}, {pct:>5.1f}%) {status}")

# ===================================================================
# SECTION 4: TIME FILTER ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  ⏰ TIME FILTER EFFECTIVENESS")
print("="*80 + "\n")

print("Hourly Trade Distribution:")
hour_v30 = trades_v30['EntryHour'].value_counts().sort_index()
hour_v31 = trades_v31['EntryHour'].value_counts().sort_index() if len(trades_v31) > 0 else pd.Series()

allowed_hours = [2, 12, 19, 23]
blocked_hours = [3, 4, 5, 6, 7, 8, 9, 11, 14, 20]

print(f"\n{'Hour':<6} {'v3.0':<8} {'v3.1':<8} {'Change':<12} {'Status'}")
print("-" * 45)

for hour in sorted(set(hour_v30.index) | set(hour_v31.index)):
    v30_count = hour_v30.get(hour, 0)
    v31_count = hour_v31.get(hour, 0)
    change = v31_count - v30_count
    
    if hour in allowed_hours:
        status = "✅ ALLOWED"
    elif hour in blocked_hours:
        status = "❌ BLOCKED"
    else:
        status = "📊 Other"
    
    print(f"{int(hour):>4}h  {int(v30_count):<8} {int(v31_count):<8} {change:+4}         {status}")

# ===================================================================
# SECTION 5: QUALITY METRICS COMPARISON
# ===================================================================
print("\n" + "="*80)
print("  💎 TRADE QUALITY COMPARISON")
print("="*80 + "\n")

if len(trades_v31) > 0:
    print(f"{'Metric':<25} {'v3.0 Baseline':<20} {'v3.1 Optimized':<20} {'Change'}")
    print("-" * 75)
    
    # MFE/MAE
    v30_mfe = trades_v30['MFE_Pips'].mean()
    v31_mfe = trades_v31['MFE_Pips'].mean()
    print(f"{'Avg MFE (pips)':<25} {v30_mfe:<20.2f} {v31_mfe:<20.2f} {v31_mfe - v30_mfe:+.2f}")
    
    v30_mae = trades_v30['MAE_Pips'].mean()
    v31_mae = trades_v31['MAE_Pips'].mean()
    print(f"{'Avg MAE (pips)':<25} {v30_mae:<20.2f} {v31_mae:<20.2f} {v31_mae - v30_mae:+.2f}")
    
    # RunUp/RunDown
    v30_runup = trades_v30['RunUp_Pips'].mean()
    v31_runup = trades_v31['RunUp_Pips'].mean()
    print(f"{'Avg RunUp (pips)':<25} {v30_runup:<20.2f} {v31_runup:<20.2f} {v31_runup - v30_runup:+.2f}")
    
    v30_rundown = trades_v30['RunDown_Pips'].mean()
    v31_rundown = trades_v31['RunDown_Pips'].mean()
    print(f"{'Avg RunDown (pips)':<25} {v30_rundown:<20.2f} {v31_rundown:<20.2f} {v31_rundown - v30_rundown:+.2f}")
    
    # Hold time
    v30_hold = trades_v30['HoldTimeBars'].mean()
    v31_hold = trades_v31['HoldTimeBars'].mean()
    print(f"{'Avg Hold (bars)':<25} {v30_hold:<20.1f} {v31_hold:<20.1f} {v31_hold - v30_hold:+.1f}")

# ===================================================================
# SECTION 6: FINAL ASSESSMENT
# ===================================================================
print("\n" + "="*80)
print("  ✅ OPTIMIZATION ASSESSMENT")
print("="*80 + "\n")

# Calculate success score
targets_met = sum([
    v31_stats['win_rate'] >= 35.0,
    v31_stats['profit_factor'] >= 1.15,
    v31_stats['net_profit'] >= 100.0,
    (1 - v31_stats['trades'] / v30_stats['trades']) >= 0.25
])

success_rate = (targets_met / 4) * 100

print(f"OPTIMIZATION SUCCESS RATE: {success_rate:.0f}% ({targets_met}/4 targets met)\n")

if success_rate >= 75:
    print("🎉 EXCELLENT RESULTS!")
    print("   ✅ Zone/Regime/Time filters are HIGHLY EFFECTIVE")
    print("   ✅ Ready to add protective stops/TPs in v3.2")
    print("   ✅ Data-driven optimization approach VALIDATED")
elif success_rate >= 50:
    print("✅ GOOD PROGRESS!")
    print("   📊 Filters showing positive impact")
    print("   🔧 Consider fine-tuning time filter hours")
    print("   📈 Continue iterative optimization")
else:
    print("⚠️  NEEDS ADJUSTMENT")
    print("   🔍 Analyze which filters helped/hurt")
    print("   🔧 Adjust filter parameters")
    print("   📊 Re-evaluate optimization strategy")

print(f"\nKey Improvements:")
if v31_stats['win_rate'] > v30_stats['win_rate']:
    print(f"   ✅ Win Rate improved: {v30_stats['win_rate']:.1f}% → {v31_stats['win_rate']:.1f}% (+{v31_stats['win_rate'] - v30_stats['win_rate']:.1f}%)")
if v31_stats['profit_factor'] > v30_stats['profit_factor']:
    print(f"   ✅ Profit Factor improved: {v30_stats['profit_factor']:.2f} → {v31_stats['profit_factor']:.2f} (+{v31_stats['profit_factor'] - v30_stats['profit_factor']:.2f})")
if v31_stats['net_profit'] > v30_stats['net_profit']:
    print(f"   ✅ Net P&L improved: ${v30_stats['net_profit']:.2f} → ${v31_stats['net_profit']:.2f} (+${v31_stats['net_profit'] - v30_stats['net_profit']:.2f})")
if v31_stats['trades'] < v30_stats['trades']:
    reduction_pct = (1 - v31_stats['trades'] / v30_stats['trades']) * 100
    print(f"   ✅ Trade count reduced: {v30_stats['trades']} → {v31_stats['trades']} (-{reduction_pct:.1f}% = fewer, better trades)")

print("\n" + "="*80)
print("  📋 NEXT STEPS")
print("="*80 + "\n")

if success_rate >= 75:
    print("Recommended v3.2 Changes:")
    print("  1. Add protective stops: ~116 pips (from v3.0 MAE analysis)")
    print("  2. Add take profits: ~100 pips (from v3.0 MFE analysis)")
    print("  3. Consider trailing stops for winners")
    print("  4. Maintain Zone/Regime/Time filters (proven effective)")
    print("  5. Expected impact: PF >1.3, Net P&L >$200")
elif success_rate >= 50:
    print("Recommended Adjustments:")
    print("  1. Fine-tune time filter hours based on v3.1 data")
    print("  2. Consider less aggressive Zone/Regime filtering")
    print("  3. Analyze combined filter effects")
    print("  4. Run v3.1b with adjusted parameters")
else:
    print("Recommended Review:")
    print("  1. Analyze individual filter impact")
    print("  2. Check if filters are too restrictive")
    print("  3. Review time filter hour selection")
    print("  4. Consider testing filters individually")

print("\n" + "="*80 + "\n")
