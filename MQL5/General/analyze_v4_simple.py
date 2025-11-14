#!/usr/bin/env python3
"""
Simple CSV Trade Analyzer for v4.0 Baseline
Works with the simplified CSV format from v4.0
"""

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

def analyze_v4_trades(csv_file):
    """Analyze trades from v4.0 simplified CSV format"""
    
    print(f"{'='*60}")
    print(f"v4.0 BASELINE TRADE ANALYSIS")
    print(f"{'='*60}\n")
    
    # Check if file exists
    csv_path = Path(csv_file)
    if not csv_path.exists():
        print(f"❌ ERROR: File not found: {csv_file}")
        print(f"\nExpected location: {csv_path.absolute()}")
        print(f"\nPlease copy the CSV from MT5 Files folder:")
        print(f"  Windows: C:\\Users\\[YourName]\\AppData\\Roaming\\MetaQuotes\\Terminal\\[ID]\\MQL5\\Files\\")
        print(f"  Mac: ~/Library/Application Support/MetaTrader 5/Bottles/[ID]/MQL5/Files/")
        return
    
    # Load CSV
    try:
        df = pd.read_csv(csv_file)
        print(f"✅ Loaded CSV: {csv_file}")
        print(f"   Rows: {len(df)}")
        print(f"   Columns: {list(df.columns)}\n")
    except Exception as e:
        print(f"❌ ERROR loading CSV: {e}")
        return
    
    # Check if empty
    if len(df) == 0:
        print("⚠️  WARNING: CSV file is EMPTY!")
        print("\nPossible causes:")
        print("  1. EA did not execute any trades during backtest")
        print("  2. CSV logging is disabled (check InpEnableTradeLog)")
        print("  3. File permissions issue")
        print("  4. LogTrade() function not being called")
        print("\nDebugging steps:")
        print("  1. Check MT5 Experts tab - did you see trade execution messages?")
        print("  2. Check MT5 Backtest report - does it show trades?")
        print("  3. Recompile EA and run backtest again")
        print("  4. Check MT5 Files folder for the CSV file")
        return
    
    # Parse timestamp
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    
    # Separate OPEN and CLOSE
    opens = df[df['Action'] == 'OPEN'].copy()
    closes = df[df['Action'] == 'CLOSE'].copy()
    
    print(f"📊 TRADE SUMMARY")
    print(f"{'='*60}")
    print(f"OPEN trades:  {len(opens)}")
    print(f"CLOSE trades: {len(closes)}")
    
    if len(opens) == 0:
        print("\n⚠️  No OPEN trades found!")
        print("The EA may not be triggering entry signals.")
        print("\nCheck:")
        print("  1. MA crossover is happening in your backtest period")
        print("  2. Entry filters are not blocking trades")
        print("  3. Risk management allows trades (equity, consecutive losses)")
        return
    
    # Show sample trades
    print(f"\n📈 SAMPLE OPEN TRADES (first 5):")
    print(opens.head().to_string(index=False))
    
    if len(closes) > 0:
        print(f"\n📉 SAMPLE CLOSE TRADES (first 5):")
        print(closes.head().to_string(index=False))
        
        # Calculate P/L
        print(f"\n{'='*60}")
        print(f"💰 PROFIT/LOSS ANALYSIS")
        print(f"{'='*60}")
        
        # Match trades (simple: assume chronological order)
        num_pairs = min(len(opens), len(closes))
        
        for i in range(num_pairs):
            open_trade = opens.iloc[i]
            close_trade = closes.iloc[i]
            
            if 'BUY' in open_trade['Type']:
                pnl = close_trade['Price'] - open_trade['Price']
            else:
                pnl = open_trade['Price'] - close_trade['Price']
            
            pnl_pct = (pnl / open_trade['Price']) * 100
            duration = (close_trade['Timestamp'] - open_trade['Timestamp']).total_seconds() / 60  # minutes
            
            result = "🟢 WIN" if pnl > 0 else "🔴 LOSS"
            print(f"Trade #{i+1}: {open_trade['Type']} | P/L: {pnl_pct:+.2f}% | Duration: {duration:.0f} min | {result}")
    
    else:
        print(f"\n⚠️  No CLOSE trades found!")
        print("Trades may still be open at end of backtest.")
    
    print(f"\n{'='*60}")
    print("✅ Analysis complete!")
    print(f"{'='*60}\n")


def main():
    import sys
    
    # Default file name
    csv_file = "TP_Crypto_Trades_Cross_v4_0.csv"
    
    # Allow command line argument
    if len(sys.argv) > 1:
        csv_file = sys.argv[1]
    
    print("\n" + "="*60)
    print("TickPhysics v4.0 Baseline CSV Analyzer")
    print("="*60 + "\n")
    
    analyze_v4_trades(csv_file)


if __name__ == "__main__":
    main()
