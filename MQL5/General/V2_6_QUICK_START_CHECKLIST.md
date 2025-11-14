# v2.6 EA - Quick Start Checklist ✅

## Pre-Compilation (5 minutes)

- [ ] **Verify EA file exists**
  ```bash
  ls -lh "/Users/patjohnston/ai-trading-platform/MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_2_6.mq5"
  ```

- [ ] **Copy EA to MT5 (if needed)**
  ```bash
  cp "/Users/patjohnston/ai-trading-platform/MQL5/Experts/TickPhysics/TP_Integrated_EA_Crossover_2_6.mq5" \
     "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/TickPhysics/"
  ```

- [ ] **Review compilation guide**
  - Open: `/Users/patjohnston/ai-trading-platform/MQL5/V2_6_COMPILATION_AND_VALIDATION_GUIDE.md`

---

## MT5 Compilation (2 minutes)

- [ ] **Open MetaEditor** (F4 in MT5)
- [ ] **Navigate to EA**: Experts → TickPhysics → TP_Integrated_EA_Crossover_2_6.mq5
- [ ] **Compile** (F7)
- [ ] **Verify**: `0 error(s), 0 warning(s)` ✅
- [ ] **Check .ex5 created** in same directory

---

## Backtest Setup (5 minutes)

- [ ] **Open Strategy Tester** (Ctrl+R)

### Basic Settings
- [ ] Expert: `TP_Integrated_EA_Crossover_2_6.mq5`
- [ ] Symbol: `NAS100` (or US100)
- [ ] Period: `M15`
- [ ] Date: `2025.01.01 - 2025.09.30`
- [ ] Deposit: `$10,000`
- [ ] Leverage: `1:100`
- [ ] Model: `Every tick`
- [ ] Visualization: `ON` (to see MA lines)

### EA Parameters (Critical!)

**Entry Logic**
- [ ] Use Physics Entry: `FALSE` ❌
- [ ] Use MA Entry: `TRUE` ✅
- [ ] MA Fast: `10`
- [ ] MA Slow: `50`

**Physics Filters (v2.5 proven)**
- [ ] Use Physics Filters: `TRUE` ✅
- [ ] Min Quality: `70.0` ⬆️ (increased from 65)
- [ ] Min Confluence: `70.0`
- [ ] Use Zone Filter: `TRUE` ✅
- [ ] Use Regime Filter: `TRUE` ✅

**Time Filters (v2.6 NEW)**
- [ ] Use Time Filter: `TRUE` ✅
- [ ] Allowed Hours: `11,13,14,18,20,21`
- [ ] Blocked Hours: `1,12,15`
- [ ] Use Day Filter: `TRUE` ✅
- [ ] Avoid Wednesday: `TRUE` ✅

**Other**
- [ ] Debug mode: `TRUE`
- [ ] Real-time logging: `TRUE`
- [ ] Magic number: `777888`

---

## Run Backtest (10-15 minutes)

- [ ] **Start backtest** (click Start button)
- [ ] **Monitor progress** (check Journal for initialization messages)
- [ ] **Wait for completion**
- [ ] **Check for errors** in Experts and Journal tabs

---

## Export Results (3 minutes)

- [ ] **Check CSV files created**
  ```bash
  ls -lh "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3001/MQL5/Files/"TP_*v2.6*
  ```

- [ ] **Copy CSVs to working directory**
  ```bash
  cp "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3001/MQL5/Files/TP_Integrated_"*"_v2.6.csv" \
     /Users/patjohnston/ai-trading-platform/MQL5/
  ```

- [ ] **Export MT5 Report**
  - Right-click backtest result
  - Report → Save as Detailed Report
  - Save as: `MTBacktest_Report_2.6.csv`
  - Move to: `/Users/patjohnston/Desktop/MT5 Backtest CSV's/`

---

## Validation (5 minutes)

- [ ] **Quick validation check**
  ```bash
  cd /Users/patjohnston/ai-trading-platform/MQL5
  python3 quick_validate.py
  ```
  - Should show v2.6 CSVs
  - Trade count should match MT5 report (±2 acceptable)

