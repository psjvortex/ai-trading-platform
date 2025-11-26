#!/usr/bin/env python3
"""
Quick MT5 Report Comparison - v2.4 vs v2.5
Based solely on MT5 backtest CSV reports
"""
import csv
import pandas as pd
from pathlib import Path

print("\n" + "="*100)
print("  📊 MT5 BACKTEST COMPARISON - v2.4 (Baseline) vs v2.5 (Physics-Optimized)")
print("="*100 + "\n")

# === PATHS ===
MT5_DROP = Path("/Users/patjohnston/Desktop/MT5 EA Backtest CSV Folder")
v24_mt5 = MT5_DROP / "MTBacktest_Report_2.4.csv"
v25_mt5 = MT5_DROP / "MTBacktest_Report_2.5.csv"

print("📂 Analyzing MT5 Official Reports:\n")
print(f"   v2.4 Baseline:  {v24_mt5.name}")
print(f"   v2.5 Optimized: {v25_mt5.name}\n")

# === PARSE MT5 REPORTS ===
def parse_mt5_report(filepath):
    """Parse MT5 backtest CSV report"""
    trades = []
    balance = 1000.0  # Starting balance
    
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('Type') == 'balance':
                balance = float(row.get('Balance', '1000').replace(' ', '').replace(',', ''))
            elif row.get('Deal') and row.get('Direction') == 'out':
                profit_str = row.get('Profit', '0').replace(' ', '').replace(',', '')
                profit = float(profit_str) if profit_str else 0
                
                trades.append({
                    'deal': row['Deal'],
                    'time': row['Time'],
                    'profit': profit,
                    'balance': balance
                })
                balance += profit
    
    return trades, balance

# Load both reports
trades_24, final_balance_24 = parse_mt5_report(v24_mt5)
trades_25, final_balance_25 = parse_mt5_report(v25_mt5)

print("="*100)
print("  📈 KEY PERFORMANCE METRICS")
print("="*100 + "\n")

# Calculate metrics
def calculate_stats(trades, starting_balance=1000.0):
    if not trades:
        return {}
    
    profits = [t['profit'] for t in trades]
    wins = [p for p in profits if p > 0]
    losses = [p for p in profits if p < 0]
    
    total_pnl = sum(profits)
    win_count = len(wins)
    loss_count = len(losses)
    total_trades = len(trades)
    
    # Drawdown calculation
    balance = starting_balance
    peak = starting_balance
    max_dd = 0
    max_dd_pct = 0
    
    for t in trades:
        balance += t['profit']
        if balance > peak:
            peak = balance
        dd = peak - balance
        dd_pct = (dd / peak * 100) if peak > 0 else 0
        if dd_pct > max_dd_pct:
            max_dd_pct = dd_pct
            max_dd = dd
    
    return {
        'total_trades': total_trades,
        'wins': win_count,
        'losses': loss_count,
        'win_rate': (win_count / total_trades * 100) if total_trades > 0 else 0,
        'total_pnl': total_pnl,
        'avg_trade': total_pnl / total_trades if total_trades > 0 else 0,
        'avg_win': sum(wins) / len(wins) if wins else 0,
        'avg_loss': sum(losses) / len(losses) if losses else 0,
        'profit_factor': abs(sum(wins) / sum(losses)) if losses and sum(losses) != 0 else 0,
        'max_dd': max_dd,
        'max_dd_pct': max_dd_pct,
        'final_balance': balance,
        'roi': ((balance - starting_balance) / starting_balance * 100)
    }

stats_24 = calculate_stats(trades_24)
stats_25 = calculate_stats(trades_25)

# Display comparison table
print(f"{'Metric':<30} {'v2.4 Baseline':<25} {'v2.5 Optimized':<25} {'Change':<20}")
print("-" * 100)

