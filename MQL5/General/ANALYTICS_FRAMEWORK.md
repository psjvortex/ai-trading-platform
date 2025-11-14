# 📊 TickPhysics Analytics & Correlation Framework

## 🎯 **Purpose**

This framework analyzes backtest CSV data to identify **which physics metrics correlate with winning trades**, enabling data-driven filter optimization and self-learning EA development.

---

## 📋 **Workflow Overview**

```
1. Backtest Pass (MA Crossover Baseline)
   └─> Generate CSV with 30-50 trades
       └─> ALL physics metrics logged
           └─> NO filters applied

2. Analytics Engine (This Framework)
   └─> Load CSV directly from MetaTrader
       └─> Separate winners vs losers
           └─> Calculate correlations
               └─> Identify predictive metrics

3. Filter Optimization
   └─> Enable top correlated filter
       └─> Re-run SAME date range
           └─> Compare results
               └─> Iterate

4. JSON Learning Module (Future)
   └─> Store insights
       └─> Auto-adjust thresholds
           └─> Self-optimize
```

---

## 🔬 **Phase 1: Baseline Data Collection**

### EA Configuration for Pass 1

```
Entry System:
  UseMAEntry = true
  UsePhysicsEntry = false
  MA_Fast = 10
  MA_Slow = 30

Physics Filters:
  UsePhysicsFilters = false    ← CRITICAL: Collect all data!
  UseZoneFilter = false
  UseRegimeFilter = false

Risk Management:
  RiskPercentPerTrade = 1.0
  StopLossPips = 50
  TakeProfitPips = 100

Logging:
  EnableRealTimeLogging = true
  PostExitMonitorBars = 50
```

### Expected Output

**File:** `TP_Integrated_Trades_NAS100.csv` (or EURUSD, etc.)

**Sample Data Structure:**
```csv
Ticket,Type,Profit,Pips,EntryQuality,EntryConfluence,EntryMomentum,EntryEntropy,EntryZone,EntryRegime,ExitReason,MFE_Pips,MAE_Pips,RunUp_Pips,RunDown_Pips
12345,BUY,25.50,12.5,72.3,80.1,125.4,1.2,BULL,NORMAL,TP,15.2,-3.5,18.7,-2.1
12346,SELL,-18.30,-9.2,58.7,45.2,85.3,2.8,AVOID,HIGH,SL,2.1,-9.8,5.3,-15.4
...
```

---

## 📊 **Phase 2: Winner vs Loser Analysis**

### Core Questions We Answer

1. **Which physics metrics predict winners?**
   - EntryQuality >70 → Win rate?
   - EntryConfluence >75 → Win rate?
   - EntryZone = BULL → Win rate?

2. **Which metrics predict losers?**
   - EntryEntropy >2.5 → Loss rate?
   - EntryZone = AVOID → Loss rate?
   - EntryRegime = HIGH → Loss rate?

3. **What thresholds maximize win rate?**
   - Quality threshold sweep: 50, 55, 60, 65, 70, 75, 80
   - Find inflection point where win rate jumps

4. **Which combinations work best?**
   - Quality >70 + Confluence >75 + Zone = BULL
   - vs Quality >65 + Any zone
   - vs Quality >75 + Low entropy (<2.0)

---

## 🐍 **Python Analytics Script Template**

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# ====================================================================
# STEP 1: Load CSV directly from MetaTrader
# ====================================================================

MT5_FILES_PATH = "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files"

def load_backtest_data(symbol="NAS100"):
    csv_file = Path(MT5_FILES_PATH) / f"TP_Integrated_Trades_{symbol}.csv"
    if not csv_file.exists():
        print(f"❌ File not found: {csv_file}")
        return None
    
    df = pd.read_csv(csv_file)
    print(f"✅ Loaded {len(df)} trades from {csv_file.name}")
    return df

# ====================================================================
# STEP 2: Separate Winners vs Losers
# ====================================================================

