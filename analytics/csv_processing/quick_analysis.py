import pandas as pd
import sys

# Load the data
try:
    df = pd.read_csv('/Users/patjohnston/ai-trading-platform/analytics/csv_processing/output/processed_trades_2025-11-26.csv')
except FileNotFoundError:
    print("Error: CSV file not found.")
    sys.exit(1)

# Basic Stats
total_trades = len(df)
total_profit = df['OUT_Profit_OP_01'].sum()
avg_profit = total_profit / total_trades if total_trades > 0 else 0

# Win Rate
wins = df[df['Trade_Result'] == 'Win']
losses = df[df['Trade_Result'] == 'Loss']
win_rate = len(wins) / total_trades * 100 if total_trades > 0 else 0

# Long vs Short Analysis
longs = df[df['Trade_Direction'] == 'Long']
shorts = df[df['Trade_Direction'] == 'Short']

long_profit = longs['OUT_Profit_OP_01'].sum()
short_profit = shorts['OUT_Profit_OP_01'].sum()

long_wins = len(longs[longs['Trade_Result'] == 'Win'])
short_wins = len(shorts[shorts['Trade_Result'] == 'Win'])

long_win_rate = long_wins / len(longs) * 100 if len(longs) > 0 else 0
short_win_rate = short_wins / len(shorts) * 100 if len(shorts) > 0 else 0

# Commission/Swap Analysis
total_commission = df['OUT_Commission'].sum()
total_swap = df['OUT_Swap'].sum()

# Output Report
print(f"--- Performance Summary ---")
print(f"Total Trades: {total_trades}")
print(f"Net Profit: ${total_profit:.2f}")
print(f"Avg Profit/Trade: ${avg_profit:.2f}")
print(f"Win Rate: {win_rate:.2f}%")
print(f"")
print(f"--- Directional Analysis ---")
print(f"Longs: {len(longs)} trades | Win Rate: {long_win_rate:.2f}% | Profit: ${long_profit:.2f}")
print(f"Shorts: {len(shorts)} trades | Win Rate: {short_win_rate:.2f}% | Profit: ${short_profit:.2f}")
print(f"")
print(f"--- Cost Analysis ---")
print(f"Total Commission: ${total_commission:.2f}")
print(f"Total Swap: ${total_swap:.2f}")
print(f"")
print(f"--- Top 5 Worst Losses ---")
print(df.sort_values('OUT_Profit_OP_01').head(5)[['IN_MT_MASTER_DATE_TIME', 'Trade_Direction', 'OUT_Profit_OP_01']].to_string(index=False))
