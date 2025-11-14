#!/usr/bin/env python3
"""
Analyze v3.2_05M MFE/MAE to calculate OPTIMAL SL/TP settings
Previous attempt used v3.1 data which was too optimistic for SL/TP trading
Now analyzing v3.2 actual results with SL/TP active
"""

import pandas as pd
import numpy as np

print("=" * 80)
print("📊 v3.2_05M OPTIMAL SL/TP ANALYSIS")
print("=" * 80)
print()

# Load v3.2 trades
v3_2_trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.2_05M.csv')

print(f"Total v3.2 trades analyzed: {len(v3_2_trades)}")
print()

# Separate winners and losers
winners = v3_2_trades[v3_2_trades['Profit'] > 0].copy()
losers = v3_2_trades[v3_2_trades['Profit'] <= 0].copy()

print(f"Winners: {len(winners)} ({len(winners)/len(v3_2_trades)*100:.1f}%)")
print(f"Losers: {len(losers)} ({len(losers)/len(v3_2_trades)*100:.1f}%)")
print()

# ============================================================================
# SECTION 1: TAKE PROFIT ANALYSIS (from Winners' MFE)
# ============================================================================
print("=" * 80)
print("SECTION 1: TAKE PROFIT ANALYSIS (from Winners' MFE)")
print("=" * 80)
print()

print("Current v3.2 Settings: TP = 1950 pips (195 pips actual)")
print(f"Current TP Hit Rate: {len(winners[winners['ExitReason'] == 'TP'])}/{len(winners)} = {len(winners[winners['ExitReason'] == 'TP'])/len(winners)*100:.1f}% of winners")
print()

if 'MFE_Pips' in winners.columns:
    print("WINNERS' MFE DISTRIBUTION (Maximum Favorable Excursion):")
    print(f"  Count: {len(winners)}")
    print(f"  Mean: {winners['MFE_Pips'].mean():.1f} pips")
    print(f"  Median (50th percentile): {winners['MFE_Pips'].median():.1f} pips")
    print(f"  25th percentile: {winners['MFE_Pips'].quantile(0.25):.1f} pips")
    print(f"  75th percentile: {winners['MFE_Pips'].quantile(0.75):.1f} pips")
    print(f"  90th percentile: {winners['MFE_Pips'].quantile(0.90):.1f} pips")
    print(f"  95th percentile: {winners['MFE_Pips'].quantile(0.95):.1f} pips")
    print(f"  Max: {winners['MFE_Pips'].max():.1f} pips")
    print()
    
    # Calculate how many winners would hit various TP levels
    tp_levels = [150, 200, 250, 300, 350, 400, 450, 500, 600]
    
    print("TP CAPTURE ANALYSIS (% of winners that reached each TP level):")
    best_tp = None
    best_score = 0
    
    for tp in tp_levels:
        would_hit = len(winners[winners['MFE_Pips'] >= tp])
        hit_rate = (would_hit / len(winners) * 100)
        
        # Score = hit rate * TP value (balance between frequency and size)
        score = hit_rate * tp
        
        print(f"  TP {tp:3.0f} pips ({tp*10:4.0f} setting): {would_hit:3d}/{len(winners)} = {hit_rate:5.1f}% capture | Score: {score:7.0f}")
        
        if score > best_score and hit_rate >= 40:  # Must capture at least 40% of winners
            best_score = score
            best_tp = tp
    
    print()
    print(f"🎯 OPTIMAL TP (best score with ≥40% capture): {best_tp} pips ({best_tp*10} setting)")
    print()

# ============================================================================
# SECTION 2: STOP LOSS ANALYSIS (from Losers' MAE)
# ============================================================================
print("=" * 80)
print("SECTION 2: STOP LOSS ANALYSIS (from Losers' MAE)")
print("=" * 80)
print()

print("Current v3.2 Settings: SL = 340 pips (34 pips actual)")
print(f"Current SL Hit Rate: {len(losers[losers['ExitReason'] == 'SL'])}/{len(losers)} = {len(losers[losers['ExitReason'] == 'SL'])/len(losers)*100:.1f}% of losers")
print()

