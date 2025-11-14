#!/usr/bin/env python3
"""
Compare v2.4 (Baseline) vs v2.5 (Physics-Optimized)
Quick performance comparison for partner presentation
"""
import pandas as pd
from pathlib import Path

# === CONFIGURATION ===
TESTER_DIR = Path("/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester")
SYMBOL = "NAS100"

V24_CSV = list(TESTER_DIR.glob("**/MQL5/Files/TP_Integrated_Trades_NAS100_v2.4.csv"))[0]
V25_CSV_PATTERN = "**/MQL5/Files/TP_Integrated_Trades_NAS100_v2.5.csv"

print("\n" + "="*100)
print("  📊 TICKPHYSICS PERFORMANCE COMPARISON - v2.4 (Baseline) vs v2.5 (Optimized)")
print("="*100 + "\n")

# Load v2.4 (baseline)
df_24 = pd.read_csv(V24_CSV)
print(f"✅ Loaded v2.4 baseline: {len(df_24)} trades\n")

# Try to load v2.5
v25_files = list(TESTER_DIR.glob(V25_CSV_PATTERN))
if not v25_files:
    print("⚠️  v2.5 CSV not found - run backtest first!")
    print(f"   Expected pattern: {V25_CSV_PATTERN}\n")
    exit(1)

df_25 = pd.read_csv(v25_files[0])
print(f"✅ Loaded v2.5 optimized: {len(df_25)} trades\n")

# Calculate metrics
def calc_metrics(df, version):
    wins = df[df['Profit'] > 0]
    losses = df[df['Profit'] <= 0]
    
    return {
        'version': version,
        'trades': len(df),
        'wins': len(wins),
        'losses': len(losses),
        'win_rate': len(wins) / len(df) * 100 if len(df) > 0 else 0,
        'total_pnl': df['Profit'].sum(),
        'avg_profit': df['Profit'].mean(),
        'avg_win': wins['Profit'].mean() if len(wins) > 0 else 0,
        'avg_loss': losses['Profit'].mean() if len(losses) > 0 else 0,
        'profit_factor': abs(wins['Profit'].sum() / losses['Profit'].sum()) if losses['Profit'].sum() != 0 else 0,
        'max_dd': df['DrawdownPercent'].min() if 'DrawdownPercent' in df.columns else 0,
        'avg_mfe': df['MFE_Pips'].mean() if 'MFE_Pips' in df.columns else 0,
        'avg_mae': df['MAE_Pips'].mean() if 'MAE_Pips' in df.columns else 0,
    }

metrics_24 = calc_metrics(df_24, "v2.4 (Baseline)")
metrics_25 = calc_metrics(df_25, "v2.5 (Optimized)")

# Print comparison
print("="*100)
print("  📈 PERFORMANCE METRICS COMPARISON")
print("="*100 + "\n")

print(f"{'Metric':<25} | {'v2.4 Baseline':<20} | {'v2.5 Optimized':<20} | {'Improvement':<20}")
print("-"*100)

# Trade count
diff = metrics_25['trades'] - metrics_24['trades']
pct = (diff / metrics_24['trades'] * 100) if metrics_24['trades'] > 0 else 0
print(f"{'Total Trades':<25} | {metrics_24['trades']:>18}   | {metrics_25['trades']:>18}   | {diff:>+7} ({pct:>+6.1f}%)")

# Win rate
diff = metrics_25['win_rate'] - metrics_24['win_rate']
print(f"{'Win Rate':<25} | {metrics_24['win_rate']:>17.1f}%  | {metrics_25['win_rate']:>17.1f}%  | {diff:>+18.1f}%")

# Total P&L
diff = metrics_25['total_pnl'] - metrics_24['total_pnl']
pct = (diff / abs(metrics_24['total_pnl']) * 100) if metrics_24['total_pnl'] != 0 else 0
print(f"{'Net P&L':<25} | ${metrics_24['total_pnl']:>17.2f}  | ${metrics_25['total_pnl']:>17.2f}  | ${diff:>+7.2f} ({pct:>+6.1f}%)")

# Avg Trade
diff = metrics_25['avg_profit'] - metrics_24['avg_profit']
print(f"{'Avg Profit/Trade':<25} | ${metrics_24['avg_profit']:>17.2f}  | ${metrics_25['avg_profit']:>17.2f}  | ${diff:>+16.2f}")

# Avg Win
diff = metrics_25['avg_win'] - metrics_24['avg_win']
print(f"{'Avg Win':<25} | ${metrics_24['avg_win']:>17.2f}  | ${metrics_25['avg_win']:>17.2f}  | ${diff:>+16.2f}")

# Avg Loss
diff = metrics_25['avg_loss'] - metrics_24['avg_loss']
print(f"{'Avg Loss':<25} | ${metrics_24['avg_loss']:>17.2f}  | ${metrics_25['avg_loss']:>17.2f}  | ${diff:>+16.2f}")

# Profit Factor
diff = metrics_25['profit_factor'] - metrics_24['profit_factor']
print(f"{'Profit Factor':<25} | {metrics_24['profit_factor']:>18.2f}  | {metrics_25['profit_factor']:>18.2f}  | {diff:>+18.2f}")

# Max Drawdown
diff = metrics_25['max_dd'] - metrics_24['max_dd']
print(f"{'Max Drawdown':<25} | {metrics_24['max_dd']:>17.1f}%  | {metrics_25['max_dd']:>17.1f}%  | {diff:>+18.1f}%")

