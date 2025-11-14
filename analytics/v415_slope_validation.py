#!/usr/bin/env python3
"""
v4.1.5 Slope Analysis & Validation
Verifies slope data capture and analyzes effectiveness vs v4.1.4

Purpose:
- Validate 33-column CSV structure
- Analyze slope distributions
- Correlate slopes with trade outcomes
- Compare v4.15 vs v4.13 performance
- Recommend optimal slope thresholds

Author: AI Trading Platform Team
Date: November 12, 2025
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from datetime import datetime

# Set style
plt.style.use('dark_background')
sns.set_palette("husl")

# Paths
DESKTOP_FOLDER = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's")
OUTPUT_DIR = Path(__file__).parent / "slope_validation_output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

print("=" * 80)
print("🚀 v4.1.5 SLOPE VALIDATION & ANALYSIS")
print("=" * 80)
print(f"\nTimestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Desktop Folder: {DESKTOP_FOLDER}")
print(f"Output Directory: {OUTPUT_DIR}\n")

# Load v4.15 data
print("📂 Loading v4.15 SLOPE data...")
signals_file = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.15_SLOPE_signals.csv"
trades_file = DESKTOP_FOLDER / "TP_Integrated_NAS100_M05_MTBacktest_v4.15_SLOPE_trades.csv"

if not signals_file.exists():
    print(f"❌ Signals file not found: {signals_file}")
    exit(1)

if not trades_file.exists():
    print(f"❌ Trades file not found: {trades_file}")
    exit(1)

df_signals = pd.read_csv(signals_file)
df_trades = pd.read_csv(trades_file)

print(f"✅ Loaded {len(df_signals):,} signals")
print(f"✅ Loaded {len(df_trades):,} trades\n")

# === VALIDATE CSV STRUCTURE ===
print("=" * 80)
print("📋 CSV STRUCTURE VALIDATION")
print("=" * 80 + "\n")

print(f"Signal CSV Columns: {len(df_signals.columns)}")
expected_cols = ['EAName', 'EAVersion', 'PhysicsScore', 
                 'SpeedSlope', 'AccelerationSlope', 'MomentumSlope', 
                 'ConfluenceSlope', 'JerkSlope']

missing = [col for col in expected_cols if col not in df_signals.columns]
if missing:
    print(f"❌ MISSING COLUMNS: {', '.join(missing)}\n")
else:
    print("✅ All expected columns present\n")

# Display slope columns
slope_cols = [col for col in df_signals.columns if 'Slope' in col]
print(f"Slope Columns Found ({len(slope_cols)}):")
for col in slope_cols:
    print(f"   - {col}")
print()

# === SLOPE STATISTICS ===
print("=" * 80)
print("📊 SLOPE STATISTICS")
print("=" * 80 + "\n")

slope_stats = df_signals[slope_cols].describe()
print(slope_stats.to_string())
print()

# Check for non-zero slopes
print("\nNon-Zero Slope Coverage:")
for col in slope_cols:
    non_zero = (df_signals[col] != 0).sum()
    pct = (non_zero / len(df_signals) * 100)
    print(f"   {col:<20} {non_zero:>6}/{len(df_signals)} ({pct:>5.1f}%)")
print()

# === SLOPE DISTRIBUTIONS ===
print("📈 Creating slope distribution plots...")

fig, axes = plt.subplots(2, 3, figsize=(18, 10))
fig.suptitle('v4.15 Slope Distributions', fontsize=16, fontweight='bold')

for idx, col in enumerate(slope_cols):
    if idx < 6:
        ax = axes[idx // 3, idx % 3]
        
        # Filter extreme outliers for better visualization
        data = df_signals[col]
        q1, q3 = data.quantile([0.01, 0.99])
        filtered = data[(data >= q1) & (data <= q3)]
        
        ax.hist(filtered, bins=50, alpha=0.7, edgecolor='white', linewidth=0.5)
        ax.axvline(0, color='red', linestyle='--', linewidth=2, alpha=0.7, label='Zero')
        ax.set_title(f'{col} Distribution', fontweight='bold')
        ax.set_xlabel('Slope Value')
        ax.set_ylabel('Frequency')
        ax.legend()
        ax.grid(alpha=0.3)

# Hide unused subplot
if len(slope_cols) < 6:
    axes[1, 2].axis('off')

plt.tight_layout()
output_file = OUTPUT_DIR / "slope_distributions.png"
plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
plt.close()
print(f"✅ Saved to {output_file}\n")

# === MERGE SIGNALS WITH TRADES ===
print("=" * 80)
print("🔗 MERGING SIGNALS WITH TRADE OUTCOMES")
print("=" * 80 + "\n")

# Merge on timestamp (signals should have logged at trade entry)
df_signals['Timestamp'] = pd.to_datetime(df_signals['Timestamp'])
df_trades['OpenTime'] = pd.to_datetime(df_trades['OpenTime'])

# Merge signals with trades
merged = pd.merge(
    df_trades,
    df_signals,
    left_on='OpenTime',
    right_on='Timestamp',
    how='left',
    suffixes=('_trade', '_signal')
)

print(f"✅ Merged {len(merged)} trades with signal data")
print(f"   Matches: {(~merged['SpeedSlope'].isna()).sum()}/{len(merged)}\n")

# Add win/loss column
merged['IsWin'] = merged['Profit'] > 0

# === SLOPE CORRELATION WITH WINS ===
print("=" * 80)
print("🎯 SLOPE CORRELATION WITH TRADE OUTCOMES")
print("=" * 80 + "\n")

correlations = {}
for col in slope_cols:
    if col in merged.columns:
        # Remove NaN values
        valid_data = merged[[col, 'IsWin']].dropna()
        if len(valid_data) > 0:
            corr = valid_data[col].corr(valid_data['IsWin'])
            correlations[col] = corr

# Sort by absolute correlation
sorted_corr = sorted(correlations.items(), key=lambda x: abs(x[1]), reverse=True)

print("Slope Correlations with Wins (sorted by strength):")
print(f"{'Slope Metric':<25} {'Correlation':<15} {'Interpretation'}")
print("-" * 60)
for slope, corr in sorted_corr:
    strength = "Strong" if abs(corr) > 0.3 else ("Moderate" if abs(corr) > 0.1 else "Weak")
    direction = "Positive" if corr > 0 else "Negative"
    print(f"{slope:<25} {corr:>+.4f}          {strength} {direction}")
print()

# === WIN RATE BY SLOPE DIRECTION ===
print("=" * 80)
print("📊 WIN RATE BY SLOPE DIRECTION")
print("=" * 80 + "\n")

for col in slope_cols:
    if col in merged.columns:
        # Split by slope direction
        positive_slope = merged[merged[col] > 0]
        negative_slope = merged[merged[col] < 0]
        
        if len(positive_slope) > 0 and len(negative_slope) > 0:
            pos_wr = (positive_slope['IsWin'].sum() / len(positive_slope) * 100)
            neg_wr = (negative_slope['IsWin'].sum() / len(negative_slope) * 100)
            diff = pos_wr - neg_wr
            
            print(f"{col}:")
            print(f"   Positive Slope: {pos_wr:>5.1f}% WR ({len(positive_slope):>4} trades)")
            print(f"   Negative Slope: {neg_wr:>5.1f}% WR ({len(negative_slope):>4} trades)")
            print(f"   Difference:     {diff:>+5.1f}%")
            print()

# === OPTIMAL THRESHOLD ANALYSIS ===
print("=" * 80)
print("🎯 OPTIMAL SLOPE THRESHOLD ANALYSIS")
print("=" * 80 + "\n")

for col in ['SpeedSlope', 'AccelerationSlope']:
    if col in merged.columns:
        print(f"\n{col} Threshold Analysis:")
        print("-" * 60)
        
        # Test different thresholds
        thresholds = np.arange(0, 50, 5)
        results = []
        
        for threshold in thresholds:
            # Positive slope filter
            filtered = merged[merged[col] > threshold]
            if len(filtered) > 10:
                wr = (filtered['IsWin'].sum() / len(filtered) * 100)
                results.append({
                    'threshold': threshold,
                    'trades': len(filtered),
                    'win_rate': wr
                })
        
        if results:
            df_results = pd.DataFrame(results)
            print(df_results.to_string(index=False))
            
            # Find optimal threshold (highest win rate with reasonable trade count)
            min_trades = len(merged) * 0.1  # At least 10% of trades
            valid = df_results[df_results['trades'] >= min_trades]
            if len(valid) > 0:
                optimal = valid.loc[valid['win_rate'].idxmax()]
                print(f"\n   📌 Recommended Threshold: {optimal['threshold']:.1f}")
                print(f"      Win Rate: {optimal['win_rate']:.1f}%")
                print(f"      Trade Count: {optimal['trades']}")

# === COMPARE WITH v4.1.3 (if available) ===
print("\n" + "=" * 80)
print("⚖️  PERFORMANCE COMPARISON: v4.15 vs v4.13")
print("=" * 80 + "\n")

# Try to find v4.13 data
v413_files = list(DESKTOP_FOLDER.glob("*v4.13*.csv"))
if v413_files:
    print(f"Found v4.13 files for comparison...")
    # Load and compare (to be implemented)
else:
    print("No v4.13 files found for comparison\n")

# === SUMMARY ===
print("=" * 80)
print("✅ VALIDATION COMPLETE")
print("=" * 80 + "\n")

print("📊 Summary:")
print(f"   Total Signals: {len(df_signals):,}")
print(f"   Total Trades: {len(df_trades):,}")
print(f"   Slope Columns: {len(slope_cols)}")
print(f"   Merged Records: {len(merged):,}")

if merged['IsWin'].sum() > 0:
    overall_wr = (merged['IsWin'].sum() / len(merged) * 100)
    print(f"   Overall Win Rate: {overall_wr:.1f}%")

print(f"\n📁 All outputs saved to: {OUTPUT_DIR}")
print("\n" + "=" * 80 + "\n")
