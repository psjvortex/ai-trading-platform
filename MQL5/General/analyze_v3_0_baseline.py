#!/usr/bin/env python3
"""
TickPhysics v3.0 BASELINE Analysis
Pure MA Crossover - No Stops, No Filters
Full Exposure Test to Measure Optimization Effectiveness
"""
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime

print("\n" + "="*80)
print("  🔬 TICKPHYSICS v3.0 BASELINE ANALYSIS")
print("  Pure MA 10/50 EMA Crossover - NO STOPS, NO FILTERS")
print("="*80 + "\n")

# Load data
mt5_df = pd.read_csv('MTBacktest_Report_3.0.csv')
trades_df = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0.csv')
signals_df = pd.read_csv('TP_Integrated_Signals_NAS100_v3.0.csv')

print(f"📊 Data Loaded:")
print(f"   MT5 Report:  {len(mt5_df)} deals")
print(f"   TP Trades:   {len(trades_df)} trades")
print(f"   TP Signals:  {len(signals_df)} signals\n")

# ===================================================================
# SECTION 1: MT5 OFFICIAL BACKTEST RESULTS
# ===================================================================
print("="*80)
print("  📈 MT5 OFFICIAL BACKTEST RESULTS")
print("="*80 + "\n")

# Parse MT5 data
exit_deals = mt5_df[mt5_df['Direction'] == 'out'].copy()
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

print(f"Test Period:      {mt5_df['Time'].iloc[0]} → {mt5_df['Time'].iloc[-1]}")
print(f"Starting Balance: $1,000.00")
print(f"Ending Balance:   ${exit_deals['Balance'].iloc[-1]:.2f}")
print(f"\nTrade Performance:")
print(f"  Total Trades:   {total_trades}")
print(f"  Wins:           {wins} ({win_rate:.1f}%)")
print(f"  Losses:         {losses} ({100-win_rate:.1f}%)")
print(f"\nProfit Analysis:")
print(f"  Gross Profit:   ${gross_profit:.2f}")
print(f"  Gross Loss:     ${gross_loss:.2f}")
print(f"  Net P&L:        ${net_profit:.2f}")
print(f"  Profit Factor:  {profit_factor:.2f}")
print(f"\nRisk/Reward:")
print(f"  Avg Win:        ${avg_win:.2f}")
print(f"  Avg Loss:       ${avg_loss:.2f}")
print(f"  R:R Ratio:      {rr_ratio:.2f}:1")

# ===================================================================
# SECTION 2: TICKPHYSICS TRADE ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🎯 TICKPHYSICS TRADE ANALYSIS")
print("="*80 + "\n")

# Exit reasons
print("Exit Reason Breakdown:")
exit_counts = trades_df['ExitReason'].value_counts()
for reason, count in exit_counts.items():
    pct = (count / len(trades_df) * 100)
    print(f"  {reason:<15} {count:>3} trades ({pct:>5.1f}%)")

# MFE/MAE Analysis
print(f"\nMFE/MAE Analysis (Max Favorable/Adverse Excursion):")
print(f"  Avg MFE:        {trades_df['MFE_Pips'].mean():.2f} pips")
print(f"  Avg MAE:        {trades_df['MAE_Pips'].mean():.2f} pips")
print(f"  MFE > Profit:   {len(trades_df[trades_df['MFE_Pips'] > trades_df['Pips']])} trades ({len(trades_df[trades_df['MFE_Pips'] > trades_df['Pips']])/len(trades_df)*100:.1f}%)")
print(f"  MAE > Loss:     {len(trades_df[trades_df['MAE_Pips'] < trades_df['Pips']])} trades ({len(trades_df[trades_df['MAE_Pips'] < trades_df['Pips']])/len(trades_df)*100:.1f}%)")

# RunUp/RunDown Analysis
print(f"\nRunUp/RunDown Analysis (Post-Exit Price Movement):")
print(f"  Avg RunUp:      {trades_df['RunUp_Pips'].mean():.2f} pips")
print(f"  Avg RunDown:    {trades_df['RunDown_Pips'].mean():.2f} pips")
print(f"  Opportunity Cost: {(trades_df['RunUp_Pips'].mean() - trades_df['Pips'].mean()):.2f} pips left on table")

