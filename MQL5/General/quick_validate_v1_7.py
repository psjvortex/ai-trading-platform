#!/usr/bin/env python3
"""Quick CSV validation for v1.7"""
import pandas as pd
from pathlib import Path

# Load trades
csv_path = Path(__file__).parent / 'analytics_output/data/backtest/TP_Integrated_Trades_NAS100_M15_v1_7.csv'
df = pd.read_csv(csv_path)

print("\n" + "="*70)
print("  BACKTEST V1.7 - CSV DATA SUMMARY")
print("="*70 + "\n")

print(f"Total Trades: {len(df)}")
print(f"Total P&L: ${df['Profit'].sum():.2f}")

wins = df[df['Profit'] > 0]
losses = df[df['Profit'] < 0]

print(f"Gross Profit: ${wins['Profit'].sum():.2f}")
print(f"Gross Loss: ${losses['Profit'].sum():.2f}")
print(f"Win Rate: {(len(wins) / len(df) * 100):.2f}% ({len(wins)} wins / {len(df)} trades)")
print(f"Loss Rate: {(len(losses) / len(df) * 100):.2f}% ({len(losses)} losses / {len(df)} trades)")
print(f"Initial Balance: $1000.00")
print(f"Final Balance: ${1000 + df['Profit'].sum():.2f}")
print()

print("Exit Reason Breakdown:")
exit_counts = df['ExitReason'].value_counts()
for reason, count in exit_counts.items():
    pct = (count / len(df)) * 100
    print(f"  {reason}: {count} trades ({pct:.1f}%)")
print()

print("Date Range:")
df['OpenTime'] = pd.to_datetime(df['OpenTime'])
df['CloseTime'] = pd.to_datetime(df['CloseTime'])
print(f"  Start: {df['OpenTime'].min()}")
print(f"  End: {df['CloseTime'].max()}")
print(f"  Duration: {(df['CloseTime'].max() - df['OpenTime'].min()).days} days")
print()

print("EA Version Tracking:")
print(f"  EA Name: {df['EAName'].iloc[0]}")
print(f"  EA Version: {df['EAVersion'].iloc[0]}")
print(f"  Symbol: {df['Symbol'].iloc[0]}")
print()

print("Trade Type Breakdown:")
type_counts = df['Type'].value_counts()
for trade_type, count in type_counts.items():
    pct = (count / len(df)) * 100
    print(f"  {trade_type}: {count} trades ({pct:.1f}%)")
print()

print("="*70)
print("✅ CSV Data Analysis Complete!")
print()
print("NEXT STEPS:")
print("1. Open: MQL5/MT5 Reports/MTBacktest_Report_1_7.pdf")
print("2. Compare the above CSV numbers with the PDF report")
print("3. Verify Total Trades, P&L, Win Rate match")
print("="*70 + "\n")
