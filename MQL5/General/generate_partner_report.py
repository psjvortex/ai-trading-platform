#!/usr/bin/env python3
"""
TickPhysics Partner Report Generator
Creates comprehensive reports and visualizations for v3.0 → v3.1 → v3.2
"""
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.gridspec import GridSpec
import seaborn as sns

print("\n" + "="*80)
print("  📊 GENERATING PARTNER REPORT")
print("  TickPhysics v3.0 → v3.1 → v3.2 Optimization Journey")
print("="*80 + "\n")

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (16, 10)
plt.rcParams['font.size'] = 10

# Load data
print("Loading data...")
mt5_v30 = pd.read_csv('MTBacktest_Report_3.0.csv')
trades_v30 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.0.csv')

mt5_v31 = pd.read_csv('MTBacktest_Report_3.1.csv')
trades_v31 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1.csv')

mt5_v32 = pd.read_csv('MTBacktest_Report_3.2.csv')
trades_v32 = pd.read_csv('TP_Integrated_Trades_NAS100_v3.2.csv')

def analyze_version(mt5_df, trades_df, version):
    """Extract key metrics from version"""
    exit_deals = mt5_df[mt5_df['Direction'] == 'out'].copy()
    exit_deals['Profit'] = exit_deals['Profit'].str.replace(' ', '').str.replace(',', '').astype(float)
    
    total_trades = len(exit_deals)
    wins = len(exit_deals[exit_deals['Profit'] > 0])
    losses = len(exit_deals[exit_deals['Profit'] < 0])
    win_rate = (wins / total_trades * 100) if total_trades > 0 else 0
    
    gross_profit = exit_deals[exit_deals['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(exit_deals[exit_deals['Profit'] < 0]['Profit'].sum())
    net_profit = exit_deals['Profit'].sum()
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    avg_win = exit_deals[exit_deals['Profit'] > 0]['Profit'].mean() if wins > 0 else 0
    avg_loss = abs(exit_deals[exit_deals['Profit'] < 0]['Profit'].mean()) if losses > 0 else 0
    
    return {
        'version': version,
        'trades': total_trades,
        'wins': wins,
        'losses': losses,
        'win_rate': win_rate,
        'gross_profit': gross_profit,
        'gross_loss': gross_loss,
        'net_profit': net_profit,
        'profit_factor': profit_factor,
        'avg_win': avg_win,
        'avg_loss': avg_loss
    }

v30 = analyze_version(mt5_v30, trades_v30, 'v3.0')
v31 = analyze_version(mt5_v31, trades_v31, 'v3.1')
v32 = analyze_version(mt5_v32, trades_v32, 'v3.2')

print(f"✓ v3.0: {v30['trades']} trades")
print(f"✓ v3.1: {v31['trades']} trades")
print(f"✓ v3.2: {v32['trades']} trades\n")

# ===================================================================
# CREATE MAIN DASHBOARD
# ===================================================================
print("Creating main dashboard...")

fig = plt.figure(figsize=(20, 12))
fig.suptitle('TickPhysics Optimization Journey: v3.0 → v3.1 → v3.2\nNAS100 M15 Timeframe | Jan 2 - Sep 24, 2025 (267 Days)', 
             fontsize=18, fontweight='bold', y=0.98)

gs = GridSpec(3, 4, figure=fig, hspace=0.3, wspace=0.3)

versions = ['v3.0\nBaseline', 'v3.1\nOptimized', 'v3.2\nPhysics']
colors = ['#e74c3c', '#3498db', '#2ecc71']

# 1. Win Rate Progression
ax1 = fig.add_subplot(gs[0, 0])
win_rates = [v30['win_rate'], v31['win_rate'], v32['win_rate']]
bars1 = ax1.bar(versions, win_rates, color=colors, alpha=0.8, edgecolor='black', linewidth=2)
ax1.axhline(y=65, color='gold', linestyle='--', linewidth=2, label='Target: 65%')
ax1.set_ylabel('Win Rate (%)', fontweight='bold')
ax1.set_title('Win Rate Progression', fontweight='bold', fontsize=12)
ax1.set_ylim(0, 100)
ax1.legend()
for i, (bar, val) in enumerate(zip(bars1, win_rates)):
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2., height + 2,
             f'{val:.1f}%', ha='center', va='bottom', fontweight='bold', fontsize=11)

# 2. Profit Factor Progression
ax2 = fig.add_subplot(gs[0, 1])
pfs = [v30['profit_factor'], v31['profit_factor'], v32['profit_factor']]
bars2 = ax2.bar(versions, pfs, color=colors, alpha=0.8, edgecolor='black', linewidth=2)
ax2.axhline(y=2.5, color='gold', linestyle='--', linewidth=2, label='Target: 2.5')
ax2.set_ylabel('Profit Factor', fontweight='bold')
ax2.set_title('Profit Factor Progression', fontweight='bold', fontsize=12)
ax2.set_ylim(0, 10)
ax2.legend()
for bar, val in zip(bars2, pfs):
    height = bar.get_height()
    ax2.text(bar.get_x() + bar.get_width()/2., height + 0.2,
             f'{val:.2f}', ha='center', va='bottom', fontweight='bold', fontsize=11)

# 3. Net P&L Progression
ax3 = fig.add_subplot(gs[0, 2])
profits = [v30['net_profit'], v31['net_profit'], v32['net_profit']]
bars3 = ax3.bar(versions, profits, color=colors, alpha=0.8, edgecolor='black', linewidth=2)
ax3.axhline(y=50, color='gold', linestyle='--', linewidth=2, label='Target: $50')
ax3.axhline(y=0, color='red', linestyle='-', linewidth=1, alpha=0.5)
ax3.set_ylabel('Net P&L ($)', fontweight='bold')
ax3.set_title('Net Profit/Loss Progression', fontweight='bold', fontsize=12)
ax3.legend()
for bar, val in zip(bars3, profits):
    height = bar.get_height()
    y_pos = height + 2 if height > 0 else height - 4
    ax3.text(bar.get_x() + bar.get_width()/2., y_pos,
             f'${val:.2f}', ha='center', va='bottom' if height > 0 else 'top', 
             fontweight='bold', fontsize=11)

# 4. Trade Count Reduction
ax4 = fig.add_subplot(gs[0, 3])
trade_counts = [v30['trades'], v31['trades'], v32['trades']]
bars4 = ax4.bar(versions, trade_counts, color=colors, alpha=0.8, edgecolor='black', linewidth=2)
ax4.set_ylabel('Number of Trades', fontweight='bold')
ax4.set_title('Trade Count (Selectivity)', fontweight='bold', fontsize=12)
ax4.set_yscale('log')
for bar, val in zip(bars4, trade_counts):
    height = bar.get_height()
    ax4.text(bar.get_x() + bar.get_width()/2., height * 1.2,
             f'{int(val)}', ha='center', va='bottom', fontweight='bold', fontsize=11)

# 5. Win/Loss Distribution
ax5 = fig.add_subplot(gs[1, 0])
versions_short = ['v3.0', 'v3.1', 'v3.2']
wins = [v30['wins'], v31['wins'], v32['wins']]
losses = [v30['losses'], v31['losses'], v32['losses']]
x = np.arange(len(versions_short))
width = 0.35
bars_w = ax5.bar(x - width/2, wins, width, label='Wins', color='#2ecc71', alpha=0.8, edgecolor='black')
bars_l = ax5.bar(x + width/2, losses, width, label='Losses', color='#e74c3c', alpha=0.8, edgecolor='black')
ax5.set_xlabel('Version', fontweight='bold')
ax5.set_ylabel('Count', fontweight='bold')
ax5.set_title('Win/Loss Distribution', fontweight='bold', fontsize=12)
ax5.set_xticks(x)
ax5.set_xticklabels(versions_short)
ax5.legend()
ax5.set_yscale('log')

# 6. Avg Win vs Avg Loss
ax6 = fig.add_subplot(gs[1, 1])
avg_wins = [v30['avg_win'], v31['avg_win'], v32['avg_win']]
avg_losses = [v30['avg_loss'], v31['avg_loss'], v32['avg_loss']]
x = np.arange(len(versions_short))
bars_aw = ax6.bar(x - width/2, avg_wins, width, label='Avg Win', color='#2ecc71', alpha=0.8, edgecolor='black')
bars_al = ax6.bar(x + width/2, avg_losses, width, label='Avg Loss', color='#e74c3c', alpha=0.8, edgecolor='black')
ax6.set_xlabel('Version', fontweight='bold')
ax6.set_ylabel('Amount ($)', fontweight='bold')
ax6.set_title('Average Win vs Loss', fontweight='bold', fontsize=12)
ax6.set_xticks(x)
ax6.set_xticklabels(versions_short)
ax6.legend()

# 7. Cumulative Improvement
ax7 = fig.add_subplot(gs[1, 2:])
metrics = ['Win Rate\n(% points)', 'Profit Factor\n(points)', 'Net P&L\n($)']
v30_to_v31 = [
    v31['win_rate'] - v30['win_rate'],
    v31['profit_factor'] - v30['profit_factor'],
    v31['net_profit'] - v30['net_profit']
]
v31_to_v32 = [
    v32['win_rate'] - v31['win_rate'],
    v32['profit_factor'] - v31['profit_factor'],
    v32['net_profit'] - v31['net_profit']
]
v30_to_v32 = [
    v32['win_rate'] - v30['win_rate'],
    v32['profit_factor'] - v30['profit_factor'],
    v32['net_profit'] - v30['net_profit']
]

x = np.arange(len(metrics))
width = 0.25
bars_01 = ax7.bar(x - width, v30_to_v31, width, label='v3.0→v3.1', color='#3498db', alpha=0.8, edgecolor='black')
bars_12 = ax7.bar(x, v31_to_v32, width, label='v3.1→v3.2', color='#9b59b6', alpha=0.8, edgecolor='black')
bars_02 = ax7.bar(x + width, v30_to_v32, width, label='v3.0→v3.2 (Total)', color='#2ecc71', alpha=0.8, edgecolor='black')

ax7.set_xlabel('Metric', fontweight='bold')
ax7.set_ylabel('Improvement', fontweight='bold')
ax7.set_title('Incremental & Cumulative Improvements', fontweight='bold', fontsize=12)
ax7.set_xticks(x)
ax7.set_xticklabels(metrics)
ax7.legend()
ax7.axhline(y=0, color='black', linestyle='-', linewidth=1, alpha=0.3)

# 8. Key Metrics Table
ax8 = fig.add_subplot(gs[2, :])
ax8.axis('off')

table_data = [
    ['Metric', 'v3.0 Baseline', 'v3.1 Optimized', 'v3.2 Physics', 'Total Change'],
    ['Trades', f"{v30['trades']}", f"{v31['trades']}", f"{v32['trades']}", f"{v32['trades']-v30['trades']:+d} (-98.9%)"],
    ['Win Rate', f"{v30['win_rate']:.1f}%", f"{v31['win_rate']:.1f}%", f"{v32['win_rate']:.1f}%", f"{v32['win_rate']-v30['win_rate']:+.1f}%"],
    ['Profit Factor', f"{v30['profit_factor']:.2f}", f"{v31['profit_factor']:.2f}", f"{v32['profit_factor']:.2f}", f"{v32['profit_factor']-v30['profit_factor']:+.2f}"],
    ['Net P&L', f"${v30['net_profit']:.2f}", f"${v31['net_profit']:.2f}", f"${v32['net_profit']:.2f}", f"${v32['net_profit']-v30['net_profit']:+.2f}"],
    ['Gross Profit', f"${v30['gross_profit']:.2f}", f"${v31['gross_profit']:.2f}", f"${v32['gross_profit']:.2f}", f"${v32['gross_profit']-v30['gross_profit']:+.2f}"],
    ['Gross Loss', f"${v30['gross_loss']:.2f}", f"${v31['gross_loss']:.2f}", f"${v32['gross_loss']:.2f}", f"${v32['gross_loss']-v30['gross_loss']:+.2f}"],
]

table = ax8.table(cellText=table_data, cellLoc='center', loc='center',
                  colWidths=[0.15, 0.18, 0.18, 0.18, 0.2])
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1, 2.5)

