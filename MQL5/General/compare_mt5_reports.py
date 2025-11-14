#!/usr/bin/env python3
"""MT5 Reports Comparison: v2.4 vs v2.5 vs v2.6"""
import pandas as pd

print("\n" + "="*100)
print("  🔬 TICKPHYSICS 3-WAY COMPARISON: v2.4 (Baseline) → v2.5 (Physics) → v2.6 (Time)")
print("="*100 + "\n")

# Load MT5 reports
mt5_24 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.4.csv", encoding='utf-8-sig')
mt5_25 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.5.csv", encoding='utf-8-sig')
mt5_26 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.6.csv", encoding='utf-8-sig')

# Extract exit trades only
exits_24 = mt5_24[mt5_24['Direction'] == 'out'].copy()
exits_25 = mt5_25[mt5_25['Direction'] == 'out'].copy()
exits_26 = mt5_26[mt5_26['Direction'] == 'out'].copy()

# Clean profit column
for df in [exits_24, exits_25, exits_26]:
    df['Profit_Clean'] = df['Profit'].astype(str).str.replace(' ', '').str.replace(',', '').astype(float)

# Calculate comprehensive metrics
def calc_metrics(exits_df, version):
    total = len(exits_df)
    if total == 0:
        return {'ver': version, 'trades': 0, 'wins': 0, 'losses': 0, 'wr': 0, 'pnl': 0,
                'avg_win': 0, 'avg_loss': 0, 'profit_factor': 0}
    
    wins = len(exits_df[exits_df['Profit_Clean'] > 0])
    losses = len(exits_df[exits_df['Profit_Clean'] < 0])
    pnl = exits_df['Profit_Clean'].sum()
    wr = (wins / total * 100)
    
    avg_win = exits_df[exits_df['Profit_Clean'] > 0]['Profit_Clean'].mean() if wins > 0 else 0
    avg_loss = exits_df[exits_df['Profit_Clean'] < 0]['Profit_Clean'].mean() if losses > 0 else 0
    profit_factor = abs(avg_win * wins / (avg_loss * losses)) if losses > 0 and avg_loss != 0 else 0
    
    return {
        'ver': version,
        'trades': total,
        'wins': wins,
        'losses': losses,
        'wr': wr,
        'pnl': pnl,
        'avg_win': avg_win,
        'avg_loss': avg_loss,
        'profit_factor': profit_factor
    }

m24 = calc_metrics(exits_24, "v2.4")
m25 = calc_metrics(exits_25, "v2.5")
m26 = calc_metrics(exits_26, "v2.6")

print("📊 BACKTEST RESULTS:")
print(f"   Period: Jan-Sep 2025, NAS100 M15")
print(f"   v2.4 (Baseline):      {m24['trades']} trades")
print(f"   v2.5 (+ Physics):     {m25['trades']} trades")
print(f"   v2.6 (+ Time):        {m26['trades']} trades\n")

# Main comparison table
print("="*110)
print("  📈 PERFORMANCE COMPARISON")
print("="*110 + "\n")

print(f"{'Metric':<25} {'v2.4 Baseline':<25} {'v2.5 +Physics':<25} {'v2.6 +Time':<25}")
print("-" * 110)
print(f"{'Trades Executed':<25} {m24['trades']:<25} {m25['trades']:<25} {m26['trades']:<25}")
print(f"{'Wins / Losses':<25} {m24['wins']} / {m24['losses']}{'':<20} {m25['wins']} / {m25['losses']}{'':<20} {m26['wins']} / {m26['losses']}{'':<20}")
print(f"{'Win Rate':<25} {m24['wr']:<24.1f}% {m25['wr']:<24.1f}% {m26['wr']:<24.1f}%")
print()
print(f"{'Total P&L':<25} ${m24['pnl']:<24.2f} ${m25['pnl']:<24.2f} ${m26['pnl']:<24.2f}")
print(f"{'Avg Win':<25} ${m24['avg_win']:<24.2f} ${m25['avg_win']:<24.2f} ${m26['avg_win']:<24.2f}")
print(f"{'Avg Loss':<25} ${m24['avg_loss']:<24.2f} ${m25['avg_loss']:<24.2f} ${m26['avg_loss']:<24.2f}")
print(f"{'Profit Factor':<25} {m24['profit_factor']:<24.2f} {m25['profit_factor']:<24.2f} {m26['profit_factor']:<24.2f}")
print()

