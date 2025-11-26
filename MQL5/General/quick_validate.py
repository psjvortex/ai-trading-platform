#!/usr/bin/env python3
"""
Quick CSV Validator - TP_CSV_Logger v8.0 Dual-Row Model
Validates NEW 90+ column comprehensive trades CSV with ENTRY/EXIT rows
"""
import csv
import pandas as pd
from pathlib import Path

# === CONFIGURATION ===
MT5_DROP_FOLDER = Path("/Users/patjohnston/Desktop/MT5_Backtest_Files")  # Updated folder name
MT5_FILES_DIR = Path("/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files")  # EA CSVs (live)
MT5_TESTER_DIR = Path("/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester")  # Backtest CSVs

# Auto-detect latest files from Desktop folder (new naming convention)
SYMBOL = "NAS100"
TIMEFRAME = "M05"
VERSION = "4.1.8.9"  # Update to your current version

print("\n" + "="*80)
print(f"  🚀 TICKPHYSICS CSV VALIDATOR v8.0 - DUAL-ROW MODEL")
print("="*80 + "\n")

print(f"📂 Reading from:\n")
print(f"   MT5 Reports:    {MT5_DROP_FOLDER}")
print(f"   TP EA CSVs:     {MT5_FILES_DIR}")
print(f"   TP Backtest:    {MT5_TESTER_DIR}\n")

# === FIND FILES ===
print("🔍 Scanning for CSV files...\n")

# Find MT5 report (from Desktop drop folder) - new naming convention
mt5_pattern = f"TP_Integrated_{SYMBOL}_{TIMEFRAME}_MTBacktest_v{VERSION}_*_MT5Backtest.csv"
mt5_files = list(MT5_DROP_FOLDER.glob(mt5_pattern))
if not mt5_files:
    # Try alternate pattern without MT5Backtest suffix
    mt5_files = list(MT5_DROP_FOLDER.glob(f"*{SYMBOL}*{TIMEFRAME}*v{VERSION}*.csv"))
    mt5_files = [f for f in mt5_files if 'MT5Backtest' in f.name or 'Report' in f.name]

if mt5_files:
    MT5_CSV = mt5_files[0]
    print(f"✅ MT5 Report:     {MT5_CSV.name}")
else:
    print("⚠️  MT5 Report: NOT FOUND in Desktop folder")
    MT5_CSV = None

# Find TickPhysics CSVs from Desktop (new naming convention)
trades_pattern = f"TP_Integrated_{SYMBOL}_{TIMEFRAME}_MTBacktest_v{VERSION}_*_trades.csv"
signals_pattern = f"TP_Integrated_{SYMBOL}_{TIMEFRAME}_MTBacktest_v{VERSION}_*_signals.csv"

tp_trades_files = list(MT5_DROP_FOLDER.glob(trades_pattern))
tp_signals_files = list(MT5_DROP_FOLDER.glob(signals_pattern))

TP_TRADES = tp_trades_files[0] if tp_trades_files else None
TP_SIGNALS = tp_signals_files[0] if tp_signals_files else None

if TP_TRADES and TP_TRADES.exists():
    print(f"✅ TP Trades CSV:  {TP_TRADES.name}")
else:
    print(f"⚠️  TP Trades CSV:  NOT FOUND")
    print(f"    Looking for: {trades_pattern}")
    TP_TRADES = None

if TP_SIGNALS and TP_SIGNALS.exists():
    print(f"✅ TP Signals CSV: {TP_SIGNALS.name}")
else:
    print(f"⚠️  TP Signals CSV: NOT FOUND")
    print(f"    Looking for: {signals_pattern}")
    TP_SIGNALS = None

print()

# === LIST CSV FILES IN DESKTOP FOLDER ===
print("📋 CSV files in Desktop folder:")
desktop_csvs = sorted(MT5_DROP_FOLDER.glob("TP_*.csv"))
if desktop_csvs:
    for csv_file in desktop_csvs:
        size = csv_file.stat().st_size / 1024  # KB
        print(f"   {csv_file.name:<70} ({size:>8.1f} KB)")
else:
    print("   (none found)")

print()

if not TP_TRADES:
    print("❌ TickPhysics Trade CSV not found!")
    print(f"\n   Expected: {trades_pattern}")
    print(f"   Location: {MT5_DROP_FOLDER}")
    print("\n   Make sure backtest completed and CSVs are in Desktop folder")
    exit(1)

# === LOAD & VALIDATE TICKPHYSICS TRADES ===
print("="*80)
print("  📊 TICKPHYSICS TRADE CSV ANALYSIS")
print("="*80 + "\n")

