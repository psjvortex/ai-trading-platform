#!/usr/bin/env python3
"""
v4.18.0 Phase 1 Analysis - Relaxed Settings Baseline
Analyzes NAS100 M05 backtest results with Phase 1 settings

Workflow:
1. Validate: EA trades CSV vs MT5 backtest report
2. Analyze: Trade performance and BUY/SELL breakdown
3. Correlate: Match signals with trades for physics analysis
"""
import pandas as pd
import numpy as np
import csv
from pathlib import Path

# === FILE PATHS ===
DESKTOP_FOLDER = Path("/Users/patjohnston/Desktop/MT5 EA Backtest CSV Folder")
MT5_REPORT = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_MT5Backtest.csv"
SIGNALS_CSV = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_signals.csv"
TRADES_CSV = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.180_SLOPE_trades.csv"

print("\n" + "="*80)
print("  🚀 PHASE 1 ANALYSIS - v4.18.0 BASELINE RESULTS")
print("="*80 + "\n")

# === STEP 1: VALIDATE EA TRADES CSV VS MT5 REPORT ===
print("="*80)
print("  STEP 1: VALIDATE EA TRADES CSV vs MT5 BACKTEST REPORT")
print("="*80 + "\n")

# Load EA trades
try:
    df_trades = pd.read_csv(TRADES_CSV)
    tp_count = len(df_trades)
    tp_pnl = df_trades['Profit'].sum()
    print(f"✅ EA Trades CSV:  {tp_count} trades, ${tp_pnl:.2f} P&L")
except Exception as e:
    print(f"❌ Error loading EA trades: {e}")
    exit(1)

