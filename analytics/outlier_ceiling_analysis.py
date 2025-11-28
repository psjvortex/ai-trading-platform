#!/usr/bin/env python3
"""
Outlier Ceiling Analysis - Investigating High Physics Metrics in Losing Trades

HYPOTHESIS: Some losing trades have abnormally HIGH physics metric values at entry,
potentially indicating:
  - Entry at momentum peaks (about to reverse)
  - Snake head spikes / whipsaws
  - Late entry into exhausted moves

GOAL: Determine if adding MAX thresholds (ceilings) could filter out these outlier losses.

Author: Claude AI
Date: 2025-11-28
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass

# Physics metrics to analyze (the ones that have Min thresholds)
# Using actual column names from processed data
PHYSICS_METRICS = [
    'EA_Entry_Quality',           # MinQualityBuy/Sell
    'EA_Entry_PhysicsScore',      # MinPhysicsScoreBuy/Sell  
    'EA_Entry_Speed',             # MinSpeedBuy/Sell
    'EA_Entry_Acceleration',      # MinAccelerationBuy/Sell
    'EA_Entry_Momentum',          # MinMomentumBuy/Sell
    'EA_Entry_SpeedSlope',        # MinSpeedSlopeBuy/Sell
    'EA_Entry_AccelerationSlope', # MinAccelerationSlopeBuy/Sell
    'EA_Entry_MomentumSlope',     # MinMomentumSlopeBuy/Sell
    'EA_Entry_ConfluenceSlope',   # MinConfluenceSlopeBuy/Sell
    'EA_Entry_JerkSlope',         # MinJerkSlopeBuy/Sell
]

@dataclass
class OutlierStats:
    metric: str
    direction: str  # BUY or SELL
    win_mean: float
    win_std: float
    win_p95: float
    loss_mean: float
    loss_std: float
    loss_p95: float
    loss_p99: float
    outlier_loss_count: int  # Losses above win's 95th percentile
    outlier_loss_pct: float
    potential_savings: float  # Sum of profits if these outliers were avoided


def load_trades(json_path: Path) -> pd.DataFrame:
    """Load trades from processed JSON file."""
    with open(json_path) as f:
        data = json.load(f)
    
    trades = data.get('trades', [])
    if not trades:
        return pd.DataFrame()
    
    # Convert to DataFrame directly - it's already flat!
    df = pd.DataFrame(trades)
    
    # Normalize direction: Trade_Direction is "Long" or "Short"
    # Map to BUY/SELL for consistency
    df['direction'] = df['Trade_Direction'].map({'Long': 'BUY', 'Short': 'SELL'})
    
    # Normalize outcome: Trade_Result is "Win" or "Loss"  
    # Map to TP/SL for consistency
    df['outcome'] = df['Trade_Result'].map({'Win': 'TP', 'Loss': 'SL'})
    
    # Use EA_Profit for profit column
    df['profit'] = df['EA_Profit']
    
    return df


def analyze_outliers(df: pd.DataFrame, metric: str, direction: str) -> OutlierStats:
    """Analyze if losses have outlier-high values for a given metric."""
    
    # Filter by direction
    dir_df = df[df['direction'] == direction].copy()
    
    # Get the metric values (use absolute for SELL since they're negative)
    if direction == 'SELL':
        # For SELL, high absolute values indicate strong signals
        dir_df['metric_val'] = dir_df[metric].abs()
    else:
        dir_df['metric_val'] = dir_df[metric]
    
    # Split into wins and losses
    wins = dir_df[dir_df['outcome'] == 'TP']['metric_val'].dropna()
    losses = dir_df[dir_df['outcome'] == 'SL']['metric_val'].dropna()
    
    if len(wins) < 10 or len(losses) < 10:
        return None
    
    # Calculate stats
    win_mean = wins.mean()
    win_std = wins.std()
    win_p95 = wins.quantile(0.95)
    
    loss_mean = losses.mean()
    loss_std = losses.std()
    loss_p95 = losses.quantile(0.95)
    loss_p99 = losses.quantile(0.99)
    
    # Find losses that are above the 95th percentile of WINS
    # These are "suspiciously high" - the metric was stronger than 95% of winning trades
    threshold = win_p95
    
    # Get the original profit values for outlier losses
    outlier_mask = dir_df['metric_val'] > threshold
    loss_mask = dir_df['outcome'] == 'SL'
    outlier_losses = dir_df[outlier_mask & loss_mask]
    
    outlier_count = len(outlier_losses)
    outlier_pct = (outlier_count / len(losses) * 100) if len(losses) > 0 else 0
    potential_savings = outlier_losses['profit'].sum() * -1  # Convert losses to savings
    
    return OutlierStats(
        metric=metric,
        direction=direction,
        win_mean=win_mean,
        win_std=win_std,
        win_p95=win_p95,
        loss_mean=loss_mean,
        loss_std=loss_std,
        loss_p95=loss_p95,
        loss_p99=loss_p99,
        outlier_loss_count=outlier_count,
        outlier_loss_pct=outlier_pct,
        potential_savings=potential_savings
    )


def find_multi_outlier_losses(df: pd.DataFrame, percentile: float = 95) -> pd.DataFrame:
    """Find losses where MULTIPLE metrics are in the high percentile range."""
    
    results = []
    
    for direction in ['BUY', 'SELL']:
        dir_df = df[df['direction'] == direction].copy()
        
        # Calculate percentile thresholds from WINNING trades
        wins = dir_df[dir_df['outcome'] == 'TP']
        
        thresholds = {}
        for metric in PHYSICS_METRICS:
            vals = wins[metric].dropna()
            if len(vals) > 0:
                if direction == 'SELL':
                    # For SELL, use absolute values
                    thresholds[metric] = vals.abs().quantile(percentile / 100)
                else:
                    thresholds[metric] = vals.quantile(percentile / 100)
        
        # For each loss, count how many metrics exceed the threshold
        losses = dir_df[dir_df['outcome'] == 'SL'].copy()
        
        for idx, row in losses.iterrows():
            outlier_count = 0
            outlier_metrics = []
            
            for metric, threshold in thresholds.items():
                val = row[metric]
                if pd.isna(val):
                    continue
                    
                if direction == 'SELL':
                    val = abs(val)
                
                if val > threshold:
                    outlier_count += 1
                    outlier_metrics.append(metric.replace('EA_Entry_', ''))
            
            if outlier_count >= 2:  # At least 2 metrics are outliers
                results.append({
                    'ticket': row.get('IN_Deal', row.get('IN_Trade_ID')),
                    'direction': direction,
                    'profit': row['profit'],
                    'outlier_count': outlier_count,
                    'outlier_metrics': ', '.join(outlier_metrics),
                    'exitReason': row.get('EA_ExitReason', 'Unknown'),
                })
    
    return pd.DataFrame(results)


def main():
    print("=" * 80)
    print("OUTLIER CEILING ANALYSIS - High Physics Metrics in Losing Trades")
    print("=" * 80)
    print()
    
    # Load all baseline files
    data_dir = Path('/Volumes/Vortex_Trading/ai-trading-platform/web/public/data/runs')
    
    all_trades = []
    for json_file in data_dir.glob('BL_*.json'):
        print(f"Loading {json_file.name}...")
        trades_df = load_trades(json_file)
        trades_df['source'] = json_file.stem
        all_trades.append(trades_df)
    
    if not all_trades:
        print("No data files found!")
        return
    
    df = pd.concat(all_trades, ignore_index=True)
    print(f"\nTotal trades loaded: {len(df)}")
    print(f"  - Wins (TP): {len(df[df['outcome'] == 'TP'])}")
    print(f"  - Losses (SL): {len(df[df['outcome'] == 'SL'])}")
    print()
    
    # =========================================================================
    # ANALYSIS 1: Per-Metric Outlier Analysis
    # =========================================================================
    print("=" * 80)
    print("ANALYSIS 1: Per-Metric Outlier Analysis")
    print("Looking for losses where individual metrics are abnormally HIGH")
    print("=" * 80)
    print()
    
    all_stats = []
    
    for metric in PHYSICS_METRICS:
        for direction in ['BUY', 'SELL']:
            stats = analyze_outliers(df, metric, direction)
            if stats:
                all_stats.append(stats)
    
    # Sort by potential savings
    all_stats.sort(key=lambda x: x.potential_savings, reverse=True)
    
    print(f"{'Metric':<25} {'Dir':<5} {'Win μ':>10} {'Win P95':>10} {'Loss P95':>10} {'Outlier#':>8} {'Outlier%':>9} {'Savings$':>12}")
    print("-" * 100)
    
    for s in all_stats:
        metric_short = s.metric.replace('EA_Entry_', '')
        print(f"{metric_short:<25} {s.direction:<5} {s.win_mean:>10.2f} {s.win_p95:>10.2f} {s.loss_p95:>10.2f} {s.outlier_loss_count:>8} {s.outlier_loss_pct:>8.1f}% ${s.potential_savings:>11.2f}")
    
    print()
    
    # =========================================================================
    # ANALYSIS 2: Multi-Metric Outlier Losses
    # =========================================================================
    print("=" * 80)
    print("ANALYSIS 2: Multi-Metric Outlier Losses")
    print("Losses where 2+ metrics exceed the 95th percentile of winning trades")
    print("=" * 80)
    print()
    
    multi_outliers = find_multi_outlier_losses(df, percentile=95)
    
    if len(multi_outliers) > 0:
        print(f"Found {len(multi_outliers)} losses with multiple outlier metrics")
        print(f"Total potential savings: ${multi_outliers['profit'].sum() * -1:.2f}")
        print()
        
        # Group by outlier count
        grouped = multi_outliers.groupby('outlier_count').agg({
            'ticket': 'count',
            'profit': 'sum'
        }).rename(columns={'ticket': 'count', 'profit': 'total_loss'})
        grouped['potential_savings'] = grouped['total_loss'] * -1
        
        print("Breakdown by number of outlier metrics:")
        print(grouped.to_string())
        print()
        
        # Show worst offenders (most outlier metrics)
        print("Top 10 Worst Multi-Outlier Losses:")
        worst = multi_outliers.nlargest(10, 'outlier_count')
        for _, row in worst.iterrows():
            print(f"  Ticket {row['ticket']}: {row['outlier_count']} outlier metrics, ${row['profit']:.2f}")
            print(f"    Outlier metrics: {row['outlier_metrics']}")
    else:
        print("No multi-metric outlier losses found.")
    
    print()
    
    # =========================================================================
    # ANALYSIS 3: Recommended Ceiling Thresholds
    # =========================================================================
    print("=" * 80)
    print("ANALYSIS 3: Recommended Ceiling Thresholds")
    print("Suggested MAX values based on winning trade distributions")
    print("=" * 80)
    print()
    
    print(f"{'Metric':<25} {'Dir':<5} {'Win P95':>12} {'Win P99':>12} {'Suggested Max':>15}")
    print("-" * 80)
    
    for direction in ['BUY', 'SELL']:
        dir_df = df[df['direction'] == direction]
        wins = dir_df[dir_df['outcome'] == 'TP']
        
        for metric in PHYSICS_METRICS:
            vals = wins[metric].dropna()
            if len(vals) < 10:
                continue
            
            if direction == 'SELL':
                vals = vals.abs()
            
            p95 = vals.quantile(0.95)
            p99 = vals.quantile(0.99)
            
            # Suggest max at 99th percentile of wins + 10% buffer
            suggested_max = p99 * 1.10
            
            metric_short = metric.replace('EA_Entry_', '')
            if direction == 'SELL':
                print(f"{metric_short:<25} {direction:<5} {p95:>12.2f} {p99:>12.2f} {-suggested_max:>15.2f}")
            else:
                print(f"{metric_short:<25} {direction:<5} {p95:>12.2f} {p99:>12.2f} {suggested_max:>15.2f}")
    
    print()
    
    # =========================================================================
    # SUMMARY & RECOMMENDATION
    # =========================================================================
    print("=" * 80)
    print("SUMMARY & RECOMMENDATION")
    print("=" * 80)
    print()
    
    total_losses = len(df[df['outcome'] == 'SL'])
    total_loss_amount = df[df['outcome'] == 'SL']['profit'].sum()
    
    if len(multi_outliers) > 0:
        outlier_loss_pct = len(multi_outliers) / total_losses * 100
        outlier_savings = multi_outliers['profit'].sum() * -1
        savings_pct = (outlier_savings / abs(total_loss_amount)) * 100
        
        print(f"Total losses: {total_losses} (${abs(total_loss_amount):.2f})")
        print(f"Multi-outlier losses: {len(multi_outliers)} ({outlier_loss_pct:.1f}% of losses)")
        print(f"Potential savings: ${outlier_savings:.2f} ({savings_pct:.1f}% of total loss amount)")
        print()
        
        if outlier_savings > 100:
            print("✅ RECOMMENDATION: Adding ceiling filters (Max thresholds) shows promise!")
            print("   Consider implementing MaxSpeedBuy, MaxAccelerationBuy, etc.")
            print("   Start with the metrics showing highest potential savings above.")
        else:
            print("⚠️  Limited benefit from ceiling filters based on this data.")
    else:
        print("No significant outlier pattern detected in losses.")


if __name__ == '__main__':
    main()