if 'MAE_Pips' in losers.columns:
    print("LOSERS' MAE DISTRIBUTION (Maximum Adverse Excursion):")
    print(f"  Count: {len(losers)}")
    print(f"  Mean: {abs(losers['MAE_Pips'].mean()):.1f} pips")
    print(f"  Median (50th percentile): {abs(losers['MAE_Pips'].median()):.1f} pips")
    print(f"  25th percentile: {abs(losers['MAE_Pips'].quantile(0.25)):.1f} pips")
    print(f"  75th percentile: {abs(losers['MAE_Pips'].quantile(0.75)):.1f} pips")
    print(f"  90th percentile: {abs(losers['MAE_Pips'].quantile(0.90)):.1f} pips")
    print(f"  95th percentile: {abs(losers['MAE_Pips'].quantile(0.95)):.1f} pips")
    print(f"  Max: {abs(losers['MAE_Pips'].min()):.1f} pips")  # min because negative
    print()
    
    # Calculate SL that would catch various percentiles
    sl_levels = [40, 50, 60, 70, 80, 90, 100, 120, 150]
    
    print("SL PROTECTION ANALYSIS (what % of losers would be stopped):")
    best_sl = None
    best_loss_reduction = 0
    
    for sl in sl_levels:
        would_stop = len(losers[abs(losers['MAE_Pips']) >= sl])
        stop_rate = (would_stop / len(losers) * 100)
        
        # How much loss would be saved
        avg_mae = abs(losers['MAE_Pips'].mean())
        loss_reduction = (avg_mae - sl) * would_stop if avg_mae > sl else 0
        
        print(f"  SL {sl:3.0f} pips ({sl*10:4.0f} setting): {would_stop:3d}/{len(losers)} = {stop_rate:5.1f}% stopped | Loss reduction: {loss_reduction:6.0f} pips")
        
        if stop_rate >= 60 and loss_reduction > best_loss_reduction:  # Want to stop most losers
            best_loss_reduction = loss_reduction
            best_sl = sl
    
    print()
    print(f"🎯 OPTIMAL SL (stops ≥60% of losers with max loss reduction): {best_sl} pips ({best_sl*10} setting)")
    print()

# ============================================================================
# SECTION 3: ALTERNATIVE ANALYSIS - REVERSAL EXITS
# ============================================================================
print("=" * 80)
print("SECTION 3: ALTERNATIVE - MA REVERSAL EXITS (NO SL/TP)")
print("=" * 80)
print()

# Check EA exits (MA reversals)
ea_exits = v3_2_trades[v3_2_trades['ExitReason'] == 'EA']
print(f"MA Reversal Exits: {len(ea_exits)} trades ({len(ea_exits)/len(v3_2_trades)*100:.1f}%)")

if len(ea_exits) > 0:
    ea_winners = ea_exits[ea_exits['Profit'] > 0]
    ea_losers = ea_exits[ea_exits['Profit'] <= 0]
    ea_wr = len(ea_winners) / len(ea_exits) * 100
    
    print(f"  Winners: {len(ea_winners)} | Losers: {len(ea_losers)} | WR: {ea_wr:.1f}%")
    print(f"  Avg Winner: ${ea_winners['Profit'].mean():.2f}" if len(ea_winners) > 0 else "  No winners")
    print(f"  Avg Loser: ${ea_losers['Profit'].mean():.2f}" if len(ea_losers) > 0 else "  No losers")
    print()
    
    print("💡 OBSERVATION:")
    print(f"  MA Reversal exits have {ea_wr:.1f}% WR vs overall {len(winners)/len(v3_2_trades)*100:.1f}% WR")
    if ea_wr > 35:
        print("  ✅ MA reversals perform BETTER - consider removing SL/TP!")
    else:
        print("  ⚠️  MA reversals not performing well")

print()

# ============================================================================
# SECTION 4: COMPARISON WITH v3.1 (NO SL/TP)
# ============================================================================
print("=" * 80)
print("SECTION 4: v3.1 (NO SL/TP) vs v3.2 (WITH SL/TP) COMPARISON")
print("=" * 80)
print()

v3_1_trades = pd.read_csv('TP_Integrated_Trades_NAS100_v3.1_05M.csv')

v3_1_winners = v3_1_trades[v3_1_trades['Profit'] > 0]
v3_1_losers = v3_1_trades[v3_1_trades['Profit'] <= 0]

print("v3.1 (NO SL/TP - MA Reversal Exits Only):")
print(f"  Trades: {len(v3_1_trades)}")
print(f"  Win Rate: {len(v3_1_winners)/len(v3_1_trades)*100:.1f}%")
print(f"  Profit Factor: {v3_1_winners['Profit'].sum() / abs(v3_1_losers['Profit'].sum()):.2f}")
print(f"  Net P&L: ${v3_1_trades['Profit'].sum():.2f}")
print()

