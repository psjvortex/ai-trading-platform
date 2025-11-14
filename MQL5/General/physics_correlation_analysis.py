#!/usr/bin/env python3
"""
TickPhysics Correlation Analysis - Win/Loss Pattern Discovery
Analyzes physics metrics to find optimal filter thresholds
"""
import pandas as pd
import numpy as np
from pathlib import Path
from scipy import stats

# === CONFIGURATION ===
TESTER_DIR = Path("/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester")
SYMBOL = "NAS100"
VERSION = "2.4"

print("\n" + "="*100)
print("  🔬 TICKPHYSICS CORRELATION ANALYSIS - Physics Pattern Discovery")
print("="*100 + "\n")

# === LOAD DATA ===
trades_pattern = f"TP_Integrated_Trades_{SYMBOL}_v{VERSION}.csv"
trades_files = list(TESTER_DIR.glob(f"**/MQL5/Files/{trades_pattern}"))

if not trades_files:
    print("❌ Trade CSV not found!")
    exit(1)

trades_csv = trades_files[0]
print(f"📂 Loading: {trades_csv.name}")
print(f"   Location: {trades_csv.parent}\n")

df = pd.read_csv(trades_csv)
print(f"✅ Loaded {len(df)} trades\n")

# === SEGMENT WINS VS LOSSES ===
wins = df[df['Profit'] > 0].copy()
losses = df[df['Profit'] <= 0].copy()

print("="*100)
print("  📊 TRADE SEGMENTATION")
print("="*100 + "\n")
print(f"Winning Trades:  {len(wins)} ({len(wins)/len(df)*100:.1f}%)")
print(f"Losing Trades:   {len(losses)} ({len(losses)/len(df)*100:.1f}%)")
print(f"Total Trades:    {len(df)}")
print(f"\nWin Rate:        {len(wins)/len(df)*100:.1f}%")
print(f"Avg Win:         ${wins['Profit'].mean():.2f}")
print(f"Avg Loss:        ${losses['Profit'].mean():.2f}")
print(f"Profit Factor:   {abs(wins['Profit'].sum() / losses['Profit'].sum()) if losses['Profit'].sum() != 0 else 'N/A':.2f}")

# === PHYSICS METRICS TO ANALYZE ===
physics_metrics = [
    'EntryQuality',
    'EntryConfluence', 
    'EntryMomentum',
    'EntryEntropy'
]

# === CORRELATION ANALYSIS ===
print("\n" + "="*100)
print("  🎯 PHYSICS METRICS CORRELATION WITH PROFITABILITY")
print("="*100 + "\n")

correlations = {}
for metric in physics_metrics:
    if metric in df.columns:
        # Calculate correlation with profit
        corr, p_value = stats.pearsonr(df[metric], df['Profit'])
        correlations[metric] = {
            'correlation': corr,
            'p_value': p_value,
            'significant': p_value < 0.05
        }
        
        sig_marker = "✅ SIGNIFICANT" if p_value < 0.05 else "⚠️  Not significant"
        direction = "📈 Positive" if corr > 0 else "📉 Negative"
        
        print(f"{metric:<20} | Corr: {corr:>7.4f} | p-value: {p_value:>7.4f} | {direction} | {sig_marker}")

# === STATISTICAL COMPARISON: WINS VS LOSSES ===
print("\n" + "="*100)
print("  📈 WINNING TRADES vs 📉 LOSING TRADES - Statistical Comparison")
print("="*100 + "\n")

print(f"{'Metric':<20} | {'Wins Mean':<12} | {'Losses Mean':<12} | {'Difference':<12} | {'T-Test p-val':<12} | {'Winner Profile':<15}")
print("-"*100)

recommendations = []

