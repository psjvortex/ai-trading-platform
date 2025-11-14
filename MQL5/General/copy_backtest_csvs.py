#!/usr/bin/env python3
"""
Copy backtest CSV files from MT5 Tester folder to workspace for analysis
Run this after each backtest to bring CSVs into the project
Supports v1.3+ with timeframe tracking
"""

import shutil
import os
from pathlib import Path
from analytics_config import OUTPUT_DIR, PATHS, DEFAULT_SYMBOL, DEFAULT_TIMEFRAME, DEFAULT_VERSION

def copy_backtest_csvs(symbol='NAS100', timeframe='M5', version='1.3'):
    """Copy backtest CSVs to workspace"""
    
    print("═══════════════════════════════════════════════════════")
    print("📂 Copying Backtest CSVs to Workspace")
    print("═══════════════════════════════════════════════════════")
    print(f"Symbol: {symbol} | Timeframe: {timeframe} | Version: {version}")
    print()
    
    # Create data directory
    data_dir = OUTPUT_DIR / 'data' / 'backtest'
    data_dir.mkdir(parents=True, exist_ok=True)
    
    # Source directory
    source_dir = Path(PATHS['backtest']['root'])
    
    files_copied = 0
    
    # File patterns with timeframe
    trades_file = f"TP_Integrated_Trades_{symbol}_{timeframe}_v{version}.csv"
    signals_file = f"TP_Integrated_Signals_{symbol}_{timeframe}_v{version}.csv"
    
    for file_type, filename in [('TRADES', trades_file), ('SIGNALS', signals_file)]:
        src = source_dir / filename
        dest = data_dir / filename
        
        if os.path.exists(src):
            shutil.copy2(src, dest)
            file_size = os.path.getsize(dest)
            print(f"✅ Copied: {file_type}")
            print(f"   From: {src}")
            print(f"   To: {dest}")
            print(f"   Size: {file_size:,} bytes")
            files_copied += 1
        else:
            print(f"❌ NOT FOUND: {file_type}")
            print(f"   Path: {src}")
    
    print("═══════════════════════════════════════════════════════")
    print(f"📊 Result: {files_copied}/2 files copied")
    
    if files_copied == 2:
        print("✅ All backtest CSVs successfully copied!")
        print(f"📁 Location: {data_dir}")
        return True
    else:
        print("⚠️  Some files missing - check paths")
        return False

if __name__ == "__main__":
    import sys
    
    symbol = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SYMBOL
    timeframe = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_TIMEFRAME
    version = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_VERSION
    
    success = copy_backtest_csvs(symbol, timeframe, version)
    sys.exit(0 if success else 1)
