#!/usr/bin/env python3
"""
TickPhysics Crypto Backtest Analyzer
Rapid iteration tool for self-healing EA optimization
"""

import pandas as pd
import numpy as np
from datetime import datetime
import sys
import os

class CryptoBacktestAnalyzer:
    def __init__(self, signals_file, trades_file):
        self.signals_file = signals_file
        self.trades_file = trades_file
        self.signals_df = None
        self.trades_df = None
        
    def load_data(self):
        """Load CSV files"""
        print(f"📂 Loading {self.signals_file}...")
        self.signals_df = pd.read_csv(self.signals_file)
        print(f"   ✅ Loaded {len(self.signals_df)} signal records")
        
        print(f"📂 Loading {self.trades_file}...")
        self.trades_df = pd.read_csv(self.trades_file)
        entry_df = self.trades_df[self.trades_df['Action'] == 'ENTRY']
        print(f"   ✅ Loaded {len(entry_df)} trades")
        
        return True
    
    def analyze_baseline(self):
        """Generate baseline performance report"""
        print("\n" + "="*70)
        print("📊 BASELINE PERFORMANCE ANALYSIS")
        print("="*70)
        
        # Trade statistics
        trades = self.trades_df[self.trades_df['Action'] == 'ENTRY'].copy()
        exits = self.trades_df[self.trades_df['Action'] == 'EXIT'].copy()
        
        if len(trades) == 0:
            print("\n⚠️  NO TRADES EXECUTED - Check your entry filters!")
            print("\nPossible issues:")
            print("  - Quality threshold too high")
            print("  - Confluence threshold too high")
            print("  - Regime filter too strict")
            print("  - Zone filter too strict")
            return
        
        # Merge entries with exits
        trades['TradeID'] = trades['TradeID'].astype(str)
        exits['TradeID'] = exits['TradeID'].astype(str)
        merged = trades.merge(exits[['TradeID', 'Exit_Price', 'Profit_Percent', 'Exit_Reason', 'Duration_Minutes']], 
                            on='TradeID', how='left')
        
        # Calculate statistics
        total_trades = len(merged)
        closed_trades = merged['Profit_Percent'].notna().sum()
        
        if closed_trades == 0:
            print("\n⚠️  NO CLOSED TRADES YET - Run longer backtest!")
            return
        
        wins = len(merged[merged['Profit_Percent'] > 0])
        losses = len(merged[merged['Profit_Percent'] < 0])
        breakevens = len(merged[merged['Profit_Percent'] == 0])
        
        win_rate = (wins / closed_trades) * 100 if closed_trades > 0 else 0
        
        avg_win = merged[merged['Profit_Percent'] > 0]['Profit_Percent'].mean() if wins > 0 else 0
        avg_loss = merged[merged['Profit_Percent'] < 0]['Profit_Percent'].mean() if losses > 0 else 0
        
        profit_factor = abs(avg_win * wins / (avg_loss * losses)) if losses > 0 and avg_loss != 0 else 0
        expectancy = (win_rate/100 * avg_win) + ((100-win_rate)/100 * avg_loss)
        
        total_return = merged['Profit_Percent'].sum()
        avg_duration = merged['Duration_Minutes'].mean() if 'Duration_Minutes' in merged.columns else 0
        
        print(f"\n📈 PERFORMANCE METRICS")
        print(f"   Total Trades:      {total_trades}")
        print(f"   Closed Trades:     {closed_trades}")
        print(f"   Win Rate:          {win_rate:.1f}%")
        print(f"   Wins:              {wins}")
        print(f"   Losses:            {losses}")
        print(f"   Breakevens:        {breakevens}")
        print(f"   ")
        print(f"   Profit Factor:     {profit_factor:.2f}")
        print(f"   Expectancy:        {expectancy:.2f}%")
        print(f"   Avg Win:           {avg_win:.2f}%")
        print(f"   Avg Loss:          {avg_loss:.2f}%")
        print(f"   Total Return:      {total_return:.2f}%")
        print(f"   Avg Duration:      {avg_duration:.0f} minutes")
        
        # Signal analysis
        print(f"\n📊 SIGNAL ANALYSIS")
        total_signals = len(self.signals_df)
        longs = len(self.signals_df[self.signals_df['Signal'] == 1])
        shorts = len(self.signals_df[self.signals_df['Signal'] == -1])
        skips = len(self.signals_df[self.signals_df['Signal'] == 0])
        
        print(f"   Total Signals:     {total_signals}")
        print(f"   Long Signals:      {longs} ({longs/total_signals*100:.1f}%)")
        print(f"   Short Signals:     {shorts} ({shorts/total_signals*100:.1f}%)")
        print(f"   Skipped:           {skips} ({skips/total_signals*100:.1f}%)")
        
        # Skip reasons
        if skips > 0:
            print(f"\n🔍 WHY SIGNALS WERE SKIPPED:")
            skip_reasons = self.signals_df[self.signals_df['Signal'] == 0]['SkipReason'].value_counts()
            for reason, count in skip_reasons.items():
                print(f"   {reason:30s} {count:4d} ({count/skips*100:5.1f}%)")
        
        # Entry quality analysis
        print(f"\n⚡ ENTRY PHYSICS METRICS")
        print(f"   Avg Entry Quality:     {merged['Entry_Quality'].mean():.1f}")
        print(f"   Avg Entry Confluence:  {merged['Entry_Confluence'].mean():.1f}")
        print(f"   Avg Entry Momentum:    {merged['Entry_Momentum'].mean():.1f}")
        
        # Win/Loss by quality
        print(f"\n🎯 WIN RATE BY QUALITY THRESHOLD")
        for threshold in [60, 65, 70, 75, 80, 85]:
            high_q = merged[merged['Entry_Quality'] >= threshold]
            if len(high_q) > 0:
                wins_hq = len(high_q[high_q['Profit_Percent'] > 0])
                wr_hq = (wins_hq / len(high_q)) * 100
                print(f"   Quality ≥ {threshold:2d}:  {wr_hq:5.1f}%  ({len(high_q):3d} trades)")
        
        # Win/Loss by confluence
        print(f"\n🎯 WIN RATE BY CONFLUENCE THRESHOLD")
        for threshold in [40, 50, 60, 70, 80, 90]:
            high_c = merged[merged['Entry_Confluence'] >= threshold]
            if len(high_c) > 0:
                wins_hc = len(high_c[high_c['Profit_Percent'] > 0])
                wr_hc = (wins_hc / len(high_c)) * 100
                print(f"   Confluence ≥ {threshold:2d}:  {wr_hc:5.1f}%  ({len(high_c):3d} trades)")
        
        # Exit reasons
        if 'Exit_Reason' in exits.columns:
            print(f"\n🚪 EXIT REASONS")
            exit_reasons = exits['Exit_Reason'].value_counts()
            for reason, count in exit_reasons.items():
                print(f"   {reason:30s} {count:4d}")
        
        # Optimization suggestions
        self.suggest_optimizations(merged, win_rate, profit_factor)
        
    def suggest_optimizations(self, merged_df, current_wr, current_pf):
        """Suggest parameter changes for next iteration"""
        print(f"\n" + "="*70)
        print("🔧 OPTIMIZATION SUGGESTIONS FOR v1.1")
        print("="*70)
        
        suggestions = []
        
        # Quality threshold
        for threshold in [70, 75, 80]:
            high_q = merged_df[merged_df['Entry_Quality'] >= threshold]
            if len(high_q) >= 10:  # Need minimum sample size
                wins = len(high_q[high_q['Profit_Percent'] > 0])
                wr = (wins / len(high_q)) * 100
                if wr > current_wr + 5:  # At least 5% improvement
                    suggestions.append({
                        'param': 'InpMinTrendQuality',
                        'current': 70,
                        'suggested': threshold,
                        'improvement': f"+{wr-current_wr:.1f}% win rate",
                        'trades': len(high_q)
                    })
                    break
        
        # Confluence threshold
        for threshold in [60, 70, 80]:
            high_c = merged_df[merged_df['Entry_Confluence'] >= threshold]
            if len(high_c) >= 10:
                wins = len(high_c[high_c['Profit_Percent'] > 0])
                wr = (wins / len(high_c)) * 100
                if wr > current_wr + 5:
                    suggestions.append({
                        'param': 'InpMinConfluence',
                        'current': 60,
                        'suggested': threshold,
                        'improvement': f"+{wr-current_wr:.1f}% win rate",
                        'trades': len(high_c)
                    })
                    break
        
        # Regime filter
        normal_only = merged_df[merged_df['Entry_RegimeColor'] == 1]
        if len(normal_only) >= 10:
            wins = len(normal_only[normal_only['Profit_Percent'] > 0])
            wr = (wins / len(normal_only)) * 100
            if wr > current_wr + 3:
                suggestions.append({
                    'param': 'InpTradeOnlyNormalRegime',
                    'current': 'false',
                    'suggested': 'true',
                    'improvement': f"+{wr-current_wr:.1f}% win rate",
                    'trades': len(normal_only)
                })
        
        # Zone filter
        green_red_only = merged_df[merged_df['Entry_ZoneColor'].isin([0, 1])]
        if len(green_red_only) >= 10:
            wins = len(green_red_only[green_red_only['Profit_Percent'] > 0])
            wr = (wins / len(green_red_only)) * 100
            if wr > current_wr + 3:
                suggestions.append({
                    'param': 'InpRequireGreenZone',
                    'current': 'false',
                    'suggested': 'true',
                    'improvement': f"+{wr-current_wr:.1f}% win rate",
                    'trades': len(green_red_only)
                })
        
        if len(suggestions) == 0:
            print("\n✅ Current parameters look good!")
            print("   Consider:")
            print("   - Running longer backtest (more data)")
            print("   - Testing different timeframes")
            print("   - Testing different symbols (BTC vs ETH)")
        else:
            print("\n🎯 RECOMMENDED CHANGES:")
            for i, sug in enumerate(suggestions, 1):
                print(f"\n   {i}. {sug['param']}")
                print(f"      Current:    {sug['current']}")
                print(f"      Suggested:  {sug['suggested']}")
                print(f"      Expected:   {sug['improvement']}")
                print(f"      Sample:     {sug['trades']} trades")
        
        print(f"\n📝 NEXT STEPS:")
        print(f"   1. Update EA parameters in MT5")
        print(f"   2. Change EA_VERSION to '1.1'")
        print(f"   3. Change CSV filenames to 'v1.1.csv'")
        print(f"   4. Run backtest again")
        print(f"   5. Compare results using: python analyze.py compare v1.0 v1.1")
        
    def compare_versions(self, old_signals, old_trades, new_signals, new_trades):
        """Compare two versions"""
        print("\n" + "="*70)
        print("📊 VERSION COMPARISON")
        print("="*70)
        
        # Load old version
        print(f"\n📂 Loading OLD version...")
        old_s = pd.read_csv(old_signals)
        old_t = pd.read_csv(old_trades)
        old_entries = old_t[old_t['Action'] == 'ENTRY']
        old_exits = old_t[old_t['Action'] == 'EXIT']
        old_merged = old_entries.merge(old_exits[['TradeID', 'Profit_Percent']], on='TradeID', how='left')
        old_closed = old_merged[old_merged['Profit_Percent'].notna()]
        
        old_wins = len(old_closed[old_closed['Profit_Percent'] > 0])
        old_wr = (old_wins / len(old_closed)) * 100 if len(old_closed) > 0 else 0
        old_return = old_closed['Profit_Percent'].sum()
        
        # Load new version
        print(f"📂 Loading NEW version...")
        new_s = pd.read_csv(new_signals)
        new_t = pd.read_csv(new_trades)
        new_entries = new_t[new_t['Action'] == 'ENTRY']
        new_exits = new_t[new_t['Action'] == 'EXIT']
        new_merged = new_entries.merge(new_exits[['TradeID', 'Profit_Percent']], on='TradeID', how='left')
        new_closed = new_merged[new_merged['Profit_Percent'].notna()]
        
        new_wins = len(new_closed[new_closed['Profit_Percent'] > 0])
        new_wr = (new_wins / len(new_closed)) * 100 if len(new_closed) > 0 else 0
        new_return = new_closed['Profit_Percent'].sum()
        
        # Compare
        print(f"\n📈 PERFORMANCE COMPARISON")
        print(f"{'Metric':<20s} {'OLD':>12s} {'NEW':>12s} {'DELTA':>12s}")
        print("-" * 60)
        
        self._print_comparison("Trades", len(old_closed), len(new_closed))
        self._print_comparison("Win Rate %", old_wr, new_wr, is_percent=True)
        self._print_comparison("Total Return %", old_return, new_return, is_percent=True)
        
        # Verdict
        print(f"\n🎯 VERDICT:")
        improved = 0
        regressed = 0
        
        if new_wr > old_wr:
            print(f"   ✅ Win rate improved by {new_wr - old_wr:.1f}%")
            improved += 1
        elif new_wr < old_wr:
            print(f"   ❌ Win rate decreased by {old_wr - new_wr:.1f}%")
            regressed += 1
        
        if new_return > old_return:
            print(f"   ✅ Returns improved by {new_return - old_return:.1f}%")
            improved += 1
        elif new_return < old_return:
            print(f"   ❌ Returns decreased by {old_return - new_return:.1f}%")
            regressed += 1
        
        if improved > regressed:
            print(f"\n   🚀 KEEP THIS VERSION! Overall improvement detected.")
            print(f"   📝 Update to v1.2 and continue iterating")
        elif regressed > improved:
            print(f"\n   ⚠️  REVERT TO OLD VERSION! Performance degraded.")
            print(f"   📝 Try different parameters")
        else:
            print(f"\n   ⚪ MIXED RESULTS - Need more data or try different approach")
        
    def _print_comparison(self, metric, old_val, new_val, is_percent=False):
        """Helper to print comparison row"""
        delta = new_val - old_val
        delta_str = f"+{delta:.1f}" if delta > 0 else f"{delta:.1f}"
        
        if is_percent:
            delta_str += "%"
            old_str = f"{old_val:.1f}%"
            new_str = f"{new_val:.1f}%"
        else:
            old_str = f"{old_val:.0f}"
            new_str = f"{new_val:.0f}"
        
        symbol = "✅" if delta > 0 else "❌" if delta < 0 else "="
        
        print(f"{metric:<20s} {old_str:>12s} {new_str:>12s} {symbol} {delta_str:>10s}")

def main():
    if len(sys.argv) < 3:
        print("Usage:")
        print("  Baseline:  python analyze_crypto.py baseline signals.csv trades.csv")
        print("  Compare:   python analyze_crypto.py compare old_signals.csv old_trades.csv new_signals.csv new_trades.csv")
        return
    
    mode = sys.argv[1]
    
    if mode == 'baseline':
        if len(sys.argv) != 4:
            print("Error: baseline mode requires 2 CSV files")
            return
        
        analyzer = CryptoBacktestAnalyzer(sys.argv[2], sys.argv[3])
        analyzer.load_data()
        analyzer.analyze_baseline()
    
    elif mode == 'compare':
        if len(sys.argv) != 6:
            print("Error: compare mode requires 4 CSV files")
            return
        
        analyzer = CryptoBacktestAnalyzer(sys.argv[4], sys.argv[5])  # New version
        analyzer.compare_versions(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    
    else:
        print(f"Unknown mode: {mode}")
        print("Use 'baseline' or 'compare'")

if __name__ == '__main__':
    main()
