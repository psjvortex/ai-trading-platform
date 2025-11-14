"""
TickPhysics CSV Logger - RunUp/RunDown Analysis Script
Analyze post-exit trade behavior for TP/SL optimization

Usage:
    python analyze_runupdown.py

Requirements:
    pip install pandas matplotlib seaborn

Input Files (from MQL5/Files/):
    - TP_Test_Trades_NAS100.csv (or your trade log)

Output:
    - Console analysis report
    - Visualizations (optional)
"""

import pandas as pd
import sys
from pathlib import Path

def analyze_runupdown(csv_file):
    """Analyze RunUp/RunDown metrics from trade log"""
    
    print("=" * 60)
    print("📊 TickPhysics RunUp/RunDown Analysis")
    print("=" * 60)
    
    # Load data
    try:
        df = pd.read_csv(csv_file)
        print(f"\n✅ Loaded: {csv_file}")
        print(f"   Total trades: {len(df)}")
        print(f"   Total columns: {len(df.columns)}")
    except FileNotFoundError:
        print(f"\n❌ ERROR: File not found: {csv_file}")
        print("   Make sure you've run Test_CSVLogger.mq5 first!")
        sys.exit(1)
    
    # Verify RunUp/RunDown columns exist
    required_cols = ['RunUp_Pips', 'RunDown_Pips', 'RunUp_TimeBars', 'RunDown_TimeBars']
    missing = [col for col in required_cols if col not in df.columns]
    if missing:
        print(f"\n❌ ERROR: Missing columns: {missing}")
        print("   Make sure you're using the enhanced v8.0.1 logger!")
        sys.exit(1)
    
    print("\n✅ RunUp/RunDown columns found!")
    
    # Split by profit/loss
    winning = df[df['Profit'] > 0]
    losing = df[df['Profit'] < 0]
    
    print("\n" + "=" * 60)
    print("📈 WINNING TRADES ANALYSIS")
    print("=" * 60)
    
    if len(winning) > 0:
        print(f"\nTotal Winning Trades: {len(winning)}")
        print(f"Average Profit: {winning['Pips'].mean():.1f} pips")
        print(f"Average MFE (during trade): {winning['MFE_Pips'].mean():.1f} pips")
        print(f"Average RunUp (after exit): {winning['RunUp_Pips'].mean():.1f} pips")
        
        # Money left on table
        left_on_table = winning['RunUp_Pips'].sum()
        total_profit = winning['Pips'].sum()
        potential_profit = total_profit + left_on_table
        capture_rate = (total_profit / potential_profit * 100) if potential_profit > 0 else 0
        
        print(f"\n💰 Exit Efficiency:")
        print(f"   Captured: {total_profit:.1f} pips")
        print(f"   Left on table: {left_on_table:.1f} pips")
        print(f"   Potential: {potential_profit:.1f} pips")
        print(f"   Capture rate: {capture_rate:.1f}%")
        
        # Early exit detection
        early_exits = winning[winning['RunUp_Pips'] > winning['Pips'] * 0.3]
        if len(early_exits) > 0:
            print(f"\n⚠️ Early Exits Detected:")
            print(f"   {len(early_exits)} trades had RunUp > 30% of profit")
            print(f"   Average RunUp on early exits: {early_exits['RunUp_Pips'].mean():.1f} pips")
            print(f"   💡 Recommendation: Consider wider TP or trailing stop")
        
        # Timing analysis
        print(f"\n⏱️ Timing:")
        print(f"   Average bars to RunUp peak: {winning['RunUp_TimeBars'].mean():.0f}")
        quick_runups = winning[winning['RunUp_TimeBars'] < 10]
        print(f"   RunUp within 10 bars: {len(quick_runups)} trades ({len(quick_runups)/len(winning)*100:.1f}%)")
        
    else:
        print("\nNo winning trades found.")
    
    print("\n" + "=" * 60)
    print("📉 LOSING TRADES ANALYSIS")
    print("=" * 60)
    
    if len(losing) > 0:
        print(f"\nTotal Losing Trades: {len(losing)}")
        print(f"Average Loss: {losing['Pips'].mean():.1f} pips")
        print(f"Average MAE (during trade): {losing['MAE_Pips'].mean():.1f} pips")
        print(f"Average RunDown (after exit): {losing['RunDown_Pips'].mean():.1f} pips")
        
        # Shake-out detection (for SELL trades)
        # For BUY: RunDown should be negative (price went down after exit)
        # For SELL: RunDown should be negative BUT that means price went down (favorable!)
        
        # Better approach: Check if exit was SL and price reversed favorably
        sl_exits = losing[losing['ExitReason'] == 'SL']
        
        if len(sl_exits) > 0:
            print(f"\n🛑 Stop Loss Analysis:")
            print(f"   SL exits: {len(sl_exits)} / {len(losing)}")
            
            # For shake-out: Price should have moved favorably AFTER SL
            # This is complex as it depends on trade direction
            # Simplification: If abs(RunDown) > abs(Loss), price reversed significantly
            shaken_out = sl_exits[abs(sl_exits['RunDown_Pips']) > abs(sl_exits['Pips']) * 0.5]
            
            if len(shaken_out) > 0:
                print(f"\n⚠️ Potential Shake-Outs Detected:")
                print(f"   {len(shaken_out)} SL exits had significant reversal after")
                print(f"   Average loss: {shaken_out['Pips'].mean():.1f} pips")
                print(f"   Average reversal: {shaken_out['RunDown_Pips'].mean():.1f} pips")
                print(f"   Average bars to reversal: {shaken_out['RunDown_TimeBars'].mean():.0f}")
                print(f"   💡 Recommendation: Consider wider SL or better entry timing")
        
    else:
        print("\nNo losing trades found.")
    
    print("\n" + "=" * 60)
    print("📋 DETAILED TRADE BREAKDOWN")
    print("=" * 60)
    
    for idx, row in df.iterrows():
        print(f"\nTrade #{row['Ticket']}")
        print(f"  Type: {row['Type']}, Exit: {row['ExitReason']}")
        print(f"  Profit: {row['Pips']:.1f} pips (${row['Profit']:.2f})")
        print(f"  During Trade:")
        print(f"    MFE: {row['MFE_Pips']:.1f} pips @ bar {row['MFE_TimeBars']}")
        print(f"    MAE: {row['MAE_Pips']:.1f} pips @ bar {row['MAE_TimeBars']}")
        print(f"  After Exit:")
        print(f"    RunUp: {row['RunUp_Pips']:.1f} pips @ bar {row['RunUp_TimeBars']}")
        print(f"    RunDown: {row['RunDown_Pips']:.1f} pips @ bar {row['RunDown_TimeBars']}")
        
        # Analysis
        if row['Profit'] > 0:
            if row['RunUp_Pips'] > row['Pips'] * 0.5:
                print(f"  📊 Analysis: Left {row['RunUp_Pips']:.1f} pips on table (TP too early)")
            else:
                print(f"  ✅ Analysis: Good exit, minimal runup after")
        else:
            if row['ExitReason'] == 'SL' and abs(row['RunDown_Pips']) > abs(row['Pips']):
                print(f"  ⚠️ Analysis: Potential shake-out (reversed {abs(row['RunDown_Pips']):.1f} pips after SL)")
            else:
                print(f"  ℹ️ Analysis: Normal losing trade")
    
    print("\n" + "=" * 60)
    print("💡 RECOMMENDATIONS")
    print("=" * 60)
    
    if len(df) > 0:
        # Overall metrics
        avg_capture_rate = df[df['Profit'] > 0]['Pips'].sum() / (df[df['Profit'] > 0]['Pips'].sum() + df[df['Profit'] > 0]['RunUp_Pips'].sum()) * 100 if len(winning) > 0 else 0
        
        print(f"\n1. Exit Efficiency: {avg_capture_rate:.1f}%")
        if avg_capture_rate < 70:
            print("   → Consider wider TP or trailing stop mechanism")
        else:
            print("   → Exit timing looks good!")
        
        if len(losing) > 0:
            shake_rate = len(sl_exits[abs(sl_exits['RunDown_Pips']) > abs(sl_exits['Pips']) * 0.5]) / len(losing) * 100 if len(sl_exits) > 0 else 0
            print(f"\n2. Shake-Out Rate: {shake_rate:.1f}%")
            if shake_rate > 30:
                print("   → Consider wider SL distance (current too tight)")
            else:
                print("   → SL distance appears reasonable")
        
        print(f"\n3. Timing Insights:")
        avg_runup_bars = df['RunUp_TimeBars'].mean()
        print(f"   → RunUp typically occurs within {avg_runup_bars:.0f} bars")
        if avg_runup_bars < 20:
            print("   → Consider short-term trailing stop (quick moves)")
        else:
            print("   → Consider longer-term position management")
    
    print("\n" + "=" * 60)
    print("✅ Analysis Complete!")
    print("=" * 60)


