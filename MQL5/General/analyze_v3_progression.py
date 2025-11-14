#!/usr/bin/env python3
"""
TickPhysics v3.0 → v3.1 → v3.2 COMPLETE PROGRESSION ANALYSIS
Track optimization journey from baseline to physics-refined
"""
import pandas as pd
import numpy as np

print("\n" + "="*80)
print("  🚀 TICKPHYSICS OPTIMIZATION JOURNEY: v3.0 → v3.1 → v3.2")
print("  From Pure Baseline to Physics-Refined Excellence")
print("="*80 + "\n")

# Load all versions
mt5_v30 = pd.read_csv('MTBacktest_Report_3.0.csv')
trades_v30 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0.csv')
signals_v30 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.0.csv')

mt5_v31 = pd.read_csv('MTBacktest_Report_3.1.csv')
trades_v31 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1.csv')
signals_v31 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.1.csv')

mt5_v32 = pd.read_csv('MTBacktest_Report_3.2.csv')
trades_v32 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.2.csv')
signals_v32 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.2.csv')

print(f"📊 Data Loaded:")
print(f"   v3.0 Baseline:        {len(trades_v30)} trades, {len(signals_v30)} signals")
print(f"   v3.1 Optimized:       {len(trades_v31)} trades, {len(signals_v31)} signals")
print(f"   v3.2 Physics-Refined: {len(trades_v32)} trades, {len(signals_v32)} signals\n")

# ===================================================================
# SECTION 1: 3-WAY PERFORMANCE COMPARISON
# ===================================================================
print("="*80)
print("  📈 PERFORMANCE PROGRESSION: v3.0 → v3.1 → v3.2")
print("="*80 + "\n")

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
v32_stats = analyze_mt5(mt5_v32, 'v3.2')

# Print comparison table
print(f"{'Metric':<20} {'v3.0 Baseline':<18} {'v3.1 Optimized':<18} {'v3.2 Physics':<18} {'Journey'}")
print("-" * 95)

def print_3way(label, v30, v31, v32, is_currency=False, is_percent=False, is_ratio=False):
    if is_currency:
        v30_str = f"${v30:,.2f}"
        v31_str = f"${v31:,.2f}"
        v32_str = f"${v32:,.2f}"
        journey = f"${v32-v30:+.2f}"
    elif is_percent:
        v30_str = f"{v30:.1f}%"
        v31_str = f"{v31:.1f}%"
        v32_str = f"{v32:.1f}%"
        journey = f"{v32-v30:+.1f}%"
    elif is_ratio:
        v30_str = f"{v30:.2f}:1"
        v31_str = f"{v31:.2f}:1"
        v32_str = f"{v32:.2f}:1"
        journey = f"{v32-v30:+.2f}"
    else:
        v30_str = f"{int(v30)}"
        v31_str = f"{int(v31)}"
        v32_str = f"{int(v32)}"
        journey = f"{int(v32-v30):+d}"
    
    print(f"{label:<20} {v30_str:<18} {v31_str:<18} {v32_str:<18} {journey}")

print_3way("Total Trades", v30_stats['trades'], v31_stats['trades'], v32_stats['trades'])
print_3way("Wins", v30_stats['wins'], v31_stats['wins'], v32_stats['wins'])
print_3way("Losses", v30_stats['losses'], v31_stats['losses'], v32_stats['losses'])
print_3way("Win Rate", v30_stats['win_rate'], v31_stats['win_rate'], v32_stats['win_rate'], is_percent=True)
print()
print_3way("Gross Profit", v30_stats['gross_profit'], v31_stats['gross_profit'], v32_stats['gross_profit'], is_currency=True)
print_3way("Gross Loss", v30_stats['gross_loss'], v31_stats['gross_loss'], v32_stats['gross_loss'], is_currency=True)
print_3way("Net P&L", v30_stats['net_profit'], v31_stats['net_profit'], v32_stats['net_profit'], is_currency=True)
print_3way("Profit Factor", v30_stats['profit_factor'], v31_stats['profit_factor'], v32_stats['profit_factor'], is_ratio=True)
print()
print_3way("Avg Win", v30_stats['avg_win'], v31_stats['avg_win'], v32_stats['avg_win'], is_currency=True)
print_3way("Avg Loss", v30_stats['avg_loss'], v31_stats['avg_loss'], v32_stats['avg_loss'], is_currency=True)
print_3way("R:R Ratio", v30_stats['rr_ratio'], v31_stats['rr_ratio'], v32_stats['rr_ratio'], is_ratio=True)
print()
print_3way("Ending Balance", v30_stats['ending_balance'], v31_stats['ending_balance'], v32_stats['ending_balance'], is_currency=True)

