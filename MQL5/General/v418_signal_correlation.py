#!/usr/bin/env python3
"""
Signal-to-Trade Correlation Analysis
Matches signals with trades to find optimal thresholds for physics metrics
"""
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime

# === FILE PATHS ===
DESKTOP_FOLDER = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's")
SIGNALS_CSV = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_signals.csv"
TRADES_CSV = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_trades.csv"

print("\n" + "="*80)
print("  🔬 SIGNAL-TO-TRADE CORRELATION ANALYSIS - THRESHOLD OPTIMIZATION")
print("="*80 + "\n")

# === LOAD DATA ===
print("📂 Loading data...\n")
df_signals = pd.read_csv(SIGNALS_CSV)
df_trades = pd.read_csv(TRADES_CSV)

# Parse timestamps for matching
df_signals['Timestamp'] = pd.to_datetime(df_signals['Timestamp'])
df_trades['OpenTime'] = pd.to_datetime(df_trades['OpenTime'])

print(f"✅ Loaded {len(df_signals)} signals")
print(f"✅ Loaded {len(df_trades)} trades\n")

# === MATCH SIGNALS TO TRADES ===
print("="*80)
print("  🔗 MATCHING SIGNALS TO TRADES")
print("="*80 + "\n")

# Strategy: Match by timestamp proximity (within 5 minutes = 1 bar on M05)
matched_data = []
unmatched_trades = 0

for idx, trade in df_trades.iterrows():
    # Find signal within 5 minutes of trade open
    time_diff = abs((df_signals['Timestamp'] - trade['OpenTime']).dt.total_seconds())
    closest_idx = time_diff.idxmin()
    
    if time_diff[closest_idx] <= 300:  # 5 minutes = 300 seconds
        signal = df_signals.iloc[closest_idx]
        matched_data.append({
            # Trade data
            'Type': trade['Type'],
            'Profit': trade['Profit'],
            'Win': trade['Profit'] > 0,
            'Pips': trade['Pips'],
            # Signal physics data
            'Momentum': signal['Momentum'],
            'Speed': signal['Speed'],
            'Acceleration': signal['Acceleration'],
            'MomentumSlope': signal['MomentumSlope'],
            'SpeedSlope': signal['SpeedSlope'],
            'AccelerationSlope': signal['AccelerationSlope'],
            'Quality': signal['Quality'],
            'PhysicsScore': signal['PhysicsScore'],
            'Confluence': signal['Confluence'],
        })
    else:
        unmatched_trades += 1

df_matched = pd.DataFrame(matched_data)
print(f"✅ Matched {len(df_matched)} trades to signals ({(len(df_matched)/len(df_trades)*100):.1f}%)")
if unmatched_trades > 0:
    print(f"⚠️  {unmatched_trades} trades could not be matched\n")

# === ANALYZE BUY TRADES ===
print("="*80)
print("  📈 BUY TRADE ANALYSIS - OPTIMAL THRESHOLDS")
print("="*80 + "\n")

buy_trades = df_matched[df_matched['Type'] == 'BUY']
buy_wins = buy_trades[buy_trades['Win'] == True]
buy_losses = buy_trades[buy_trades['Win'] == False]

print(f"BUY Trades: {len(buy_trades)} ({len(buy_wins)} wins @ {len(buy_wins)/len(buy_trades)*100:.1f}%)\n")

metrics = ['Speed', 'Acceleration', 'Momentum', 'SpeedSlope', 'AccelerationSlope', 'MomentumSlope']
buy_thresholds = {}

for metric in metrics:
    if metric in buy_trades.columns:
        win_avg = buy_wins[metric].mean()
        loss_avg = buy_losses[metric].mean()
        win_median = buy_wins[metric].median()
        loss_median = buy_losses[metric].median()
        
        # Find threshold that maximizes win rate
        # Use median of losses as conservative threshold
        suggested_threshold = loss_median
        
        buy_thresholds[metric] = suggested_threshold
        
        print(f"{metric:20}")
        print(f"  Winners:  Avg={win_avg:8.2f}  Median={win_median:8.2f}")
        print(f"  Losers:   Avg={loss_avg:8.2f}  Median={loss_median:8.2f}")
        print(f"  💡 Suggested threshold: {suggested_threshold:8.2f}")
        print()

# === ANALYZE SELL TRADES ===
print("="*80)
print("  📉 SELL TRADE ANALYSIS - OPTIMAL THRESHOLDS")
print("="*80 + "\n")

sell_trades = df_matched[df_matched['Type'] == 'SELL']
sell_wins = sell_trades[sell_trades['Win'] == True]
sell_losses = sell_trades[sell_trades['Win'] == False]

print(f"SELL Trades: {len(sell_trades)} ({len(sell_wins)} wins @ {len(sell_wins)/len(sell_trades)*100:.1f}%)\n")

sell_thresholds = {}

