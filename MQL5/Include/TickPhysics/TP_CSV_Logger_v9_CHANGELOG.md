# TP_CSV_Logger v9.0 - CHANGELOG

## 🎯 Major Update: Entry_*/Exit_* Explicit Naming Convention

**Date:** November 17, 2025
**Version:** 8.0 → 9.0

---

## 📊 Summary of Changes

### Column Count
- **Before:** 108 columns
- **After:** 110 columns (+2)

### Naming Convention Upgrade
All physics metrics now have explicit `Entry_*` and `Exit_*` prefixes for maximum clarity in ML models.

---

## 🔄 Field Changes

### ❌ REMOVED (Ambiguous Names):
- `Quality`, `Confluence`, `Momentum`, `Speed`, `Acceleration`, `Entropy`, `Jerk`, `PhysicsScore`
- `SpeedSlope`, `AccelerationSlope`, `MomentumSlope`, `ConfluenceSlope`, `JerkSlope`
- `Zone`, `Regime`, `Spread`

### ✅ ADDED (Explicit Entry Physics - 19 fields):
1. `Entry_Quality`
2. `Entry_Confluence`
3. `Entry_Momentum`
4. `Entry_Speed`
5. `Entry_Acceleration`
6. `Entry_Entropy`
7. `Entry_Jerk`
8. `Entry_PhysicsScore`
9. `Entry_SpeedSlope`
10. `Entry_AccelerationSlope`
11. `Entry_MomentumSlope`
12. `Entry_ConfluenceSlope`
13. `Entry_JerkSlope`
14. `Entry_Zone`
15. `Entry_Regime`
16. `Entry_Spread`

### ✅ ADDED (Explicit Exit Physics - 20 fields):
1. `ExitReason` (kept)
2. `Exit_Quality`
3. `Exit_Confluence`
4. `Exit_Momentum`
5. `Exit_Speed`
6. `Exit_Acceleration`
7. `Exit_Entropy`
8. `Exit_Jerk`
9. `Exit_PhysicsScore`
10. `Exit_SpeedSlope`
11. `Exit_AccelerationSlope`
12. `Exit_MomentumSlope`
13. `Exit_ConfluenceSlope`
14. `Exit_JerkSlope`
15. `Exit_Zone`
16. `Exit_Regime`
17. `Exit_Spread`

---

## 🏗️ Code Changes

### 1. **Struct Fields Updated** (`TradeLogEntry`)
```cpp
// OLD (ambiguous):
double quality;
double confluence;
string zone;

// NEW (explicit):
double entryQuality;
double entryConfluence;
string entryZone;

double exitQuality;
double exitConfluence;
string exitZone;
```

### 2. **Constructor Updated**
All new fields initialized to 0 or default values to prevent garbage data.

### 3. **CSV Header Writer Updated**
```cpp
// NEW header structure (110 columns):
FileWriteString(handle, "Entry_Quality,Entry_Confluence,...Entry_Spread,");
FileWriteString(handle, "ExitReason,Exit_Quality,Exit_Confluence,...Exit_Spread,");
```

### 4. **LogTrade Function Updated**
Data writing now uses `entry.entryQuality`, `entry.exitQuality`, etc.

---

## 📈 Benefits

### For Machine Learning:
✅ **Crystal clear feature names** - no ambiguity about which row contains which data
✅ **Easy feature engineering** - can easily calculate decay: `Entry_Speed - Exit_Speed`
✅ **Better model interpretability** - feature importance clearly tied to entry or exit

### For Analysis:
✅ **Explicit data structure** - immediately understand what each column represents
✅ **Prevents confusion** - no more "is this entry or exit physics?"
✅ **Professional naming** - follows industry best practices

### For Backtesting:
✅ **Complete entry snapshot** - all Entry_* fields captured at trade open
✅ **Complete exit snapshot** - all Exit_* fields captured at trade close
✅ **Full physics decay analysis** - compare entry vs exit conditions

---

## ⚠️ Breaking Changes

### Impact:
- **Existing CSVs**: Old v8.0 CSVs won't match new column names
- **Analytics scripts**: Python scripts need column name updates
- **EA code**: Any direct field access needs updating

### Migration:
1. Recompile EA with new logger
2. Run new backtest to generate v9.0 CSV
3. Update Python scripts to use new column names:
   ```python
   # OLD
   df['Quality']
   
   # NEW
   df['Entry_Quality']  # for ENTRY rows
   df['Exit_Quality']   # for EXIT rows
   ```

---

## 🚀 Next Steps

1. **Compile EA** - Recompile `TP_Integrated_EA_Crossover_4_1_8_9`
2. **Run backtest** - Generate new v9.0 CSV with proper naming
3. **Validate** - Check that Entry_* and Exit_* fields populate correctly
4. **Update analytics** - Modify Python scripts for new names

---

## 📝 Version History

- **v9.0** (Nov 17, 2025) - Entry_*/Exit_* explicit naming
- **v8.0** (Nov 4, 2025) - Dual-row model with 108 columns
- **v7.0** - Added physics decay analysis
- **v6.0** - Added RunUp/RunDown post-trade metrics

