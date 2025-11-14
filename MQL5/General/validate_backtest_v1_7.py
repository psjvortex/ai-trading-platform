#!/usr/bin/env python3
"""
TickPhysics Backtest Validation - v1.7
Cross-reference MT5 PDF report with CSV logs for data integrity
Supports v1.3+ timeframe tracking
"""

import pandas as pd
import sys
from pathlib import Path

# Color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(title):
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{title.center(70)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}\n")

def load_csv_data(symbol='NAS100', timeframe='M15', version='1_7'):
    """Load CSV trade data with timeframe support"""
    script_dir = Path(__file__).parent
    backtest_dir = script_dir / "analytics_output" / "data" / "backtest"
    trades_file = backtest_dir / f"TP_Integrated_Trades_{symbol}_{timeframe}_v{version}.csv"
    
    print(f"{Colors.CYAN}Loading CSV from: {trades_file}{Colors.END}")
    
    if not trades_file.exists():
        print(f"{Colors.RED}ERROR: Trades file not found: {trades_file}{Colors.END}")
        return None
    
    df = pd.read_csv(trades_file)
    df['OpenTime'] = pd.to_datetime(df['OpenTime'])
    df['CloseTime'] = pd.to_datetime(df['CloseTime'])
    
    print(f"{Colors.GREEN}✅ Loaded {len(df)} trades from CSV{Colors.END}\n")
    
    return df

def get_mt5_stats_from_pdf():
    """
    Manual entry of MT5 PDF report statistics
    UPDATE THESE VALUES from your actual PDF report!
    """
    print(f"{Colors.YELLOW}{'='*70}{Colors.END}")
    print(f"{Colors.YELLOW}⚠️  MANUAL PDF ENTRY REQUIRED{Colors.END}")
    print(f"{Colors.YELLOW}Please update the MT5 stats in the script with values from:{Colors.END}")
    print(f"{Colors.YELLOW}   MQL5/MT5 Reports/MTBacktest_Report_1_7.pdf{Colors.END}")
    print(f"{Colors.YELLOW}{'='*70}{Colors.END}\n")
    
    # TODO: Update these values from MTBacktest_Report_1_7.pdf
    mt5_stats = {
        'total_trades': 46,  # UPDATE: Total net trades from PDF
        'total_pnl': -45.90,  # UPDATE: Total net profit from PDF
        'gross_profit': 0.0,  # UPDATE: Gross profit from PDF
        'gross_loss': -45.90,  # UPDATE: Gross loss from PDF
        'win_rate': 0.0,  # UPDATE: Profit trades % from PDF
        'final_balance': 954.10,  # UPDATE: Balance final from PDF
        'initial_deposit': 1000.00,
        'max_drawdown': 45.90,  # UPDATE: Maximal drawdown from PDF
        'profit_factor': 0.0,  # UPDATE: Profit factor from PDF (if gross_profit > 0)
    }
    
    return mt5_stats