# Trade counts
print(f"{'Total Trades':<30} {stats_24['total_trades']:<25} {stats_25['total_trades']:<25} {stats_25['total_trades'] - stats_24['total_trades']} ({(stats_25['total_trades']/stats_24['total_trades']-1)*100:+.1f}%)")
print(f"{'Wins':<30} {stats_24['wins']:<25} {stats_25['wins']:<25} {stats_25['wins'] - stats_24['wins']:+d}")
print(f"{'Losses':<30} {stats_24['losses']:<25} {stats_25['losses']:<25} {stats_25['losses'] - stats_24['losses']:+d}")
print(f"{'Win Rate':<30} {stats_24['win_rate']:.1f}%{'':<20} {stats_25['win_rate']:.1f}%{'':<20} {stats_25['win_rate'] - stats_24['win_rate']:+.1f}%")
print()

# P&L
print(f"{'Total P&L':<30} ${stats_24['total_pnl']:.2f}{'':<19} ${stats_25['total_pnl']:.2f}{'':<19} ${stats_25['total_pnl'] - stats_24['total_pnl']:+.2f}")
print(f"{'Avg P&L per Trade':<30} ${stats_24['avg_trade']:.2f}{'':<19} ${stats_25['avg_trade']:.2f}{'':<19} ${stats_25['avg_trade'] - stats_24['avg_trade']:+.2f}")
print(f"{'Avg Win':<30} ${stats_24['avg_win']:.2f}{'':<19} ${stats_25['avg_win']:.2f}{'':<19} ${stats_25['avg_win'] - stats_24['avg_win']:+.2f}")
print(f"{'Avg Loss':<30} ${stats_24['avg_loss']:.2f}{'':<19} ${stats_25['avg_loss']:.2f}{'':<19} ${stats_25['avg_loss'] - stats_24['avg_loss']:+.2f}")
print()

# Risk metrics
print(f"{'Profit Factor':<30} {stats_24['profit_factor']:.2f}{'':<21} {stats_25['profit_factor']:.2f}{'':<21} {stats_25['profit_factor'] - stats_24['profit_factor']:+.2f}")
print(f"{'Max Drawdown':<30} ${stats_24['max_dd']:.2f} ({stats_24['max_dd_pct']:.2f}%){'':<8} ${stats_25['max_dd']:.2f} ({stats_25['max_dd_pct']:.2f}%){'':<8}")
print(f"{'Final Balance':<30} ${stats_24['final_balance']:.2f}{'':<19} ${stats_25['final_balance']:.2f}{'':<19} ${stats_25['final_balance'] - stats_24['final_balance']:+.2f}")
print(f"{'ROI':<30} {stats_24['roi']:.2f}%{'':<20} {stats_25['roi']:.2f}%{'':<20} {stats_25['roi'] - stats_24['roi']:+.2f}%")

print("\n" + "="*100)
print("  🎯 FILTER EFFECTIVENESS")
print("="*100 + "\n")

trades_rejected = stats_24['total_trades'] - stats_25['total_trades']
rejection_rate = (trades_rejected / stats_24['total_trades'] * 100) if stats_24['total_trades'] > 0 else 0

print(f"Baseline Signals (v2.4):         {stats_24['total_trades']}")
print(f"Filtered Signals (v2.5):         {stats_25['total_trades']}")
print(f"Signals Rejected by Physics:     {trades_rejected} ({rejection_rate:.1f}%)")
print()

# Analysis
print("="*100)
print("  ✅ ANALYSIS & VERDICT")
print("="*100 + "\n")

# Win Rate comparison
if stats_25['win_rate'] > stats_24['win_rate']:
    wr_change = stats_25['win_rate'] - stats_24['win_rate']
    print(f"✅ WIN RATE IMPROVED: {stats_24['win_rate']:.1f}% → {stats_25['win_rate']:.1f}% (+{wr_change:.1f}%)")
    print(f"   Physics filters successfully improved trade quality!")
