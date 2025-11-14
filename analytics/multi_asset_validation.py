#!/usr/bin/env python3
"""
Multi-Asset Physics Score Validation
Analyzes 6 diverse datasets to validate evidence-based weights and physics score
"""
import pandas as pd
import numpy as np
from scipy import stats
from pathlib import Path
import json

# Dataset configuration
DATASETS = [
    {'name': 'NAS100_5M', 'signals': 'TP_Integrated_Signals_NAS100_v3.1.4.csv', 
     'trades': 'TP_Integrated_Trades_NAS100_v3.1.4.csv', 'asset_class': 'Index'},
    {'name': 'NAS100_15M', 'signals': 'TP_Integrated_Signals_NAS100_15M_v4.13_PRODUCTION.csv',
     'trades': 'TP_Integrated_Trades_NAS100_15M_v4.13_PRODUCTION.csv', 'asset_class': 'Index'},
    {'name': 'US30_5M', 'signals': 'TP_Integrated_Signals_US30_v4.13_PRODUCTION.csv',
     'trades': 'TP_Integrated_Trades_US30_v4.13_PRODUCTION.csv', 'asset_class': 'Index'},
    {'name': 'EURUSD_5M', 'signals': 'TP_Integrated_Signals_EURUSD_05M_v4.13_PRODUCTION.csv',
     'trades': 'TP_Integrated_Trades_EURUSD_05M_v4.13_PRODUCTION.csv', 'asset_class': 'Forex'},
    {'name': 'USDJPY_5M', 'signals': 'TP_Integrated_Signals_USDJPY_05M_v4.13_PRODUCTION.csv',
     'trades': 'TP_Integrated_Trades_USDJPY__05M_v4.13_PRODUCTION.csv', 'asset_class': 'Forex'},
    {'name': 'AUDUSD_5M', 'signals': 'TP_Integrated_Signals_AUDUSD_05M_v4.13_PRODUCTION.csv',
     'trades': 'TP_Integrated_Trades_AUDUSD_05M_v4.13_PRODUCTION.csv', 'asset_class': 'Forex'},
]

BASE_DIR = Path('/Users/patjohnston/ai-trading-platform/MQL5/Backtest_Reports')
OUTPUT_DIR = Path('/Users/patjohnston/ai-trading-platform/analytics/multi_asset_output')
OUTPUT_DIR.mkdir(exist_ok=True)

print('='*80)
print('  🚀 MULTI-ASSET PHYSICS SCORE VALIDATION')
print('='*80)
print(f'\n📂 Analyzing {len(DATASETS)} datasets...\n')

# Storage for results
all_results = []
physics_metrics = ['Acceleration', 'Speed', 'Jerk', 'Momentum', 'Confluence', 'Quality']

