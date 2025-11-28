#!/usr/bin/env python3
"""
Time Segment Analysis - Day of Week & Time Segment Performance

HYPOTHESIS: Certain days of the week or time segments may consistently 
underperform, and filtering them out could improve overall strategy performance.

Analyzes:
  - Day of Week (Monday-Sunday)
  - Month
  - 15-minute segments (15-001 to 15-096)
  - 30-minute segments (30-001 to 30-048)  
  - 1-hour segments (1h-001 to 1h-024)
  - 2-hour segments (2h-001 to 2h-012)
  - 3-hour segments (3h-001 to 3h-008)
  - 4-hour segments (4h-001 to 4h-006)

Author: Claude AI
Date: 2025-11-28
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, List, Tuple
from collections import defaultdict

# Time segment columns to analyze
TIME_COLUMNS = {
    'IN_CST_Day_OP_01': 'Day of Week',
    'IN_CST_Month_OP_01': 'Month',
    'IN_Segment_15M_OP_01': '15-Min Segment',
    'IN_Segment_30M_OP_01': '30-Min Segment', 
    'IN_Segment_01H_OP_01': '1-Hour Segment',
    'IN_Segment_02H_OP_01': '2-Hour Segment',
    'IN_Segment_03H_OP_01': '3-Hour Segment',
    'IN_Segment_04H_OP_01': '4-Hour Segment',
}


def load_trades(json_path: Path) -> pd.DataFrame:
    """Load trades from processed JSON file."""
    with open(json_path) as f:
        data = json.load(f)
    
    trades = data.get('trades', [])
    if not trades:
        return pd.DataFrame()
    
    df = pd.DataFrame(trades)
    
    # Normalize direction
    df['direction'] = df['Trade_Direction'].map({'Long': 'BUY', 'Short': 'SELL'})
    df['outcome'] = df['Trade_Result'].map({'Win': 'TP', 'Loss': 'SL'})
    df['profit'] = df['EA_Profit']
    
    return df


def analyze_segment(df: pd.DataFrame, column: str, label: str) -> Dict:
    """Analyze performance by segment value."""
    
    if column not in df.columns:
        return None
    
    # Group by segment
    grouped = df.groupby(column).agg({
        'profit': ['sum', 'count', 'mean'],
        'outcome': lambda x: (x == 'TP').sum()
    }).reset_index()
    
    grouped.columns = [column, 'net_profit', 'trade_count', 'avg_profit', 'wins']
    grouped['win_rate'] = grouped['wins'] / grouped['trade_count'] * 100
    grouped['profit_factor'] = grouped.apply(
        lambda row: calculate_pf(df[df[column] == row[column]]['profit']), axis=1
    )
    
    # Sort by net profit
    grouped = grouped.sort_values('net_profit', ascending=True)
    
    return {
        'column': column,
        'label': label,
        'data': grouped,
        'total_segments': len(grouped),
        'losing_segments': len(grouped[grouped['net_profit'] < 0]),
        'winning_segments': len(grouped[grouped['net_profit'] > 0]),
    }


def calculate_pf(profits: pd.Series) -> float:
    """Calculate profit factor from a series of profits."""
    gains = profits[profits > 0].sum()
    losses = abs(profits[profits < 0].sum())
    return gains / losses if losses > 0 else float('inf') if gains > 0 else 0


def find_worst_segments(analysis: Dict, min_trades: int = 10) -> pd.DataFrame:
    """Find segments that are consistently losing."""
    data = analysis['data']
    
    # Filter for segments with enough trades
    significant = data[data['trade_count'] >= min_trades].copy()
    
    # Filter for losing segments
    losers = significant[significant['net_profit'] < 0].sort_values('net_profit')
    
    return losers


def calculate_savings(df: pd.DataFrame, column: str, segments_to_avoid: List[str]) -> Dict:
    """Calculate potential savings from avoiding certain segments."""
    
    if not segments_to_avoid:
        return {'savings': 0, 'trades_avoided': 0}
    
    avoided_trades = df[df[column].isin(segments_to_avoid)]
    remaining_trades = df[~df[column].isin(segments_to_avoid)]
    
    avoided_profit = avoided_trades['profit'].sum()
    remaining_profit = remaining_trades['profit'].sum()
    
    return {
        'segments_avoided': segments_to_avoid,
        'trades_avoided': len(avoided_trades),
        'avoided_profit': avoided_profit,
        'savings': -avoided_profit if avoided_profit < 0 else 0,
        'remaining_trades': len(remaining_trades),
        'remaining_profit': remaining_profit,
        'remaining_win_rate': (remaining_trades['outcome'] == 'TP').mean() * 100 if len(remaining_trades) > 0 else 0
    }


def main():
    print("=" * 80)
    print("TIME SEGMENT ANALYSIS - Day/Hour Performance Patterns")
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
    
    total_trades = len(df)
    total_profit = df['profit'].sum()
    baseline_win_rate = (df['outcome'] == 'TP').mean() * 100
    
    print(f"\nTotal trades loaded: {total_trades}")
    print(f"Baseline Net Profit: ${total_profit:.2f}")
    print(f"Baseline Win Rate: {baseline_win_rate:.1f}%")
    print()
    
    # =========================================================================
    # ANALYSIS BY EACH TIME DIMENSION
    # =========================================================================
    
    all_recommendations = []
    
    for column, label in TIME_COLUMNS.items():
        if column not in df.columns:
            print(f"⚠️  Column {column} not found in data, skipping...")
            continue
            
        print("=" * 80)
        print(f"ANALYSIS: {label} ({column})")
        print("=" * 80)
        
        analysis = analyze_segment(df, column, label)
        if not analysis:
            continue
        
        data = analysis['data']
        
        # Summary stats
        print(f"\nTotal {label} values: {analysis['total_segments']}")
        print(f"  - Winning: {analysis['winning_segments']}")
        print(f"  - Losing: {analysis['losing_segments']}")
        print()
        
        # Show worst performers
        worst = find_worst_segments(analysis, min_trades=10)
        
        if len(worst) > 0:
            print(f"WORST PERFORMING {label.upper()} (min 10 trades):")
            print("-" * 70)
            print(f"{'Segment':<15} {'Trades':>8} {'Win%':>8} {'Net P/L':>12} {'Avg P/L':>10} {'PF':>8}")
            print("-" * 70)
            
            for _, row in worst.head(10).iterrows():
                pf_str = f"{row['profit_factor']:.2f}" if row['profit_factor'] != float('inf') else "∞"
                print(f"{str(row[column]):<15} {int(row['trade_count']):>8} {row['win_rate']:>7.1f}% ${row['net_profit']:>10.2f} ${row['avg_profit']:>9.2f} {pf_str:>8}")
            
            # Calculate potential savings from avoiding worst segments
            # Start with segments that have PF < 0.5 and are significantly losing
            segments_to_avoid = worst[
                (worst['profit_factor'] < 0.8) & 
                (worst['net_profit'] < -100)
            ][column].tolist()
            
            if segments_to_avoid:
                savings = calculate_savings(df, column, segments_to_avoid)
                
                print(f"\n📊 POTENTIAL SAVINGS from avoiding {len(segments_to_avoid)} worst {label}s:")
                print(f"   Segments to avoid: {', '.join(str(s) for s in segments_to_avoid[:5])}{'...' if len(segments_to_avoid) > 5 else ''}")
                print(f"   Trades avoided: {savings['trades_avoided']} ({savings['trades_avoided']/total_trades*100:.1f}%)")
                print(f"   Savings: ${savings['savings']:.2f}")
                print(f"   New net profit: ${savings['remaining_profit']:.2f}")
                print(f"   New win rate: {savings['remaining_win_rate']:.1f}%")
                
                if savings['savings'] > 500:  # Significant savings threshold
                    all_recommendations.append({
                        'dimension': label,
                        'column': column,
                        'avoid': segments_to_avoid,
                        'savings': savings['savings'],
                        'trades_avoided': savings['trades_avoided'],
                        'pct_avoided': savings['trades_avoided']/total_trades*100
                    })
        
        # Show best performers too
        best = data[data['trade_count'] >= 10].sort_values('net_profit', ascending=False).head(5)
        if len(best) > 0:
            print(f"\nBEST PERFORMING {label.upper()} (min 10 trades):")
            print("-" * 70)
            for _, row in best.iterrows():
                pf_str = f"{row['profit_factor']:.2f}" if row['profit_factor'] != float('inf') else "∞"
                print(f"{str(row[column]):<15} {int(row['trade_count']):>8} {row['win_rate']:>7.1f}% ${row['net_profit']:>10.2f} ${row['avg_profit']:>9.2f} {pf_str:>8}")
        
        print()
    
    # =========================================================================
    # COMBINED RECOMMENDATION
    # =========================================================================
    print("=" * 80)
    print("SUMMARY & RECOMMENDATIONS")
    print("=" * 80)
    print()
    
    if all_recommendations:
        all_recommendations.sort(key=lambda x: x['savings'], reverse=True)
        
        total_potential_savings = sum(r['savings'] for r in all_recommendations)
        
        print(f"✅ Found {len(all_recommendations)} time dimensions with significant filter potential")
        print(f"   Total potential savings: ${total_potential_savings:.2f}")
        print()
        
        for rec in all_recommendations:
            print(f"📌 {rec['dimension']}:")
            print(f"   Avoid: {', '.join(str(s) for s in rec['avoid'][:8])}{'...' if len(rec['avoid']) > 8 else ''}")
            print(f"   Savings: ${rec['savings']:.2f} ({rec['trades_avoided']} trades, {rec['pct_avoided']:.1f}%)")
            print()
        
        print("\n✅ RECOMMENDATION: Add time-based filters to EA!")
        print("   Suggested EA inputs:")
        print("   - UseDayOfWeekFilter (bool) + TradeOnMonday...TradeOnSunday")
        print("   - UseTimeSegmentFilter (bool) + allowed segment ranges")
        print("   - UseMonthFilter (bool) + TradeInJanuary...TradeInDecember")
    else:
        print("⚠️  No significant time-based patterns found that would justify filters.")
        print("   Time segment performance appears relatively uniform.")
    
    # =========================================================================
    # DIRECTION-SPECIFIC ANALYSIS
    # =========================================================================
    print("\n" + "=" * 80)
    print("DIRECTION-SPECIFIC DAY ANALYSIS (LONG vs SHORT)")
    print("=" * 80)
    
    for direction in ['BUY', 'SELL']:
        dir_df = df[df['direction'] == direction]
        if len(dir_df) == 0:
            continue
            
        print(f"\n{direction} TRADES - Day of Week Performance:")
        print("-" * 60)
        
        day_col = 'IN_CST_Day_OP_01'
        if day_col in dir_df.columns:
            day_stats = dir_df.groupby(day_col).agg({
                'profit': ['sum', 'count', 'mean'],
                'outcome': lambda x: (x == 'TP').sum()
            }).reset_index()
            day_stats.columns = [day_col, 'net_profit', 'trades', 'avg_profit', 'wins']
            day_stats['win_rate'] = day_stats['wins'] / day_stats['trades'] * 100
            day_stats = day_stats.sort_values('net_profit')
            
            print(f"{'Day':<12} {'Trades':>8} {'Win%':>8} {'Net P/L':>12} {'Avg P/L':>10}")
            print("-" * 60)
            for _, row in day_stats.iterrows():
                color = "🔴" if row['net_profit'] < -100 else "🟢" if row['net_profit'] > 100 else "⚪"
                print(f"{color} {row[day_col]:<10} {int(row['trades']):>8} {row['win_rate']:>7.1f}% ${row['net_profit']:>10.2f} ${row['avg_profit']:>9.2f}")


if __name__ == '__main__':
    main()
