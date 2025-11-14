#!/usr/bin/env python3
"""
5M Baseline Analysis - v3.0_05M 
Identifies optimization targets for v3.1_05M
"""
import pandas as pd
import numpy as np

print("\n" + "="*80)
print("  🔬 TICKPHYSICS 5-MINUTE BASELINE ANALYSIS (v3.0_05M)")
print("  Pure MA Crossover - No Filters")
print("="*80 + "\n")

# Load 5M baseline data
trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0_05M.csv')
signals = pd.read_csv('TP_Integrated_Signals_NAS100_v3.0_05M.csv')

print(f"📊 Data Loaded:")
print(f"   Trades:      {len(trades):,}")
print(f"   Signals:     {len(signals):,}\n")

# Parse timestamps
trades['OpenTime'] = pd.to_datetime(trades['OpenTime'])
trades['CloseTime'] = pd.to_datetime(trades['CloseTime'])

# ===================================================================
# SECTION 1: OVERALL PERFORMANCE
# ===================================================================
print("="*80)
print("  📈 OVERALL 5M BASELINE PERFORMANCE")
print("="*80 + "\n")

total_trades = len(trades)
winners = trades[trades['Profit'] > 0]
losers = trades[trades['Profit'] <= 0]

win_count = len(winners)
loss_count = len(losers)
win_rate = (win_count / total_trades * 100) if total_trades > 0 else 0

gross_profit = winners['Profit'].sum() if len(winners) > 0 else 0
gross_loss = abs(losers['Profit'].sum()) if len(losers) > 0 else 0
net_profit = trades['Profit'].sum()
profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0

avg_win = winners['Profit'].mean() if len(winners) > 0 else 0
avg_loss = abs(losers['Profit'].mean()) if len(losers) > 0 else 0
rr_ratio = (avg_win / avg_loss) if avg_loss > 0 else 0

# Test period
start_date = trades['OpenTime'].min()
end_date = trades['CloseTime'].max()
test_days = (end_date - start_date).days

print(f"Test Period:       {start_date.strftime('%b %d')} - {end_date.strftime('%b %d, %Y')} ({test_days} days)")
print(f"\n{'='*50}")
print(f"Total Trades:      {total_trades:,}")
print(f"Winners:           {win_count} ({win_rate:.1f}%)")
print(f"Losers:            {loss_count} ({100-win_rate:.1f}%)")
print(f"\nGross Profit:      ${gross_profit:,.2f}")
print(f"Gross Loss:        ${gross_loss:,.2f}")
print(f"Net P&L:           ${net_profit:,.2f}")
print(f"Profit Factor:     {profit_factor:.2f}")
print(f"\nAvg Win:           ${avg_win:.2f}")
print(f"Avg Loss:          ${avg_loss:.2f}")
print(f"R:R Ratio:         {rr_ratio:.2f}:1")
print(f"\nTrades/Day:        {total_trades/test_days:.1f}")
print(f"Signal-to-Trade:   {len(signals)/total_trades:.1f}:1")

# ===================================================================
# SECTION 2: ZONE PERFORMANCE ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🌍 TRADING ZONE PERFORMANCE (5M)")
print("="*80 + "\n")

print(f"{'Zone':<15} {'Trades':<10} {'Win Rate':<12} {'Avg P&L':<12} {'Net P&L':<12} {'Status'}")
print("-" * 80)

zone_stats = {}
for zone in sorted(trades['EntryZone'].unique()):
    zone_trades = trades[trades['EntryZone'] == zone]
    if len(zone_trades) > 0:
        zone_wins = len(zone_trades[zone_trades['Profit'] > 0])
        zone_wr = (zone_wins / len(zone_trades) * 100)
        zone_avg_pnl = zone_trades['Profit'].mean()
        zone_net_pnl = zone_trades['Profit'].sum()
        
        zone_stats[zone] = {
            'count': len(zone_trades),
            'wr': zone_wr,
            'avg_pnl': zone_avg_pnl,
            'net_pnl': zone_net_pnl
        }
        
        if zone_wr < 25:
            status = "❌ FILTER"
        elif zone_wr < 30:
            status = "⚠️  POOR"
        elif zone_wr >= 35:
            status = "✅ GOOD"
        else:
            status = "📊 OK"
        
        pct = (len(zone_trades)/total_trades*100)
        print(f"{zone:<15} {len(zone_trades):<10} {zone_wr:>5.1f}%      ${zone_avg_pnl:>7.2f}      ${zone_net_pnl:>8.2f}   {status}")

worst_zone = min(zone_stats.items(), key=lambda x: x[1]['wr'])
best_zone = max(zone_stats.items(), key=lambda x: x[1]['wr'])

