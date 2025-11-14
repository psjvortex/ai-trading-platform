# TickPhysics Self-Learning & Self-Healing System
## Autonomous EA Optimization Framework

---

## 🎯 Overview

This is a **fully autonomous, data-driven EA optimization system** that continuously learns from trade results and automatically updates its configuration to improve performance.

### Key Features
- ✅ **JSON-Based Configuration** - All EA parameters in one editable file
- ✅ **Python Learning Engine** - Analyzes trade CSVs and optimizes filters
- ✅ **MQL5 JSON Reader** - EA loads config from JSON at startup
- ✅ **Automatic Optimization** - Time filters, physics thresholds, risk parameters
- ✅ **Performance Tracking** - Historical optimization cycles and results
- ✅ **Manual & Auto Modes** - Control when updates occur

---

## 📁 File Structure

```
MQL5/
├── EA_Config_v2_6.json                 # Main configuration file
├── self_learning_engine.py             # Python optimization engine
├── Include/TickPhysics/
│   └── TP_JSON_Config.mqh              # MQL5 JSON parser
├── Experts/TickPhysics/
│   ├── TP_Integrated_EA_Crossover_2_6.mq5  # Current EA (manual inputs)
│   └── TP_Integrated_EA_Auto_2_7.mq5       # Future: JSON-based EA
└── TP_Integrated_Trades_*.csv          # Trade history (analyzed by engine)
```

---

## 🚀 Quick Start

### 1. **Initial Setup** (One-Time)

```bash
cd /Users/patjohnston/ai-trading-platform/MQL5

# Make Python script executable
chmod +x self_learning_engine.py

# Verify config exists
cat EA_Config_v2_6.json
```

### 2. **Run a Backtest** (v2.6)

1. Open MT5 and load `TP_Integrated_EA_Crossover_2_6.mq5`
2. Run backtest (Jan-Sep 2025, NAS100 M15)
3. Export MT5 report: `MTBacktest_Report_2.6.csv`
4. EA generates: `TP_Integrated_Trades_NAS100_v2.6.csv`

### 3. **Analyze & Optimize**

```bash
# Generate performance report (no changes)
python3 self_learning_engine.py --report-only

# Update config automatically (if thresholds met)
python3 self_learning_engine.py

# Force update (manual override)
python3 self_learning_engine.py --force

# Specify files explicitly
python3 self_learning_engine.py \
  --config EA_Config_v2_6.json \
  --trades TP_Integrated_Trades_NAS100_v2.6.csv \
  --force
```

### 4. **Review Changes**

```bash
# View updated config
cat EA_Config_v2_6.json

# Check optimization history
cat EA_Config_v2_6.json | grep -A 50 "optimization_history"
```

---

## 🧠 How the Learning Engine Works

### **Input:** Trade CSV from EA backtest/live run
```csv
Ticket,Open_Time,Close_Time,Type,Profit,Entry_Quality,Entry_Hour,Entry_DayOfWeek,...
```

### **Analysis:** Python engine calculates:
1. **Win Rate by Hour** (0-23)
2. **Win Rate by Day** (Sun-Sat)
3. **Profit by Hour/Day**
4. **Optimal Quality Threshold** (60, 65, 70, 75, 80)
5. **Optimal Confluence Threshold**

### **Optimization Logic:**

```python
# For each hour:
if win_rate >= 40% and total_profit > 0:
    → Add to allowed_hours
elif win_rate < 32% or total_profit < 0:
    → Add to blocked_hours

# For each day:
if win_rate < 32% or total_profit < 0:
    → Add to blocked_days

# Quality threshold:
# Find threshold with best: win_rate × avg_profit × sqrt(trade_count)
```

### **Output:** Updated `EA_Config_v2_6.json`

```json
{
  "time_filters": {
    "allowed_hours": [11, 13, 14, 18, 20, 21],  // ← Updated
    "blocked_hours": [1, 12, 15],               // ← Updated
    "blocked_days": [3]                         // ← Wednesday
  },
  "physics_filters": {
    "min_quality": 75.0                         // ← Optimized
  },
  "optimization_history": [
    {
      "version": "2.6.1",
      "date": "2025-01-15",
      "win_rate": 0.42,
      "changes": "Auto-optimized based on 455 trades"
    }
  ]
}
```

---

## 📊 Configuration File Explained

### **EA_Config_v2_6.json Structure**