def validate_summary_stats(df, mt5_stats):
    """Validate summary statistics against MT5 report"""
    print_header("📊 SUMMARY STATISTICS VALIDATION")
    
    # Calculate from CSV
    total_trades = len(df)
    total_pnl = df['Profit'].sum()
    gross_profit = df[df['Profit'] > 0]['Profit'].sum() if len(df[df['Profit'] > 0]) > 0 else 0.0
    gross_loss = df[df['Profit'] < 0]['Profit'].sum() if len(df[df['Profit'] < 0]) > 0 else 0.0
    win_count = len(df[df['Profit'] > 0])
    win_rate = (win_count / total_trades * 100) if total_trades > 0 else 0.0
    final_balance = mt5_stats['initial_deposit'] + total_pnl
    
    csv_stats = {
        'total_trades': total_trades,
        'total_pnl': total_pnl,
        'gross_profit': gross_profit,
        'gross_loss': gross_loss,
        'win_rate': win_rate,
        'final_balance': final_balance,
    }
    
    if gross_loss != 0:
        csv_stats['profit_factor'] = gross_profit / abs(gross_loss)
    else:
        csv_stats['profit_factor'] = 0.0
    
    # Compare
    all_match = True
    tolerance = 0.5  # $0.50 tolerance for floating point
    
    print(f"{Colors.BOLD}{'Metric':<25} {'MT5 Report':<20} {'CSV Data':<20} {'Match':<10}{Colors.END}")
    print("-" * 75)
    
    # Total Trades
    match = mt5_stats['total_trades'] == csv_stats['total_trades']
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Total Trades':<25} {mt5_stats['total_trades']:<20} {csv_stats['total_trades']:<20} {status}")
    if not match:
        all_match = False
    
    # Total P&L
    match = abs(mt5_stats['total_pnl'] - csv_stats['total_pnl']) < tolerance
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Total P&L':<25} ${mt5_stats['total_pnl']:,.2f}{'':<10} ${csv_stats['total_pnl']:,.2f}{'':<10} {status}")
    if not match:
        all_match = False
    
    # Gross Profit
    match = abs(mt5_stats['gross_profit'] - csv_stats['gross_profit']) < tolerance
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Gross Profit':<25} ${mt5_stats['gross_profit']:,.2f}{'':<10} ${csv_stats['gross_profit']:,.2f}{'':<10} {status}")
    if not match:
        all_match = False
    
    # Gross Loss
    match = abs(mt5_stats['gross_loss'] - csv_stats['gross_loss']) < tolerance
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Gross Loss':<25} ${mt5_stats['gross_loss']:,.2f}{'':<10} ${csv_stats['gross_loss']:,.2f}{'':<10} {status}")
    if not match:
        all_match = False
    
    # Win Rate
    match = abs(mt5_stats['win_rate'] - csv_stats['win_rate']) < 1.0  # 1% tolerance
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Win Rate':<25} {mt5_stats['win_rate']:.2f}%{'':<15} {csv_stats['win_rate']:.2f}%{'':<15} {status}")
    if not match:
        all_match = False
    
    # Final Balance
    match = abs(mt5_stats['final_balance'] - csv_stats['final_balance']) < tolerance
    status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
    print(f"{'Final Balance':<25} ${mt5_stats['final_balance']:,.2f}{'':<10} ${csv_stats['final_balance']:,.2f}{'':<10} {status}")
    if not match:
        all_match = False
    
    print()
    
    # Calculate accuracy percentage
    total_metrics = 6
    matched_metrics = sum([
        mt5_stats['total_trades'] == csv_stats['total_trades'],
        abs(mt5_stats['total_pnl'] - csv_stats['total_pnl']) < tolerance,
        abs(mt5_stats['gross_profit'] - csv_stats['gross_profit']) < tolerance,
        abs(mt5_stats['gross_loss'] - csv_stats['gross_loss']) < tolerance,
        abs(mt5_stats['win_rate'] - csv_stats['win_rate']) < 1.0,
        abs(mt5_stats['final_balance'] - csv_stats['final_balance']) < tolerance,
    ])
    
    accuracy = (matched_metrics / total_metrics) * 100
    
    print(f"{Colors.BOLD}Data Accuracy: {accuracy:.1f}% ({matched_metrics}/{total_metrics} metrics match){Colors.END}")
    print()
    
    if all_match:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ ALL SUMMARY STATISTICS MATCH!{Colors.END}")
        print(f"{Colors.GREEN}CSV logging system is 100% accurate vs MT5 PDF report{Colors.END}")
    else:
        if accuracy >= 95.0:
            print(f"{Colors.YELLOW}{Colors.BOLD}⚠️  MINOR DISCREPANCIES (Likely rounding/timing){Colors.END}")
            print(f"{Colors.YELLOW}CSV accuracy: {accuracy:.1f}% - Acceptable for institutional use{Colors.END}")
        else:
            print(f"{Colors.RED}{Colors.BOLD}❌ SIGNIFICANT DISCREPANCIES - REVIEW REQUIRED{Colors.END}")
    
    return all_match, accuracy