print("v3.2 (WITH SL/TP 340/1950):")
print(f"  Trades: {len(v3_2_trades)}")
print(f"  Win Rate: {len(winners)/len(v3_2_trades)*100:.1f}%")
print(f"  Profit Factor: {winners['Profit'].sum() / abs(losers['Profit'].sum()):.2f}")
print(f"  Net P&L: ${v3_2_trades['Profit'].sum():.2f}")
print()

print("DELTA (v3.2 vs v3.1):")
print(f"  Trades: {len(v3_2_trades) - len(v3_1_trades):+d} ({(len(v3_2_trades) - len(v3_1_trades))/len(v3_1_trades)*100:+.1f}%)")
print(f"  Win Rate: {(len(winners)/len(v3_2_trades)*100) - (len(v3_1_winners)/len(v3_1_trades)*100):+.1f}%")
print(f"  Net P&L: ${v3_2_trades['Profit'].sum() - v3_1_trades['Profit'].sum():+.2f}")
print()

# ============================================================================
# SECTION 5: RECOMMENDATIONS
# ============================================================================
print("=" * 80)
print("SECTION 5: RECOMMENDATIONS FOR v3.21_05M")
print("=" * 80)
print()

print("🎯 OPTION A: OPTIMIZED SL/TP (Based on v3.2 MFE/MAE)")
if best_tp and best_sl:
    print(f"  Stop Loss: {best_sl} pips ({best_sl*10} setting)")
    print(f"  Take Profit: {best_tp} pips ({best_tp*10} setting)")
    print(f"  R:R Ratio: {best_tp/best_sl:.2f}:1")
    print()
    print(f"  Expected TP Hit Rate: {len(winners[winners['MFE_Pips'] >= best_tp])/len(winners)*100:.1f}% of winners")
    print(f"  Expected SL Hit Rate: {len(losers[abs(losers['MAE_Pips']) >= best_sl])/len(losers)*100:.1f}% of losers")
    print()

print("🎯 OPTION B: HYBRID APPROACH")
print("  Keep Momentum filter from v3.2 (MinMomentum -346.58)")
print("  Remove SL/TP (set to 0)")
print("  Use MA reversal exits only (like v3.1)")
print("  Expected: Combine v3.1's 38.5% WR with v3.2's trade reduction")
print()

print("💡 RECOMMENDED APPROACH:")

# Decision logic
v3_1_wr = len(v3_1_winners)/len(v3_1_trades)*100
v3_2_wr = len(winners)/len(v3_2_trades)*100
ea_exit_performance = ea_wr if len(ea_exits) > 0 else 0

if v3_1_wr > v3_2_wr and ea_exit_performance > 35:
    print("  ✅ OPTION B: Remove SL/TP, use MA reversals + Momentum filter")
    print()
    print("  REASONING:")
    print(f"    • v3.1 (no SL/TP) had {v3_1_wr:.1f}% WR vs v3.2 (with SL/TP) {v3_2_wr:.1f}% WR")
    print(f"    • MA reversal exits show {ea_exit_performance:.1f}% WR in v3.2")
    print(f"    • SL getting hit too often ({len(losers[losers['ExitReason'] == 'SL'])/len(losers)*100:.1f}% of losers)")
    print(f"    • Keep Momentum filter advantage (30% trade reduction)")
    print()
    print("  v3.21_05M SETTINGS:")
    print("    StopLossPips = 0")
    print("    TakeProfitPips = 0")
    print("    MinMomentum = -346.58 (KEEP from v3.2)")
    print("    Expected: ~373 trades, 35-45% WR, PF 1.3-1.6")
else:
    print("  ✅ OPTION A: Use optimized SL/TP from v3.2 data")
    print()
    print("  REASONING:")
    print(f"    • Net profit improved: ${v3_2_trades['Profit'].sum():.2f} vs ${v3_1_trades['Profit'].sum():.2f}")
    print(f"    • Just need wider SL to avoid premature stops")
    print(f"    • TP needs adjustment for realistic capture rate")
    print()
    print("  v3.21_05M SETTINGS:")
    if best_sl and best_tp:
        print(f"    StopLossPips = {best_sl*10}")
        print(f"    TakeProfitPips = {best_tp*10}")
        print(f"    MinMomentum = -346.58 (KEEP from v3.2)")
        print(f"    Expected: ~300-350 trades, 30-40% WR, PF 1.5-2.0")

print()
print("=" * 80)
print("✅ ANALYSIS COMPLETE!")
print("=" * 80)
