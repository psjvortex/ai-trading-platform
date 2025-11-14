#!/usr/bin/env python3
"""
Exit Reason Validation Script
Validates that TP_Trade_Tracker correctly logs exit reasons (SL/TP/MANUAL)
"""

import pandas as pd
import sys
from pathlib import Path

def validate_exit_reasons(csv_path):
    """
    Validate exit reason detection in trade CSV
    """
    print("=" * 70)
    print("🔍 Exit Reason Validation Report")
    print("=" * 70)
    
    if not Path(csv_path).exists():
        print(f"❌ ERROR: CSV file not found: {csv_path}")
        return False
    
    # Load CSV
    try:
        df = pd.read_csv(csv_path)
        print(f"✅ Loaded CSV: {csv_path}")
        print(f"📊 Total trades: {len(df)}")
        print()
    except Exception as e:
        print(f"❌ ERROR loading CSV: {e}")
        return False
    
    # Check required columns
    required_cols = ['ExitReason', 'ClosePrice', 'SL', 'TP', 'Profit']
    missing = [col for col in required_cols if col not in df.columns]
    if missing:
        print(f"❌ Missing columns: {missing}")
        return False
    
    print("✅ All required columns present")
    print()
    
    # Analyze exit reasons
    print("📋 EXIT REASON DISTRIBUTION")
    print("-" * 70)
    exit_counts = df['ExitReason'].value_counts()
    for reason, count in exit_counts.items():
        pct = (count / len(df)) * 100
        print(f"  {reason:12s}: {count:3d} trades ({pct:5.1f}%)")
    print()
    
    # Validate SL exits
    print("🔍 VALIDATING SL EXITS")
    print("-" * 70)
    sl_exits = df[df['ExitReason'] == 'SL']
    if len(sl_exits) > 0:
        sl_valid = 0
        sl_invalid = 0
        
        for idx, row in sl_exits.iterrows():
            close_price = row['ClosePrice']
            sl = row['SL']
            tolerance = 5.0  # pips (adjust for symbol)
            
            # Check if close price is within tolerance of SL
            if abs(close_price - sl) <= tolerance:
                sl_valid += 1
            else:
                sl_invalid += 1
                print(f"  ⚠️  Trade #{int(row['Ticket'])}: Close={close_price:.2f}, SL={sl:.2f}, Diff={abs(close_price-sl):.2f}")
        
        print(f"  ✅ Valid SL exits: {sl_valid}/{len(sl_exits)}")
        if sl_invalid > 0:
            print(f"  ⚠️  Invalid SL exits: {sl_invalid}/{len(sl_exits)}")
    else:
        print("  ℹ️  No SL exits found")
    print()
    
    # Validate TP exits
    print("🔍 VALIDATING TP EXITS")
    print("-" * 70)
    tp_exits = df[df['ExitReason'] == 'TP']
    if len(tp_exits) > 0:
        tp_valid = 0
        tp_invalid = 0
        
        for idx, row in tp_exits.iterrows():
            close_price = row['ClosePrice']
            tp = row['TP']
            tolerance = 5.0  # pips
            
            if abs(close_price - tp) <= tolerance:
                tp_valid += 1
            else:
                tp_invalid += 1
                print(f"  ⚠️  Trade #{int(row['Ticket'])}: Close={close_price:.2f}, TP={tp:.2f}, Diff={abs(close_price-tp):.2f}")
        
        print(f"  ✅ Valid TP exits: {tp_valid}/{len(tp_exits)}")
        if tp_invalid > 0:
            print(f"  ⚠️  Invalid TP exits: {tp_invalid}/{len(tp_exits)}")
    else:
        print("  ℹ️  No TP exits found")
    print()
    
    # Check for "MANUAL" as default (potential bug)
    print("🔍 CHECKING FOR POTENTIAL BUGS")
    print("-" * 70)
    if exit_counts.get('MANUAL', 0) == len(df):
        print("  ❌ CRITICAL: All trades marked as MANUAL - detection broken!")
        return False
    else:
        print("  ✅ Exit reason detection appears to be working")
    print()
    
    # Profit analysis by exit reason
    print("💰 PROFIT ANALYSIS BY EXIT REASON")
    print("-" * 70)
    for reason in exit_counts.index:
        subset = df[df['ExitReason'] == reason]
        avg_profit = subset['Profit'].mean()
        win_rate = (subset['Profit'] > 0).sum() / len(subset) * 100
        print(f"  {reason:12s}: Avg Profit = ${avg_profit:7.2f}, Win Rate = {win_rate:5.1f}%")
    print()
    
    # RunUp/RunDown analysis (if available)
    if 'RunUpPips' in df.columns and 'RunDownPips' in df.columns:
        print("📊 RUNUP/RUNDOWN ANALYSIS BY EXIT REASON")
        print("-" * 70)
        for reason in exit_counts.index:
            subset = df[df['ExitReason'] == reason]
            avg_runup = subset['RunUpPips'].mean()
            avg_rundown = subset['RunDownPips'].mean()
            print(f"  {reason:12s}: RunUp = {avg_runup:6.2f} pips, RunDown = {avg_rundown:6.2f} pips")
        print()
        
        # Shake-out detection for SL exits
        if len(sl_exits) > 0:
            print("🎯 SHAKE-OUT DETECTION (SL Exits with Large RunDown)")
            print("-" * 70)
            shakeouts = sl_exits[sl_exits['RunDownPips'] > 20.0]  # Adjust threshold
            if len(shakeouts) > 0:
                print(f"  ⚠️  Potential shake-outs: {len(shakeouts)}/{len(sl_exits)} SL exits")
                for idx, row in shakeouts.head(5).iterrows():
                    print(f"    Trade #{int(row['Ticket'])}: RunDown = {row['RunDownPips']:.2f} pips (SL too tight?)")
            else:
                print("  ✅ No obvious shake-outs detected")
            print()
    
    print("=" * 70)
    print("✅ VALIDATION COMPLETE")
    print("=" * 70)
    
    return True


if __name__ == "__main__":
    # Default path
    csv_path = "Files/TP_Tracker_Test_Trades_NAS100.csv"
    
    # Allow custom path from command line
    if len(sys.argv) > 1:
        csv_path = sys.argv[1]
    
    success = validate_exit_reasons(csv_path)
    sys.exit(0 if success else 1)