def analyze_winners_vs_losers(df):
    """
    Core analysis: What makes winners different from losers?
    """
    winners = df[df['Profit'] > 0].copy()
    losers = df[df['Profit'] <= 0].copy()
    
    print("\n" + "="*60)
    print("📊 BASELINE STATISTICS")
    print("="*60)
    print(f"Total Trades: {len(df)}")
    print(f"Winners: {len(winners)} ({len(winners)/len(df)*100:.1f}%)")
    print(f"Losers: {len(losers)} ({len(losers)/len(df)*100:.1f}%)")
    print(f"Win Rate: {len(winners)/len(df)*100:.1f}%")
    print(f"Avg Profit (Winners): ${winners['Profit'].mean():.2f}")
    print(f"Avg Loss (Losers): ${losers['Profit'].mean():.2f}")
    print(f"Profit Factor: {winners['Profit'].sum() / abs(losers['Profit'].sum()):.2f}")
    
    return winners, losers

# ====================================================================
# STEP 3: Physics Metrics Correlation Analysis
# ====================================================================

def correlate_physics_metrics(df, winners, losers):
    """
    Find which physics metrics correlate with winning trades
    """
    physics_cols = [
        'EntryQuality', 'EntryConfluence', 'EntryMomentum', 
        'EntryEntropy', 'MFE_Pips', 'MAE_Pips'
    ]
    
    print("\n" + "="*60)
    print("🔬 PHYSICS METRICS: WINNERS vs LOSERS")
    print("="*60)
    
    comparison = pd.DataFrame({
        'Metric': physics_cols,
        'Winners (Avg)': [winners[col].mean() for col in physics_cols],
        'Losers (Avg)': [losers[col].mean() for col in physics_cols],
    })
    comparison['Difference'] = comparison['Winners (Avg)'] - comparison['Losers (Avg)']
    comparison['% Difference'] = (comparison['Difference'] / comparison['Losers (Avg)']) * 100
    
    # Sort by absolute difference (highest correlation)
    comparison['Abs_Diff'] = comparison['Difference'].abs()
    comparison = comparison.sort_values('Abs_Diff', ascending=False)
    
    print(comparison.to_string(index=False))
    
    return comparison

# ====================================================================
# STEP 4: Zone & Regime Distribution
# ====================================================================

def analyze_zones_and_regimes(df):
    """
    Which zones/regimes have best win rates?
    """
    print("\n" + "="*60)
    print("🎯 TRADING ZONE ANALYSIS")
    print("="*60)
    
    zone_stats = df.groupby('EntryZone').agg({
        'Profit': ['count', 'mean', 'sum'],
        'Pips': 'mean'
    }).round(2)
    
    # Calculate win rate per zone
    for zone in df['EntryZone'].unique():
        zone_df = df[df['EntryZone'] == zone]
        win_rate = len(zone_df[zone_df['Profit'] > 0]) / len(zone_df) * 100
        print(f"{zone}: {len(zone_df)} trades, {win_rate:.1f}% win rate, "
              f"Avg: ${zone_df['Profit'].mean():.2f}, Total: ${zone_df['Profit'].sum():.2f}")
    
    print("\n" + "="*60)
    print("⚡ VOLATILITY REGIME ANALYSIS")
    print("="*60)
    
    for regime in df['EntryRegime'].unique():
        regime_df = df[df['EntryRegime'] == regime]
        win_rate = len(regime_df[regime_df['Profit'] > 0]) / len(regime_df) * 100
        print(f"{regime}: {len(regime_df)} trades, {win_rate:.1f}% win rate, "
              f"Avg: ${regime_df['Profit'].mean():.2f}")

# ====================================================================
# STEP 5: Threshold Optimization
# ====================================================================