# MFE/MAE
diff = metrics_25['avg_mfe'] - metrics_24['avg_mfe']
print(f"{'Avg MFE (pips)':<25} | {metrics_24['avg_mfe']:>18.1f}  | {metrics_25['avg_mfe']:>18.1f}  | {diff:>+18.1f}")

diff = metrics_25['avg_mae'] - metrics_24['avg_mae']
print(f"{'Avg MAE (pips)':<25} | {metrics_24['avg_mae']:>18.1f}  | {metrics_25['avg_mae']:>18.1f}  | {diff:>+18.1f}")

# Exit reason breakdown
print("\n" + "="*100)
print("  📍 EXIT REASON COMPARISON")
print("="*100 + "\n")

if 'ExitReason' in df_24.columns and 'ExitReason' in df_25.columns:
    exit_24 = df_24['ExitReason'].value_counts()
    exit_25 = df_25['ExitReason'].value_counts()
    
    all_reasons = set(exit_24.index) | set(exit_25.index)
    
    print(f"{'Exit Reason':<15} | {'v2.4 Count':<12} | {'v2.4 %':<10} | {'v2.5 Count':<12} | {'v2.5 %':<10}")
    print("-"*100)
    
    for reason in sorted(all_reasons):
        count_24 = exit_24.get(reason, 0)
        count_25 = exit_25.get(reason, 0)
        pct_24 = (count_24 / len(df_24) * 100) if len(df_24) > 0 else 0
        pct_25 = (count_25 / len(df_25) * 100) if len(df_25) > 0 else 0
        
        print(f"{reason:<15} | {count_24:>12} | {pct_24:>9.1f}% | {count_25:>12} | {pct_25:>9.1f}%")

# Regime/Zone analysis for v2.5
print("\n" + "="*100)
print("  🌡️  v2.5 FILTER EFFECTIVENESS")
print("="*100 + "\n")

if 'EntryRegime' in df_25.columns:
    print("Volatility Regime Distribution:")
    regime_stats = df_25.groupby('EntryRegime').agg({
        'Profit': ['count', 'mean', 'sum']
    }).round(2)
    
    for regime in df_25['EntryRegime'].unique():
        regime_df = df_25[df_25['EntryRegime'] == regime]
        count = len(regime_df)
        pct = (count / len(df_25) * 100)
        avg = regime_df['Profit'].mean()
        win_rate = (regime_df['Profit'] > 0).sum() / len(regime_df) * 100
        
        print(f"   {regime:<10} | {count:>4} trades ({pct:>5.1f}%) | Avg: ${avg:>7.2f} | Win Rate: {win_rate:>5.1f}%")

if 'EntryZone' in df_25.columns:
    print("\nTrading Zone Distribution:")
    for zone in df_25['EntryZone'].unique():
        zone_df = df_25[df_25['EntryZone'] == zone]
        count = len(zone_df)
        pct = (count / len(df_25) * 100)
        avg = zone_df['Profit'].mean()
        win_rate = (zone_df['Profit'] > 0).sum() / len(zone_df) * 100
        
        print(f"   {zone:<15} | {count:>4} trades ({pct:>5.1f}%) | Avg: ${avg:>7.2f} | Win Rate: {win_rate:>5.1f}%")

# Final verdict
print("\n" + "="*100)
print("  🎯 OPTIMIZATION VERDICT")
print("="*100 + "\n")

# Calculate improvement score
improvement_score = 0

if metrics_25['win_rate'] > metrics_24['win_rate']:
    improvement_score += 1
    print("✅ Win Rate IMPROVED: {:.1f}% → {:.1f}% (+{:.1f}%)".format(
        metrics_24['win_rate'], metrics_25['win_rate'], 
        metrics_25['win_rate'] - metrics_24['win_rate']))
else:
    print("❌ Win Rate DECLINED")

if metrics_25['total_pnl'] > metrics_24['total_pnl']:
    improvement_score += 1
    print("✅ Net P&L IMPROVED: ${:.2f} → ${:.2f} (+${:.2f})".format(
        metrics_24['total_pnl'], metrics_25['total_pnl'],
        metrics_25['total_pnl'] - metrics_24['total_pnl']))
else:
    print("❌ Net P&L DECLINED")

if metrics_25['avg_profit'] > metrics_24['avg_profit']:
    improvement_score += 1
    print("✅ Avg Trade IMPROVED: ${:.2f} → ${:.2f} (+${:.2f})".format(
        metrics_24['avg_profit'], metrics_25['avg_profit'],
        metrics_25['avg_profit'] - metrics_24['avg_profit']))
else:
    print("❌ Avg Trade DECLINED")

if metrics_25['profit_factor'] > metrics_24['profit_factor']:
    improvement_score += 1
    print("✅ Profit Factor IMPROVED: {:.2f} → {:.2f}".format(
        metrics_24['profit_factor'], metrics_25['profit_factor']))
else:
    print("❌ Profit Factor DECLINED")

print(f"\n📊 Overall Improvement Score: {improvement_score}/4")

if improvement_score >= 3:
    print("\n🎉 SUCCESS! v2.5 physics optimization is working!")
    print("   → Recommend: Proceed to partner dashboard & live testing")
elif improvement_score == 2:
    print("\n⚠️  MIXED RESULTS - Further optimization needed")
    print("   → Recommend: Review filter thresholds or add time-of-day filter")
else:
    print("\n❌ OPTIMIZATION FAILED - Filters may be too aggressive")
    print("   → Recommend: Relax filter criteria or revert to baseline")

print("\n" + "="*100 + "\n")
