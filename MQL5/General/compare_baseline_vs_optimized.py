#!/usr/bin/env python3
"""
📊 TickPhysics Performance Comparison: v2.4 (Baseline) vs v2.5 (Optimized)
- v2.4 = MA Crossover only (no physics filters)
- v2.5 = MA Crossover + Physics filters (regime + zone)
"""
import pandas as pd
import csv
from pathlib import Path
from datetime import datetime

print("\n" + "="*100)
print("  📊 TICKPHYSICS OPTIMIZATION ANALYSIS - BASELINE vs PHYSICS-OPTIMIZED")
print("="*100 + "\n")

# === PATHS ===
TESTER_DIR = Path("/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/MQL5/Files")
MT5_DROP = Path("/Users/patjohnston/Desktop/MT5 EA Backtest CSV Folder")

# Load TickPhysics CSVs
v24_trades = TESTER_DIR / "TP_Integrated_Trades_NAS100_v2.4.csv"
v25_trades = TESTER_DIR / "TP_Integrated_Trades_NAS100_v2.5.csv"

# Load MT5 reports
v24_mt5 = MT5_DROP / "MTBacktest_Report_2.4.csv"
v25_mt5 = MT5_DROP / "MTBacktest_Report_2.5.csv"

print("📂 Data Sources:\n")
print(f"   v2.4 Baseline:")
print(f"      TP CSV: {v24_trades.name}")
print(f"      MT5 Report: {v24_mt5.name}")
print(f"\n   v2.5 Optimized:")
print(f"      TP CSV: {v25_trades.name}")
print(f"      MT5 Report: {v25_mt5.name}")
print()

# === LOAD DATA ===
df_24 = pd.read_csv(v24_trades)
df_25 = pd.read_csv(v25_trades)

print("✅ Data loaded successfully\n")