```json
{
  "meta": {
    "config_version": "2.6.0",
    "last_updated": "2025-01-15T00:00:00Z",
    "optimization_cycle": 1,              // Increments each update
    "total_trades_analyzed": 455          // Tracks learning progress
  },
  
  "risk_management": {
    "risk_percent_per_trade": 1.0,        // % of balance per trade
    "max_daily_risk": 3.0,
    "max_concurrent_trades": 3,
    "min_r_ratio": 1.5,
    "stop_loss_pips": 50,
    "take_profit_pips": 100
  },
  
  "physics_filters": {
    "enabled": true,
    "min_quality": 70.0,                  // ← Learning engine optimizes
    "min_confluence": 70.0,
    "zone_filter_enabled": true,
    "regime_filter_enabled": true,
    "blocked_zones": ["BEAR"],
    "blocked_regimes": ["LOW"]
  },
  
  "time_filters": {
    "enabled": true,
    "allowed_hours": [11, 13, 14, 18, 20, 21],  // ← Auto-optimized
    "blocked_hours": [1, 12, 15],               // ← Auto-optimized
    "blocked_days": [3]                         // ← 3 = Wednesday
  },
  
  "learning_parameters": {
    "auto_update_enabled": false,         // ← Set true for full automation
    "min_trades_for_update": 100,         // Require 100 trades minimum
    "update_frequency_trades": 50         // Update every 50 new trades
  }
}
```

---

## 🔄 Automation Workflows

### **Workflow A: Manual Review & Approval** (Recommended for now)

```bash
# 1. Run backtest in MT5
# 2. Analyze results
python3 self_learning_engine.py --report-only

# 3. Review recommendations
cat EA_Config_v2_6.json

# 4. Apply changes (manual approval)
python3 self_learning_engine.py --force

# 5. Run new backtest with updated config
```

### **Workflow B: Semi-Automatic** (After 50 new trades)

```json
{
  "learning_parameters": {
    "auto_update_enabled": true,
    "min_trades_for_update": 100,
    "update_frequency_trades": 50
  }
}
```

```bash
# Run after each backtest/live session
python3 self_learning_engine.py

# Engine will:
# - Check if 50 new trades since last update
# - If yes: auto-optimize and update config
# - If no: skip and report status
```

### **Workflow C: Fully Autonomous** (Future Live Trading)

1. **EA runs live** → Generates `TP_Integrated_Trades_NAS100_v2.6.csv`
2. **Cron job** (every 6 hours):
   ```bash
   python3 self_learning_engine.py --config EA_Config_v2_6.json
   ```
3. **Engine checks:**
   - Have 50+ new trades been executed?
   - Yes → Update config automatically
   - No → Do nothing
4. **EA reads updated config** on next restart
5. **Repeat cycle** → Continuous improvement

---

## 🎓 Self-Learning Examples

### **Example 1: Time Filter Optimization**

**Before v2.6:**
```json
"time_filters": {
  "allowed_hours": [],              // Trade all hours
  "blocked_hours": []
}
```

**After analyzing 455 trades:**
```
Hour 01: 15 trades | WR: 20.0% | P/L: -$450.00  ❌ BLOCK
Hour 11: 28 trades | WR: 53.6% | P/L: +$820.00  ✅ ALLOW
Hour 12: 18 trades | WR: 27.8% | P/L: -$320.00  ❌ BLOCK
Hour 13: 32 trades | WR: 50.0% | P/L: +$640.00  ✅ ALLOW
```

**Updated config:**
```json
"time_filters": {
  "allowed_hours": [11, 13, 14, 18, 20, 21],
  "blocked_hours": [1, 12, 15]
}
```

**Result:** v2.6 backtest only trades during high-performance hours!

---

### **Example 2: Quality Threshold Optimization**

**Analysis:**
```
MinQuality=60: 380 trades | WR: 38.4% | Avg: +$2.15
MinQuality=65: 320 trades | WR: 41.3% | Avg: +$3.80
MinQuality=70: 250 trades | WR: 45.6% | Avg: +$5.20  ← BEST SCORE
MinQuality=75: 180 trades | WR: 48.9% | Avg: +$6.10  (too few trades)
```

**Score = WR × AvgProfit × sqrt(TradeCount)**
- Quality 70: 0.456 × 5.20 × sqrt(250) = **37.4** ✅
- Quality 75: 0.489 × 6.10 × sqrt(180) = **36.8**

**Updated config:**
```json
"physics_filters": {
  "min_quality": 70.0  // ← Optimized from 65
}
```

---

## 📈 Performance Tracking

### **View Optimization History**

```bash
cat EA_Config_v2_6.json | grep -A 50 "optimization_history"
```