else:
    wr_change = stats_24['win_rate'] - stats_25['win_rate']
    print(f"⚠️  WIN RATE DECLINED: {stats_24['win_rate']:.1f}% → {stats_25['win_rate']:.1f}% (-{wr_change:.1f}%)")

print()

# P&L comparison  
if stats_25['total_pnl'] > stats_24['total_pnl']:
    pnl_change = stats_25['total_pnl'] - stats_24['total_pnl']
    pnl_pct = (pnl_change / abs(stats_24['total_pnl']) * 100) if stats_24['total_pnl'] != 0 else 0
    print(f"✅ PROFIT IMPROVED: ${stats_24['total_pnl']:.2f} → ${stats_25['total_pnl']:.2f} (+${pnl_change:.2f}, +{pnl_pct:.1f}%)")
else:
    pnl_change = stats_24['total_pnl'] - stats_25['total_pnl']
    pnl_pct = (pnl_change / abs(stats_24['total_pnl']) * 100) if stats_24['total_pnl'] != 0 else 0
    print(f"⚠️  PROFIT DECLINED: ${stats_24['total_pnl']:.2f} → ${stats_25['total_pnl']:.2f} (-${pnl_change:.2f}, -{pnl_pct:.1f}%)")

print()

# Avg trade comparison
if stats_25['avg_trade'] > stats_24['avg_trade']:
    avg_change = stats_25['avg_trade'] - stats_24['avg_trade']
    print(f"✅ AVG TRADE IMPROVED: ${stats_24['avg_trade']:.2f} → ${stats_25['avg_trade']:.2f} (+${avg_change:.2f})")
    print(f"   Each trade is now more profitable on average!")
else:
    avg_change = stats_24['avg_trade'] - stats_25['avg_trade']
    print(f"⚠️  AVG TRADE DECLINED: ${stats_24['avg_trade']:.2f} → ${stats_25['avg_trade']:.2f} (-${avg_change:.2f})")

print()

# Profit Factor
if stats_25['profit_factor'] > stats_24['profit_factor']:
    pf_change = stats_25['profit_factor'] - stats_24['profit_factor']
    print(f"✅ PROFIT FACTOR IMPROVED: {stats_24['profit_factor']:.2f} → {stats_25['profit_factor']:.2f} (+{pf_change:.2f})")
else:
    pf_change = stats_24['profit_factor'] - stats_25['profit_factor']
    print(f"⚠️  PROFIT FACTOR DECLINED: {stats_24['profit_factor']:.2f} → {stats_25['profit_factor']:.2f} (-{pf_change:.2f})")

print()

# Overall verdict
print("="*100)
print("  🏆 FINAL VERDICT")
print("="*100 + "\n")

improvements = 0
if stats_25['win_rate'] > stats_24['win_rate']: improvements += 1
if stats_25['total_pnl'] > stats_24['total_pnl']: improvements += 1
if stats_25['avg_trade'] > stats_24['avg_trade']: improvements += 1
if stats_25['profit_factor'] > stats_24['profit_factor']: improvements += 1

if improvements >= 3:
    print("🎉 PHYSICS OPTIMIZATION SUCCESSFUL!")
    print("\nThe regime and zone filters significantly improved EA performance:")
    print(f"  • Rejected {rejection_rate:.0f}% of low-quality signals")
    print(f"  • Improved {improvements}/4 key metrics")
    print(f"  • {stats_25['win_rate']:.1f}% win rate (vs {stats_24['win_rate']:.1f}% baseline)")
    print(f"  • ${stats_25['total_pnl']:.2f} total P&L (vs ${stats_24['total_pnl']:.2f} baseline)")
    print("\n✅ RECOMMENDATION: Use v2.5 with physics filters for live trading")
elif improvements >= 2:
    print("⚠️  MIXED RESULTS - Further tuning recommended")
    print(f"\nPhysics filters showed partial improvement ({improvements}/4 metrics):")
    print(f"  • Rejected {rejection_rate:.0f}% of signals")
    print(f"  • Consider adjusting filter thresholds")
    print("\n💡 RECOMMENDATION: Test with relaxed filters or different regime/zone combinations")