def find_optimal_thresholds(df):
    """
    Test different quality/confluence thresholds to find sweet spots
    """
    print("\n" + "="*60)
    print("🎯 QUALITY THRESHOLD SWEEP")
    print("="*60)
    
    thresholds = [50, 55, 60, 65, 70, 75, 80]
    results = []
    
    for threshold in thresholds:
        filtered = df[df['EntryQuality'] >= threshold]
        if len(filtered) == 0:
            continue
        
        win_rate = len(filtered[filtered['Profit'] > 0]) / len(filtered) * 100
        avg_profit = filtered['Profit'].mean()
        
        results.append({
            'Quality_Threshold': threshold,
            'Trades': len(filtered),
            'Win_Rate_%': win_rate,
            'Avg_Profit_$': avg_profit,
            'Total_Profit_$': filtered['Profit'].sum()
        })
    
    results_df = pd.DataFrame(results)
    print(results_df.to_string(index=False))
    
    # Find best threshold
    best = results_df.loc[results_df['Win_Rate_%'].idxmax()]
    print(f"\n🏆 BEST QUALITY THRESHOLD: {best['Quality_Threshold']}")
    print(f"   Win Rate: {best['Win_Rate_%']:.1f}%")
    print(f"   Trades: {best['Trades']}")
    
    return results_df

# ====================================================================
# STEP 6: Exit Reason Analysis
# ====================================================================

def analyze_exit_reasons(df):
    """
    How often does each exit reason occur? Which is most profitable?
    """
    print("\n" + "="*60)
    print("🚪 EXIT REASON DISTRIBUTION")
    print("="*60)
    
    for reason in df['ExitReason'].unique():
        reason_df = df[df['ExitReason'] == reason]
        win_rate = len(reason_df[reason_df['Profit'] > 0]) / len(reason_df) * 100
        print(f"{reason}: {len(reason_df)} trades ({len(reason_df)/len(df)*100:.1f}%), "
              f"{win_rate:.1f}% win rate, Avg: ${reason_df['Profit'].mean():.2f}")

# ====================================================================
# STEP 7: MFE/MAE & RunUp/RunDown Insights
# ====================================================================

def analyze_mfe_mae_runup_rundown(df):
    """
    Analyze post-entry and post-exit price movement
    """
    print("\n" + "="*60)
    print("📈 MFE/MAE ANALYSIS")
    print("="*60)
    
    winners = df[df['Profit'] > 0]
    losers = df[df['Profit'] <= 0]
    
    print(f"Winners - Avg MFE: {winners['MFE_Pips'].mean():.2f} pips, Avg MAE: {winners['MAE_Pips'].mean():.2f} pips")
    print(f"Losers  - Avg MFE: {losers['MFE_Pips'].mean():.2f} pips, Avg MAE: {losers['MAE_Pips'].mean():.2f} pips")
    
    print("\n" + "="*60)
    print("🔄 RUNUP/RUNDOWN ANALYSIS (Post-Exit Movement)")
    print("="*60)
    
    print(f"Avg RunUp: {df['RunUp_Pips'].mean():.2f} pips (max favorable after exit)")
    print(f"Avg RunDown: {df['RunDown_Pips'].mean():.2f} pips (max adverse after exit)")
    
    # Identify "exited too early" trades (RunUp >> Profit)
    early_exits = df[(df['Profit'] > 0) & (df['RunUp_Pips'] > df['Pips'] * 2)]
    if len(early_exits) > 0:
        print(f"\n⚠️  {len(early_exits)} trades exited too early (RunUp >2x Profit)")
        print(f"   Avg Profit: ${early_exits['Profit'].mean():.2f}")
        print(f"   Avg RunUp: {early_exits['RunUp_Pips'].mean():.2f} pips")
        print(f"   Missed Opportunity: ${(early_exits['RunUp_Pips'].mean() - early_exits['Pips'].mean()) * 10:.2f}/trade")

# ====================================================================
# STEP 8: Generate Visualizations
# ====================================================================

