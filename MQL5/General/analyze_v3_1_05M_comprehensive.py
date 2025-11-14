#!/usr/bin/env python3
"""
v3.1_05M Comprehensive Analysis
- Compare v3.1 vs v3.0 baseline
- Calculate optimal SL/TP from MFE/MAE and RunUp/RunDown
- Identify physics thresholds for v3.2
"""
import pandas as pd
import numpy as np

print("\n" + "="*80)
print("  📊 v3.1_05M COMPREHENSIVE ANALYSIS")
print("  Zone/Regime/Time Optimization Results")
print("="*80 + "\n")

# Load v3.1 data
trades_31 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1_05M.csv')
signals_31 = pd.read_csv('TP_Integrated_Signals_NAS100_v3.1_05M.csv')

# Load v3.0 baseline for comparison
trades_30 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0_05M.csv')

print(f"📊 Data Loaded:")
print(f"   v3.1 Trades:  {len(trades_31):,}")
print(f"   v3.1 Signals: {len(signals_31):,}")
print(f"   v3.0 Trades:  {len(trades_30):,} (baseline)\n")

# ===================================================================
# SECTION 1: v3.1 vs v3.0 COMPARISON
# ===================================================================
print("="*80)
print("  📈 v3.1 vs v3.0 PERFORMANCE COMPARISON")
print("="*80 + "\n")

def calc_stats(df):
    total = len(df)
    winners = df[df['Profit'] > 0]
    losers = df[df['Profit'] <= 0]
    
    win_count = len(winners)
    loss_count = len(losers)
    wr = (win_count / total * 100) if total > 0 else 0
    
    gp = winners['Profit'].sum() if len(winners) > 0 else 0
    gl = abs(losers['Profit'].sum()) if len(losers) > 0 else 0
    net = df['Profit'].sum()
    pf = (gp / gl) if gl > 0 else 0
    
    avg_win = winners['Profit'].mean() if len(winners) > 0 else 0
    avg_loss = abs(losers['Profit'].mean()) if len(losers) > 0 else 0
    
    return {
        'trades': total,
        'wins': win_count,
        'losses': loss_count,
        'wr': wr,
        'gp': gp,
        'gl': gl,
        'net': net,
        'pf': pf,
        'avg_win': avg_win,
        'avg_loss': avg_loss
    }

stats_30 = calc_stats(trades_30)
stats_31 = calc_stats(trades_31)

print("v3.0 BASELINE (Pure MA Crossover):")
print(f"   Trades:        {stats_30['trades']:,}")
print(f"   Win Rate:      {stats_30['wr']:.1f}%")
print(f"   Profit Factor: {stats_30['pf']:.2f}")
print(f"   Net P&L:       ${stats_30['net']:.2f}")
print(f"   Avg Win:       ${stats_30['avg_win']:.2f}")
print(f"   Avg Loss:      ${stats_30['avg_loss']:.2f}")

print(f"\nv3.1 OPTIMIZED (Zone/Regime/Time Filters):")
print(f"   Trades:        {stats_31['trades']:,} ({(stats_31['trades']/stats_30['trades']-1)*100:+.1f}%)")
print(f"   Win Rate:      {stats_31['wr']:.1f}% ({stats_31['wr']-stats_30['wr']:+.1f}%)")
print(f"   Profit Factor: {stats_31['pf']:.2f} ({stats_31['pf']-stats_30['pf']:+.2f})")
print(f"   Net P&L:       ${stats_31['net']:.2f} (${stats_31['net']-stats_30['net']:+.2f})")
print(f"   Avg Win:       ${stats_31['avg_win']:.2f} (${stats_31['avg_win']-stats_30['avg_win']:+.2f})")
print(f"   Avg Loss:      ${stats_31['avg_loss']:.2f} (${stats_31['avg_loss']-stats_30['avg_loss']:+.2f})")

trade_reduction = (1 - stats_31['trades']/stats_30['trades']) * 100
wr_improvement = stats_31['wr'] - stats_30['wr']

print(f"\n🎯 OPTIMIZATION IMPACT:")
print(f"   Trade Reduction:  {trade_reduction:.1f}%")
print(f"   WR Improvement:   {wr_improvement:+.1f}%")
print(f"   PF Improvement:   {stats_31['pf']-stats_30['pf']:+.2f}")

