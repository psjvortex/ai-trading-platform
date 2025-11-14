# TickPhysics Crypto Trading System - QA & Analysis Guide

## 🎯 Quick Start: Proving Self-Learning & Self-Healing

This guide will help you quickly validate and demonstrate the self-learning and self-healing capabilities of your TickPhysics EA.

---

## 📋 Prerequisites

1. **MetaTrader 5** installed with TickPhysics EA and Indicator compiled
2. **Python 3.8+** installed on your Mac
3. **VS Code** with Copilot (optional, for development)

---

## 🚀 Setup Instructions

### 1. Install Python Dependencies

```bash
cd /Users/patjohnston/ai-trading-platform/MQL5
pip3 install -r requirements.txt
```

This installs:
- `pandas` - Data analysis
- `plotly` - Interactive charts
- `dash` - Web-based dashboard

### 2. Make Scripts Executable

```bash
chmod +x quick_qa.sh
```

---

## 📊 QA Workflow: Validating Self-Healing

### **Phase 1: Baseline Run (No Self-Healing)**

#### Step 1: Configure EA for Baseline
In MetaTrader 5, temporarily disable or minimize self-healing features:
- Set `MinQuality` to a low value (e.g., 30)
- Set `MinConfluence` to a low value (e.g., 2.0)
- This allows more trades to pass through, establishing a baseline

#### Step 2: Run Backtest
1. Open **Strategy Tester** in MT5 (Ctrl+R)
2. Select **TickPhysics_Crypto_SelfHealing_EA_v2_1**
3. Choose symbol: **ETHUSD** or **BTCUSD**
4. Timeframe: **M5**
5. Date range: **Last 3 months**
6. Click **Start**

#### Step 3: Locate CSV Files
After backtest completes, CSV files are in:
```
~/Library/Application Support/MetaQuotes/Terminal/<TERMINAL_ID>/MQL5/Files/
```

Files generated:
- `TP_Crypto_Signals_v2.0.csv` - All signals (BUY/SELL/SKIP)
- `TP_Crypto_Trades_v2.0.csv` - Executed trades with P&L

#### Step 4: Copy Files for Baseline Analysis
```bash
mkdir -p backtest_results/baseline
cp ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Crypto_Signals_v2.0.csv \
   backtest_results/baseline/signals_baseline.csv
cp ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Crypto_Trades_v2.0.csv \
   backtest_results/baseline/trades_baseline.csv
```

#### Step 5: Analyze Baseline
```bash
python3 analyze_backtest.py analyze \
    backtest_results/baseline/signals_baseline.csv \
    backtest_results/baseline/trades_baseline.csv \
    --export backtest_results/baseline/analysis.json
```

**Expected Output:**
- Total trades, win rate, profit factor
- Signal-to-trade ratio (should be high - most signals executed)
- Loss pattern identification
- Optimization suggestions

---

### **Phase 2: Optimized Run (With Self-Healing)**

#### Step 1: Apply Optimization Suggestions
Based on Phase 1 analysis, update EA parameters:
- Increase `MinQuality` (e.g., 50-70)
- Increase `MinConfluence` (e.g., 3.0-4.0)
- Adjust `EntropyThreshold` if needed
- Enable JSON learning file (should be enabled by default)

#### Step 2: Run Optimized Backtest
Repeat the backtest with the same date range and symbol.

#### Step 3: Copy Optimized Results
```bash
mkdir -p backtest_results/optimized
cp ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Crypto_Signals_v2.0.csv \
   backtest_results/optimized/signals_optimized.csv
cp ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Crypto_Trades_v2.0.csv \
   backtest_results/optimized/trades_optimized.csv
```

#### Step 4: Compare Baseline vs Optimized
```bash
python3 analyze_backtest.py compare \
    backtest_results/optimized/signals_optimized.csv \
    backtest_results/optimized/trades_optimized.csv \
    --baseline-signals backtest_results/baseline/signals_baseline.csv \
    --baseline-trades backtest_results/baseline/trades_baseline.csv
```

**Expected Improvements:**
- ✅ Higher win rate
- ✅ Higher profit factor
- ✅ Reduced max drawdown
- ✅ Increased skip rate (showing self-healing filter is working)
- ✅ Fewer consecutive losses

---

### **Phase 3: JSON Learning State Validation**

#### Verify JSON File Creation
The EA should create a JSON learning file during backtests:
```bash
# Look for the learning state file
ls -la ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/ | grep -i learn
```

Expected file: `TP_Learning_State_v2.0.json`

#### Inspect Learning State
```bash
cat ~/Library/Application\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Learning_State_v2.0.json
```

**What to look for:**
- Trade history with outcomes
- Learned patterns (loss zones, confluence thresholds)
- Adaptation counters

#### Validate State is Being Used
Add logging to your EA (if not already present) to print:
- "Reading learning state from JSON..."
- "Applying learned restriction: [details]"
- "Trade blocked by self-healing: [reason]"

Re-run backtest and check MT5 logs for these messages.

---

## 📈 Professional Dashboard

### Launch Interactive Dashboard
```bash
python3 dashboard.py \
    backtest_results/optimized/signals_optimized.csv \
    backtest_results/optimized/trades_optimized.csv \
    --port 8050 \
    --title "TickPhysics Q4 2025 Performance"
```