def main():
    """Main entry point"""
    
    # MetaTrader Files folder (primary source)
    mt5_files = Path.home() / "Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files"
    
    # Try to find CSV in common locations (prioritize MT5 folder)
    possible_paths = [
        mt5_files / "TP_Test_Trades_NAS100.csv",  # Direct from MT5
        mt5_files / "CSV" / "TP_Test_Trades_NAS100.csv",  # MT5 CSV subfolder
        "CSV/TP_Test_Trades_NAS100.csv",  # Local workspace copy
        "TP_Test_Trades_NAS100.csv",  # Current directory
        "../MQL5/CSV/TP_Test_Trades_NAS100.csv",  # Workspace backup
    ]
    
    csv_file = None
    for path in possible_paths:
        if Path(path).exists():
            csv_file = str(path)
            print(f"📂 Found CSV at: {path}")
            break
    
    if csv_file is None:
        print("\n❌ Could not auto-locate CSV file.")
        print("\nPlease provide the path to your trade log CSV:")
        print("Example: TP_Test_Trades_NAS100.csv")
        csv_input = input("\nPath: ").strip()
        if csv_input:
            csv_file = csv_input
        else:
            csv_file = "TP_Test_Trades_NAS100.csv"
    
    analyze_runupdown(csv_file)


if __name__ == "__main__":
    main()
