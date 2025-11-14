#!/usr/bin/env python3
"""
Quick Test Runner for Exit Reason Validation
This script automates the CSV collection and validation process.
"""

import sys
import subprocess
from pathlib import Path
import shutil

# Configuration
MT5_FILES_DIR = Path.home() / "Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files"
LOCAL_DIR = Path(__file__).parent
DEFAULT_SYMBOL = "NAS100"

def find_latest_csv():
    """Find the latest TP_Tracker CSV file"""
    pattern = "TP_Tracker_Test_Trades_*.csv"
    files = list(MT5_FILES_DIR.glob(pattern))
    
    if not files:
        print(f"❌ No CSV files found in {MT5_FILES_DIR}")
        print(f"   Looking for pattern: {pattern}")
        return None
    
    # Get most recently modified
    latest = max(files, key=lambda p: p.stat().st_mtime)
    return latest

def copy_csv_local(source_path):
    """Copy CSV to local directory for analysis"""
    dest = LOCAL_DIR / "test_trades.csv"
    
    try:
        shutil.copy2(source_path, dest)
        print(f"✅ Copied CSV to: {dest}")
        return dest
    except Exception as e:
        print(f"❌ Failed to copy CSV: {e}")
        return None

def run_validation(csv_path):
    """Run the validation script"""
    script = LOCAL_DIR / "validate_exit_reasons.py"
    
    if not script.exists():
        print(f"❌ Validation script not found: {script}")
        return False
    
    try:
        result = subprocess.run(
            [sys.executable, str(script), str(csv_path)],
            capture_output=False,
            text=True
        )
        return result.returncode == 0
    except Exception as e:
        print(f"❌ Failed to run validation: {e}")
        return False

def main():
    print("=" * 70)
    print("🚀 TP_Trade_Tracker Exit Reason Test Runner")
    print("=" * 70)
    print()
    
    # Step 1: Find CSV
    print("📁 Step 1: Locating CSV file...")
    csv_source = find_latest_csv()
    
    if not csv_source:
        print()
        print("💡 Instructions:")
        print("   1. Run Test_TradeTracker EA in MetaTrader 5")
        print("   2. Execute trades with SL, TP, and MANUAL exits")
        print("   3. Wait for CSV to be generated")
        print("   4. Run this script again")
        return 1
    
    print(f"✅ Found: {csv_source.name}")
    print(f"   Modified: {csv_source.stat().st_mtime}")
    print()
    
    # Step 2: Copy CSV
    print("📋 Step 2: Copying CSV to local directory...")
    local_csv = copy_csv_local(csv_source)
    
    if not local_csv:
        return 1
    print()
    
    # Step 3: Run validation
    print("🔍 Step 3: Running validation...")
    print("=" * 70)
    success = run_validation(local_csv)
    print()
    
    if success:
        print("=" * 70)
        print("✅ TEST PASSED: Exit reason detection is working correctly!")
        print("=" * 70)
        print()
        print("🎯 Next Steps:")
        print("   1. Review the validation report above")
        print("   2. Check RunUp/RunDown data quality")
        print("   3. Run extended backtest if needed")
        print("   4. Integrate with production EA")
        return 0
    else:
        print("=" * 70)
        print("❌ TEST FAILED: Issues detected in exit reason logging")
        print("=" * 70)
        print()
        print("🔧 Debugging Steps:")
        print("   1. Review the validation report above")
        print("   2. Check MQL5/BUGFIX_EXIT_REASON_DETECTION.md")
        print("   3. Verify DetermineExitReason() implementation")
        print("   4. Re-compile and re-test")
        return 1

if __name__ == "__main__":
    sys.exit(main())
