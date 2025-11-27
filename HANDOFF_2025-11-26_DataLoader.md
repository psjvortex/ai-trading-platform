# Handoff Document - November 26, 2025
## Session: DataLoader & Browser CSV Processor Implementation

---

## 🎯 QUICK START FOR NEW SESSION

When starting a new chat on any machine, paste this:

```
Read /HANDOFF_2025-11-26_DataLoader.md and continue from where we left off.
The project is an EA trading performance dashboard built with React/Vite/TypeScript.
```

---

## 📋 WHAT WAS BUILT TODAY

### 1. Browser-Compatible CSV Processor
**File**: `/web/src/lib/csvProcessor.ts` (~900 lines)

- Ported the Node.js CSV processor to run entirely in the browser
- Uses Papa Parse instead of `fs.readFileSync`
- Includes `TimeSegmentCalculator` class for MT5→CST timezone conversion
- `BrowserCSVProcessor` class with `processAll()` method
- Handles: pairing MT5 trades, indexing EA trades, matching signals
- Returns `ProcessingResult` with trades array and statistics

### 2. DataLoader Component
**File**: `/web/src/components/DataLoader.tsx` (~300 lines)

Features:
- **"Load from Default Location"** button (green) - one-click loading from `~/Desktop/MT5_Backtest_Files/`
- Drag-and-drop zones for 3 CSV files (MT5 Report, EA Trades, EA Signals)
- Visual feedback: green checkmark when loaded, file name/size display
- Processing statistics after completion
- Auto-processes and loads dashboard

### 3. Vite API Endpoints
**File**: `/web/vite.config.ts`

Added middleware for filesystem access:
- `GET /api/csv-files` - Lists CSVs in `~/Desktop/MT5_Backtest_Files/`
- `GET /api/csv-content?file=<name>` - Returns CSV file content

### 4. Dashboard Integration
**File**: `/web/src/components/Dashboard.tsx`

Changes:
- Added "Load New Data" button (blue) in header
- Shows DataLoader when no trades loaded or user clicks button
- Improved fetch error handling for missing trades.csv

### 5. Extended Trade Type
**File**: `/web/src/types.ts`

Added 60+ new optional fields:
- Time segments (IN_Segment_15M_OP_01, etc.)
- Signal matching fields (Signal_Entry_Matched, etc.)
- Physics decay metrics
- Made IN_Deal and IN_Trade_ID accept `string | number`

---

## 🔧 HOW IT WORKS

### Workflow A: Auto-load from existing trades.csv
1. Dashboard fetches `/data/trades.csv` from public folder
2. If found → loads dashboard with that data
3. If 404/empty → shows DataLoader UI

### Workflow B: Load from Default Location
1. Click "Load from Default Location" button
2. Reads 3 CSVs from `~/Desktop/MT5_Backtest_Files/`
3. Processes in-browser using same logic as Node.js version
4. Loads dashboard with fresh data

### Workflow C: Drag-and-Drop
1. Drag 3 source CSVs into the DataLoader zones
2. Click "Process & Load Dashboard"
3. Processing happens in-browser

---

## 📁 KEY FILES MODIFIED/CREATED TODAY

```
web/
├── src/
│   ├── lib/
│   │   └── csvProcessor.ts       # NEW - Browser CSV processor
│   ├── components/
│   │   ├── DataLoader.tsx        # NEW - Drag-drop UI
│   │   └── Dashboard.tsx         # MODIFIED - Added DataLoader integration
│   └── types.ts                  # MODIFIED - Extended Trade interface
└── vite.config.ts                # MODIFIED - Added API endpoints
```

---

## 🚀 TO RUN THE PROJECT

```bash
cd /path/to/ai-trading-platform/web
pnpm install
pnpm run dev
```

Then open http://localhost:5173

---

## ⚠️ KNOWN ISSUES / NOTES

1. **iCloud Files**: If files in `~/Desktop/MT5_Backtest_Files/` show as `.icloud`, they need to be downloaded first (click in Finder)

2. **Default Folder Location**: Currently hardcoded to `~/Desktop/MT5_Backtest_Files/` - could be made configurable

3. **File Detection Patterns**:
   - MT5 Report: filename contains `MT5Report` or `Report`
   - EA Trades: filename contains `MASTER_trades` or `_trades` (not signals)
   - EA Signals: filename contains `_signals`

---

## 🎯 SUGGESTED NEXT FEATURES

1. **Comparison Mode** - Load two datasets and compare metrics side-by-side
2. **Filter Presets** - Save/load optimization filter configurations
3. **Monte Carlo Simulation** - Randomize trade order to see profit distribution
4. **Rolling Performance Windows** - 30-day rolling metrics to detect regime changes
5. **Trade Table** - Sortable/searchable list of all trades

---

## 📊 CURRENT PROJECT STATE

- **EA Version**: v5.0.0.0
- **Total Trades in Current Dataset**: 2,287
- **Dashboard Tabs**: Overview, Summary, Temporal, Sessions, Optimization, Excursions, Analysis
- **Git**: All changes committed to `main` branch

---

## 🔑 IMPORTANT CONTEXT FILES

These files contain project context that persists across sessions:

1. `/CLAUDE_CONTEXT.md` - High-level project overview
2. `/CONTEXT_PROMPT_FOR_CLAUDE.md` - Detailed technical context
3. `/HANDOFF_v5_0_0_0_MASTER.md` - Previous major handoff
4. `/docs/copilot-prompt-pack.md` - Coding standards and patterns
5. `/analytics/csv_processing/types.ts` - Full data model definitions

---

## 💬 CHAT HISTORY NOTE

**Chat threads are stored locally per machine, NOT in the project folder.**

To maintain continuity across machines:
1. Create handoff docs like this one before switching
2. Start new sessions by referencing the latest handoff
3. Key context files travel with the project on SSD

---

*Last updated: November 26, 2025 @ end of session*
