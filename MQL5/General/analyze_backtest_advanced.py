#!/usr/bin/env python3
"""
Advanced TickPhysics Backtest Analytics
========================================
Analyzes CSV trade logs to identify physics metrics that correlate with winning trades.
Builds probability tables, threshold optimization, and JSON outputs for self-learning EA.

Usage:
    python analyze_backtest_advanced.py <csv_file> [--output-dir reports]
    
Output:
    - Statistical summary (winners vs losers)
    - Correlation matrices (metrics vs profit)
    - Threshold optimization tables (best cutoffs per metric)
    - Win probability by metric ranges
    - Multi-metric combination analysis
    - JSON configuration for self-learning EA
    - Interactive dashboard HTML
"""

import pandas as pd
import numpy as np
import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Any
import warnings
warnings.filterwarnings('ignore')

# Try to import visualization libraries (optional)
try:
    import matplotlib.pyplot as plt
    import seaborn as sns
    HAS_PLOTTING = True
except ImportError:
    HAS_PLOTTING = False
    print("⚠️  matplotlib/seaborn not found. Install for visualizations: pip install matplotlib seaborn")

try:
    from scipy import stats
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False
    print("⚠️  scipy not found. Install for advanced stats: pip install scipy")


class TradeAnalytics:
    """Advanced analytics for TickPhysics trade data"""
    
    def __init__(self, csv_path: str, output_dir: str = "reports"):
        self.csv_path = Path(csv_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # Load and prepare data
        self.df = None
        self.winners = None
        self.losers = None
        self.breakeven = None
        
        # Physics metrics to analyze
        self.physics_metrics = [
            'EntryAccel', 'EntryVelocity', 'EntryMomentum',
            'EntryVolatility', 'EntryTrend', 'EntryForce',
            'AvgAccel', 'AvgVelocity', 'AvgMomentum',
            'MaxAccel', 'MaxVelocity', 'MinAccel', 'MinVelocity',
            'MFE', 'MAE', 'RunUp', 'RunDown'
        ]
        
        # Results storage
        self.results = {
            'summary': {},
            'correlations': {},
            'thresholds': {},
            'probabilities': {},
            'combinations': {},
            'recommendations': {}
        }
        
    def load_data(self) -> bool:
        """Load CSV and prepare dataframe"""
        print(f"\n{'='*80}")
        print(f"🔍 TICKPHYSICS ADVANCED ANALYTICS")
        print(f"{'='*80}")
        print(f"📁 Loading: {self.csv_path}")
        
        try:
            self.df = pd.read_csv(self.csv_path)
            print(f"✅ Loaded {len(self.df)} trades")
            
            # Add derived columns
            self.df['IsWinner'] = self.df['NetProfit'] > 0
            self.df['IsLoser'] = self.df['NetProfit'] < 0
            self.df['IsBreakeven'] = self.df['NetProfit'] == 0
            self.df['ProfitPips'] = self.df['NetProfit'] / 10.0  # Assuming 1 pip = $10
            self.df['RMultiple'] = self.df['NetProfit'] / abs(self.df['MaxDrawdown'])
            
            # Separate winners/losers
            self.winners = self.df[self.df['IsWinner']]
            self.losers = self.df[self.df['IsLoser']]
            self.breakeven = self.df[self.df['IsBreakeven']]
            
            print(f"  ✅ Winners: {len(self.winners)} ({len(self.winners)/len(self.df)*100:.1f}%)")
            print(f"  ❌ Losers: {len(self.losers)} ({len(self.losers)/len(self.df)*100:.1f}%)")
            print(f"  ⚖️  Breakeven: {len(self.breakeven)} ({len(self.breakeven)/len(self.df)*100:.1f}%)")
            
            return True
            
        except Exception as e:
            print(f"❌ Error loading CSV: {e}")
            return False
    
    def basic_statistics(self):
        """Calculate basic performance statistics"""
        print(f"\n{'='*80}")
        print(f"📊 BASIC STATISTICS")
        print(f"{'='*80}")
        
        stats = {
            'total_trades': len(self.df),
            'winners': len(self.winners),
            'losers': len(self.losers),
            'breakeven': len(self.breakeven),
            'win_rate': len(self.winners) / len(self.df) * 100,
            'total_profit': self.df['NetProfit'].sum(),
            'avg_win': self.winners['NetProfit'].mean() if len(self.winners) > 0 else 0,
            'avg_loss': self.losers['NetProfit'].mean() if len(self.losers) > 0 else 0,
            'largest_win': self.df['NetProfit'].max(),
            'largest_loss': self.df['NetProfit'].min(),
            'profit_factor': abs(self.winners['NetProfit'].sum() / self.losers['NetProfit'].sum()) if len(self.losers) > 0 else 0,
            'avg_mfe': self.df['MFE'].mean(),
            'avg_mae': self.df['MAE'].mean(),
            'avg_runup': self.winners['RunUp'].mean() if len(self.winners) > 0 else 0,
            'avg_rundown': self.losers['RunDown'].mean() if len(self.losers) > 0 else 0,
        }
        
        self.results['summary'] = stats
        
        print(f"Total Trades: {stats['total_trades']}")
        print(f"Win Rate: {stats['win_rate']:.2f}%")
        print(f"Total Profit: ${stats['total_profit']:.2f}")
        print(f"Profit Factor: {stats['profit_factor']:.2f}")
        print(f"\nAverage Win: ${stats['avg_win']:.2f}")
        print(f"Average Loss: ${stats['avg_loss']:.2f}")
        print(f"Expectancy: ${(stats['avg_win'] * stats['win_rate']/100 + stats['avg_loss'] * (100-stats['win_rate'])/100):.2f}")
        print(f"\nMFE/MAE Ratio: {stats['avg_mfe']/abs(stats['avg_mae']) if stats['avg_mae'] != 0 else 0:.2f}")
        
    def correlation_analysis(self):
        """Analyze correlation between physics metrics and profit"""
        print(f"\n{'='*80}")
        print(f"🔗 CORRELATION ANALYSIS (Metrics vs Profit)")
        print(f"{'='*80}")
        
        correlations = {}
        
        for metric in self.physics_metrics:
            if metric in self.df.columns:
                # Pearson correlation with profit
                corr = self.df[metric].corr(self.df['NetProfit'])
                
                # Point-biserial correlation with win/loss
                win_loss_corr = self.df[metric].corr(self.df['IsWinner'].astype(int))
                
                # Statistical significance test
                if HAS_SCIPY:
                    _, p_value = stats.pearsonr(self.df[metric].dropna(), 
                                               self.df.loc[self.df[metric].notna(), 'NetProfit'])
                    significant = p_value < 0.05
                else:
                    p_value = None
                    significant = abs(corr) > 0.2  # Simple threshold
                
                correlations[metric] = {
                    'profit_corr': corr,
                    'win_corr': win_loss_corr,
                    'p_value': p_value,
                    'significant': significant,
                    'strength': 'Strong' if abs(corr) > 0.5 else 'Moderate' if abs(corr) > 0.3 else 'Weak'
                }
                
                # Print if significant
                if significant:
                    direction = "📈 Positive" if corr > 0 else "📉 Negative"
                    print(f"{metric:20s} {direction:15s} r={corr:6.3f}  {correlations[metric]['strength']:10s}")
        
        self.results['correlations'] = correlations
        
        # Identify top correlated metrics
        sorted_corr = sorted(correlations.items(), 
                           key=lambda x: abs(x[1]['profit_corr']), 
                           reverse=True)
        
        print(f"\n🏆 TOP 5 PREDICTIVE METRICS:")
        for metric, data in sorted_corr[:5]:
            print(f"  {metric}: r={data['profit_corr']:.3f} ({data['strength']})")
        
        return correlations
    
    def threshold_optimization(self, metric: str, percentiles: List[int] = None) -> Dict:
        """Find optimal threshold for a single metric"""
        if percentiles is None:
            percentiles = [10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90]
        
        if metric not in self.df.columns:
            return {}
        
        results = []
        values = self.df[metric].dropna()
        
        for pct in percentiles:
            threshold = np.percentile(values, pct)
            
            # Test both directions (above and below threshold)
            for direction, operator in [('above', '>'), ('below', '<')]:
                if direction == 'above':
                    filtered = self.df[self.df[metric] > threshold]
                else:
                    filtered = self.df[self.df[metric] < threshold]
                
                if len(filtered) > 0:
                    win_rate = (filtered['NetProfit'] > 0).sum() / len(filtered) * 100
                    avg_profit = filtered['NetProfit'].mean()
                    total_profit = filtered['NetProfit'].sum()
                    count = len(filtered)
                    
                    results.append({
                        'percentile': pct,
                        'threshold': threshold,
                        'direction': direction,
                        'operator': operator,
                        'count': count,
                        'win_rate': win_rate,
                        'avg_profit': avg_profit,
                        'total_profit': total_profit,
                        'expectancy': avg_profit,
                    })
        
        # Find best threshold by win rate and expectancy
        if results:
            df_results = pd.DataFrame(results)
            best_by_winrate = df_results.loc[df_results['win_rate'].idxmax()]
            best_by_expectancy = df_results.loc[df_results['expectancy'].idxmax()]
            
            return {
                'all_thresholds': results,
                'best_by_winrate': best_by_winrate.to_dict(),
                'best_by_expectancy': best_by_expectancy.to_dict(),
            }
        
        return {}
    
    def optimize_all_thresholds(self):
        """Optimize thresholds for all significant metrics"""
        print(f"\n{'='*80}")
        print(f"🎯 THRESHOLD OPTIMIZATION")
        print(f"{'='*80}")
        
        # Only optimize metrics with significant correlation
        significant_metrics = [m for m, data in self.results['correlations'].items() 
                             if data['significant']]
        
        print(f"Optimizing {len(significant_metrics)} significant metrics...\n")
        
        optimized = {}
        
        for metric in significant_metrics:
            opt = self.threshold_optimization(metric)
            if opt:
                optimized[metric] = opt
                best = opt['best_by_winrate']
                baseline_wr = len(self.winners) / len(self.df) * 100
                improvement = best['win_rate'] - baseline_wr
                
                print(f"{metric:20s} {best['operator']} {best['threshold']:8.4f}")
                print(f"  Win Rate: {best['win_rate']:5.1f}% ({improvement:+.1f}% vs baseline)")
                print(f"  Trades: {int(best['count']):4d}  Expectancy: ${best['expectancy']:.2f}")
                print()
        
        self.results['thresholds'] = optimized
        return optimized
    
    def probability_tables(self, metric: str, bins: int = 5) -> pd.DataFrame:
        """Create win probability table by metric ranges"""
        if metric not in self.df.columns:
            return pd.DataFrame()
        
        # Create bins
        df_clean = self.df[[metric, 'NetProfit']].dropna()
        df_clean['Range'] = pd.qcut(df_clean[metric], q=bins, duplicates='drop')
        
        # Calculate stats per range
        prob_table = df_clean.groupby('Range').agg({
            'NetProfit': ['count', 'mean', 'sum', lambda x: (x > 0).sum()]
        }).round(2)
        
        prob_table.columns = ['Count', 'AvgProfit', 'TotalProfit', 'Winners']
        prob_table['WinRate%'] = (prob_table['Winners'] / prob_table['Count'] * 100).round(1)
        prob_table['Expectancy'] = prob_table['AvgProfit']
        
        return prob_table
    
    def build_all_probability_tables(self):
        """Build probability tables for all significant metrics"""
        print(f"\n{'='*80}")
        print(f"📊 WIN PROBABILITY TABLES")
        print(f"{'='*80}")
        
        significant_metrics = [m for m, data in self.results['correlations'].items() 
                             if data['significant']][:5]  # Top 5
        
        prob_tables = {}
        
        for metric in significant_metrics:
            table = self.probability_tables(metric)
            if not table.empty:
                prob_tables[metric] = table
                print(f"\n{metric}:")
                print(table.to_string())
        
        self.results['probabilities'] = prob_tables
        return prob_tables
    
    def multi_metric_combinations(self, top_n: int = 3):
        """Test combinations of multiple metrics"""
        print(f"\n{'='*80}")
        print(f"🔬 MULTI-METRIC COMBINATION ANALYSIS")
        print(f"{'='*80}")
        
        # Get top N metrics by correlation
        top_metrics = sorted(self.results['correlations'].items(), 
                           key=lambda x: abs(x[1]['profit_corr']), 
                           reverse=True)[:top_n]
        
        top_metrics = [m[0] for m in top_metrics if m[1]['significant']]
        
        if len(top_metrics) < 2:
            print("Not enough significant metrics for combination analysis")
            return {}
        
        print(f"Testing combinations of: {', '.join(top_metrics)}\n")
        
        combinations = []
        
        # Test each metric individually
        for metric in top_metrics:
            if metric in self.results['thresholds']:
                best = self.results['thresholds'][metric]['best_by_winrate']
                
                if best['direction'] == 'above':
                    filtered = self.df[self.df[metric] > best['threshold']]
                else:
                    filtered = self.df[self.df[metric] < best['threshold']]
                
                if len(filtered) > 0:
                    combinations.append({
                        'metrics': [metric],
                        'conditions': f"{metric} {best['operator']} {best['threshold']:.4f}",
                        'count': len(filtered),
                        'win_rate': (filtered['NetProfit'] > 0).sum() / len(filtered) * 100,
                        'total_profit': filtered['NetProfit'].sum(),
                        'avg_profit': filtered['NetProfit'].mean(),
                    })
        
        # Test pairwise combinations
        for i, metric1 in enumerate(top_metrics):
            for metric2 in top_metrics[i+1:]:
                if metric1 in self.results['thresholds'] and metric2 in self.results['thresholds']:
                    best1 = self.results['thresholds'][metric1]['best_by_winrate']
                    best2 = self.results['thresholds'][metric2]['best_by_winrate']
                    
                    # Apply both filters
                    filtered = self.df.copy()
                    if best1['direction'] == 'above':
                        filtered = filtered[filtered[metric1] > best1['threshold']]
                    else:
                        filtered = filtered[filtered[metric1] < best1['threshold']]
                    
                    if best2['direction'] == 'above':
                        filtered = filtered[filtered[metric2] > best2['threshold']]
                    else:
                        filtered = filtered[filtered[metric2] < best2['threshold']]
                    
                    if len(filtered) > 0:
                        combinations.append({
                            'metrics': [metric1, metric2],
                            'conditions': f"{metric1} {best1['operator']} {best1['threshold']:.4f} AND {metric2} {best2['operator']} {best2['threshold']:.4f}",
                            'count': len(filtered),
                            'win_rate': (filtered['NetProfit'] > 0).sum() / len(filtered) * 100,
                            'total_profit': filtered['NetProfit'].sum(),
                            'avg_profit': filtered['NetProfit'].mean(),
                        })
        
        # Sort by win rate
        combinations.sort(key=lambda x: x['win_rate'], reverse=True)
        
        # Print top combinations
        baseline_wr = len(self.winners) / len(self.df) * 100
        print(f"Baseline Win Rate: {baseline_wr:.1f}%\n")
        
        for i, combo in enumerate(combinations[:10], 1):
            improvement = combo['win_rate'] - baseline_wr
            print(f"{i}. {combo['conditions']}")
            print(f"   Trades: {combo['count']:4d}  Win Rate: {combo['win_rate']:5.1f}% ({improvement:+.1f}%)")
            print(f"   Total: ${combo['total_profit']:.2f}  Avg: ${combo['avg_profit']:.2f}\n")
        
        self.results['combinations'] = combinations
        return combinations
    
    def generate_json_config(self) -> Dict:
        """Generate JSON configuration for self-learning EA"""
        print(f"\n{'='*80}")
        print(f"📝 GENERATING JSON CONFIGURATION FOR SELF-LEARNING EA")
        print(f"{'='*80}")
        
        # Get best combination
        best_combo = None
        if self.results['combinations']:
            best_combo = self.results['combinations'][0]
        
        # Build recommended filters
        recommended_filters = []
        
        for metric, opt_data in self.results['thresholds'].items():
            best = opt_data['best_by_winrate']
            baseline_wr = len(self.winners) / len(self.df) * 100
            
            # Only recommend if significant improvement
            if best['win_rate'] - baseline_wr > 5.0 and best['count'] > 10:
                recommended_filters.append({
                    'metric': metric,
                    'operator': best['operator'],
                    'threshold': float(best['threshold']),
                    'expected_win_rate': float(best['win_rate']),
                    'expected_expectancy': float(best['expectancy']),
                    'improvement_vs_baseline': float(best['win_rate'] - baseline_wr),
                })
        
        config = {
            'generated_at': datetime.now().isoformat(),
            'source_file': str(self.csv_path),
            'baseline_performance': {
                'total_trades': int(self.results['summary']['total_trades']),
                'win_rate': float(self.results['summary']['win_rate']),
                'profit_factor': float(self.results['summary']['profit_factor']),
                'total_profit': float(self.results['summary']['total_profit']),
            },
            'recommended_filters': recommended_filters,
            'best_combination': best_combo if best_combo else {},
            'top_correlations': {
                metric: {
                    'correlation': float(data['profit_corr']),
                    'strength': data['strength']
                }
                for metric, data in sorted(self.results['correlations'].items(), 
                                          key=lambda x: abs(x[1]['profit_corr']), 
                                          reverse=True)[:5]
            },
        }
        
        # Save to file
        json_path = self.output_dir / 'ea_config_optimized.json'
        with open(json_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ JSON config saved: {json_path}")
        print(f"\n📋 RECOMMENDED FILTERS ({len(recommended_filters)}):")
        for f in recommended_filters:
            print(f"  {f['metric']} {f['operator']} {f['threshold']:.4f} → {f['expected_win_rate']:.1f}% win rate")
        
        self.results['recommendations'] = config
        return config
    
    def generate_visualizations(self):
        """Generate visual charts and plots"""
        if not HAS_PLOTTING:
            print("\n⚠️  Skipping visualizations (matplotlib not installed)")
            return
        
        print(f"\n{'='*80}")
        print(f"📈 GENERATING VISUALIZATIONS")
        print(f"{'='*80}")
        
        fig_dir = self.output_dir / 'figures'
        fig_dir.mkdir(exist_ok=True)
        
        # 1. Profit distribution
        plt.figure(figsize=(12, 6))
        plt.subplot(1, 2, 1)
        self.winners['NetProfit'].hist(bins=30, alpha=0.7, color='green', label='Winners')
        plt.xlabel('Profit ($)')
        plt.ylabel('Frequency')
        plt.title('Winner Distribution')
        plt.legend()
        
        plt.subplot(1, 2, 2)
        self.losers['NetProfit'].hist(bins=30, alpha=0.7, color='red', label='Losers')
        plt.xlabel('Profit ($)')
        plt.ylabel('Frequency')
        plt.title('Loser Distribution')
        plt.legend()
        plt.tight_layout()
        plt.savefig(fig_dir / 'profit_distribution.png', dpi=150)
        print(f"  ✅ profit_distribution.png")
        plt.close()
        
        # 2. Correlation heatmap
        significant_metrics = [m for m, d in self.results['correlations'].items() if d['significant']]
        if len(significant_metrics) > 1:
            corr_matrix = self.df[significant_metrics + ['NetProfit']].corr()
            
            plt.figure(figsize=(10, 8))
            sns.heatmap(corr_matrix, annot=True, fmt='.2f', cmap='coolwarm', center=0)
            plt.title('Correlation Matrix: Significant Metrics vs Profit')
            plt.tight_layout()
            plt.savefig(fig_dir / 'correlation_heatmap.png', dpi=150)
            print(f"  ✅ correlation_heatmap.png")
            plt.close()
        
        # 3. Top metrics comparison (winners vs losers)
        top_3_metrics = [m for m, d in sorted(self.results['correlations'].items(), 
                                             key=lambda x: abs(x[1]['profit_corr']), 
                                             reverse=True) if d['significant']][:3]
        
        if top_3_metrics:
            fig, axes = plt.subplots(1, len(top_3_metrics), figsize=(15, 5))
            if len(top_3_metrics) == 1:
                axes = [axes]
            
            for ax, metric in zip(axes, top_3_metrics):
                winner_vals = self.winners[metric].dropna()
                loser_vals = self.losers[metric].dropna()
                
                ax.hist([winner_vals, loser_vals], bins=20, alpha=0.6, 
                       color=['green', 'red'], label=['Winners', 'Losers'])
                ax.set_xlabel(metric)
                ax.set_ylabel('Frequency')
                ax.set_title(f'{metric}\n(r={self.results["correlations"][metric]["profit_corr"]:.3f})')
                ax.legend()
            
            plt.tight_layout()
            plt.savefig(fig_dir / 'top_metrics_comparison.png', dpi=150)
            print(f"  ✅ top_metrics_comparison.png")
            plt.close()
        
        print(f"✅ Visualizations saved to: {fig_dir}")
    
    def generate_html_report(self):
        """Generate interactive HTML dashboard"""
        print(f"\n{'='*80}")
        print(f"🌐 GENERATING HTML REPORT")
        print(f"{'='*80}")
        
        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <title>TickPhysics Analytics Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }}
        h2 {{ color: #34495e; margin-top: 30px; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
        th {{ background-color: #3498db; color: white; }}
        tr:hover {{ background-color: #f5f5f5; }}
        .metric-good {{ color: #27ae60; font-weight: bold; }}
        .metric-bad {{ color: #e74c3c; font-weight: bold; }}
        .metric-neutral {{ color: #95a5a6; }}
        .summary-box {{ background: #ecf0f1; padding: 15px; margin: 10px 0; border-radius: 5px; }}
        .recommendation {{ background: #d5f4e6; padding: 15px; margin: 10px 0; border-left: 4px solid #27ae60; }}
        code {{ background: #f4f4f4; padding: 2px 6px; border-radius: 3px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 TickPhysics Advanced Analytics Report</h1>
        <p><strong>Generated:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p><strong>Source:</strong> {self.csv_path.name}</p>
        
        <h2>📊 Performance Summary</h2>
        <div class="summary-box">
            <table>
                <tr><th>Metric</th><th>Value</th></tr>
                <tr><td>Total Trades</td><td>{self.results['summary']['total_trades']}</td></tr>
                <tr><td>Win Rate</td><td class="metric-{'good' if self.results['summary']['win_rate'] > 50 else 'bad'}">{self.results['summary']['win_rate']:.2f}%</td></tr>
                <tr><td>Profit Factor</td><td class="metric-{'good' if self.results['summary']['profit_factor'] > 1.5 else 'bad'}">{self.results['summary']['profit_factor']:.2f}</td></tr>
                <tr><td>Total Profit</td><td class="metric-{'good' if self.results['summary']['total_profit'] > 0 else 'bad'}">${self.results['summary']['total_profit']:.2f}</td></tr>
                <tr><td>Average Win</td><td class="metric-good">${self.results['summary']['avg_win']:.2f}</td></tr>
                <tr><td>Average Loss</td><td class="metric-bad">${self.results['summary']['avg_loss']:.2f}</td></tr>
            </table>
        </div>
        
        <h2>🔗 Top Correlated Metrics</h2>
        <table>
            <tr><th>Metric</th><th>Correlation</th><th>Strength</th><th>Significant</th></tr>
"""
        
        # Add correlation table
        for metric, data in sorted(self.results['correlations'].items(), 
                                  key=lambda x: abs(x[1]['profit_corr']), 
                                  reverse=True)[:10]:
            sig_icon = "✅" if data['significant'] else "❌"
            corr_class = "metric-good" if data['profit_corr'] > 0 else "metric-bad"
            html_content += f"""
            <tr>
                <td><code>{metric}</code></td>
                <td class="{corr_class}">{data['profit_corr']:.3f}</td>
                <td>{data['strength']}</td>
                <td>{sig_icon}</td>
            </tr>
"""
        
        html_content += """
        </table>
        
        <h2>🎯 Recommended Filters</h2>
"""
        
        # Add recommendations
        if self.results.get('recommendations', {}).get('recommended_filters'):
            for filt in self.results['recommendations']['recommended_filters']:
                html_content += f"""
        <div class="recommendation">
            <strong>{filt['metric']}</strong> {filt['operator']} <code>{filt['threshold']:.4f}</code><br>
            Expected Win Rate: <span class="metric-good">{filt['expected_win_rate']:.1f}%</span> 
            (improvement: +{filt['improvement_vs_baseline']:.1f}%)<br>
            Expected Expectancy: ${filt['expected_expectancy']:.2f}
        </div>
"""
        
        html_content += """
        <h2>🔬 Best Multi-Metric Combinations</h2>
        <table>
            <tr><th>#</th><th>Conditions</th><th>Trades</th><th>Win Rate</th><th>Total Profit</th></tr>
"""
        
        # Add combinations
        for i, combo in enumerate(self.results.get('combinations', [])[:5], 1):
            html_content += f"""
            <tr>
                <td>{i}</td>
                <td><code>{combo['conditions']}</code></td>
                <td>{combo['count']}</td>
                <td class="metric-good">{combo['win_rate']:.1f}%</td>
                <td>${combo['total_profit']:.2f}</td>
            </tr>
"""
        
        html_content += """
        </table>
        
        <h2>📁 Output Files</h2>
        <ul>
            <li><code>ea_config_optimized.json</code> - JSON configuration for self-learning EA</li>
            <li><code>figures/</code> - Visual charts and plots</li>
        </ul>
        
        <p style="margin-top: 40px; color: #7f8c8d; text-align: center;">
            Generated by TickPhysics Advanced Analytics v1.0
        </p>
    </div>
</body>
</html>
"""
        
        html_path = self.output_dir / 'analytics_report.html'
        with open(html_path, 'w') as f:
            f.write(html_content)
        
        print(f"✅ HTML report saved: {html_path}")
        return html_path
    
    def run_full_analysis(self):
        """Run complete analysis pipeline"""
        if not self.load_data():
            return False
        
        # Run all analyses
        self.basic_statistics()
        self.correlation_analysis()
        self.optimize_all_thresholds()
        self.build_all_probability_tables()
        self.multi_metric_combinations()
        self.generate_json_config()
        self.generate_visualizations()
        html_path = self.generate_html_report()
        
        print(f"\n{'='*80}")
        print(f"✅ ANALYSIS COMPLETE!")
        print(f"{'='*80}")
        print(f"\n📂 All outputs saved to: {self.output_dir}")
        print(f"🌐 Open report: {html_path}")
        print(f"📝 JSON config: {self.output_dir / 'ea_config_optimized.json'}")
        
        return True


def main():
    parser = argparse.ArgumentParser(description='Advanced TickPhysics Backtest Analytics')
    parser.add_argument('csv_file', help='Path to CSV trade log file')
    parser.add_argument('--output-dir', default='reports', help='Output directory for reports')
    
    args = parser.parse_args()
    
    analytics = TradeAnalytics(args.csv_file, args.output_dir)
    success = analytics.run_full_analysis()
    
    return 0 if success else 1


if __name__ == '__main__':
    exit(main())