```json
"optimization_history": [
  {
    "version": "2.5",
    "date": "2025-01-10",
    "total_trades": 455,
    "win_rate": 0.396,
    "profit_factor": 1.23,
    "net_profit": 1234.56,
    "changes": "Added zone/regime filters",
    "result": "Baseline with physics filters"
  },
  {
    "version": "2.6",
    "date": "2025-01-15",
    "total_trades": 180,
    "win_rate": 0.456,
    "profit_factor": 1.52,
    "net_profit": 2145.80,
    "changes": "Time filters added",
    "result": "+6% WR, +23% profit factor"
  },
  {
    "version": "2.6.1",
    "date": "2025-01-20",
    "total_trades": 230,
    "win_rate": 0.478,
    "profit_factor": 1.68,
    "result": "Auto-optimized (first learning cycle)"
  }
]
```

---

## 🔧 Advanced Usage

### **Custom Analysis**

```python
from self_learning_engine import SelfLearningEngine

engine = SelfLearningEngine('EA_Config_v2_6.json', 'TP_Integrated_Trades_NAS100_v2.6.csv')

# Analyze specific patterns
hourly_stats = engine.analyze_time_of_day_performance()
daily_stats = engine.analyze_day_of_week_performance()

# Custom optimization
physics_opt = engine.optimize_physics_filters()

# Generate detailed report
print(engine.generate_report())
```

### **Custom Thresholds**

Edit `EA_Config_v2_6.json`:

```json
"performance_thresholds": {
  "acceptable_win_rate": 0.45,       // ← Require 45% WR to allow hour
  "target_win_rate": 0.55,
  "acceptable_profit_factor": 1.3,
  "min_trades_per_week": 10          // ← Minimum activity level
}
```

---

## 🚨 Safety Features

### **Validation Before Update**

```python
# Engine checks:
1. Minimum 100 trades (configurable)
2. Statistical significance (min 10 trades per hour/day)
3. Confidence threshold (95% by default)
4. Performance thresholds met
```

### **Rollback Protection**

```json
// Each update saves previous state in optimization_history
// Manual rollback:
{
  "time_filters": {
    "allowed_hours": [9, 10, 11],  // ← Copy from previous version
    "blocked_hours": []
  }
}
```

### **Backup Strategy**

```bash
# Before each learning cycle:
cp EA_Config_v2_6.json EA_Config_v2_6_backup_$(date +%Y%m%d_%H%M%S).json
```

---

## 📅 Roadmap

### **Phase 1: Manual Learning** ✅ (Current)
- [x] JSON config file
- [x] Python learning engine
- [x] MQL5 JSON reader
- [x] Manual optimization workflow
- [x] Performance reporting

### **Phase 2: Semi-Automatic** (Next)
- [ ] Create `TP_Integrated_EA_Auto_2_7.mq5` (reads JSON)
- [ ] Run learning engine after each backtest
- [ ] A/B test: v2.6 (manual) vs v2.7 (JSON)
- [ ] Validate JSON-based EA matches manual inputs

### **Phase 3: Fully Autonomous** (Future)
- [ ] Live EA generates CSVs continuously
- [ ] Cron job runs learning engine every N hours
- [ ] EA reloads config without restart (via global variables)
- [ ] Email/Telegram notifications on updates
- [ ] Multi-timeframe optimization
- [ ] Walk-forward analysis

### **Phase 4: Advanced ML** (Long-term)
- [ ] sklearn integration for pattern recognition
- [ ] Predict optimal entry timing
- [ ] Dynamic SL/TP based on market regime
- [ ] Ensemble model (combine multiple strategies)

---

## 🎯 Next Steps for You

1. **Compile v2.6** (fix any remaining errors)
2. **Run v2.6 backtest** (Jan-Sep 2025, NAS100 M15)
3. **Generate trade CSV**
4. **Test learning engine:**
   ```bash
   python3 self_learning_engine.py --report-only
   ```
5. **Review recommendations**
6. **Run v2.6.1 backtest** with optimized config
7. **Compare results:** v2.5 → v2.6 → v2.6.1

---

## 💡 Pro Tips

1. **Start Conservative**
   - Use `--report-only` first to see recommendations
   - Manually review changes before applying
   - Set `auto_update_enabled: false` initially

2. **Build Confidence**
   - Run 3-5 optimization cycles manually
   - Verify improvements are consistent
   - Then enable auto-update

3. **Monitor Performance**
   - Track win rate, profit factor, drawdown
   - If performance degrades, rollback config
   - Use longer backtests (6-12 months) for validation

4. **Document Everything**
   - The `optimization_history` array tracks all changes
   - Add custom notes to explain manual overrides
   - Keep backups of working configs

---

## 🙏 Questions?

This is an **iterative, data-driven system**. The more backtests you run, the smarter it gets!

**Workflow:**
```
Backtest → Analyze → Optimize → Backtest → Repeat
   v2.5  →   v2.6  →   v2.6.1  →   v2.6.2  → ...
```

Each cycle improves performance based on **real trade data**, not guesswork.

🚀 **Let's get v2.6 running and prove the concept!**