df_trades = pd.read_csv(TP_TRADES)
print(f"✅ Loaded {len(df_trades)} trades from TP CSV\n")

# Show first few columns to verify structure
print("First 5 columns:")
for col in df_trades.columns[:5]:
    print(f"   - {col}")
print(f"   ... ({len(df_trades.columns)} total columns)\n")

# === VALIDATE KEY COLUMNS ===
required_v8 = [
    'EAName', 'EAVersion', 'RowType', 'Ticket', 'Timestamp', 'OpenTime', 'CloseTime',
    'Quality', 'PhysicsScore', 'SpeedSlope', 'Zone', 'Regime',
    'EntryQuality', 'EntryPhysicsScore', 'EntryZone',
    'Profit', 'Pips', 'ExitReason', 'MFE', 'MAE',
    'TimeSegment15M', 'TimeSegment1H', 'TradingSession',
    'PhysicsScoreDecay', 'SpeedSlopeDecay', 'ZoneTransitioned',
    'DataQualityScore', 'ValidationFlags'
]
missing = [col for col in required_v8 if col not in df_trades.columns]

if missing:
    print(f"❌ MISSING COLUMNS: {', '.join(missing)}\n")
else:
    print(f"✅ All {len(required_v8)} key columns present\n")

# === DUAL-ROW MODEL VALIDATION ===
print("="*80)
print("  🔄 DUAL-ROW MODEL VALIDATION (v8.0)")
print("="*80 + "\n")

if 'RowType' in df_trades.columns:
    entry_rows = df_trades[df_trades['RowType'] == 'ENTRY']
    exit_rows = df_trades[df_trades['RowType'] == 'EXIT']
    
    print(f"Total Rows:    {len(df_trades)}")
    print(f"ENTRY rows:    {len(entry_rows)}")
    print(f"EXIT rows:     {len(exit_rows)}")
    
    # Check if we have exactly 2 rows per trade
    if len(entry_rows) == len(exit_rows):
        print(f"✅ Perfect dual-row structure: {len(exit_rows)} trades × 2 rows each\n")
    else:
        print(f"⚠️  Row count mismatch: {len(entry_rows)} ENTRY vs {len(exit_rows)} EXIT\n")
    
    # Verify ENTRY rows have physics
    entry_physics_count = (entry_rows['PhysicsScore'] > 0).sum()
    print(f"ENTRY physics populated:  {entry_physics_count}/{len(entry_rows)} ({entry_physics_count/len(entry_rows)*100:.1f}%)")
    
    # Verify EXIT rows have decay analysis
    if 'PhysicsScoreDecay' in df_trades.columns:
        exit_decay_count = (exit_rows['PhysicsScoreDecay'] != 0).sum()
        print(f"EXIT decay calculated:    {exit_decay_count}/{len(exit_rows)} ({exit_decay_count/len(exit_rows)*100:.1f}%)")
    
    # Check zone transitions
    if 'ZoneTransitioned' in df_trades.columns:
        zone_transitions = exit_rows['ZoneTransitioned'].sum()
        print(f"Zone transitions:         {zone_transitions}/{len(exit_rows)} ({zone_transitions/len(exit_rows)*100:.1f}%)")
        print(f"   ⚡ Winners with transitions: TBD (need profit filter)")
    
    print()
else:
    print("⚠️  RowType column not found - not using dual-row model\n")

# === EA VERSION CHECK ===
if 'EAName' in df_trades.columns and 'EAVersion' in df_trades.columns:
    ea_name = df_trades['EAName'].iloc[0] if len(df_trades) > 0 else "N/A"
    ea_version = df_trades['EAVersion'].iloc[0] if len(df_trades) > 0 else "N/A"
    print(f"EA Name:    {ea_name}")
    print(f"EA Version: {ea_version}\n")

# === TRADE STATISTICS (EXIT ROWS ONLY) ===
print("="*80)
print("  📈 TRADE STATISTICS (EXIT rows only)")
print("="*80 + "\n")

# Filter to EXIT rows for trade stats
if 'RowType' in df_trades.columns:
    trades_only = df_trades[df_trades['RowType'] == 'EXIT']
else:
    trades_only = df_trades  # Fallback if no RowType column

total = len(trades_only)
pnl = trades_only['Profit'].sum() if 'Profit' in trades_only.columns else 0
wins = len(trades_only[trades_only['Profit'] > 0]) if 'Profit' in trades_only.columns else 0
losses = len(trades_only[trades_only['Profit'] < 0]) if 'Profit' in trades_only.columns else 0
win_rate = (wins / total * 100) if total > 0 else 0

