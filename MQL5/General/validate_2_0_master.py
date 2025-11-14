#!/usr/bin/env python3
"""
Validate TickPhysics CSV Against MT5 Report - 2_0_Master
Short backtest validation before full year run
"""
import csv
import pandas as pd
from pathlib import Path
from datetime import datetime

print("\n" + "="*80)
print("  TICKPHYSICS CSV VALIDATION - 2_0_Master Short Test")
print("="*80 + "\n")

# === CONFIGURATION ===
WORKSPACE = Path(__file__).parent
MT5_BACKTEST_CSVS = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's")  # User's drop folder
ANALYTICS_DATA = WORKSPACE / "analytics_output" / "data" / "backtest"

# File paths (update version/timeframe as needed)
SYMBOL = "NAS100"
TIMEFRAME = "M15"  # Update based on your test
VERSION = "2_0"

MT5_CSV = MT5_BACKTEST_CSVS / f"MTBacktest_Report_{VERSION}_validation.csv"
TP_TRADES_CSV = MT5_BACKTEST_CSVS / f"TP_Integrated_Trades_{SYMBOL}_{TIMEFRAME}_v{VERSION}.csv"
TP_SIGNALS_CSV = MT5_BACKTEST_CSVS / f"TP_Integrated_Signals_{SYMBOL}_{TIMEFRAME}_v{VERSION}.csv"

print("📂 File Locations:")
print(f"   MT5 Report:     {MT5_CSV}")
print(f"   TP Trades CSV:  {TP_TRADES_CSV}")
print(f"   TP Signals CSV: {TP_SIGNALS_CSV}")
print()

# === CHECK FILE EXISTENCE ===
files_exist = True
for file_path, name in [(MT5_CSV, "MT5 CSV"), (TP_TRADES_CSV, "TP Trades"), (TP_SIGNALS_CSV, "TP Signals")]:
    if file_path.exists():
        print(f"✅ {name}: Found")
    else:
        print(f"❌ {name}: MISSING - {file_path}")
        files_exist = False

if not files_exist:
    print("\n⚠️  Please copy CSV files from MT5 Tester directory first!")
    print("\nMT5 Tester Path (Windows):")
    print("  C:\\Users\\[User]\\AppData\\Roaming\\MetaQuotes\\Terminal\\[ID]\\MQL5\\Files\\")
    print("\nMT5 Tester Path (macOS via Wine):")
    print("  ~/Library/Application Support/com.metaquotes.metatrader5/Bottles/")
    print("  metatrader5/drive_c/users/[user]/AppData/Roaming/MetaQuotes/Terminal/[ID]/MQL5/Files/")
    exit(1)

print()

# === LOAD TICKPHYSICS TRADES CSV ===
print("="*80)
print("  LOADING TICKPHYSICS TRADE CSV")
print("="*80 + "\n")

try:
    df_trades = pd.read_csv(TP_TRADES_CSV)
    print(f"✅ Loaded {len(df_trades)} trades from TP CSV")
    print(f"\nColumns ({len(df_trades.columns)}):")
    for col in df_trades.columns:
        print(f"   - {col}")
except Exception as e:
    print(f"❌ Error loading TP Trades CSV: {e}")
    exit(1)

# === VALIDATE CSV STRUCTURE ===
print("\n" + "="*80)
print("  CSV STRUCTURE VALIDATION")
print("="*80 + "\n")

required_columns = [
    'eaName', 'eaVersion', 'ticket', 'openTime', 'closeTime', 'symbol', 'type',
    'lots', 'openPrice', 'closePrice', 'sl', 'tp', 'profit', 'pips',
    'exitReason', 'mfe', 'mae', 'mfePips', 'maePips',
    'runUpPips', 'runDownPips', 'entryQuality', 'entryConfluence'
]

missing_cols = []
for col in required_columns:
    if col in df_trades.columns:
        print(f"✅ {col}")
    else:
        print(f"❌ {col} - MISSING")
        missing_cols.append(col)

if missing_cols:
    print(f"\n⚠️  WARNING: {len(missing_cols)} required columns missing!")
else:
    print("\n✅ All required columns present!")

# === CHECK EA VERSION TRACKING ===
print("\n" + "="*80)
print("  EA VERSION TRACKING")
print("="*80 + "\n")

if 'eaName' in df_trades.columns and 'eaVersion' in df_trades.columns:
    ea_names = df_trades['eaName'].unique()
    ea_versions = df_trades['eaVersion'].unique()
    
    print(f"EA Name(s):    {', '.join(str(x) for x in ea_names)}")
    print(f"EA Version(s): {', '.join(str(x) for x in ea_versions)}")
    
    if len(ea_names) == 1 and len(ea_versions) == 1:
        print("✅ Consistent EA name/version across all trades")
    else:
        print("⚠️  Multiple EA names/versions detected!")
else:
    print("❌ eaName or eaVersion columns missing!")

# === TRADE STATISTICS ===
print("\n" + "="*80)
print("  TICKPHYSICS TRADE STATISTICS")
print("="*80 + "\n")

