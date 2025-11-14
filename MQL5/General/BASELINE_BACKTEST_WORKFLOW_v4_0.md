# Baseline Backtest Workflow - v4.0

**Date**: 2025-11-02  
**Version**: v4.0  
**Mode**: Pure MA Crossover Baseline (Physics OFF)  
**Goal**: Establish baseline performance for optimization  

---

## ✅ PRE-BACKTEST CHECKLIST

### EA Configuration (v4.0)
- [x] **Physics**: OFF (`InpUsePhysics = false`)
- [x] **TickPhysics Indicator**: OFF (`InpUseTickPhysicsIndicator = false`)
- [x] **MA Entry**: 10/300 LWMA on Close
- [x] **MA Exit**: 10/250 LWMA on Close
- [x] **CSV Logging**: ENABLED
  - Signals: `TP_Crypto_Signals_Cross_v4_0.csv`
  - Trades: `TP_Crypto_Trades_Cross_v4_0.csv`
- [x] **Chart Display**: ON (Blue/Yellow/White MAs)

### Risk Management Settings
- Risk per trade: 10% of equity
- Stop Loss: 3% of entry price
- Take Profit: 2% of entry price
- Max positions: 1
- No daily limits (for full backtest)

---

## 📋 BACKTEST STEPS

### 1. Run Backtest in MT5
```
1. Open MetaTrader 5
2. Open Strategy Tester (Ctrl+R)
3. Select: TickPhysics_Crypto_SelfHealing_Crossover_EA_v4_0
4. Symbol: ETHUSD (or your crypto pair)
5. Timeframe: M5 (5-minute)
6. Period: 1-3 months (for statistically significant data)
7. Mode: "Every tick" or "1 minute OHLC"
8. Initial Deposit: $10,000 (or your starting balance)
9. Click "Start"
10. Wait for completion
```

### 2. Verify CSV Files Generated
After backtest completes, check:
```
C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[ID]\MQL5\Files\
```

Should contain:
- ✅ `TP_Crypto_Trades_Cross_v4_0.csv`
- ✅ `TP_Crypto_Signals_Cross_v4_0.csv`

### 3. Copy CSV Files to Project
```bash
# Copy to your project folder
cp ~/AppData/.../MQL5/Files/TP_Crypto_Trades_Cross_v4_0.csv \
   /Users/patjohnston/ai-trading-platform/MQL5/

cp ~/AppData/.../MQL5/Files/TP_Crypto_Signals_Cross_v4_0.csv \
   /Users/patjohnston/ai-trading-platform/MQL5/
```

---

## 🐍 PYTHON ANALYSIS

### 1. Run Analysis Script
```bash
cd /Users/patjohnston/ai-trading-platform/MQL5

python analyze_baseline_backtest.py
```

### 2. What You'll Get

#### Console Output:
```
📊 Loading data from TP_Crypto_Trades_Cross_v4_0.csv
✅ Loaded X trade records

📈 TRADE ANALYSIS
Total OPEN trades: X
Total CLOSE trades: Y

🎯 PERFORMANCE METRICS
Total Closed Trades: Z
Wins: XX (XX%)
Losses: YY (YY%)
Win Rate: XX.XX%

Average Win: X.XX%
Largest Win: X.XX%
Average Loss: -X.XX%
Largest Loss: -X.XX%

Profit Factor: X.XX
Average Trade Duration: XX.X hours

🔧 OPTIMIZATION RECOMMENDATIONS
1. EXIT MA OPTIMIZATION
2. RISK/REWARD ANALYSIS
3. WIN RATE ANALYSIS
4. NEXT STEPS
```

#### Files Generated:
1. **`baseline_analysis_v4_0.png`** - Performance charts:
   - P/L distribution histogram
   - Cumulative P/L curve
   - Win/Loss by trade type
   - Duration vs Profitability scatter