# === CALCULATE METRICS ===
def calculate_metrics(df, version_name):
    """Calculate comprehensive trading metrics"""
    wins = df[df['Profit'] > 0]
    losses = df[df['Profit'] <= 0]
    
    # Get MT5 official numbers for validation
    mt5_file = v24_mt5 if '2.4' in version_name else v25_mt5
    mt5_trades = []
    mt5_total_pnl = 0
    
    with open(mt5_file, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('Deal') and row.get('Direction') == 'out':
                profit_str = row.get('Profit', '0').replace(' ', '').replace(',', '')
                profit = float(profit_str) if profit_str else 0
                mt5_trades.append(profit)
                mt5_total_pnl += profit
    
    return {
        'version': version_name,
        'total_trades': len(df),
        'mt5_trades': len(mt5_trades),
        'wins': len(wins),
        'losses': len(losses),
        'win_rate': (len(wins) / len(df) * 100) if len(df) > 0 else 0,
        
        # P&L
        'total_pnl': df['Profit'].sum(),
        'mt5_pnl': mt5_total_pnl,
        'avg_trade': df['Profit'].mean(),
        'avg_win': wins['Profit'].mean() if len(wins) > 0 else 0,
        'avg_loss': losses['Profit'].mean() if len(losses) > 0 else 0,
        
        # Risk metrics
        'profit_factor': abs(wins['Profit'].sum() / losses['Profit'].sum()) if len(losses) > 0 and losses['Profit'].sum() != 0 else 0,
        'max_dd': df['DrawdownPercent'].min() if 'DrawdownPercent' in df.columns else 0,
        
        # Exit analysis
        'sl_exits': len(df[df['ExitReason'] == 'SL']),
        'tp_exits': len(df[df['ExitReason'] == 'TP']),
        'ea_exits': len(df[df['ExitReason'] == 'EA']),
        
        # Pips
        'total_pips': df['Pips'].sum() if 'Pips' in df.columns else 0,
        'avg_pips': df['Pips'].mean() if 'Pips' in df.columns else 0,
        'avg_win_pips': wins['Pips'].mean() if 'Pips' in wins.columns and len(wins) > 0 else 0,
        'avg_loss_pips': losses['Pips'].mean() if 'Pips' in losses.columns and len(losses) > 0 else 0,
    }

metrics_24 = calculate_metrics(df_24, "v2.4 Baseline (No Filters)")
metrics_25 = calculate_metrics(df_25, "v2.5 Optimized (Regime+Zone)")

# === DISPLAY COMPARISON TABLE ===
print("="*100)
print("  📈 PERFORMANCE COMPARISON")
print("="*100 + "\n")

print(f"{'Metric':<30} {'v2.4 Baseline':<25} {'v2.5 Optimized':<25} {'Change':<15}")
print("-" * 100)

# Trade counts
print(f"{'Total Trades':<30} {metrics_24['total_trades']:<25} {metrics_25['total_trades']:<25} {metrics_25['total_trades'] - metrics_24['total_trades']} ({(metrics_25['total_trades']/metrics_24['total_trades']-1)*100:+.1f}%)")
print(f"{'MT5 Validation':<30} {metrics_24['mt5_trades']:<25} {metrics_25['mt5_trades']:<25}")
print(f"{'Wins':<30} {metrics_24['wins']:<25} {metrics_25['wins']:<25} {metrics_25['wins'] - metrics_24['wins']:+d}")
print(f"{'Losses':<30} {metrics_24['losses']:<25} {metrics_25['losses']:<25} {metrics_25['losses'] - metrics_24['losses']:+d}")
print(f"{'Win Rate':<30} {metrics_24['win_rate']:.1f}%{'':<20} {metrics_25['win_rate']:.1f}%{'':<20} {metrics_25['win_rate'] - metrics_24['win_rate']:+.1f}%")
print()

# P&L
print(f"{'Total P&L (TP CSV)':<30} ${metrics_24['total_pnl']:.2f}{'':<19} ${metrics_25['total_pnl']:.2f}{'':<19} ${metrics_25['total_pnl'] - metrics_24['total_pnl']:+.2f}")
print(f"{'Total P&L (MT5)':<30} ${metrics_24['mt5_pnl']:.2f}{'':<19} ${metrics_25['mt5_pnl']:.2f}{'':<19} ${metrics_25['mt5_pnl'] - metrics_24['mt5_pnl']:+.2f}")
print(f"{'Avg Trade P&L':<30} ${metrics_24['avg_trade']:.2f}{'':<19} ${metrics_25['avg_trade']:.2f}{'':<19} ${metrics_25['avg_trade'] - metrics_24['avg_trade']:+.2f}")
print(f"{'Avg Win':<30} ${metrics_24['avg_win']:.2f}{'':<19} ${metrics_25['avg_win']:.2f}{'':<19} ${metrics_25['avg_win'] - metrics_24['avg_win']:+.2f}")
print(f"{'Avg Loss':<30} ${metrics_24['avg_loss']:.2f}{'':<19} ${metrics_25['avg_loss']:.2f}{'':<19} ${metrics_25['avg_loss'] - metrics_24['avg_loss']:+.2f}")
print()

# Risk metrics
print(f"{'Profit Factor':<30} {metrics_24['profit_factor']:.2f}{'':<21} {metrics_25['profit_factor']:.2f}{'':<21} {metrics_25['profit_factor'] - metrics_24['profit_factor']:+.2f}")
print(f"{'Max Drawdown':<30} {metrics_24['max_dd']:.2f}%{'':<20} {metrics_25['max_dd']:.2f}%{'':<20} {metrics_25['max_dd'] - metrics_24['max_dd']:+.2f}%")
print()

# Pips
print(f"{'Total Pips':<30} {metrics_24['total_pips']:.2f}{'':<19} {metrics_25['total_pips']:.2f}{'':<19} {metrics_25['total_pips'] - metrics_24['total_pips']:+.2f}")
print(f"{'Avg Pips/Trade':<30} {metrics_24['avg_pips']:.2f}{'':<19} {metrics_25['avg_pips']:.2f}{'':<19} {metrics_25['avg_pips'] - metrics_24['avg_pips']:+.2f}")
print(f"{'Avg Win Pips':<30} {metrics_24['avg_win_pips']:.2f}{'':<19} {metrics_25['avg_win_pips']:.2f}{'':<19} {metrics_25['avg_win_pips'] - metrics_24['avg_win_pips']:+.2f}")
print(f"{'Avg Loss Pips':<30} {metrics_24['avg_loss_pips']:.2f}{'':<19} {metrics_25['avg_loss_pips']:.2f}{'':<19} {metrics_25['avg_loss_pips'] - metrics_24['avg_loss_pips']:+.2f}")
print()

# Exit reasons
print(f"{'SL Exits':<30} {metrics_24['sl_exits']} ({metrics_24['sl_exits']/metrics_24['total_trades']*100:.1f}%){'':<12} {metrics_25['sl_exits']} ({metrics_25['sl_exits']/metrics_25['total_trades']*100:.1f}%){'':<12} {metrics_25['sl_exits'] - metrics_24['sl_exits']:+d}")
print(f"{'TP Exits':<30} {metrics_24['tp_exits']} ({metrics_24['tp_exits']/metrics_24['total_trades']*100:.1f}%){'':<12} {metrics_25['tp_exits']} ({metrics_25['tp_exits']/metrics_25['total_trades']*100:.1f}%){'':<12} {metrics_25['tp_exits'] - metrics_24['tp_exits']:+d}")
print(f"{'EA Exits (Reversal)':<30} {metrics_24['ea_exits']} ({metrics_24['ea_exits']/metrics_24['total_trades']*100:.1f}%){'':<12} {metrics_25['ea_exits']} ({metrics_25['ea_exits']/metrics_25['total_trades']*100:.1f}%){'':<12} {metrics_25['ea_exits'] - metrics_24['ea_exits']:+d}")

print("\n" + "="*100)
print("  🎯 FILTER EFFECTIVENESS ANALYSIS")
print("="*100 + "\n")

# Calculate what the filters rejected
trades_rejected = metrics_24['total_trades'] - metrics_25['total_trades']
rejection_rate = (trades_rejected / metrics_24['total_trades'] * 100) if metrics_24['total_trades'] > 0 else 0

print(f"Signals Generated (v2.4):    {metrics_24['total_trades']}")
print(f"Signals Accepted (v2.5):     {metrics_25['total_trades']}")
print(f"Signals Rejected by Filters: {trades_rejected} ({rejection_rate:.1f}%)")
print()

# Quality comparison
if metrics_25['win_rate'] > metrics_24['win_rate']:
    improvement = metrics_25['win_rate'] - metrics_24['win_rate']
    print(f"✅ Win Rate IMPROVED by {improvement:.1f}% ({metrics_24['win_rate']:.1f}% → {metrics_25['win_rate']:.1f}%)")
else:
    decline = metrics_24['win_rate'] - metrics_25['win_rate']
    print(f"⚠️  Win Rate DECLINED by {decline:.1f}% ({metrics_24['win_rate']:.1f}% → {metrics_25['win_rate']:.1f}%)")

if metrics_25['avg_trade'] > metrics_24['avg_trade']:
    improvement = metrics_25['avg_trade'] - metrics_24['avg_trade']
    print(f"✅ Avg P&L per Trade IMPROVED by ${improvement:.2f} (${metrics_24['avg_trade']:.2f} → ${metrics_25['avg_trade']:.2f})")
else:
    decline = metrics_24['avg_trade'] - metrics_25['avg_trade']
    print(f"⚠️  Avg P&L per Trade DECLINED by ${decline:.2f} (${metrics_24['avg_trade']:.2f} → ${metrics_25['avg_trade']:.2f})")

if metrics_25['profit_factor'] > metrics_24['profit_factor']:
    improvement = metrics_25['profit_factor'] - metrics_24['profit_factor']
    print(f"✅ Profit Factor IMPROVED by {improvement:.2f} ({metrics_24['profit_factor']:.2f} → {metrics_25['profit_factor']:.2f})")
else:
    decline = metrics_24['profit_factor'] - metrics_25['profit_factor']
    print(f"⚠️  Profit Factor DECLINED by {decline:.2f} ({metrics_24['profit_factor']:.2f} → {metrics_25['profit_factor']:.2f})")

print()

# === ZONE/REGIME ANALYSIS (v2.5 only) ===
if 'EntryZone' in df_25.columns and 'EntryRegime' in df_25.columns:
    print("="*100)
    print("  🔬 PHYSICS FILTER ANALYSIS (v2.5 Accepted Trades)")
    print("="*100 + "\n")
    
    print("Trading Zone Distribution:")
    zone_counts = df_25['EntryZone'].value_counts()
    for zone, count in zone_counts.items():
        wins_in_zone = len(df_25[(df_25['EntryZone'] == zone) & (df_25['Profit'] > 0)])
        wr = (wins_in_zone / count * 100) if count > 0 else 0
        pnl = df_25[df_25['EntryZone'] == zone]['Profit'].sum()
        print(f"   {zone:<12} {count:>3} trades ({count/len(df_25)*100:>5.1f}%) | Win Rate: {wr:>5.1f}% | P&L: ${pnl:>8.2f}")
    
    print("\nVolatility Regime Distribution:")
    regime_counts = df_25['EntryRegime'].value_counts()
    for regime, count in regime_counts.items():
        wins_in_regime = len(df_25[(df_25['EntryRegime'] == regime) & (df_25['Profit'] > 0)])
        wr = (wins_in_regime / count * 100) if count > 0 else 0
        pnl = df_25[df_25['EntryRegime'] == regime]['Profit'].sum()
        print(f"   {regime:<12} {count:>3} trades ({count/len(df_25)*100:>5.1f}%) | Win Rate: {wr:>5.1f}% | P&L: ${pnl:>8.2f}")
    
    print()

# === FINAL VERDICT ===
print("="*100)
print("  ✅ FINAL VERDICT")
print("="*100 + "\n")

total_improvement = (metrics_25['total_pnl'] - metrics_24['total_pnl']) / abs(metrics_24['total_pnl']) * 100 if metrics_24['total_pnl'] != 0 else 0

if metrics_25['total_pnl'] > metrics_24['total_pnl'] and metrics_25['win_rate'] > metrics_24['win_rate']:
    print("🎉 OPTIMIZATION SUCCESSFUL!")
    print(f"\n   Physics filters improved performance:")
    print(f"   • P&L: ${metrics_24['total_pnl']:.2f} → ${metrics_25['total_pnl']:.2f} ({total_improvement:+.1f}%)")
    print(f"   • Win Rate: {metrics_24['win_rate']:.1f}% → {metrics_25['win_rate']:.1f}% ({metrics_25['win_rate'] - metrics_24['win_rate']:+.1f}%)")
    print(f"   • Trades: {metrics_24['total_trades']} → {metrics_25['total_trades']} (-{rejection_rate:.1f}% noise filtered)")
    print(f"\n   ✅ Filters are working as intended - avoiding BEAR zones and LOW regimes")
elif metrics_25['win_rate'] > metrics_24['win_rate']:
    print("⚠️  MIXED RESULTS:")
    print(f"\n   Win Rate improved but total P&L declined:")
    print(f"   • Win Rate: {metrics_24['win_rate']:.1f}% → {metrics_25['win_rate']:.1f}% ({metrics_25['win_rate'] - metrics_24['win_rate']:+.1f}%)")
    print(f"   • P&L: ${metrics_24['total_pnl']:.2f} → ${metrics_25['total_pnl']:.2f} ({total_improvement:+.1f}%)")
    print(f"\n   💡 Filters improved quality but reduced volume too much")
else:
    print("❌ OPTIMIZATION INCONCLUSIVE:")
    print(f"\n   Filters may need adjustment:")
    print(f"   • Win Rate: {metrics_24['win_rate']:.1f}% → {metrics_25['win_rate']:.1f}% ({metrics_25['win_rate'] - metrics_24['win_rate']:+.1f}%)")
    print(f"   • P&L: ${metrics_24['total_pnl']:.2f} → ${metrics_25['total_pnl']:.2f} ({total_improvement:+.1f}%)")
    print(f"\n   💡 Consider relaxing filter thresholds or testing different combinations")

print("\n" + "="*100 + "\n")

# Save summary to file
summary_file = Path("/Users/patjohnston/ai-trading-platform/MQL5/V2_4_vs_V2_5_COMPARISON.md")
with open(summary_file, 'w') as f:
    f.write("# TickPhysics Optimization Results: v2.4 vs v2.5\n\n")
    f.write(f"**Test Period:** {datetime.now().strftime('%Y-%m-%d')}\n")
    f.write(f"**Symbol:** NAS100 M15\n\n")
    
    f.write("## Summary\n\n")
    f.write(f"- **v2.4 Baseline:** MA Crossover only (no physics filters)\n")
    f.write(f"- **v2.5 Optimized:** MA Crossover + Physics filters (regime + zone)\n\n")
    
    f.write("## Key Metrics\n\n")
    f.write(f"| Metric | v2.4 Baseline | v2.5 Optimized | Change |\n")
    f.write(f"|--------|---------------|----------------|--------|\n")
    f.write(f"| Total Trades | {metrics_24['total_trades']} | {metrics_25['total_trades']} | {metrics_25['total_trades'] - metrics_24['total_trades']} ({(metrics_25['total_trades']/metrics_24['total_trades']-1)*100:+.1f}%) |\n")
    f.write(f"| Win Rate | {metrics_24['win_rate']:.1f}% | {metrics_25['win_rate']:.1f}% | {metrics_25['win_rate'] - metrics_24['win_rate']:+.1f}% |\n")
    f.write(f"| Total P&L | ${metrics_24['total_pnl']:.2f} | ${metrics_25['total_pnl']:.2f} | ${metrics_25['total_pnl'] - metrics_24['total_pnl']:+.2f} |\n")
    f.write(f"| Avg P&L/Trade | ${metrics_24['avg_trade']:.2f} | ${metrics_25['avg_trade']:.2f} | ${metrics_25['avg_trade'] - metrics_24['avg_trade']:+.2f} |\n")
    f.write(f"| Profit Factor | {metrics_24['profit_factor']:.2f} | {metrics_25['profit_factor']:.2f} | {metrics_25['profit_factor'] - metrics_24['profit_factor']:+.2f} |\n")
    f.write(f"| Max Drawdown | {metrics_24['max_dd']:.2f}% | {metrics_25['max_dd']:.2f}% | {metrics_25['max_dd'] - metrics_24['max_dd']:+.2f}% |\n")
    
    f.write(f"\n## Filter Impact\n\n")
    f.write(f"- Signals Rejected: {trades_rejected} ({rejection_rate:.1f}%)\n")
    f.write(f"- Filters avoided BEAR zones and LOW volatility regimes\n")

print(f"📄 Summary saved to: {summary_file.name}\n")