for dataset in DATASETS:
    print(f"📊 Processing {dataset['name']}...")
    
    try:
        # Load data
        signals = pd.read_csv(BASE_DIR / dataset['signals'])
        trades = pd.read_csv(BASE_DIR / dataset['trades'])
        
        # Merge on timestamp
        merged = pd.merge(trades, signals, left_on='OpenTime', right_on='Timestamp', how='inner')
        
        if len(merged) == 0:
            print("   ⚠️  No merged trades - skipping")
            continue
        
        # Calculate IsWin
        merged['IsWin'] = (merged['Profit'] > 0).astype(int)
        
        # Correlations for each physics metric
        correlations = {}
        for metric in physics_metrics:
            if metric in merged.columns:
                profit_corr, profit_p = stats.pearsonr(merged[metric], merged['Profit'])
                win_corr, win_p = stats.pearsonr(merged[metric], merged['IsWin'])
                correlations[metric] = {
                    'profit_corr': profit_corr,
                    'profit_p': profit_p,
                    'win_corr': win_corr,
                    'win_p': win_p,
                    'significant': profit_p < 0.05 or win_p < 0.05
                }
        
        # Physics Score analysis
        ps_stats = {}
        if 'PhysicsScore' in merged.columns:
            ps_profit_corr, ps_profit_p = stats.pearsonr(merged['PhysicsScore'], merged['Profit'])
            ps_win_corr, ps_win_p = stats.pearsonr(merged['PhysicsScore'], merged['IsWin'])
            
            # Quartile analysis
            merged['PSQuartile'] = pd.qcut(merged['PhysicsScore'], q=4, labels=['Q1', 'Q2', 'Q3', 'Q4'])
            quartile_perf = merged.groupby('PSQuartile', observed=True).agg({
                'Profit': ['mean', 'sum'],
                'IsWin': 'mean',
                'Ticket': 'count'
            })
            
            ps_stats = {
                'profit_corr': ps_profit_corr,
                'profit_p': ps_profit_p,
                'win_corr': ps_win_corr,
                'win_p': ps_win_p,
                'mean': merged['PhysicsScore'].mean(),
                'median': merged['PhysicsScore'].median(),
                'q1_win_rate': quartile_perf.loc['Q1', ('IsWin', 'mean')],
                'q2_win_rate': quartile_perf.loc['Q2', ('IsWin', 'mean')],
                'q3_win_rate': quartile_perf.loc['Q3', ('IsWin', 'mean')],
                'q4_win_rate': quartile_perf.loc['Q4', ('IsWin', 'mean')],
                'q3_best': quartile_perf.loc['Q3', ('IsWin', 'mean')] == quartile_perf[('IsWin', 'mean')].max()
            }
        
        # Confluence analysis
        confluence_stats = {}
        if 'Confluence' in merged.columns:
            conf_groups = merged.groupby('Confluence', observed=True).agg({
                'Profit': ['mean', 'sum', 'count'],
                'IsWin': 'mean'
            })
            if 100.0 in conf_groups.index and 80.0 in conf_groups.index:
                confluence_stats = {
                    'conf_80_win_rate': conf_groups.loc[80.0, ('IsWin', 'mean')],
                    'conf_100_win_rate': conf_groups.loc[100.0, ('IsWin', 'mean')],
                    'conf_100_better': conf_groups.loc[100.0, ('IsWin', 'mean')] > conf_groups.loc[80.0, ('IsWin', 'mean')]
                }
        
        # Store results
        result = {
            'dataset': dataset['name'],
            'asset_class': dataset['asset_class'],
            'total_trades': len(merged),
            'win_rate': merged['IsWin'].mean(),
            'total_profit': merged['Profit'].sum(),
            'correlations': correlations,
            'physics_score': ps_stats,
            'confluence': confluence_stats
        }
        all_results.append(result)
        
        print(f"   ✅ {len(merged)} trades | Win Rate: {result['win_rate']:.1%} | P&L: ${result['total_profit']:.2f}")
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        continue

print(f'\n✅ Processed {len(all_results)}/{len(DATASETS)} datasets successfully\n')

# === CROSS-DATASET ANALYSIS ===
print('='*80)
print('  📈 CROSS-DATASET CORRELATION ANALYSIS')
print('='*80 + '\n')

# Find metrics that consistently correlate across datasets
metric_consistency = {}
for metric in physics_metrics:
    appearances = []
    profit_corrs = []
    win_corrs = []
    
    for result in all_results:
        if metric in result['correlations']:
            corr_data = result['correlations'][metric]
            if corr_data['significant']:
                appearances.append(result['dataset'])
                profit_corrs.append(corr_data['profit_corr'])
                win_corrs.append(corr_data['win_corr'])
    
    if len(appearances) > 0:
        metric_consistency[metric] = {
            'datasets': len(appearances),
            'coverage': len(appearances) / len(all_results),
            'avg_profit_corr': np.mean(profit_corrs),
            'avg_win_corr': np.mean(win_corrs),
            'appears_in': appearances
        }

# Sort by coverage (how many datasets show this correlation)
sorted_metrics = sorted(metric_consistency.items(), key=lambda x: x[1]['coverage'], reverse=True)

print('🏆 MOST CONSISTENT PREDICTORS (across all assets):')
print('-'*80)
for i, (metric, metric_stats) in enumerate(sorted_metrics[:5], 1):
    print(f'{i}. {metric:15s} | Coverage: {metric_stats["coverage"]:.0%} ({metric_stats["datasets"]}/{len(all_results)}) | '
          f'Avg Profit Corr: {metric_stats["avg_profit_corr"]:+.3f} | Avg Win Corr: {metric_stats["avg_win_corr"]:+.3f}')

# === ASSET CLASS COMPARISON ===
print('\n' + '='*80)
print('  🏭 INDICES vs 💱 FOREX COMPARISON')
print('='*80 + '\n')