# Load MT5 report
try:
    mt5_trades = []
    with open(MT5_REPORT, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('Deal') and row.get('Direction') == 'out':
                profit_str = row.get('Profit', '0').replace(' ', '').replace(',', '')
                mt5_trades.append({
                    'deal': row['Deal'],
                    'profit': float(profit_str) if profit_str else 0
                })
    
    mt5_count = len(mt5_trades)
    mt5_pnl = sum(t['profit'] for t in mt5_trades)
    print(f"✅ MT5 Report:     {mt5_count} trades, ${mt5_pnl:.2f} P&L\n")
    
    # Validation
    trade_match = (tp_count == mt5_count)
    pnl_match = abs(tp_pnl - mt5_pnl) < 1.0
    
    print("Validation Results:")
    if trade_match:
        print(f"  ✅ Trade count MATCHES ({tp_count} trades)")
    else:
        print(f"  ⚠️  Trade count MISMATCH: EA={tp_count}, MT5={mt5_count}, Diff={abs(tp_count - mt5_count)}")
    
    if pnl_match:
        print(f"  ✅ P&L MATCHES (${tp_pnl:.2f})")
    else:
        print(f"  ⚠️  P&L MISMATCH: EA=${tp_pnl:.2f}, MT5=${mt5_pnl:.2f}, Diff=${abs(tp_pnl - mt5_pnl):.2f}")
    
    if trade_match and pnl_match:
        print("\n🎉 VALIDATION PASSED - EA CSV matches MT5 backtest report!\n")
    else:
        print("\n⚠️  VALIDATION WARNING - Minor discrepancies detected\n")
        
except Exception as e:
    print(f"❌ Error loading MT5 report: {e}")
    print("⚠️  Proceeding with EA trades analysis only\n")

# Load signals for later correlation
try:
    df_signals = pd.read_csv(SIGNALS_CSV)
    print(f"✅ Signals CSV: {len(df_signals)} signals loaded\n")
except Exception as e:
    print(f"❌ Error loading signals: {e}")
    df_signals = None

# === BASIC STATISTICS ===
print("="*80)
print("  STEP 2: TRADE PERFORMANCE ANALYSIS")
print("="*80 + "\n")

total_trades = len(df_trades)
if total_trades == 0:
    print("❌ No trades found! Check backtest execution.")
    exit(1)

wins = len(df_trades[df_trades['Profit'] > 0])
losses = len(df_trades[df_trades['Profit'] <= 0])
win_rate = (wins / total_trades * 100) if total_trades > 0 else 0

total_pnl = df_trades['Profit'].sum()
avg_win = df_trades[df_trades['Profit'] > 0]['Profit'].mean() if wins > 0 else 0
avg_loss = df_trades[df_trades['Profit'] <= 0]['Profit'].mean() if losses > 0 else 0

print(f"Total Trades:     {total_trades}")
print(f"Wins:             {wins} ({win_rate:.1f}%)")
print(f"Losses:           {losses} ({100-win_rate:.1f}%)")
print(f"Total P&L:        ${total_pnl:.2f}")
print(f"Avg Win:          ${avg_win:.2f}")
print(f"Avg Loss:         ${avg_loss:.2f}")
print(f"Win/Loss Ratio:   {abs(avg_win/avg_loss):.2f}:1" if avg_loss != 0 else "N/A")

# Expectancy
expectancy = (win_rate/100 * avg_win) + ((1-win_rate/100) * avg_loss)
print(f"Expectancy:       ${expectancy:.2f} per trade")

# === BUY vs SELL BREAKDOWN ===
print("\n" + "="*80)
print("  📈 BUY vs SELL PERFORMANCE")
print("="*80 + "\n")

# Type column: "BUY" or "SELL" strings
buy_trades = df_trades[df_trades['Type'] == 'BUY']
sell_trades = df_trades[df_trades['Type'] == 'SELL']

for trade_type, trades_df, label in [('BUY', buy_trades, "BUY"), ('SELL', sell_trades, "SELL")]:
    if len(trades_df) == 0:
        print(f"{label:4} Trades: 0")
        continue
    
    wins_sig = len(trades_df[trades_df['Profit'] > 0])
    wr_sig = (wins_sig / len(trades_df) * 100)
    pnl_sig = trades_df['Profit'].sum()
    
    print(f"{label:4} Trades: {len(trades_df):3} | Win Rate: {wr_sig:5.1f}% | P&L: ${pnl_sig:8.2f}")

# === PHYSICS METRICS CORRELATION WITH WINS ===
print("\n" + "="*80)
print("  🔬 PHYSICS METRICS - WIN/LOSS CORRELATION")
print("="*80 + "\n")

# Entry columns use format: EntryMomentum, EntrySpeed (not entryMomentum)
physics_cols = ['EntryMomentum', 'EntryAcceleration', 'EntrySpeed']

for col in physics_cols:
    if col not in df_trades.columns:
        print(f"⚠️  {col} not found in trades CSV")
        continue
    
    win_trades = df_trades[df_trades['Profit'] > 0]
    loss_trades = df_trades[df_trades['Profit'] <= 0]
    
    if len(win_trades) > 0 and len(loss_trades) > 0:
        win_avg = win_trades[col].mean()
        loss_avg = loss_trades[col].mean()
        diff = win_avg - loss_avg
        
        print(f"{col:25} | Wins: {win_avg:8.2f} | Losses: {loss_avg:8.2f} | Diff: {diff:8.2f}")

# === BUY PHYSICS BREAKDOWN ===
print("\n" + "="*80)
print("  📈 BUY TRADES - PHYSICS ANALYSIS")
print("="*80 + "\n")

if len(buy_trades) > 0:
    buy_wins = buy_trades[buy_trades['Profit'] > 0]
    buy_losses = buy_trades[buy_trades['Profit'] <= 0]
    
    print(f"BUY Trades: {len(buy_trades)} ({len(buy_wins)} wins, {len(buy_losses)} losses)\n")
    
    for col in ['EntrySpeed', 'EntryMomentum', 'EntryAcceleration']:
        if col in buy_trades.columns:
            win_avg = buy_wins[col].mean() if len(buy_wins) > 0 else 0
            loss_avg = buy_losses[col].mean() if len(buy_losses) > 0 else 0
            print(f"  {col:20} | Wins: {win_avg:8.2f} | Losses: {loss_avg:8.2f}")

# === SELL PHYSICS BREAKDOWN ===
print("\n" + "="*80)
print("  📉 SELL TRADES - PHYSICS ANALYSIS")
print("="*80 + "\n")

if len(sell_trades) > 0:
    sell_wins = sell_trades[sell_trades['Profit'] > 0]
    sell_losses = sell_trades[sell_trades['Profit'] <= 0]
    
    print(f"SELL Trades: {len(sell_trades)} ({len(sell_wins)} wins, {len(sell_losses)} losses)\n")
    
    for col in ['EntrySpeed', 'EntryMomentum', 'EntryAcceleration']:
        if col in sell_trades.columns:
            win_avg = sell_wins[col].mean() if len(sell_wins) > 0 else 0
            loss_avg = sell_losses[col].mean() if len(sell_losses) > 0 else 0
            print(f"  {col:20} | Wins: {win_avg:8.2f} | Losses: {loss_avg:8.2f}")

# === SLOPE ANALYSIS ===
print("\n" + "="*80)
print("  STEP 3: SIGNAL-TO-TRADE CORRELATION ANALYSIS")
print("="*80 + "\n")

if df_signals is None:
    print("❌ Signals CSV not loaded - skipping correlation analysis\n")
else:
    print(f"Total Signals: {len(df_signals)}")
    print(f"Total Trades:  {len(df_trades)}")
    print(f"Execution Rate: {(len(df_trades)/len(df_signals)*100):.1f}%\n")
    
    # Check if slope columns exist in signals
    slope_cols = ['speedSlope', 'accelerationSlope', 'momentumSlope']
    available_slopes = [col for col in slope_cols if col in df_signals.columns]
    
    if available_slopes:
        print(f"✅ Found {len(available_slopes)} slope metrics in signals CSV")
        print("   (Detailed signal-trade correlation analysis requires matching timestamps)\n")
    else:
        print("⚠️  No slope columns found in signals CSV")
        print("   Available columns:", ', '.join(df_signals.columns[:10]), "...\n")

# === SIGNAL ANALYSIS ===
print("\n" + "="*80)
print("  🎲 SIGNAL GENERATION ANALYSIS")
print("="*80 + "\n")

total_signals = len(df_signals)
if total_signals > 0:
    print(f"Total Signals Generated: {total_signals}")
    print(f"Signals Executed:        {total_trades} ({(total_trades/total_signals*100):.1f}%)")
    print(f"Signals Filtered Out:    {total_signals - total_trades}\n")
    
    # Signal type breakdown
    if 'signalType' in df_signals.columns:
        print("Signal Type Distribution:")
        for sig_type, count in df_signals['signalType'].value_counts().items():
            pct = (count / total_signals * 100)
            print(f"  {sig_type:20} {count:5} ({pct:5.1f}%)")

# === REJECTION ANALYSIS ===
print("\n" + "="*80)
print("  ⚠️  REJECTION REASON ANALYSIS")
print("="*80 + "\n")

if 'physicsPass' in df_signals.columns:
    passed = len(df_signals[df_signals['physicsPass'] == 'PASS'])
    rejected = len(df_signals[df_signals['physicsPass'] == 'REJECT'])
    
    print(f"Physics Filters PASS:   {passed} ({(passed/total_signals*100):.1f}%)")
    print(f"Physics Filters REJECT: {rejected} ({(rejected/total_signals*100):.1f}%)\n")
    
    if 'rejectReason' in df_signals.columns:
        rejections = df_signals[df_signals['physicsPass'] == 'REJECT']
        if len(rejections) > 0:
            print("Top 10 Rejection Reasons:")
            for reason, count in rejections['rejectReason'].value_counts().head(10).items():
                pct = (count / len(rejections) * 100)
                print(f"  {reason:35} {count:4} ({pct:5.1f}%)")

# === THRESHOLD OPTIMIZATION HINTS ===
print("\n" + "="*80)
print("  💡 THRESHOLD OPTIMIZATION HINTS")
print("="*80 + "\n")

print("Current Phase 1 Settings:")
print("  MaxSpreadPips:        25.0")
print("  MinPhysicsScore:      40.0")
print("  MinAccelerationBuy:   80.0")
print("  MinAccelerationSell: -80.0")
print("  MinSpeedBuy:          55.0")
print("  MinSpeedSell:        -55.0")
print("  MinMomentumBuy:       30.0")
print("  MinMomentumSell:     -30.0")
print("  RequireFullConfluence: false\n")

# Analyze if thresholds are too loose/tight based on EntryMomentum (only metric we have)
if len(buy_trades) > 0 and 'EntryMomentum' in df_trades.columns:
    buy_wins = buy_trades[buy_trades['Profit'] > 0]
    buy_losses = buy_trades[buy_trades['Profit'] <= 0]
    
    if len(buy_wins) > 0 and len(buy_losses) > 0:
        buy_mom_win = buy_wins['EntryMomentum'].mean()
        buy_mom_loss = buy_losses['EntryMomentum'].mean()
        
        if buy_mom_win > buy_mom_loss + 5:
            print(f"💡 BUY: Winners have higher Momentum ({buy_mom_win:.1f} vs {buy_mom_loss:.1f})")
            print(f"   Consider raising MinMomentumBuy from 30.0 to {buy_mom_loss:.0f}\n")

if len(sell_trades) > 0 and 'EntryMomentum' in df_trades.columns:
    sell_wins = sell_trades[sell_trades['Profit'] > 0]
    sell_losses = sell_trades[sell_trades['Profit'] <= 0]
    
    if len(sell_wins) > 0 and len(sell_losses) > 0:
        sell_mom_win = sell_wins['EntryMomentum'].mean()
        sell_mom_loss = sell_losses['EntryMomentum'].mean()
        
        if sell_mom_win < sell_mom_loss - 5:
            print(f"💡 SELL: Winners have lower Momentum ({sell_mom_win:.1f} vs {sell_mom_loss:.1f})")
            print(f"   Consider lowering MinMomentumSell from -30.0 to {sell_mom_loss:.0f}\n")

# === FINAL SUMMARY ===
print("="*80)
print("  ✅ PHASE 1 ANALYSIS COMPLETE")
print("="*80 + "\n")

if win_rate >= 40:
    print(f"✅ Win rate {win_rate:.1f}% meets baseline target (40%+)")
else:
    print(f"⚠️  Win rate {win_rate:.1f}% below target (need 40%+ for 2:1 R:R)")

if total_trades >= 50:
    print(f"✅ Sample size {total_trades} is statistically significant (50+ trades)")
else:
    print(f"⚠️  Sample size {total_trades} is small (need 50+ for statistical significance)")

print(f"\n💰 Net Result: ${total_pnl:.2f}")
print(f"📊 Expectancy: ${expectancy:.2f} per trade")

if expectancy > 0:
    print("\n🎉 System shows positive expectancy with Phase 1 settings!")
else:
    print("\n⚠️  System shows negative expectancy - threshold optimization needed")

print("\n" + "="*80 + "\n")
