#!/usr/bin/env python3
"""
Phase 1 vs Phase 2 Comparison Analysis
Compare baseline (v4.180) vs optimized (v4.181) results
"""
import pandas as pd
from pathlib import Path

DESKTOP = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's")

# Phase 1 (Baseline - Relaxed thresholds)
phase1_trades = pd.read_csv(DESKTOP / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_trades.csv")
phase1_signals = pd.read_csv(DESKTOP / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_signals.csv")

# Phase 2 (Optimized thresholds)
phase2_trades = pd.read_csv(DESKTOP / "TP_Integrated_NAS100_M05_MTBacktest_v4.181_OPTIMIZED_trades.csv")
phase2_signals = pd.read_csv(DESKTOP / "TP_Integrated_NAS100_M05_MTBacktest_v4.181_OPTIMIZED_signals.csv")

print("\n" + "="*80)
print("  📊 PHASE 1 vs PHASE 2 COMPARISON - NAS100 M05 (2025 YTD)")
print("="*80 + "\n")

# === OVERALL COMPARISON ===
print("="*80)
print("  🎯 OVERALL PERFORMANCE")
print("="*80 + "\n")

def analyze_phase(trades_df, signals_df, phase_name, thresholds):
    total = len(trades_df)
    wins = len(trades_df[trades_df['Profit'] > 0])
    losses = len(trades_df[trades_df['Profit'] <= 0])
    wr = (wins/total*100) if total > 0 else 0
    pnl = trades_df['Profit'].sum()
    avg_win = trades_df[trades_df['Profit'] > 0]['Profit'].mean() if wins > 0 else 0
    avg_loss = trades_df[trades_df['Profit'] <= 0]['Profit'].mean() if losses > 0 else 0
    
    print(f"{phase_name} Results:")
    print(f"  Thresholds:  {thresholds}")
    print(f"  Trades:      {total}")
    print(f"  Wins:        {wins} ({wr:.1f}%)")
    print(f"  Losses:      {losses}")
    print(f"  Total P&L:   ${pnl:.2f}")
    print(f"  Avg Win:     ${avg_win:.2f}")
    print(f"  Avg Loss:    ${avg_loss:.2f}")
    print(f"  Expectancy:  ${(wr/100*avg_win + (1-wr/100)*avg_loss):.2f} per trade")
    print(f"  Signals Gen: {len(signals_df)}")
    print(f"  Exec Rate:   {(total/len(signals_df)*100):.1f}%")
    print()
    
    return {
        'trades': total,
        'wins': wins,
        'wr': wr,
        'pnl': pnl,
        'expectancy': (wr/100*avg_win + (1-wr/100)*avg_loss),
        'signals': len(signals_df)
    }

phase1_stats = analyze_phase(phase1_trades, phase1_signals, "PHASE 1 (v4.180 BASELINE)",
                             "Speed:55/-55, Accel:80/-80, Mom:30/-30")

phase2_stats = analyze_phase(phase2_trades, phase2_signals, "PHASE 2 (v4.181 OPTIMIZED)",
                             "Speed:4031/-3797, Accel:1171/-1534, Mom:215/-216")

# === DELTA ANALYSIS ===
print("="*80)
print("  📈 IMPROVEMENT ANALYSIS (Phase 2 vs Phase 1)")
print("="*80 + "\n")

trade_delta = phase2_stats['trades'] - phase1_stats['trades']
trade_pct = (phase2_stats['trades'] / phase1_stats['trades'] * 100) - 100
wr_delta = phase2_stats['wr'] - phase1_stats['wr']
pnl_delta = phase2_stats['pnl'] - phase1_stats['pnl']
exp_delta = phase2_stats['expectancy'] - phase1_stats['expectancy']

print(f"Trades:        {phase2_stats['trades']:4} vs {phase1_stats['trades']:4} = {trade_delta:+4} ({trade_pct:+.1f}%)")
print(f"Win Rate:      {phase2_stats['wr']:5.1f}% vs {phase1_stats['wr']:5.1f}% = {wr_delta:+5.1f}%")
print(f"Total P&L:     ${phase2_stats['pnl']:6.2f} vs ${phase1_stats['pnl']:6.2f} = ${pnl_delta:+7.2f}")
print(f"Expectancy:    ${phase2_stats['expectancy']:5.2f} vs ${phase1_stats['expectancy']:5.2f} = ${exp_delta:+5.2f}")
print()

# === BUY vs SELL BREAKDOWN ===
print("="*80)
print("  📊 BUY vs SELL COMPARISON")
print("="*80 + "\n")

def buy_sell_analysis(df, phase_name):
    buy = df[df['Type'] == 'BUY']
    sell = df[df['Type'] == 'SELL']
    
    buy_wr = (len(buy[buy['Profit'] > 0]) / len(buy) * 100) if len(buy) > 0 else 0
    sell_wr = (len(sell[sell['Profit'] > 0]) / len(sell) * 100) if len(sell) > 0 else 0
    
    buy_pnl = buy['Profit'].sum()
    sell_pnl = sell['Profit'].sum()
    
    print(f"{phase_name}:")
    print(f"  BUY:   {len(buy):3} trades @ {buy_wr:5.1f}% WR = ${buy_pnl:7.2f}")
    print(f"  SELL:  {len(sell):3} trades @ {sell_wr:5.1f}% WR = ${sell_pnl:7.2f}")
    print()
    
    return {'buy_trades': len(buy), 'buy_wr': buy_wr, 'sell_trades': len(sell), 'sell_wr': sell_wr}

p1_bs = buy_sell_analysis(phase1_trades, "Phase 1")
p2_bs = buy_sell_analysis(phase2_trades, "Phase 2")

# === EXIT REASON COMPARISON ===
print("="*80)
print("  🚪 EXIT REASON COMPARISON")
print("="*80 + "\n")

print("Phase 1 Exits:")
for reason, count in phase1_trades['ExitReason'].value_counts().items():
    pct = count / len(phase1_trades) * 100
    print(f"  {reason:10} {count:4} ({pct:5.1f}%)")

print("\nPhase 2 Exits:")
for reason, count in phase2_trades['ExitReason'].value_counts().items():
    pct = count / len(phase2_trades) * 100
    print(f"  {reason:10} {count:4} ({pct:5.1f}%)")

# === VERDICT ===
print("\n" + "="*80)
print("  ✅ VERDICT")
print("="*80 + "\n")

if phase2_stats['pnl'] > phase1_stats['pnl']:
    print(f"✅ Phase 2 is MORE PROFITABLE: ${pnl_delta:+.2f}")
else:
    print(f"⚠️  Phase 2 is LESS PROFITABLE: ${pnl_delta:+.2f}")

if phase2_stats['wr'] > phase1_stats['wr']:
    print(f"✅ Phase 2 has BETTER WIN RATE: {wr_delta:+.1f}%")
else:
    print(f"⚠️  Phase 2 has WORSE WIN RATE: {wr_delta:+.1f}%")

if phase2_stats['expectancy'] > phase1_stats['expectancy']:
    print(f"✅ Phase 2 has BETTER EXPECTANCY: ${exp_delta:+.2f} per trade")
else:
    print(f"⚠️  Phase 2 has WORSE EXPECTANCY: ${exp_delta:+.2f} per trade")

print("\n💡 Analysis:")
if phase2_stats['trades'] > phase1_stats['trades']:
    print(f"   Phase 2 produced MORE trades ({trade_delta:+d}) than predicted (223)")
    print("   Optimization may have been based on subset of data or different filtering logic")
else:
    print(f"   Phase 2 filtered out {-trade_delta} trades as expected")

print("\n📊 Recommendation:")
if phase2_stats['pnl'] > phase1_stats['pnl'] and phase2_stats['expectancy'] > phase1_stats['expectancy']:
    print("   ✅ USE PHASE 2 SETTINGS - Better profitability and expectancy")
    print("   ✅ Proceed with US30 and GER40 Phase 2 tests")
elif phase2_stats['wr'] > phase1_stats['wr'] + 5:
    print("   ⚠️  MIXED RESULTS - Higher win rate but check if worth fewer trades")
    print("   💡 Consider hybrid approach or further threshold refinement")
else:
    print("   ⚠️  PHASE 1 SETTINGS APPEAR BETTER")
    print("   💡 Re-analyze thresholds or test different optimization criteria")

print("\n" + "="*80 + "\n")