for metric in physics_metrics:
    if metric in df.columns:
        win_mean = wins[metric].mean()
        loss_mean = losses[metric].mean()
        diff = win_mean - loss_mean
        diff_pct = (diff / loss_mean * 100) if loss_mean != 0 else 0
        
        # T-test to check if means are significantly different
        t_stat, p_val = stats.ttest_ind(wins[metric], losses[metric])
        
        # Determine if winners have higher or lower values
        if diff > 0:
            winner_profile = "HIGHER ⬆️"
            recommendation = f"Filter: Keep trades with {metric} > {loss_mean:.1f}"
        else:
            winner_profile = "LOWER ⬇️"
            recommendation = f"Filter: Keep trades with {metric} < {loss_mean:.1f}"
        
        sig = "✅" if p_val < 0.05 else "⚠️"
        
        print(f"{metric:<20} | {win_mean:>11.2f} | {loss_mean:>11.2f} | {diff:>11.2f} | {p_val:>11.4f} {sig} | {winner_profile:<15}")
        
        if p_val < 0.05 and abs(diff) > 0:
            recommendations.append({
                'metric': metric,
                'threshold': loss_mean,
                'direction': 'above' if diff > 0 else 'below',
                'improvement': diff_pct,
                'p_value': p_val
            })

# === ZONE & REGIME ANALYSIS ===
print("\n" + "="*100)
print("  🗺️  TRADING ZONE PERFORMANCE")
print("="*100 + "\n")

if 'EntryZone' in df.columns:
    zone_stats = df.groupby('EntryZone').agg({
        'Profit': ['count', 'sum', 'mean'],
        'Ticket': 'count'
    }).round(2)
    
    zone_win_rate = df.groupby('EntryZone').apply(lambda x: (x['Profit'] > 0).sum() / len(x) * 100).round(1)
    
    print(f"{'Zone':<15} | {'Trades':<8} | {'Total P&L':<12} | {'Avg P&L':<12} | {'Win Rate':<10}")
    print("-"*100)
    
    zone_recommendations = []
    for zone in df['EntryZone'].unique():
        zone_df = df[df['EntryZone'] == zone]
        trades = len(zone_df)
        total_pnl = zone_df['Profit'].sum()
        avg_pnl = zone_df['Profit'].mean()
        win_rate = (zone_df['Profit'] > 0).sum() / len(zone_df) * 100
        
        quality = "✅ GOOD" if win_rate > 35 and avg_pnl > 0 else "⚠️ AVOID" if win_rate < 25 else "⚪ NEUTRAL"
        
        print(f"{zone:<15} | {trades:<8} | ${total_pnl:>10.2f} | ${avg_pnl:>10.2f} | {win_rate:>8.1f}% | {quality}")
        
        if win_rate > 35 or win_rate < 25:
            zone_recommendations.append({
                'zone': zone,
                'action': 'PREFER' if win_rate > 35 else 'AVOID',
                'win_rate': win_rate,
                'avg_profit': avg_pnl
            })

print("\n" + "="*100)
print("  🌡️  VOLATILITY REGIME PERFORMANCE")
print("="*100 + "\n")

if 'EntryRegime' in df.columns:
    print(f"{'Regime':<15} | {'Trades':<8} | {'Total P&L':<12} | {'Avg P&L':<12} | {'Win Rate':<10}")
    print("-"*100)
    
    regime_recommendations = []
    for regime in df['EntryRegime'].unique():
        regime_df = df[df['EntryRegime'] == regime]
        trades = len(regime_df)
        total_pnl = regime_df['Profit'].sum()
        avg_pnl = regime_df['Profit'].mean()
        win_rate = (regime_df['Profit'] > 0).sum() / len(regime_df) * 100
        
        quality = "✅ GOOD" if win_rate > 35 and avg_pnl > 0 else "⚠️ AVOID" if win_rate < 25 else "⚪ NEUTRAL"
        
        print(f"{regime:<15} | {trades:<8} | ${total_pnl:>10.2f} | ${avg_pnl:>10.2f} | {win_rate:>8.1f}% | {quality}")
        
        if win_rate > 35 or win_rate < 25:
            regime_recommendations.append({
                'regime': regime,
                'action': 'PREFER' if win_rate > 35 else 'AVOID',
                'win_rate': win_rate,
                'avg_profit': avg_pnl
            })

