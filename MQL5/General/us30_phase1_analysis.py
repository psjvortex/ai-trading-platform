#!/usr/bin/env python3
"""
US30 Phase 1 Baseline Analysis
Analyze US30 M05 backtest with relaxed settings
"""
import pandas as pd
from pathlib import Path

DESKTOP = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's")

# Load US30 Phase 1 data
us30_trades = pd.read_csv(DESKTOP / "TP_Integrated_US30_M05_MTBacktest_v4.180_SLOPE_trades.csv")
us30_signals = pd.read_csv(DESKTOP / "TP_Integrated_US30_M05_MTBacktest_v4.180_SLOPE_signals.csv")

print("\n" + "="*80)
print("  📊 US30 PHASE 1 BASELINE ANALYSIS - M05 (2025 YTD)")
print("="*80 + "\n")

# === OVERALL STATS ===
total = len(us30_trades)
wins = len(us30_trades[us30_trades['Profit'] > 0])
losses = len(us30_trades[us30_trades['Profit'] <= 0])
wr = (wins/total*100) if total > 0 else 0
pnl = us30_trades['Profit'].sum()
avg_win = us30_trades[us30_trades['Profit'] > 0]['Profit'].mean() if wins > 0 else 0
avg_loss = us30_trades[us30_trades['Profit'] <= 0]['Profit'].mean() if losses > 0 else 0
expectancy = (wr/100*avg_win + (1-wr/100)*avg_loss)

print("US30 Phase 1 Results (Relaxed Thresholds):")
print(f"  Trades:      {total}")
print(f"  Wins:        {wins} ({wr:.1f}%)")
print(f"  Losses:      {losses}")
print(f"  Total P&L:   ${pnl:.2f}")
print(f"  Avg Win:     ${avg_win:.2f}")
print(f"  Avg Loss:    ${avg_loss:.2f}")
print(f"  Expectancy:  ${expectancy:.2f} per trade")
print(f"  Signals:     {len(us30_signals)}")
print(f"  Exec Rate:   {(total/len(us30_signals)*100):.1f}%\n")

# === BUY vs SELL ===
print("="*80)
print("  📈 BUY vs SELL BREAKDOWN")
print("="*80 + "\n")

buy = us30_trades[us30_trades['Type'] == 'BUY']
sell = us30_trades[us30_trades['Type'] == 'SELL']

buy_wr = (len(buy[buy['Profit'] > 0]) / len(buy) * 100) if len(buy) > 0 else 0
sell_wr = (len(sell[sell['Profit'] > 0]) / len(sell) * 100) if len(sell) > 0 else 0

buy_pnl = buy['Profit'].sum()
sell_pnl = sell['Profit'].sum()

print(f"BUY:   {len(buy):3} trades @ {buy_wr:5.1f}% WR = ${buy_pnl:7.2f}")
print(f"SELL:  {len(sell):3} trades @ {sell_wr:5.1f}% WR = ${sell_pnl:7.2f}\n")

# === EXIT REASONS ===
print("="*80)
print("  🚪 EXIT REASONS")
print("="*80 + "\n")

for reason, count in us30_trades['ExitReason'].value_counts().items():
    pct = count / len(us30_trades) * 100
    print(f"  {reason:10} {count:4} ({pct:5.1f}%)")

# === COMPARISON TO NAS100 ===
print("\n" + "="*80)
print("  📊 US30 vs NAS100 COMPARISON (Phase 1)")
print("="*80 + "\n")

# NAS100 Phase 1 stats for reference
nas_trades = 1009
nas_wr = 59.6
nas_pnl = 69.19
nas_exp = 0.07

print("                  US30      NAS100     Delta")
print(f"Trades:          {total:5}     {nas_trades:5}     {total-nas_trades:+5}")
print(f"Win Rate:        {wr:5.1f}%    {nas_wr:5.1f}%    {wr-nas_wr:+5.1f}%")
print(f"P&L:           ${pnl:7.2f}  ${nas_pnl:7.2f}  ${pnl-nas_pnl:+7.2f}")
print(f"Expectancy:    ${expectancy:7.2f}  ${nas_exp:7.2f}  ${expectancy-nas_exp:+7.2f}")

print("\n" + "="*80)
print("  ✅ PHASE 1 BASELINE COMPLETE")
print("="*80 + "\n")

if expectancy > 0:
    print(f"✅ US30 shows positive expectancy (${expectancy:.2f} per trade)")
else:
    print(f"⚠️  US30 shows negative expectancy (${expectancy:.2f} per trade)")

if wr >= 40:
    print(f"✅ Win rate {wr:.1f}% meets 2:1 R:R threshold (40%+)")
else:
    print(f"⚠️  Win rate {wr:.1f}% below 2:1 R:R threshold (need 40%+)")

print(f"\n💡 Next Step: Run US30 Phase 2 backtest with v4.1.8.1 optimized thresholds")
print("   Expected: Fewer trades, higher expectancy (similar to NAS100 improvement)\n")

print("="*80 + "\n")
