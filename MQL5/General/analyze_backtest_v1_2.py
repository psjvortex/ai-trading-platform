#!/usr/bin/env python3
"""
TickPhysics Backtest Analytics - Universal (v1.2 and v1.3+)
Professional-grade trade analysis for institutional review
Supports both legacy (symbol_version) and new (symbol_timeframe_version) formats
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from pathlib import Path
import sys

# Analytics config
from analytics_config import OUTPUT_DIR, DEFAULT_SYMBOL, DEFAULT_TIMEFRAME, DEFAULT_VERSION

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_section(title):
    """Print formatted section header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{title.center(70)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}\n")

def print_metric(label, value, color=Colors.GREEN, unit=""):
    """Print formatted metric"""
    print(f"{Colors.BOLD}{label:40s}{Colors.END} {color}{value}{unit}{Colors.END}")

def load_backtest_data(symbol=DEFAULT_SYMBOL, version=DEFAULT_VERSION):
    """Load backtest CSV files"""
    backtest_dir = Path(OUTPUT_DIR) / "data" / "backtest"
    
    trades_file = backtest_dir / f"TP_Integrated_Trades_{symbol}_v{version}.csv"
    signals_file = backtest_dir / f"TP_Integrated_Signals_{symbol}_v{version}.csv"
    
    if not trades_file.exists():
        print(f"{Colors.RED}ERROR: Trades file not found: {trades_file}{Colors.END}")
        return None, None
    
    if not signals_file.exists():
        print(f"{Colors.RED}ERROR: Signals file not found: {signals_file}{Colors.END}")
        return None, None
    
    # Load trades
    trades_df = pd.read_csv(trades_file)
    trades_df['OpenTime'] = pd.to_datetime(trades_df['OpenTime'])
    trades_df['CloseTime'] = pd.to_datetime(trades_df['CloseTime'])
    
    # Load signals
    signals_df = pd.read_csv(signals_file)
    signals_df['Timestamp'] = pd.to_datetime(signals_df['Timestamp'])
    
    print(f"{Colors.GREEN}✅ Loaded {len(trades_df)} trades and {len(signals_df)} signals{Colors.END}")
    
    return trades_df, signals_df

def analyze_performance(trades_df):
    """Calculate comprehensive performance metrics"""
    print_section("📊 PERFORMANCE SUMMARY")
    
    # Basic stats
    total_trades = len(trades_df)
    winning_trades = len(trades_df[trades_df['Profit'] > 0])
    losing_trades = len(trades_df[trades_df['Profit'] < 0])
    breakeven_trades = len(trades_df[trades_df['Profit'] == 0])
    
    win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0
    
    total_pnl = trades_df['Profit'].sum()
    avg_win = trades_df[trades_df['Profit'] > 0]['Profit'].mean() if winning_trades > 0 else 0
    avg_loss = trades_df[trades_df['Profit'] < 0]['Profit'].mean() if losing_trades > 0 else 0
    
    largest_win = trades_df['Profit'].max()
    largest_loss = trades_df['Profit'].min()
    
    # Print metrics
    print_metric("Total Trades:", str(total_trades))
    print_metric("Winning Trades:", str(winning_trades), Colors.GREEN)
    print_metric("Losing Trades:", str(losing_trades), Colors.RED)
    print_metric("Breakeven Trades:", str(breakeven_trades), Colors.YELLOW)
    print_metric("Win Rate:", f"{win_rate:.2f}", Colors.GREEN, "%")
    print()
    print_metric("Total P&L:", f"${total_pnl:,.2f}", Colors.GREEN if total_pnl >= 0 else Colors.RED)
    print_metric("Average Win:", f"${avg_win:,.2f}", Colors.GREEN)
    print_metric("Average Loss:", f"${avg_loss:,.2f}", Colors.RED)
    print_metric("Largest Win:", f"${largest_win:,.2f}", Colors.GREEN)
    print_metric("Largest Loss:", f"${largest_loss:,.2f}", Colors.RED)
    
    # Risk metrics
    if avg_loss != 0:
        profit_factor = abs(avg_win * winning_trades / (avg_loss * losing_trades)) if losing_trades > 0 else float('inf')
        expectancy = (win_rate/100 * avg_win) + ((1 - win_rate/100) * avg_loss)
        
        print()
        print_metric("Profit Factor:", f"{profit_factor:.2f}", Colors.GREEN if profit_factor > 1 else Colors.RED)
        print_metric("Expectancy:", f"${expectancy:,.2f}", Colors.GREEN if expectancy > 0 else Colors.RED)
    
    # Drawdown analysis
    trades_df['CumulativePnL'] = trades_df['Profit'].cumsum()
    trades_df['RunningMax'] = trades_df['CumulativePnL'].cummax()
    trades_df['Drawdown'] = trades_df['CumulativePnL'] - trades_df['RunningMax']
    
    max_drawdown = trades_df['Drawdown'].min()
    
    print()
    print_metric("Max Drawdown:", f"${max_drawdown:,.2f}", Colors.RED)
    
    return {
        'total_trades': total_trades,
        'win_rate': win_rate,
        'total_pnl': total_pnl,
        'max_drawdown': max_drawdown,
        'profit_factor': profit_factor if avg_loss != 0 else 0
    }