print(f"\n🎯 KEY FINDINGS:")
print(f"   Worst: {worst_zone[0]} ({worst_zone[1]['wr']:.1f}% WR, {worst_zone[1]['count']} trades)")
print(f"   Best:  {best_zone[0]} ({best_zone[1]['wr']:.1f}% WR, {best_zone[1]['count']} trades)")
print(f"   Spread: {best_zone[1]['wr'] - worst_zone[1]['wr']:.1f}%")

# ===================================================================
# SECTION 3: REGIME PERFORMANCE ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  ⚡ VOLATILITY REGIME PERFORMANCE (5M)")
print("="*80 + "\n")

print(f"{'Regime':<15} {'Trades':<10} {'Win Rate':<12} {'Avg P&L':<12} {'Net P&L':<12} {'Status'}")
print("-" * 80)

regime_stats = {}
for regime in sorted(trades['EntryRegime'].unique()):
    regime_trades = trades[trades['EntryRegime'] == regime]
    if len(regime_trades) > 0:
        regime_wins = len(regime_trades[regime_trades['Profit'] > 0])
        regime_wr = (regime_wins / len(regime_trades) * 100)
        regime_avg_pnl = regime_trades['Profit'].mean()
        regime_net_pnl = regime_trades['Profit'].sum()
        
        regime_stats[regime] = {
            'count': len(regime_trades),
            'wr': regime_wr,
            'avg_pnl': regime_avg_pnl,
            'net_pnl': regime_net_pnl
        }
        
        if regime_wr < 25:
            status = "❌ FILTER"
        elif regime_wr < 30:
            status = "⚠️  POOR"
        elif regime_wr >= 35:
            status = "✅ GOOD"
        else:
            status = "📊 OK"
        
        print(f"{regime:<15} {len(regime_trades):<10} {regime_wr:>5.1f}%      ${regime_avg_pnl:>7.2f}      ${regime_net_pnl:>8.2f}   {status}")

worst_regime = min(regime_stats.items(), key=lambda x: x[1]['wr'])
best_regime = max(regime_stats.items(), key=lambda x: x[1]['wr'])

print(f"\n🎯 KEY FINDINGS:")
print(f"   Worst: {worst_regime[0]} ({worst_regime[1]['wr']:.1f}% WR, {worst_regime[1]['count']} trades)")
print(f"   Best:  {best_regime[0]} ({best_regime[1]['wr']:.1f}% WR, {best_regime[1]['count']} trades)")
print(f"   Spread: {best_regime[1]['wr'] - worst_regime[1]['wr']:.1f}%")

# ===================================================================
# SECTION 4: TIME-OF-DAY ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  ⏰ HOURLY PERFORMANCE ANALYSIS (5M)")
print("="*80 + "\n")

trades['EntryHour'] = trades['OpenTime'].dt.hour

print(f"{'Hour':<8} {'Trades':<10} {'Win Rate':<12} {'Avg P&L':<12} {'Net P&L':<12} {'Status'}")
print("-" * 80)

hour_stats = {}
for hour in sorted(trades['EntryHour'].unique()):
    hour_trades = trades[trades['EntryHour'] == hour]
    if len(hour_trades) > 0:
        hour_wins = len(hour_trades[hour_trades['Profit'] > 0])
        hour_wr = (hour_wins / len(hour_trades) * 100)
        hour_avg_pnl = hour_trades['Profit'].mean()
        hour_net_pnl = hour_trades['Profit'].sum()
        
        hour_stats[int(hour)] = {
            'count': len(hour_trades),
            'wr': hour_wr,
            'avg_pnl': hour_avg_pnl,
            'net_pnl': hour_net_pnl
        }
        
        if hour_wr < 20:
            status = "❌ BLOCK"
        elif hour_wr < 25:
            status = "⚠️  POOR"
        elif hour_wr >= 40:
            status = "✅ ALLOW"
        else:
            status = "📊 OK"
        
        print(f"{int(hour):>2}h      {len(hour_trades):<10} {hour_wr:>5.1f}%      ${hour_avg_pnl:>7.2f}      ${hour_net_pnl:>8.2f}   {status}")

# Find best and worst hours
sorted_hours = sorted(hour_stats.items(), key=lambda x: x[1]['wr'])
worst_hours = [h for h, stats in sorted_hours if stats['wr'] < 20]
best_hours = [h for h, stats in sorted_hours if stats['wr'] >= 40]

print(f"\n🎯 KEY FINDINGS:")
if worst_hours:
    worst_wr_avg = np.mean([hour_stats[h]['wr'] for h in worst_hours])
    print(f"   Block Hours (<20% WR): {','.join(map(str, worst_hours))} (Avg: {worst_wr_avg:.1f}% WR)")
if best_hours:
    best_wr_avg = np.mean([hour_stats[h]['wr'] for h in best_hours])
    print(f"   Allow Hours (≥40% WR): {','.join(map(str, best_hours))} (Avg: {best_wr_avg:.1f}% WR)")