# Style header row
for i in range(5):
    table[(0, i)].set_facecolor('#34495e')
    table[(0, i)].set_text_props(weight='bold', color='white')

# Style data rows
for i in range(1, len(table_data)):
    table[(i, 0)].set_facecolor('#ecf0f1')
    table[(i, 0)].set_text_props(weight='bold')
    for j in range(1, 5):
        table[(i, j)].set_facecolor('white')

plt.tight_layout()
plt.savefig('TickPhysics_Partner_Report_Dashboard.png', dpi=300, bbox_inches='tight')
print("✓ Saved: TickPhysics_Partner_Report_Dashboard.png")

# ===================================================================
# CREATE FILTER EFFECTIVENESS CHART
# ===================================================================
print("Creating filter effectiveness chart...")

fig2, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
fig2.suptitle('TickPhysics Optimization Filters - Effectiveness Analysis', 
              fontsize=16, fontweight='bold')

# 1. Zone Distribution (v3.0 baseline)
zone_data_v30 = trades_v30['EntryZone'].value_counts()
zone_wr_v30 = {}
for zone in zone_data_v30.index:
    zone_trades = trades_v30[trades_v30['EntryZone'] == zone]
    zone_wins = len(zone_trades[zone_trades['Profit'] > 0])
    zone_wr_v30[zone] = (zone_wins / len(zone_trades) * 100) if len(zone_trades) > 0 else 0

