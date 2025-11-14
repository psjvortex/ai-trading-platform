#!/usr/bin/env python3
"""
Multi-Backtest Comparison Tool
Compares baseline vs physics-enhanced versions
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
from pathlib import Path

sns.set_style("darkgrid")

def compare_backtests(*report_files):
    """
    Compare multiple backtest reports
    
    Args:
        *report_files: Paths to JSON report files
    """
    reports = []
    for file in report_files:
        with open(file, 'r') as f:
            report = json.load(f)
            report['file'] = Path(file).stem
            reports.append(report)
    
    # Create comparison dataframe
    comparison_data = []
    for report in reports:
        perf = report.get('performance', {})
        comparison_data.append({
            'Version': report.get('version', 'Unknown'),
            'Strategy': report.get('strategy', 'Unknown'),
            'Total Trades': perf.get('total_trades', 0),
            'Win Rate %': perf.get('win_rate', 0),
            'Wins': perf.get('wins', 0),
            'Losses': perf.get('losses', 0),
            'Avg Win %': perf.get('avg_win_percent', 0),
            'Avg Loss %': perf.get('avg_loss_percent', 0),
            'Profit Factor': perf.get('profit_factor', 0),
            'Total P/L %': perf.get('total_pnl_percent', 0)
        })
    
    df = pd.DataFrame(comparison_data)
    
    # Print comparison table
    print("\n" + "="*100)
    print("BACKTEST COMPARISON")
    print("="*100)
    print(df.to_string(index=False))
    print("="*100)
    
    # Generate comparison charts
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('Backtest Comparison - Baseline vs Physics Enhanced', fontsize=16, fontweight='bold')
    
    # 1. Win Rate Comparison
    ax1 = axes[0, 0]
    ax1.bar(df['Version'], df['Win Rate %'], edgecolor='black', alpha=0.7)
    ax1.set_ylabel('Win Rate (%)')
    ax1.set_title('Win Rate Comparison')
    ax1.axhline(y=50, color='red', linestyle='--', linewidth=1, label='50% baseline')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # 2. Profit Factor Comparison
    ax2 = axes[0, 1]
    ax2.bar(df['Version'], df['Profit Factor'], edgecolor='black', alpha=0.7, color='green')
    ax2.set_ylabel('Profit Factor')
    ax2.set_title('Profit Factor Comparison')
    ax1.axhline(y=1.0, color='red', linestyle='--', linewidth=1, label='Break-even')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. Total P/L Comparison
    ax3 = axes[1, 0]
    colors = ['green' if x > 0 else 'red' for x in df['Total P/L %']]
    ax3.bar(df['Version'], df['Total P/L %'], edgecolor='black', alpha=0.7, color=colors)
    ax3.set_ylabel('Total P/L (%)')
    ax3.set_title('Total Profit/Loss Comparison')
    ax3.axhline(y=0, color='black', linestyle='--', linewidth=1)
    ax3.grid(True, alpha=0.3)
    
    # 4. Risk/Reward Comparison
    ax4 = axes[1, 1]
    x_pos = range(len(df))
    ax4.bar(x_pos, df['Avg Win %'], width=0.4, label='Avg Win', edgecolor='black', alpha=0.7)
    ax4.bar([p + 0.4 for p in x_pos], abs(df['Avg Loss %']), width=0.4, label='Avg Loss', 
            edgecolor='black', alpha=0.7, color='red')
    ax4.set_xticks([p + 0.2 for p in x_pos])
    ax4.set_xticklabels(df['Version'])
    ax4.set_ylabel('Percentage (%)')
    ax4.set_title('Average Win vs Average Loss')
    ax4.legend()
    ax4.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('backtest_comparison.png', dpi=150, bbox_inches='tight')
    print(f"\n📊 Comparison chart saved: backtest_comparison.png")
    plt.show()
    
    return df

if __name__ == "__main__":
    # Example usage - add your report files here
    compare_backtests(
        "baseline_report_v4_0.json",
        # Add more reports as you create them:
        # "physics_entropy_report.json",
        # "physics_confluence_report.json",
        # "physics_combined_report.json"
    )