def create_dashboards(df, winners, losers):
    """
    Create visual dashboards for presentation
    """
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('TickPhysics Backtest Analytics Dashboard', fontsize=16, fontweight='bold')
    
    # 1. Quality Distribution: Winners vs Losers
    axes[0, 0].hist([winners['EntryQuality'], losers['EntryQuality']], 
                    label=['Winners', 'Losers'], bins=15, alpha=0.7)
    axes[0, 0].set_title('Entry Quality Distribution')
    axes[0, 0].set_xlabel('Quality')
    axes[0, 0].legend()
    
    # 2. Confluence Distribution: Winners vs Losers
    axes[0, 1].hist([winners['EntryConfluence'], losers['EntryConfluence']], 
                    label=['Winners', 'Losers'], bins=15, alpha=0.7)
    axes[0, 1].set_title('Entry Confluence Distribution')
    axes[0, 1].set_xlabel('Confluence')
    axes[0, 1].legend()
    
    # 3. Zone Win Rate
    zone_data = df.groupby('EntryZone').apply(
        lambda x: len(x[x['Profit'] > 0]) / len(x) * 100
    ).sort_values(ascending=False)
    axes[1, 0].bar(zone_data.index, zone_data.values)
    axes[1, 0].set_title('Win Rate by Trading Zone')
    axes[1, 0].set_ylabel('Win Rate %')
    axes[1, 0].tick_params(axis='x', rotation=45)
    
    # 4. MFE vs MAE Scatter
    axes[1, 1].scatter(df['MAE_Pips'], df['MFE_Pips'], 
                      c=['green' if p > 0 else 'red' for p in df['Profit']], 
                      alpha=0.6)
    axes[1, 1].set_title('MFE vs MAE (Green=Winners, Red=Losers)')
    axes[1, 1].set_xlabel('MAE (Pips)')
    axes[1, 1].set_ylabel('MFE (Pips)')
    axes[1, 1].axhline(0, color='black', linestyle='--', linewidth=0.5)
    axes[1, 1].axvline(0, color='black', linestyle='--', linewidth=0.5)
    
    plt.tight_layout()
    plt.savefig('backtest_analytics_dashboard.png', dpi=300, bbox_inches='tight')
    print("\n✅ Dashboard saved: backtest_analytics_dashboard.png")

# ====================================================================
# STEP 9: Generate Recommendations
# ====================================================================

def generate_recommendations(comparison_df, threshold_results):
    """
    AI-powered recommendations for next optimization pass
    """
    print("\n" + "="*60)
    print("🤖 AI RECOMMENDATIONS FOR NEXT PASS")
    print("="*60)
    
    # Find metric with highest positive correlation to winners
    top_metric = comparison_df.iloc[0]
    
    print(f"\n1️⃣ HIGHEST CORRELATION METRIC:")
    print(f"   Metric: {top_metric['Metric']}")
    print(f"   Winners Avg: {top_metric['Winners (Avg)']:.2f}")
    print(f"   Losers Avg: {top_metric['Losers (Avg)']:.2f}")
    print(f"   Difference: {top_metric['% Difference']:.1f}%")
    
    # Optimal threshold
    best_threshold = threshold_results.loc[threshold_results['Win_Rate_%'].idxmax()]
    
    print(f"\n2️⃣ RECOMMENDED FILTER:")
    print(f"   UsePhysicsFilters = true")
    print(f"   MinQuality = {best_threshold['Quality_Threshold']}")
    print(f"   Expected Win Rate: {best_threshold['Win_Rate_%']:.1f}%")
    print(f"   Expected Trades: {best_threshold['Trades']}")
    
    print(f"\n3️⃣ NEXT BACKTEST CONFIGURATION:")
    print(f"   - Run SAME date range as Pass 1")
    print(f"   - Enable UsePhysicsFilters = true")
    print(f"   - Set MinQuality = {best_threshold['Quality_Threshold']}")
    print(f"   - Compare results to baseline")

# ====================================================================
# MAIN EXECUTION
# ====================================================================

def run_full_analysis(symbol="NAS100"):
    """
    Complete analytics pipeline
    """
    print("\n" + "="*60)
    print("🚀 TICKPHYSICS ANALYTICS ENGINE")
    print("="*60)
    
    # Load data
    df = load_backtest_data(symbol)
    if df is None:
        return
    
    # Core analysis
    winners, losers = analyze_winners_vs_losers(df)
    comparison = correlate_physics_metrics(df, winners, losers)
    analyze_zones_and_regimes(df)
    threshold_results = find_optimal_thresholds(df)
    analyze_exit_reasons(df)
    analyze_mfe_mae_runup_rundown(df)
    
    # Visualizations
    create_dashboards(df, winners, losers)
    
    # AI Recommendations
    generate_recommendations(comparison, threshold_results)
    
    print("\n" + "="*60)
    print("✅ ANALYSIS COMPLETE!")
    print("="*60)
    
    return df, winners, losers, comparison, threshold_results