total_trades = len(df_trades)
total_pnl = df_trades['profit'].sum() if 'profit' in df_trades.columns else 0
wins = len(df_trades[df_trades['profit'] > 0]) if 'profit' in df_trades.columns else 0
losses = len(df_trades[df_trades['profit'] < 0]) if 'profit' in df_trades.columns else 0
win_rate = (wins / total_trades * 100) if total_trades > 0 else 0

print(f"Total Trades:  {total_trades}")
print(f"Wins:          {wins} ({win_rate:.1f}%)")
print(f"Losses:        {losses} ({100-win_rate:.1f}%)")
print(f"Total P&L:     ${total_pnl:.2f}")

if 'pips' in df_trades.columns:
    avg_pips = df_trades['pips'].mean()
    print(f"Avg Pips:      {avg_pips:.2f}")

# === EXIT REASON BREAKDOWN ===
if 'exitReason' in df_trades.columns:
    print("\nExit Reasons:")
    exit_counts = df_trades['exitReason'].value_counts()
    for reason, count in exit_counts.items():
        pct = (count / total_trades * 100)
        print(f"   {reason:<15} {count:>3} trades ({pct:>5.1f}%)")

# === MFE/MAE VALIDATION ===
print("\n" + "="*80)
print("  MFE/MAE/RUNUP/RUNDOWN VALIDATION")
print("="*80 + "\n")

mfe_cols = ['mfe', 'mae', 'mfePips', 'maePips', 'runUpPips', 'runDownPips']
for col in mfe_cols:
    if col in df_trades.columns:
        non_zero = (df_trades[col] != 0).sum()
        pct = (non_zero / total_trades * 100) if total_trades > 0 else 0
        avg_val = df_trades[col].mean()
        print(f"✅ {col:<15} {non_zero}/{total_trades} non-zero ({pct:>5.1f}%) | Avg: {avg_val:>8.2f}")
    else:
        print(f"❌ {col:<15} MISSING")

# === LOAD MT5 CSV FOR COMPARISON ===
print("\n" + "="*80)
print("  MT5 REPORT COMPARISON")
print("="*80 + "\n")

try:
    # Parse MT5 CSV (skip header rows, find data)
    mt5_trades = []
    with open(MT5_CSV, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('Deal') and row.get('Direction') == 'out':
                mt5_trades.append({
                    'deal': row['Deal'],
                    'time': row['Time'],
                    'profit': float(row['Profit'].replace(' ', '').replace(',', '')) if row['Profit'] else 0,
                    'type': row['Type']
                })
    
    mt5_total = len(mt5_trades)
    mt5_pnl = sum(t['profit'] for t in mt5_trades)
    
    print(f"MT5 Total Trades: {mt5_total}")
    print(f"MT5 Total P&L:    ${mt5_pnl:.2f}")
    print()
    
    # Compare
    trade_diff = abs(total_trades - mt5_total)
    pnl_diff = abs(total_pnl - mt5_pnl)
    
    if trade_diff == 0:
        print("✅ Trade count MATCHES!")
    else:
        print(f"⚠️  Trade count MISMATCH: TP={total_trades}, MT5={mt5_total}, Diff={trade_diff}")
    
    if pnl_diff < 1.0:
        print("✅ P&L MATCHES!")
    else:
        print(f"⚠️  P&L MISMATCH: TP=${total_pnl:.2f}, MT5=${mt5_pnl:.2f}, Diff=${pnl_diff:.2f}")
    
    # Calculate accuracy
    matches = sum([trade_diff == 0, pnl_diff < 1.0])
    accuracy = (matches / 2) * 100
    
    print(f"\n📊 Validation Accuracy: {accuracy:.0f}%")
    
except Exception as e:
    print(f"⚠️  Could not parse MT5 CSV: {e}")
    print("   (This is optional - TP CSV validation still passed)")

# === LOAD SIGNALS CSV ===
print("\n" + "="*80)
print("  SIGNAL CSV VALIDATION")
print("="*80 + "\n")

try:
    df_signals = pd.read_csv(TP_SIGNALS_CSV)
    print(f"✅ Loaded {len(df_signals)} signals from TP Signals CSV")
    
    if 'signalType' in df_signals.columns:
        signal_counts = df_signals['signalType'].value_counts()
        print("\nSignal Distribution:")
        for sig_type, count in signal_counts.items():
            pct = (count / len(df_signals) * 100)
            print(f"   {sig_type:<8} {count:>4} ({pct:>5.1f}%)")
    
except Exception as e:
    print(f"⚠️  Could not load Signals CSV: {e}")

# === FINAL SUMMARY ===
print("\n" + "="*80)
print("  VALIDATION SUMMARY")
print("="*80 + "\n")

if not missing_cols and trade_diff == 0 and pnl_diff < 1.0:
    print("✅ ✅ ✅  PERFECT! All validations passed!")
    print("\n🚀 Ready for full year 2024 backtest!")
elif not missing_cols:
    print("✅ CSV structure is perfect!")
    print("⚠️  Minor discrepancies in trade count/P&L - review logs")
else:
    print("⚠️  Some issues detected - review above")

print("\n" + "="*80 + "\n")
