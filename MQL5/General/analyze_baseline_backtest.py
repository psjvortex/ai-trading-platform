#!/usr/bin/env python3
"""
TickPhysics Baseline Backtest Analyzer
Analyzes CSV logs from MA crossover baseline EA (v4.0)
Generates performance reports and optimization recommendations
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from pathlib import Path
import json

# Set style
sns.set_style("darkgrid")
plt.rcParams['figure.figsize'] = (15, 10)

class BaselineBacktestAnalyzer:
    """Analyzes baseline MA crossover strategy performance"""
    
    def __init__(self, trades_csv, signals_csv=None):
        """
        Initialize analyzer with CSV files
        
        Args:
            trades_csv: Path to TP_Crypto_Trades_Cross_v4_0.csv
            signals_csv: Path to TP_Crypto_Signals_Cross_v4_0.csv (optional)
        """
        self.trades_csv = Path(trades_csv)
        self.signals_csv = Path(signals_csv) if signals_csv else None
        
        # Load data
        self.trades_df = None
        self.signals_df = None
        self.stats = {}
        
        self._load_data()
    
    def _load_data(self):
        """Load CSV files into dataframes"""
        print(f"📊 Loading data from {self.trades_csv}")
        
        # Load trades
        if self.trades_csv.exists():
            self.trades_df = pd.read_csv(self.trades_csv)
            self.trades_df['Timestamp'] = pd.to_datetime(self.trades_df['Timestamp'])
            print(f"✅ Loaded {len(self.trades_df)} trade records")
        else:
            print(f"⚠️  Trades file not found: {self.trades_csv}")
            return
        
        # Load signals
        if self.signals_csv and self.signals_csv.exists():
            self.signals_df = pd.read_csv(self.signals_csv)
            self.signals_df['Timestamp'] = pd.to_datetime(self.signals_df['Timestamp'])
            print(f"✅ Loaded {len(self.signals_df)} signal records")
    
    def analyze_trades(self):
        """Analyze trade performance"""
        if self.trades_df is None or len(self.trades_df) == 0:
            print("❌ No trades to analyze")
            return
        
        # Separate OPEN and CLOSE trades
        opens = self.trades_df[self.trades_df['Action'] == 'OPEN'].copy()
        closes = self.trades_df[self.trades_df['Action'] == 'CLOSE'].copy()
        
        print(f"\n{'='*60}")
        print(f"📈 TRADE ANALYSIS")
        print(f"{'='*60}")
        print(f"Total OPEN trades: {len(opens)}")
        print(f"Total CLOSE trades: {len(closes)}")
        
        if len(opens) == 0:
            print("⚠️  No open trades found")
            return
        
        # Calculate P/L for closed trades
        if len(closes) > 0:
            # Match open/close pairs (assumes chronological order)
            trade_pairs = []
            for i, close in closes.iterrows():
                # Find matching open (same type, before close)
                matching_opens = opens[
                    (opens['Type'] == close['Type']) & 
                    (opens['Timestamp'] < close['Timestamp'])
                ]
                if len(matching_opens) > 0:
                    open_trade = matching_opens.iloc[-1]  # Get most recent
                    
                    # Calculate P/L
                    if 'BUY' in close['Type']:
                        pnl = close['Price'] - open_trade['Price']
                    else:
                        pnl = open_trade['Price'] - close['Price']
                    
                    pnl_percent = (pnl / open_trade['Price']) * 100
                    
                    duration = (close['Timestamp'] - open_trade['Timestamp']).total_seconds() / 3600  # hours
                    
                    trade_pairs.append({
                        'open_time': open_trade['Timestamp'],
                        'close_time': close['Timestamp'],
                        'type': close['Type'],
                        'open_price': open_trade['Price'],
                        'close_price': close['Price'],
                        'sl': open_trade['SL'],
                        'tp': open_trade['TP'],
                        'lots': open_trade['Lots'],
                        'pnl': pnl,
                        'pnl_percent': pnl_percent,
                        'duration_hours': duration
                    })
            
            if len(trade_pairs) > 0:
                trades_analysis = pd.DataFrame(trade_pairs)
                
                # Performance metrics
                wins = trades_analysis[trades_analysis['pnl'] > 0]
                losses = trades_analysis[trades_analysis['pnl'] < 0]
                
                win_rate = len(wins) / len(trades_analysis) * 100 if len(trades_analysis) > 0 else 0
                
                print(f"\n{'='*60}")
                print(f"🎯 PERFORMANCE METRICS")
                print(f"{'='*60}")
                print(f"Total Closed Trades: {len(trades_analysis)}")
                print(f"Wins: {len(wins)} ({len(wins)/len(trades_analysis)*100:.1f}%)")
                print(f"Losses: {len(losses)} ({len(losses)/len(trades_analysis)*100:.1f}%)")
                print(f"Win Rate: {win_rate:.2f}%")
                
                if len(wins) > 0:
                    print(f"\nAverage Win: {wins['pnl_percent'].mean():.2f}%")
                    print(f"Largest Win: {wins['pnl_percent'].max():.2f}%")
                
                if len(losses) > 0:
                    print(f"Average Loss: {losses['pnl_percent'].mean():.2f}%")
                    print(f"Largest Loss: {losses['pnl_percent'].min():.2f}%")
                
                if len(wins) > 0 and len(losses) > 0:
                    profit_factor = abs(wins['pnl'].sum() / losses['pnl'].sum())
                    print(f"\nProfit Factor: {profit_factor:.2f}")
                
                print(f"\nAverage Trade Duration: {trades_analysis['duration_hours'].mean():.1f} hours")
                print(f"Median Trade Duration: {trades_analysis['duration_hours'].median():.1f} hours")
                
                # Save analysis
                self.stats['trades'] = trades_analysis
                self.stats['win_rate'] = win_rate
                self.stats['total_trades'] = len(trades_analysis)
                
                # Generate plots
                self._plot_trade_analysis(trades_analysis)
    
    def _plot_trade_analysis(self, trades_df):
        """Generate visualization plots"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('Baseline MA Crossover Strategy - Performance Analysis', fontsize=16, fontweight='bold')
        
        # 1. P/L Distribution
        ax1 = axes[0, 0]
        ax1.hist(trades_df['pnl_percent'], bins=30, edgecolor='black', alpha=0.7)
        ax1.axvline(x=0, color='red', linestyle='--', linewidth=2, label='Break-even')
        ax1.set_xlabel('P/L (%)')
        ax1.set_ylabel('Frequency')
        ax1.set_title('Trade P/L Distribution')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # 2. Cumulative P/L
        ax2 = axes[0, 1]
        trades_df['cumulative_pnl'] = trades_df['pnl_percent'].cumsum()
        ax2.plot(trades_df.index, trades_df['cumulative_pnl'], linewidth=2)
        ax2.fill_between(trades_df.index, 0, trades_df['cumulative_pnl'], alpha=0.3)
        ax2.set_xlabel('Trade Number')
        ax2.set_ylabel('Cumulative P/L (%)')
        ax2.set_title('Cumulative Performance')
        ax2.grid(True, alpha=0.3)
        ax2.axhline(y=0, color='red', linestyle='--', linewidth=1)
        
        # 3. Win/Loss by Type
        ax3 = axes[1, 0]
        trade_type_stats = trades_df.groupby('type').agg({
            'pnl': ['count', lambda x: (x > 0).sum(), lambda x: (x < 0).sum()]
        })
        trade_type_stats.columns = ['Total', 'Wins', 'Losses']
        trade_type_stats.plot(kind='bar', ax=ax3, edgecolor='black')
        ax3.set_xlabel('Trade Type')
        ax3.set_ylabel('Count')
        ax3.set_title('Win/Loss by Trade Type')
        ax3.legend(['Total', 'Wins', 'Losses'])
        ax3.grid(True, alpha=0.3)
        plt.setp(ax3.xaxis.get_majorticklabels(), rotation=0)
        
        # 4. Trade Duration vs P/L
        ax4 = axes[1, 1]
        colors = ['green' if x > 0 else 'red' for x in trades_df['pnl_percent']]
        ax4.scatter(trades_df['duration_hours'], trades_df['pnl_percent'], 
                   c=colors, alpha=0.6, edgecolors='black')
        ax4.axhline(y=0, color='black', linestyle='--', linewidth=1)
        ax4.set_xlabel('Duration (hours)')
        ax4.set_ylabel('P/L (%)')
        ax4.set_title('Trade Duration vs Profitability')
        ax4.grid(True, alpha=0.3)
        
        plt.tight_layout()
        
        # Save plot
        output_file = self.trades_csv.parent / 'baseline_analysis_v4_0.png'
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"\n📊 Analysis chart saved: {output_file}")
        
        # Show plot
        plt.show()
    
    def generate_report(self, output_file='baseline_report_v4_0.json'):
        """Generate JSON report with all statistics"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'version': 'v4.0',
            'strategy': 'Pure MA Crossover Baseline',
            'files_analyzed': {
                'trades': str(self.trades_csv),
                'signals': str(self.signals_csv) if self.signals_csv else None
            },
            'performance': {
                'total_trades': self.stats.get('total_trades', 0),
                'win_rate': self.stats.get('win_rate', 0)
            }
        }
        
        # Add detailed trade stats if available
        if 'trades' in self.stats:
            trades_df = self.stats['trades']
            wins = trades_df[trades_df['pnl'] > 0]
            losses = trades_df[trades_df['pnl'] < 0]
            
            report['performance'].update({
                'wins': len(wins),
                'losses': len(losses),
                'avg_win_percent': float(wins['pnl_percent'].mean()) if len(wins) > 0 else 0,
                'avg_loss_percent': float(losses['pnl_percent'].mean()) if len(losses) > 0 else 0,
                'largest_win_percent': float(wins['pnl_percent'].max()) if len(wins) > 0 else 0,
                'largest_loss_percent': float(losses['pnl_percent'].min()) if len(losses) > 0 else 0,
                'profit_factor': float(abs(wins['pnl'].sum() / losses['pnl'].sum())) if len(losses) > 0 else 0,
                'avg_duration_hours': float(trades_df['duration_hours'].mean()),
                'total_pnl_percent': float(trades_df['pnl_percent'].sum())
            })
        
        # Save report
        output_path = self.trades_csv.parent / output_file
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Report saved: {output_path}")
        return report
    
    def optimize_parameters(self):
        """Suggest parameter optimizations based on baseline performance"""
        if 'trades' not in self.stats:
            print("⚠️  No trade data available for optimization")
            return
        
        trades_df = self.stats['trades']
        
        print(f"\n{'='*60}")
        print(f"🔧 OPTIMIZATION RECOMMENDATIONS")
        print(f"{'='*60}")
        
        # Analyze trade duration
        avg_duration = trades_df['duration_hours'].mean()
        median_duration = trades_df['duration_hours'].median()
        
        print(f"\n1. EXIT MA OPTIMIZATION:")
        print(f"   Current Exit MA: 10/250")
        print(f"   Average trade duration: {avg_duration:.1f} hours")
        print(f"   Median trade duration: {median_duration:.1f} hours")
        
        if avg_duration > 48:
            print(f"   💡 Trades are lasting {avg_duration:.1f}h - consider FASTER exit MA (e.g., 10/150)")
        elif avg_duration < 12:
            print(f"   💡 Trades are quick ({avg_duration:.1f}h) - current exit MA seems appropriate")
        
        # Analyze win/loss ratio
        wins = trades_df[trades_df['pnl'] > 0]
        losses = trades_df[trades_df['pnl'] < 0]
        
        print(f"\n2. RISK/REWARD ANALYSIS:")
        if len(wins) > 0 and len(losses) > 0:
            avg_win = wins['pnl_percent'].mean()
            avg_loss = abs(losses['pnl_percent'].mean())
            rr_ratio = avg_win / avg_loss if avg_loss > 0 else 0
            
            print(f"   Average Win: {avg_win:.2f}%")
            print(f"   Average Loss: {avg_loss:.2f}%")
            print(f"   Risk/Reward Ratio: {rr_ratio:.2f}")
            
            if rr_ratio < 1.0:
                print(f"   ⚠️  R:R < 1.0 - Consider widening TP or tightening SL")
            elif rr_ratio > 2.0:
                print(f"   ✅ R:R > 2.0 - Good risk/reward profile")
        
        # Win rate analysis
        win_rate = self.stats.get('win_rate', 0)
        print(f"\n3. WIN RATE ANALYSIS:")
        print(f"   Current Win Rate: {win_rate:.1f}%")
        
        if win_rate < 40:
            print(f"   ⚠️  Low win rate - Consider adding filters (entropy, confluence, zone)")
        elif win_rate > 60:
            print(f"   ✅ High win rate - Baseline is solid!")
        
        print(f"\n4. NEXT STEPS:")
        print(f"   📊 Run multiple backtests with different MA combinations")
        print(f"   🔬 Enable physics filters one by one to measure impact")
        print(f"   📈 Compare v4.0 baseline to physics-enhanced versions")


def main():
    """Main analysis function"""
    print("="*60)
    print("TickPhysics Baseline Backtest Analyzer v4.0")
    print("="*60)
    
    # File paths (adjust these to your MT5 Files folder)
    # Example: C:/Users/YourName/AppData/Roaming/MetaQuotes/Terminal/XXXXX/MQL5/Files/
    trades_file = "TP_Crypto_Trades_Cross_v4_0.csv"
    signals_file = "TP_Crypto_Signals_Cross_v4_0.csv"
    
    # Initialize analyzer
    analyzer = BaselineBacktestAnalyzer(trades_file, signals_file)
    
    # Run analysis
    analyzer.analyze_trades()
    
    # Generate report
    report = analyzer.generate_report()
    
    # Optimization recommendations
    analyzer.optimize_parameters()
    
    print(f"\n{'='*60}")
    print("✅ Analysis Complete!")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
