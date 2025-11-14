#!/usr/bin/env python3
"""
Parse MT5 CSV Report and Validate Against TickPhysics CSV
"""
import csv
from pathlib import Path

# Parse MT5 CSV Report
mt5_file = Path(__file__).parent / "MT5 Excel Reports" / "MTBacktest_Report_1_7.csv"

print("\n" + "="*70)
print("  MT5 REPORT PARSER - V1.7 VALIDATION")
print("="*70 + "\n")

# Read MT5 CSV
trades = []
total_profit = 0.0
initial_balance = 0.0
final_balance = 0.0

with open(mt5_file, 'r', encoding='utf-8-sig') as f:
    # utf-8-sig removes BOM character
    reader = csv.DictReader(f, skipinitialspace=True)
    
    for row in reader:
        # Skip empty rows
        if not row['Deal']:
            continue
            
        deal_num = row['Deal']
        deal_type = row['Type']
        direction = row['Direction']
        
        # Track initial balance
        if deal_type == 'balance':
            initial_balance = float(row['Balance'].replace(' ', ''))
            print(f"Initial Balance: ${initial_balance:,.2f}")
            continue
        
        # Process trades (we want 'out' direction to count completed trades)
        if direction == 'out':
            profit_str = row['Profit'].replace(' ', '').replace(',', '')
            profit = float(profit_str) if profit_str else 0.0
            balance_str = row['Balance'].replace(' ', '').replace(',', '')
            balance = float(balance_str) if balance_str else 0.0
            
            trades.append({
                'deal': deal_num,
                'time': row['Time'],
                'symbol': row['Symbol'],
                'type': deal_type,
                'volume': row['Volume'],
                'price': row['Price'],
                'profit': profit,
                'balance': balance,
                'comment': row['Comment']
            })
            
            total_profit += profit
            final_balance = balance

print(f"Parsed {len(trades)} completed trades\n")

# Calculate statistics
wins = [t for t in trades if t['profit'] > 0]
losses = [t for t in trades if t['profit'] < 0]
gross_profit = sum(t['profit'] for t in wins)
gross_loss = sum(t['profit'] for t in losses)
win_rate = (len(wins) / len(trades) * 100) if len(trades) > 0 else 0.0

# Count exit types
sl_count = sum(1 for t in trades if 'sl' in t['comment'].lower())
tp_count = sum(1 for t in trades if 'tp' in t['comment'].lower())

print("="*70)
print("  MT5 REPORT STATISTICS")
print("="*70 + "\n")

print(f"Total Trades:        {len(trades)}")
print(f"Total P&L:          ${total_profit:,.2f}")
print(f"Gross Profit:        ${gross_profit:,.2f}")
print(f"Gross Loss:          ${gross_loss:,.2f}")
print(f"Win Rate:            {win_rate:.2f}% ({len(wins)} wins / {len(losses)} losses)")
print(f"Initial Balance:     ${initial_balance:,.2f}")
print(f"Final Balance:       ${final_balance:,.2f}")
print(f"\nExit Breakdown:")
print(f"  SL (Stop Loss):    {sl_count} trades ({sl_count/len(trades)*100:.1f}%)")
print(f"  TP (Take Profit):  {tp_count} trades ({tp_count/len(trades)*100:.1f}%)")

print("\n" + "="*70)
print("  COMPARISON: MT5 vs CSV")
print("="*70 + "\n")

# CSV Stats (from previous analysis)
csv_stats = {
    'total_trades': 46,
    'total_pnl': -312.02,
    'gross_profit': 67.73,
    'gross_loss': -379.75,
    'win_rate': 8.70,
    'final_balance': 687.98,
    'sl_count': 42,
    'tp_count': 4
}

# Compare
def compare_values(name, mt5_val, csv_val, tolerance=0.5, is_pct=False):
    if is_pct:
        match = abs(mt5_val - csv_val) < 1.0
        diff = mt5_val - csv_val
        status = "✓ MATCH" if match else f"✗ DIFF: {diff:+.2f}%"
    else:
        match = abs(mt5_val - csv_val) < tolerance
        diff = mt5_val - csv_val
        status = "✓ MATCH" if match else f"✗ DIFF: ${diff:+.2f}"
    
    print(f"{name:<25} MT5: {mt5_val:>12.2f}  CSV: {csv_val:>12.2f}  {status}")
    return match

all_match = True
all_match &= compare_values("Total Trades", len(trades), csv_stats['total_trades'], tolerance=0)
all_match &= compare_values("Total P&L ($)", total_profit, csv_stats['total_pnl'])
all_match &= compare_values("Gross Profit ($)", gross_profit, csv_stats['gross_profit'])
all_match &= compare_values("Gross Loss ($)", gross_loss, csv_stats['gross_loss'])
all_match &= compare_values("Win Rate (%)", win_rate, csv_stats['win_rate'], is_pct=True)
all_match &= compare_values("Final Balance ($)", final_balance, csv_stats['final_balance'])
all_match &= compare_values("SL Count", sl_count, csv_stats['sl_count'], tolerance=0)
all_match &= compare_values("TP Count", tp_count, csv_stats['tp_count'], tolerance=0)

# Calculate accuracy
total_metrics = 8
matched_metrics = sum([
    len(trades) == csv_stats['total_trades'],
    abs(total_profit - csv_stats['total_pnl']) < 0.5,
    abs(gross_profit - csv_stats['gross_profit']) < 0.5,
    abs(gross_loss - csv_stats['gross_loss']) < 0.5,
    abs(win_rate - csv_stats['win_rate']) < 1.0,
    abs(final_balance - csv_stats['final_balance']) < 0.5,
    sl_count == csv_stats['sl_count'],
    tp_count == csv_stats['tp_count']
])

accuracy = (matched_metrics / total_metrics) * 100

print("\n" + "="*70)
print(f"  VALIDATION RESULT: {accuracy:.1f}% ACCURACY")
print("="*70 + "\n")

if accuracy == 100.0:
    print("✅ PERFECT MATCH! CSV logging is 100% accurate vs MT5 report")
elif accuracy >= 99.0:
    print("✅ EXCELLENT! CSV logging is 99%+ accurate vs MT5 report")
elif accuracy >= 95.0:
    print("⚠️  GOOD: CSV logging is 95%+ accurate (minor rounding differences)")
else:
    print("❌ DISCREPANCY: CSV accuracy below 95% - review required")

print(f"\nMatched Metrics: {matched_metrics}/{total_metrics}")
print("\n" + "="*70 + "\n")

# Show first and last trade for verification
print("FIRST TRADE VERIFICATION:")
first = trades[0]
print(f"  Deal: {first['deal']} | Time: {first['time']}")
print(f"  Type: {first['type']} | Profit: ${first['profit']:.2f}")
print(f"  Comment: {first['comment']}")

print("\nLAST TRADE VERIFICATION:")
last = trades[-1]
print(f"  Deal: {last['deal']} | Time: {last['time']}")
print(f"  Type: {last['type']} | Profit: ${last['profit']:.2f}")
print(f"  Comment: {last['comment']}")

print("\n" + "="*70 + "\n")