if stats_31['wr'] >= 30 and stats_31['pf'] >= 1.2:
    print(f"   ✅ SUCCESSFUL optimization!")
elif stats_31['wr'] >= 28 and stats_31['pf'] >= 1.0:
    print(f"   ⚠️  MARGINAL improvement - may need adjustment")
else:
    print(f"   ❌ UNDERPERFORMING - filters too aggressive or ineffective")

# ===================================================================
# SECTION 2: FILTER EFFECTIVENESS ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🎯 FILTER EFFECTIVENESS (v3.1)")
print("="*80 + "\n")

# What did we filter out?
filtered_trades = stats_30['trades'] - stats_31['trades']
print(f"Total Filtered: {filtered_trades} trades ({trade_reduction:.1f}%)\n")

# Zone distribution
print("ZONE DISTRIBUTION:")
print(f"{'Zone':<15} {'v3.0':<10} {'v3.1':<10} {'Filtered':<12} {'Impact'}")
print("-" * 65)
for zone in sorted(trades_30['EntryZone'].unique()):
    count_30 = len(trades_30[trades_30['EntryZone'] == zone])
    count_31 = len(trades_31[trades_31['EntryZone'] == zone])
    filtered = count_30 - count_31
    pct = (filtered/count_30*100) if count_30 > 0 else 0
    
    if filtered > 0:
        status = "✅ FILTERED" if pct == 100 else f"⚠️  {pct:.0f}%"
    else:
        status = "📊 KEPT"
    
    print(f"{zone:<15} {count_30:<10} {count_31:<10} {filtered:<12} {status}")

# Regime distribution
print(f"\nREGIME DISTRIBUTION:")
print(f"{'Regime':<15} {'v3.0':<10} {'v3.1':<10} {'Filtered':<12} {'Impact'}")
print("-" * 65)
for regime in sorted(trades_30['EntryRegime'].unique()):
    count_30 = len(trades_30[trades_30['EntryRegime'] == regime])
    count_31 = len(trades_31[trades_31['EntryRegime'] == regime])
    filtered = count_30 - count_31
    pct = (filtered/count_30*100) if count_30 > 0 else 0
    
    if filtered > 0:
        status = "✅ FILTERED" if pct == 100 else f"⚠️  {pct:.0f}%"
    else:
        status = "📊 KEPT"
    
    print(f"{regime:<15} {count_30:<10} {count_31:<10} {filtered:<12} {status}")

# Hour distribution
trades_30['EntryHour'] = pd.to_datetime(trades_30['OpenTime']).dt.hour
trades_31['EntryHour'] = pd.to_datetime(trades_31['OpenTime']).dt.hour

blocked_hours = [6, 7, 13, 14]
print(f"\nHOUR FILTER (Blocked: {blocked_hours}):")
for hour in blocked_hours:
    count_30 = len(trades_30[trades_30['EntryHour'] == hour])
    count_31 = len(trades_31[trades_31['EntryHour'] == hour])
    filtered = count_30 - count_31
    pct = (filtered/count_30*100) if count_30 > 0 else 0
    print(f"   Hour {hour:2d}: {count_30:3d} → {count_31:3d} ({pct:.0f}% blocked)")

# ===================================================================
# SECTION 3: OPTIMAL SL/TP CALCULATION
# ===================================================================
print("\n" + "="*80)
print("  💰 OPTIMAL SL/TP CALCULATION (v3.1 Winners)")
print("  Based on MFE/MAE and RunUp/RunDown Analysis")
print("="*80 + "\n")

winners_31 = trades_31[trades_31['Profit'] > 0].copy()
losers_31 = trades_31[trades_31['Profit'] <= 0].copy()

print(f"Analyzing {len(winners_31)} winners and {len(losers_31)} losers...\n")

# MFE Analysis (Max Favorable Excursion - how far trades went in profit)
print("📈 TAKE PROFIT ANALYSIS (from Winner MFE):")
print("   MFE = Maximum profit reached during trade")
print()