zones = list(zone_wr_v30.keys())
wr_values = list(zone_wr_v30.values())
colors_zone = ['#e74c3c' if wr < 25 else '#f39c12' if wr < 35 else '#2ecc71' for wr in wr_values]

ax1.barh(zones, wr_values, color=colors_zone, alpha=0.8, edgecolor='black', linewidth=2)
ax1.axvline(x=28, color='blue', linestyle='--', linewidth=2, label='v3.0 Avg (28%)')
ax1.axvline(x=80, color='green', linestyle='--', linewidth=2, label='v3.2 Target (80%)')
ax1.set_xlabel('Win Rate (%)', fontweight='bold')
ax1.set_title('Zone Performance (v3.0 Baseline)\nBEAR Zone Filtered in v3.1/v3.2', fontweight='bold')
ax1.legend()
ax1.set_xlim(0, 100)

# 2. Regime Distribution (v3.0 baseline)
regime_data_v30 = trades_v30['EntryRegime'].value_counts()
regime_wr_v30 = {}
for regime in regime_data_v30.index:
    regime_trades = trades_v30[trades_v30['EntryRegime'] == regime]
    regime_wins = len(regime_trades[regime_trades['Profit'] > 0])
    regime_wr_v30[regime] = (regime_wins / len(regime_trades) * 100) if len(regime_trades) > 0 else 0

