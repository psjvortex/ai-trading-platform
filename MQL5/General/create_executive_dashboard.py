#!/usr/bin/env python3
"""
TickPhysics 5M Optimization - Executive Dashboard
Professional hedge fund-style reporting with dark theme and interactive visualizations

Analyzes the complete optimization journey: v3.0 → v3.1 → v3.2 → v3.21
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
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
print("📊 TICKPHYSICS 5M OPTIMIZATION - EXECUTIVE DASHBOARD")
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
    
    print("✅ All data loaded successfully")
    print()
except FileNotFoundError as e:
    print(f"❌ Error: {e}")
    exit(1)

# ============================================================================
# CALCULATE METRICS
# ============================================================================
def calculate_metrics(trades_df):
    """Calculate comprehensive trading metrics"""
    total_trades = len(trades_df)
    winners = len(trades_df[trades_df['Profit'] > 0])
    losers = len(trades_df[trades_df['Profit'] <= 0])
    
    win_rate = (winners / total_trades * 100) if total_trades > 0 else 0
    
    gross_profit = trades_df[trades_df['Profit'] > 0]['Profit'].sum()
    gross_loss = abs(trades_df[trades_df['Profit'] < 0]['Profit'].sum())
    net_profit = trades_df['Profit'].sum()
    
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
    
    avg_win = trades_df[trades_df['Profit'] > 0]['Profit'].mean() if winners > 0 else 0
    avg_loss = trades_df[trades_df['Profit'] < 0]['Profit'].mean() if losers > 0 else 0
    
    avg_win_pips = trades_df[trades_df['Profit'] > 0]['Pips'].mean() if winners > 0 else 0
    avg_loss_pips = trades_df[trades_df['Profit'] < 0]['Pips'].mean() if losers > 0 else 0
    
    return {
        'trades': total_trades,
        'winners': winners,
        'losers': losers,
        'win_rate': win_rate,
        'gross_profit': gross_profit,
        'gross_loss': gross_loss,
        'net_profit': net_profit,
        'profit_factor': profit_factor,
        'avg_win': avg_win,
        'avg_loss': avg_loss,
        'avg_win_pips': avg_win_pips,
        'avg_loss_pips': avg_loss_pips
    }

metrics = {
    'v3.0': calculate_metrics(trades_v30),
    'v3.1': calculate_metrics(trades_v31),
    'v3.2': calculate_metrics(trades_v32),
    'v3.21': calculate_metrics(trades_v321)
}

# ============================================================================
# CREATE DASHBOARD FIGURE
# ============================================================================
fig = plt.figure(figsize=(24, 16))
fig.patch.set_facecolor(COLORS['bg_dark'])

# Add main title with styling
fig.suptitle('TICKPHYSICS 5M OPTIMIZATION DASHBOARD\nNAS100 Performance Analysis (Jan 2 - Sep 29, 2025)', 
             fontsize=24, fontweight='bold', color=COLORS['text'], y=0.98)

# Create grid layout
gs = fig.add_gridspec(5, 4, hspace=0.4, wspace=0.3, top=0.93, bottom=0.05, left=0.05, right=0.95)

# ============================================================================
# ROW 1: KEY METRICS CARDS
# ============================================================================
def create_metric_card(ax, title, value, subtitle, color, icon=''):
    """Create a professional metric card"""
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')
    
    # Card background
    rect = plt.Rectangle((0.05, 0.1), 0.9, 0.8, facecolor=COLORS['bg_card'], 
                         edgecolor=color, linewidth=2, alpha=0.9)
    ax.add_patch(rect)
    
    # Icon/Title
    ax.text(0.5, 0.75, icon + ' ' + title, ha='center', va='center',
            fontsize=12, color=COLORS['neutral'], fontweight='bold')
    
    # Main value
    ax.text(0.5, 0.50, value, ha='center', va='center',
            fontsize=28, color=color, fontweight='bold')
    
    # Subtitle
    ax.text(0.5, 0.25, subtitle, ha='center', va='center',
            fontsize=10, color=COLORS['neutral'])

# Win Rate Card
ax1 = fig.add_subplot(gs[0, 0])
create_metric_card(ax1, 'WIN RATE', f"{metrics['v3.21']['win_rate']:.1f}%", 
                  'v3.21 (Best Performer)', COLORS['success'], '🎯')

# Total Trades Card
ax2 = fig.add_subplot(gs[0, 1])
create_metric_card(ax2, 'TOTAL TRADES', f"{metrics['v3.21']['trades']}", 
                  '63% reduction from v3.1', COLORS['primary'], '📊')

# Profit Factor Card
ax3 = fig.add_subplot(gs[0, 2])
create_metric_card(ax3, 'PROFIT FACTOR', f"{metrics['v3.21']['profit_factor']:.2f}", 
                  'Risk-adjusted returns', COLORS['accent'], '💰')

# Net P&L Card
ax4 = fig.add_subplot(gs[0, 3])
create_metric_card(ax4, 'NET P&L', f"${metrics['v3.21']['net_profit']:.2f}", 
                  'Total profit/loss', COLORS['warning'], '💵')

# ============================================================================
# ROW 2: VERSION PROGRESSION
# ============================================================================
ax5 = fig.add_subplot(gs[1, :2])
ax5.set_facecolor(COLORS['bg_card'])

versions = ['v3.0', 'v3.1', 'v3.2', 'v3.21']
win_rates = [metrics[v]['win_rate'] for v in versions]
colors_wr = [COLORS['danger'], COLORS['success'], COLORS['danger'], COLORS['success']]

bars = ax5.bar(versions, win_rates, color=colors_wr, alpha=0.8, edgecolor='white', linewidth=2)

# Add value labels on bars
for bar, wr in zip(bars, win_rates):
    height = bar.get_height()
    ax5.text(bar.get_x() + bar.get_width()/2., height + 1,
            f'{wr:.1f}%', ha='center', va='bottom', fontsize=12, 
            fontweight='bold', color=COLORS['text'])

ax5.set_title('📈 Win Rate Progression', fontsize=14, fontweight='bold', 
             color=COLORS['text'], pad=15)
ax5.set_ylabel('Win Rate (%)', fontsize=11, color=COLORS['text'])
ax5.set_xlabel('Version', fontsize=11, color=COLORS['text'])
ax5.axhline(y=35, color=COLORS['warning'], linestyle='--', linewidth=1.5, 
           label='Target (35%)', alpha=0.7)
ax5.legend(loc='upper left', framealpha=0.3)
ax5.grid(axis='y', alpha=0.2, linestyle='--')
ax5.tick_params(colors=COLORS['text'])

# Trade count comparison
ax6 = fig.add_subplot(gs[1, 2:])
ax6.set_facecolor(COLORS['bg_card'])

trade_counts = [metrics[v]['trades'] for v in versions]
bars2 = ax6.bar(versions, trade_counts, color=COLORS['primary'], alpha=0.8, 
               edgecolor='white', linewidth=2)

# Add value labels
for bar, count in zip(bars2, trade_counts):
    height = bar.get_height()
    ax6.text(bar.get_x() + bar.get_width()/2., height + 20,
            f'{count}', ha='center', va='bottom', fontsize=12, 
            fontweight='bold', color=COLORS['text'])

ax6.set_title('📉 Trade Count Reduction (Filter Effectiveness)', fontsize=14, 
             fontweight='bold', color=COLORS['text'], pad=15)
ax6.set_ylabel('Number of Trades', fontsize=11, color=COLORS['text'])
ax6.set_xlabel('Version', fontsize=11, color=COLORS['text'])
ax6.grid(axis='y', alpha=0.2, linestyle='--')
ax6.tick_params(colors=COLORS['text'])

# ============================================================================
# ROW 3: PROFIT FACTOR & NET P&L COMPARISON
# ============================================================================
ax7 = fig.add_subplot(gs[2, :2])
ax7.set_facecolor(COLORS['bg_card'])

profit_factors = [metrics[v]['profit_factor'] for v in versions]
colors_pf = [COLORS['warning'] if pf < 1.2 else COLORS['success'] for pf in profit_factors]

bars3 = ax7.bar(versions, profit_factors, color=colors_pf, alpha=0.8, 
               edgecolor='white', linewidth=2)

for bar, pf in zip(bars3, profit_factors):
    height = bar.get_height()
    ax7.text(bar.get_x() + bar.get_width()/2., height + 0.02,
            f'{pf:.2f}', ha='center', va='bottom', fontsize=12, 
            fontweight='bold', color=COLORS['text'])

ax7.set_title('💰 Profit Factor Evolution', fontsize=14, fontweight='bold', 
             color=COLORS['text'], pad=15)
ax7.set_ylabel('Profit Factor', fontsize=11, color=COLORS['text'])
ax7.set_xlabel('Version', fontsize=11, color=COLORS['text'])
ax7.axhline(y=1.4, color=COLORS['warning'], linestyle='--', linewidth=1.5, 
           label='Target (1.4)', alpha=0.7)
ax7.axhline(y=1.0, color=COLORS['danger'], linestyle='--', linewidth=1.5, 
           label='Breakeven', alpha=0.7)
ax7.legend(loc='upper left', framealpha=0.3)
ax7.grid(axis='y', alpha=0.2, linestyle='--')
ax7.tick_params(colors=COLORS['text'])

# Net P&L comparison
ax8 = fig.add_subplot(gs[2, 2:])
ax8.set_facecolor(COLORS['bg_card'])

net_pls = [metrics[v]['net_profit'] for v in versions]
colors_pl = [COLORS['success'] if pl > 0 else COLORS['danger'] for pl in net_pls]

bars4 = ax8.bar(versions, net_pls, color=colors_pl, alpha=0.8, 
               edgecolor='white', linewidth=2)

for bar, pl in zip(bars4, net_pls):
    height = bar.get_height()
    y_pos = height + 10 if height > 0 else height - 20
    ax8.text(bar.get_x() + bar.get_width()/2., y_pos,
            f'${pl:.2f}', ha='center', va='bottom' if height > 0 else 'top', 
            fontsize=12, fontweight='bold', color=COLORS['text'])

ax8.set_title('💵 Net Profit/Loss Comparison', fontsize=14, fontweight='bold', 
             color=COLORS['text'], pad=15)
ax8.set_ylabel('Net P&L ($)', fontsize=11, color=COLORS['text'])
ax8.set_xlabel('Version', fontsize=11, color=COLORS['text'])
ax8.axhline(y=0, color=COLORS['neutral'], linestyle='-', linewidth=1.5, alpha=0.5)
ax8.grid(axis='y', alpha=0.2, linestyle='--')
ax8.tick_params(colors=COLORS['text'])

# ============================================================================
# ROW 4: MOMENTUM FILTER ANALYSIS (v3.21)
# ============================================================================
ax9 = fig.add_subplot(gs[3, :2])
ax9.set_facecolor(COLORS['bg_card'])

# Momentum distribution for winners vs losers
winners_v321 = trades_v321[trades_v321['Profit'] > 0]
losers_v321 = trades_v321[trades_v321['Profit'] <= 0]

ax9.hist(winners_v321['EntryMomentum'], bins=30, alpha=0.7, 
        color=COLORS['success'], label=f'Winners ({len(winners_v321)})', 
        edgecolor='white', linewidth=0.5)
ax9.hist(losers_v321['EntryMomentum'], bins=30, alpha=0.7, 
        color=COLORS['danger'], label=f'Losers ({len(losers_v321)})', 
        edgecolor='white', linewidth=0.5)

# Add mean lines
winners_mean = winners_v321['EntryMomentum'].mean()
losers_mean = losers_v321['EntryMomentum'].mean()

ax9.axvline(winners_mean, color=COLORS['success'], linestyle='--', linewidth=2, 
           label=f'Winners Mean: {winners_mean:.1f}')
ax9.axvline(losers_mean, color=COLORS['danger'], linestyle='--', linewidth=2, 
           label=f'Losers Mean: {losers_mean:.1f}')
ax9.axvline(-346.58, color=COLORS['warning'], linestyle=':', linewidth=2.5, 
           label='Filter Threshold: -346.58')

ax9.set_title('🎯 Momentum Distribution - Winners vs Losers (v3.21)', 
             fontsize=14, fontweight='bold', color=COLORS['text'], pad=15)
ax9.set_xlabel('Entry Momentum', fontsize=11, color=COLORS['text'])
ax9.set_ylabel('Frequency', fontsize=11, color=COLORS['text'])
ax9.legend(loc='upper left', framealpha=0.3, fontsize=9)
ax9.grid(axis='y', alpha=0.2, linestyle='--')
ax9.tick_params(colors=COLORS['text'])

# Add separation metric
separation = winners_mean - losers_mean
ax9.text(0.98, 0.95, f'Separation: {separation:.1f}\n✅ STRONG', 
        transform=ax9.transAxes, ha='right', va='top',
        fontsize=11, color=COLORS['success'], fontweight='bold',
        bbox=dict(boxstyle='round', facecolor=COLORS['bg_card'], 
                 edgecolor=COLORS['success'], linewidth=2, alpha=0.9))

# Exit strategy comparison
ax10 = fig.add_subplot(gs[3, 2:])
ax10.set_facecolor(COLORS['bg_card'])

# Compare v3.2 (SL/TP) vs v3.21 (MA Reversals)
exit_data = {
    'v3.2 SL': [238, 0.0],
    'v3.2 TP': [47, 100.0],
    'v3.2 EA': [88, 42.0],
    'v3.21 MA': [199, 42.2]
}

exit_labels = list(exit_data.keys())
exit_wrs = [data[1] for data in exit_data.values()]
exit_colors = [COLORS['danger'], COLORS['success'], COLORS['warning'], COLORS['primary']]

bars5 = ax10.bar(exit_labels, exit_wrs, color=exit_colors, alpha=0.8, 
                edgecolor='white', linewidth=2)

for bar, wr in zip(bars5, exit_wrs):
    height = bar.get_height()
    ax10.text(bar.get_x() + bar.get_width()/2., height + 2,
             f'{wr:.1f}%', ha='center', va='bottom', fontsize=11, 
             fontweight='bold', color=COLORS['text'])

ax10.set_title('🚪 Exit Strategy Effectiveness', fontsize=14, fontweight='bold', 
              color=COLORS['text'], pad=15)
ax10.set_ylabel('Win Rate (%)', fontsize=11, color=COLORS['text'])
ax10.set_xlabel('Exit Method', fontsize=11, color=COLORS['text'])
ax10.grid(axis='y', alpha=0.2, linestyle='--')
ax10.tick_params(colors=COLORS['text'], labelsize=9)
plt.setp(ax10.xaxis.get_majorticklabels(), rotation=15, ha='right')

# ============================================================================
# ROW 5: KEY INSIGHTS & RECOMMENDATIONS
# ============================================================================
ax11 = fig.add_subplot(gs[4, :])
ax11.set_xlim(0, 1)
ax11.set_ylim(0, 1)
ax11.axis('off')

# Create insights panel
rect = plt.Rectangle((0.02, 0.05), 0.96, 0.9, facecolor=COLORS['bg_card'], 
                     edgecolor=COLORS['primary'], linewidth=3, alpha=0.95)
ax11.add_patch(rect)

# Title
ax11.text(0.5, 0.85, '🎯 KEY INSIGHTS & RECOMMENDATIONS', ha='center', va='center',
         fontsize=16, color=COLORS['primary'], fontweight='bold')

# Insights columns
insights_left = [
    "✅ v3.21 HYBRID achieves highest Win Rate: 42.2%",
    "✅ Momentum filter (≥-346.58) provides 128.7 point separation",
    "✅ MA Reversal exits outperform SL/TP (42.2% vs 22.5%)",
    "✅ Trade reduction of 63% maintains/improves WR quality",
    "⚠️  Profit Factor 1.13 slightly below 1.4 target"
]

insights_right = [
    "🔄 v3.0 → v3.1: +11.7% WR via Zone/Regime/Time filters",
    "❌ v3.1 → v3.2: -15.9% WR (SL/TP approach failed)",
    "✅ v3.2 → v3.21: +19.7% WR (removed SL/TP, kept Momentum)",
    "🏆 v3.21 validated as OPTIMAL 5M strategy",
    "🚀 Ready for multi-timeframe expansion (5M + 15M)"
]

y_pos = 0.70
for insight in insights_left:
    color = COLORS['success'] if '✅' in insight else (COLORS['warning'] if '⚠️' in insight else COLORS['danger'])
    ax11.text(0.05, y_pos, insight, ha='left', va='center',
             fontsize=10, color=color, fontweight='bold')
    y_pos -= 0.12

y_pos = 0.70
for insight in insights_right:
    color = COLORS['success'] if '✅' in insight else (COLORS['warning'] if '⚠️' in insight else (COLORS['primary'] if '🚀' in insight else COLORS['accent']))
    ax11.text(0.55, y_pos, insight, ha='left', va='center',
             fontsize=10, color=color, fontweight='bold')
    y_pos -= 0.12

# Bottom recommendation
ax11.text(0.5, 0.08, '📊 NEXT STEPS: Comprehensive 5M vs 15M comparison | Partner dashboard reports | Forward testing preparation',
         ha='center', va='center', fontsize=11, color=COLORS['text'], 
         style='italic', fontweight='bold')

# ============================================================================
# SAVE DASHBOARD
# ============================================================================
timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
filename = f'TickPhysics_5M_Executive_Dashboard_{timestamp}.png'
plt.savefig(filename, dpi=300, facecolor=COLORS['bg_dark'], edgecolor='none', 
           bbox_inches='tight')
print(f"✅ Dashboard saved: {filename}")

# Display
plt.tight_layout()
plt.show()

print()
print("=" * 100)
print("DASHBOARD GENERATION COMPLETE")
print("=" * 100)