2. **`baseline_report_v4_0.json`** - Detailed metrics:
   ```json
   {
     "timestamp": "2025-11-02T...",
     "version": "v4.0",
     "strategy": "Pure MA Crossover Baseline",
     "performance": {
       "total_trades": 50,
       "win_rate": 52.0,
       "wins": 26,
       "losses": 24,
       "avg_win_percent": 1.85,
       "avg_loss_percent": -1.23,
       "profit_factor": 1.45,
       "total_pnl_percent": 15.2
     }
   }
   ```

---

## 📊 OPTIMIZATION WORKFLOW

After baseline analysis, you'll have data to:

### Phase 1: MA Parameter Optimization
Test different MA combinations:
```
Entry MA:  10/200, 10/300, 10/400
Exit MA:   10/150, 10/200, 10/250
```

### Phase 2: Physics Filters (One at a Time)
Enable each filter individually to measure impact:
1. Entropy filter only
2. Confluence filter only
3. Trading zone filter only
4. Volume regime filter only

### Phase 3: Combined Physics
Best-performing filters combined

### Phase 4: Self-Healing
Enable adaptive optimization with physics

---

## 📈 EXPECTED BASELINE RESULTS

### Good Baseline Indicators:
- ✅ Win rate: 45-55%
- ✅ Profit factor: > 1.2
- ✅ Average R:R: > 1.0
- ✅ Consistent performance across market conditions

### Red Flags:
- ❌ Win rate < 35% (MA combo not suitable)
- ❌ Profit factor < 1.0 (losing strategy)
- ❌ Large drawdowns (need tighter risk management)
- ❌ Most trades hitting SL (MA periods too tight)

---

## 🔬 PHYSICS ENHANCEMENT TARGETS

After establishing baseline, physics filters should:
- **Increase win rate** by 5-15%
- **Improve profit factor** by 0.2-0.5
- **Reduce max drawdown** by 20-40%
- **Filter out choppy markets** (reduce losing trades)

---

## 📝 BACKTEST DOCUMENTATION

Create a record for each backtest:

```markdown
### Backtest #1 - Pure Baseline
- Date: 2025-11-02
- Version: v4.0
- Symbol: ETHUSD
- Timeframe: M5
- Period: 2024-10-01 to 2024-12-31
- MA Entry: 10/300
- MA Exit: 10/250
- Physics: OFF

Results:
- Total Trades: XX
- Win Rate: XX%
- Profit Factor: X.XX
- Net P/L: +XX%

Notes:
- Baseline established
- Good performance in trending markets
- Suffered in consolidation periods
```

---

## 🚀 NEXT STEPS AFTER BASELINE

1. ✅ **Document baseline performance**
2. 📊 **Compare multiple timeframes** (M5, M15, M30)
3. 🔧 **Test MA variations** (10/200, 10/400, etc.)
4. 🔬 **Enable physics filters one by one**
5. 📈 **Build comparison dashboard** (baseline vs physics)
6. 🤖 **Implement self-healing optimization**
7. 💰 **Paper trade best configuration**
8. 🎯 **Live trade with proven settings**

---

## 📚 FILES REFERENCE

### EA Files:
- `/Users/patjohnston/ai-trading-platform/MQL5/TickPhysics_Crypto_SelfHealing_Crossover_EA_v4_0`

### Analysis Scripts:
- `/Users/patjohnston/ai-trading-platform/MQL5/analyze_baseline_backtest.py`

### Documentation:
- This file: `BASELINE_BACKTEST_WORKFLOW_v4_0.md`
- Optimization summary: `OPTIMIZATION_v2_9_GLOBAL_BUFFERS.md`

### Data Files (Generated):
- `TP_Crypto_Trades_Cross_v4_0.csv`
- `TP_Crypto_Signals_Cross_v4_0.csv`
- `baseline_analysis_v4_0.png`
- `baseline_report_v4_0.json`

---

**Status**: ✅ **READY FOR BASELINE BACKTEST**

Run your first backtest and let the data guide optimization! 🚀