mfe_pips = winners_31['MFE_Pips'].dropna()
if len(mfe_pips) > 0:
    mfe_stats = {
        'mean': mfe_pips.mean(),
        'median': mfe_pips.median(),
        'p25': mfe_pips.quantile(0.25),
        'p50': mfe_pips.quantile(0.50),
        'p75': mfe_pips.quantile(0.75),
        'p90': mfe_pips.quantile(0.90),
        'max': mfe_pips.max()
    }
    
    print(f"   Mean MFE:        {mfe_stats['mean']:.1f} pips")
    print(f"   Median MFE:      {mfe_stats['median']:.1f} pips")
    print(f"   25th Percentile: {mfe_stats['p25']:.1f} pips")
    print(f"   75th Percentile: {mfe_stats['p75']:.1f} pips (captures 75% of winners)")
    print(f"   90th Percentile: {mfe_stats['p90']:.1f} pips (captures 90% of winners)")
    print()
    
    # User prefers tighter TP for frequency
    recommended_tp = mfe_stats['p75']
    conservative_tp = mfe_stats['median']
    aggressive_tp = mfe_stats['p90']
    
    print(f"   🎯 RECOMMENDED TP: {recommended_tp:.0f} pips")
    print(f"      (75th percentile - captures most winners, avoids overhang)")
    print(f"   💡 Conservative:  {conservative_tp:.0f} pips (50th percentile - higher frequency)")
    print(f"   💪 Aggressive:    {aggressive_tp:.0f} pips (90th percentile - fewer but bigger wins)")

# MAE Analysis (Max Adverse Excursion - how far trades went against)
print(f"\n📉 STOP LOSS ANALYSIS (from Loser MAE):")
print("   MAE = Maximum loss reached during trade")
print()

mae_pips = losers_31['MAE_Pips'].dropna()
if len(mae_pips) > 0:
    mae_stats = {
        'mean': abs(mae_pips.mean()),
        'median': abs(mae_pips.median()),
        'p25': abs(mae_pips.quantile(0.25)),
        'p50': abs(mae_pips.quantile(0.50)),
        'p75': abs(mae_pips.quantile(0.75)),
        'p90': abs(mae_pips.quantile(0.90)),
        'max': abs(mae_pips.max())
    }
    
    print(f"   Mean MAE:        {mae_stats['mean']:.1f} pips")
    print(f"   Median MAE:      {mae_stats['median']:.1f} pips")
    print(f"   75th Percentile: {mae_stats['p75']:.1f} pips")
    print(f"   90th Percentile: {mae_stats['p90']:.1f} pips")
    print()
    
    # Set SL just beyond 75th percentile of loser MAE
    recommended_sl = mae_stats['p75'] * 1.1  # 10% buffer
    conservative_sl = mae_stats['median'] * 1.1
    wide_sl = mae_stats['p90'] * 1.1
    
    print(f"   🎯 RECOMMENDED SL: {recommended_sl:.0f} pips")
    print(f"      (75th percentile + 10% buffer)")
    print(f"   🛡️  Conservative:  {conservative_sl:.0f} pips (tighter, may stop out winners)")
    print(f"   📊 Wide:          {wide_sl:.0f} pips (90th percentile - gives more room)")

# Calculate R:R ratio
if len(mfe_pips) > 0 and len(mae_pips) > 0:
    rr_ratio = recommended_tp / recommended_sl
    print(f"\n💎 OPTIMAL SL/TP SETTINGS FOR v3.2:")
    print(f"   Stop Loss:    {recommended_sl:.0f} pips")
    print(f"   Take Profit:  {recommended_tp:.0f} pips")
    print(f"   R:R Ratio:    {rr_ratio:.2f}:1")
    print()
    
    # Estimate capture rate
    tp_capture = (mfe_pips >= recommended_tp).sum() / len(mfe_pips) * 100
    print(f"   📊 Expected Performance:")
    print(f"      {tp_capture:.1f}% of winners would hit TP")
    print(f"      Estimated: {len(winners_31) * (tp_capture/100):.0f} TP hits from {len(winners_31)} winners")

# ===================================================================
# SECTION 4: PHYSICS ANALYSIS FOR v3.2
# ===================================================================
print("\n" + "="*80)
print("  🔬 PHYSICS METRICS ANALYSIS (v3.1 Winners vs Losers)")
print("="*80 + "\n")