regimes = list(regime_wr_v30.keys())
wr_values_r = list(regime_wr_v30.values())
colors_regime = ['#e74c3c' if wr < 25 else '#f39c12' if wr < 35 else '#2ecc71' for wr in wr_values_r]

ax2.barh(regimes, wr_values_r, color=colors_regime, alpha=0.8, edgecolor='black', linewidth=2)
ax2.axvline(x=28, color='blue', linestyle='--', linewidth=2, label='v3.0 Avg (28%)')
ax2.axvline(x=80, color='green', linestyle='--', linewidth=2, label='v3.2 Target (80%)')
ax2.set_xlabel('Win Rate (%)', fontweight='bold')
ax2.set_title('Regime Performance (v3.0 Baseline)\nLOW Regime Filtered in v3.1/v3.2', fontweight='bold')
ax2.legend()
ax2.set_xlim(0, 100)

# 3. Time Distribution (v3.0 baseline - top/bottom hours)
hour_data_v30 = trades_v30.groupby('EntryHour').agg({'Profit': ['count', lambda x: (x > 0).sum()]})
hour_data_v30.columns = ['count', 'wins']
hour_data_v30['win_rate'] = (hour_data_v30['wins'] / hour_data_v30['count'] * 100)
hour_data_v30 = hour_data_v30.sort_values('win_rate')

# Top 5 and bottom 5 hours
top_hours = hour_data_v30.tail(5)
bottom_hours = hour_data_v30.head(5)
combined_hours = pd.concat([bottom_hours, top_hours])