indices = [r for r in all_results if r['asset_class'] == 'Index']
forex = [r for r in all_results if r['asset_class'] == 'Forex']

print(f'📊 Indices ({len(indices)} datasets):')
if indices:
    idx_trades = sum(r['total_trades'] for r in indices)
    idx_win_rate = np.mean([r['win_rate'] for r in indices])
    print(f'   Total Trades: {idx_trades}')
    print(f'   Avg Win Rate: {idx_win_rate:.1%}')

print(f'\n💱 Forex ({len(forex)} datasets):')
if forex:
    fx_trades = sum(r['total_trades'] for r in forex)
    fx_win_rate = np.mean([r['win_rate'] for r in forex])
    print(f'   Total Trades: {fx_trades}')
    print(f'   Avg Win Rate: {fx_win_rate:.1%}')

# === PHYSICS SCORE VALIDATION ===
print('\n' + '='*80)
print('  🎯 PHYSICS SCORE VALIDATION')
print('='*80 + '\n')

ps_results = [r for r in all_results if r['physics_score']]
if ps_results:
    print(f'📊 Physics Score Analysis ({len(ps_results)} datasets with PhysicsScore):')
    print('-'*80)
    
    avg_win_corr = np.mean([r['physics_score']['win_corr'] for r in ps_results])
    significant_count = sum(1 for r in ps_results if r['physics_score']['win_p'] < 0.05)
    q3_best_count = sum(1 for r in ps_results if r['physics_score'].get('q3_best', False))
    
    print(f'Average Win Rate Correlation:    {avg_win_corr:+.3f}')
    print(f'Statistically Significant:       {significant_count}/{len(ps_results)} datasets')
    print(f'Q3 (55-85 range) is best:        {q3_best_count}/{len(ps_results)} datasets')
    
    print('\n📈 Win Rate by Physics Score Quartile:')
    print('-'*80)
    for q in ['q1', 'q2', 'q3', 'q4']:
        wr_key = f'{q}_win_rate'
        if all(wr_key in r['physics_score'] for r in ps_results):
            avg_wr = np.mean([r['physics_score'][wr_key] for r in ps_results])
            print(f'   {q.upper():3s}: {avg_wr:.1%}')

# === CONFLUENCE VALIDATION ===
print('\n' + '='*80)
print('  🔗 CONFLUENCE 100% vs 80% VALIDATION')
print('='*80 + '\n')

conf_results = [r for r in all_results if r['confluence']]
if conf_results:
    conf_100_better_count = sum(1 for r in conf_results if r['confluence'].get('conf_100_better', False))
    avg_80_wr = np.mean([r['confluence']['conf_80_win_rate'] for r in conf_results])
    avg_100_wr = np.mean([r['confluence']['conf_100_win_rate'] for r in conf_results])
    
    print(f'Datasets showing Confluence 100% > 80%:  {conf_100_better_count}/{len(conf_results)}')
    print(f'Average Win Rate @ 80% Confluence:      {avg_80_wr:.1%}')
    print(f'Average Win Rate @ 100% Confluence:     {avg_100_wr:.1%}')
    print(f'Improvement:                             {(avg_100_wr - avg_80_wr):.1%}')

# === SAVE RESULTS ===
with open(OUTPUT_DIR / 'multi_asset_results.json', 'w') as f:
    json.dump(all_results, f, indent=2, default=str)

with open(OUTPUT_DIR / 'metric_consistency.json', 'w') as f:
    json.dump(metric_consistency, f, indent=2)

print('\n' + '='*80)
print('  ✅ ANALYSIS COMPLETE')
print('='*80)
print(f'\n📁 Results saved to: {OUTPUT_DIR}')
print('\n🎯 KEY FINDINGS:')
print(f'   • Total Datasets: {len(all_results)}')
print(f'   • Total Trades: {sum(r["total_trades"] for r in all_results)}')
print(f'   • Most Consistent Predictor: {sorted_metrics[0][0]} ({sorted_metrics[0][1]["coverage"]:.0%} coverage)')
print(f'   • Physics Score Win Correlation: {avg_win_corr:+.3f} (avg)')
if conf_results:
    print(f'   • Confluence 100% Win Rate Boost: +{(avg_100_wr - avg_80_wr):.1%}')

print('\n' + '='*80 + '\n')
