# Signal-Trade Correlation Analysis Output

This directory contains a comprehensive analysis correlating signal metrics with trading outcomes to identify which metrics have the biggest impact on profitability.

## 🌐 Interactive Dashboard

**👉 Open `dashboard.html` in your browser for an interactive experience!**

The dashboard includes:
- 📊 Tabbed interface with Overview, Key Findings, Correlations, Visualizations, Recommendations, and Downloads
- 📈 Embedded visualizations with interactive explanations
- 💡 Actionable recommendations with priority levels
- 📥 Direct download links for all reports and data files

**To view the dashboard:**
1. Simply open `dashboard.html` in any modern web browser
2. Or run a local server: `python -m http.server 8888` and visit `http://localhost:8888/dashboard.html`

## 📁 Files in this Directory

### 📄 Reports & Documentation

| File | Description | Best For |
|------|-------------|----------|
| **`dashboard.html`** | 🌐 Interactive web dashboard with tabs and visualizations | **START HERE** - Best overall experience |
| **`QUICK_REFERENCE.md`** | 2-page executive summary with actionable insights | Quick review, implementation decisions |
| **`ANALYSIS_REPORT.md`** | Full 10-page detailed analysis report | Deep dive, understanding methodology |
| **`README.md`** | This file - directory guide | Navigation |

### 📊 Data Files

| File | Description | Use Case |
|------|-------------|----------|
| **`correlation_results.csv`** | Complete correlation table (56 signal-outcome pairs) | Statistical analysis, custom queries |
| **`merged_signals_trades.csv`** | Combined signals + trades dataset (134 rows) | Further analysis, custom visualizations |
| **`analysis_summary.json`** | Machine-readable summary statistics | Programmatic access, dashboards |

### 📈 Visualizations

| File | Description |
|------|-------------|
| **`correlation_heatmap.png`** | Color-coded matrix of all correlations |
| **`top_correlations_scatter.png`** | Scatter plots of top 6 strongest relationships |
| **`quality_performance.png`** | Performance breakdown by signal quality levels |

## 🚀 Quick Start

### If you have 2 minutes:
Read **`QUICK_REFERENCE.md`** → Get the top 3 insights and action items

### If you have 15 minutes:
1. Read `QUICK_REFERENCE.md`
2. View the three visualization files
3. Scan the Executive Summary in `ANALYSIS_REPORT.md`

### If you want deep analysis:
Read **`ANALYSIS_REPORT.md`** cover to cover

### If you want to do your own analysis:
Use **`merged_signals_trades.csv`** and **`correlation_results.csv`**

## 🎯 Key Findings at a Glance

### Most Important Signal Metrics (in order):

1. **Acceleration** (r=+0.279 with win rate) ⭐⭐⭐
2. **Confluence** (100% vs 80% makes huge difference) ⭐⭐⭐
3. **Jerk** (r=+0.230 with profit) ⭐⭐
4. **Momentum** (r=+0.210 with profit) ⭐⭐
5. Speed (r=+0.207 with win rate) ⭐

### Critical Insight:
**Trading only 100% confluence signals could triple your profit per trade** (from $0.57 to $1.67 average)

## 📊 Analysis Details

- **Dataset:** NAS100 v3.1.1 backtest results
- **Trades Analyzed:** 134 matched signal-trade pairs
- **Statistical Method:** Pearson & Spearman correlations with significance testing
- **Significance Level:** α = 0.05

## 🔄 How to Regenerate Analysis

To run the analysis again (e.g., for different versions):

```bash
cd /Users/patjohnston/ai-trading-platform/analytics
python signal_trade_correlation_analysis.py
```

Edit the file paths in the `main()` function to analyze different datasets (v3.1.0, v3.2, etc.)

## 📧 Questions?

Refer to:
- Methodology section in `ANALYSIS_REPORT.md`
- Python script: `../signal_trade_correlation_analysis.py`
- Raw correlation data: `correlation_results.csv`

## 🎨 Visualization Guide

### Correlation Heatmap (`correlation_heatmap.png`)
- **Green:** Positive correlation (higher signal metric → better outcome)
- **Red:** Negative correlation (higher signal metric → worse outcome)
- **Yellow/White:** Weak or no correlation
- **Numbers:** Correlation coefficient (-1.0 to +1.0)

### Scatter Plots (`top_correlations_scatter.png`)
- Six plots showing the strongest relationships
- Red dashed line = trend line
- Title includes correlation coefficient and p-value

### Quality Performance (`quality_performance.png`)
- Four charts showing how signal quality affects outcomes
- Average Profit, Win Rate, R:R Ratio, and Trade Count
- Note: Some quality bins have very few trades

## 💡 Implementation Tips

1. **Start with Priority 1** items in QUICK_REFERENCE.md
2. **Backtest changes** on other datasets before live trading
3. **Monitor key metrics** after implementation:
   - Win rate (should increase toward 56%)
   - Average profit per trade (should increase toward $1.67)
   - Trade frequency (will decrease with stricter filters)

## 📈 Next Steps

1. ✅ Review findings
2. ✅ Implement 100% confluence filter
3. ✅ Adjust signal weighting (increase acceleration weight)
4. 📊 Backtest on v3.1.0, v3.2 datasets to validate
5. 📊 Apply to live trading with caution
6. 📊 Monitor and iterate

---

**Generated:** November 12, 2025  
**Analysis Tool:** Python script with pandas, scipy, matplotlib, seaborn  
**Source Code:** `../signal_trade_correlation_analysis.py`