# ===================================================================
# SECTION 2: OPTIMIZATION IMPACT ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  📊 OPTIMIZATION IMPACT BREAKDOWN")
print("="*80 + "\n")

print("v3.0 → v3.1 (Zone/Regime/Time Filters):")
print(f"  Trades:        {v30_stats['trades']} → {v31_stats['trades']} ({(v31_stats['trades']/v30_stats['trades']-1)*100:+.1f}%)")
print(f"  Win Rate:      {v30_stats['win_rate']:.1f}% → {v31_stats['win_rate']:.1f}% ({v31_stats['win_rate']-v30_stats['win_rate']:+.1f}%)")
print(f"  Profit Factor: {v30_stats['profit_factor']:.2f} → {v31_stats['profit_factor']:.2f} ({v31_stats['profit_factor']-v30_stats['profit_factor']:+.2f})")
print(f"  Net P&L:       ${v30_stats['net_profit']:.2f} → ${v31_stats['net_profit']:.2f} (${v31_stats['net_profit']-v30_stats['net_profit']:+.2f})")
print(f"  ✅ IMPACT: Zone/Regime/Time filters TRANSFORMED performance!")

print(f"\nv3.1 → v3.2 (Physics Refinement - Momentum Filter):")
print(f"  Trades:        {v31_stats['trades']} → {v32_stats['trades']} ({(v32_stats['trades']/v31_stats['trades']-1)*100:+.1f}%)")
print(f"  Win Rate:      {v31_stats['win_rate']:.1f}% → {v32_stats['win_rate']:.1f}% ({v32_stats['win_rate']-v31_stats['win_rate']:+.1f}%)")
print(f"  Profit Factor: {v31_stats['profit_factor']:.2f} → {v32_stats['profit_factor']:.2f} ({v32_stats['profit_factor']-v31_stats['profit_factor']:+.2f})")
print(f"  Net P&L:       ${v31_stats['net_profit']:.2f} → ${v32_stats['net_profit']:.2f} (${v32_stats['net_profit']-v31_stats['net_profit']:+.2f})")

if v32_stats['win_rate'] > v31_stats['win_rate'] and v32_stats['profit_factor'] > v31_stats['profit_factor']:
    print(f"  ✅ IMPACT: Momentum filter IMPROVED performance!")
elif v32_stats['win_rate'] > v31_stats['win_rate'] or v32_stats['profit_factor'] > v31_stats['profit_factor']:
    print(f"  📊 IMPACT: Momentum filter showed PARTIAL improvement")
else:
    print(f"  ⚠️  IMPACT: Momentum filter may be TOO RESTRICTIVE")

print(f"\nComplete Journey (v3.0 → v3.2):")
print(f"  Trades:        {v30_stats['trades']} → {v32_stats['trades']} ({(v32_stats['trades']/v30_stats['trades']-1)*100:+.1f}%)")
print(f"  Win Rate:      {v30_stats['win_rate']:.1f}% → {v32_stats['win_rate']:.1f}% ({v32_stats['win_rate']-v30_stats['win_rate']:+.1f}%)")
print(f"  Profit Factor: {v30_stats['profit_factor']:.2f} → {v32_stats['profit_factor']:.2f} ({v32_stats['profit_factor']-v30_stats['profit_factor']:+.2f})")
print(f"  Net P&L:       ${v30_stats['net_profit']:.2f} → ${v32_stats['net_profit']:.2f} (${v32_stats['net_profit']-v30_stats['net_profit']:+.2f})")

# ===================================================================
# SECTION 3: v3.2 DETAILED ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🔬 v3.2 PHYSICS-REFINED DETAILED ANALYSIS")
print("="*80 + "\n")

