#!/usr/bin/env python3
"""
Update Dashboard with v5.0.0.0 Data
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Configuration
sns.set_style('darkgrid')
plt.rcParams['figure.facecolor'] = '#1a1a1a'
plt.rcParams['axes.facecolor'] = '#2d2d2d'
plt.rcParams['text.color'] = 'white'
plt.rcParams['axes.labelcolor'] = 'white'
plt.rcParams['xtick.color'] = 'white'
plt.rcParams['ytick.color'] = 'white'
plt.rcParams['grid.color'] = '#404040'

# Point to the new v5.0.0.0 files on Desktop
BASE_DIR = Path('/Users/patjohnston/Desktop/MT5_Backtest_Files')
OUTPUT_DIR = Path('/Users/patjohnston/ai-trading-platform/analytics/multi_asset_output')
OUTPUT_DIR.mkdir(exist_ok=True)

DATASETS = [
    {
        'name': 'v5.0.0.0_MASTER',
        'signals': 'TP_Integrated_NAS100_M05_MTBacktest_v5.0.0.0_MASTER_signals.csv',
        'trades': 'TP_Integrated_NAS100_M05_MTBacktest_v5.0.0.0_MASTER_trades.csv',
        'asset': 'NAS100',
        'timeframe': '5M'
    }
]

print('='*80)
print('  📊 UPDATING DASHBOARD WITH v5.0.0.0 DATA')
print('='*80 + '\n')

# Load data
all_data = []
for dataset in DATASETS:
    try:
        signals_path = BASE_DIR / dataset['signals']
        trades_path = BASE_DIR / dataset['trades']
        
        if not signals_path.exists() or not trades_path.exists():
            print(f"❌ Files not found for {dataset['name']}")
            continue
            
        signals = pd.read_csv(signals_path)
        trades = pd.read_csv(trades_path)
        
        # Merge
        # Note: Adjust merge keys if necessary based on CSV structure
        # v5 CSVs might have different column names, let's try standard ones
        merged = pd.merge(trades, signals, left_on='OpenTime', right_on='Timestamp', how='inner')
        
        merged['IsWin'] = (merged['Profit'] > 0).astype(int)
        merged['Dataset'] = dataset['name']
        merged['AssetClass'] = dataset['asset']
        merged['Timeframe'] = dataset['timeframe']
        
        all_data.append(merged)
        print(f"✅ Loaded {dataset['name']}: {len(merged)} trades")
    except Exception as e:
        print(f"❌ Error loading {dataset['name']}: {e}")

if not all_data:
    print("No data loaded. Exiting.")
    exit(1)

combined_df = pd.concat(all_data, ignore_index=True)
print(f'\n📊 Combined Dataset: {len(combined_df)} total trades\n')

# === VISUALIZATION 1: Physics Score Quartile Performance ===
print('📈 Creating Physics Score Quartile Chart...')
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
fig.patch.set_facecolor('#1a1a1a')

if 'PhysicsScore' in combined_df.columns:
    combined_df['PSQuartile'] = pd.qcut(combined_df['PhysicsScore'], q=4, 
                                          labels=['Q1\n(0-25%)', 'Q2\n(25-50%)', 'Q3\n(50-75%)', 'Q4\n(75-100%)'])

    # Win Rate by Quartile
    quartile_stats = combined_df.groupby('PSQuartile', observed=True).agg({
        'IsWin': 'mean',
        'Profit': 'mean',
        'Ticket': 'count'
    })

    ax1.bar(range(4), quartile_stats['IsWin'] * 100, color=['#ff6b6b', '#ffd93d', '#6bcf7f', '#4ecdc4'], 
            edgecolor='white', linewidth=2)
    ax1.set_xlabel('Physics Score Quartile', fontsize=12, fontweight='bold')
    ax1.set_ylabel('Win Rate (%)', fontsize=12, fontweight='bold')
    ax1.set_title('Win Rate by Physics Score Quartile', fontsize=14, fontweight='bold', color='#00d4ff')
    ax1.set_xticks(range(4))
    ax1.set_xticklabels(quartile_stats.index)
    ax1.grid(axis='y', alpha=0.3)
    for i, v in enumerate(quartile_stats['IsWin'] * 100):
        ax1.text(i, v + 1, f'{v:.1f}%', ha='center', fontweight='bold', fontsize=11)

    # Trade Count by Quartile
    ax2.bar(range(4), quartile_stats['Ticket'], color=['#ff6b6b', '#ffd93d', '#6bcf7f', '#4ecdc4'],
            edgecolor='white', linewidth=2)
    ax2.set_xlabel('Physics Score Quartile', fontsize=12, fontweight='bold')
    ax2.set_ylabel('Number of Trades', fontsize=12, fontweight='bold')
    ax2.set_title('Trade Distribution by Physics Score Quartile', fontsize=14, fontweight='bold', color='#00d4ff')
    ax2.set_xticks(range(4))
    ax2.set_xticklabels(quartile_stats.index)
    ax2.grid(axis='y', alpha=0.3)
    for i, v in enumerate(quartile_stats['Ticket']):
        ax2.text(i, v + 10, str(int(v)), ha='center', fontweight='bold', fontsize=11)

    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'physics_score_quartile_performance.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
    print(f'   ✅ Saved: physics_score_quartile_performance.png')
    plt.close()

# === VISUALIZATION 2: Confluence Impact ===
print('📈 Creating Confluence Impact Chart...')
fig, ax = plt.subplots(figsize=(12, 7))
fig.patch.set_facecolor('#1a1a1a')

conf_data = []
for dataset in combined_df['Dataset'].unique():
    subset = combined_df[combined_df['Dataset'] == dataset]
    if 'Confluence' in subset.columns:
        # Check unique confluence values to decide what to plot
        # For v5, we might have different values. Let's plot bins if continuous, or specific values if discrete.
        # Assuming similar structure to previous versions for now
        for conf in [80.0, 100.0]:
             # Check if these values exist roughly
            conf_subset = subset[(subset['Confluence'] >= conf - 5) & (subset['Confluence'] <= conf + 5)]
            if len(conf_subset) > 0:
                conf_data.append({
                    'Dataset': dataset,
                    'Confluence': f'{int(conf)}%',
                    'WinRate': conf_subset['IsWin'].mean() * 100,
                    'Trades': len(conf_subset)
                })

conf_df = pd.DataFrame(conf_data)
if not conf_df.empty:
    sns.barplot(data=conf_df, x='Dataset', y='WinRate', hue='Confluence', palette='viridis', ax=ax)
    
    ax.set_xlabel('Dataset', fontsize=12, fontweight='bold')
    ax.set_ylabel('Win Rate (%)', fontsize=12, fontweight='bold')
    ax.set_title('Impact of Confluence', fontsize=14, fontweight='bold', color='#00d4ff')
    ax.grid(axis='y', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'confluence_impact_comparison.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
    print(f'   ✅ Saved: confluence_impact_comparison.png')
plt.close()

# === VISUALIZATION 3: Physics Metrics Correlation Heatmap ===
print('📈 Creating Physics Metrics Correlation Heatmap...')
fig, ax = plt.subplots(figsize=(12, 10))
fig.patch.set_facecolor('#1a1a1a')

physics_cols = ['Acceleration', 'Speed', 'Jerk', 'Momentum', 'Confluence', 'Quality', 'PhysicsScore', 'IsWin', 'SpeedSlope', 'AccelerationSlope']
available_cols = [col for col in physics_cols if col in combined_df.columns]
if available_cols:
    corr_matrix = combined_df[available_cols].corr()

    mask = np.triu(np.ones_like(corr_matrix, dtype=bool), k=1)
    sns.heatmap(corr_matrix, mask=mask, annot=True, fmt='.3f', cmap='RdYlGn', center=0,
                square=True, linewidths=1, cbar_kws={"shrink": 0.8}, ax=ax,
                vmin=-0.3, vmax=0.3)

    ax.set_title('Physics Metrics Correlation Matrix', 
                 fontsize=14, fontweight='bold', color='#00d4ff', pad=20)
    plt.tight_layout()
    plt.savefig(OUTPUT_DIR / 'physics_correlation_heatmap.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
    print(f'   ✅ Saved: physics_correlation_heatmap.png')
    plt.close()

# === VISUALIZATION 4: Asset Class Comparison (Just one asset here) ===
# Skipping or adapting
print('📈 Creating Asset Class Comparison Chart (Single Asset)...')
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
fig.patch.set_facecolor('#1a1a1a')

asset_stats = combined_df.groupby('AssetClass').agg({
    'IsWin': 'mean',
    'Profit': 'sum',
    'Ticket': 'count'
})

colors = ['#4ecdc4']
ax1.bar(asset_stats.index, asset_stats['IsWin'] * 100, color=colors, edgecolor='white', linewidth=2)
ax1.set_ylabel('Win Rate (%)', fontsize=12, fontweight='bold')
ax1.set_title('Win Rate', fontsize=14, fontweight='bold', color='#00d4ff')
ax1.grid(axis='y', alpha=0.3)

ax2.bar(asset_stats.index, asset_stats['Ticket'], color=colors, edgecolor='white', linewidth=2)
ax2.set_ylabel('Number of Trades', fontsize=12, fontweight='bold')
ax2.set_title('Trade Count', fontsize=14, fontweight='bold', color='#00d4ff')

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'asset_class_comparison.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
print(f'   ✅ Saved: asset_class_comparison.png')
plt.close()

# === VISUALIZATION 5: Per-Dataset Performance ===
print('📈 Creating Per-Dataset Performance Chart...')
fig, ax = plt.subplots(figsize=(14, 8))
fig.patch.set_facecolor('#1a1a1a')

dataset_stats = combined_df.groupby('Dataset').agg({
    'IsWin': 'mean',
    'Ticket': 'count',
    'Profit': 'sum'
}).sort_values('IsWin', ascending=False)

colors_palette = ['#6bcf7f' if x > 0.4 else '#ffd93d' if x > 0.35 else '#ff6b6b' 
                  for x in dataset_stats['IsWin']]

bars = ax.barh(range(len(dataset_stats)), dataset_stats['IsWin'] * 100, 
               color=colors_palette, edgecolor='white', linewidth=2)
ax.set_yticks(range(len(dataset_stats)))
ax.set_yticklabels(dataset_stats.index)
ax.set_xlabel('Win Rate (%)', fontsize=12, fontweight='bold')
ax.set_title('Win Rate by Dataset', fontsize=14, fontweight='bold', color='#00d4ff')
ax.grid(axis='x', alpha=0.3)

for i, (idx, row) in enumerate(dataset_stats.iterrows()):
    ax.text(row['IsWin'] * 100 + 1, i, f'{row["IsWin"]*100:.1f}% ({int(row["Ticket"])} trades)', 
            va='center', fontweight='bold', fontsize=10)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'dataset_performance_ranking.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
print(f'   ✅ Saved: dataset_performance_ranking.png')
plt.close()

# === VISUALIZATION 6: Physics Score Distribution ===
print('📈 Creating Physics Score Distribution Chart...')
fig, ax = plt.subplots(figsize=(10, 6))
fig.patch.set_facecolor('#1a1a1a')

if 'PhysicsScore' in combined_df.columns:
    ax.hist(combined_df['PhysicsScore'], bins=30, color='#4ecdc4', edgecolor='white', alpha=0.7)
    ax.axvline(combined_df['PhysicsScore'].mean(), color='#ff6b6b', linestyle='--', linewidth=2, label='Mean')
    ax.axvline(combined_df['PhysicsScore'].median(), color='#ffd93d', linestyle='--', linewidth=2, label='Median')
    ax.set_xlabel('Physics Score', fontsize=10)
    ax.set_ylabel('Frequency', fontsize=10)
    ax.set_title(f'Physics Score Distribution\n(μ={combined_df["PhysicsScore"].mean():.1f}, σ={combined_df["PhysicsScore"].std():.1f})', 
                      fontsize=11, fontweight='bold')
    ax.legend(fontsize=9)
    ax.grid(alpha=0.3)

plt.tight_layout()
plt.savefig(OUTPUT_DIR / 'physics_score_distributions.png', dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
print(f'   ✅ Saved: physics_score_distributions.png')
plt.close()

print('\n' + '='*80)
print('  ✅ DASHBOARD UPDATED SUCCESSFULLY')
print('='*80)
