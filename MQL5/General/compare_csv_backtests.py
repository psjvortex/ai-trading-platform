#!/usr/bin/env python3
"""
Detailed CSV Backtest Comparison
=================================
Compares baseline vs optimized backtests side-by-side using raw CSV files.
Shows improvements, degradations, and statistical significance.

Usage:
    python compare_csv_backtests.py <baseline_csv> <optimized_csv> [--output comparison_report.html]
    
Example:
    python compare_csv_backtests.py data/baseline.csv data/filtered_run1.csv
"""

import pandas as pd
import numpy as np
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, Tuple

try:
    import matplotlib.pyplot as plt
    import seaborn as sns
    HAS_PLOTTING = True
except ImportError:
    HAS_PLOTTING = False

try:
    from scipy import stats
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False


class CSVBacktestComparison:
    """Compare two backtest CSV files in detail"""
    
    def __init__(self, baseline_path: str, optimized_path: str):
        self.baseline_path = Path(baseline_path)
        self.optimized_path = Path(optimized_path)
        
        self.baseline_df = None
        self.optimized_df = None
        
        self.baseline_stats = {}
        self.optimized_stats = {}
        self.comparison = {}
    
    def load_data(self) -> bool:
        """Load both CSV files"""
        print(f"\n{'='*80}")
        print(f"📊 CSV BACKTEST COMPARISON")
        print(f"{'='*80}")
        
        try:
            self.baseline_df = pd.read_csv(self.baseline_path)
            self.optimized_df = pd.read_csv(self.optimized_path)
            
            print(f"✅ Baseline:  {len(self.baseline_df)} trades from {self.baseline_path.name}")
            print(f"✅ Optimized: {len(self.optimized_df)} trades from {self.optimized_path.name}")
            
            return True
        except Exception as e:
            print(f"❌ Error loading files: {e}")
            return False
    
    def calculate_stats(self, df: pd.DataFrame) -> Dict:
        """Calculate comprehensive statistics for a dataframe"""
        winners = df[df['NetProfit'] > 0]
        losers = df[df['NetProfit'] < 0]
        
        stats = {
            'total_trades': len(df),
            'winners': len(winners),
            'losers': len(losers),
            'win_rate': len(winners) / len(df) * 100 if len(df) > 0 else 0,
            'total_profit': df['NetProfit'].sum(),
            'avg_profit': df['NetProfit'].mean(),
            'median_profit': df['NetProfit'].median(),
            'avg_win': winners['NetProfit'].mean() if len(winners) > 0 else 0,
            'avg_loss': losers['NetProfit'].mean() if len(losers) > 0 else 0,
            'largest_win': df['NetProfit'].max(),
            'largest_loss': df['NetProfit'].min(),
            'profit_factor': abs(winners['NetProfit'].sum() / losers['NetProfit'].sum()) if len(losers) > 0 and losers['NetProfit'].sum() != 0 else 0,
            'expectancy': df['NetProfit'].mean(),
            'sharpe_ratio': df['NetProfit'].mean() / df['NetProfit'].std() if df['NetProfit'].std() != 0 else 0,
            'max_consecutive_wins': self._max_consecutive(df['NetProfit'] > 0),
            'max_consecutive_losses': self._max_consecutive(df['NetProfit'] < 0),
            'avg_mfe': df['MFE'].mean() if 'MFE' in df.columns else 0,
            'avg_mae': df['MAE'].mean() if 'MAE' in df.columns else 0,
            'avg_runup': winners['RunUp'].mean() if 'RunUp' in df.columns and len(winners) > 0 else 0,
            'avg_rundown': losers['RunDown'].mean() if 'RunDown' in df.columns and len(losers) > 0 else 0,
            'avg_hold_time': (pd.to_datetime(df['ExitTime']) - pd.to_datetime(df['EntryTime'])).mean().total_seconds() / 60 if 'ExitTime' in df.columns else 0,
        }
        
        return stats
    
    def _max_consecutive(self, series):
        """Calculate maximum consecutive True values"""
        max_count = 0
        current_count = 0
        for val in series:
            if val:
                current_count += 1
                max_count = max(max_count, current_count)
            else:
                current_count = 0
        return max_count
    
    def compare(self):
        """Compare baseline vs optimized"""
        print(f"\n{'='*80}")
        print(f"📈 PERFORMANCE COMPARISON")
        print(f"{'='*80}")
        
        self.baseline_stats = self.calculate_stats(self.baseline_df)
        self.optimized_stats = self.calculate_stats(self.optimized_df)
        
        # Calculate improvements
        metrics = [
            ('Total Trades', 'total_trades', 'absolute'),
            ('Win Rate (%)', 'win_rate', 'percentage'),
            ('Total Profit ($)', 'total_profit', 'currency'),
            ('Profit Factor', 'profit_factor', 'ratio'),
            ('Expectancy ($)', 'expectancy', 'currency'),
            ('Avg Win ($)', 'avg_win', 'currency'),
            ('Avg Loss ($)', 'avg_loss', 'currency'),
            ('Sharpe Ratio', 'sharpe_ratio', 'ratio'),
            ('Largest Win ($)', 'largest_win', 'currency'),
            ('Largest Loss ($)', 'largest_loss', 'currency'),
            ('Max Consecutive Wins', 'max_consecutive_wins', 'absolute'),
            ('Max Consecutive Losses', 'max_consecutive_losses', 'absolute'),
            ('Avg Hold Time (min)', 'avg_hold_time', 'time'),
        ]
        
        print(f"\n{'Metric':<25} {'Baseline':<15} {'Optimized':<15} {'Change':<15} {'Status'}")
        print(f"{'-'*85}")
        
        for label, key, fmt in metrics:
            baseline_val = self.baseline_stats[key]
            optimized_val = self.optimized_stats[key]
            
            # Calculate change
            if baseline_val != 0:
                pct_change = (optimized_val - baseline_val) / abs(baseline_val) * 100
            else:
                pct_change = 0
            
            abs_change = optimized_val - baseline_val
            
            # Format values
            if fmt == 'currency':
                baseline_str = f"${baseline_val:.2f}"
                optimized_str = f"${optimized_val:.2f}"
                change_str = f"{abs_change:+.2f} ({pct_change:+.1f}%)"
            elif fmt == 'percentage':
                baseline_str = f"{baseline_val:.2f}%"
                optimized_str = f"{optimized_val:.2f}%"
                change_str = f"{abs_change:+.2f}pp"
            elif fmt == 'ratio':
                baseline_str = f"{baseline_val:.2f}"
                optimized_str = f"{optimized_val:.2f}"
                change_str = f"{abs_change:+.2f} ({pct_change:+.1f}%)"
            elif fmt == 'time':
                baseline_str = f"{baseline_val:.1f}"
                optimized_str = f"{optimized_val:.1f}"
                change_str = f"{abs_change:+.1f} ({pct_change:+.1f}%)"
            else:  # absolute
                baseline_str = f"{int(baseline_val)}"
                optimized_str = f"{int(optimized_val)}"
                change_str = f"{int(abs_change):+d} ({pct_change:+.1f}%)"
            
            # Determine if improvement (depends on metric)
            is_improvement = False
            if key in ['win_rate', 'total_profit', 'profit_factor', 'expectancy', 'avg_win', 
                      'sharpe_ratio', 'largest_win', 'max_consecutive_wins']:
                is_improvement = abs_change > 0
            elif key in ['avg_loss', 'largest_loss', 'max_consecutive_losses']:
                is_improvement = abs_change < 0  # Less negative is better
            elif key == 'total_trades':
                is_improvement = abs_change > -50  # Minor reduction OK, major reduction bad
            
            status = "✅" if is_improvement else "⚠️" if abs(pct_change) < 5 else "❌"
            
            print(f"{label:<25} {baseline_str:<15} {optimized_str:<15} {change_str:<15} {status}")
            
            self.comparison[key] = {
                'baseline': baseline_val,
                'optimized': optimized_val,
                'absolute_change': abs_change,
                'percent_change': pct_change,
                'improvement': is_improvement,
            }
        
        # Statistical significance test
        if HAS_SCIPY and len(self.baseline_df) > 30 and len(self.optimized_df) > 30:
            t_stat, p_value = stats.ttest_ind(
                self.baseline_df['NetProfit'], 
                self.optimized_df['NetProfit']
            )
            print(f"\n📊 Statistical Significance:")
            print(f"   t-statistic: {t_stat:.3f}")
            print(f"   p-value: {p_value:.4f}")
            if p_value < 0.05:
                print(f"   ✅ Difference is statistically significant (p < 0.05)")
            else:
                print(f"   ⚠️  Difference is NOT statistically significant (p >= 0.05)")
        
    def generate_visualizations(self, output_dir: Path):
        """Generate comparison charts"""
        if not HAS_PLOTTING:
            print("\n⚠️  Skipping visualizations (matplotlib not installed)")
            return
        
        print(f"\n{'='*80}")
        print(f"📊 GENERATING COMPARISON CHARTS")
        print(f"{'='*80}")
        
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)
        
        # 1. Comprehensive comparison chart
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        
        # Histogram
        axes[0, 0].hist(self.baseline_df['NetProfit'], bins=30, alpha=0.5, label='Baseline', color='blue')
        axes[0, 0].hist(self.optimized_df['NetProfit'], bins=30, alpha=0.5, label='Optimized', color='green')
        axes[0, 0].axvline(self.baseline_df['NetProfit'].mean(), color='blue', linestyle='--', label='Baseline Mean')
        axes[0, 0].axvline(self.optimized_df['NetProfit'].mean(), color='green', linestyle='--', label='Optimized Mean')
        axes[0, 0].set_xlabel('Net Profit ($)')
        axes[0, 0].set_ylabel('Frequency')
        axes[0, 0].set_title('Profit Distribution Comparison')
        axes[0, 0].legend()
        axes[0, 0].grid(alpha=0.3)
        
        # Cumulative profit (equity curve)
        baseline_cumsum = self.baseline_df['NetProfit'].cumsum()
        optimized_cumsum = self.optimized_df['NetProfit'].cumsum()
        axes[0, 1].plot(baseline_cumsum.values, label='Baseline', color='blue', linewidth=2)
        axes[0, 1].plot(optimized_cumsum.values, label='Optimized', color='green', linewidth=2)
        axes[0, 1].set_xlabel('Trade Number')
        axes[0, 1].set_ylabel('Cumulative Profit ($)')
        axes[0, 1].set_title('Equity Curve Comparison')
        axes[0, 1].legend()
        axes[0, 1].grid(alpha=0.3)
        
        # Box plot
        data_to_plot = [self.baseline_df['NetProfit'], self.optimized_df['NetProfit']]
        axes[1, 0].boxplot(data_to_plot, labels=['Baseline', 'Optimized'])
        axes[1, 0].set_ylabel('Net Profit ($)')
        axes[1, 0].set_title('Profit Distribution (Box Plot)')
        axes[1, 0].grid(alpha=0.3)
        
        # Key metrics bar chart
        metrics_to_plot = ['win_rate', 'profit_factor', 'expectancy']
        baseline_vals = [self.baseline_stats[m] for m in metrics_to_plot]
        optimized_vals = [self.optimized_stats[m] for m in metrics_to_plot]
        
        x = np.arange(len(metrics_to_plot))
        width = 0.35
        axes[1, 1].bar(x - width/2, baseline_vals, width, label='Baseline', color='blue', alpha=0.7)
        axes[1, 1].bar(x + width/2, optimized_vals, width, label='Optimized', color='green', alpha=0.7)
        axes[1, 1].set_ylabel('Value')
        axes[1, 1].set_title('Key Metrics Comparison')
        axes[1, 1].set_xticks(x)
        axes[1, 1].set_xticklabels(['Win Rate (%)', 'Profit Factor', 'Expectancy ($)'])
        axes[1, 1].legend()
        axes[1, 1].grid(alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(output_dir / 'comparison_charts.png', dpi=150, bbox_inches='tight')
        print(f"  ✅ comparison_charts.png")
        plt.close()
        
    def generate_html_report(self, output_path: str = "comparison_report.html"):
        """Generate comprehensive HTML comparison report"""
        print(f"\n{'='*80}")
        print(f"🌐 GENERATING HTML REPORT")
        print(f"{'='*80}")
        
        # Calculate key improvements
        win_rate_improvement = self.comparison['win_rate']['absolute_change']
        profit_improvement = self.comparison['total_profit']['absolute_change']
        pf_improvement = self.comparison['profit_factor']['absolute_change']
        
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Backtest Comparison Report</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 0; padding: 20px; background: #f5f7fa; }}
        .container {{ max-width: 1400px; margin: 0 auto; background: white; padding: 40px; box-shadow: 0 2px 20px rgba(0,0,0,0.1); border-radius: 8px; }}
        h1 {{ color: #2c3e50; border-bottom: 4px solid #3498db; padding-bottom: 15px; margin-bottom: 30px; }}
        h2 {{ color: #34495e; margin-top: 40px; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #ecf0f1; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th, td {{ padding: 14px; text-align: left; border-bottom: 1px solid #ecf0f1; }}
        th {{ background-color: #3498db; color: white; font-weight: 600; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; }}
        tr:hover {{ background-color: #f8f9fa; }}
        .improvement {{ color: #27ae60; font-weight: bold; }}
        .degradation {{ color: #e74c3c; font-weight: bold; }}
        .neutral {{ color: #95a5a6; }}
        .summary-box {{ display: flex; gap: 20px; margin: 30px 0; }}
        .summary-card {{ flex: 1; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 25px; border-radius: 10px; text-align: center; color: white; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }}
        .summary-card h3 {{ margin: 0 0 10px 0; font-size: 14px; text-transform: uppercase; opacity: 0.9; }}
        .summary-card .value {{ font-size: 36px; font-weight: bold; margin: 10px 0; }}
        .summary-card .change {{ font-size: 18px; margin-top: 10px; opacity: 0.95; }}
        .positive {{ color: #2ecc71; }}
        .negative {{ color: #e74c3c; }}
        code {{ background: #f4f4f4; padding: 3px 8px; border-radius: 4px; font-family: 'Monaco', 'Consolas', monospace; font-size: 13px; }}
        .recommendation {{ background: #d5f4e6; padding: 20px; margin: 20px 0; border-left: 5px solid #27ae60; border-radius: 5px; }}
        .warning {{ background: #fee; padding: 20px; margin: 20px 0; border-left: 5px solid #e74c3c; border-radius: 5px; }}
        img {{ max-width: 100%; height: auto; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin: 20px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Backtest Comparison Report</h1>
        <p><strong>Generated:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p><strong>Baseline:</strong> <code>{self.baseline_path.name}</code> ({self.baseline_stats['total_trades']} trades)</p>
        <p><strong>Optimized:</strong> <code>{self.optimized_path.name}</code> ({self.optimized_stats['total_trades']} trades)</p>
        
        <h2>🎯 Executive Summary</h2>
        <div class="summary-box">
            <div class="summary-card">
                <h3>Win Rate</h3>
                <div class="value">{self.optimized_stats['win_rate']:.1f}%</div>
                <div class="change">
                    {win_rate_improvement:+.1f}pp from baseline
                </div>
            </div>
            <div class="summary-card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                <h3>Total Profit</h3>
                <div class="value">${self.optimized_stats['total_profit']:.2f}</div>
                <div class="change">
                    {profit_improvement:+.2f} ({self.comparison['total_profit']['percent_change']:+.1f}%)
                </div>
            </div>
            <div class="summary-card" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                <h3>Profit Factor</h3>
                <div class="value">{self.optimized_stats['profit_factor']:.2f}</div>
                <div class="change">
                    {pf_improvement:+.2f} from baseline
                </div>
            </div>
            <div class="summary-card" style="background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);">
                <h3>Trade Count</h3>
                <div class="value">{self.optimized_stats['total_trades']}</div>
                <div class="change">
                    {self.comparison['total_trades']['absolute_change']:+d} trades
                </div>
            </div>
        </div>
        
        <h2>📈 Detailed Performance Metrics</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Baseline</th>
                <th>Optimized</th>
                <th>Change</th>
                <th>Status</th>
            </tr>
"""
        
        # Add all comparison rows
        metrics_display = [
            ('Total Trades', 'total_trades', lambda x: f"{int(x)}"),
            ('Win Rate', 'win_rate', lambda x: f"{x:.2f}%"),
            ('Total Profit', 'total_profit', lambda x: f"${x:.2f}"),
            ('Profit Factor', 'profit_factor', lambda x: f"{x:.2f}"),
            ('Expectancy', 'expectancy', lambda x: f"${x:.2f}"),
            ('Average Win', 'avg_win', lambda x: f"${x:.2f}"),
            ('Average Loss', 'avg_loss', lambda x: f"${x:.2f}"),
            ('Sharpe Ratio', 'sharpe_ratio', lambda x: f"{x:.2f}"),
            ('Largest Win', 'largest_win', lambda x: f"${x:.2f}"),
            ('Largest Loss', 'largest_loss', lambda x: f"${x:.2f}"),
            ('Max Consecutive Wins', 'max_consecutive_wins', lambda x: f"{int(x)}"),
            ('Max Consecutive Losses', 'max_consecutive_losses', lambda x: f"{int(x)}"),
            ('Avg Hold Time (min)', 'avg_hold_time', lambda x: f"{x:.1f}"),
        ]
        
        for label, key, formatter in metrics_display:
            baseline_val = self.baseline_stats[key]
            optimized_val = self.optimized_stats[key]
            change_data = self.comparison[key]
            
            change_class = 'improvement' if change_data['improvement'] else 'degradation'
            status = '✅' if change_data['improvement'] else '❌'
            
            html += f"""
            <tr>
                <td><strong>{label}</strong></td>
                <td>{formatter(baseline_val)}</td>
                <td>{formatter(optimized_val)}</td>
                <td class="{change_class}">{change_data['absolute_change']:+.2f} ({change_data['percent_change']:+.1f}%)</td>
                <td style="font-size: 18px;">{status}</td>
            </tr>
"""
        
        html += """
        </table>
        
        <h2>📊 Visual Analysis</h2>
        <img src="comparison_charts.png" alt="Comparison Charts" style="width: 100%;">
        
        <h2>💡 Analysis & Recommendations</h2>
"""
        
        # Generate dynamic recommendations based on results
        if win_rate_improvement > 10:
            html += f"""
        <div class="recommendation">
            <h3>✅ Excellent Win Rate Improvement</h3>
            <p>The optimized strategy improved win rate by <strong>{win_rate_improvement:.1f} percentage points</strong>, 
            which is a significant improvement. This suggests the physics filters are effectively identifying high-probability trades.</p>
        </div>
"""
        elif win_rate_improvement > 5:
            html += f"""
        <div class="recommendation">
            <h3>✅ Good Win Rate Improvement</h3>
            <p>Win rate increased by <strong>{win_rate_improvement:.1f} percentage points</strong>. 
            This is a positive result indicating the filters are working as intended.</p>
        </div>
"""
        elif win_rate_improvement < -5:
            html += f"""
        <div class="warning">
            <h3>⚠️ Win Rate Degradation</h3>
            <p>Win rate <strong>decreased by {abs(win_rate_improvement):.1f} percentage points</strong>. 
            This indicates the current filter settings may be removing profitable trades. 
            Consider adjusting thresholds or re-running analytics on a larger dataset.</p>
        </div>
"""
        
        if profit_improvement > 0:
            html += f"""
        <div class="recommendation">
            <h3>✅ Positive Profit Impact</h3>
            <p>Total profit improved by <strong>${profit_improvement:.2f}</strong> ({self.comparison['total_profit']['percent_change']:+.1f}%). 
            The optimization is generating more net profit.</p>
        </div>
"""
        else:
            html += f"""
        <div class="warning">
            <h3>❌ Profit Decreased</h3>
            <p>Total profit decreased by <strong>${abs(profit_improvement):.2f}</strong>. 
            Even if win rate improved, the filtered-out trades may have included large winners. 
            Review the threshold settings and consider a more balanced approach.</p>
        </div>
"""
        
        trade_reduction_pct = abs(self.comparison['total_trades']['percent_change'])
        if trade_reduction_pct > 50:
            html += f"""
        <div class="warning">
            <h3>⚠️ Significant Trade Count Reduction</h3>
            <p>Trade count reduced by <strong>{trade_reduction_pct:.1f}%</strong> ({abs(self.comparison['total_trades']['absolute_change'])} trades). 
            This aggressive filtering may indicate:</p>
            <ul>
                <li>Overly strict threshold settings</li>
                <li>Potential overfitting to the training data</li>
                <li>Reduced opportunity for profit (fewer trades = less compounding)</li>
            </ul>
            <p><strong>Recommendation:</strong> Test on out-of-sample data to validate these filters aren't overfit.</p>
        </div>
"""
        elif trade_reduction_pct < 10:
            html += f"""
        <div class="recommendation">
            <h3>✅ Conservative Filtering</h3>
            <p>Trade count only reduced by <strong>{trade_reduction_pct:.1f}%</strong>. 
            This conservative approach maintains high trade frequency while improving quality.</p>
        </div>
"""
        
        # Profit factor analysis
        if self.optimized_stats['profit_factor'] > 1.5:
            html += f"""
        <div class="recommendation">
            <h3>✅ Strong Profit Factor</h3>
            <p>Profit factor of <strong>{self.optimized_stats['profit_factor']:.2f}</strong> indicates 
            winning trades are significantly larger than losing trades on average.</p>
        </div>
"""
        
        html += """
        <h2>📋 Next Steps</h2>
        <ol>
            <li><strong>Out-of-Sample Validation:</strong> Test these same filter settings on a different date range to ensure they aren't overfit.</li>
            <li><strong>Walk-Forward Analysis:</strong> Run sequential backtests to validate consistency across market conditions.</li>
            <li><strong>Live Paper Trading:</strong> Deploy to a demo account to validate in real market conditions.</li>
            <li><strong>Monitor Drift:</strong> Compare actual vs expected performance weekly to detect degradation early.</li>
        </ol>
        
        <p style="margin-top: 60px; padding-top: 20px; border-top: 2px solid #ecf0f1; color: #7f8c8d; text-align: center;">
            <strong>TickPhysics CSV Backtest Comparison Tool v1.0</strong><br>
            Generated for AI Trading Platform Analytics
        </p>
    </div>
</body>
</html>
"""
        
        output_path = Path(output_path)
        with open(output_path, 'w') as f:
            f.write(html)
        
        print(f"✅ HTML report saved: {output_path}")
        return output_path
    
    def run(self, output_html: str = "comparison_report.html"):
        """Run full comparison analysis"""
        if not self.load_data():
            return False
        
        self.compare()
        
        output_dir = Path(output_html).parent
        if output_dir == Path('.'):
            output_dir = Path('comparison_output')
        output_dir.mkdir(exist_ok=True)
        
        self.generate_visualizations(output_dir)
        self.generate_html_report(output_dir / Path(output_html).name)
        
        print(f"\n{'='*80}")
        print(f"✅ COMPARISON COMPLETE!")
        print(f"{'='*80}")
        print(f"📂 Output directory: {output_dir}")
        print(f"🌐 Open: {output_dir / Path(output_html).name}")
        
        return True


def main():
    parser = argparse.ArgumentParser(description='Compare two backtest CSV files in detail')
    parser.add_argument('baseline', help='Baseline CSV file path')
    parser.add_argument('optimized', help='Optimized/filtered CSV file path')
    parser.add_argument('--output', default='comparison_report.html', help='Output HTML filename')
    
    args = parser.parse_args()
    
    comparison = CSVBacktestComparison(args.baseline, args.optimized)
    success = comparison.run(args.output)
    
    return 0 if success else 1


if __name__ == '__main__':
    exit(main())