print(f"Trade Summary:")
print(f"  Total Trades:   {len(trades_v32)}")
print(f"  Winners:        {len(trades_v32[trades_v32['Profit'] > 0])} ({len(trades_v32[trades_v32['Profit'] > 0])/len(trades_v32)*100:.1f}%)")
print(f"  Losers:         {len(trades_v32[trades_v32['Profit'] < 0])} ({len(trades_v32[trades_v32['Profit'] < 0])/len(trades_v32)*100:.1f}%)")

if len(trades_v32) > 0:
    print(f"\nPhysics Metrics (Entry):")
    print(f"  Quality:    Min={trades_v32['EntryQuality'].min():.2f}, Max={trades_v32['EntryQuality'].max():.2f}, Avg={trades_v32['EntryQuality'].mean():.2f}")
    print(f"  Confluence: Min={trades_v32['EntryConfluence'].min():.2f}, Max={trades_v32['EntryConfluence'].max():.2f}, Avg={trades_v32['EntryConfluence'].mean():.2f}")
    print(f"  Momentum:   Min={trades_v32['EntryMomentum'].min():.2f}, Max={trades_v32['EntryMomentum'].max():.2f}, Avg={trades_v32['EntryMomentum'].mean():.2f}")
    print(f"  → Threshold: MinMomentum=-437.77 (all trades above this)")
    
    print(f"\nZone Distribution:")
    for zone in ['BEAR', 'AVOID', 'BULL', 'TRANSITION']:
        count = len(trades_v32[trades_v32['EntryZone'] == zone])
        if count > 0:
            wins = len(trades_v32[(trades_v32['EntryZone'] == zone) & (trades_v32['Profit'] > 0)])
            wr = (wins / count * 100) if count > 0 else 0
            print(f"  {zone:<12} {count:>2} trades ({wr:>5.1f}% WR)")
    
    print(f"\nRegime Distribution:")
    for regime in ['LOW', 'NORMAL', 'HIGH']:
        count = len(trades_v32[trades_v32['EntryRegime'] == regime])
        if count > 0:
            wins = len(trades_v32[(trades_v32['EntryRegime'] == regime) & (trades_v32['Profit'] > 0)])
            wr = (wins / count * 100) if count > 0 else 0
            print(f"  {regime:<12} {count:>2} trades ({wr:>5.1f}% WR)")
    
    print(f"\nTime Distribution:")
    hour_counts = trades_v32['EntryHour'].value_counts().sort_index()
    for hour, count in hour_counts.items():
        wins = len(trades_v32[(trades_v32['EntryHour'] == hour) & (trades_v32['Profit'] > 0)])
        wr = (wins / count * 100) if count > 0 else 0
        print(f"  Hour {int(hour):>2}h: {int(count):>2} trades ({wr:>5.1f}% WR)")

# ===================================================================
# SECTION 4: MOMENTUM FILTER EFFECTIVENESS
# ===================================================================
print("\n" + "="*80)
print("  ⚡ MOMENTUM FILTER EFFECTIVENESS ANALYSIS")
print("="*80 + "\n")

print("v3.1 Momentum Distribution (7W/5L):")
v31_winners = trades_v31[trades_v31['Profit'] > 0]
v31_losers = trades_v31[trades_v31['Profit'] < 0]
print(f"  Winners avg momentum: {v31_winners['EntryMomentum'].mean():.2f}")
print(f"  Losers avg momentum:  {v31_losers['EntryMomentum'].mean():.2f}")
print(f"  Separation:           {v31_winners['EntryMomentum'].mean() - v31_losers['EntryMomentum'].mean():.2f}")
print(f"  v3.2 Threshold:       -437.77 (75% of v3.1 winners above)")