Open browser to: **http://localhost:8050**

### Dashboard Features
1. **Performance Metrics Cards**
   - Total Trades, Win Rate, Profit Factor
   - Total Profit, Max Drawdown

2. **Equity Curve**
   - Visual balance progression
   - Winning/losing trade markers

3. **Signal Analysis**
   - Distribution of BUY/SELL/SKIP signals
   - Shows self-healing filter effectiveness

4. **Profit Distribution**
   - Histogram of wins vs losses
   - Risk/reward visualization

5. **Learning Evolution Timeline**
   - Skip rate over time (shows adaptive behavior)
   - Demonstrates self-learning progression

### Sharing with Business Partner
```bash
# Generate static HTML report
python3 -c "
from dashboard import TickPhysicsDashboard
import plotly.io as pio

dashboard = TickPhysicsDashboard(
    'backtest_results/optimized/signals_optimized.csv',
    'backtest_results/optimized/trades_optimized.csv',
    'TickPhysics Q4 2025 Performance'
)

# Export individual charts as HTML
dashboard.create_equity_curve().write_html('equity_curve.html')
print('✅ Exported equity_curve.html')
"
```

Or simply share the dashboard URL when running locally, or deploy to a cloud service.

---

## 🔬 Advanced: Controlled MA Crossover Test

To isolate self-healing effects with a simple, repeatable baseline:

### Create Simplified Test EA
Modify a copy of your EA to use a simple MA crossover instead of TickPhysics signals:
```cpp
// In OnTick() - Replace TickPhysics signal detection with:
double ma_fast[], ma_slow[];
CopyBuffer(handleMAFast, 0, 0, 2, ma_fast);
CopyBuffer(handleMASlow, 0, 0, 2, ma_slow);

// Simple crossover logic
bool buy_signal = (ma_fast[0] > ma_slow[0] && ma_fast[1] <= ma_slow[1]);
bool sell_signal = (ma_fast[0] < ma_slow[0] && ma_fast[1] >= ma_slow[1]);
```

**But keep the self-healing/learning logic intact**

Run two versions:
1. **Version A:** MA crossover only (no self-healing)
2. **Version B:** MA crossover + self-healing filtering

Compare results - Version B should show:
- Same number of crossover signals
- But fewer executed trades (due to filtering)
- Better win rate and profit factor

This proves the self-healing logic is working independently of signal generation.

---

## 📝 Best Practices for Business Presentation

### 1. Focus on Key Metrics
Highlight in this order:
- **Win Rate improvement** (e.g., 45% → 58%)
- **Profit Factor improvement** (e.g., 1.2 → 2.1)
- **Max Drawdown reduction** (e.g., 25% → 12%)

### 2. Show Before/After Visuals
Use the comparison charts from the dashboard showing clear improvement.

### 3. Explain Self-Healing Mechanism
- "The system learns from losses and restricts entries at unfavorable conditions"
- "Skip rate increased from 20% to 45%, showing intelligent filtering"
- "Same market data, smarter decision-making"

### 4. Demonstrate Real-Time Adaptation
Show the learning timeline chart - skip rate changes over time prove the system adapts.

### 5. Risk Management Story
- "Fixed SL/TP with physics-based confluence ensures controlled risk"
- "Entropy filter prevents overtrading in choppy conditions"
- "Self-healing progressively improves without manual intervention"

---

## 🐛 Troubleshooting

### CSV Files Not Found
```bash
# Search all possible locations
find ~ -name "TP_Crypto_Signals_v2.0.csv" 2>/dev/null
```

### Dashboard Won't Start
```bash
# Check if port is in use
lsof -i :8050

# Try different port
python3 dashboard.py signals.csv trades.csv --port 8051
```

### Import Errors
```bash
# Reinstall dependencies
pip3 install --upgrade -r requirements.txt
```

### JSON File Not Created
Check EA inputs - ensure learning is enabled:
```cpp
input bool InpEnableLearning = true;  // Should be true
input string InpLearningFile = "TP_Learning_State_v2.0.json";
```

---

## 🎯 Success Criteria Checklist

- [ ] Baseline backtest completed and analyzed
- [ ] Optimized backtest shows measurable improvement
- [ ] JSON learning state file is being created and read
- [ ] Signal skip rate increases with optimization
- [ ] Win rate improves by at least 5-10%
- [ ] Profit factor improves by at least 0.3-0.5
- [ ] Dashboard launches and displays all charts
- [ ] Before/after comparison clearly demonstrates self-learning
- [ ] Ready to present to business partner

---

## 📞 Next Steps

After validating the system:

1. **Forward Testing**
   - Run EA on demo account for 1-2 weeks
   - Monitor real-time performance vs backtest
   - Validate JSON learning persists across sessions

2. **Multi-Symbol Testing**
   - Test on BTCUSD, ETHUSD, other crypto pairs
   - Verify self-learning works across different assets

3. **Parameter Optimization**
   - Use MT5 Strategy Tester optimization feature
   - Find optimal MinQuality/MinConfluence ranges
   - Document optimal parameters per symbol

4. **Production Deployment**
   - Move to live account with small capital
   - Implement monitoring and alerting
   - Schedule regular performance reviews

---

**Good luck with your QA process! 🚀**