# Delta analysis
print("="*110)
print("  📊 INCREMENTAL IMPROVEMENT ANALYSIS")
print("="*110 + "\n")

d25 = m25['pnl'] - m24['pnl']
d26 = m26['pnl'] - m25['pnl']
dwr25 = m25['wr'] - m24['wr']
dwr26 = m26['wr'] - m25['wr']
dt25 = m25['trades'] - m24['trades']
dt26 = m26['trades'] - m25['trades']

print("v2.5 vs v2.4 (Adding Physics Filters):")
print(f"   P&L Change:        ${d25:+.2f} ({(d25/abs(m24['pnl'])*100) if m24['pnl'] != 0 else 0:+.1f}%)")
print(f"   Win Rate Change:   {dwr25:+.1f}%")
print(f"   Trade Count:       {dt25:+d} ({(dt25/m24['trades']*100) if m24['trades'] > 0 else 0:+.1f}%)")
print(f"   Result:            {'✅ IMPROVED' if d25 > 0 else '❌ WORSE'}")
print()

print("v2.6 vs v2.5 (Adding Time Filters):")
print(f"   P&L Change:        ${d26:+.2f} ({(d26/abs(m25['pnl'])*100) if m25['pnl'] != 0 else 0:+.1f}%)")
print(f"   Win Rate Change:   {dwr26:+.1f}%")
print(f"   Trade Count:       {dt26:+d} ({(dt26/m25['trades']*100) if m25['trades'] > 0 else 0:+.1f}%)")
print(f"   Result:            {'✅ IMPROVED' if d26 > 0 else '❌ WORSE'}")
print()

# Summary
print("="*110)
print("  🎯 SUMMARY")
print("="*110 + "\n")

if d25 > 0:
    print(f"✅ v2.5 Physics Filters: +${d25:.2f} improvement over baseline")
else:
    print(f"❌ v2.5 Physics Filters: ${d25:.2f} worse than baseline")

if d26 > 0:
    print(f"✅ v2.6 Time Filters: +${d26:.2f} improvement over v2.5")
else:
    print(f"❌ v2.6 Time Filters: ${d26:.2f} worse than v2.5")

total_improvement = m26['pnl'] - m24['pnl']
print(f"\n📊 Total Journey (v2.4 → v2.6): ${total_improvement:+.2f} ({(total_improvement/abs(m24['pnl'])*100) if m24['pnl'] != 0 else 0:+.1f}%)")

print()

# Recommendations
print("="*110)
print("  💡 RECOMMENDATIONS")
print("="*110 + "\n")

if d26 < 0:
    print("❌ TIME FILTERS HURT PERFORMANCE")
    print()
    print("Problem:")
    print("   • v2.6 time filters blocked profitable opportunities")
    print(f"   • Reduced trade count by {abs(dt26)} ({abs(dt26/m25['trades']*100):.1f}%)")
    print(f"   • Lost ${abs(d26):.2f} in profit vs v2.5")
    print()
    print("Next Steps:")
    print("   1. Load v2.6 TP CSV files to analyze which hours were blocked")
    print("   2. Review time-of-day performance in v2.5 data")
    print("   3. Revise allowed/blocked hours based on actual v2.5 profitability")
    print("   4. Consider: Remove time filters OR use ONLY blocked hours (remove bad hours, allow all others)")
    print()
    print(f"   🎯 Goal: Match or beat v2.5 performance (${m25['pnl']:.2f})")
else:
    print("✅ TIME FILTERS WORKING!")
    print(f"   Continue with v2.6 settings - improved by ${d26:.2f}")

print("\n" + "="*110 + "\n")