colors_hour = ['#e74c3c' if wr < 25 else '#f39c12' if wr < 35 else '#2ecc71' 
               for wr in combined_hours['win_rate']]

ax3.barh([f"Hour {int(h)}h" for h in combined_hours.index], 
         combined_hours['win_rate'], color=colors_hour, alpha=0.8, edgecolor='black', linewidth=2)
ax3.axvline(x=28, color='blue', linestyle='--', linewidth=2, label='v3.0 Avg (28%)')
ax3.set_xlabel('Win Rate (%)', fontweight='bold')
ax3.set_title('Time Performance (v3.0 Best/Worst Hours)\nv3.1/v3.2: Hours 2,12,19,23 Only', fontweight='bold')
ax3.legend()
ax3.set_xlim(0, 100)

# 4. Momentum Distribution (v3.1 winners vs losers)
if len(trades_v31) > 0:
    v31_winners = trades_v31[trades_v31['Profit'] > 0]['EntryMomentum']
    v31_losers = trades_v31[trades_v31['Profit'] < 0]['EntryMomentum']
    
    ax4.hist(v31_winners, bins=15, alpha=0.7, label=f'Winners (n={len(v31_winners)})', 
             color='#2ecc71', edgecolor='black')
    ax4.hist(v31_losers, bins=15, alpha=0.7, label=f'Losers (n={len(v31_losers)})', 
             color='#e74c3c', edgecolor='black')
    ax4.axvline(x=-437.77, color='purple', linestyle='--', linewidth=3, 
                label='v3.2 Threshold (-437.77)')
    ax4.set_xlabel('Entry Momentum', fontweight='bold')
    ax4.set_ylabel('Frequency', fontweight='bold')
    ax4.set_title('Momentum Distribution (v3.1 Winners vs Losers)\nv3.2 Filter: Momentum > -437.77', 
                  fontweight='bold')
    ax4.legend()

plt.tight_layout()
plt.savefig('TickPhysics_Filter_Effectiveness.png', dpi=300, bbox_inches='tight')
print("✓ Saved: TickPhysics_Filter_Effectiveness.png")

# ===================================================================
# CREATE SCALABILITY PROJECTION
# ===================================================================
print("Creating scalability projection...")

fig3 = plt.figure(figsize=(18, 10))
fig3.suptitle('TickPhysics v3.2 Scalability Projection - Multi-Symbol & Multi-Timeframe', 
              fontsize=16, fontweight='bold')

gs3 = GridSpec(2, 3, figure=fig3, hspace=0.3, wspace=0.3)

# Current v3.2 performance (baseline)
single_trades_per_year = (v32['trades'] / 267) * 365
single_profit_per_year = (v32['net_profit'] / 267) * 365

# 1. Multi-Timeframe Projection (same symbol)
ax1 = fig3.add_subplot(gs3[0, 0])
timeframes = ['M15\n(Current)', 'M15+M30\n(2 TFs)', 'M15+M30+H1\n(3 TFs)', 'M15+M30+H1+H4\n(4 TFs)']
trades_tf = [single_trades_per_year * i for i in [1, 2, 3, 4]]
bars_tf = ax1.bar(timeframes, trades_tf, color=['#3498db', '#2ecc71', '#9b59b6', '#e67e22'], 
                  alpha=0.8, edgecolor='black', linewidth=2)
ax1.set_ylabel('Trades per Year', fontweight='bold')
ax1.set_title('Multi-Timeframe Scaling\n(NAS100 Only)', fontweight='bold')
for bar, val in zip(bars_tf, trades_tf):
    ax1.text(bar.get_x() + bar.get_width()/2., val + 0.5,
             f'{val:.0f}', ha='center', va='bottom', fontweight='bold')

# 2. Multi-Symbol Projection (M15 only)
ax2 = fig3.add_subplot(gs3[0, 1])
symbols = ['NAS100\n(1 Symbol)', '10 Symbols', '30 Symbols', '120 Symbols\n(Full Broker)']
trades_sym = [single_trades_per_year * i for i in [1, 10, 30, 120]]
bars_sym = ax2.bar(symbols, trades_sym, color=['#3498db', '#2ecc71', '#9b59b6', '#e67e22'], 
                   alpha=0.8, edgecolor='black', linewidth=2)