- [ ] **Compare v2.5 vs v2.6**
  ```bash
  python3 compare_v25_v26.py
  ```
  - Generates: `V2_5_vs_V2_6_COMPARISON.md`
  - Check for improvement in profit and win rate

---

## Success Criteria ✅

### Performance (v2.6 should beat v2.5)
- [ ] Higher Win Rate (>50%)
- [ ] Better Profit Factor (>1.3)
- [ ] Positive Total Profit (>$1,000)
- [ ] Fewer total trades (more selective filtering)

### Data Integrity
- [ ] CSV trade count matches MT5 report (±2)
- [ ] All trades have complete physics metrics
- [ ] All trades have hour/day stamps
- [ ] Signal rejections logged

### Expected Outcomes
- [ ] ~30-50 trades (heavily filtered)
- [ ] ~50-60% win rate (up from v2.5)
- [ ] PF 1.3-1.8 (better risk/reward)
- [ ] Profit $1,000-$3,000 (net improvement)

---

## File Organization (2 minutes)

- [ ] **Create results folder**
  ```bash
  mkdir -p /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/
  ```

- [ ] **Move all v2.6 files**
  ```bash
  mv TP_Integrated_*v2.6.csv /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/
  mv /Users/patjohnston/Desktop/MT5\ Backtest\ CSV\'s/MTBacktest_Report_2.6.csv \
     /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/
  mv V2_5_vs_V2_6_COMPARISON.md /Users/patjohnston/ai-trading-platform/MQL5/Results/v2.6/
  ```

---

## Troubleshooting

### ❌ Compilation Errors
- Check all `.mqh` libraries are in `Include/TickPhysics/`
- Verify no syntax errors (shouldn't be any in v2.6)
- Try compiling libraries first

### ❌ No CSVs Created
- Check EA initialization in Journal tab
- Verify "Enable real-time logging" is TRUE
- Check file permissions on MQL5/Files directory

### ❌ Trade Count Mismatch
- Small discrepancies (1-3 trades) are acceptable
- Check for unclosed trades at backtest end
- Verify magic number is correct (777888)

### ❌ v2.6 Doesn't Outperform v2.5
- Review time filter settings (may be too restrictive)
- Check that physics filters are enabled
- Verify Wednesday blocking is active
- Consider adjusting MinQuality threshold

---

## Next Steps (After Successful v2.6 Validation)

### Phase 1: JSON Configuration
- [ ] Design JSON config schema
- [ ] Implement JSON reader in EA
- [ ] Test dynamic parameter loading

### Phase 2: Automated Learning
- [ ] Create Python service for trade analysis
- [ ] Generate updated JSON configs automatically
- [ ] Implement EA config refresh mechanism

### Phase 3: Full Autonomy
- [ ] Complete learning loop (trade → analyze → update → repeat)
- [ ] Add convergence detection
- [ ] Document improvement metrics

### Phase 4: Partner Presentation
- [ ] Create executive summary (v2.4 → v2.5 → v2.6 progression)
- [ ] Demonstrate self-learning capability
- [ ] Show roadmap to full automation

---

## Time Estimates

| Task | Time | Status |
|------|------|--------|
| Pre-compilation checks | 5 min | ⬜ |
| MT5 compilation | 2 min | ⬜ |
| Backtest setup | 5 min | ⬜ |
| Run backtest | 10-15 min | ⬜ |
| Export results | 3 min | ⬜ |
| Validation | 5 min | ⬜ |
| File organization | 2 min | ⬜ |
| **TOTAL** | **~35 min** | ⬜ |

---

## Documentation Reference

- **Full Guide**: `V2_6_COMPILATION_AND_VALIDATION_GUIDE.md`
- **Self-Improving README**: `V2_6_SELF_IMPROVING_README.md`
- **v2.5 Analysis**: `V2_5_ANALYSIS_FOR_V2_6.md`
- **v2.5 Summary**: `V2_5_OPTIMIZATION_SUMMARY.md`
- **Comparison Script**: `compare_v25_v26.py`

---

**Last Updated**: 2025-01-XX  
**Version**: 2.6  
**Status**: Ready to compile and test  

🚀 **Let's prove the EA can learn and improve itself!**
