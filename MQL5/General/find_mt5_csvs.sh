#!/bin/bash
#
# Find MT5 Tester Directory and List Recent CSV Files
#

echo "========================================================================"
echo "  MT5 TESTER DIRECTORY FINDER - macOS"
echo "========================================================================"
echo ""

# Base path for MetaTrader 5 on macOS (Wine)
BASE_PATH="$HOME/Library/Application Support/com.metaquotes.metatrader5/Bottles/metatrader5/drive_c/users"

echo "🔍 Searching for MT5 Terminal directories..."
echo ""

# Find all Terminal directories
TERMINAL_DIRS=$(find "$BASE_PATH" -type d -name "Terminal" 2>/dev/null)

if [ -z "$TERMINAL_DIRS" ]; then
    echo "❌ No Terminal directories found!"
    echo ""
    echo "Possible reasons:"
    echo "  1. MT5 not installed via Wine"
    echo "  2. Different installation path"
    echo "  3. No backtests run yet"
    exit 1
fi

# Loop through each Terminal directory
while IFS= read -r TERMINAL_DIR; do
    echo "📁 Found Terminal: $TERMINAL_DIR"
    
    # List subdirectories (each is a Terminal ID)
    for TERMINAL_ID_DIR in "$TERMINAL_DIR"/*/; do
        if [ -d "$TERMINAL_ID_DIR" ]; then
            TERMINAL_ID=$(basename "$TERMINAL_ID_DIR")
            FILES_DIR="$TERMINAL_ID_DIR/MQL5/Files"
            
            echo "   Terminal ID: $TERMINAL_ID"
            
            if [ -d "$FILES_DIR" ]; then
                echo "   ✅ Files directory exists: $FILES_DIR"
                
                # Count TP_Integrated CSV files
                TP_COUNT=$(find "$FILES_DIR" -name "TP_Integrated*.csv" 2>/dev/null | wc -l)
                
                if [ $TP_COUNT -gt 0 ]; then
                    echo "   🎯 Found $TP_COUNT TickPhysics CSV files:"
                    find "$FILES_DIR" -name "TP_Integrated*.csv" -exec ls -lh {} \; | while read -r line; do
                        echo "      $line"
                    done
                else
                    echo "   ⚠️  No TickPhysics CSV files found"
                fi
                
                echo ""
            else
                echo "   ❌ Files directory not found"
                echo ""
            fi
        fi
    done
done <<< "$TERMINAL_DIRS"

echo "========================================================================"
echo "  COPY COMMAND GENERATOR"
echo "========================================================================"
echo ""
echo "To copy CSV files to workspace, use:"
echo ""
echo "cp \"$FILES_DIR\"/TP_Integrated*.csv \\"
echo "   /Users/patjohnston/ai-trading-platform/MQL5/analytics_output/data/backtest/"
echo ""
echo "Or to see what will be copied first:"
echo ""
echo "ls -lh \"$FILES_DIR\"/TP_Integrated*.csv"
echo ""
echo "========================================================================"
