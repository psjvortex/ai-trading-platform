#!/usr/bin/env python3
"""
TickPhysics Self-Learning Engine
Analyzes trade results and automatically updates EA configuration
"""

import pandas as pd
import numpy as np
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple, Any
import logging

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SelfLearningEngine:
    """Autonomous EA optimization engine"""
    
    def __init__(self, config_path: str, trades_csv_path: str):
        self.config_path = Path(config_path)
        self.trades_csv_path = Path(trades_csv_path)
        self.config = self.load_config()
        self.trades_df = None
        
    def load_config(self) -> Dict:
        """Load current EA configuration"""
        with open(self.config_path, 'r') as f:
            return json.load(f)
    
    def save_config(self):
        """Save updated configuration"""
        self.config['meta']['last_updated'] = datetime.now().isoformat()
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f, indent=2)
        logger.info(f"✅ Config saved: {self.config_path}")
    
    def load_trades(self) -> pd.DataFrame:
        """Load trade history CSV"""
        if not self.trades_csv_path.exists():
            logger.error(f"❌ Trades file not found: {self.trades_csv_path}")
            return None
        
        df = pd.read_csv(self.trades_csv_path)
        logger.info(f"📊 Loaded {len(df)} trades from {self.trades_csv_path.name}")
        return df
    
    def analyze_time_of_day_performance(self) -> Dict[int, Dict]:
        """Analyze performance by hour of day"""
        if self.trades_df is None:
            return {}
        
        hourly_stats = {}
        
        for hour in range(24):
            hour_trades = self.trades_df[self.trades_df['Entry_Hour'] == hour]
            
            if len(hour_trades) == 0:
                continue
            
            wins = hour_trades[hour_trades['Profit'] > 0]
            win_rate = len(wins) / len(hour_trades) if len(hour_trades) > 0 else 0
            avg_profit = hour_trades['Profit'].mean()
            total_profit = hour_trades['Profit'].sum()
            
            hourly_stats[hour] = {
                'trades': len(hour_trades),
                'win_rate': win_rate,
                'avg_profit': avg_profit,
                'total_profit': total_profit,
                'profitable': total_profit > 0
            }
        
        return hourly_stats
    
    def analyze_day_of_week_performance(self) -> Dict[int, Dict]:
        """Analyze performance by day of week"""
        if self.trades_df is None:
            return {}
        
        daily_stats = {}
        day_names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        
        for day in range(7):
            day_trades = self.trades_df[self.trades_df['Entry_DayOfWeek'] == day]
            
            if len(day_trades) == 0:
                continue
            
            wins = day_trades[day_trades['Profit'] > 0]
            win_rate = len(wins) / len(day_trades) if len(day_trades) > 0 else 0
            avg_profit = day_trades['Profit'].mean()
            total_profit = day_trades['Profit'].sum()
            
            daily_stats[day] = {
                'day_name': day_names[day],
                'trades': len(day_trades),
                'win_rate': win_rate,
                'avg_profit': avg_profit,
                'total_profit': total_profit,
                'profitable': total_profit > 0
            }
        
        return daily_stats
    
    def optimize_time_filters(self) -> Tuple[List[int], List[int], List[int]]:
        """Determine optimal time filters based on performance"""
        hourly_stats = self.analyze_time_of_day_performance()
        
        # Define thresholds
        min_trades = 10
        min_win_rate = self.config['performance_thresholds']['acceptable_win_rate']
        
        allowed_hours = []
        blocked_hours = []
        
        for hour, stats in hourly_stats.items():
            if stats['trades'] < min_trades:
                continue  # Not enough data
            
            if stats['win_rate'] >= min_win_rate and stats['profitable']:
                allowed_hours.append(hour)
            elif stats['win_rate'] < (min_win_rate * 0.8) or not stats['profitable']:
                blocked_hours.append(hour)
        
        # Analyze days
        daily_stats = self.analyze_day_of_week_performance()
        blocked_days = []
        
        for day, stats in daily_stats.items():
            if stats['trades'] < min_trades:
                continue
            
            if stats['win_rate'] < (min_win_rate * 0.8) or not stats['profitable']:
                blocked_days.append(day)
        
        return sorted(allowed_hours), sorted(blocked_hours), sorted(blocked_days)
    
    def optimize_physics_filters(self) -> Dict:
        """Optimize physics filter thresholds"""
        if self.trades_df is None:
            return {}
        
        # Analyze quality threshold
        quality_analysis = {}
        for threshold in [60, 65, 70, 75, 80]:
            high_quality = self.trades_df[self.trades_df['Entry_Quality'] >= threshold]
            if len(high_quality) > 0:
                wins = high_quality[high_quality['Profit'] > 0]
                quality_analysis[threshold] = {
                    'trades': len(high_quality),
                    'win_rate': len(wins) / len(high_quality),
                    'avg_profit': high_quality['Profit'].mean()
                }
        
        # Find optimal threshold
        best_threshold = 70
        best_score = 0
        
        for threshold, stats in quality_analysis.items():
            # Score = win_rate * avg_profit * sqrt(trade_count)
            if stats['trades'] > 20:
                score = stats['win_rate'] * stats['avg_profit'] * np.sqrt(stats['trades'])
                if score > best_score:
                    best_score = score
                    best_threshold = threshold
        
        return {
            'optimal_min_quality': best_threshold,
            'analysis': quality_analysis
        }
    
    def calculate_performance_metrics(self) -> Dict:
        """Calculate overall performance metrics"""
        if self.trades_df is None or len(self.trades_df) == 0:
            return {}
        
        wins = self.trades_df[self.trades_df['Profit'] > 0]
        losses = self.trades_df[self.trades_df['Profit'] < 0]
        
        win_rate = len(wins) / len(self.trades_df)
        
        gross_profit = wins['Profit'].sum() if len(wins) > 0 else 0
        gross_loss = abs(losses['Profit'].sum()) if len(losses) > 0 else 0
        profit_factor = gross_profit / gross_loss if gross_loss > 0 else 0
        
        net_profit = self.trades_df['Profit'].sum()
        avg_win = wins['Profit'].mean() if len(wins) > 0 else 0
        avg_loss = losses['Profit'].mean() if len(losses) > 0 else 0
        
        return {
            'total_trades': len(self.trades_df),
            'win_rate': win_rate,
            'profit_factor': profit_factor,
            'net_profit': net_profit,
            'gross_profit': gross_profit,
            'gross_loss': gross_loss,
            'avg_win': avg_win,
            'avg_loss': avg_loss,
            'wins': len(wins),
            'losses': len(losses)
        }
    
    def should_update_config(self) -> Tuple[bool, str]:
        """Determine if config should be updated"""
        if self.trades_df is None or len(self.trades_df) == 0:
            return False, "No trade data available"
        
        # Check if auto-update is enabled
        if not self.config['learning_parameters']['auto_update_enabled']:
            return False, "Auto-update disabled"
        
        # Check minimum trades threshold
        min_trades = self.config['learning_parameters']['min_trades_for_update']
        if len(self.trades_df) < min_trades:
            return False, f"Insufficient trades ({len(self.trades_df)}/{min_trades})"
        
        # Check if enough new trades since last update
        total_analyzed = self.config['meta']['total_trades_analyzed']
        new_trades = len(self.trades_df) - total_analyzed
        update_freq = self.config['learning_parameters']['update_frequency_trades']
        
        if new_trades < update_freq:
            return False, f"Not enough new trades ({new_trades}/{update_freq})"
        
        return True, "Ready for update"
    
    def update_configuration(self, force: bool = False) -> Dict:
        """Main method to analyze and update EA configuration"""
        logger.info("🧠 Starting Self-Learning Analysis...")
        
        # Load trades
        self.trades_df = self.load_trades()
        if self.trades_df is None:
            return {'status': 'error', 'message': 'Failed to load trades'}
        
        # Check if update is needed
        should_update, reason = self.should_update_config()
        if not should_update and not force:
            logger.info(f"⏸️  Update skipped: {reason}")
            return {'status': 'skipped', 'reason': reason}
        
        logger.info(f"✅ Update triggered: {reason if should_update else 'FORCED'}")
        
        # Calculate current performance
        metrics = self.calculate_performance_metrics()
        logger.info(f"📊 Current Performance:")
        logger.info(f"   Win Rate: {metrics['win_rate']:.1%}")
        logger.info(f"   Profit Factor: {metrics['profit_factor']:.2f}")
        logger.info(f"   Net Profit: ${metrics['net_profit']:.2f}")
        
        # Optimize time filters
        logger.info("🕐 Analyzing time patterns...")
        allowed_hours, blocked_hours, blocked_days = self.optimize_time_filters()
        
        logger.info(f"   Optimal Hours: {allowed_hours}")
        logger.info(f"   Blocked Hours: {blocked_hours}")
        logger.info(f"   Blocked Days: {blocked_days}")
        
        # Optimize physics filters
        logger.info("🎯 Optimizing physics filters...")
        physics_opt = self.optimize_physics_filters()
        logger.info(f"   Optimal MinQuality: {physics_opt.get('optimal_min_quality', 70)}")
        
        # Update configuration
        old_config = self.config.copy()
        
        self.config['time_filters']['allowed_hours'] = allowed_hours
        self.config['time_filters']['blocked_hours'] = blocked_hours
        self.config['time_filters']['blocked_days'] = blocked_days
        
        if 'optimal_min_quality' in physics_opt:
            self.config['physics_filters']['min_quality'] = physics_opt['optimal_min_quality']
        
        # Update meta
        self.config['meta']['total_trades_analyzed'] = len(self.trades_df)
        self.config['meta']['optimization_cycle'] += 1
        self.config['meta']['update_trigger'] = 'auto' if should_update else 'forced'
        
        # Add to history
        self.config['optimization_history'].append({
            'version': f"2.6.{self.config['meta']['optimization_cycle']}",
            'date': datetime.now().isoformat(),
            'total_trades': metrics['total_trades'],
            'win_rate': metrics['win_rate'],
            'profit_factor': metrics['profit_factor'],
            'net_profit': metrics['net_profit'],
            'changes': f"Auto-optimized: allowed_hours={allowed_hours}, blocked_days={blocked_days}, min_quality={physics_opt.get('optimal_min_quality', 70)}",
            'result': 'Auto-generated by learning engine'
        })
        
        # Save config
        self.save_config()
        
        logger.info("✅ Configuration updated successfully!")
        
        return {
            'status': 'success',
            'metrics': metrics,
            'changes': {
                'allowed_hours': {'old': old_config['time_filters']['allowed_hours'], 'new': allowed_hours},
                'blocked_hours': {'old': old_config['time_filters']['blocked_hours'], 'new': blocked_hours},
                'blocked_days': {'old': old_config['time_filters']['blocked_days'], 'new': blocked_days},
                'min_quality': {
                    'old': old_config['physics_filters']['min_quality'],
                    'new': self.config['physics_filters']['min_quality']
                }
            }
        }
    
    def generate_report(self) -> str:
        """Generate detailed performance report"""
        self.trades_df = self.load_trades()
        if self.trades_df is None:
            return "No trade data available"
        
        metrics = self.calculate_performance_metrics()
        hourly = self.analyze_time_of_day_performance()
        daily = self.analyze_day_of_week_performance()
        
        report = []
        report.append("=" * 70)
        report.append("TICKPHYSICS SELF-LEARNING REPORT")
        report.append("=" * 70)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Config Version: {self.config['meta']['config_version']}")
        report.append(f"Optimization Cycle: {self.config['meta']['optimization_cycle']}")
        report.append("")
        
        report.append("OVERALL PERFORMANCE")
        report.append("-" * 70)
        report.append(f"Total Trades: {metrics['total_trades']}")
        report.append(f"Win Rate: {metrics['win_rate']:.2%}")
        report.append(f"Profit Factor: {metrics['profit_factor']:.2f}")
        report.append(f"Net Profit: ${metrics['net_profit']:.2f}")
        report.append(f"Avg Win: ${metrics['avg_win']:.2f}")
        report.append(f"Avg Loss: ${metrics['avg_loss']:.2f}")
        report.append("")
        
        report.append("HOURLY PERFORMANCE")
        report.append("-" * 70)
        for hour in sorted(hourly.keys()):
            stats = hourly[hour]
            status = "✅" if stats['profitable'] and stats['win_rate'] > 0.4 else "❌"
            report.append(f"{status} Hour {hour:02d}: {stats['trades']:3d} trades | WR: {stats['win_rate']:.1%} | P/L: ${stats['total_profit']:+.2f}")
        report.append("")
        
        report.append("DAILY PERFORMANCE")
        report.append("-" * 70)
        for day in sorted(daily.keys()):
            stats = daily[day]
            status = "✅" if stats['profitable'] and stats['win_rate'] > 0.4 else "❌"
            report.append(f"{status} {stats['day_name']:9s}: {stats['trades']:3d} trades | WR: {stats['win_rate']:.1%} | P/L: ${stats['total_profit']:+.2f}")
        report.append("")
        
        report.append("CURRENT CONFIGURATION")
        report.append("-" * 70)
        report.append(f"Allowed Hours: {self.config['time_filters']['allowed_hours']}")
        report.append(f"Blocked Hours: {self.config['time_filters']['blocked_hours']}")
        report.append(f"Blocked Days: {[daily[d]['day_name'] for d in self.config['time_filters']['blocked_days']]}")
        report.append(f"Min Quality: {self.config['physics_filters']['min_quality']}")
        report.append("")
        
        report.append("=" * 70)
        
        return "\n".join(report)