# === TIME-BASED ANALYSIS ===
print("\n" + "="*100)
print("  🕐 TIME-OF-DAY PERFORMANCE")
print("="*100 + "\n")

if 'EntryHour' in df.columns:
    hour_stats = df.groupby('EntryHour').agg({
        'Profit': ['count', 'sum', 'mean']
    }).round(2)
    
    print(f"{'Hour (UTC)':<12} | {'Trades':<8} | {'Total P&L':<12} | {'Avg P&L':<12} | {'Win Rate':<10}")
    print("-"*100)
    
    best_hours = []
    worst_hours = []
    
    for hour in sorted(df['EntryHour'].unique()):
        hour_df = df[df['EntryHour'] == hour]
        if len(hour_df) < 5:  # Skip hours with too few trades
            continue
            
        trades = len(hour_df)
        total_pnl = hour_df['Profit'].sum()
        avg_pnl = hour_df['Profit'].mean()
        win_rate = (hour_df['Profit'] > 0).sum() / len(hour_df) * 100
        
        quality = "✅ GOOD" if win_rate > 35 and avg_pnl > 0 else "⚠️ POOR" if win_rate < 25 else "⚪ OK"
        
        print(f"{hour:02d}:00 UTC   | {trades:<8} | ${total_pnl:>10.2f} | ${avg_pnl:>10.2f} | {win_rate:>8.1f}% | {quality}")
        
        if win_rate > 35 and avg_pnl > 0:
            best_hours.append(hour)
        elif win_rate < 25:
            worst_hours.append(hour)

# === ACTIONABLE RECOMMENDATIONS ===
print("\n" + "="*100)
print("  💡 ACTIONABLE RECOMMENDATIONS FOR EA OPTIMIZATION")
print("="*100 + "\n")

print("🎯 PHYSICS FILTER RECOMMENDATIONS:\n")

if recommendations:
    for i, rec in enumerate(recommendations, 1):
        direction_text = "above" if rec['direction'] == 'above' else "below"
        print(f"{i}. {rec['metric']}: Keep trades {direction_text} {rec['threshold']:.1f}")
        print(f"   → Expected improvement: {abs(rec['improvement']):.1f}%")
        print(f"   → Statistical confidence: p={rec['p_value']:.4f} {'✅ HIGH' if rec['p_value'] < 0.01 else '⚠️ MODERATE'}\n")
else:
    print("   ⚠️  No statistically significant physics correlations found.")
    print("   → Consider using zone/regime/time filters instead\n")

print("\n🗺️  ZONE/REGIME FILTERS:\n")

if 'zone_recommendations' in locals() and zone_recommendations:
    for rec in zone_recommendations:
        print(f"   • {rec['action']} zone: {rec['zone']} (Win rate: {rec['win_rate']:.1f}%, Avg: ${rec['avg_profit']:.2f})")
else:
    print("   No strong zone patterns detected\n")

if 'regime_recommendations' in locals() and regime_recommendations:
    for rec in regime_recommendations:
        print(f"   • {rec['action']} regime: {rec['regime']} (Win rate: {rec['win_rate']:.1f}%, Avg: ${rec['avg_profit']:.2f})")
else:
    print("   No strong regime patterns detected\n")

print("\n🕐 TIME-BASED FILTERS:\n")

if best_hours:
    print(f"   ✅ BEST HOURS (prefer): {', '.join([f'{h:02d}:00' for h in best_hours])}")
if worst_hours:
    print(f"   ⚠️  WORST HOURS (avoid): {', '.join([f'{h:02d}:00' for h in worst_hours])}")

if not best_hours and not worst_hours:
    print("   No strong time-of-day patterns detected")

# === PROPOSED EA CONFIGURATION ===
print("\n" + "="*100)
print("  ⚙️  PROPOSED EA CONFIGURATION (Apply to v2.5)")
print("="*100 + "\n")

