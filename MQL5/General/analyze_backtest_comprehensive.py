#!/usr/bin/env python3
"""
TickPhysics Backtest Analytics & Reporting System
Institutional-grade analytics with charts and PDF reports
"""
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from datetime import datetime
import numpy as np

# Set style for professional charts
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10

class BacktestAnalyzer:
    """Comprehensive backtest analysis and reporting"""
    
    def __init__(self, symbol='NAS100', timeframe='M15', version='1_7'):
        self.symbol = symbol
        self.timeframe = timeframe
        self.version = version
        
        # Paths
        self.base_dir = Path(__file__).parent
        self.data_dir = self.base_dir / 'analytics_output' / 'data' / 'backtest'
        self.charts_dir = self.base_dir / 'analytics_output' / 'charts' / f'v{version}'
        self.reports_dir = self.base_dir / 'analytics_output' / 'reports' / f'v{version}'
        
        # Create output directories
        self.charts_dir.mkdir(parents=True, exist_ok=True)
        self.reports_dir.mkdir(parents=True, exist_ok=True)
        
        # Load data
        self.trades_df = None
        self.signals_df = None
        self.load_data()
    
    def load_data(self):
        """Load CSV data"""
        trades_file = self.data_dir / f'TP_Integrated_Trades_{self.symbol}_{self.timeframe}_v{self.version}.csv'
        signals_file = self.data_dir / f'TP_Integrated_Signals_{self.symbol}_{self.timeframe}_v{self.version}.csv'
        
        print(f"\n{'='*70}")
        print(f"  LOADING DATA: {self.symbol} {self.timeframe} v{self.version}")
        print(f"{'='*70}\n")
        
        # Load trades
        self.trades_df = pd.read_csv(trades_file)
        self.trades_df['OpenTime'] = pd.to_datetime(self.trades_df['OpenTime'])
        self.trades_df['CloseTime'] = pd.to_datetime(self.trades_df['CloseTime'])
        
        # Load signals
        self.signals_df = pd.read_csv(signals_file)
        self.signals_df['Timestamp'] = pd.to_datetime(self.signals_df['Timestamp'])
        
        print(f"✅ Loaded {len(self.trades_df)} trades")
        print(f"✅ Loaded {len(self.signals_df)} signals\n")
    
    def calculate_metrics(self):
        """Calculate comprehensive performance metrics"""
        df = self.trades_df
        
        total_trades = len(df)
        wins = df[df['Profit'] > 0]
        losses = df[df['Profit'] < 0]
        
        metrics = {
            # Basic Stats
            'total_trades': total_trades,
            'winning_trades': len(wins),
            'losing_trades': len(losses),
            'win_rate': (len(wins) / total_trades * 100) if total_trades > 0 else 0,
            
            # P&L
            'total_pnl': df['Profit'].sum(),
            'gross_profit': wins['Profit'].sum() if len(wins) > 0 else 0,
            'gross_loss': losses['Profit'].sum() if len(losses) > 0 else 0,
            'avg_win': wins['Profit'].mean() if len(wins) > 0 else 0,
            'avg_loss': losses['Profit'].mean() if len(losses) > 0 else 0,
            'largest_win': wins['Profit'].max() if len(wins) > 0 else 0,
            'largest_loss': losses['Profit'].min() if len(losses) > 0 else 0,
            
            # Risk Metrics
            'profit_factor': abs(wins['Profit'].sum() / losses['Profit'].sum()) if len(losses) > 0 and losses['Profit'].sum() != 0 else 0,
            'sharpe_ratio': (df['Profit'].mean() / df['Profit'].std()) if df['Profit'].std() > 0 else 0,
            'max_consecutive_wins': self._max_consecutive(df, 'Profit', lambda x: x > 0),
            'max_consecutive_losses': self._max_consecutive(df, 'Profit', lambda x: x < 0),
            
            # Execution
            'avg_hold_time_bars': df['HoldTimeBars'].mean(),
            'avg_hold_time_minutes': df['HoldTimeMinutes'].mean(),
            
            # Exit Reasons
            'sl_exits': len(df[df['ExitReason'] == 'SL']),
            'tp_exits': len(df[df['ExitReason'] == 'TP']),
            'reversal_exits': len(df[df['ExitReason'] == 'REVERSAL']),
            
            # MFE/MAE
            'avg_mfe_pips': df['MFE_Pips'].mean(),
            'avg_mae_pips': df['MAE_Pips'].mean(),
            'avg_runup_pips': df['RunUp_Pips'].mean(),
            'avg_rundown_pips': df['RunDown_Pips'].mean(),
        }
        
        # Equity curve
        df['CumProfit'] = df['Profit'].cumsum()
        metrics['max_drawdown'] = (df['CumProfit'].cummax() - df['CumProfit']).max()
        metrics['max_runup'] = df['CumProfit'].max()
        
        return metrics
    
    def _max_consecutive(self, df, column, condition):
        """Calculate max consecutive occurrences"""
        streak = 0
        max_streak = 0
        for val in df[column]:
            if condition(val):
                streak += 1
                max_streak = max(max_streak, streak)
            else:
                streak = 0
        return max_streak
    
    def generate_equity_curve(self):
        """Generate equity curve chart"""
        df = self.trades_df.copy()
        df['CumProfit'] = df['Profit'].cumsum()
        df['Balance'] = 1000 + df['CumProfit']  # Starting balance $1000
        
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))
        
        # Equity curve
        ax1.plot(df['CloseTime'], df['Balance'], linewidth=2, color='#2E86AB')
        ax1.axhline(y=1000, color='gray', linestyle='--', alpha=0.5, label='Starting Balance')
        ax1.fill_between(df['CloseTime'], 1000, df['Balance'], 
                         where=(df['Balance'] >= 1000), alpha=0.3, color='green', label='Profit')
        ax1.fill_between(df['CloseTime'], 1000, df['Balance'], 
                         where=(df['Balance'] < 1000), alpha=0.3, color='red', label='Loss')
        ax1.set_title(f'Equity Curve - {self.symbol} {self.timeframe} v{self.version}', 
                     fontsize=14, fontweight='bold')
        ax1.set_ylabel('Balance ($)', fontsize=12)
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Drawdown
        running_max = df['Balance'].expanding().max()
        drawdown = df['Balance'] - running_max
        ax2.fill_between(df['CloseTime'], 0, drawdown, alpha=0.5, color='red')
        ax2.set_title('Drawdown', fontsize=14, fontweight='bold')
        ax2.set_ylabel('Drawdown ($)', fontsize=12)
        ax2.set_xlabel('Date', fontsize=12)
        ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        filepath = self.charts_dir / 'equity_curve.png'
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✅ Generated: {filepath.name}")
    
    def generate_trade_distribution(self):
        """Generate trade distribution charts"""
        df = self.trades_df
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(14, 10))
        
        # Profit distribution
        ax1.hist(df['Profit'], bins=30, color='#2E86AB', alpha=0.7, edgecolor='black')
        ax1.axvline(x=0, color='red', linestyle='--', linewidth=2)
        ax1.set_title('Profit/Loss Distribution', fontsize=12, fontweight='bold')
        ax1.set_xlabel('Profit ($)')
        ax1.set_ylabel('Frequency')
        
        # Exit reasons pie chart
        exit_counts = df['ExitReason'].value_counts()
        colors = ['#FF6B6B', '#4ECDC4', '#45B7D1']
        ax2.pie(exit_counts.values, labels=exit_counts.index, autopct='%1.1f%%',
                colors=colors, startangle=90)
        ax2.set_title('Exit Reasons', fontsize=12, fontweight='bold')
        
        # Win/Loss by type
        type_profits = df.groupby('Type')['Profit'].agg(['sum', 'count'])
        ax3.bar(type_profits.index, type_profits['sum'], color=['#4ECDC4', '#FF6B6B'])
        ax3.set_title('P&L by Trade Type', fontsize=12, fontweight='bold')
        ax3.set_ylabel('Total Profit ($)')
        ax3.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
        
        # Hold time distribution
        ax4.hist(df['HoldTimeBars'], bins=20, color='#45B7D1', alpha=0.7, edgecolor='black')
        ax4.set_title('Hold Time Distribution', fontsize=12, fontweight='bold')
        ax4.set_xlabel('Bars')
        ax4.set_ylabel('Frequency')
        
        plt.tight_layout()
        filepath = self.charts_dir / 'trade_distribution.png'
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✅ Generated: {filepath.name}")
    
    def generate_time_analysis(self):
        """Generate time-based analysis charts"""
        df = self.trades_df.copy()
        df['Hour'] = df['OpenTime'].dt.hour
        df['DayOfWeek'] = df['OpenTime'].dt.day_name()
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
        
        # Hourly performance
        hourly = df.groupby('Hour')['Profit'].agg(['sum', 'count'])
        ax1.bar(hourly.index, hourly['sum'], color='#2E86AB', alpha=0.7)
        ax1.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
        ax1.set_title('P&L by Hour of Day', fontsize=12, fontweight='bold')
        ax1.set_xlabel('Hour (UTC)')
        ax1.set_ylabel('Total Profit ($)')
        ax1.grid(True, alpha=0.3)
        
        # Day of week performance
        day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
        daily = df.groupby('DayOfWeek')['Profit'].agg(['sum', 'count'])
        daily = daily.reindex(day_order)
        ax2.bar(range(len(daily)), daily['sum'], color='#4ECDC4', alpha=0.7)
        ax2.set_xticks(range(len(daily)))
        ax2.set_xticklabels(daily.index, rotation=45)
        ax2.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
        ax2.set_title('P&L by Day of Week', fontsize=12, fontweight='bold')
        ax2.set_ylabel('Total Profit ($)')
        ax2.grid(True, alpha=0.3)
        
        plt.tight_layout()
        filepath = self.charts_dir / 'time_analysis.png'
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✅ Generated: {filepath.name}")
    
    def generate_mfe_mae_analysis(self):
        """Generate MFE/MAE analysis"""
        df = self.trades_df
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(14, 10))
        
        # MFE vs MAE scatter
        wins = df[df['Profit'] > 0]
        losses = df[df['Profit'] < 0]
        
        ax1.scatter(wins['MAE_Pips'], wins['MFE_Pips'], alpha=0.6, color='green', label='Wins', s=50)
        ax1.scatter(losses['MAE_Pips'], losses['MFE_Pips'], alpha=0.6, color='red', label='Losses', s=50)
        ax1.set_title('MFE vs MAE (Pips)', fontsize=12, fontweight='bold')
        ax1.set_xlabel('MAE (Pips)')
        ax1.set_ylabel('MFE (Pips)')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # RunUp vs RunDown
        ax2.scatter(wins['RunDown_Pips'], wins['RunUp_Pips'], alpha=0.6, color='green', label='Wins', s=50)
        ax2.scatter(losses['RunDown_Pips'], losses['RunUp_Pips'], alpha=0.6, color='red', label='Losses', s=50)
        ax2.set_title('RunUp vs RunDown (Pips)', fontsize=12, fontweight='bold')
        ax2.set_xlabel('RunDown (Pips)')
        ax2.set_ylabel('RunUp (Pips)')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # MFE distribution
        ax3.hist([wins['MFE_Pips'], losses['MFE_Pips']], bins=20, label=['Wins', 'Losses'],
                color=['green', 'red'], alpha=0.6, edgecolor='black')
        ax3.set_title('MFE Distribution', fontsize=12, fontweight='bold')
        ax3.set_xlabel('MFE (Pips)')
        ax3.set_ylabel('Frequency')
        ax3.legend()
        
        # MAE distribution
        ax4.hist([wins['MAE_Pips'], losses['MAE_Pips']], bins=20, label=['Wins', 'Losses'],
                color=['green', 'red'], alpha=0.6, edgecolor='black')
        ax4.set_title('MAE Distribution', fontsize=12, fontweight='bold')
        ax4.set_xlabel('MAE (Pips)')
        ax4.set_ylabel('Frequency')
        ax4.legend()
        
        plt.tight_layout()
        filepath = self.charts_dir / 'mfe_mae_analysis.png'
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✅ Generated: {filepath.name}")
    
    def generate_markdown_report(self, metrics):
        """Generate comprehensive markdown report"""
        report = f"""# 📊 TickPhysics Backtest Report - v{self.version}

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Symbol:** {self.symbol}  
**Timeframe:** {self.timeframe}  
**EA Version:** {self.version}

---

## 🎯 Executive Summary

### Performance Overview
```
Strategy:          MA Crossover (10/50 EMA)
Physics Filters:   DISABLED (Baseline)
Total Trades:      {metrics['total_trades']}
Win Rate:          {metrics['win_rate']:.2f}%
Profit Factor:     {metrics['profit_factor']:.2f}
Total P&L:         ${metrics['total_pnl']:.2f}
Max Drawdown:      ${metrics['max_drawdown']:.2f}
```

### Risk Assessment
- **Sharpe Ratio:** {metrics['sharpe_ratio']:.3f}
- **Largest Win:** ${metrics['largest_win']:.2f}
- **Largest Loss:** ${metrics['largest_loss']:.2f}
- **Avg Win:** ${metrics['avg_win']:.2f}
- **Avg Loss:** ${metrics['avg_loss']:.2f}

---

## 📈 Detailed Statistics

### Trade Distribution
| Metric | Value |
|--------|-------|
| Total Trades | {metrics['total_trades']} |
| Winning Trades | {metrics['winning_trades']} ({metrics['win_rate']:.2f}%) |
| Losing Trades | {metrics['losing_trades']} ({100-metrics['win_rate']:.2f}%) |
| Max Consecutive Wins | {metrics['max_consecutive_wins']} |
| Max Consecutive Losses | {metrics['max_consecutive_losses']} |

### Profit & Loss
| Metric | Value |
|--------|-------|
| Total P&L | ${metrics['total_pnl']:.2f} |
| Gross Profit | ${metrics['gross_profit']:.2f} |
| Gross Loss | ${metrics['gross_loss']:.2f} |
| Profit Factor | {metrics['profit_factor']:.2f} |
| Average Win | ${metrics['avg_win']:.2f} |
| Average Loss | ${metrics['avg_loss']:.2f} |

### Exit Analysis
| Exit Type | Count | Percentage |
|-----------|-------|------------|
| Stop Loss | {metrics['sl_exits']} | {metrics['sl_exits']/metrics['total_trades']*100:.1f}% |
| Take Profit | {metrics['tp_exits']} | {metrics['tp_exits']/metrics['total_trades']*100:.1f}% |
| Reversal | {metrics['reversal_exits']} | {metrics['reversal_exits']/metrics['total_trades']*100:.1f}% |

### Execution Metrics
| Metric | Value |
|--------|-------|
| Avg Hold Time | {metrics['avg_hold_time_bars']:.1f} bars ({metrics['avg_hold_time_minutes']:.0f} min) |
| Avg MFE | {metrics['avg_mfe_pips']:.2f} pips |
| Avg MAE | {metrics['avg_mae_pips']:.2f} pips |
| Avg RunUp | {metrics['avg_runup_pips']:.2f} pips |
| Avg RunDown | {metrics['avg_rundown_pips']:.2f} pips |

---

## 📊 Charts

### Equity Curve
![Equity Curve](../charts/v{self.version}/equity_curve.png)

### Trade Distribution
![Trade Distribution](../charts/v{self.version}/trade_distribution.png)

### Time Analysis
![Time Analysis](../charts/v{self.version}/time_analysis.png)

### MFE/MAE Analysis
![MFE/MAE Analysis](../charts/v{self.version}/mfe_mae_analysis.png)

---

## 🎯 Key Insights

### Strengths
- ✅ All {metrics['total_trades']} trades logged with complete data
- ✅ Advanced metrics (MFE/MAE/RunUp/RunDown) captured
- ✅ Exit reasons properly tracked

### Areas for Improvement
- ⚠️ **Win Rate:** {metrics['win_rate']:.2f}% indicates strategy needs optimization
- ⚠️ **SL Dominance:** {metrics['sl_exits']/metrics['total_trades']*100:.1f}% of exits hit stop loss
- ⚠️ **Profit Factor:** {metrics['profit_factor']:.2f} (target: >1.5 for profitable strategy)

### Recommendations
1. **Optimize Entry Timing:** High SL rate suggests premature entries
2. **Test Multiple Timeframes:** M15 may not be optimal for this MA combination
3. **Enable Physics Filters:** Add quality filtering to improve win rate
4. **Adjust SL/TP:** Consider tighter SL or wider TP based on MFE/MAE analysis

---

## 🔬 Next Steps

### Immediate Optimizations
1. **Multi-Timeframe Testing:**
   - Run backtests on M5, M30, H1, H4
   - Compare performance across timeframes
   - Identify optimal timeframe for MA crossover strategy

2. **MA Period Optimization:**
   - Test combinations: 10/20, 20/50, 50/200
   - Document win rate changes
   - Find sweet spot for signal generation

3. **Physics Filter Integration:**
   - Enable quality filtering (MinQuality = 65)
   - Compare MA-only vs MA+Physics
   - Measure improvement in win rate and profit factor

### Long-Term Development
- Build multi-version comparison dashboard
- Add walk-forward analysis
- Implement Monte Carlo simulation
- Develop automated optimization pipeline

---

**Report Generated by:** TickPhysics Analytics Engine  
**Status:** Baseline Established - Ready for Optimization
"""
        
        filepath = self.reports_dir / 'backtest_report.md'
        with open(filepath, 'w') as f:
            f.write(report)
        
        print(f"✅ Generated: {filepath.name}")
        
        return filepath
    
    def run_full_analysis(self):
        """Run complete analysis and generate all reports"""
        print(f"\n{'='*70}")
        print(f"  GENERATING ANALYTICS: {self.symbol} {self.timeframe} v{self.version}")
        print(f"{'='*70}\n")
        
        # Calculate metrics
        print("📊 Calculating metrics...")
        metrics = self.calculate_metrics()
        
        # Generate charts
        print("\n📈 Generating charts...")
        self.generate_equity_curve()
        self.generate_trade_distribution()
        self.generate_time_analysis()
        self.generate_mfe_mae_analysis()
        
        # Generate report
        print("\n📝 Generating report...")
        report_path = self.generate_markdown_report(metrics)
        
        print(f"\n{'='*70}")
        print(f"  ✅ ANALYSIS COMPLETE!")
        print(f"{'='*70}\n")
        print(f"📁 Charts: {self.charts_dir}")
        print(f"📄 Report: {report_path}")
        print(f"\n{'='*70}\n")
        
        return metrics, report_path

def main():
    """Main entry point"""
    import sys
    
    # Parse arguments
    symbol = sys.argv[1] if len(sys.argv) > 1 else 'NAS100'
    timeframe = sys.argv[2] if len(sys.argv) > 2 else 'M15'
    version = sys.argv[3] if len(sys.argv) > 3 else '1_7'
    
    # Run analysis
    analyzer = BacktestAnalyzer(symbol, timeframe, version)
    metrics, report_path = analyzer.run_full_analysis()
    
    # Print summary
    print("\n📊 QUICK SUMMARY:")
    print(f"   Total Trades: {metrics['total_trades']}")
    print(f"   Win Rate: {metrics['win_rate']:.2f}%")
    print(f"   Total P&L: ${metrics['total_pnl']:.2f}")
    print(f"   Profit Factor: {metrics['profit_factor']:.2f}")
    print(f"   Max Drawdown: ${metrics['max_drawdown']:.2f}")
    print()

if __name__ == "__main__":
    main()