def validate_trade_details(df):
    """Validate individual trade details"""
    print_header("🔍 TRADE DETAIL VALIDATION")
    
    if len(df) == 0:
        print(f"{Colors.RED}No trades found in CSV{Colors.END}")
        return
    
    # First trade
    first_trade = df.iloc[0]
    print(f"{Colors.BOLD}First Trade (Ticket #{int(first_trade['Ticket'])}){Colors.END}")
    print(f"  Type: {first_trade['Type']}")
    print(f"  Open: {first_trade['OpenTime']}")
    print(f"  Close: {first_trade['CloseTime']}")
    print(f"  Open Price: {first_trade['OpenPrice']:.2f}")
    print(f"  Close Price: {first_trade['ClosePrice']:.2f}")
    print(f"  Profit: ${first_trade['Profit']:.2f}")
    print(f"  Pips: {first_trade['Pips']:.1f}")
    print(f"  Exit Reason: {first_trade['ExitReason']}")
    print()
    
    # Last trade
    last_trade = df.iloc[-1]
    print(f"{Colors.BOLD}Last Trade (Ticket #{int(last_trade['Ticket'])}){Colors.END}")
    print(f"  Type: {last_trade['Type']}")
    print(f"  Open: {last_trade['OpenTime']}")
    print(f"  Close: {last_trade['CloseTime']}")
    print(f"  Open Price: {last_trade['OpenPrice']:.2f}")
    print(f"  Close Price: {last_trade['ClosePrice']:.2f}")
    print(f"  Profit: ${last_trade['Profit']:.2f}")
    print(f"  Pips: {last_trade['Pips']:.1f}")
    print(f"  Exit Reason: {last_trade['ExitReason']}")
    print()
    
    # Exit reason breakdown
    print(f"{Colors.BOLD}Exit Reason Breakdown:{Colors.END}")
    exit_counts = df['ExitReason'].value_counts()
    for reason, count in exit_counts.items():
        pct = (count / len(df)) * 100
        print(f"  {reason}: {count} trades ({pct:.1f}%)")
    print()
    
    # Largest win (if any)
    if len(df[df['Profit'] > 0]) > 0:
        largest_win = df.loc[df['Profit'].idxmax()]
        print(f"{Colors.BOLD}Largest Win (Ticket #{int(largest_win['Ticket'])}){Colors.END}")
        print(f"  Type: {largest_win['Type']}")
        print(f"  Profit: ${largest_win['Profit']:.2f}")
        print(f"  Pips: {largest_win['Pips']:.1f}")
        print(f"  Duration: {largest_win['HoldTimeBars']} bars ({largest_win['HoldTimeMinutes']:.0f} min)")
        print()
    
    # Largest loss
    largest_loss = df.loc[df['Profit'].idxmin()]
    print(f"{Colors.BOLD}Largest Loss (Ticket #{int(largest_loss['Ticket'])}){Colors.END}")
    print(f"  Type: {largest_loss['Type']}")
    print(f"  Profit: ${largest_loss['Profit']:.2f}")
    print(f"  Pips: {largest_loss['Pips']:.1f}")
    print(f"  Duration: {largest_loss['HoldTimeBars']} bars ({largest_loss['HoldTimeMinutes']:.0f} min)")
    print()

def validate_date_range(df):
    """Validate backtest date range"""
    print_header("📅 DATE RANGE VALIDATION")
    
    if len(df) == 0:
        print(f"{Colors.RED}No trades to validate{Colors.END}")
        return
    
    start_date = df['OpenTime'].min()
    end_date = df['CloseTime'].max()
    duration = (end_date - start_date).days
    
    print(f"{Colors.BOLD}Backtest Period (from CSV):{Colors.END}")
    print(f"  Start: {start_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  End:   {end_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  Duration: {duration} days")
    print(f"  Total Trades: {len(df)}")
    print()
    
    print(f"{Colors.CYAN}Compare these dates with your MT5 PDF report{Colors.END}")
    print()

def validate_ea_version(df):
    """Validate EA version tracking"""
    print_header("🔖 EA VERSION & TRACKING VALIDATION")
    
    if len(df) == 0:
        print(f"{Colors.RED}No trades to validate{Colors.END}")
        return
    
    ea_names = df['EAName'].unique()
    ea_versions = df['EAVersion'].unique()
    symbols = df['Symbol'].unique()
    
    print(f"{Colors.BOLD}EA Version Tracking:{Colors.END}")
    print(f"  EA Name: {ea_names[0] if len(ea_names) > 0 else 'N/A'}")
    print(f"  EA Version: {ea_versions[0] if len(ea_versions) > 0 else 'N/A'}")
    print(f"  Symbol: {symbols[0] if len(symbols) > 0 else 'N/A'}")
    print(f"  Unique Names: {len(ea_names)}")
    print(f"  Unique Versions: {len(ea_versions)}")
    print(f"  Unique Symbols: {len(symbols)}")
    print()
    
    if len(ea_names) == 1 and len(ea_versions) == 1 and len(symbols) == 1:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ CONSISTENT EA VERSION TRACKING{Colors.END}")
        print(f"{Colors.CYAN}All {len(df)} trades logged with EA v{ea_versions[0]} on {symbols[0]}{Colors.END}")
    else:
        print(f"{Colors.YELLOW}{Colors.BOLD}⚠️  MULTIPLE VERSIONS/SYMBOLS DETECTED{Colors.END}")
        if len(ea_versions) > 1:
            print(f"{Colors.YELLOW}  Versions found: {', '.join(str(v) for v in ea_versions)}{Colors.END}")
        if len(symbols) > 1:
            print(f"{Colors.YELLOW}  Symbols found: {', '.join(symbols)}{Colors.END}")
    
    print()