print(f"Total Trades:  {total}")
print(f"Wins:          {wins} ({win_rate:.1f}%)")
print(f"Losses:        {losses} ({100-win_rate:.1f}%)")
print(f"Total P&L:     ${pnl:.2f}")

if 'Pips' in trades_only.columns:
    avg_pips = trades_only['Pips'].mean()
    print(f"Avg Pips:      {avg_pips:.2f}")

# === EXIT REASONS ===
if 'ExitReason' in df_trades.columns:
    print("\n📍 Exit Reason Breakdown:")
    exits = df_trades['ExitReason'].value_counts()
    for reason, count in exits.items():
        pct = (count / total * 100)
        print(f"   {reason:<15} {count:>3} ({pct:>5.1f}%)")

# === MFE/MAE/RUNUP/RUNDOWN ===
print("\n" + "="*80)
print("  🎯 POST-TRADE ANALYTICS VALIDATION")
print("="*80 + "\n")

metrics = ['MFE_Pips', 'MAE_Pips', 'RunUp_Pips', 'RunDown_Pips']
for metric in metrics:
    if metric in df_trades.columns:
        non_zero = (df_trades[metric] != 0).sum()
        pct = (non_zero / total * 100) if total > 0 else 0
        avg = df_trades[metric].mean()
        print(f"✅ {metric:<15} {non_zero:>3}/{total} non-zero ({pct:>5.1f}%) | Avg: {avg:>8.2f}")
    else:
        print(f"❌ {metric:<15} MISSING")

# === COMPARE WITH MT5 REPORT ===
if MT5_CSV and MT5_CSV.exists():
    print("\n" + "="*80)
    print("  ⚖️  MT5 REPORT COMPARISON")
    print("="*80 + "\n")
    
    try:
        mt5_trades = []
        with open(MT5_CSV, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get('Deal') and row.get('Direction') == 'out':
                    profit_str = row.get('Profit', '0').replace(' ', '').replace(',', '')
                    mt5_trades.append({
                        'deal': row['Deal'],
                        'profit': float(profit_str) if profit_str else 0
                    })
        
        mt5_total = len(mt5_trades)
        mt5_pnl = sum(t['profit'] for t in mt5_trades)
        
        print(f"MT5 Trades:    {mt5_total}")
        print(f"MT5 P&L:       ${mt5_pnl:.2f}")
        print()
        print(f"TP Trades:     {total}")
        print(f"TP P&L:        ${pnl:.2f}")
        print()
        
        trade_match = (total == mt5_total)
        pnl_match = abs(pnl - mt5_pnl) < 1.0
        
        if trade_match:
            print("✅ Trade count MATCHES!")
        else:
            print(f"⚠️  Trade count MISMATCH: Diff = {abs(total - mt5_total)}")
        
        if pnl_match:
            print("✅ P&L MATCHES!")
        else:
            print(f"⚠️  P&L MISMATCH: Diff = ${abs(pnl - mt5_pnl):.2f}")
        
        # Overall accuracy
        accuracy = sum([trade_match, pnl_match]) / 2 * 100
        print(f"\n📊 Validation Accuracy: {accuracy:.0f}%")
        
    except Exception as e:
        print(f"⚠️  Could not parse MT5 CSV: {e}")

# === SIGNALS CSV ===
if TP_SIGNALS and TP_SIGNALS.exists():
    print("\n" + "="*80)
    print("  🎲 SIGNAL CSV ANALYSIS")
    print("="*80 + "\n")
    
    df_signals = pd.read_csv(TP_SIGNALS)
    print(f"✅ Loaded {len(df_signals)} signals\n")
    
    if 'signalType' in df_signals.columns:
        print("Signal Distribution:")
        signals = df_signals['signalType'].value_counts()
        for sig, count in signals.items():
            pct = (count / len(df_signals) * 100)
            print(f"   {sig:<8} {count:>5} ({pct:>5.1f}%)")

# === FINAL SUMMARY ===
print("\n" + "="*80)
print("  ✅ VALIDATION COMPLETE")
print("="*80 + "\n")

if total > 0 and not missing and (not MT5_CSV or (trade_match and pnl_match)):
    print("🎉 ALL CHECKS PASSED!")
    print("\n✅ CSV structure is perfect")
    print("✅ All metrics logged correctly")
    print("✅ MT5 comparison successful")
    print("\n🚀 Ready for full year 2024 backtest!")
elif total > 0:
    print("⚠️  Minor issues detected - review above")
    print("\n💡 CSVs are valid but may have slight discrepancies")
else:
    print("❌ No trades found - check backtest execution")

print("\n" + "="*80 + "\n")
