#!/usr/bin/env python3
"""
Comprehensive Performance Analysis
Analyzes ALL trades (wins AND losses) to identify patterns and optimization opportunities
"""

import json
import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple

class ComprehensivePerformanceAnalyzer:
    def __init__(self, json_path: str):
        """Load processed trade data"""
        with open(json_path, 'r') as f:
            data = json.load(f)
        
        self.trades_df = pd.DataFrame(data['trades'])
        self.metadata = data['metadata']
        self.statistics = data['statistics']
        
        # Convert numeric columns
        numeric_cols = [col for col in self.trades_df.columns if any(x in col for x in 
            ['Quality', 'Confluence', 'Speed', 'Acceleration', 'Momentum', 'Slope', 'Profit', 
             'MFE', 'MAE', 'RRatio', 'Pips', 'Percent', 'Duration', 'ROI', 'Physics'])]
        
        for col in numeric_cols:
            if col in self.trades_df.columns:
                self.trades_df[col] = pd.to_numeric(self.trades_df[col], errors='coerce')
        
        print(f"✅ Loaded {len(self.trades_df)} trades")
        print(f"   MT5 Total Profit: ${self.trades_df['OUT_Profit_OP_01'].sum():.2f}")
        print(f"   EA Total Profit:  ${self.trades_df['EA_Profit'].sum():.2f}")
    
    def generate_comprehensive_report(self, output_dir: str = 'output'):
        """Generate complete performance analysis report"""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        print("\n" + "="*80)
        print("COMPREHENSIVE PERFORMANCE OPTIMIZATION REPORT")
        print("="*80)
        
        # 1. Executive Summary
        summary = self._executive_summary()
        
        # 2. Win/Loss Analysis
        win_loss = self._win_loss_analysis()
        
        # 3. Physics Metrics Analysis (Winners vs Losers)
        physics = self._physics_analysis()
        
        # 4. Time-based Patterns
        time_patterns = self._time_analysis()
        
        # 5. Trade Duration Analysis
        duration = self._duration_analysis()
        
        # 6. Excursion Analysis (MFE/MAE)
        excursion = self._excursion_analysis()
        
        # 7. Exit Reason Analysis
        exit_reasons = self._exit_reason_analysis()
        
        # 8. Zone & Regime Analysis
        zones = self._zone_regime_analysis()
        
        # 9. Signal Decay Analysis
        decay = self._decay_analysis()
        
        # 10. Recommendations
        recommendations = self._generate_recommendations(summary, win_loss, physics, time_patterns)
        
        # Build comprehensive report
        report = self._build_markdown_report(
            summary, win_loss, physics, time_patterns, 
            duration, excursion, exit_reasons, zones, decay, recommendations
        )
        
        # Export report
        report_path = output_path / 'COMPREHENSIVE_PERFORMANCE_REPORT.md'
        with open(report_path, 'w') as f:
            f.write(report)
        
        print(f"\n✅ Report saved to: {report_path}")
        
        # Export detailed CSV analysis
        self._export_detailed_csvs(output_path)
        
        return report
    
    def _executive_summary(self) -> Dict:
        """Generate executive summary statistics"""
        total_trades = len(self.trades_df)
        
        # Categorize by result
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        breakeven = self.trades_df[self.trades_df['Trade_Result'] == 'Breakeven']
        
        total_profit = self.trades_df['OUT_Profit_OP_01'].sum()
        win_profit = wins['OUT_Profit_OP_01'].sum()
        loss_profit = losses['OUT_Profit_OP_01'].sum()
        
        avg_win = wins['OUT_Profit_OP_01'].mean() if len(wins) > 0 else 0
        avg_loss = losses['OUT_Profit_OP_01'].mean() if len(losses) > 0 else 0
        
        win_rate = (len(wins) / total_trades * 100) if total_trades > 0 else 0
        
        # Profit factor
        profit_factor = abs(win_profit / loss_profit) if loss_profit != 0 else float('inf')
        
        # Expectancy
        expectancy = (win_rate/100 * avg_win) + ((100-win_rate)/100 * avg_loss)
        
        summary = {
            'total_trades': total_trades,
            'wins': len(wins),
            'losses': len(losses),
            'breakeven': len(breakeven),
            'win_rate': win_rate,
            'total_profit': total_profit,
            'win_profit': win_profit,
            'loss_profit': loss_profit,
            'avg_win': avg_win,
            'avg_loss': avg_loss,
            'profit_factor': profit_factor,
            'expectancy': expectancy,
            'largest_win': wins['OUT_Profit_OP_01'].max() if len(wins) > 0 else 0,
            'largest_loss': losses['OUT_Profit_OP_01'].min() if len(losses) > 0 else 0
        }
        
        print(f"\n📊 EXECUTIVE SUMMARY")
        print(f"   Total Trades: {total_trades}")
        print(f"   Winners: {len(wins)} ({win_rate:.1f}%)")
        print(f"   Losers: {len(losses)} ({len(losses)/total_trades*100:.1f}%)")
        print(f"   Breakeven: {len(breakeven)}")
        print(f"   Total Profit: ${total_profit:.2f}")
        print(f"   Profit Factor: {profit_factor:.2f}")
        print(f"   Expectancy: ${expectancy:.2f} per trade")
        
        return summary
    
    def _win_loss_analysis(self) -> Dict:
        """Detailed win/loss breakdown"""
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        # By direction
        long_wins = wins[wins['Trade_Direction'] == 'Long']
        short_wins = wins[wins['Trade_Direction'] == 'Short']
        long_losses = losses[losses['Trade_Direction'] == 'Long']
        short_losses = losses[losses['Trade_Direction'] == 'Short']
        
        print(f"\n📈 WIN/LOSS BY DIRECTION")
        print(f"   LONG:  {len(long_wins)} wins, {len(long_losses)} losses")
        print(f"   SHORT: {len(short_wins)} wins, {len(short_losses)} losses")
        
        return {
            'long_wins': len(long_wins),
            'long_losses': len(long_losses),
            'short_wins': len(short_wins),
            'short_losses': len(short_losses),
            'long_win_rate': len(long_wins)/(len(long_wins)+len(long_losses))*100 if (len(long_wins)+len(long_losses)) > 0 else 0,
            'short_win_rate': len(short_wins)/(len(short_wins)+len(short_losses))*100 if (len(short_wins)+len(short_losses)) > 0 else 0
        }
    
    def _physics_analysis(self) -> Dict:
        """Analyze physics metrics for winners vs losers"""
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        metrics = ['EA_Entry_Quality', 'EA_Entry_Confluence', 'EA_Entry_PhysicsScore',
                   'EA_Entry_Speed', 'EA_Entry_SpeedSlope', 'EA_Entry_AccelerationSlope']
        
        print(f"\n🔬 PHYSICS METRICS COMPARISON")
        print(f"{'Metric':<30} {'Winners (avg)':<15} {'Losers (avg)':<15} {'Difference':<15}")
        print("-" * 80)
        
        analysis = {}
        for metric in metrics:
            if metric in wins.columns and metric in losses.columns:
                win_avg = wins[metric].mean()
                loss_avg = losses[metric].mean()
                diff = win_avg - loss_avg
                
                print(f"{metric:<30} {win_avg:>14.2f} {loss_avg:>14.2f} {diff:>+14.2f}")
                
                analysis[metric] = {
                    'win_avg': win_avg,
                    'loss_avg': loss_avg,
                    'difference': diff,
                    'win_std': wins[metric].std(),
                    'loss_std': losses[metric].std()
                }
        
        return analysis
    
    def _time_analysis(self) -> Dict:
        """Analyze performance by time segments and sessions"""
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        # By 1H segment
        print(f"\n⏰ PERFORMANCE BY TIME SEGMENT (1H)")
        segment_analysis = {}
        
        for segment in sorted(self.trades_df['IN_Segment_01H_OP_01'].unique()):
            segment_trades = self.trades_df[self.trades_df['IN_Segment_01H_OP_01'] == segment]
            segment_wins = segment_trades[segment_trades['Trade_Result'] == 'Win']
            segment_losses = segment_trades[segment_trades['Trade_Result'] == 'Loss']
            
            total = len(segment_trades)
            win_count = len(segment_wins)
            loss_count = len(segment_losses)
            win_rate = (win_count / total * 100) if total > 0 else 0
            profit = segment_trades['OUT_Profit_OP_01'].sum()
            
            if total > 0:
                segment_analysis[segment] = {
                    'total': total,
                    'wins': win_count,
                    'losses': loss_count,
                    'win_rate': win_rate,
                    'profit': profit,
                    'avg_profit': profit / total
                }
                
                print(f"   {segment}: {win_count}W/{loss_count}L ({win_rate:.1f}%) | Profit: ${profit:>8.2f} | Avg: ${profit/total:>7.2f}")
        
        # By session
        print(f"\n📅 PERFORMANCE BY SESSION")
        session_analysis = {}
        
        for session in sorted(self.trades_df['IN_Session_Name_OP_02'].unique()):
            session_trades = self.trades_df[self.trades_df['IN_Session_Name_OP_02'] == session]
            session_wins = session_trades[session_trades['Trade_Result'] == 'Win']
            session_losses = session_trades[session_trades['Trade_Result'] == 'Loss']
            
            total = len(session_trades)
            win_count = len(session_wins)
            loss_count = len(session_losses)
            win_rate = (win_count / total * 100) if total > 0 else 0
            profit = session_trades['OUT_Profit_OP_01'].sum()
            
            if total > 0:
                session_analysis[session] = {
                    'total': total,
                    'wins': win_count,
                    'losses': loss_count,
                    'win_rate': win_rate,
                    'profit': profit
                }
                
                print(f"   {session}: {win_count}W/{loss_count}L ({win_rate:.1f}%) | Profit: ${profit:>8.2f}")
        
        return {
            'segments': segment_analysis,
            'sessions': session_analysis
        }
    
    def _duration_analysis(self) -> Dict:
        """Analyze trade duration patterns"""
        print(f"\n⏱️  TRADE DURATION ANALYSIS")
        
        durations = self.trades_df['Trade_Duration_Minutes'].describe()
        print(f"   Min: {durations['min']:.0f} min")
        print(f"   25%: {durations['25%']:.0f} min")
        print(f"   Median: {durations['50%']:.0f} min")
        print(f"   75%: {durations['75%']:.0f} min")
        print(f"   Max: {durations['max']:.0f} min")
        
        # Duration vs outcome
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        avg_win_duration = wins['Trade_Duration_Minutes'].mean()
        avg_loss_duration = losses['Trade_Duration_Minutes'].mean()
        
        print(f"\n   Average Duration:")
        print(f"   Winners: {avg_win_duration:.0f} min")
        print(f"   Losers: {avg_loss_duration:.0f} min")
        print(f"   Difference: {avg_win_duration - avg_loss_duration:+.0f} min")
        
        return {
            'summary': durations.to_dict(),
            'avg_win_duration': avg_win_duration,
            'avg_loss_duration': avg_loss_duration
        }
    
    def _excursion_analysis(self) -> Dict:
        """Analyze MFE/MAE patterns"""
        print(f"\n📊 EXCURSION ANALYSIS (MFE/MAE)")
        
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        # MFE utilization
        win_mfe_util = wins['EA_MFEUtilization'].mean()
        loss_mfe_util = losses['EA_MFEUtilization'].mean()
        
        print(f"   MFE Utilization:")
        print(f"   Winners: {win_mfe_util:.1f}%")
        print(f"   Losers: {loss_mfe_util:.1f}%")
        
        # MAE impact
        win_mae_impact = wins['EA_MAEImpact'].mean()
        loss_mae_impact = losses['EA_MAEImpact'].mean()
        
        print(f"\n   MAE Impact:")
        print(f"   Winners: {win_mae_impact:.1f}%")
        print(f"   Losers: {loss_mae_impact:.1f}%")
        
        # Excursion efficiency
        win_exc_eff = wins['EA_ExcursionEfficiency'].mean()
        loss_exc_eff = losses['EA_ExcursionEfficiency'].mean()
        
        print(f"\n   Excursion Efficiency:")
        print(f"   Winners: {win_exc_eff:.2f}")
        print(f"   Losers: {loss_exc_eff:.2f}")
        
        return {
            'mfe_util_winners': win_mfe_util,
            'mfe_util_losers': loss_mfe_util,
            'mae_impact_winners': win_mae_impact,
            'mae_impact_losers': loss_mae_impact,
            'exc_eff_winners': win_exc_eff,
            'exc_eff_losers': loss_exc_eff
        }
    
    def _exit_reason_analysis(self) -> Dict:
        """Analyze exit reasons and their profitability"""
        print(f"\n🚪 EXIT REASON ANALYSIS")
        
        exit_analysis = {}
        
        for reason in self.trades_df['EA_ExitReason'].unique():
            if pd.isna(reason) or reason == '':
                continue
                
            reason_trades = self.trades_df[self.trades_df['EA_ExitReason'] == reason]
            wins = reason_trades[reason_trades['Trade_Result'] == 'Win']
            losses = reason_trades[reason_trades['Trade_Result'] == 'Loss']
            
            total = len(reason_trades)
            win_rate = (len(wins) / total * 100) if total > 0 else 0
            avg_profit = reason_trades['OUT_Profit_OP_01'].mean()
            total_profit = reason_trades['OUT_Profit_OP_01'].sum()
            
            exit_analysis[reason] = {
                'count': total,
                'wins': len(wins),
                'losses': len(losses),
                'win_rate': win_rate,
                'avg_profit': avg_profit,
                'total_profit': total_profit
            }
            
            print(f"   {reason:<20}: {len(wins)}W/{len(losses)}L ({win_rate:>5.1f}%) | Avg: ${avg_profit:>7.2f} | Total: ${total_profit:>8.2f}")
        
        return exit_analysis
    
    def _zone_regime_analysis(self) -> Dict:
        """Analyze performance by zone and regime"""
        print(f"\n🎯 ZONE & REGIME ANALYSIS")
        
        # Entry zones
        print(f"\n   Entry Zones:")
        zone_analysis = {}
        
        for zone in self.trades_df['EA_Entry_Zone'].unique():
            if pd.isna(zone) or zone == '':
                continue
                
            zone_trades = self.trades_df[self.trades_df['EA_Entry_Zone'] == zone]
            wins = zone_trades[zone_trades['Trade_Result'] == 'Win']
            
            total = len(zone_trades)
            win_rate = (len(wins) / total * 100) if total > 0 else 0
            profit = zone_trades['OUT_Profit_OP_01'].sum()
            
            zone_analysis[zone] = {
                'count': total,
                'win_rate': win_rate,
                'profit': profit
            }
            
            print(f"   {zone:<15}: {total} trades | {win_rate:.1f}% WR | ${profit:>8.2f}")
        
        # Entry regimes
        print(f"\n   Entry Regimes:")
        regime_analysis = {}
        
        for regime in self.trades_df['EA_Entry_Regime'].unique():
            if pd.isna(regime) or regime == '':
                continue
                
            regime_trades = self.trades_df[self.trades_df['EA_Entry_Regime'] == regime]
            wins = regime_trades[regime_trades['Trade_Result'] == 'Win']
            
            total = len(regime_trades)
            win_rate = (len(wins) / total * 100) if total > 0 else 0
            profit = regime_trades['OUT_Profit_OP_01'].sum()
            
            regime_analysis[regime] = {
                'count': total,
                'win_rate': win_rate,
                'profit': profit
            }
            
            print(f"   {regime:<15}: {total} trades | {win_rate:.1f}% WR | ${profit:>8.2f}")
        
        return {
            'zones': zone_analysis,
            'regimes': regime_analysis
        }
    
    def _decay_analysis(self) -> Dict:
        """Analyze physics decay patterns"""
        print(f"\n📉 PHYSICS DECAY ANALYSIS")
        
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        
        decay_metrics = ['EA_PhysicsScoreDecay', 'EA_SpeedDecay', 'EA_SpeedSlopeDecay', 'EA_ConfluenceDecay']
        
        decay_analysis = {}
        
        for metric in decay_metrics:
            if metric in wins.columns:
                win_avg = wins[metric].mean()
                loss_avg = losses[metric].mean()
                
                decay_analysis[metric] = {
                    'win_avg': win_avg,
                    'loss_avg': loss_avg,
                    'difference': win_avg - loss_avg
                }
                
                print(f"   {metric:<30}: Winners={win_avg:>7.2f}, Losers={loss_avg:>7.2f}, Diff={win_avg-loss_avg:>+7.2f}")
        
        return decay_analysis
    
    def _generate_recommendations(self, summary: Dict, win_loss: Dict, physics: Dict, time_patterns: Dict) -> List[str]:
        """Generate actionable recommendations"""
        recommendations = []
        
        # Win rate recommendations
        if summary['win_rate'] < 50:
            recommendations.append(f"⚠️  Win rate ({summary['win_rate']:.1f}%) is below 50%. Consider tightening entry filters.")
        
        # Profit factor recommendations
        if summary['profit_factor'] < 1.5:
            recommendations.append(f"⚠️  Profit factor ({summary['profit_factor']:.2f}) is low. Focus on reducing loss size or increasing winners.")
        
        # Direction bias
        if win_loss['long_win_rate'] > win_loss['short_win_rate'] + 10:
            recommendations.append(f"✅ LONG trades perform significantly better ({win_loss['long_win_rate']:.1f}% vs {win_loss['short_win_rate']:.1f}%). Consider favoring longs.")
        elif win_loss['short_win_rate'] > win_loss['long_win_rate'] + 10:
            recommendations.append(f"✅ SHORT trades perform significantly better ({win_loss['short_win_rate']:.1f}% vs {win_loss['long_win_rate']:.1f}%). Consider favoring shorts.")
        
        # Physics thresholds
        for metric, data in physics.items():
            if data['difference'] > 0:
                recommendations.append(f"📊 {metric}: Winners average {data['win_avg']:.2f} vs losers {data['loss_avg']:.2f}. Set minimum threshold at {data['loss_avg']*1.1:.2f}")
        
        # Time-based recommendations
        best_segment = max(time_patterns['segments'].items(), key=lambda x: x[1]['win_rate'])
        worst_segment = min(time_patterns['segments'].items(), key=lambda x: x[1]['win_rate'])
        
        recommendations.append(f"⏰ Best time segment: {best_segment[0]} ({best_segment[1]['win_rate']:.1f}% WR, ${best_segment[1]['profit']:.2f})")
        recommendations.append(f"⚠️  Worst time segment: {worst_segment[0]} ({worst_segment[1]['win_rate']:.1f}% WR, ${worst_segment[1]['profit']:.2f}). Consider avoiding.")
        
        return recommendations
    
    def _build_markdown_report(self, summary, win_loss, physics, time_patterns, duration, excursion, exit_reasons, zones, decay, recommendations):
        """Build complete markdown report"""
        
        report = f"""# COMPREHENSIVE PERFORMANCE OPTIMIZATION REPORT

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Dataset:** {self.metadata['sourceFiles']['mt5Report']}
**Total Trades Analyzed:** {summary['total_trades']}

---

## 📊 EXECUTIVE SUMMARY

### Overall Performance
- **Total Trades:** {summary['total_trades']}
- **Winners:** {summary['wins']} ({summary['win_rate']:.1f}%)
- **Losers:** {summary['losses']} ({summary['losses']/summary['total_trades']*100:.1f}%)
- **Breakeven:** {summary['breakeven']}

### Profitability Metrics
- **Total Profit/Loss:** ${summary['total_profit']:.2f}
- **Gross Profit (Winners):** ${summary['win_profit']:.2f}
- **Gross Loss (Losers):** ${summary['loss_profit']:.2f}
- **Average Winner:** ${summary['avg_win']:.2f}
- **Average Loser:** ${summary['avg_loss']:.2f}
- **Profit Factor:** {summary['profit_factor']:.2f}
- **Expectancy:** ${summary['expectancy']:.2f} per trade
- **Largest Win:** ${summary['largest_win']:.2f}
- **Largest Loss:** ${summary['largest_loss']:.2f}

### Risk-Reward Profile
- **Win/Loss Ratio:** {abs(summary['avg_win']/summary['avg_loss']):.2f}:1
- **Expected Value:** ${summary['expectancy']:.2f} per trade

---

## 📈 WIN/LOSS ANALYSIS

### By Direction
- **LONG Trades:**
  - Wins: {win_loss['long_wins']}
  - Losses: {win_loss['long_losses']}
  - Win Rate: {win_loss['long_win_rate']:.1f}%

- **SHORT Trades:**
  - Wins: {win_loss['short_wins']}
  - Losses: {win_loss['short_losses']}
  - Win Rate: {win_loss['short_win_rate']:.1f}%

### Key Finding
{"✅ **SHORT trades significantly outperform LONG trades**" if win_loss['short_win_rate'] > win_loss['long_win_rate'] + 5 else "✅ **LONG trades significantly outperform SHORT trades**" if win_loss['long_win_rate'] > win_loss['short_win_rate'] + 5 else "Both directions perform similarly"}

---

## 🔬 PHYSICS METRICS: WINNERS VS LOSERS

| Metric | Winners (Avg) | Losers (Avg) | Difference | Insight |
|--------|--------------|--------------|------------|---------|
"""
        
        for metric, data in physics.items():
            metric_name = metric.replace('EA_Entry_', '')
            insight = "✅ Higher is better" if data['difference'] > 0 else "⚠️  Losers higher"
            report += f"| {metric_name} | {data['win_avg']:.2f} | {data['loss_avg']:.2f} | {data['difference']:+.2f} | {insight} |\n"
        
        report += f"""
### Recommended Minimum Thresholds
Based on the analysis above, to filter out potential losers:

"""
        
        for metric, data in physics.items():
            if data['difference'] > 0:
                threshold = data['loss_avg'] * 1.1  # 10% above loser average
                metric_name = metric.replace('EA_Entry_', '')
                report += f"- **{metric_name}:** ≥ {threshold:.2f}\n"
        
        report += f"""
---

## ⏰ TIME-BASED PERFORMANCE

### By Hour Segment (Best to Worst)
"""
        
        sorted_segments = sorted(time_patterns['segments'].items(), key=lambda x: x[1]['win_rate'], reverse=True)
        for segment, data in sorted_segments[:10]:  # Top 10
            report += f"- **{segment}:** {data['wins']}W/{data['losses']}L ({data['win_rate']:.1f}%) | Profit: ${data['profit']:.2f} | Avg: ${data['avg_profit']:.2f}\n"
        
        report += f"""
### By Trading Session
"""
        
        for session, data in time_patterns['sessions'].items():
            report += f"- **{session}:** {data['wins']}W/{data['losses']}L ({data['win_rate']:.1f}%) | Total Profit: ${data['profit']:.2f}\n"
        
        report += f"""
---

## ⏱️  TRADE DURATION PATTERNS

### Duration Statistics
- **Minimum:** {duration['summary']['min']:.0f} minutes
- **25th Percentile:** {duration['summary']['25%']:.0f} minutes
- **Median:** {duration['summary']['50%']:.0f} minutes
- **75th Percentile:** {duration['summary']['75%']:.0f} minutes
- **Maximum:** {duration['summary']['max']:.0f} minutes

### Duration vs Outcome
- **Average Winner Duration:** {duration['avg_win_duration']:.0f} minutes
- **Average Loser Duration:** {duration['avg_loss_duration']:.0f} minutes
- **Difference:** {duration['avg_win_duration'] - duration['avg_loss_duration']:+.0f} minutes

{"✅ Winners hold longer on average" if duration['avg_win_duration'] > duration['avg_loss_duration'] else "⚠️  Losers hold longer - consider tighter stops"}

---

## 📊 EXCURSION ANALYSIS (MFE/MAE)

### MFE Utilization (How much of potential profit captured)
- **Winners:** {excursion['mfe_util_winners']:.1f}%
- **Losers:** {excursion['mfe_util_losers']:.1f}%

### MAE Impact (Adverse excursion impact)
- **Winners:** {excursion['mae_impact_winners']:.1f}%
- **Losers:** {excursion['mae_impact_losers']:.1f}%

### Excursion Efficiency (MFE/MAE ratio)
- **Winners:** {excursion['exc_eff_winners']:.2f}
- **Losers:** {excursion['exc_eff_losers']:.2f}

**Key Insight:** {"Winners capture more of potential profit and minimize adverse excursion" if excursion['exc_eff_winners'] > excursion['exc_eff_losers'] else "Need to improve profit capture and reduce adverse movement"}

---

## 🚪 EXIT REASON BREAKDOWN

| Exit Reason | Trades | Wins | Losses | Win Rate | Avg Profit | Total Profit |
|-------------|--------|------|--------|----------|------------|--------------|
"""
        
        sorted_exits = sorted(exit_reasons.items(), key=lambda x: x[1]['total_profit'], reverse=True)
        for reason, data in sorted_exits:
            report += f"| {reason} | {data['count']} | {data['wins']} | {data['losses']} | {data['win_rate']:.1f}% | ${data['avg_profit']:.2f} | ${data['total_profit']:.2f} |\n"
        
        report += f"""
---

## 🎯 ZONE & REGIME PERFORMANCE

### Entry Zones
"""
        
        for zone, data in zones['zones'].items():
            report += f"- **{zone}:** {data['count']} trades | {data['win_rate']:.1f}% WR | ${data['profit']:.2f}\n"
        
        report += f"""
### Entry Regimes
"""
        
        for regime, data in zones['regimes'].items():
            report += f"- **{regime}:** {data['count']} trades | {data['win_rate']:.1f}% WR | ${data['profit']:.2f}\n"
        
        report += f"""
---

## 📉 PHYSICS DECAY PATTERNS

How much do physics metrics decay from entry to exit?

| Metric | Winners (Avg Decay) | Losers (Avg Decay) | Difference |
|--------|--------------------|--------------------|------------|
"""
        
        for metric, data in decay.items():
            metric_name = metric.replace('EA_', '')
            report += f"| {metric_name} | {data['win_avg']:.2f} | {data['loss_avg']:.2f} | {data['difference']:+.2f} |\n"
        
        report += f"""
**Insight:** {"Winners show less physics decay, maintaining momentum longer" if any(d['difference'] < 0 for d in decay.values()) else "Losers decay faster - exit sooner when physics deteriorate"}

---

## 🎯 ACTIONABLE RECOMMENDATIONS

"""
        
        for i, rec in enumerate(recommendations, 1):
            report += f"{i}. {rec}\n"
        
        report += f"""
---

## 📋 OPTIMIZATION CHECKLIST

### Entry Filters (Apply These Minimums)
"""
        
        for metric, data in physics.items():
            if data['difference'] > 0:
                threshold = data['loss_avg'] * 1.1
                metric_name = metric.replace('EA_Entry_', '')
                report += f"- [ ] {metric_name} ≥ {threshold:.2f}\n"
        
        best_session = max(time_patterns['sessions'].items(), key=lambda x: x[1]['win_rate'])
        worst_session = min(time_patterns['sessions'].items(), key=lambda x: x[1]['win_rate'])
        
        report += f"""
### Time Filters
- [ ] Favor {best_session[0]} session ({best_session[1]['win_rate']:.1f}% WR)
- [ ] Avoid {worst_session[0]} session ({worst_session[1]['win_rate']:.1f}% WR)

### Direction Preference
- [ ] {"Favor SHORT trades" if win_loss['short_win_rate'] > win_loss['long_win_rate'] else "Favor LONG trades"} (Better win rate: {max(win_loss['short_win_rate'], win_loss['long_win_rate']):.1f}%)

### Exit Management
"""
        
        best_exit = max(exit_reasons.items(), key=lambda x: x[1]['win_rate'])
        report += f"- [ ] Monitor for {best_exit[0]} exits (highest win rate: {best_exit[1]['win_rate']:.1f}%)\n"
        
        if duration['avg_loss_duration'] > duration['avg_win_duration']:
            report += f"- [ ] Implement tighter time-based stops (losers hold {duration['avg_loss_duration']:.0f} min vs winners {duration['avg_win_duration']:.0f} min)\n"
        
        report += f"""
---

## 📁 DETAILED DATA EXPORTS

Additional CSV files have been generated for deeper analysis:

1. **winners_analysis.csv** - All winning trades with full metrics
2. **losers_analysis.csv** - All losing trades with full metrics
3. **time_segment_performance.csv** - Performance breakdown by hour
4. **physics_comparison.csv** - Side-by-side physics metrics for winners vs losers
5. **exit_reason_performance.csv** - Detailed exit reason profitability

---

**Report End**

*Generated by Comprehensive Performance Analyzer v1.0*
"""
        
        return report
    
    def _export_detailed_csvs(self, output_path: Path):
        """Export detailed CSV analyses"""
        
        # Winners
        wins = self.trades_df[self.trades_df['Trade_Result'] == 'Win']
        wins.to_csv(output_path / 'winners_analysis.csv', index=False)
        print(f"✅ Exported winners_analysis.csv ({len(wins)} trades)")
        
        # Losers
        losses = self.trades_df[self.trades_df['Trade_Result'] == 'Loss']
        losses.to_csv(output_path / 'losers_analysis.csv', index=False)
        print(f"✅ Exported losers_analysis.csv ({len(losses)} trades)")
        
        # Time segment performance
        segment_perf = self.trades_df.groupby('IN_Segment_01H_OP_01').agg({
            'OUT_Profit_OP_01': ['count', 'sum', 'mean'],
            'Trade_Result': lambda x: (x == 'Win').sum()
        }).reset_index()
        segment_perf.columns = ['Segment', 'Total_Trades', 'Total_Profit', 'Avg_Profit', 'Wins']
        segment_perf['Win_Rate'] = (segment_perf['Wins'] / segment_perf['Total_Trades'] * 100).round(1)
        segment_perf = segment_perf.sort_values('Win_Rate', ascending=False)
        segment_perf.to_csv(output_path / 'time_segment_performance.csv', index=False)
        print(f"✅ Exported time_segment_performance.csv")
        
        # Physics comparison
        physics_metrics = [col for col in self.trades_df.columns if 'EA_Entry' in col and any(x in col for x in ['Quality', 'Confluence', 'Speed', 'Slope', 'Physics'])]
        
        physics_comp = pd.DataFrame({
            'Metric': physics_metrics,
            'Winners_Mean': [wins[m].mean() for m in physics_metrics],
            'Winners_Std': [wins[m].std() for m in physics_metrics],
            'Losers_Mean': [losses[m].mean() for m in physics_metrics],
            'Losers_Std': [losses[m].std() for m in physics_metrics],
        })
        physics_comp['Difference'] = physics_comp['Winners_Mean'] - physics_comp['Losers_Mean']
        physics_comp['Recommended_Min'] = (physics_comp['Losers_Mean'] * 1.1).round(2)
        physics_comp = physics_comp.sort_values('Difference', ascending=False)
        physics_comp.to_csv(output_path / 'physics_comparison.csv', index=False)
        print(f"✅ Exported physics_comparison.csv")
        
        # Exit reason performance
        exit_perf = self.trades_df.groupby('EA_ExitReason').agg({
            'OUT_Profit_OP_01': ['count', 'sum', 'mean'],
            'Trade_Result': lambda x: (x == 'Win').sum()
        }).reset_index()
        exit_perf.columns = ['Exit_Reason', 'Total_Trades', 'Total_Profit', 'Avg_Profit', 'Wins']
        exit_perf['Win_Rate'] = (exit_perf['Wins'] / exit_perf['Total_Trades'] * 100).round(1)
        exit_perf = exit_perf.sort_values('Total_Profit', ascending=False)
        exit_perf.to_csv(output_path / 'exit_reason_performance.csv', index=False)
        print(f"✅ Exported exit_reason_performance.csv")

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        json_path = 'output/processed_trades_2025-11-22.json'
    else:
        json_path = sys.argv[1]
    
    print(f"📂 Loading: {json_path}")
    
    analyzer = ComprehensivePerformanceAnalyzer(json_path)
    report = analyzer.generate_comprehensive_report()
    
    print("\n" + "="*80)
    print("✅ COMPREHENSIVE ANALYSIS COMPLETE!")
    print("="*80)