print("// Physics Filters (enable in EA)")
print("UsePhysicsFilters = true;")

if recommendations:
    # Find the most significant recommendations
    quality_rec = next((r for r in recommendations if r['metric'] == 'EntryQuality'), None)
    confluence_rec = next((r for r in recommendations if r['metric'] == 'EntryConfluence'), None)
    
    if quality_rec:
        threshold = quality_rec['threshold']
        print(f"MinQuality = {threshold:.0f};  // {quality_rec['direction']} baseline: {threshold:.1f}")
    else:
        print(f"MinQuality = 65.0;  // Default (no strong correlation found)")
    
    if confluence_rec:
        threshold = confluence_rec['threshold']
        print(f"MinConfluence = {threshold:.0f};  // {confluence_rec['direction']} baseline: {threshold:.1f}")
    else:
        print(f"MinConfluence = 70.0;  // Default (no strong correlation found)")
else:
    print("MinQuality = 65.0;  // Default")
    print("MinConfluence = 70.0;  // Default")

if 'zone_recommendations' in locals() and zone_recommendations:
    avoid_zones = [r['zone'] for r in zone_recommendations if r['action'] == 'AVOID']
    if avoid_zones:
        print(f"\nUseZoneFilter = true;")
        print(f"// AVOID zones: {', '.join(avoid_zones)}")

if 'regime_recommendations' in locals() and regime_recommendations:
    avoid_regimes = [r['regime'] for r in regime_recommendations if r['action'] == 'AVOID']
    if avoid_regimes:
        print(f"\nUseRegimeFilter = true;")
        print(f"// AVOID regimes: {', '.join(avoid_regimes)}")

# === EXPECTED IMPROVEMENT ===
print("\n" + "="*100)
print("  📊 EXPECTED IMPROVEMENT ESTIMATE")
print("="*100 + "\n")

print("Current Performance:")
print(f"  Win Rate:     {len(wins)/len(df)*100:.1f}%")
print(f"  Total Trades: {len(df)}")
print(f"  Net P&L:      ${df['Profit'].sum():.2f}")
print(f"  Avg Trade:    ${df['Profit'].mean():.2f}")

# Simulate filtering
if recommendations:
    # Apply the most significant filter
    best_rec = max(recommendations, key=lambda x: abs(x['improvement']))
    metric = best_rec['metric']
    threshold = best_rec['threshold']
    
    if best_rec['direction'] == 'above':
        filtered_df = df[df[metric] > threshold]
    else:
        filtered_df = df[df[metric] < threshold]
    
    filtered_wins = filtered_df[filtered_df['Profit'] > 0]
    
    print(f"\nProjected Performance (with {metric} filter):")
    print(f"  Win Rate:     {len(filtered_wins)/len(filtered_df)*100:.1f}% ({len(filtered_wins)/len(filtered_df)*100 - len(wins)/len(df)*100:+.1f}%)")
    print(f"  Total Trades: {len(filtered_df)} ({len(filtered_df) - len(df):+d} trades)")
    print(f"  Net P&L:      ${filtered_df['Profit'].sum():.2f} (${filtered_df['Profit'].sum() - df['Profit'].sum():+.2f})")
    print(f"  Avg Trade:    ${filtered_df['Profit'].mean():.2f} (${filtered_df['Profit'].mean() - df['Profit'].mean():+.2f})")

print("\n" + "="*100)
print("  ✅ ANALYSIS COMPLETE - Ready for EA v2.5 optimization!")
print("="*100 + "\n")

print("💡 NEXT STEPS:")
print("   1. Review recommendations above")
print("   2. Update EA configuration with suggested thresholds")
print("   3. Run new backtest (v2.5) with physics filters enabled")
print("   4. Compare baseline (v2.4) vs optimized (v2.5) results")
print("   5. Generate partner dashboard with before/after comparison\n")