# Hold time analysis
print(f"\nHold Time Analysis:")
print(f"  Avg Hold:       {trades_df['HoldTimeBars'].mean():.1f} bars ({trades_df['HoldTimeMinutes'].mean():.0f} minutes)")
print(f"  Min Hold:       {trades_df['HoldTimeBars'].min()} bars")
print(f"  Max Hold:       {trades_df['HoldTimeBars'].max()} bars")

# ===================================================================
# SECTION 3: PHYSICS METRICS CORRELATION ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🔬 PHYSICS METRICS CORRELATION ANALYSIS")
print("="*80 + "\n")

# Classify trades
trades_df['IsWin'] = trades_df['Profit'] > 0
winners = trades_df[trades_df['IsWin']]
losers = trades_df[~trades_df['IsWin']]

print(f"Comparing Winners vs Losers:\n")

# Quality Analysis
print("📊 QUALITY (Physics Consistency):")
print(f"  Winners Avg:    {winners['EntryQuality'].mean():.1f}")
print(f"  Losers Avg:     {losers['EntryQuality'].mean():.1f}")
print(f"  Difference:     {winners['EntryQuality'].mean() - losers['EntryQuality'].mean():.1f}")
quality_corr = trades_df[['EntryQuality', 'Profit']].corr().iloc[0, 1]
print(f"  Correlation:    {quality_corr:.3f} {'✅ STRONG' if abs(quality_corr) > 0.3 else '⚠️ WEAK'}")

# Confluence Analysis
print(f"\n📊 CONFLUENCE (Multi-Timeframe Agreement):")
print(f"  Winners Avg:    {winners['EntryConfluence'].mean():.1f}")
print(f"  Losers Avg:     {losers['EntryConfluence'].mean():.1f}")
print(f"  Difference:     {winners['EntryConfluence'].mean() - losers['EntryConfluence'].mean():.1f}")
conf_corr = trades_df[['EntryConfluence', 'Profit']].corr().iloc[0, 1]
print(f"  Correlation:    {conf_corr:.3f} {'✅ STRONG' if abs(conf_corr) > 0.3 else '⚠️ WEAK'}")

# Momentum Analysis
print(f"\n📊 MOMENTUM (Trend Strength):")
print(f"  Winners Avg:    {winners['EntryMomentum'].mean():.1f}")
print(f"  Losers Avg:     {losers['EntryMomentum'].mean():.1f}")
print(f"  Difference:     {winners['EntryMomentum'].mean() - losers['EntryMomentum'].mean():.1f}")
mom_corr = trades_df[['EntryMomentum', 'Profit']].corr().iloc[0, 1]
print(f"  Correlation:    {mom_corr:.3f} {'✅ STRONG' if abs(mom_corr) > 0.3 else '⚠️ WEAK'}")

# Entropy Analysis
print(f"\n📊 ENTROPY (Market Disorder/Randomness):")
print(f"  Winners Avg:    {winners['EntryEntropy'].mean():.1f}")
print(f"  Losers Avg:     {losers['EntryEntropy'].mean():.1f}")
print(f"  Difference:     {winners['EntryEntropy'].mean() - losers['EntryEntropy'].mean():.1f}")
ent_corr = trades_df[['EntryEntropy', 'Profit']].corr().iloc[0, 1]
print(f"  Correlation:    {ent_corr:.3f} {'✅ STRONG' if abs(ent_corr) > 0.3 else '⚠️ WEAK'}")

# ===================================================================
# SECTION 4: ZONE & REGIME ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  🌍 ZONE & REGIME PERFORMANCE ANALYSIS")
print("="*80 + "\n")

# Zone Performance
print("Trading Zone Performance:")
zone_stats = trades_df.groupby('EntryZone').agg({
    'Profit': ['count', 'sum', lambda x: (x > 0).sum()],
    'Pips': 'mean'
}).round(2)
zone_stats.columns = ['Trades', 'Total_PnL', 'Wins', 'Avg_Pips']
zone_stats['WinRate'] = (zone_stats['Wins'] / zone_stats['Trades'] * 100).round(1)
zone_stats['Avg_PnL'] = (zone_stats['Total_PnL'] / zone_stats['Trades']).round(2)

