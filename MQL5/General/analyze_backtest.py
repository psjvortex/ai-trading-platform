#!/usr/bin/env python3
"""
TickPhysics Crypto Backtest Analyzer
Analyzes CSV logs from EA backtests to validate self-learning and self-healing mechanics
"""

import pandas as pd
import numpy as np
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple
import argparse


class TickPhysicsAnalyzer:
    """Analyzes TickPhysics EA performance and validates self-learning behavior"""
    
    def __init__(self, signals_file: str, trades_file: str):
        """Initialize analyzer with CSV log files"""
        self.signals_file = Path(signals_file)
        self.trades_file = Path(trades_file)
        
        # Load data
        self.signals_df = None
        self.trades_df = None
        self.load_data()
        
    def load_data(self):
        """Load CSV files into pandas DataFrames"""
        try:
            # Load signals
            if self.signals_file.exists():
                self.signals_df = pd.read_csv(self.signals_file)
                print(f"✅ Loaded {len(self.signals_df)} signals from {self.signals_file.name}")
            else:
                print(f"⚠️  Signals file not found: {self.signals_file}")
                
            # Load trades
            if self.trades_file.exists():
                self.trades_df = pd.read_csv(self.trades_file)
                print(f"✅ Loaded {len(self.trades_df)} trades from {self.trades_file.name}")
            else:
                print(f"⚠️  Trades file not found: {self.trades_file}")
                
        except Exception as e:
            print(f"❌ Error loading data: {e}")
            
    def calculate_performance_metrics(self) -> Dict:
        """Calculate key performance metrics"""
        if self.trades_df is None or len(self.trades_df) == 0:
            return {}
            
        metrics = {}
        
        # Basic metrics
        total_trades = len(self.trades_df)
        winning_trades = len(self.trades_df[self.trades_df['Profit'] > 0])
        losing_trades = len(self.trades_df[self.trades_df['Profit'] < 0])
        
        metrics['total_trades'] = total_trades
        metrics['winning_trades'] = winning_trades
        metrics['losing_trades'] = losing_trades
        metrics['win_rate'] = (winning_trades / total_trades * 100) if total_trades > 0 else 0
        
        # Profit metrics
        total_profit = self.trades_df['Profit'].sum()
        gross_profit = self.trades_df[self.trades_df['Profit'] > 0]['Profit'].sum()
        gross_loss = abs(self.trades_df[self.trades_df['Profit'] < 0]['Profit'].sum())
        
        metrics['total_profit'] = total_profit
        metrics['gross_profit'] = gross_profit
        metrics['gross_loss'] = gross_loss
        metrics['profit_factor'] = (gross_profit / gross_loss) if gross_loss > 0 else 0
        
        # Average metrics
        metrics['avg_win'] = self.trades_df[self.trades_df['Profit'] > 0]['Profit'].mean() if winning_trades > 0 else 0
        metrics['avg_loss'] = self.trades_df[self.trades_df['Profit'] < 0]['Profit'].mean() if losing_trades > 0 else 0
        
        # Max drawdown
        if 'Balance' in self.trades_df.columns:
            cumulative_max = self.trades_df['Balance'].cummax()
            drawdown = (self.trades_df['Balance'] - cumulative_max) / cumulative_max * 100
            metrics['max_drawdown_pct'] = abs(drawdown.min())
        
        return metrics
        
    def analyze_signal_vs_trade_ratio(self) -> Dict:
        """Analyze how many signals resulted in trades (self-healing filtering)"""
        if self.signals_df is None or self.trades_df is None:
            return {}
            
        total_signals = len(self.signals_df)
        total_trades = len(self.trades_df)
        
        # Count signals by action
        buy_signals = len(self.signals_df[self.signals_df['Signal'] == 'BUY'])
        sell_signals = len(self.signals_df[self.signals_df['Signal'] == 'SELL'])
        skipped_signals = len(self.signals_df[self.signals_df['Signal'] == 'SKIP'])
        
        analysis = {
            'total_signals': total_signals,
            'total_trades': total_trades,
            'buy_signals': buy_signals,
            'sell_signals': sell_signals,
            'skipped_signals': skipped_signals,
            'signal_to_trade_ratio': (total_trades / total_signals * 100) if total_signals > 0 else 0,
            'skip_rate': (skipped_signals / total_signals * 100) if total_signals > 0 else 0
        }
        
        return analysis
        
    def identify_loss_patterns(self, min_consecutive_losses: int = 3) -> List[Dict]:
        """Identify patterns where consecutive losses occurred at similar conditions"""
        if self.trades_df is None or len(self.trades_df) < min_consecutive_losses:
            return []
            
        patterns = []
        consecutive_losses = 0
        loss_streak_start = None
        
        for idx, row in self.trades_df.iterrows():
            if row['Profit'] < 0:
                consecutive_losses += 1
                if consecutive_losses == 1:
                    loss_streak_start = idx
            else:
                if consecutive_losses >= min_consecutive_losses:
                    # Found a pattern
                    pattern = {
                        'start_idx': loss_streak_start,
                        'end_idx': idx - 1,
                        'consecutive_losses': consecutive_losses,
                        'total_loss': self.trades_df.loc[loss_streak_start:idx-1, 'Profit'].sum()
                    }
                    patterns.append(pattern)
                consecutive_losses = 0
                loss_streak_start = None
                
        return patterns
        
    def generate_optimization_suggestions(self) -> List[str]:
        """Generate optimization suggestions based on analysis"""
        suggestions = []
        
        metrics = self.calculate_performance_metrics()
        
        if metrics.get('win_rate', 0) < 40:
            suggestions.append("⚠️  Win rate below 40% - Consider tightening entry filters (increase MinQuality/MinConfluence)")
            
        if metrics.get('profit_factor', 0) < 1.5:
            suggestions.append("⚠️  Profit factor below 1.5 - Risk/reward may be suboptimal (review SL/TP settings)")
            
        signal_analysis = self.analyze_signal_vs_trade_ratio()
        if signal_analysis.get('skip_rate', 0) < 30:
            suggestions.append("💡 Low skip rate - Self-healing may not be filtering aggressively enough")
        elif signal_analysis.get('skip_rate', 0) > 70:
            suggestions.append("⚠️  High skip rate - Self-healing may be too restrictive, missing opportunities")
            
        loss_patterns = self.identify_loss_patterns()
        if len(loss_patterns) > 0:
            suggestions.append(f"🔍 Found {len(loss_patterns)} consecutive loss patterns - Review JSON learning file")
            
        if not suggestions:
            suggestions.append("✅ Performance metrics look healthy!")
            
        return suggestions
        
    def print_summary_report(self):
        """Print a comprehensive summary report"""
        print("\n" + "="*80)
        print("📊 TICKPHYSICS BACKTEST ANALYSIS REPORT")
        print("="*80)
        
        # Performance Metrics
        print("\n📈 PERFORMANCE METRICS:")
        print("-" * 80)
        metrics = self.calculate_performance_metrics()
        for key, value in metrics.items():
            if isinstance(value, float):
                print(f"  {key.replace('_', ' ').title()}: {value:.2f}")
            else:
                print(f"  {key.replace('_', ' ').title()}: {value}")
                
        # Signal Analysis
        print("\n🎯 SIGNAL ANALYSIS:")
        print("-" * 80)
        signal_analysis = self.analyze_signal_vs_trade_ratio()
        for key, value in signal_analysis.items():
            if isinstance(value, float):
                print(f"  {key.replace('_', ' ').title()}: {value:.2f}")
            else:
                print(f"  {key.replace('_', ' ').title()}: {value}")
                
        # Loss Patterns
        print("\n🔍 LOSS PATTERN ANALYSIS:")
        print("-" * 80)
        loss_patterns = self.identify_loss_patterns()
        if loss_patterns:
            for i, pattern in enumerate(loss_patterns, 1):
                print(f"  Pattern {i}: {pattern['consecutive_losses']} consecutive losses, "
                      f"Total Loss: ${pattern['total_loss']:.2f}")
        else:
            print("  ✅ No significant loss patterns detected")
            
        # Optimization Suggestions
        print("\n💡 OPTIMIZATION SUGGESTIONS:")
        print("-" * 80)
        suggestions = self.generate_optimization_suggestions()
        for suggestion in suggestions:
            print(f"  {suggestion}")
            
        print("\n" + "="*80)
        
    def export_analysis_json(self, output_file: str = "backtest_analysis.json"):
        """Export analysis results to JSON"""
        analysis = {
            'timestamp': datetime.now().isoformat(),
            'metrics': self.calculate_performance_metrics(),
            'signal_analysis': self.analyze_signal_vs_trade_ratio(),
            'loss_patterns': self.identify_loss_patterns(),
            'suggestions': self.generate_optimization_suggestions()
        }
        
        output_path = Path(output_file)
        with open(output_path, 'w') as f:
            json.dump(analysis, f, indent=2)
            
        print(f"\n✅ Analysis exported to: {output_path}")
        