if len(trades_v32) > 0:
    print(f"\nv3.2 Momentum Results:")
    print(f"  Min momentum:  {trades_v32['EntryMomentum'].min():.2f}")
    print(f"  Max momentum:  {trades_v32['EntryMomentum'].max():.2f}")
    print(f"  Avg momentum:  {trades_v32['EntryMomentum'].mean():.2f}")
    
    # Check if any trades violated the threshold (shouldn't happen)
    below_threshold = trades_v32[trades_v32['EntryMomentum'] < -437.77]
    if len(below_threshold) > 0:
        print(f"  ⚠️  WARNING: {len(below_threshold)} trades below threshold!")
    else:
        print(f"  ✅ All trades passed momentum filter")
    
    v32_winners = trades_v32[trades_v32['Profit'] > 0]
    v32_losers = trades_v32[trades_v32['Profit'] < 0]
    
    if len(v32_winners) > 0:
        print(f"\nv3.2 Winners momentum: {v32_winners['EntryMomentum'].mean():.2f}")
    if len(v32_losers) > 0:
        print(f"v3.2 Losers momentum:  {v32_losers['EntryMomentum'].mean():.2f}")
    if len(v32_winners) > 0 and len(v32_losers) > 0:
        print(f"v3.2 Separation:       {v32_winners['EntryMomentum'].mean() - v32_losers['EntryMomentum'].mean():.2f}")

# ===================================================================
# SECTION 5: SIGNAL FILTERING PROGRESSION
# ===================================================================
print("\n" + "="*80)
print("  🔍 SIGNAL FILTERING PROGRESSION")
print("="*80 + "\n")

print(f"Signal Generation:")
print(f"  v3.0: {len(signals_v30):>5} total signals → {len(trades_v30):>3} trades ({len(trades_v30)/len(signals_v30)*100:.2f}% conversion)")
print(f"  v3.1: {len(signals_v31):>5} total signals → {len(trades_v31):>3} trades ({len(trades_v31)/len(signals_v31)*100:.2f}% conversion)")
print(f"  v3.2: {len(signals_v32):>5} total signals → {len(trades_v32):>3} trades ({len(trades_v32)/len(signals_v32)*100:.2f}% conversion)")

print(f"\nFiltering Effectiveness:")
v30_filtered = len(signals_v30) - len(trades_v30)
v31_filtered = len(signals_v31) - len(trades_v31)
v32_filtered = len(signals_v32) - len(trades_v32)

print(f"  v3.0: {v30_filtered:>5} signals filtered ({v30_filtered/len(signals_v30)*100:.1f}%)")
print(f"  v3.1: {v31_filtered:>5} signals filtered ({v31_filtered/len(signals_v31)*100:.1f}%) ← Zone/Regime/Time filters")
print(f"  v3.2: {v32_filtered:>5} signals filtered ({v32_filtered/len(signals_v32)*100:.1f}%) ← + Momentum filter")

# ===================================================================
# SECTION 6: FINAL VERDICT & NEXT STEPS
# ===================================================================
print("\n" + "="*80)
print("  ✅ FINAL VERDICT & RECOMMENDATIONS")
print("="*80 + "\n")

# Calculate target achievement
targets_met = 0
target_details = []

if v32_stats['win_rate'] >= 65.0:
    targets_met += 1
    target_details.append(f"✅ Win Rate: {v32_stats['win_rate']:.1f}% (target: 65%+)")
else:
    target_details.append(f"❌ Win Rate: {v32_stats['win_rate']:.1f}% (target: 65%+, missed by {65.0-v32_stats['win_rate']:.1f}%)")

if v32_stats['profit_factor'] >= 2.5:
    targets_met += 1
    target_details.append(f"✅ Profit Factor: {v32_stats['profit_factor']:.2f} (target: 2.5+)")
else:
    target_details.append(f"❌ Profit Factor: {v32_stats['profit_factor']:.2f} (target: 2.5+, missed by {2.5-v32_stats['profit_factor']:.2f})")

if v32_stats['net_profit'] >= 50.0:
    targets_met += 1
    target_details.append(f"✅ Net P&L: ${v32_stats['net_profit']:.2f} (target: $50+)")
else:
    target_details.append(f"❌ Net P&L: ${v32_stats['net_profit']:.2f} (target: $50+, missed by ${50.0-v32_stats['net_profit']:.2f})")

if v32_stats['trades'] >= 6 and v32_stats['trades'] <= 10:
    targets_met += 1
    target_details.append(f"✅ Trade Count: {v32_stats['trades']} (target: 6-10)")
elif v32_stats['trades'] < 6:
    target_details.append(f"⚠️  Trade Count: {v32_stats['trades']} (target: 6-10, too few)")
