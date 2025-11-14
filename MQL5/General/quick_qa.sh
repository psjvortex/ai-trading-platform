#!/bin/bash

# TickPhysics Quick QA Script
# Automates the process of running backtests and analyzing results

set -e

echo "🚀 TickPhysics Quick QA Workflow"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MQL5_FILES_DIR="$HOME/Library/Application Support/MetaQuotes/Terminal/*/MQL5/Files"
OUTPUT_DIR="./backtest_results"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}Step 1: Checking for CSV log files...${NC}"

# Find the most recent signals and trades files
SIGNALS_FILE=$(find $MQL5_FILES_DIR -name "TP_Crypto_Signals_v2.0.csv" -type f 2>/dev/null | head -1)
TRADES_FILE=$(find $MQL5_FILES_DIR -name "TP_Crypto_Trades_v2.0.csv" -type f 2>/dev/null | head -1)

if [ -z "$SIGNALS_FILE" ] || [ -z "$TRADES_FILE" ]; then
    echo -e "${YELLOW}⚠️  CSV files not found in MetaTrader Files directory${NC}"
    echo "Please run a backtest in MetaTrader 5 Strategy Tester first."
    echo "Expected files:"
    echo "  - TP_Crypto_Signals_v2.0.csv"
    echo "  - TP_Crypto_Trades_v2.0.csv"
    exit 1
fi

echo -e "${GREEN}✅ Found CSV files:${NC}"
echo "  Signals: $SIGNALS_FILE"
echo "  Trades: $TRADES_FILE"
echo ""

# Copy files to output directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
cp "$SIGNALS_FILE" "$OUTPUT_DIR/signals_${TIMESTAMP}.csv"
cp "$TRADES_FILE" "$OUTPUT_DIR/trades_${TIMESTAMP}.csv"

echo -e "${BLUE}Step 2: Running analysis...${NC}"
python3 analyze_backtest.py analyze \
    "$OUTPUT_DIR/signals_${TIMESTAMP}.csv" \
    "$OUTPUT_DIR/trades_${TIMESTAMP}.csv" \
    --export "$OUTPUT_DIR/analysis_${TIMESTAMP}.json"

echo ""
echo -e "${BLUE}Step 3: Would you like to launch the dashboard? (y/n)${NC}"
read -r LAUNCH_DASHBOARD

if [ "$LAUNCH_DASHBOARD" = "y" ] || [ "$LAUNCH_DASHBOARD" = "Y" ]; then
    echo -e "${GREEN}🚀 Launching dashboard...${NC}"
    python3 dashboard.py \
        "$OUTPUT_DIR/signals_${TIMESTAMP}.csv" \
        "$OUTPUT_DIR/trades_${TIMESTAMP}.csv"
fi

echo ""
echo -e "${GREEN}✅ QA workflow complete!${NC}"
echo "Results saved to: $OUTPUT_DIR"