# ====================================================================
# RUN IT!
# ====================================================================

if __name__ == "__main__":
    df, winners, losers, comparison, threshold_results = run_full_analysis("NAS100")
```

---

## 📈 **Expected Insights from First Pass**

### Hypothesis Testing

**Hypothesis 1: Quality Matters**
```
If quality >70:
  Win Rate: XX% (baseline: XX%)
  Avg Profit: $XX (baseline: $XX)
  
Decision: Enable MinQuality filter? Yes/No
```

**Hypothesis 2: Avoid AVOID Zone**
```
AVOID zone trades:
  Win Rate: XX%
  Avg Profit: $XX
  
BULL zone trades:
  Win Rate: XX%
  Avg Profit: $XX
  
Decision: Enable UseZoneFilter? Yes/No
```

**Hypothesis 3: Low Entropy = Better**
```
Entropy <2.0:
  Win Rate: XX%
  
Entropy >2.5:
  Win Rate: XX%
  
Decision: Add entropy filter? Yes/No
```

---

## 🔄 **Iterative Optimization Workflow**

### Pass 1: Baseline
```
Config:
  UseMAEntry = true
  UsePhysicsFilters = false

Results:
  47 trades, 53% win rate, PF 1.12

Insights:
  Quality >70 → 68% win rate
  AVOID zone → 38% win rate
```

### Pass 2: Enable Top Filter
```
Config:
  UseMAEntry = true
  UsePhysicsFilters = true
  MinQuality = 70

Results:
  32 trades, 68% win rate, PF 1.85

Improvement:
  +28% win rate
  +65% profit factor
```

### Pass 3: Add Second Filter
```
Config:
  UsePhysicsFilters = true
  MinQuality = 70
  UseZoneFilter = true (exclude AVOID)

Results:
  24 trades, 75% win rate, PF 2.15

Improvement:
  +10% win rate
  +16% profit factor
```

---

## 🎯 **Success Metrics**

After each pass, we compare:

| Metric | Pass 1 (Baseline) | Pass 2 | Pass 3 | Target |
|--------|-------------------|--------|--------|--------|
| Total Trades | 47 | 32 | 24 | >20 |
| Win Rate % | 53 | 68 | 75 | >70 |
| Profit Factor | 1.12 | 1.85 | 2.15 | >2.0 |
| Avg Winner $ | 28.50 | 32.10 | 35.20 | >30 |
| Avg Loser $ | -22.30 | -18.50 | -15.10 | <-20 |
| Max DD % | -5.2 | -3.8 | -2.9 | <-3.0 |

---

## 🤖 **Future: JSON Self-Learning Module**

Based on these analytics, we'll build:

```json
{
  "learning_config": {
    "auto_optimize": true,
    "optimization_frequency": "monthly",
    "min_sample_size": 30
  },
  "learned_filters": {
    "quality": {
      "enabled": true,
      "threshold": 70.0,
      "confidence": 0.85,
      "win_rate_improvement": 28.3,
      "learned_from": "2025-10 backtest"
    },
    "zone_filter": {
      "enabled": true,
      "exclude": ["AVOID"],
      "confidence": 0.78,
      "win_rate_improvement": 10.2,
      "learned_from": "2025-10 backtest"
    }
  },
  "auto_adjustments": {
    "sl_distance": {
      "original": 50,
      "optimized": 55,
      "reason": "MAE analysis shows avg -53 pips",
      "confidence": 0.72
    }
  }
}
```

---

## 📞 **Next Steps**

1. ✅ **Compile updated EA** with MA crossover
2. ✅ **Run backtest** on NAS100, last 30 days
3. ✅ **Tell me when complete**, I'll pull CSV and run analytics
4. ✅ **Review insights** together
5. ✅ **Enable best filter**, re-run same period
6. ✅ **Compare results**, iterate

---

**Created:** November 4, 2025  
**Purpose:** Data-driven EA optimization framework  
**Goal:** Build self-learning trading system