def analyze_by_direction(trades_df):
    """Analyze performance by trade direction"""
    print_section("📈 PERFORMANCE BY DIRECTION")
    
    for direction in ['BUY', 'SELL']:
        dir_trades = trades_df[trades_df['Type'] == direction]
        if len(dir_trades) == 0:
            continue
        
        wins = len(dir_trades[dir_trades['Profit'] > 0])
        total = len(dir_trades)
        win_rate = (wins / total * 100) if total > 0 else 0
        total_pnl = dir_trades['Profit'].sum()
        
        print(f"{Colors.BOLD}{direction} Trades:{Colors.END}")
        print_metric(f"  Count:", str(total))
        print_metric(f"  Win Rate:", f"{win_rate:.2f}", Colors.GREEN, "%")
        print_metric(f"  Total P&L:", f"${total_pnl:,.2f}", Colors.GREEN if total_pnl >= 0 else Colors.RED)
        print()

def analyze_exit_reasons(trades_df):
    """Analyze performance by exit reason"""
    print_section("🚪 EXIT REASON ANALYSIS")
    
    exit_reasons = trades_df['ExitReason'].value_counts()
    
    for reason, count in exit_reasons.items():
        reason_trades = trades_df[trades_df['ExitReason'] == reason]
        pnl = reason_trades['Profit'].sum()
        wins = len(reason_trades[reason_trades['Profit'] > 0])
        win_rate = (wins / count * 100) if count > 0 else 0
        
        print(f"{Colors.BOLD}{reason}:{Colors.END}")
        print_metric(f"  Count:", str(count))
        print_metric(f"  Win Rate:", f"{win_rate:.2f}", Colors.GREEN, "%")
        print_metric(f"  Total P&L:", f"${pnl:,.2f}", Colors.GREEN if pnl >= 0 else Colors.RED)
        print()

def analyze_trade_duration(trades_df):
    """Analyze trade duration patterns"""
    print_section("⏱️  TRADE DURATION ANALYSIS")
    
    trades_df['DurationMinutes'] = (trades_df['CloseTime'] - trades_df['OpenTime']).dt.total_seconds() / 60
    
    avg_duration = trades_df['DurationMinutes'].mean()
    median_duration = trades_df['DurationMinutes'].median()
    min_duration = trades_df['DurationMinutes'].min()
    max_duration = trades_df['DurationMinutes'].max()
    
    print_metric("Average Duration:", f"{avg_duration:.1f}", Colors.CYAN, " minutes")
    print_metric("Median Duration:", f"{median_duration:.1f}", Colors.CYAN, " minutes")
    print_metric("Shortest Trade:", f"{min_duration:.1f}", Colors.CYAN, " minutes")
    print_metric("Longest Trade:", f"{max_duration:.1f}", Colors.CYAN, " minutes")
    
    # Duration vs profitability
    print()
    print(f"{Colors.BOLD}Duration vs Profitability:{Colors.END}")
    
    # Bin trades by duration
    bins = [0, 30, 60, 180, 360, float('inf')]
    labels = ['0-30m', '30-60m', '1-3h', '3-6h', '6h+']
    trades_df['DurationBin'] = pd.cut(trades_df['DurationMinutes'], bins=bins, labels=labels)
    
    for label in labels:
        bin_trades = trades_df[trades_df['DurationBin'] == label]
        if len(bin_trades) > 0:
            wins = len(bin_trades[bin_trades['Profit'] > 0])
            win_rate = (wins / len(bin_trades) * 100)
            avg_pnl = bin_trades['Profit'].mean()
            print_metric(f"  {label}:", f"{len(bin_trades)} trades | WR: {win_rate:.1f}% | Avg: ${avg_pnl:,.2f}")