for zone in zone_stats.index:
    row = zone_stats.loc[zone]
    print(f"  {zone:<15} {int(row['Trades']):>3} trades | WR: {row['WinRate']:>5.1f}% | Avg P&L: ${row['Avg_PnL']:>7.2f} | Avg Pips: {row['Avg_Pips']:>7.2f}")

# Regime Performance
print(f"\nVolatility Regime Performance:")
regime_stats = trades_df.groupby('EntryRegime').agg({
    'Profit': ['count', 'sum', lambda x: (x > 0).sum()],
    'Pips': 'mean'
}).round(2)
regime_stats.columns = ['Trades', 'Total_PnL', 'Wins', 'Avg_Pips']
regime_stats['WinRate'] = (regime_stats['Wins'] / regime_stats['Trades'] * 100).round(1)
regime_stats['Avg_PnL'] = (regime_stats['Total_PnL'] / regime_stats['Trades']).round(2)

for regime in regime_stats.index:
    row = regime_stats.loc[regime]
    print(f"  {regime:<15} {int(row['Trades']):>3} trades | WR: {row['WinRate']:>5.1f}% | Avg P&L: ${row['Avg_PnL']:>7.2f} | Avg Pips: {row['Avg_Pips']:>7.2f}")

# ===================================================================
# SECTION 5: TIME-OF-DAY ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  ⏰ TIME-OF-DAY PERFORMANCE ANALYSIS")
print("="*80 + "\n")

print("Hourly Performance (Entry Hour):")
hour_stats = trades_df.groupby('EntryHour').agg({
    'Profit': ['count', lambda x: (x > 0).sum()],
}).round(2)
hour_stats.columns = ['Trades', 'Wins']
hour_stats['WinRate'] = (hour_stats['Wins'] / hour_stats['Trades'] * 100).round(1)
hour_stats = hour_stats.sort_values('Trades', ascending=False)

print(f"\n{'Hour':<6} {'Trades':<8} {'WinRate':<10} {'Status'}")
print("-" * 40)
for hour in hour_stats.head(15).index:
    row = hour_stats.loc[hour]
    status = "✅ STRONG" if row['Trades'] >= 10 and row['WinRate'] > 40 else ("⚠️ WEAK" if row['WinRate'] < 25 else "📊 AVERAGE")
    print(f"{int(hour):>4}h  {int(row['Trades']):<8} {row['WinRate']:>5.1f}%     {status}")

# ===================================================================
# SECTION 6: SIGNAL ANALYSIS
# ===================================================================
print("\n" + "="*80)
print("  📡 SIGNAL GENERATION ANALYSIS")
print("="*80 + "\n")

total_signals = len(signals_df)
buy_signals = len(signals_df[signals_df['SignalType'] == 'BUY'])
sell_signals = len(signals_df[signals_df['SignalType'] == 'SELL'])
none_signals = len(signals_df[signals_df['SignalType'] == 'NONE'])

print(f"Total Signals Generated: {total_signals}")
print(f"  BUY Signals:   {buy_signals} ({buy_signals/total_signals*100:.1f}%)")
print(f"  SELL Signals:  {sell_signals} ({sell_signals/total_signals*100:.1f}%)")
print(f"  NO Signal:     {none_signals} ({none_signals/total_signals*100:.1f}%)")
print(f"\nSignal → Trade Conversion:")
print(f"  Total Trade Signals: {buy_signals + sell_signals}")
print(f"  Actual Trades:       {total_trades}")
print(f"  Conversion Rate:     {total_trades/(buy_signals + sell_signals)*100:.1f}%")

# Physics Pass/Reject in signals
physics_pass = len(signals_df[signals_df['PhysicsPass'] == 'PASS'])
physics_reject = len(signals_df[signals_df['PhysicsPass'] == 'REJECT'])
print(f"\nPhysics Filter Analysis (NOT APPLIED - BASELINE):")
print(f"  Would Pass:    {physics_pass} signals ({physics_pass/total_signals*100:.1f}%)")
print(f"  Would Reject:  {physics_reject} signals ({physics_reject/total_signals*100:.1f}%)")