else:
    print("❌ OPTIMIZATION INCONCLUSIVE")
    print(f"\nPhysics filters did not improve performance ({improvements}/4 metrics improved):")
    print(f"  • Over-filtering may have rejected good trades")
    print(f"  • Filter logic may need revision")
    print("\n💡 RECOMMENDATION: Review filter criteria and correlation analysis")

print("\n" + "="*100 + "\n")

# Save summary
summary_file = Path("/Users/patjohnston/ai-trading-platform/MQL5/MT5_COMPARISON_V2_4_VS_V2_5.md")
with open(summary_file, 'w') as f:
    f.write("# MT5 Backtest Comparison: v2.4 vs v2.5\n\n")
    f.write("## Configuration\n\n")
    f.write("- **v2.4:** MA Crossover (no physics filters)\n")
    f.write("- **v2.5:** MA Crossover + Physics filters (BEAR zone + LOW regime rejection)\n")
    f.write("- **Symbol:** NAS100 M15\n")
    f.write("- **Period:** Jan 2025 - Sep 2025 (9 months)\n\n")
    
    f.write("## Results\n\n")
    f.write("| Metric | v2.4 | v2.5 | Change |\n")
    f.write("|--------|------|------|--------|\n")
    f.write(f"| Trades | {stats_24['total_trades']} | {stats_25['total_trades']} | {stats_25['total_trades'] - stats_24['total_trades']} ({(stats_25['total_trades']/stats_24['total_trades']-1)*100:+.1f}%) |\n")
    f.write(f"| Win Rate | {stats_24['win_rate']:.1f}% | {stats_25['win_rate']:.1f}% | {stats_25['win_rate'] - stats_24['win_rate']:+.1f}% |\n")
    f.write(f"| Total P&L | ${stats_24['total_pnl']:.2f} | ${stats_25['total_pnl']:.2f} | ${stats_25['total_pnl'] - stats_24['total_pnl']:+.2f} |\n")
    f.write(f"| Avg Trade | ${stats_24['avg_trade']:.2f} | ${stats_25['avg_trade']:.2f} | ${stats_25['avg_trade'] - stats_24['avg_trade']:+.2f} |\n")
    f.write(f"| Profit Factor | {stats_24['profit_factor']:.2f} | {stats_25['profit_factor']:.2f} | {stats_25['profit_factor'] - stats_24['profit_factor']:+.2f} |\n")
    f.write(f"| Max DD | {stats_24['max_dd_pct']:.2f}% | {stats_25['max_dd_pct']:.2f}% | {stats_25['max_dd_pct'] - stats_24['max_dd_pct']:+.2f}% |\n")
    f.write(f"| ROI | {stats_24['roi']:.2f}% | {stats_25['roi']:.2f}% | {stats_25['roi'] - stats_24['roi']:+.2f}% |\n\n")
    
    f.write(f"## Filter Impact\n\n")
    f.write(f"- Physics filters rejected {trades_rejected} signals ({rejection_rate:.1f}%)\n")
    f.write(f"- Filters avoided BEAR trading zones and LOW volatility regimes\n")
    f.write(f"- Metrics improved: {improvements}/4\n\n")
    
    if improvements >= 3:
        f.write("## Conclusion\n\n")
        f.write("✅ **Physics optimization was successful.** The regime and zone filters significantly improved trading performance by filtering out low-quality setups.\n")
    elif improvements >= 2:
        f.write("## Conclusion\n\n")
        f.write("⚠️ **Mixed results.** Physics filters showed some improvement but may need fine-tuning for optimal performance.\n")
    else:
        f.write("## Conclusion\n\n")
        f.write("❌ **Optimization inconclusive.** Current filter settings may be too restrictive or need revision.\n")

print(f"📄 Summary saved to: {summary_file.name}\n")
