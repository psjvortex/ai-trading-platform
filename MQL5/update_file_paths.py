#!/usr/bin/env python3
"""
Update File Paths After Directory Reorganization

This script updates all Python scripts in the General/ folder to reference
CSV files in the new Backtest_Reports/ folder.

Directory structure:
- MQL5/Backtest_Reports/ - All CSV files (MTBacktest, Trades, Signals)
- MQL5/General/ - All Python scripts, docs, and other files
"""

import os
import re
from pathlib import Path

# Define paths
MQL5_DIR = Path(__file__).parent
GENERAL_DIR = MQL5_DIR / "General"
BACKTEST_DIR = MQL5_DIR / "Backtest_Reports"

# Patterns to replace
PATTERNS = [
    # Direct CSV references without path (most common)
    (r"pd\.read_csv\('(TP_Integrated_[^']+\.csv)'\)", 
     r"pd.read_csv('../Backtest_Reports/\1')"),
    
    (r'pd\.read_csv\("(TP_Integrated_[^"]+\.csv)"\)', 
     r'pd.read_csv("../Backtest_Reports/\1")'),
    
    (r"pd\.read_csv\('(MTBacktest_[^']+\.csv)'\)", 
     r"pd.read_csv('../Backtest_Reports/\1')"),
    
    (r'pd\.read_csv\("(MTBacktest_[^"]+\.csv)"\)', 
     r'pd.read_csv("../Backtest_Reports/\1")'),
    
    # File path construction patterns
    (r'f"(TP_Integrated_Trades_[^"]+)"', 
     r'f"../Backtest_Reports/TP_Integrated_Trades_{symbol}_v{version}.csv"'),
    
    (r'f"(TP_Integrated_Signals_[^"]+)"', 
     r'f"../Backtest_Reports/TP_Integrated_Signals_{symbol}_v{version}.csv"'),
]

def update_file(filepath):
    """Update file paths in a Python file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Apply each pattern
        for pattern, replacement in PATTERNS:
            matches = re.findall(pattern, content)
            if matches:
                content = re.sub(pattern, replacement, content)
                changes_made.extend(matches)
        
        # Only write if changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True, changes_made
        
        return False, []
        
    except Exception as e:
        print(f"  ❌ Error processing {filepath.name}: {e}")
        return False, []

def main():
    print("=" * 80)
    print("🔧 UPDATING FILE PATHS IN PYTHON SCRIPTS")
    print("=" * 80)
    print()
    print(f"📁 General folder: {GENERAL_DIR}")
    print(f"📁 Backtest folder: {BACKTEST_DIR}")
    print()
    
    # Get all Python files in General folder
    py_files = list(GENERAL_DIR.glob("*.py"))
    
    print(f"Found {len(py_files)} Python files to check...")
    print()
    
    updated_count = 0
    skipped_count = 0
    
    for py_file in sorted(py_files):
        updated, changes = update_file(py_file)
        
        if updated:
            updated_count += 1
            print(f"✅ Updated: {py_file.name}")
            if changes:
                print(f"   Changed: {len(changes)} CSV references")
        else:
            skipped_count += 1
    
    print()
    print("=" * 80)
    print("📊 SUMMARY")
    print("=" * 80)
    print(f"✅ Updated: {updated_count} files")
    print(f"⏭️  Skipped: {skipped_count} files (no changes needed)")
    print(f"📝 Total: {len(py_files)} files processed")
    print()
    
    # Verify CSV files are in Backtest_Reports
    csv_files = list(BACKTEST_DIR.glob("*.csv"))
    print(f"📦 CSV files in Backtest_Reports/: {len(csv_files)}")
    print()
    
    # Show breakdown
    trades_count = len(list(BACKTEST_DIR.glob("TP_Integrated_Trades_*.csv")))
    signals_count = len(list(BACKTEST_DIR.glob("TP_Integrated_Signals_*.csv")))
    mt5_count = len(list(BACKTEST_DIR.glob("*MTBacktest*.csv")))
    
    print(f"  - Trades files: {trades_count}")
    print(f"  - Signals files: {signals_count}")
    print(f"  - MT5 Reports: {mt5_count}")
    print()
    
    print("✅ File path update complete!")
    print()
    print("⚠️  MANUAL REVIEW NEEDED:")
    print("   - Scripts with complex path logic may need manual updates")
    print("   - Check scripts that use pathlib.Path() constructions")
    print("   - Test critical scripts before running")
    print()

if __name__ == "__main__":
    main()
