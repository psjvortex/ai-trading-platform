"""
Signal-Trade Correlation Analysis
==================================
This script analyzes the correlation between signal metrics and trading outcomes
to identify which signal features have the biggest impact on trading performance.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
from typing import Dict, List, Tuple
import json

# Set style for better visualizations
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 8)


class SignalTradeAnalyzer:
    """Analyzes correlations between signals and trading outcomes."""
    
    def __init__(self, signals_path: str, trades_path: str):
        """
        Initialize the analyzer with signal and trade data.
        
        Args:
            signals_path: Path to the signals CSV file
            trades_path: Path to the trades CSV file
        """
        self.signals_df = pd.read_csv(signals_path)
        self.trades_df = pd.read_csv(trades_path)
        self.merged_df = None
        self.correlations = {}
        
    def prepare_data(self):
        """Merge signals and trades data on timestamp and prepare for analysis."""
        # Convert timestamps
        self.signals_df['Timestamp'] = pd.to_datetime(self.signals_df['Timestamp'])
        self.trades_df['OpenTime'] = pd.to_datetime(self.trades_df['OpenTime'])
        
        # Merge on timestamp (signals should match trade entry)
        self.merged_df = pd.merge(
            self.trades_df,
            self.signals_df,
            left_on='OpenTime',
            right_on='Timestamp',
            how='inner',
            suffixes=('_trade', '_signal')
        )
        
        # Add derived metrics
        self._add_derived_metrics()
        
        print(f"✓ Merged {len(self.merged_df)} trades with signals")
        print(f"  Total signals: {len(self.signals_df)}")
        print(f"  Total trades: {len(self.trades_df)}")
        
    def _add_derived_metrics(self):
        """Add derived trading performance metrics."""
        # Win/loss binary indicator
        self.merged_df['IsWin'] = (self.merged_df['Profit'] > 0).astype(int)
        
        # Profit categories
        self.merged_df['ProfitCategory'] = pd.cut(
            self.merged_df['Profit'],
            bins=[-np.inf, -5, 0, 5, 10, np.inf],
            labels=['Large Loss', 'Small Loss', 'Small Win', 'Medium Win', 'Large Win']
        )
        
        # Risk-adjusted return
        self.merged_df['RiskAdjustedReturn'] = (
            self.merged_df['Profit'] / self.merged_df['RiskPercent']
        ).replace([np.inf, -np.inf], 0)
        
    def analyze_correlations(self) -> pd.DataFrame:
        """
        Calculate correlations between signal metrics and trading outcomes.
        
        Returns:
            DataFrame with correlation analysis results
        """
        # Signal metrics to analyze
        signal_metrics = [
            'Quality', 'Confluence', 'Momentum', 'Speed', 
            'Acceleration', 'Entropy', 'Jerk'
        ]
        
        # Trading outcome metrics
        outcome_metrics = [
            'Profit', 'ProfitPercent', 'Pips', 'RRatio',
            'MFE', 'MAE', 'IsWin', 'HoldTimeBars'
        ]
        
        correlation_results = []
        
        for signal_metric in signal_metrics:
            if signal_metric not in self.merged_df.columns:
                continue
                
            for outcome_metric in outcome_metrics:
                if outcome_metric not in self.merged_df.columns:
                    continue
                    
                # Calculate Pearson correlation
                corr, p_value = stats.pearsonr(
                    self.merged_df[signal_metric].fillna(0),
                    self.merged_df[outcome_metric].fillna(0)
                )
                
                # Calculate Spearman correlation (rank-based, more robust)
                spearman_corr, spearman_p = stats.spearmanr(
                    self.merged_df[signal_metric].fillna(0),
                    self.merged_df[outcome_metric].fillna(0)
                )
                
                correlation_results.append({
                    'SignalMetric': signal_metric,
                    'OutcomeMetric': outcome_metric,
                    'PearsonCorr': corr,
                    'PearsonPValue': p_value,
                    'SpearmanCorr': spearman_corr,
                    'SpearmanPValue': spearman_p,
                    'Significant': p_value < 0.05,
                    'AbsCorr': abs(corr)
                })
        
        self.correlations = pd.DataFrame(correlation_results)
        self.correlations = self.correlations.sort_values('AbsCorr', ascending=False)
        
        return self.correlations
    
    def get_top_predictors(self, n: int = 10, outcome: str = 'Profit') -> pd.DataFrame:
        """
        Get the top signal metrics that predict a specific outcome.
        
        Args:
            n: Number of top predictors to return
            outcome: The outcome metric to analyze
            
        Returns:
            DataFrame with top predictors
        """
        if self.correlations is None or self.correlations.empty:
            self.analyze_correlations()
            
        top_predictors = self.correlations[
            self.correlations['OutcomeMetric'] == outcome
        ].head(n)
        
        return top_predictors
    
    def analyze_by_signal_quality(self) -> Dict:
        """Analyze trading performance by signal quality bins."""
        # Create quality bins
        self.merged_df['QualityBin'] = pd.cut(
            self.merged_df['Quality'],
            bins=[0, 90, 95, 97, 100],
            labels=['Low (90-)', 'Medium (90-95)', 'High (95-97)', 'Very High (97+)']
        )
        
        quality_analysis = self.merged_df.groupby('QualityBin').agg({
            'Profit': ['mean', 'median', 'sum', 'std'],
            'IsWin': 'mean',  # Win rate
            'Pips': ['mean', 'median'],
            'RRatio': ['mean', 'median'],
            'HoldTimeBars': ['mean', 'median'],
            'Ticket': 'count'  # Number of trades
        }).round(2)
        
        return quality_analysis
    
    def analyze_by_confluence(self) -> Dict:
        """Analyze trading performance by confluence level."""
        confluence_analysis = self.merged_df.groupby('Confluence').agg({
            'Profit': ['mean', 'median', 'sum', 'count'],
            'IsWin': 'mean',
            'Pips': ['mean', 'median'],
            'RRatio': ['mean', 'median']
        }).round(2)
        
        return confluence_analysis
    
    def analyze_momentum_impact(self) -> Dict:
        """Analyze how momentum affects trading outcomes."""
        # Separate by signal direction
        buy_signals = self.merged_df[self.merged_df['Signal'] == 1]
        sell_signals = self.merged_df[self.merged_df['Signal'] == -1]
        
        results = {
            'buy_signals': {
                'momentum_profit_corr': buy_signals[['Momentum', 'Profit']].corr().iloc[0, 1],
                'speed_profit_corr': buy_signals[['Speed', 'Profit']].corr().iloc[0, 1],
                'avg_profit_by_momentum': buy_signals.groupby(
                    pd.cut(buy_signals['Momentum'], bins=5)
                )['Profit'].mean()
            },
            'sell_signals': {
                'momentum_profit_corr': sell_signals[['Momentum', 'Profit']].corr().iloc[0, 1],
                'speed_profit_corr': sell_signals[['Speed', 'Profit']].corr().iloc[0, 1],
                'avg_profit_by_momentum': sell_signals.groupby(
                    pd.cut(sell_signals['Momentum'], bins=5)
                )['Profit'].mean()
            }
        }
        
        return results
    
    def create_correlation_heatmap(self, output_path: str = None):
        """Create a heatmap of correlations between signals and outcomes."""
        signal_metrics = ['Quality', 'Confluence', 'Momentum', 'Speed', 
                         'Acceleration', 'Entropy', 'Jerk']
        outcome_metrics = ['Profit', 'ProfitPercent', 'Pips', 'RRatio', 
                          'IsWin', 'MFE', 'MAE']
        
        # Create correlation matrix
        corr_matrix = pd.DataFrame(
            index=signal_metrics,
            columns=outcome_metrics
        )
        
        for sig in signal_metrics:
            for out in outcome_metrics:
                if sig in self.merged_df.columns and out in self.merged_df.columns:
                    corr_matrix.loc[sig, out] = self.merged_df[[sig, out]].corr().iloc[0, 1]
        
        corr_matrix = corr_matrix.astype(float)
        
        # Create heatmap
        plt.figure(figsize=(12, 8))
        sns.heatmap(
            corr_matrix,
            annot=True,
            fmt='.3f',
            cmap='RdYlGn',
            center=0,
            vmin=-1,
            vmax=1,
            cbar_kws={'label': 'Correlation Coefficient'}
        )
        plt.title('Signal Metrics vs Trading Outcomes - Correlation Heatmap', 
                 fontsize=16, fontweight='bold')
        plt.xlabel('Trading Outcomes', fontsize=12)
        plt.ylabel('Signal Metrics', fontsize=12)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Heatmap saved to {output_path}")
        else:
            plt.show()
            
    def create_scatter_plots(self, output_path: str = None):
        """Create scatter plots for top correlations."""
        top_corrs = self.correlations.head(6)
        
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        axes = axes.flatten()
        
        for idx, row in enumerate(top_corrs.itertuples()):
            if idx >= 6:
                break
                
            ax = axes[idx]
            
            x = self.merged_df[row.SignalMetric]
            y = self.merged_df[row.OutcomeMetric]
            
            # Scatter plot with regression line
            ax.scatter(x, y, alpha=0.5, s=50)
            
            # Add regression line
            z = np.polyfit(x, y, 1)
            p = np.poly1d(z)
            ax.plot(x, p(x), "r--", linewidth=2, alpha=0.8)
            
            ax.set_xlabel(row.SignalMetric, fontsize=11, fontweight='bold')
            ax.set_ylabel(row.OutcomeMetric, fontsize=11, fontweight='bold')
            ax.set_title(
                f'{row.SignalMetric} → {row.OutcomeMetric}\n'
                f'Corr: {row.PearsonCorr:.3f} (p={row.PearsonPValue:.4f})',
                fontsize=10
            )
            ax.grid(True, alpha=0.3)
            
        plt.suptitle('Top 6 Signal-Outcome Correlations', 
                    fontsize=16, fontweight='bold', y=1.00)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Scatter plots saved to {output_path}")
        else:
            plt.show()
    
    def create_quality_performance_chart(self, output_path: str = None):
        """Create visualization of performance by signal quality."""
        quality_stats = self.analyze_by_signal_quality()
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # Extract data for plotting
        quality_labels = quality_stats.index.tolist()
        avg_profit = quality_stats[('Profit', 'mean')].values
        win_rate = quality_stats[('IsWin', 'mean')].values * 100
        avg_rratio = quality_stats[('RRatio', 'mean')].values
        trade_count = quality_stats[('Ticket', 'count')].values
        
        # Plot 1: Average Profit by Quality
        axes[0, 0].bar(quality_labels, avg_profit, color='skyblue', edgecolor='navy')
        axes[0, 0].set_title('Average Profit by Signal Quality', fontsize=12, fontweight='bold')
        axes[0, 0].set_ylabel('Average Profit ($)', fontsize=11)
        axes[0, 0].axhline(y=0, color='red', linestyle='--', alpha=0.5)
        axes[0, 0].grid(True, alpha=0.3)
        
        # Plot 2: Win Rate by Quality
        axes[0, 1].bar(quality_labels, win_rate, color='lightgreen', edgecolor='darkgreen')
        axes[0, 1].set_title('Win Rate by Signal Quality', fontsize=12, fontweight='bold')
        axes[0, 1].set_ylabel('Win Rate (%)', fontsize=11)
        axes[0, 1].axhline(y=50, color='orange', linestyle='--', alpha=0.5, label='50% baseline')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # Plot 3: Risk-Reward Ratio by Quality
        axes[1, 0].bar(quality_labels, avg_rratio, color='coral', edgecolor='darkred')
        axes[1, 0].set_title('Average R:R Ratio by Signal Quality', fontsize=12, fontweight='bold')
        axes[1, 0].set_ylabel('R:R Ratio', fontsize=11)
        axes[1, 0].axhline(y=1, color='blue', linestyle='--', alpha=0.5, label='1:1 baseline')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        
        # Plot 4: Trade Count by Quality
        axes[1, 1].bar(quality_labels, trade_count, color='plum', edgecolor='purple')
        axes[1, 1].set_title('Number of Trades by Signal Quality', fontsize=12, fontweight='bold')
        axes[1, 1].set_ylabel('Trade Count', fontsize=11)
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.suptitle('Trading Performance by Signal Quality', 
                    fontsize=16, fontweight='bold')
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Quality performance chart saved to {output_path}")
        else:
            plt.show()
    
    def generate_report(self, output_dir: str):
        """Generate a comprehensive analysis report."""
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        print("\n" + "="*70)
        print("SIGNAL-TRADE CORRELATION ANALYSIS REPORT")
        print("="*70)
        
        # 1. Top Correlations
        print("\n📊 TOP 10 SIGNAL-OUTCOME CORRELATIONS")
        print("-" * 70)
        top_10 = self.correlations.head(10)
        print(top_10[['SignalMetric', 'OutcomeMetric', 'PearsonCorr', 
                     'PearsonPValue', 'Significant']].to_string(index=False))
        
        # 2. Top Profit Predictors
        print("\n💰 TOP PROFIT PREDICTORS")
        print("-" * 70)
        profit_predictors = self.get_top_predictors(n=5, outcome='Profit')
        print(profit_predictors[['SignalMetric', 'PearsonCorr', 
                                'SpearmanCorr', 'Significant']].to_string(index=False))
        
        # 3. Top Win Rate Predictors
        print("\n🎯 TOP WIN RATE PREDICTORS")
        print("-" * 70)
        win_predictors = self.get_top_predictors(n=5, outcome='IsWin')
        print(win_predictors[['SignalMetric', 'PearsonCorr', 
                            'SpearmanCorr', 'Significant']].to_string(index=False))
        
        # 4. Quality Analysis
        print("\n⭐ PERFORMANCE BY SIGNAL QUALITY")
        print("-" * 70)
        quality_stats = self.analyze_by_signal_quality()
        print(quality_stats)
        
        # 5. Confluence Analysis
        print("\n🔗 PERFORMANCE BY CONFLUENCE LEVEL")
        print("-" * 70)
        confluence_stats = self.analyze_by_confluence()
        print(confluence_stats)
        
        # 6. Momentum Impact
        print("\n🚀 MOMENTUM IMPACT ANALYSIS")
        print("-" * 70)
        momentum_results = self.analyze_momentum_impact()
        print(f"BUY Signals - Momentum-Profit Correlation: "
              f"{momentum_results['buy_signals']['momentum_profit_corr']:.3f}")
        print(f"SELL Signals - Momentum-Profit Correlation: "
              f"{momentum_results['sell_signals']['momentum_profit_corr']:.3f}")
        
        # Generate visualizations
        print("\n📈 GENERATING VISUALIZATIONS...")
        print("-" * 70)
        
        self.create_correlation_heatmap(
            output_path / 'correlation_heatmap.png'
        )
        
        self.create_scatter_plots(
            output_path / 'top_correlations_scatter.png'
        )
        
        self.create_quality_performance_chart(
            output_path / 'quality_performance.png'
        )
        
        # Save data to CSV
        self.correlations.to_csv(
            output_path / 'correlation_results.csv',
            index=False
        )
        print(f"✓ Correlation results saved to correlation_results.csv")
        
        # Save merged data
        self.merged_df.to_csv(
            output_path / 'merged_signals_trades.csv',
            index=False
        )
        print(f"✓ Merged data saved to merged_signals_trades.csv")
        
        # Save summary statistics
        summary = {
            'total_trades': len(self.merged_df),
            'overall_win_rate': float(self.merged_df['IsWin'].mean()),
            'total_profit': float(self.merged_df['Profit'].sum()),
            'avg_profit_per_trade': float(self.merged_df['Profit'].mean()),
            'top_profit_predictor': {
                'metric': profit_predictors.iloc[0]['SignalMetric'],
                'correlation': float(profit_predictors.iloc[0]['PearsonCorr'])
            },
            'top_winrate_predictor': {
                'metric': win_predictors.iloc[0]['SignalMetric'],
                'correlation': float(win_predictors.iloc[0]['PearsonCorr'])
            }
        }
        
        with open(output_path / 'analysis_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        print(f"✓ Summary saved to analysis_summary.json")
        
        print("\n" + "="*70)
        print("✅ ANALYSIS COMPLETE!")
        print(f"📁 All reports saved to: {output_path}")
        print("="*70 + "\n")
        
        return summary


def main():
    """Main execution function."""
    # Define paths
    base_path = Path(__file__).parent.parent / 'MQL5' / 'Backtest_Reports'
    
    signals_file = base_path / 'TP_Integrated_Signals_NAS100_v3.1.1.csv'
    trades_file = base_path / 'TP_Integrated_Trades_NAS100_v3.1.1.csv'
    output_dir = Path(__file__).parent.parent / 'analytics' / 'signal_analysis_output'
    
    # Create analyzer
    print("🔍 Initializing Signal-Trade Correlation Analyzer...")
    analyzer = SignalTradeAnalyzer(
        signals_path=str(signals_file),
        trades_path=str(trades_file)
    )
    
    # Prepare data
    print("📥 Loading and merging data...")
    analyzer.prepare_data()
    
    # Analyze correlations
    print("🔬 Analyzing correlations...")
    analyzer.analyze_correlations()
    
    # Generate comprehensive report
    analyzer.generate_report(str(output_dir))


if __name__ == "__main__":
    main()