# ===================================================================
# SECTION 7: OPTIMIZATION RECOMMENDATIONS
# ===================================================================
print("\n" + "="*80)
print("  💡 OPTIMIZATION RECOMMENDATIONS FOR v3.1")
print("="*80 + "\n")

recommendations = []

# 1. Zone filtering
worst_zone = zone_stats.nsmallest(1, 'WinRate').index[0]
worst_zone_wr = zone_stats.loc[worst_zone, 'WinRate']
if worst_zone_wr < 30:
    recommendations.append(f"🎯 AVOID {worst_zone} zone (WR: {worst_zone_wr:.1f}%) - UseZoneFilter=true")

# 2. Regime filtering
worst_regime = regime_stats.nsmallest(1, 'WinRate').index[0]
worst_regime_wr = regime_stats.loc[worst_regime, 'WinRate']
if worst_regime_wr < 30:
    recommendations.append(f"🎯 AVOID {worst_regime} regime (WR: {worst_regime_wr:.1f}%) - UseRegimeFilter=true")

# 3. Physics thresholds
if quality_corr > 0.1:
    quality_threshold = winners['EntryQuality'].quantile(0.25)
    recommendations.append(f"📊 INCREASE MinQuality to {quality_threshold:.0f} (current winners avg: {winners['EntryQuality'].mean():.1f})")

if conf_corr > 0.1:
    conf_threshold = winners['EntryConfluence'].quantile(0.25)
    recommendations.append(f"📊 INCREASE MinConfluence to {conf_threshold:.0f} (current winners avg: {winners['EntryConfluence'].mean():.1f})")

# 4. Time filtering
best_hours = hour_stats[hour_stats['WinRate'] > 40].index.tolist()
worst_hours = hour_stats[hour_stats['WinRate'] < 25].index.tolist()
if best_hours:
    recommendations.append(f"⏰ ALLOW trading hours: {','.join(map(str, sorted(best_hours)))}")
if worst_hours:
    recommendations.append(f"⏰ BLOCK trading hours: {','.join(map(str, sorted(worst_hours)))}")

# 5. Stop loss/TP consideration
avg_mae_loss = losers['MAE_Pips'].mean()
avg_mfe_win = winners['MFE_Pips'].mean()
if avg_mae_loss < -50:
    recommendations.append(f"🛡️ CONSIDER adding StopLoss: {abs(avg_mae_loss)*1.2:.0f} pips (avg MAE: {avg_mae_loss:.1f})")
if avg_mfe_win > 100:
    recommendations.append(f"💰 CONSIDER adding TakeProfit: {avg_mfe_win*0.7:.0f} pips (avg MFE: {avg_mfe_win:.1f})")

print("Priority Optimizations:\n")
for i, rec in enumerate(recommendations[:5], 1):
    print(f"{i}. {rec}")

# ===================================================================
# SECTION 8: BASELINE SUMMARY
# ===================================================================
print("\n" + "="*80)
print("  📋 BASELINE SUMMARY - v3.0 PASS #1")
print("="*80 + "\n")

print(f"✅ BASELINE ESTABLISHED:")
print(f"   Trades:        {total_trades}")
print(f"   Win Rate:      {win_rate:.1f}%")
print(f"   Profit Factor: {profit_factor:.2f}")
print(f"   R:R Ratio:     {rr_ratio:.2f}:1")
print(f"   Net P&L:       ${net_profit:.2f}")
print(f"\n🎯 OPTIMIZATION TARGETS (v3.1):")
print(f"   Win Rate:      35-40% (up from {win_rate:.1f}%)")
print(f"   Profit Factor: >1.15 (up from {profit_factor:.2f})")
print(f"   R:R Ratio:     ≥2.0:1 (current: {rr_ratio:.2f}:1)")
print(f"   Net P&L:       >$100 (up from ${net_profit:.2f})")

print("\n" + "="*80)
print("  ✅ ANALYSIS COMPLETE - READY FOR v3.1 OPTIMIZATION")
print("="*80 + "\n")