# ===================================================================
# SECTION 5: PHYSICS METRICS CORRELATION
# ===================================================================
print("\n" + "="*80)
print("  🔬 PHYSICS METRICS ANALYSIS")
print("="*80 + "\n")

physics_cols = ['EntryQuality', 'EntryConfluence', 'EntryMomentum']

for col in physics_cols:
    if col in trades.columns:
        # Calculate correlation
        corr = trades[[col, 'Profit']].corr().iloc[0, 1]
        
        # Calculate averages
        winner_avg = winners[col].mean() if len(winners) > 0 else 0
        loser_avg = losers[col].mean() if len(losers) > 0 else 0
        separation = winner_avg - loser_avg
        
        print(f"{col:<20} Corr: {corr:>7.3f}   Winners: {winner_avg:>8.2f}   Losers: {loser_avg:>8.2f}   Δ: {separation:>8.2f}")

# ===================================================================
# SECTION 6: OPTIMIZATION RECOMMENDATIONS
# ===================================================================
print("\n" + "="*80)
print("  🎯 v3.1_05M OPTIMIZATION RECOMMENDATIONS")
print("="*80 + "\n")

print("Based on 5M baseline analysis:\n")

# Zone recommendations
if worst_zone[1]['wr'] < 25:
    eliminated_trades = worst_zone[1]['count']
    remaining_pct = (1 - eliminated_trades/total_trades) * 100
    print(f"🌍 ZONE FILTER:")
    print(f"   UseZoneFilter = true")
    print(f"   Avoid: {worst_zone[0]} ({worst_zone[1]['wr']:.1f}% WR)")
    print(f"   Eliminates: {eliminated_trades} trades ({eliminated_trades/total_trades*100:.1f}%)")
    print(f"   Remaining: ~{total_trades - eliminated_trades} trades\n")

# Regime recommendations
if worst_regime[1]['wr'] < 25:
    print(f"⚡ REGIME FILTER:")
    print(f"   UseRegimeFilter = true")
    print(f"   Avoid: {worst_regime[0]} ({worst_regime[1]['wr']:.1f}% WR)")
    print(f"   Eliminates: {worst_regime[1]['count']} trades ({worst_regime[1]['count']/total_trades*100:.1f}%)\n")

# Time recommendations
if best_hours:
    print(f"⏰ TIME FILTER:")
    print(f"   UseTimeFilter = true")
    print(f"   AllowedHours = \"{','.join(map(str, best_hours))}\"")
    print(f"   (Only trade hours with ≥40% WR)")
    if worst_hours:
        print(f"   BlockedHours = \"{','.join(map(str, worst_hours))}\"")
        print(f"   (Hours with <20% WR)\n")

# Combined impact estimate
combined_eliminated = 0
if worst_zone[1]['wr'] < 25:
    combined_eliminated += worst_zone[1]['count']
if worst_regime[1]['wr'] < 25:
    combined_eliminated += worst_regime[1]['count']

expected_remaining = total_trades - combined_eliminated
expected_improvement = "UNKNOWN"

print(f"📊 COMBINED FILTER IMPACT ESTIMATE:")
print(f"   Zone + Regime filters: ~{combined_eliminated} trades eliminated ({combined_eliminated/total_trades*100:.1f}%)")
print(f"   Expected remaining: ~{expected_remaining} trades")
print(f"   + Time filter will further reduce based on hour selection")
print(f"   Target: Similar improvement as 15M (28% → 61.5% WR)\n")

# ===================================================================
# SECTION 7: COMPARISON TO 15M BASELINE
# ===================================================================
print("="*80)
print("  📊 COMPARISON TO 15M BASELINE")
print("="*80 + "\n")

print("15M v3.0 Baseline:")
print(f"   Trades:        454")
print(f"   Win Rate:      28.0%")
print(f"   Profit Factor: 0.97")
print(f"   Net P&L:       -$6.97")
print()
print("5M v3.0 Baseline:")
print(f"   Trades:        {total_trades:,} ({total_trades/454:.1f}x more)")
print(f"   Win Rate:      {win_rate:.1f}% ({win_rate-28.0:+.1f}%)")
print(f"   Profit Factor: {profit_factor:.2f} ({profit_factor-0.97:+.2f})")
print(f"   Net P&L:       ${net_profit:.2f} (${net_profit-(-6.97):+.2f})")
print()
print("Expected 5M Characteristics:")
print(f"   ✅ {total_trades/454:.1f}x more trades (5M has 3x more bars per hour)")
print(f"   ✅ Similar zone/regime patterns (BEAR and LOW likely worst)")
print(f"   ⚠️  Different optimal hours (5M faster timeframe)")
print(f"   ✅ Physics metrics should correlate similarly")

print("\n" + "="*80)
print("  ✅ ANALYSIS COMPLETE - READY FOR v3.1_05M EA CREATION")
print("="*80 + "\n")