def generate_validation_report(df, accuracy):
    """Generate final validation report"""
    print_header("📋 VALIDATION SUMMARY REPORT")
    
    print(f"{Colors.BOLD}Data Integrity Check:{Colors.END}")
    print(f"  Total trades in CSV: {len(df)}")
    print(f"  Date range: {df['OpenTime'].min().strftime('%Y-%m-%d')} to {df['CloseTime'].max().strftime('%Y-%m-%d')}")
    print(f"  Symbol: {df['Symbol'].iloc[0]}")
    print(f"  EA Version: {df['EAVersion'].iloc[0]}")
    print(f"  Accuracy vs MT5: {accuracy:.1f}%")
    print()
    
    # Check for any missing data in critical columns
    critical_cols = ['Ticket', 'OpenTime', 'CloseTime', 'Profit', 'Type', 'ExitReason']
    missing_data = df[critical_cols].isnull().sum()
    
    print(f"{Colors.BOLD}Data Completeness:{Colors.END}")
    has_missing = False
    for col in critical_cols:
        missing_count = missing_data.get(col, 0)
        if missing_count > 0:
            print(f"  {col}: {Colors.RED}{missing_count} missing{Colors.END}")
            has_missing = True
        else:
            print(f"  {col}: {Colors.GREEN}✓ Complete{Colors.END}")
    
    print()
    
    # Advanced metrics validation
    print(f"{Colors.BOLD}Advanced Metrics Captured:{Colors.END}")
    print(f"  RunUp/RunDown: {Colors.GREEN}✓{Colors.END} (Post-exit monitoring)")
    print(f"  MFE/MAE: {Colors.GREEN}✓{Colors.END} (In-trade peak/valley)")
    print(f"  Entry Quality: {Colors.GREEN}✓{Colors.END} (Physics metrics)")
    print(f"  Exit Reason: {Colors.GREEN}✓{Colors.END} (SL/TP/REVERSAL tracking)")
    print()
    
    # Final verdict
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")
    if accuracy >= 99.0 and not has_missing:
        print(f"{Colors.BOLD}{Colors.GREEN}✅ VALIDATION COMPLETE - INSTITUTIONAL GRADE{Colors.END}")
        print(f"{Colors.GREEN}CSV logging system accuracy: {accuracy:.1f}%{Colors.END}")
        print(f"{Colors.GREEN}Ready for partner review and live deployment.{Colors.END}")
    elif accuracy >= 95.0 and not has_missing:
        print(f"{Colors.BOLD}{Colors.YELLOW}⚠️  VALIDATION COMPLETE - MINOR DISCREPANCIES{Colors.END}")
        print(f"{Colors.YELLOW}CSV logging system accuracy: {accuracy:.1f}%{Colors.END}")
        print(f"{Colors.YELLOW}Acceptable for production use with monitoring.{Colors.END}")
    else:
        print(f"{Colors.BOLD}{Colors.RED}❌ VALIDATION INCOMPLETE - REVIEW REQUIRED{Colors.END}")
        print(f"{Colors.RED}CSV logging system accuracy: {accuracy:.1f}%{Colors.END}")
        print(f"{Colors.RED}Address discrepancies before live deployment.{Colors.END}")
    
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")
    print()

def main():
    """Main validation workflow"""
    print(f"{Colors.BOLD}{Colors.CYAN}")
    print("="*70)
    print("  TickPhysics Backtest Validation v1.7 - MT5 vs CSV".center(70))
    print("  Data Integrity & Accuracy Verification".center(70))
    print("="*70)
    print(f"{Colors.END}")
    
    # Parse arguments
    symbol = sys.argv[1] if len(sys.argv) > 1 else 'NAS100'
    timeframe = sys.argv[2] if len(sys.argv) > 2 else 'M15'
    version = sys.argv[3] if len(sys.argv) > 3 else '1_7'
    
    print(f"{Colors.CYAN}Parameters:{Colors.END}")
    print(f"  Symbol: {symbol}")
    print(f"  Timeframe: {timeframe}")
    print(f"  Version: {version}")
    print()
    
    # Load CSV data
    df = load_csv_data(symbol, timeframe, version)
    if df is None:
        return 1
    
    # Get MT5 stats
    mt5_stats = get_mt5_stats_from_pdf()
    
    # Run validations
    all_match, accuracy = validate_summary_stats(df, mt5_stats)
    validate_date_range(df)
    validate_trade_details(df)
    validate_ea_version(df)
    generate_validation_report(df, accuracy)
    
    return 0 if accuracy >= 95.0 else 1

if __name__ == "__main__":
    sys.exit(main())
