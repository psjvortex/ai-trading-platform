"""
Multi-Dataset Signal-Trade Correlation Analysis
================================================
Analyzes correlations across multiple versions, timeframes, and symbols
to identify robust patterns that hold across different market conditions.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
from typing import Dict
import json
import warnings
warnings.filterwarnings('ignore')

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (16, 10)


class MultiDatasetAnalyzer:
    """Analyzes correlations across multiple backtest datasets."""
    
    def __init__(self, base_path: str):
        """
        Initialize the multi-dataset analyzer.
        
        Args:
            base_path: Path to the Backtest_Reports directory
        """
        self.base_path = Path(base_path)
        self.datasets = []
        self.all_correlations = []
        self.summary_stats = {}
        
    def discover_datasets(self):
        """Automatically discover all available signal/trade pairs."""
        print("🔍 Discovering datasets...")
        
        # Pattern matching for different files
        signals_files = list(self.base_path.glob("TP_Integrated_Signals_*.csv"))
        
        for signals_file in signals_files:
            # Extract metadata from filename
            filename = signals_file.stem
            parts = filename.replace("TP_Integrated_Signals_", "").split("_")
            
            # Parse symbol and version
            symbol = parts[0] if parts else "UNKNOWN"
            version = parts[1] if len(parts) > 1 else "UNKNOWN"
            timeframe = parts[2] if len(parts) > 2 else "1H"
            
            # Find corresponding trades file
            trades_pattern = f"TP_Integrated_Trades_{symbol}_"
            trades_files = list(self.base_path.glob(f"{trades_pattern}*.csv"))
            
            # Match by version
            trades_file = None
            for tf in trades_files:
                if version in tf.stem and timeframe in tf.stem:
                    trades_file = tf
                    break
                elif version in tf.stem and len(parts) == 2:  # No timeframe specified
                    trades_file = tf
                    break
            
            if trades_file and trades_file.exists():
                dataset_info = {
                    'symbol': symbol,
                    'version': version,
                    'timeframe': timeframe,
                    'signals_file': signals_file,
                    'trades_file': trades_file,
                    'name': f"{symbol}_{version}_{timeframe}"
                }
                self.datasets.append(dataset_info)
                print(f"  ✓ Found: {dataset_info['name']}")
        
        # Also check subdirectories
        for subdir in ['BTCUSD', 'MTB']:
            subdir_path = self.base_path / subdir
            if subdir_path.exists():
                signals_files = list(subdir_path.glob("TP_Integrated_Signals_*.csv"))
                for signals_file in signals_files:
                    filename = signals_file.stem
                    # Try to find matching trades file
                    trades_files = list(subdir_path.glob("TP_Integrated_Trades_*.csv"))
                    if trades_files:
                        dataset_info = {
                            'symbol': subdir,
                            'version': 'UNKNOWN',
                            'timeframe': '1H',
                            'signals_file': signals_file,
                            'trades_file': trades_files[0],
                            'name': f"{subdir}_subdir"
                        }
                        self.datasets.append(dataset_info)
                        print(f"  ✓ Found: {dataset_info['name']} (subdirectory)")
        
        print(f"\n📊 Discovered {len(self.datasets)} datasets\n")
        return self.datasets
    
    def analyze_dataset(self, dataset_info: Dict) -> Dict:
        """Analyze a single dataset."""
        try:
            # Load data
            signals_df = pd.read_csv(dataset_info['signals_file'])
            trades_df = pd.read_csv(dataset_info['trades_file'])
            
            # Convert timestamps
            signals_df['Timestamp'] = pd.to_datetime(signals_df['Timestamp'], errors='coerce')
            trades_df['OpenTime'] = pd.to_datetime(trades_df['OpenTime'], errors='coerce')
            
            # Merge
            merged_df = pd.merge(
                trades_df,
                signals_df,
                left_on='OpenTime',
                right_on='Timestamp',
                how='inner',
                suffixes=('_trade', '_signal')
            )
            
            if len(merged_df) == 0:
                print(f"  ⚠️  {dataset_info['name']}: No matching trades found")
                return None
            
            # Add derived metrics
            merged_df['IsWin'] = (merged_df['Profit'] > 0).astype(int)
            
            # Calculate correlations
            signal_metrics = ['Quality', 'Confluence', 'Momentum', 'Speed', 
                            'Acceleration', 'Entropy', 'Jerk']
            outcome_metrics = ['Profit', 'ProfitPercent', 'IsWin', 'RRatio', 'Pips']
            
            correlations = []
            for sig in signal_metrics:
                if sig not in merged_df.columns:
                    continue
                for out in outcome_metrics:
                    if out not in merged_df.columns:
                        continue
                    
                    # Filter out invalid values
                    valid_mask = (~merged_df[sig].isna()) & (~merged_df[out].isna())
                    if valid_mask.sum() < 10:  # Need at least 10 samples
                        continue
                    
                    try:
                        corr, p_value = stats.pearsonr(
                            merged_df.loc[valid_mask, sig],
                            merged_df.loc[valid_mask, out]
                        )
                        
                        if not np.isnan(corr):
                            correlations.append({
                                'dataset': dataset_info['name'],
                                'symbol': dataset_info['symbol'],
                                'version': dataset_info['version'],
                                'timeframe': dataset_info['timeframe'],
                                'signal_metric': sig,
                                'outcome_metric': out,
                                'correlation': corr,
                                'p_value': p_value,
                                'n_samples': valid_mask.sum(),
                                'significant': p_value < 0.05
                            })
                    except Exception:
                        continue
            
            # Calculate dataset stats
            stats_dict = {
                'dataset': dataset_info['name'],
                'symbol': dataset_info['symbol'],
                'version': dataset_info['version'],
                'timeframe': dataset_info['timeframe'],
                'total_trades': len(merged_df),
                'win_rate': merged_df['IsWin'].mean(),
                'avg_profit': merged_df['Profit'].mean(),
                'total_profit': merged_df['Profit'].sum(),
                'correlations_found': len(correlations)
            }
            
            print(f"  ✓ {dataset_info['name']}: {len(merged_df)} trades, "
                  f"{len(correlations)} correlations")
            
            return {
                'stats': stats_dict,
                'correlations': correlations,
                'merged_data': merged_df
            }
            
        except Exception as e:
            print(f"  ✗ {dataset_info['name']}: Error - {str(e)}")
            return None
    
    def analyze_all_datasets(self):
        """Analyze all discovered datasets."""
        print("\n🔬 Analyzing all datasets...\n")
        
        results = []
        for dataset_info in self.datasets:
            result = self.analyze_dataset(dataset_info)
            if result:
                results.append(result)
                self.all_correlations.extend(result['correlations'])
                self.summary_stats[dataset_info['name']] = result['stats']
        
        print(f"\n✅ Analyzed {len(results)} datasets successfully")
        print(f"📊 Total correlations calculated: {len(self.all_correlations)}\n")
        
        return results
    
    def find_robust_correlations(self, min_datasets: int = 3) -> pd.DataFrame:
        """
        Find correlations that appear consistently across multiple datasets.
        
        Args:
            min_datasets: Minimum number of datasets where correlation must appear
            
        Returns:
            DataFrame with robust correlations
        """
        if not self.all_correlations:
            return pd.DataFrame()
        
        corr_df = pd.DataFrame(self.all_correlations)
        
        # Group by signal-outcome pair
        grouped = corr_df.groupby(['signal_metric', 'outcome_metric']).agg({
            'correlation': ['mean', 'std', 'count'],
            'p_value': 'mean',
            'significant': 'sum',
            'n_samples': 'sum'
        }).reset_index()
        
        # Flatten column names
        grouped.columns = ['_'.join(col).strip('_') for col in grouped.columns.values]
        
        # Filter for robust patterns
        robust = grouped[grouped['correlation_count'] >= min_datasets].copy()
        robust = robust.sort_values('correlation_mean', key=abs, ascending=False)
        
        # Add consistency metric (inverse of std)
        robust['consistency'] = 1 / (1 + robust['correlation_std'])
        robust['robustness_score'] = (
            abs(robust['correlation_mean']) * 
            robust['consistency'] * 
            np.log1p(robust['correlation_count'])
        )
        
        robust = robust.sort_values('robustness_score', ascending=False)
        
        return robust
    
    def compare_across_symbols(self) -> Dict:
        """Compare correlations across different symbols."""
        if not self.all_correlations:
            return {}
        
        corr_df = pd.DataFrame(self.all_correlations)
        
        by_symbol = {}
        for symbol in corr_df['symbol'].unique():
            symbol_data = corr_df[corr_df['symbol'] == symbol]
            
            # Top correlations for this symbol
            top_corr = symbol_data.nlargest(10, 'correlation', keep='all')
            
            by_symbol[symbol] = {
                'n_datasets': symbol_data['dataset'].nunique(),
                'total_trades': symbol_data['n_samples'].sum(),
                'avg_correlation': symbol_data['correlation'].abs().mean(),
                'top_predictor': top_corr.iloc[0] if len(top_corr) > 0 else None
            }
        
        return by_symbol
    
    def compare_across_timeframes(self) -> Dict:
        """Compare correlations across different timeframes."""
        if not self.all_correlations:
            return {}
        
        corr_df = pd.DataFrame(self.all_correlations)
        
        by_timeframe = {}
        for tf in corr_df['timeframe'].unique():
            tf_data = corr_df[corr_df['timeframe'] == tf]
            
            by_timeframe[tf] = {
                'n_datasets': tf_data['dataset'].nunique(),
                'total_trades': tf_data['n_samples'].sum(),
                'avg_correlation': tf_data['correlation'].abs().mean(),
                'significant_pct': (tf_data['significant'].sum() / len(tf_data)) * 100
            }
        
        return by_timeframe
    
    def create_robustness_heatmap(self, output_path: str = None):
        """Create heatmap showing correlation consistency across datasets."""
        if not self.all_correlations:
            print("No correlations to plot")
            return
        
        corr_df = pd.DataFrame(self.all_correlations)
        
        # Pivot to get mean correlation for each signal-outcome pair
        pivot = corr_df.pivot_table(
            values='correlation',
            index='signal_metric',
            columns='outcome_metric',
            aggfunc='mean'
        )
        
        # Create heatmap
        plt.figure(figsize=(14, 8))
        sns.heatmap(
            pivot,
            annot=True,
            fmt='.3f',
            cmap='RdYlGn',
            center=0,
            vmin=-0.5,
            vmax=0.5,
            cbar_kws={'label': 'Mean Correlation Across All Datasets'}
        )
        plt.title('Robust Signal-Outcome Correlations\n'
                  f'Averaged Across {len(self.datasets)} Datasets',
                  fontsize=16, fontweight='bold', pad=20)
        plt.xlabel('Trading Outcomes', fontsize=12, fontweight='bold')
        plt.ylabel('Signal Metrics', fontsize=12, fontweight='bold')
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Robustness heatmap saved to {output_path}")
        else:
            plt.show()
    
    def create_consistency_chart(self, output_path: str = None):
        """Create chart showing which correlations are most consistent."""
        robust = self.find_robust_correlations(min_datasets=2)
        
        if len(robust) == 0:
            print("No robust correlations found")
            return
        
        top_20 = robust.head(20)
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 10))
        
        # Chart 1: Top correlations by robustness score
        labels = [f"{row['signal_metric']}\n→ {row['outcome_metric']}" 
                 for _, row in top_20.iterrows()]
        
        ax1.barh(range(len(top_20)), top_20['correlation_mean'], 
                        color=['#28a745' if x > 0 else '#dc3545' 
                               for x in top_20['correlation_mean']])
        ax1.set_yticks(range(len(top_20)))
        ax1.set_yticklabels(labels, fontsize=9)
        ax1.set_xlabel('Mean Correlation', fontsize=12, fontweight='bold')
        ax1.set_title('Top 20 Most Robust Correlations\n(Averaged Across Datasets)', 
                     fontsize=14, fontweight='bold')
        ax1.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
        ax1.grid(axis='x', alpha=0.3)
        
        # Add dataset count labels
        for i, (_, row) in enumerate(top_20.iterrows()):
            ax1.text(row['correlation_mean'], i, 
                    f"  n={int(row['correlation_count'])}", 
                    va='center', fontsize=8, color='black')
        
        # Chart 2: Consistency scores
        ax2.barh(range(len(top_20)), top_20['consistency'], 
                        color='#667eea', alpha=0.7)
        ax2.set_yticks(range(len(top_20)))
        ax2.set_yticklabels(labels, fontsize=9)
        ax2.set_xlabel('Consistency Score', fontsize=12, fontweight='bold')
        ax2.set_title('Correlation Consistency\n(Lower Std Dev = Higher Score)', 
                     fontsize=14, fontweight='bold')
        ax2.grid(axis='x', alpha=0.3)
        
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Consistency chart saved to {output_path}")
        else:
            plt.show()
    
    def create_symbol_comparison(self, output_path: str = None):
        """Compare correlation strengths across symbols."""
        if not self.all_correlations:
            return
        
        corr_df = pd.DataFrame(self.all_correlations)
        
        # Calculate average absolute correlation by symbol
        symbol_stats = corr_df.groupby('symbol').agg({
            'correlation': lambda x: abs(x).mean(),
            'dataset': 'nunique',
            'n_samples': 'sum'
        }).reset_index()
        
        symbol_stats.columns = ['Symbol', 'Avg_Abs_Correlation', 'N_Datasets', 'Total_Trades']
        symbol_stats = symbol_stats.sort_values('Avg_Abs_Correlation', ascending=False)
        
        fig, axes = plt.subplots(1, 3, figsize=(18, 6))
        
        # Chart 1: Average correlation strength
        axes[0].barh(symbol_stats['Symbol'], symbol_stats['Avg_Abs_Correlation'], 
                    color='#667eea')
        axes[0].set_xlabel('Avg Absolute Correlation', fontweight='bold')
        axes[0].set_title('Signal Predictiveness by Symbol', fontweight='bold')
        axes[0].grid(axis='x', alpha=0.3)
        
        # Chart 2: Number of datasets
        axes[1].barh(symbol_stats['Symbol'], symbol_stats['N_Datasets'], 
                    color='#28a745')
        axes[1].set_xlabel('Number of Datasets', fontweight='bold')
        axes[1].set_title('Dataset Coverage by Symbol', fontweight='bold')
        axes[1].grid(axis='x', alpha=0.3)
        
        # Chart 3: Total trades
        axes[2].barh(symbol_stats['Symbol'], symbol_stats['Total_Trades'], 
                    color='#ffc107')
        axes[2].set_xlabel('Total Trades Analyzed', fontweight='bold')
        axes[2].set_title('Sample Size by Symbol', fontweight='bold')
        axes[2].grid(axis='x', alpha=0.3)
        
        plt.suptitle('Cross-Symbol Analysis', fontsize=16, fontweight='bold', y=1.02)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Symbol comparison saved to {output_path}")
        else:
            plt.show()
    
    def generate_multi_dataset_report(self, output_dir: str):
        """Generate comprehensive multi-dataset analysis report."""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        print("\n" + "="*80)
        print("MULTI-DATASET CORRELATION ANALYSIS REPORT")
        print("="*80)
        
        # 1. Overview
        print("\n📊 DATASET OVERVIEW")
        print("-" * 80)
        print(f"Total Datasets Analyzed: {len(self.datasets)}")
        print(f"Total Correlations Calculated: {len(self.all_correlations)}")
        
        # Summary by symbol
        corr_df = pd.DataFrame(self.all_correlations)
        print(f"\nSymbols: {', '.join(corr_df['symbol'].unique())}")
        print(f"Versions: {', '.join(corr_df['version'].unique())}")
        print(f"Timeframes: {', '.join(corr_df['timeframe'].unique())}")
        
        # 2. Robust Correlations
        print("\n🎯 TOP 10 MOST ROBUST CORRELATIONS")
        print("-" * 80)
        print("(Appear consistently across multiple datasets)")
        print()
        
        robust = self.find_robust_correlations(min_datasets=2)
        if len(robust) > 0:
            top_10 = robust.head(10)
            display_cols = ['signal_metric', 'outcome_metric', 'correlation_mean', 
                          'correlation_std', 'correlation_count', 'robustness_score']
            print(top_10[display_cols].to_string(index=False))
            
            # Save to CSV
            robust.to_csv(output_path / 'robust_correlations.csv', index=False)
            print("\n✓ Robust correlations saved to robust_correlations.csv")
        
        # 3. Symbol Comparison
        print("\n🔍 COMPARISON BY SYMBOL")
        print("-" * 80)
        symbol_comp = self.compare_across_symbols()
        for symbol, symbol_stats in symbol_comp.items():
            print(f"\n{symbol}:")
            print(f"  Datasets: {symbol_stats['n_datasets']}")
            print(f"  Total Trades: {symbol_stats['total_trades']}")
            print(f"  Avg Correlation Strength: {symbol_stats['avg_correlation']:.3f}")
        
        # 4. Timeframe Comparison
        print("\n⏱️  COMPARISON BY TIMEFRAME")
        print("-" * 80)
        tf_comp = self.compare_across_timeframes()
        for tf, tf_stats in tf_comp.items():
            print(f"\n{tf}:")
            print(f"  Datasets: {tf_stats['n_datasets']}")
            print(f"  Total Trades: {tf_stats['total_trades']}")
            print(f"  Avg Correlation: {tf_stats['avg_correlation']:.3f}")
            print(f"  Significant %: {tf_stats['significant_pct']:.1f}%")
        
        # 5. Generate visualizations
        print("\n📈 GENERATING VISUALIZATIONS...")
        print("-" * 80)
        
        self.create_robustness_heatmap(
            output_path / 'multi_dataset_robustness_heatmap.png'
        )
        
        self.create_consistency_chart(
            output_path / 'multi_dataset_consistency_chart.png'
        )
        
        self.create_symbol_comparison(
            output_path / 'multi_dataset_symbol_comparison.png'
        )
        
        # 6. Save all correlations
        corr_df.to_csv(output_path / 'all_correlations.csv', index=False)
        print("✓ All correlations saved to all_correlations.csv")
        
        # 7. Save summary stats
        summary_df = pd.DataFrame(self.summary_stats.values())
        summary_df.to_csv(output_path / 'dataset_summary.csv', index=False)
        print("✓ Dataset summary saved to dataset_summary.csv")
        
        # 8. Create JSON summary
        summary = {
            'analysis_date': '2025-11-12',
            'total_datasets': len(self.datasets),
            'total_correlations': len(self.all_correlations),
            'symbols': list(corr_df['symbol'].unique()),
            'versions': list(corr_df['version'].unique()),
            'timeframes': list(corr_df['timeframe'].unique()),
            'top_robust_correlation': {
                'signal': robust.iloc[0]['signal_metric'] if len(robust) > 0 else None,
                'outcome': robust.iloc[0]['outcome_metric'] if len(robust) > 0 else None,
                'mean_correlation': float(robust.iloc[0]['correlation_mean']) if len(robust) > 0 else None,
                'appears_in_datasets': int(robust.iloc[0]['correlation_count']) if len(robust) > 0 else None
            } if len(robust) > 0 else {}
        }
        
        with open(output_path / 'multi_dataset_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        print("✓ Summary saved to multi_dataset_summary.json")
        
        print("\n" + "="*80)
        print("✅ MULTI-DATASET ANALYSIS COMPLETE!")
        print(f"📁 All reports saved to: {output_path}")
        print("="*80 + "\n")


def main():
    """Main execution function."""
    base_path = Path(__file__).parent.parent / 'MQL5' / 'Backtest_Reports'
    output_dir = Path(__file__).parent.parent / 'analytics' / 'multi_dataset_analysis'
    
    print("🚀 Multi-Dataset Correlation Analysis")
    print("=" * 80)
    
    # Create analyzer
    analyzer = MultiDatasetAnalyzer(str(base_path))
    
    # Discover datasets
    datasets = analyzer.discover_datasets()
    
    if len(datasets) == 0:
        print("❌ No datasets found!")
        return
    
    # Analyze all
    analyzer.analyze_all_datasets()
    
    # Generate report
    analyzer.generate_multi_dataset_report(str(output_dir))


if __name__ == "__main__":
    main()
