#!/usr/bin/env python3
"""
Analyze v2.5 trades to find optimization opportunities for v2.6
Extract patterns from wins vs losses to improve physics filters
"""
import csv
import pandas as pd
from pathlib import Path
from datetime import datetime

print("\n" + "="*100)
print("  🔬 V2.5 DEEP DIVE ANALYSIS - Finding Patterns for v2.6 Optimization")
print("="*100 + "\n")

# Load v2.5 MT5 report (we'll extract what we can)
MT5_REPORT = Path("/Users/patjohnston/Desktop/MT5 Backtest CSV's/MTBacktest_Report_2.5.csv")

print("📂 Loading v2.5 backtest data...\n")

# Parse MT5 report
trades = []
with open(MT5_REPORT, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row.get('Deal') and row.get('Direction') == 'out':
            profit_str = row.get('Profit', '0').replace(' ', '').replace(',', '')
            profit = float(profit_str) if profit_str else 0
            
            # Parse timestamp
            time_str = row.get('Time', '')
            dt = datetime.strptime(time_str, '%Y.%m.%d %H:%M:%S') if time_str else None
            
            trades.append({
                'deal': row['Deal'],
                'time': time_str,
                'datetime': dt,
                'type': row.get('Type', ''),
                'volume': float(row.get('Volume', '0').replace(',', '')),
                'price': float(row.get('Price', '0').replace(' ', '').replace(',', '')),
                'profit': profit,
                'balance': float(row.get('Balance', '0').replace(' ', '').replace(',', '')),
                'hour': dt.hour if dt else None,
                'day_of_week': dt.weekday() if dt else None,  # 0=Monday, 6=Sunday
            })

df = pd.DataFrame(trades)
print(f"✅ Loaded {len(df)} trades from MT5 report\n")

# Separate wins and losses
wins = df[df['profit'] > 0]
losses = df[df['profit'] <= 0]

print("="*100)
print("  📊 WIN vs LOSS COMPARISON")
print("="*100 + "\n")

print(f"Total Trades: {len(df)}")
print(f"Wins:         {len(wins)} ({len(wins)/len(df)*100:.1f}%)")
print(f"Losses:       {len(losses)} ({len(losses)/len(df)*100:.1f}%)")
print(f"\nAvg Win:  ${wins['profit'].mean():.2f}")
print(f"Avg Loss: ${losses['profit'].mean():.2f}")
print(f"Win/Loss Ratio: {abs(wins['profit'].mean() / losses['profit'].mean()):.2f}x")

print("\n" + "="*100)
print("  ⏰ TIME-OF-DAY ANALYSIS")
print("="*100 + "\n")

# Analyze by hour
print("Performance by Hour (UTC):")
print(f"{'Hour':<10} {'Total':<10} {'Wins':<10} {'Losses':<10} {'Win Rate':<12} {'Avg P&L':<12}")
print("-" * 70)

for hour in range(24):
    hour_trades = df[df['hour'] == hour]
    if len(hour_trades) > 0:
        hour_wins = len(hour_trades[hour_trades['profit'] > 0])
        hour_losses = len(hour_trades[hour_trades['profit'] <= 0])
        hour_wr = (hour_wins / len(hour_trades) * 100)
        hour_pnl = hour_trades['profit'].mean()
        
        status = "✅" if hour_wr > 40 else "⚠️" if hour_wr > 30 else "❌"
        print(f"{hour:02d}:00 {status:<4} {len(hour_trades):<10} {hour_wins:<10} {hour_losses:<10} {hour_wr:<11.1f}% ${hour_pnl:<11.2f}")

# Find best and worst hours
hour_performance = []
for hour in range(24):
    hour_trades = df[df['hour'] == hour]
    if len(hour_trades) >= 3:  # Minimum sample size
        hour_wins = len(hour_trades[hour_trades['profit'] > 0])
        hour_wr = (hour_wins / len(hour_trades) * 100)
        hour_pnl = hour_trades['profit'].mean()
        hour_performance.append({
            'hour': hour,
            'trades': len(hour_trades),
            'win_rate': hour_wr,
            'avg_pnl': hour_pnl
        })

hour_df = pd.DataFrame(hour_performance)

print("\n🏆 Best Trading Hours (Win Rate > 40%):")
best_hours = hour_df[hour_df['win_rate'] > 40].sort_values('win_rate', ascending=False)
if len(best_hours) > 0:
    for _, row in best_hours.iterrows():
        print(f"   {int(row['hour']):02d}:00 - Win Rate: {row['win_rate']:.1f}% | Avg P&L: ${row['avg_pnl']:.2f} | Trades: {int(row['trades'])}")
else:
    print("   None found (consider lowering threshold)")

print("\n⚠️  Worst Trading Hours (Win Rate < 30%):")
worst_hours = hour_df[hour_df['win_rate'] < 30].sort_values('win_rate')
if len(worst_hours) > 0:
    for _, row in worst_hours.iterrows():
        print(f"   {int(row['hour']):02d}:00 - Win Rate: {row['win_rate']:.1f}% | Avg P&L: ${row['avg_pnl']:.2f} | Trades: {int(row['trades'])}")
else:
    print("   None found")

print("\n" + "="*100)
print("  📅 DAY-OF-WEEK ANALYSIS")
print("="*100 + "\n")

day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

print("Performance by Day of Week:")
print(f"{'Day':<12} {'Total':<10} {'Wins':<10} {'Losses':<10} {'Win Rate':<12} {'Avg P&L':<12}")
print("-" * 70)

for day in range(7):
    day_trades = df[df['day_of_week'] == day]
    if len(day_trades) > 0:
        day_wins = len(day_trades[day_trades['profit'] > 0])
        day_losses = len(day_trades[day_trades['profit'] <= 0])
        day_wr = (day_wins / len(day_trades) * 100)
        day_pnl = day_trades['profit'].mean()
        
        status = "✅" if day_wr > 40 else "⚠️" if day_wr > 30 else "❌"
        print(f"{day_names[day]:<10} {status:<2} {len(day_trades):<10} {day_wins:<10} {day_losses:<10} {day_wr:<11.1f}% ${day_pnl:<11.2f}")

print("\n" + "="*100)
print("  💰 PROFIT DISTRIBUTION ANALYSIS")
print("="*100 + "\n")

# Analyze win/loss sizes
print("Win Distribution:")
win_ranges = [
    (0, 20, 'Small wins ($0-$20)'),
    (20, 50, 'Medium wins ($20-$50)'),
    (50, 100, 'Large wins ($50-$100)'),
    (100, float('inf'), 'Huge wins (>$100)')
]

for min_val, max_val, label in win_ranges:
    range_wins = wins[(wins['profit'] >= min_val) & (wins['profit'] < max_val)]
    count = len(range_wins)
    pct = (count / len(wins) * 100) if len(wins) > 0 else 0
    avg = range_wins['profit'].mean() if count > 0 else 0
    print(f"   {label:<25} {count:>3} ({pct:>5.1f}%) | Avg: ${avg:>6.2f}")

print("\nLoss Distribution:")
loss_ranges = [
    (-20, 0, 'Small losses ($0-$20)'),
    (-50, -20, 'Medium losses ($20-$50)'),
    (-100, -50, 'Large losses ($50-$100)'),
    (-float('inf'), -100, 'Huge losses (>$100)')
]

for min_val, max_val, label in loss_ranges:
    range_losses = losses[(losses['profit'] >= min_val) & (losses['profit'] < max_val)]
    count = len(range_losses)
    pct = (count / len(losses) * 100) if len(losses) > 0 else 0
    avg = range_losses['profit'].mean() if count > 0 else 0
    print(f"   {label:<25} {count:>3} ({pct:>5.1f}%) | Avg: ${avg:>6.2f}")

print("\n" + "="*100)
print("  🎯 OPTIMIZATION RECOMMENDATIONS FOR V2.6")
print("="*100 + "\n")

recommendations = []

# Time-of-day filter
if len(best_hours) > 0:
    best_hour_list = [int(row['hour']) for _, row in best_hours.iterrows()]
    avg_best_wr = best_hours['win_rate'].mean()
    recommendations.append({
        'filter': 'Time-of-Day Filter',
        'action': f'Trade only during high-win-rate hours: {best_hour_list}',
        'expected_impact': f'Win rate could improve from 34.7% to ~{avg_best_wr:.1f}%',
        'implementation': 'Add UseTimeFilter + AllowedHours[] parameter'
    })

if len(worst_hours) > 0:
    worst_hour_list = [int(row['hour']) for _, row in worst_hours.iterrows()]
    recommendations.append({
        'filter': 'Time-of-Day Block',
        'action': f'Avoid trading during hours: {worst_hour_list}',
        'expected_impact': 'Eliminate low-quality setups',
        'implementation': 'Add BlockedHours[] parameter'
    })

# Day-of-week analysis
day_performance = []
for day in range(7):
    day_trades = df[df['day_of_week'] == day]
    if len(day_trades) >= 5:  # Minimum sample
        day_wins = len(day_trades[day_trades['profit'] > 0])
        day_wr = (day_wins / len(day_trades) * 100)
        day_performance.append({
            'day': day,
            'name': day_names[day],
            'win_rate': day_wr,
            'trades': len(day_trades)
        })

day_perf_df = pd.DataFrame(day_performance)
if len(day_perf_df) > 0:
    best_days = day_perf_df[day_perf_df['win_rate'] > 40]
    worst_days = day_perf_df[day_perf_df['win_rate'] < 25]
    
    if len(worst_days) > 0:
        worst_day_names = list(worst_days['name'])
        recommendations.append({
            'filter': 'Day-of-Week Filter',
            'action': f'Avoid trading on: {worst_day_names}',
            'expected_impact': 'Filter out low-performing days',
            'implementation': 'Add AvoidDays[] parameter'
        })

# Current v2.5 performance check
current_wr = 34.7
if current_wr < 40:
    recommendations.append({
        'filter': 'Tighten Physics Quality Threshold',
        'action': 'Increase MinQuality from 65 to 70-75',
        'expected_impact': 'Further reduce noise, target 40%+ win rate',
        'implementation': 'Update MinQuality parameter'
    })

# Print recommendations
print("💡 Recommended Enhancements for v2.6:\n")
for i, rec in enumerate(recommendations, 1):
    print(f"{i}. {rec['filter']}")
    print(f"   Action: {rec['action']}")
    print(f"   Impact: {rec['expected_impact']}")
    print(f"   Code: {rec['implementation']}")
    print()

print("="*100)
print("  📝 V2.6 IMPLEMENTATION PLAN")
print("="*100 + "\n")

print("Based on analysis, v2.6 should include:\n")
print("1. ✅ Keep v2.5 filters (BEAR zone + LOW regime rejection)")
print("2. 🆕 Add time-of-day filter (trade only best hours)")
print("3. 🆕 Add day-of-week filter (avoid worst days)")
print("4. 🆕 Optional: Increase MinQuality threshold to 70")
print()

# Generate specific hour recommendations
if len(hour_df) > 0:
    # Find hours with WR > 40% OR (WR > 35% AND avg_pnl > 5)
    good_hours = hour_df[
        (hour_df['win_rate'] > 40) | 
        ((hour_df['win_rate'] > 35) & (hour_df['avg_pnl'] > 5))
    ].sort_values('win_rate', ascending=False)
    
    if len(good_hours) > 0:
        recommended_hours = sorted([int(h) for h in good_hours['hour']])
        print(f"🕐 Recommended Trading Hours for v2.6: {recommended_hours}")
        print(f"   (Based on WR > 40% or WR > 35% + Avg P&L > $5)\n")
    
    # Find hours to block
    bad_hours = hour_df[hour_df['win_rate'] < 25]
    if len(bad_hours) > 0:
        blocked_hours = sorted([int(h) for h in bad_hours['hour']])
        print(f"🚫 Hours to Block in v2.6: {blocked_hours}")
        print(f"   (Win rate < 25%)\n")

print("="*100)
print("  🚀 NEXT STEPS")
print("="*100 + "\n")

print("1. Create TP_Integrated_EA_Crossover_2_6.mq5 with new filters")
print("2. Add input parameters:")
print("   - UseTimeFilter (bool)")
print("   - AllowedHours (int array)")
print("   - AvoidDays (ENUM_DAY_OF_WEEK array)")
print("   - MinQuality = 70 (increased from 65)")
print("3. Run backtest on same period (Jan-Sep 2025)")
print("4. Compare v2.6 vs v2.5:")
print("   - Target: Win rate 40%+")
print("   - Target: Profit factor > 1.3")
print("   - Prove iterative improvement capability")
print()

# Save detailed analysis
output_file = Path("/Users/patjohnston/ai-trading-platform/MQL5/V2_5_ANALYSIS_FOR_V2_6.md")
with open(output_file, 'w') as f:
    f.write("# v2.5 Analysis for v2.6 Optimization\n\n")
    f.write("## Summary\n\n")
    f.write(f"- **Total Trades:** {len(df)}\n")
    f.write(f"- **Win Rate:** {len(wins)/len(df)*100:.1f}%\n")
    f.write(f"- **Total P&L:** ${df['profit'].sum():.2f}\n\n")
    
    f.write("## Best Trading Hours\n\n")
    if len(best_hours) > 0:
        for _, row in best_hours.iterrows():
            f.write(f"- **{int(row['hour']):02d}:00** - WR: {row['win_rate']:.1f}% | P&L: ${row['avg_pnl']:.2f}\n")
    
    f.write("\n## Worst Trading Hours\n\n")
    if len(worst_hours) > 0:
        for _, row in worst_hours.iterrows():
            f.write(f"- **{int(row['hour']):02d}:00** - WR: {row['win_rate']:.1f}% | P&L: ${row['avg_pnl']:.2f}\n")
    
    f.write("\n## Recommendations for v2.6\n\n")
    for i, rec in enumerate(recommendations, 1):
        f.write(f"{i}. **{rec['filter']}**\n")
        f.write(f"   - {rec['action']}\n")
        f.write(f"   - Expected: {rec['expected_impact']}\n\n")

print(f"📄 Detailed analysis saved to: {output_file.name}\n")
print("="*100 + "\n")