def compare_backtests(baseline_analyzer: TickPhysicsAnalyzer, 
                      optimized_analyzer: TickPhysicsAnalyzer):
    """Compare two backtest runs to show improvement"""
    print("\n" + "="*80)
    print("📊 BACKTEST COMPARISON: Baseline vs Optimized")
    print("="*80)
    
    baseline_metrics = baseline_analyzer.calculate_performance_metrics()
    optimized_metrics = optimized_analyzer.calculate_performance_metrics()
    
    comparison_keys = ['total_trades', 'win_rate', 'profit_factor', 'total_profit', 'max_drawdown_pct']
    
    print(f"\n{'Metric':<30} {'Baseline':<15} {'Optimized':<15} {'Change':<15}")
    print("-" * 80)
    
    for key in comparison_keys:
        baseline_val = baseline_metrics.get(key, 0)
        optimized_val = optimized_metrics.get(key, 0)
        
        if baseline_val != 0:
            change_pct = ((optimized_val - baseline_val) / baseline_val * 100)
            change_str = f"{change_pct:+.1f}%"
        else:
            change_str = "N/A"
            
        print(f"{key.replace('_', ' ').title():<30} {baseline_val:<15.2f} {optimized_val:<15.2f} {change_str:<15}")
        
    print("\n" + "="*80)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Analyze TickPhysics EA backtest results')
    parser.add_argument('mode', choices=['analyze', 'compare'], 
                       help='Analysis mode: analyze single run or compare two runs')
    parser.add_argument('signals_file', help='Path to signals CSV file')
    parser.add_argument('trades_file', help='Path to trades CSV file')
    parser.add_argument('--baseline-signals', help='Baseline signals file (for compare mode)')
    parser.add_argument('--baseline-trades', help='Baseline trades file (for compare mode)')
    parser.add_argument('--export', help='Export analysis to JSON file')
    
    args = parser.parse_args()
    
    if args.mode == 'analyze':
        # Single analysis
        analyzer = TickPhysicsAnalyzer(args.signals_file, args.trades_file)
        analyzer.print_summary_report()
        
        if args.export:
            analyzer.export_analysis_json(args.export)
            
    elif args.mode == 'compare':
        # Comparison analysis
        if not args.baseline_signals or not args.baseline_trades:
            print("❌ Error: --baseline-signals and --baseline-trades required for compare mode")
            return
            
        baseline = TickPhysicsAnalyzer(args.baseline_signals, args.baseline_trades)
        optimized = TickPhysicsAnalyzer(args.signals_file, args.trades_file)
        
        baseline.print_summary_report()
        optimized.print_summary_report()
        compare_backtests(baseline, optimized)


if __name__ == '__main__':
    main()
