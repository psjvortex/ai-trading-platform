#!/usr/bin/env python3
"""3-Way Comparison: v2.4 vs v2.5 vs v2.6"""
import pandas as pd

print("\n" + "="*100)
print("  🔬 TICKPHYSICS 3-WAY COMPARISON: v2.4 → v2.5 → v2.6")
print("="*100 + "\n")

# Load MT5 reports
mt5_24 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.4.csv", encoding='utf-8-sig')
mt5_25 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.5.csv", encoding='utf-8-sig')
mt5_26 = pd.read_csv("MT5 Excel Reports/MTBacktest_Report_2.6.csv", encoding='utf-8-sig')

# Extract exit trades
exits_24 = mt5_24[mt5_24['Direction'] == 'out'].copy()
exits_25 = mt5_25[mt5_25['Direction'] == 'out'].copy()
exits_26 = mt5_26[mt5_26['Direction'] == 'out'].copy()

# Clean profit
for df in [exits_24, exits_25, exits_26]:
    df['Profit_Clean'] = df['Profit'].astype(str).str.replace(' ', '').str.replace(',', '').astype(float)

# Load TP CSVs
tp_24 = pd.read_csv("TP_Integrated_Trades_NAS100_v2.4.csv")
tp_25 = pd.read_csv("TP_Integrated_Trades_NAS100_v2.5.csv")
tp_26 = pd.read_csv("TP_Integrated_Trades_NAS100_v2.6.csv")

sig_24 = pd.read_csv("TP_Integrated_Signals_NAS100_v2.4.csv")
sig_25 = pd.read_csv("TP_Integrated_Signals_NAS100_v2.5.csv")
sig_26 = pd.read_csv("TP_Integrated_Signals_NAS100_v2.6.csv")

print("📊 DATA LOADED:")
print(f"   v2.4: {len(exits_24)} trades, {len(sig_24)} signals")
print(f"   v2.5: {len(exits_25)} trades, {len(sig_25)} signals")
print(f"   v2.6: {len(exits_26)} trades, {len(sig_26)} signals\n")

# Calculate metrics
def metrics(exits, tp, sig, ver):
    total = len(exits)
    wins = len(exits[exits['Profit_Clean'] > 0])
    pnl = exits['Profit_Clean'].sum()
    wr = (wins/total*100) if total > 0 else 0
    rej = ((len(sig)-total)/len(sig)*100) if len(sig) > 0 else 0
    return {'ver': ver, 'trades': total, 'signals': len(sig), 'wins': wins, 
            'pnl': pnl, 'wr': wr, 'rej': rej}

m24 = metrics(exits_24, tp_24, sig_24, "v2.4")
m25 = metrics(exits_25, tp_25, sig_25, "v2.5")
m26 = metrics(exits_26, tp_26, sig_26, "v2.6")

# Comparison table
print("="*90)
print("  📈 PERFORMANCE COMPARISON")
print("="*90 + "\n")
print(f"{'Metric':<20} {'v2.4':<20} {'v2.5':<20} {'v2.6':<20}")
print("-"*90)
print(f"{'Signals':<20} {m24['signals']:<20} {m25['signals']:<20} {m26['signals']:<20}")
print(f"{'Rejected':<20} {'-':<20} {m25['rej']:.1f}%{'':<15} {m26['rej']:.1f}%{'':<15}")
print(f"{'Trades':<20} {m24['trades']:<20} {m25['trades']:<20} {m26['trades']:<20}")
print(f"{'P&L':<20} ${m24['pnl']:<19.2f} ${m25['pnl']:<19.2f} ${m26['pnl']:<19.2f}")
print(f"{'Win Rate':<20} {m24['wr']:<19.1f}% {m25['wr']:<19.1f}% {m26['wr']:<19.1f}%\n")

# Delta analysis
print("="*90)
print("  📊 DELTA ANALYSIS")
print("="*90 + "\n")

d25 = m25['pnl'] - m24['pnl']
d26 = m26['pnl'] - m25['pnl']

print(f"v2.5 vs v2.4: ${d25:+.2f} ({(d25/abs(m24['pnl'])*100):+.1f}%) - {'✅ BETTER' if d25>0 else '❌ WORSE'}")
print(f"v2.6 vs v2.5: ${d26:+.2f} ({(d26/abs(m25['pnl'])*100):+.1f}%) - {'✅ BETTER' if d26>0 else '❌ WORSE'}\n")

print("="*90 + "\n")