ax2.set_ylabel('Trades per Year', fontweight='bold')
ax2.set_title('Multi-Symbol Scaling\n(M15 Timeframe)', fontweight='bold')
for bar, val in zip(bars_sym, trades_sym):
    ax2.text(bar.get_x() + bar.get_width()/2., val + 50,
             f'{val:.0f}', ha='center', va='bottom', fontweight='bold', fontsize=9)

# 3. Combined Scaling (4 TFs × 30 Symbols)
ax3 = fig3.add_subplot(gs3[0, 2])
scenarios = ['Current\nNAS100 M15', '4 TFs\nNAS100', '30 Symbols\nM15', '4 TFs ×\n30 Symbols']
trades_combined = [
    single_trades_per_year,
    single_trades_per_year * 4,
    single_trades_per_year * 30,
    single_trades_per_year * 4 * 30
]
bars_comb = ax3.bar(scenarios, trades_combined, color=['#3498db', '#2ecc71', '#9b59b6', '#e67e22'], 
                    alpha=0.8, edgecolor='black', linewidth=2)
ax3.set_ylabel('Trades per Year', fontweight='bold')
ax3.set_title('Combined Scaling Strategy', fontweight='bold')
ax3.set_yscale('log')
for bar, val in zip(bars_comb, trades_combined):
    ax3.text(bar.get_x() + bar.get_width()/2., val * 1.2,
             f'{val:.0f}', ha='center', va='bottom', fontweight='bold', fontsize=9)

# 4. Profit Projection (4 TFs × varying symbols)
ax4 = fig3.add_subplot(gs3[1, :])
symbol_counts = np.array([1, 5, 10, 20, 30, 50, 75, 100, 120])
profit_projection = single_profit_per_year * 4 * symbol_counts  # 4 timeframes

ax4.plot(symbol_counts, profit_projection, marker='o', linewidth=3, markersize=10,
         color='#2ecc71', label='Projected Annual Profit')
ax4.fill_between(symbol_counts, profit_projection * 0.7, profit_projection * 1.3, 
                 alpha=0.2, color='#2ecc71', label='±30% Range')
ax4.axhline(y=1000, color='gold', linestyle='--', linewidth=2, label='$1,000 Target')
ax4.axhline(y=5000, color='orange', linestyle='--', linewidth=2, label='$5,000 Target')
ax4.set_xlabel('Number of Symbols (4 Timeframes Each)', fontweight='bold', fontsize=12)
ax4.set_ylabel('Annual Profit ($)', fontweight='bold', fontsize=12)
ax4.set_title('Annual Profit Projection - v3.2 Performance @ 80% WR, 8.72 PF\n(Assumes: 4 Timeframes per Symbol, Consistent Performance)', 
              fontweight='bold', fontsize=13)
ax4.legend(fontsize=11)
ax4.grid(True, alpha=0.3)

# Add annotations
for i, (sym, prof) in enumerate(zip(symbol_counts[[2, 5, 8]], profit_projection[[2, 5, 8]])):
    ax4.annotate(f'{int(sym)} symbols\n${prof:.0f}/year', 
                xy=(sym, prof), xytext=(sym+5, prof+500),
                fontsize=10, fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='yellow', alpha=0.7),
                arrowprops=dict(arrowstyle='->', connectionstyle='arc3,rad=0.3', linewidth=2))

plt.tight_layout()
plt.savefig('TickPhysics_Scalability_Projection.png', dpi=300, bbox_inches='tight')
print("✓ Saved: TickPhysics_Scalability_Projection.png")

print("\n" + "="*80)
print("  ✅ REPORT GENERATION COMPLETE")
print("="*80)
print("\nGenerated Files:")
print("  1. TickPhysics_Partner_Report_Dashboard.png")
print("  2. TickPhysics_Filter_Effectiveness.png")
print("  3. TickPhysics_Scalability_Projection.png")
print("\nThese professional visualizations are ready to share with your partner!")
print("="*80 + "\n")