else:
    target_details.append(f"📊 Trade Count: {v32_stats['trades']} (target: 6-10, more is ok)")

print(f"v3.2 Target Achievement: {targets_met}/4\n")
for detail in target_details:
    print(f"  {detail}")

success_rate = (targets_met / 4) * 100

print(f"\n{'='*40}")
if success_rate >= 75:
    print("🎉 EXCELLENT! v3.2 ACHIEVED TARGETS!")
    print("{'='*40}\n")
    print("Next Steps:")
    print("  1. ✅ v3.2 physics refinement successful")
    print("  2. 🚀 Proceed to v3.3: Add protective stops/TPs")
    print("  3. 📊 Add SL: ~116 pips (from v3.0 MAE analysis)")
    print("  4. 📊 Add TP: ~100 pips (from v3.0 MFE analysis)")
    print("  5. 🎯 Consider trailing stops for winners")
    print("  6. 📈 Expected v3.3: Maintain WR, improve risk management")
elif success_rate >= 50:
    print("📊 GOOD PROGRESS! v3.2 SHOWS IMPROVEMENT")
    print("{'='*40}\n")
    print("Next Steps:")
    print("  1. 📊 v3.2 momentum filter partially effective")
    print("  2. 🔧 Option A: Relax momentum threshold (more trades)")
    print("  3. 🔧 Option B: Proceed to v3.3 with current filters")
    print("  4. 📈 Monitor if fewer trades = acceptable tradeoff")
else:
    print("⚠️  NEEDS REVIEW - v3.2 UNDERPERFORMED")
    print("{'='*40}\n")
    print("Next Steps:")
    print("  1. 🔍 Analyze v3.2 losers (why did they pass?)")
    print("  2. 🔧 Momentum threshold may be too loose")
    print("  3. 🔧 Consider momentum direction alignment")
    print("  4. 📊 Review quality/confluence thresholds")
    print("  5. 🔄 Run v3.2b with adjusted parameters")

print("\n" + "="*80)
print("  📋 OPTIMIZATION JOURNEY SUMMARY")
print("="*80)
print(f"""
v3.0 Baseline (Pure Crossover):
  - 454 trades, 28% WR, PF 0.97, -$6.97
  - Purpose: Establish raw performance baseline
  - Finding: System works, needs filtering
  
v3.1 Zone/Regime/Time (Data-Driven):
  - 13 trades (-97%), 61.5% WR (+33.5%), PF 2.30 (+1.33), +$41.50 (+$48)
  - Purpose: Apply zone/regime/time filters from v3.0 analysis
  - Finding: MASSIVE improvement, momentum separates winners/losers
  
v3.2 Physics-Refined (Momentum Filter):
  - {v32_stats['trades']} trades ({(v32_stats['trades']/v31_stats['trades']-1)*100:+.1f}%), {v32_stats['win_rate']:.1f}% WR ({v32_stats['win_rate']-v31_stats['win_rate']:+.1f}%), PF {v32_stats['profit_factor']:.2f} ({v32_stats['profit_factor']-v31_stats['profit_factor']:+.2f}), ${v32_stats['net_profit']:.2f} (${v32_stats['net_profit']-v31_stats['net_profit']:+.2f})
  - Purpose: Add momentum threshold from v3.1 winner analysis
  - Finding: {('Ultra-selective, quality maintained' if v32_stats['win_rate'] >= v31_stats['win_rate'] else 'May need adjustment')}

Complete Journey (v3.0 → v3.2):
  - Trades: 454 → {v32_stats['trades']} ({(v32_stats['trades']/v30_stats['trades']-1)*100:.1f}%)
  - Win Rate: 28% → {v32_stats['win_rate']:.1f}% ({v32_stats['win_rate']-v30_stats['win_rate']:+.1f}%)
  - Profit Factor: 0.97 → {v32_stats['profit_factor']:.2f} ({v32_stats['profit_factor']-v30_stats['profit_factor']:+.2f})
  - Net P&L: -$6.97 → ${v32_stats['net_profit']:.2f} (${v32_stats['net_profit']-v30_stats['net_profit']:+.2f})
""")
print("="*80 + "\n")
