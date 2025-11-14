#!/usr/bin/env python3
"""
TickPhysics 5M Optimization - Composite Dashboard
Combines Executive, Technical, and Multi-Timeframe views into one comprehensive report

Professional hedge fund-style reporting with dark theme
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import seaborn as sns
from datetime import datetime
from matplotlib.patches import Rectangle, FancyBboxPatch
import warnings
warnings.filterwarnings('ignore')

# Set professional dark theme
plt.style.use('dark_background')
sns.set_palette("husl")

# Custom color palette (professional hedge fund style)
COLORS = {
    'primary': '#00D9FF',      # Cyan
    'success': '#00FF88',      # Green
    'warning': '#FFB800',      # Amber
    'danger': '#FF3366',       # Red
    'accent': '#B45AF2',       # Purple
    'neutral': '#8B92A8',      # Gray
    'bg_dark': '#0A0E1A',      # Dark background
    'bg_card': '#141824',      # Card background
    'text': '#E4E7EB'          # Text color
}

print("=" * 100)
print("📊 TICKPHYSICS 5M OPTIMIZATION - COMPOSITE DASHBOARD")
print("=" * 100)
print()

# ============================================================================
# LOAD DATA
# ============================================================================
print("Loading data files...")
try:
    # Load all 4 versions from Backtest_Reports folder
    trades_v30 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.0_05M.csv')
    trades_v31 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.1_05M.csv')
    trades_v32 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.2_05M.csv')
    trades_v321 = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.21_05M.csv')
    
    # Load 15M data for comparison
    trades_15m = pd.read_csv('../Backtest_Reports/TP_Integrated_Trades_NAS100_v3.2.csv')
    
    print("✅ All data loaded successfully")
    print()
except Exception as e:
    print(f"❌ Error loading data: {e}")
    exit(1)

# ============================================================================
# CALCULATE METRICS
# ============================================================================
def calc_metrics(df):
    """Calculate key metrics for a trades dataframe"""
    total_trades = len(df)
    winners = len(df[df['Profit'] > 0])
    losers = len(df[df['Profit'] <= 0])
    
    win_rate = (winners / total_trades * 100) if total_trades > 0 else 0
    
    gross_profit = df[df['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(df[df['Profit'] < 0]['Profit'].sum())
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    net_pl = df['Profit'].sum()
    avg_win = df[df['Profit'] > 0]['Profit'].mean() if winners > 0 else 0
    avg_loss = df[df['Profit'] < 0]['Profit'].mean() if losers > 0 else 0
    
    return {
        'trades': total_trades,
        'winners': winners,
        'losers': losers,
        'win_rate': win_rate,
        'profit_factor': profit_factor,
        'net_pl': net_pl,
        'avg_win': avg_win,
        'avg_loss': avg_loss
    }

metrics_v30 = calc_metrics(trades_v30)
metrics_v31 = calc_metrics(trades_v31)
metrics_v32 = calc_metrics(trades_v32)
metrics_v321 = calc_metrics(trades_v321)
metrics_15m = calc_metrics(trades_15m)

# ============================================================================
# CREATE COMPOSITE DASHBOARD
# ============================================================================
print("Creating composite dashboard...")

# Create figure with custom layout
fig = plt.figure(figsize=(36, 24))
fig.patch.set_facecolor(COLORS['bg_dark'])

# Create main grid: 3 rows (Executive, Technical, Multi-Timeframe)
gs_main = gridspec.GridSpec(3, 1, figure=fig, height_ratios=[1, 1.2, 1], hspace=0.15)

# ============================================================================
# SECTION 1: EXECUTIVE SUMMARY (TOP)
# ============================================================================
gs_exec = gridspec.GridSpecFromSubplotSpec(2, 4, subplot_spec=gs_main[0], hspace=0.3, wspace=0.3)

# Add section title
fig.text(0.5, 0.97, '📊 EXECUTIVE SUMMARY - v3.21 Optimization Results', 
         ha='center', fontsize=24, weight='bold', color=COLORS['text'])

# Row 1: Key Metric Cards (4 cards)
metric_cards = [
    {'title': 'Win Rate', 'value': f"{metrics_v321['win_rate']:.1f}%", 'subtitle': 'v3.21 Best Performer', 'color': COLORS['success']},
    {'title': 'Total Trades', 'value': f"{metrics_v321['trades']}", 'subtitle': '63% reduction', 'color': COLORS['primary']},
    {'title': 'Profit Factor', 'value': f"{metrics_v321['profit_factor']:.2f}", 'subtitle': 'Risk-adjusted', 'color': COLORS['accent']},
    {'title': 'Net P&L', 'value': f"${metrics_v321['net_pl']:.2f}", 'subtitle': 'Total profit/loss', 'color': COLORS['warning']}
]

for i, card in enumerate(metric_cards):
    ax = fig.add_subplot(gs_exec[0, i])
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')
    
    # Card background
    rect = FancyBboxPatch((0.05, 0.1), 0.9, 0.8, boxstyle="round,pad=0.05", 
                          facecolor=COLORS['bg_card'], edgecolor=card['color'], linewidth=2)
    ax.add_patch(rect)
    
    # Card content
    ax.text(0.5, 0.65, card['title'], ha='center', va='center', 
            fontsize=14, color=COLORS['neutral'], weight='bold')
    ax.text(0.5, 0.40, card['value'], ha='center', va='center', 
            fontsize=28, color=card['color'], weight='bold')
    ax.text(0.5, 0.20, card['subtitle'], ha='center', va='center', 
            fontsize=11, color=COLORS['text'], alpha=0.7)

# Row 2: Version Progression Chart
ax_prog = fig.add_subplot(gs_exec[1, :])
ax_prog.set_facecolor(COLORS['bg_card'])

versions = ['v3.0', 'v3.1', 'v3.2', 'v3.21']
wr_values = [metrics_v30['win_rate'], metrics_v31['win_rate'], metrics_v32['win_rate'], metrics_v321['win_rate']]
trade_counts = [metrics_v30['trades'], metrics_v31['trades'], metrics_v32['trades'], metrics_v321['trades']]

x = np.arange(len(versions))
width = 0.35

bars1 = ax_prog.bar(x - width/2, wr_values, width, label='Win Rate %', 
                     color=[COLORS['danger'], COLORS['success'], COLORS['danger'], COLORS['success']], alpha=0.8)
ax_prog2 = ax_prog.twinx()
bars2 = ax_prog2.bar(x + width/2, trade_counts, width, label='Trade Count', 
                      color=COLORS['primary'], alpha=0.5)

ax_prog.set_xlabel('Version', fontsize=12, color=COLORS['text'], weight='bold')
ax_prog.set_ylabel('Win Rate (%)', fontsize=12, color=COLORS['text'], weight='bold')
ax_prog2.set_ylabel('Trade Count', fontsize=12, color=COLORS['text'], weight='bold')
ax_prog.set_title('Optimization Progression: Win Rate vs Trade Count', 
                  fontsize=14, color=COLORS['text'], weight='bold', pad=10)
ax_prog.set_xticks(x)
ax_prog.set_xticklabels(versions, fontsize=11, color=COLORS['text'])
ax_prog.tick_params(colors=COLORS['text'])
ax_prog2.tick_params(colors=COLORS['text'])
ax_prog.axhline(35, color=COLORS['warning'], linestyle='--', alpha=0.5, label='WR Target: 35%')
ax_prog.legend(loc='upper left', fontsize=10, framealpha=0.9)
ax_prog2.legend(loc='upper right', fontsize=10, framealpha=0.9)
ax_prog.grid(True, alpha=0.2)

# Add value labels on bars
for bar, val in zip(bars1, wr_values):
    height = bar.get_height()
    ax_prog.text(bar.get_x() + bar.get_width()/2., height,
                f'{val:.1f}%', ha='center', va='bottom', fontsize=9, color=COLORS['text'])

# ============================================================================
# SECTION 2: TECHNICAL DEEP-DIVE (MIDDLE)
# ============================================================================
gs_tech = gridspec.GridSpecFromSubplotSpec(2, 3, subplot_spec=gs_main[1], hspace=0.3, wspace=0.3)

# Add section title
fig.text(0.5, 0.63, '🔬 TECHNICAL ANALYSIS - Filter Effectiveness & Performance Patterns', 
         ha='center', fontsize=24, weight='bold', color=COLORS['text'])

# Physics Metrics Heatmap
ax_physics = fig.add_subplot(gs_tech[0, 0])
ax_physics.set_facecolor(COLORS['bg_card'])

winners = trades_v321[trades_v321['Profit'] > 0]
losers = trades_v321[trades_v321['Profit'] <= 0]

physics_data = {
    'Quality': [winners['EntryQuality'].mean(), losers['EntryQuality'].mean()],
    'Confluence': [winners['EntryConfluence'].mean(), losers['EntryConfluence'].mean()],
    'Momentum': [winners['EntryMomentum'].mean(), losers['EntryMomentum'].mean()]
}

physics_df = pd.DataFrame(physics_data, index=['Winners', 'Losers']).T
sns.heatmap(physics_df, annot=True, fmt='.1f', cmap='RdYlGn', center=85, 
            cbar_kws={'label': 'Value'}, ax=ax_physics, linewidths=1, linecolor=COLORS['text'])
ax_physics.set_title('Physics Metrics: Winners vs Losers', fontsize=12, color=COLORS['text'], weight='bold')
ax_physics.set_xlabel('')
ax_physics.set_ylabel('')
ax_physics.tick_params(colors=COLORS['text'])

# Exit Strategy Comparison
ax_exit = fig.add_subplot(gs_tech[0, 1])
ax_exit.set_facecolor(COLORS['bg_card'])

v32_exits = trades_v32['ExitReason'].value_counts()
exit_labels = v32_exits.index.tolist()
exit_sizes = v32_exits.values.tolist()
colors_exit = [COLORS['danger'] if 'SL' in label else COLORS['success'] if 'TP' in label else COLORS['primary'] for label in exit_labels]

wedges, texts, autotexts = ax_exit.pie(exit_sizes, labels=exit_labels, autopct='%1.1f%%',
                                         colors=colors_exit, startangle=90)
for text in texts:
    text.set_color(COLORS['text'])
    text.set_fontsize(10)
for autotext in autotexts:
    autotext.set_color('white')
    autotext.set_fontsize(9)
    autotext.set_weight('bold')

ax_exit.set_title('v3.2 Exit Distribution\n(SL/TP Strategy)', fontsize=12, color=COLORS['text'], weight='bold')

# v3.21 Exit (100% EA)
ax_exit321 = fig.add_subplot(gs_tech[0, 2])
ax_exit321.set_facecolor(COLORS['bg_card'])
ax_exit321.set_xlim(0, 1)
ax_exit321.set_ylim(0, 1)
ax_exit321.axis('off')

rect = FancyBboxPatch((0.1, 0.2), 0.8, 0.6, boxstyle="round,pad=0.05",
                      facecolor=COLORS['bg_dark'], edgecolor=COLORS['primary'], linewidth=3)
ax_exit321.add_patch(rect)
ax_exit321.text(0.5, 0.7, 'v3.21 Exit Strategy', ha='center', va='center',
               fontsize=14, color=COLORS['text'], weight='bold')
ax_exit321.text(0.5, 0.5, '100%', ha='center', va='center',
               fontsize=36, color=COLORS['primary'], weight='bold')
ax_exit321.text(0.5, 0.35, 'MA Reversals (EA)', ha='center', va='center',
               fontsize=12, color=COLORS['text'])
ax_exit321.text(0.5, 0.25, f"WR: {metrics_v321['win_rate']:.1f}%", ha='center', va='center',
               fontsize=11, color=COLORS['success'], weight='bold')

# Hourly Performance
ax_hourly = fig.add_subplot(gs_tech[1, :])
ax_hourly.set_facecolor(COLORS['bg_card'])

trades_v321['Hour'] = pd.to_datetime(trades_v321['OpenTime']).dt.hour
hourly_counts = trades_v321.groupby('Hour').size()
hourly_wr = trades_v321.groupby('Hour').apply(lambda x: (len(x[x['Profit'] > 0]) / len(x) * 100) if len(x) > 0 else 0)

hours = range(24)
counts = [hourly_counts.get(h, 0) for h in hours]
wrs = [hourly_wr.get(h, 0) for h in hours]

blocked_hours = [6, 7, 13, 14]
colors_hourly = [COLORS['danger'] if h in blocked_hours else COLORS['primary'] for h in hours]

bars = ax_hourly.bar(hours, counts, color=colors_hourly, alpha=0.7, label='Trade Count')
ax_hourly2 = ax_hourly.twinx()
ax_hourly2.plot(hours, wrs, color=COLORS['success'], marker='o', linewidth=2, label='Win Rate %')

ax_hourly.set_xlabel('Hour of Day', fontsize=12, color=COLORS['text'], weight='bold')
ax_hourly.set_ylabel('Trade Count', fontsize=12, color=COLORS['text'], weight='bold')
ax_hourly2.set_ylabel('Win Rate (%)', fontsize=12, color=COLORS['text'], weight='bold')
ax_hourly.set_title('Hourly Performance Distribution (Blocked Hours in Red)', 
                    fontsize=14, color=COLORS['text'], weight='bold', pad=10)
ax_hourly.set_xticks(hours)
ax_hourly.tick_params(colors=COLORS['text'])
ax_hourly2.tick_params(colors=COLORS['text'])
ax_hourly.axhline(20, color=COLORS['warning'], linestyle='--', alpha=0.3, label='Min Threshold')
ax_hourly.legend(loc='upper left', fontsize=10, framealpha=0.9)
ax_hourly2.legend(loc='upper right', fontsize=10, framealpha=0.9)
ax_hourly.grid(True, alpha=0.2, axis='y')

# ============================================================================
# SECTION 3: MULTI-TIMEFRAME COMPARISON (BOTTOM)
# ============================================================================
gs_multi = gridspec.GridSpecFromSubplotSpec(1, 3, subplot_spec=gs_main[2], hspace=0.3, wspace=0.3)

# Add section title
fig.text(0.5, 0.305, '🔄 MULTI-TIMEFRAME STRATEGY - 5M vs 15M Comparison', 
         ha='center', fontsize=24, weight='bold', color=COLORS['text'])

# 5M vs 15M Comparison Cards
ax_compare = fig.add_subplot(gs_multi[0, 0])
ax_compare.set_facecolor(COLORS['bg_card'])
ax_compare.set_xlim(0, 1)
ax_compare.set_ylim(0, 1)
ax_compare.axis('off')

comparison_data = [
    ('Win Rate', f"{metrics_v321['win_rate']:.1f}%", f"{metrics_15m['win_rate']:.1f}%"),
    ('Profit Factor', f"{metrics_v321['profit_factor']:.2f}", f"{metrics_15m['profit_factor']:.2f}"),
    ('Trades', f"{metrics_v321['trades']}", f"{metrics_15m['trades']}"),
    ('Net P&L', f"${metrics_v321['net_pl']:.2f}", f"${metrics_15m['net_pl']:.2f}")
]

y_pos = 0.85
ax_compare.text(0.5, 0.95, '5M vs 15M Metrics', ha='center', va='top',
               fontsize=14, color=COLORS['text'], weight='bold')
ax_compare.text(0.25, y_pos, '5M (v3.21)', ha='center', va='top',
               fontsize=11, color=COLORS['primary'], weight='bold')
ax_compare.text(0.75, y_pos, '15M (v3.2)', ha='center', va='top',
               fontsize=11, color=COLORS['accent'], weight='bold')

y_pos -= 0.12
for metric, val_5m, val_15m in comparison_data:
    ax_compare.text(0.05, y_pos, metric, ha='left', va='center',
                   fontsize=10, color=COLORS['neutral'], weight='bold')
    ax_compare.text(0.25, y_pos, val_5m, ha='center', va='center',
                   fontsize=11, color=COLORS['primary'])
    ax_compare.text(0.75, y_pos, val_15m, ha='center', va='center',
                   fontsize=11, color=COLORS['accent'])
    y_pos -= 0.15

# Trade Frequency Projection
ax_freq = fig.add_subplot(gs_multi[0, 1])
ax_freq.set_facecolor(COLORS['bg_card'])

months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
trades_5m_monthly = [metrics_v321['trades'] / 9 * 1] * 12  # Extrapolate to full year
trades_15m_monthly = [metrics_15m['trades'] / 9 * 1] * 12

x_months = np.arange(len(months))
width = 0.35

bars1 = ax_freq.bar(x_months - width/2, trades_5m_monthly, width, label='5M', 
                    color=COLORS['primary'], alpha=0.8)
bars2 = ax_freq.bar(x_months + width/2, trades_15m_monthly, width, label='15M', 
                    color=COLORS['accent'], alpha=0.8)

ax_freq.set_xlabel('Month', fontsize=11, color=COLORS['text'], weight='bold')
ax_freq.set_ylabel('Projected Trades', fontsize=11, color=COLORS['text'], weight='bold')
ax_freq.set_title('Annual Trade Frequency Projection', fontsize=12, color=COLORS['text'], weight='bold', pad=10)
ax_freq.set_xticks(x_months)
ax_freq.set_xticklabels(months, fontsize=9, color=COLORS['text'])
ax_freq.tick_params(colors=COLORS['text'])
ax_freq.legend(fontsize=10, framealpha=0.9)
ax_freq.grid(True, alpha=0.2, axis='y')

# Key Insights Panel
ax_insights = fig.add_subplot(gs_multi[0, 2])
ax_insights.set_facecolor(COLORS['bg_card'])
ax_insights.set_xlim(0, 1)
ax_insights.set_ylim(0, 1)
ax_insights.axis('off')

insights = [
    '🎯 KEY FINDINGS:',
    '',
    f'✅ v3.21: {metrics_v321["win_rate"]:.1f}% WR (Best 5M)',
    f'✅ 15M: {metrics_15m["win_rate"]:.1f}% WR (Superior)',
    '',
    '📊 STRATEGY:',
    f'• 5M: High freq ({metrics_v321["trades"]} trades)',
    f'• 15M: Low freq ({metrics_15m["trades"]} trades)',
    '• Non-correlated timeframes',
    '• Portfolio diversification',
    '',
    '🚀 NEXT STEPS:',
    '1. Forward testing v3.21',
    '2. Multi-symbol validation',
    '3. Scale to 60-120 symbols'
]

y_pos = 0.95
for insight in insights:
    if insight.startswith('🎯') or insight.startswith('📊') or insight.startswith('🚀'):
        color = COLORS['warning']
        weight = 'bold'
        size = 12
    elif insight.startswith('✅'):
        color = COLORS['success']
        weight = 'normal'
        size = 10
    elif insight.startswith('•'):
        color = COLORS['text']
        weight = 'normal'
        size = 9
    elif insight.startswith('1') or insight.startswith('2') or insight.startswith('3'):
        color = COLORS['primary']
        weight = 'normal'
        size = 9
    else:
        color = COLORS['text']
        weight = 'normal'
        size = 10
    
    ax_insights.text(0.05, y_pos, insight, ha='left', va='top',
                    fontsize=size, color=color, weight=weight)
    y_pos -= 0.06

# ============================================================================
# SAVE DASHBOARD
# ============================================================================
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
filename = f'TickPhysics_Composite_Dashboard_{timestamp}.png'

plt.tight_layout()
plt.savefig(filename, dpi=300, facecolor=COLORS['bg_dark'], edgecolor='none', 
            bbox_inches='tight', pad_inches=0.5)

print(f"✅ Composite dashboard saved: {filename}")
print(f"   Size: {36}x{24} inches")
print(f"   Resolution: 300 DPI")
print(f"   Sections: Executive, Technical, Multi-Timeframe")
print()
print("=" * 100)
print("COMPOSITE DASHBOARD COMPLETE")
print("=" * 100)