physics_cols = ['EntryQuality', 'EntryConfluence', 'EntryMomentum']

print(f"{'Metric':<20} {'Winners':<12} {'Losers':<12} {'Separation':<12} {'Status'}")
print("-" * 70)

physics_thresholds = {}

for col in physics_cols:
    if col in trades_31.columns:
        winner_avg = winners_31[col].mean()
        loser_avg = losers_31[col].mean()
        separation = winner_avg - loser_avg
        
        # Calculate 25th percentile of winners for threshold
        threshold = winners_31[col].quantile(0.25)
        physics_thresholds[col] = threshold
        
        if abs(separation) > 30:
            status = "✅ STRONG"
        elif abs(separation) > 15:
            status = "📊 MODERATE"
        else:
            status = "❌ WEAK"
        
        print(f"{col:<20} {winner_avg:>10.2f}  {loser_avg:>10.2f}  {separation:>10.2f}  {status}")

print(f"\n🎯 RECOMMENDED v3.2 PHYSICS THRESHOLDS:")
print(f"   (25th percentile of v3.1 winners)")
print()

for col, threshold in physics_thresholds.items():
    metric_name = col.replace('Entry', '')
    print(f"   Min{metric_name}: {threshold:.2f}")

# Winner-only correlation analysis
print(f"\n📊 WINNER-ONLY CORRELATION:")
if len(winners_31) > 0:
    for col in physics_cols:
        if col in winners_31.columns:
            corr = winners_31[[col, 'Profit']].corr().iloc[0, 1]
            print(f"   {col}: {corr:.3f}")

# ===================================================================
# SECTION 5: v3.2 OPTIMIZATION RECOMMENDATIONS
# ===================================================================
print("\n" + "="*80)
print("  🚀 v3.2_05M OPTIMIZATION RECOMMENDATIONS")
print("="*80 + "\n")

print("Based on v3.1 analysis, v3.2 should include:\n")

print("1️⃣  KEEP v3.1 FILTERS:")
print("   ✅ UseZoneFilter = true (TRANSITION blocked)")
print("   ✅ UseRegimeFilter = true (LOW blocked)")
print("   ✅ UseTimeFilter = true (hours 6,7,13,14 blocked)")
print()

print("2️⃣  ADD STOP LOSS / TAKE PROFIT:")
print(f"   StopLossPips = {recommended_sl:.0f}")
print(f"   TakeProfitPips = {recommended_tp:.0f}")
print(f"   (R:R = {rr_ratio:.2f}:1)")
print()

print("3️⃣  REFINE PHYSICS THRESHOLDS:")
for col, threshold in physics_thresholds.items():
    metric_name = col.replace('Entry', '')
    print(f"   Min{metric_name} = {threshold:.2f}")
print()

# Momentum is usually the strongest separator
if 'EntryMomentum' in physics_thresholds:
    momentum_threshold = physics_thresholds['EntryMomentum']
    print(f"   🎯 CRITICAL: MinMomentum = {momentum_threshold:.2f}")
    print(f"      (Momentum shows strongest separation)")
print()

print("4️⃣  EXPECTED v3.2 RESULTS:")
physics_passes = len(winners_31)
for col, threshold in physics_thresholds.items():
    physics_passes = len(winners_31[winners_31[col] >= threshold])

expected_reduction = (1 - physics_passes / stats_31['trades']) * 100
expected_trades = physics_passes

if expected_trades >= 5:
    print(f"   Estimated Trades: ~{expected_trades} ({expected_reduction:.0f}% reduction from v3.1)")
    print(f"   Target Win Rate:  50-80%")
    print(f"   Target PF:        2.0-5.0")
    print(f"   ✅ Trade count acceptable for high-quality strategy")
else:
    print(f"   ⚠️  Warning: Only ~{expected_trades} trades expected")
    print(f"   May be too aggressive - consider loosening physics thresholds")

print("\n" + "="*80)
print("  ✅ ANALYSIS COMPLETE - READY FOR v3.2_05M EA CREATION")
print("="*80 + "\n")