def analyze_signals(signals_df):
    """Analyze signal generation patterns"""
    print_section("🔔 SIGNAL ANALYSIS")
    
    total_signals = len(signals_df)
    buy_signals = len(signals_df[signals_df['Signal'] == 'BUY'])
    sell_signals = len(signals_df[signals_df['Signal'] == 'SELL'])
    
    print_metric("Total Signals Generated:", str(total_signals))
    print_metric("BUY Signals:", str(buy_signals), Colors.GREEN)
    print_metric("SELL Signals:", str(sell_signals), Colors.RED)
    
    # Signal frequency
    signals_df['Date'] = signals_df['Timestamp'].dt.date
    signals_per_day = signals_df.groupby('Date').size()
    
    print()
    print_metric("Avg Signals per Day:", f"{signals_per_day.mean():.1f}", Colors.CYAN)
    print_metric("Max Signals in a Day:", str(signals_per_day.max()), Colors.CYAN)
    print_metric("Min Signals in a Day:", str(signals_per_day.min()), Colors.CYAN)

def generate_summary_report(trades_df, signals_df, metrics):
    """Generate executive summary report"""
    print_section("📋 EXECUTIVE SUMMARY")
    
    # Backtest period
    start_date = trades_df['OpenTime'].min()
    end_date = trades_df['CloseTime'].max()
    duration_days = (end_date - start_date).days
    
    print(f"{Colors.BOLD}Backtest Period:{Colors.END}")
    print(f"  Start: {start_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  End:   {end_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  Duration: {duration_days} days ({duration_days/7:.1f} weeks)")
    print()
    
    # Key metrics
    print(f"{Colors.BOLD}Key Performance Indicators:{Colors.END}")
    print_metric("Total Trades:", str(metrics['total_trades']))
    print_metric("Win Rate:", f"{metrics['win_rate']:.2f}", Colors.GREEN, "%")
    print_metric("Total P&L:", f"${metrics['total_pnl']:,.2f}", 
                 Colors.GREEN if metrics['total_pnl'] >= 0 else Colors.RED)
    print_metric("Max Drawdown:", f"${metrics['max_drawdown']:,.2f}", Colors.RED)
    print_metric("Profit Factor:", f"{metrics['profit_factor']:.2f}", 
                 Colors.GREEN if metrics['profit_factor'] > 1 else Colors.RED)
    
    # Rating
    print()
    print(f"{Colors.BOLD}Strategy Rating:{Colors.END}")
    
    score = 0
    if metrics['win_rate'] >= 50:
        score += 1
    if metrics['total_pnl'] > 0:
        score += 1
    if metrics['profit_factor'] > 1.5:
        score += 1
    if metrics['max_drawdown'] > -5000:
        score += 1
    
    rating = "★" * score + "☆" * (4 - score)
    rating_color = Colors.GREEN if score >= 3 else (Colors.YELLOW if score == 2 else Colors.RED)
    
    print(f"  {rating_color}{rating} ({score}/4){Colors.END}")
    
    if score >= 3:
        print(f"  {Colors.GREEN}Strong performance - suitable for live testing{Colors.END}")
    elif score == 2:
        print(f"  {Colors.YELLOW}Moderate performance - requires optimization{Colors.END}")
    else:
        print(f"  {Colors.RED}Weak performance - significant improvements needed{Colors.END}")

def main():
    """Main analysis workflow"""
    print(f"{Colors.BOLD}{Colors.BLUE}")
    print("═" * 70)
    print("  TickPhysics Backtest Analytics - NAS100 v1.2".center(70))
    print("  Professional Trade Analysis & Performance Review".center(70))
    print("═" * 70)
    print(f"{Colors.END}")
    
    # Load data
    trades_df, signals_df = load_backtest_data()
    
    if trades_df is None or signals_df is None:
        print(f"{Colors.RED}Failed to load data. Exiting.{Colors.END}")
        return 1
    
    # Run analyses
    metrics = analyze_performance(trades_df)
    analyze_by_direction(trades_df)
    analyze_exit_reasons(trades_df)
    analyze_trade_duration(trades_df)
    analyze_signals(signals_df)
    generate_summary_report(trades_df, signals_df, metrics)
    
    # Export enhanced data
    print_section("💾 EXPORTING ENHANCED DATA")
    
    output_dir = Path(OUTPUT_DIR) / "reports"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Export trades with calculated metrics
    enhanced_trades = trades_df.copy()
    enhanced_trades['DurationMinutes'] = (enhanced_trades['CloseTime'] - enhanced_trades['OpenTime']).dt.total_seconds() / 60
    enhanced_trades['IsWin'] = enhanced_trades['Profit'] > 0
    
    output_file = output_dir / f"enhanced_trades_NAS100_v1.2_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    enhanced_trades.to_csv(output_file, index=False)
    
    print(f"{Colors.GREEN}✅ Enhanced trades exported to:{Colors.END}")
    print(f"   {output_file}")
    
    print(f"\n{Colors.BOLD}{Colors.GREEN}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.GREEN}Analysis Complete!{Colors.END}")
    print(f"{Colors.BOLD}{Colors.GREEN}{'='*70}{Colors.END}\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