for metric in metrics:
    if metric in sell_trades.columns:
        win_avg = sell_wins[metric].mean()
        loss_avg = sell_losses[metric].mean()
        win_median = sell_wins[metric].median()
        loss_median = sell_losses[metric].median()
        
        # For SELL, we want MORE NEGATIVE values
        suggested_threshold = loss_median
        
        sell_thresholds[metric] = suggested_threshold
        
        print(f"{metric:20}")
        print(f"  Winners:  Avg={win_avg:8.2f}  Median={win_median:8.2f}")
        print(f"  Losers:   Avg={loss_avg:8.2f}  Median={loss_median:8.2f}")
        print(f"  💡 Suggested threshold: {suggested_threshold:8.2f}")
        print()

# === BACKTESTING OPTIMIZED THRESHOLDS ===
print("="*80)
print("  🧪 SIMULATED RESULTS WITH OPTIMIZED THRESHOLDS")
print("="*80 + "\n")

print("Testing: What if we applied these thresholds to Phase 1 data?\n")

# Simulate filtering with new thresholds
def would_pass_filters(row, thresholds_dict):
    if row['Type'] == 'BUY':
        return (
            row['Speed'] >= thresholds_dict['Speed'] and
            row['Acceleration'] >= thresholds_dict['Acceleration'] and
            row['Momentum'] >= thresholds_dict['Momentum']
        )
    else:  # SELL
        return (
            row['Speed'] <= thresholds_dict['Speed'] and
            row['Acceleration'] <= thresholds_dict['Acceleration'] and
            row['Momentum'] <= thresholds_dict['Momentum']
        )

df_matched['PassesOptimized'] = df_matched.apply(
    lambda row: would_pass_filters(row, buy_thresholds if row['Type'] == 'BUY' else sell_thresholds),
    axis=1
)

filtered_trades = df_matched[df_matched['PassesOptimized']]
filtered_wins = filtered_trades[filtered_trades['Win'] == True]

print(f"Current Phase 1 Results:")
print(f"  Trades:     {len(df_matched)}")
print(f"  Wins:       {len(df_matched[df_matched['Win']])} ({len(df_matched[df_matched['Win']])/len(df_matched)*100:.1f}%)")
print(f"  Total P&L:  ${df_matched['Profit'].sum():.2f}\n")

print(f"Simulated Optimized Results:")
print(f"  Trades:     {len(filtered_trades)} ({len(filtered_trades)/len(df_matched)*100:.1f}% kept)")
print(f"  Wins:       {len(filtered_wins)} ({len(filtered_wins)/len(filtered_trades)*100:.1f}% win rate)")
print(f"  Total P&L:  ${filtered_trades['Profit'].sum():.2f}")
print(f"  Improvement: {filtered_trades['Profit'].sum() - df_matched['Profit'].sum():.2f}")

win_rate_improvement = (len(filtered_wins)/len(filtered_trades)*100) - (len(df_matched[df_matched['Win']])/len(df_matched)*100)
print(f"  Win Rate Δ: {win_rate_improvement:+.1f}%\n")

# === RECOMMENDED SETTINGS ===
print("="*80)
print("  ⚙️  RECOMMENDED EA SETTINGS FOR v4.1.8.1")
print("="*80 + "\n")

print("Copy these values into TP_Integrated_EA_Crossover_4_1_8_1.mq5:\n")

print(f"// BUY Thresholds")
print(f"input double MinSpeedBuy         = {buy_thresholds['Speed']:.1f};")
print(f"input double MinAccelerationBuy  = {buy_thresholds['Acceleration']:.1f};")
print(f"input double MinMomentumBuy      = {buy_thresholds['Momentum']:.1f};")
print()
print(f"// SELL Thresholds (negative values)")
print(f"input double MinSpeedSell        = {sell_thresholds['Speed']:.1f};")
print(f"input double MinAccelerationSell = {sell_thresholds['Acceleration']:.1f};")
print(f"input double MinMomentumSell     = {sell_thresholds['Momentum']:.1f};")
print()

# === SLOPE ANALYSIS ===
print("="*80)
print("  📐 SLOPE METRIC ANALYSIS")
print("="*80 + "\n")

print("Slope metrics show if physics are IMPROVING (positive slope) or WEAKENING (negative slope)\n")

for slope_metric in ['SpeedSlope', 'AccelerationSlope', 'MomentumSlope']:
    if slope_metric in df_matched.columns:
        wins_slope = df_matched[df_matched['Win'] == True][slope_metric].mean()
        loss_slope = df_matched[df_matched['Win'] == False][slope_metric].mean()
        
        print(f"{slope_metric:20} | Wins: {wins_slope:7.2f} | Losses: {loss_slope:7.2f} | Diff: {wins_slope-loss_slope:7.2f}")

print("\n💡 Positive slope = metric getting stronger (better for entry)")
print("💡 If winner slopes > loser slopes, consider adding slope filters\n")

# === SUMMARY ===
print("="*80)
print("  ✅ ANALYSIS COMPLETE")
print("="*80 + "\n")

print("Next Steps:")
print("1. Update TP_Integrated_EA_Crossover_4_1_8_1.mq5 with recommended thresholds")
print("2. Compile and run Phase 2 backtest (NAS100 M05, 2025 YTD)")
print("3. Compare Phase 2 results vs Phase 1 baseline")
print("4. If improved, test on US30 and GER40 with same settings\n")

print("="*80 + "\n")
