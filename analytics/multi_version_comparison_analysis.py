#!/usr/bin/env python3
"""
Multi-Version EA Comparison Analysis
Compares performance across EA versions: v4.1.3, v4.1.4, v4.1.5

Purpose:
- Track performance evolution across versions
- Validate optimization improvements
- Identify version-specific strengths/weaknesses
- Guide future development decisions

Author: AI Trading Platform Team
Date: November 12, 2025
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple
import json

# Set style
plt.style.use('dark_background')
sns.set_palette("husl")

class MultiVersionAnalyzer:
    """Analyzes and compares multiple EA versions"""
    
    def __init__(self, backtest_dir: Path, output_dir: Path):
        self.backtest_dir = Path(backtest_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Version configuration
        self.versions = {
            'v4.1.3': {
                'name': 'v4.1.3 (Baseline)',
                'color': '#FF6B6B',
                'description': 'Original correlation-based weights',
                'features': ['Physics Score', 'Confluence Filter']
            },
            'v4.1.4': {
                'name': 'v4.1.4 (Multi-Asset)',
                'color': '#4ECDC4',
                'description': 'Speed-prioritized weights + Q3 threshold',
                'features': ['Physics Score', 'Confluence 100%', 'Speed Priority']
            },
            'v4.1.5': {
                'name': 'v4.1.5 (Slope)',
                'color': '#95E1D3',
                'description': 'Directional momentum confirmation',
                'features': ['Physics Score', 'Confluence 100%', 'Speed Priority', 'Slope Filters']
            }
        }
        
        self.results = {}
        self.comparison_data = None
        
    def load_version_data(self, version: str, file_pattern: str = None) -> pd.DataFrame:
        """Load all CSV files for a specific version"""
        print(f"\n📂 Loading {version} data...")
        
        # Auto-detect files based on version naming
        if file_pattern is None:
            if version == 'v4.1.3':
                pattern = 'v4.1.3'
            elif version == 'v4.1.4':
                # Handle both v4.13 and v4.1.4 naming
                pattern = 'v4.13'
            elif version == 'v4.1.5':
                pattern = 'v4.15'
            else:
                pattern = version
        else:
            pattern = file_pattern
        
        # Find all matching files (combine pattern matching)
        all_files = list(self.backtest_dir.glob('*.csv'))
        trade_files = [f for f in all_files if 'Trades' in f.name and pattern.replace('*', '') in f.name]
        signal_files = [f for f in all_files if 'Signals' in f.name and pattern.replace('*', '') in f.name]
        
        print(f"   Found {len(trade_files)} trade files")
        print(f"   Found {len(signal_files)} signal files")
        
        if not trade_files:
            print(f"   ⚠️  No files found for {version}")
            return None
        
        # Load and combine all trade files
        all_trades = []
        for file in trade_files:
            try:
                df = pd.read_csv(file)
                # Extract asset and timeframe from filename
                parts = file.stem.split('_')
                asset = parts[2] if len(parts) > 2 else 'Unknown'
                timeframe = parts[3] if len(parts) > 3 else 'Unknown'
                
                df['Asset'] = asset
                df['Timeframe'] = timeframe
                df['Version'] = version
                df['SourceFile'] = file.name
                all_trades.append(df)
                print(f"   ✅ {asset} {timeframe}: {len(df)} trades")
            except Exception as e:
                print(f"   ❌ Error loading {file.name}: {e}")
        
        if not all_trades:
            return None
        
        combined = pd.concat(all_trades, ignore_index=True)
        print(f"   📊 Total trades for {version}: {len(combined)}")
        
        return combined
    
    def calculate_metrics(self, df: pd.DataFrame, version: str) -> Dict:
        """Calculate comprehensive metrics for a version"""
        if df is None or len(df) == 0:
            return None
        
        metrics = {
            'version': version,
            'total_trades': len(df),
            'total_wins': len(df[df['Profit'] > 0]),
            'total_losses': len(df[df['Profit'] <= 0]),
            'win_rate': len(df[df['Profit'] > 0]) / len(df) * 100,
            'total_profit': df['Profit'].sum(),
            'avg_win': df[df['Profit'] > 0]['Profit'].mean() if len(df[df['Profit'] > 0]) > 0 else 0,
            'avg_loss': df[df['Profit'] <= 0]['Profit'].mean() if len(df[df['Profit'] <= 0]) > 0 else 0,
            'profit_factor': abs(df[df['Profit'] > 0]['Profit'].sum() / df[df['Profit'] <= 0]['Profit'].sum()) if len(df[df['Profit'] <= 0]) > 0 else 0,
            'max_drawdown': df['Profit'].cumsum().min() if len(df) > 0 else 0,
            'sharpe_ratio': df['Profit'].mean() / df['Profit'].std() if df['Profit'].std() > 0 else 0,
        }
        
        # Per-asset metrics
        metrics['by_asset'] = {}
        for asset in df['Asset'].unique():
            asset_df = df[df['Asset'] == asset]
            metrics['by_asset'][asset] = {
                'trades': len(asset_df),
                'win_rate': len(asset_df[asset_df['Profit'] > 0]) / len(asset_df) * 100,
                'profit': asset_df['Profit'].sum(),
                'avg_profit': asset_df['Profit'].mean()
            }
        
        # Per-timeframe metrics
        metrics['by_timeframe'] = {}
        for tf in df['Timeframe'].unique():
            tf_df = df[df['Timeframe'] == tf]
            metrics['by_timeframe'][tf] = {
                'trades': len(tf_df),
                'win_rate': len(tf_df[tf_df['Profit'] > 0]) / len(tf_df) * 100,
                'profit': tf_df['Profit'].sum()
            }
        
        return metrics
    
    def create_version_comparison_table(self):
        """Create comprehensive comparison table"""
        print("\n📊 Creating version comparison table...")
        
        comparison = []
        for version, data in self.results.items():
            if data is None:
                continue
            
            comparison.append({
                'Version': self.versions[version]['name'],
                'Description': self.versions[version]['description'],
                'Total Trades': f"{data['total_trades']:,}",
                'Win Rate (%)': f"{data['win_rate']:.1f}%",
                'Total Profit': f"${data['total_profit']:,.2f}",
                'Profit Factor': f"{data['profit_factor']:.2f}",
                'Avg Win': f"${data['avg_win']:.2f}",
                'Avg Loss': f"${data['avg_loss']:.2f}",
                'Sharpe Ratio': f"{data['sharpe_ratio']:.3f}",
                'Max DD': f"${data['max_drawdown']:,.2f}"
            })
        
        df_comparison = pd.DataFrame(comparison)
        
        # Save to CSV
        output_file = self.output_dir / 'version_comparison_table.csv'
        df_comparison.to_csv(output_file, index=False)
        print(f"   ✅ Saved to {output_file}")
        
        return df_comparison
    
    def plot_win_rate_comparison(self):
        """Compare win rates across versions"""
        print("\n📈 Creating win rate comparison chart...")
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Overall win rate comparison
        versions_list = []
        win_rates = []
        colors = []
        
        for version, data in self.results.items():
            if data is None:
                continue
            versions_list.append(self.versions[version]['name'])
            win_rates.append(data['win_rate'])
            colors.append(self.versions[version]['color'])
        
        bars1 = ax1.bar(versions_list, win_rates, color=colors, alpha=0.8, edgecolor='white', linewidth=2)
        ax1.set_ylabel('Win Rate (%)', fontsize=12, fontweight='bold')
        ax1.set_title('Overall Win Rate Comparison', fontsize=14, fontweight='bold', pad=20)
        ax1.grid(axis='y', alpha=0.3, linestyle='--')
        ax1.set_ylim(0, 100)
        
        # Add value labels on bars
        for bar in bars1:
            height = bar.get_height()
            ax1.text(bar.get_x() + bar.get_width()/2., height,
                    f'{height:.1f}%',
                    ha='center', va='bottom', fontweight='bold', fontsize=11)
        
        # Win rate improvement chart
        if len(win_rates) > 1:
            improvements = []
            labels = []
            for i in range(1, len(win_rates)):
                improvement = win_rates[i] - win_rates[0]
                improvements.append(improvement)
                labels.append(f"{versions_list[i]}\nvs {versions_list[0]}")
            
            bar_colors = ['green' if x > 0 else 'red' for x in improvements]
            bars2 = ax2.bar(labels, improvements, color=bar_colors, alpha=0.7, edgecolor='white', linewidth=2)
            ax2.set_ylabel('Win Rate Improvement (%)', fontsize=12, fontweight='bold')
            ax2.set_title('Win Rate Improvement vs Baseline', fontsize=14, fontweight='bold', pad=20)
            ax2.axhline(y=0, color='white', linestyle='-', linewidth=1, alpha=0.5)
            ax2.grid(axis='y', alpha=0.3, linestyle='--')
            
            for bar in bars2:
                height = bar.get_height()
                ax2.text(bar.get_x() + bar.get_width()/2., height,
                        f'{height:+.1f}%',
                        ha='center', va='bottom' if height > 0 else 'top',
                        fontweight='bold', fontsize=11)
        
        plt.tight_layout()
        output_file = self.output_dir / 'win_rate_comparison.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        print(f"   ✅ Saved to {output_file}")
    
    def plot_profit_comparison(self):
        """Compare profitability across versions"""
        print("\n💰 Creating profit comparison chart...")
        
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        versions_list = []
        total_profits = []
        profit_factors = []
        sharpe_ratios = []
        colors = []
        
        for version, data in self.results.items():
            if data is None:
                continue
            versions_list.append(self.versions[version]['name'])
            total_profits.append(data['total_profit'])
            profit_factors.append(data['profit_factor'])
            sharpe_ratios.append(data['sharpe_ratio'])
            colors.append(self.versions[version]['color'])
        
        # Total Profit
        bars1 = axes[0, 0].bar(versions_list, total_profits, color=colors, alpha=0.8, edgecolor='white', linewidth=2)
        axes[0, 0].set_ylabel('Total Profit ($)', fontsize=12, fontweight='bold')
        axes[0, 0].set_title('Total Profit Comparison', fontsize=14, fontweight='bold', pad=20)
        axes[0, 0].grid(axis='y', alpha=0.3, linestyle='--')
        axes[0, 0].axhline(y=0, color='white', linestyle='-', linewidth=1, alpha=0.5)
        
        for bar in bars1:
            height = bar.get_height()
            axes[0, 0].text(bar.get_x() + bar.get_width()/2., height,
                           f'${height:,.0f}',
                           ha='center', va='bottom' if height > 0 else 'top',
                           fontweight='bold', fontsize=10)
        
        # Profit Factor
        bars2 = axes[0, 1].bar(versions_list, profit_factors, color=colors, alpha=0.8, edgecolor='white', linewidth=2)
        axes[0, 1].set_ylabel('Profit Factor', fontsize=12, fontweight='bold')
        axes[0, 1].set_title('Profit Factor Comparison', fontsize=14, fontweight='bold', pad=20)
        axes[0, 1].grid(axis='y', alpha=0.3, linestyle='--')
        axes[0, 1].axhline(y=1.0, color='yellow', linestyle='--', linewidth=2, alpha=0.5, label='Break-even')
        axes[0, 1].legend()
        
        for bar in bars2:
            height = bar.get_height()
            axes[0, 1].text(bar.get_x() + bar.get_width()/2., height,
                           f'{height:.2f}',
                           ha='center', va='bottom',
                           fontweight='bold', fontsize=10)
        
        # Sharpe Ratio
        bars3 = axes[1, 0].bar(versions_list, sharpe_ratios, color=colors, alpha=0.8, edgecolor='white', linewidth=2)
        axes[1, 0].set_ylabel('Sharpe Ratio', fontsize=12, fontweight='bold')
        axes[1, 0].set_title('Risk-Adjusted Returns (Sharpe Ratio)', fontsize=14, fontweight='bold', pad=20)
        axes[1, 0].grid(axis='y', alpha=0.3, linestyle='--')
        axes[1, 0].axhline(y=0, color='white', linestyle='-', linewidth=1, alpha=0.5)
        
        for bar in bars3:
            height = bar.get_height()
            axes[1, 0].text(bar.get_x() + bar.get_width()/2., height,
                           f'{height:.3f}',
                           ha='center', va='bottom' if height > 0 else 'top',
                           fontweight='bold', fontsize=10)
        
        # Trade Count
        trade_counts = [self.results[v]['total_trades'] for v in self.results if self.results[v] is not None]
        bars4 = axes[1, 1].bar(versions_list, trade_counts, color=colors, alpha=0.8, edgecolor='white', linewidth=2)
        axes[1, 1].set_ylabel('Number of Trades', fontsize=12, fontweight='bold')
        axes[1, 1].set_title('Trade Count Comparison', fontsize=14, fontweight='bold', pad=20)
        axes[1, 1].grid(axis='y', alpha=0.3, linestyle='--')
        
        for bar in bars4:
            height = bar.get_height()
            axes[1, 1].text(bar.get_x() + bar.get_width()/2., height,
                           f'{int(height):,}',
                           ha='center', va='bottom',
                           fontweight='bold', fontsize=10)
        
        plt.tight_layout()
        output_file = self.output_dir / 'profit_comparison.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        print(f"   ✅ Saved to {output_file}")
    
    def plot_asset_performance_comparison(self):
        """Compare performance across assets for each version"""
        print("\n🌍 Creating asset performance comparison...")
        
        # Collect all unique assets
        all_assets = set()
        for version, data in self.results.items():
            if data and 'by_asset' in data:
                all_assets.update(data['by_asset'].keys())
        
        assets_list = sorted(list(all_assets))
        
        fig, axes = plt.subplots(2, 1, figsize=(16, 10))
        
        # Win Rate by Asset
        x = np.arange(len(assets_list))
        width = 0.25
        
        for i, (version, data) in enumerate(self.results.items()):
            if data is None:
                continue
            
            win_rates = []
            for asset in assets_list:
                if asset in data['by_asset']:
                    win_rates.append(data['by_asset'][asset]['win_rate'])
                else:
                    win_rates.append(0)
            
            offset = width * (i - 1)
            axes[0].bar(x + offset, win_rates, width, 
                       label=self.versions[version]['name'],
                       color=self.versions[version]['color'],
                       alpha=0.8, edgecolor='white', linewidth=1)
        
        axes[0].set_xlabel('Asset', fontsize=12, fontweight='bold')
        axes[0].set_ylabel('Win Rate (%)', fontsize=12, fontweight='bold')
        axes[0].set_title('Win Rate by Asset - Version Comparison', fontsize=14, fontweight='bold', pad=20)
        axes[0].set_xticks(x)
        axes[0].set_xticklabels(assets_list)
        axes[0].legend()
        axes[0].grid(axis='y', alpha=0.3, linestyle='--')
        axes[0].set_ylim(0, 100)
        
        # Trade Count by Asset
        for i, (version, data) in enumerate(self.results.items()):
            if data is None:
                continue
            
            trade_counts = []
            for asset in assets_list:
                if asset in data['by_asset']:
                    trade_counts.append(data['by_asset'][asset]['trades'])
                else:
                    trade_counts.append(0)
            
            offset = width * (i - 1)
            axes[1].bar(x + offset, trade_counts, width,
                       label=self.versions[version]['name'],
                       color=self.versions[version]['color'],
                       alpha=0.8, edgecolor='white', linewidth=1)
        
        axes[1].set_xlabel('Asset', fontsize=12, fontweight='bold')
        axes[1].set_ylabel('Number of Trades', fontsize=12, fontweight='bold')
        axes[1].set_title('Trade Count by Asset - Version Comparison', fontsize=14, fontweight='bold', pad=20)
        axes[1].set_xticks(x)
        axes[1].set_xticklabels(assets_list)
        axes[1].legend()
        axes[1].grid(axis='y', alpha=0.3, linestyle='--')
        
        plt.tight_layout()
        output_file = self.output_dir / 'asset_performance_comparison.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        print(f"   ✅ Saved to {output_file}")
    
    def plot_feature_evolution(self):
        """Show feature evolution across versions"""
        print("\n🔧 Creating feature evolution timeline...")
        
        fig, ax = plt.subplots(figsize=(14, 8))
        
        versions_list = ['v4.1.3', 'v4.1.4', 'v4.1.5']
        all_features = set()
        
        # Collect all features
        for version in versions_list:
            if version in self.versions:
                all_features.update(self.versions[version]['features'])
        
        features_list = sorted(list(all_features))
        
        # Create feature matrix
        feature_matrix = np.zeros((len(features_list), len(versions_list)))
        
        for i, version in enumerate(versions_list):
            if version in self.versions:
                for j, feature in enumerate(features_list):
                    if feature in self.versions[version]['features']:
                        feature_matrix[j, i] = 1
        
        # Plot heatmap
        im = ax.imshow(feature_matrix, cmap='Greens', aspect='auto', alpha=0.8)
        
        # Set ticks
        ax.set_xticks(np.arange(len(versions_list)))
        ax.set_yticks(np.arange(len(features_list)))
        ax.set_xticklabels([self.versions[v]['name'] for v in versions_list])
        ax.set_yticklabels(features_list)
        
        # Add checkmarks
        for i in range(len(features_list)):
            for j in range(len(versions_list)):
                if feature_matrix[i, j] == 1:
                    ax.text(j, i, '✓', ha='center', va='center',
                           color='white', fontsize=20, fontweight='bold')
        
        ax.set_title('Feature Evolution Across Versions', fontsize=14, fontweight='bold', pad=20)
        ax.set_xlabel('EA Version', fontsize=12, fontweight='bold')
        ax.set_ylabel('Features', fontsize=12, fontweight='bold')
        
        plt.tight_layout()
        output_file = self.output_dir / 'feature_evolution.png'
        plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='#1a1a1a')
        plt.close()
        print(f"   ✅ Saved to {output_file}")
    
    def create_executive_dashboard(self):
        """Create HTML dashboard with all visualizations"""
        print("\n📄 Creating executive dashboard...")
        
        # Get statistics
        stats = []
        for version, data in self.results.items():
            if data is None:
                continue
            stats.append({
                'version': self.versions[version]['name'],
                'description': self.versions[version]['description'],
                'trades': data['total_trades'],
                'win_rate': data['win_rate'],
                'profit': data['total_profit'],
                'profit_factor': data['profit_factor']
            })
        
        html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EA Version Comparison Dashboard - v4.1.3 vs v4.1.4 vs v4.1.5</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #e0e0e0;
            padding: 20px;
            line-height: 1.6;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        
        .header {{
            text-align: center;
            padding: 40px 20px;
            background: linear-gradient(135deg, #0f3460 0%, #16213e 100%);
            border-radius: 15px;
            margin-bottom: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }}
        
        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(90deg, #4ECDC4, #95E1D3);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        
        .header p {{
            color: #95E1D3;
            font-size: 1.1em;
        }}
        
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .stat-card {{
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            padding: 25px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }}
        
        .stat-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 12px 24px rgba(78, 205, 196, 0.2);
        }}
        
        .stat-card h3 {{
            color: #4ECDC4;
            margin-bottom: 15px;
            font-size: 1.3em;
        }}
        
        .stat-card .version-desc {{
            color: #95E1D3;
            font-size: 0.9em;
            margin-bottom: 15px;
            font-style: italic;
        }}
        
        .stat-row {{
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }}
        
        .stat-row:last-child {{
            border-bottom: none;
        }}
        
        .stat-label {{
            color: #95E1D3;
        }}
        
        .stat-value {{
            color: #fff;
            font-weight: bold;
        }}
        
        .positive {{
            color: #4ECDC4 !important;
        }}
        
        .negative {{
            color: #FF6B6B !important;
        }}
        
        .section {{
            background: rgba(255, 255, 255, 0.03);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            border: 1px solid rgba(255, 255, 255, 0.1);
        }}
        
        .section h2 {{
            color: #4ECDC4;
            margin-bottom: 20px;
            font-size: 1.8em;
            padding-bottom: 10px;
            border-bottom: 2px solid #4ECDC4;
        }}
        
        .chart-container {{
            margin: 20px 0;
            text-align: center;
        }}
        
        .chart-container img {{
            max-width: 100%;
            height: auto;
            border-radius: 10px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
        }}
        
        .insights {{
            background: linear-gradient(135deg, rgba(78, 205, 196, 0.1), rgba(149, 225, 211, 0.1));
            border-left: 4px solid #4ECDC4;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
        }}
        
        .insights h3 {{
            color: #4ECDC4;
            margin-bottom: 10px;
        }}
        
        .insights ul {{
            margin-left: 20px;
        }}
        
        .insights li {{
            margin: 8px 0;
        }}
        
        .timestamp {{
            text-align: center;
            color: #666;
            margin-top: 40px;
            padding: 20px;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 EA Version Comparison Dashboard</h1>
            <p>Comprehensive Analysis: v4.1.3 (Baseline) → v4.1.4 (Multi-Asset) → v4.1.5 (Slope)</p>
        </div>
        
        <div class="stats-grid">
"""
        
        for stat in stats:
            win_rate_class = 'positive' if stat['win_rate'] > 40 else 'negative'
            profit_class = 'positive' if stat['profit'] > 0 else 'negative'
            pf_class = 'positive' if stat['profit_factor'] > 1.0 else 'negative'
            
            html_content += f"""
            <div class="stat-card">
                <h3>{stat['version']}</h3>
                <div class="version-desc">{stat['description']}</div>
                <div class="stat-row">
                    <span class="stat-label">Total Trades:</span>
                    <span class="stat-value">{stat['trades']:,}</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Win Rate:</span>
                    <span class="stat-value {win_rate_class}">{stat['win_rate']:.1f}%</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Total Profit:</span>
                    <span class="stat-value {profit_class}">${stat['profit']:,.2f}</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Profit Factor:</span>
                    <span class="stat-value {pf_class}">{stat['profit_factor']:.2f}</span>
                </div>
            </div>
"""
        
        html_content += """
        </div>
        
        <div class="section">
            <h2>📊 Performance Comparison</h2>
            <div class="chart-container">
                <img src="win_rate_comparison.png" alt="Win Rate Comparison">
            </div>
            <div class="chart-container">
                <img src="profit_comparison.png" alt="Profit Comparison">
            </div>
        </div>
        
        <div class="section">
            <h2>🌍 Asset-Level Analysis</h2>
            <div class="chart-container">
                <img src="asset_performance_comparison.png" alt="Asset Performance">
            </div>
        </div>
        
        <div class="section">
            <h2>🔧 Feature Evolution</h2>
            <div class="chart-container">
                <img src="feature_evolution.png" alt="Feature Evolution">
            </div>
            
            <div class="insights">
                <h3>Version Highlights:</h3>
                <ul>
                    <li><strong>v4.1.3 (Baseline):</strong> Original correlation-based weights from single-dataset analysis</li>
                    <li><strong>v4.1.4 (Multi-Asset):</strong> Speed-prioritized weights (28%/25%) + Physics Score Q3 threshold (55.0) + Confluence 100% filter</li>
                    <li><strong>v4.1.5 (Slope):</strong> Added directional momentum confirmation via slope analysis (3-bar linear slopes for Speed, Acceleration, Momentum, Jerk)</li>
                </ul>
            </div>
        </div>
        
        <div class="insights">
            <h3>🎯 Key Insights:</h3>
            <ul>
                <li><strong>Trade Count Evolution:</strong> Expect progressive filtering (v4.1.3 → v4.1.4 → v4.1.5) as we add more strict filters</li>
                <li><strong>Win Rate Optimization:</strong> Each version should show improved win rate due to better signal quality filtering</li>
                <li><strong>Slope Impact (v4.1.5):</strong> Directional momentum filters should catch "late" entries where metrics are declining</li>
                <li><strong>Quality vs Quantity:</strong> Fewer trades with higher win rates = better risk-adjusted returns</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>📋 Next Steps</h2>
            <div class="insights">
                <h3>Analysis Workflow:</h3>
                <ul>
                    <li>Complete v4.1.4 backtests on all assets (NAS100, US30, EURUSD, USDJPY, AUDUSD)</li>
                    <li>Compare v4.1.4 against v4.1.3 baseline to validate multi-asset optimizations</li>
                    <li>Run v4.1.5 backtests on same datasets to measure slope filter effectiveness</li>
                    <li>Analyze CSV data to optimize slope thresholds (MinSpeedSlope, MinAccelerationSlope)</li>
                    <li>Create slope effectiveness report showing correlation between slopes and wins</li>
                </ul>
            </div>
        </div>
        
        <div class="timestamp">
            <p>Dashboard Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <p>Analysis Framework: Multi-Version EA Comparison Tool v1.0</p>
        </div>
    </div>
</body>
</html>
"""
        
        output_file = self.output_dir / 'version_comparison_dashboard.html'
        with open(output_file, 'w') as f:
            f.write(html_content)
        
        print(f"   ✅ Saved to {output_file}")
    
    def run_full_analysis(self):
        """Run complete version comparison analysis"""
        print("=" * 80)
        print("🚀 MULTI-VERSION EA COMPARISON ANALYSIS")
        print("=" * 80)
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Backtest Directory: {self.backtest_dir}")
        print(f"Output Directory: {self.output_dir}")
        
        # Load data for each version
        for version in ['v4.1.3', 'v4.1.4', 'v4.1.5']:
            df = self.load_version_data(version)
            if df is not None:
                self.results[version] = self.calculate_metrics(df, version)
            else:
                self.results[version] = None
                print(f"   ⚠️  Skipping {version} (no data found)")
        
        # Create visualizations
        if any(self.results.values()):
            self.create_version_comparison_table()
            self.plot_win_rate_comparison()
            self.plot_profit_comparison()
            self.plot_asset_performance_comparison()
            self.plot_feature_evolution()
            self.create_executive_dashboard()
            
            print("\n" + "=" * 80)
            print("✅ ANALYSIS COMPLETE!")
            print("=" * 80)
            print(f"\n📁 All outputs saved to: {self.output_dir}")
            print("\n📊 Generated Files:")
            print("   • version_comparison_table.csv")
            print("   • win_rate_comparison.png")
            print("   • profit_comparison.png")
            print("   • asset_performance_comparison.png")
            print("   • feature_evolution.png")
            print("   • version_comparison_dashboard.html")
        else:
            print("\n❌ No data available for any version!")


def main():
    """Main execution"""
    # Setup paths
    project_root = Path(__file__).parent.parent
    backtest_dir = project_root / "MQL5" / "Backtest_Reports"
    output_dir = project_root / "analytics" / "version_comparison_output"
    
    print(f"\n📂 Searching for backtest files in: {backtest_dir}")
    print(f"📂 Output directory: {output_dir}\n")
    
    # Run analysis
    analyzer = MultiVersionAnalyzer(backtest_dir, output_dir)
    analyzer.run_full_analysis()
    
    # Open dashboard
    dashboard_file = output_dir / "version_comparison_dashboard.html"
    if dashboard_file.exists():
        print(f"\n🌐 Opening dashboard in browser...")
        import webbrowser
        webbrowser.open(f"file://{dashboard_file.absolute()}")


if __name__ == "__main__":
    main()