def main():
    """Main execution"""
    import argparse
    
    parser = argparse.ArgumentParser(description='TickPhysics Self-Learning Engine')
    parser.add_argument('--config', default='EA_Config_v2_6.json', help='Path to config JSON')
    parser.add_argument('--trades', help='Path to trades CSV file')
    parser.add_argument('--force', action='store_true', help='Force update regardless of thresholds')
    parser.add_argument('--report-only', action='store_true', help='Generate report without updating config')
    
    args = parser.parse_args()
    
    # Auto-detect latest trades file if not specified
    if not args.trades:
        trades_files = sorted(Path('.').glob('TP_Integrated_Trades_*.csv'))
        if trades_files:
            args.trades = str(trades_files[-1])
            logger.info(f"📁 Auto-detected trades file: {args.trades}")
        else:
            logger.error("❌ No trades file found. Specify with --trades")
            return
    
    engine = SelfLearningEngine(args.config, args.trades)
    
    if args.report_only:
        print(engine.generate_report())
    else:
        result = engine.update_configuration(force=args.force)
        print("\n" + engine.generate_report())
        
        if result['status'] == 'success':
            logger.info("\n🎉 Self-learning cycle complete! Config updated.")
        elif result['status'] == 'skipped':
            logger.info(f"\n⏸️  Update skipped: {result['reason']}")


if __name__ == '__main__':
    main()
