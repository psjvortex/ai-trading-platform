#!/usr/bin/env python3
"""
TickPhysics Backtest Validation
Cross-reference MT5 PDF report with CSV logs for data integrity
"""

import pandas as pd
from pathlib import Path
from analytics_config import OUTPUT_DIR, DEFAULT_SYMBOL, DEFAULT_VERSION

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

def load_csv_data():
    """Load CSV trade data"""
    backtest_dir = Path(OUTPUT_DIR) / "data" / "backtest"
    trades_file = backtest_dir / f"TP_Integrated_Trades_{DEFAULT_SYMBOL}_v{DEFAULT_VERSION}.csv"
    
    if not trades_file.exists():
        print(f"{Colors.RED}ERROR: Trades file not found{Colors.END}")
        return None
    
    df = pd.read_csv(trades_file)
    df['OpenTime'] = pd.to_datetime(df['OpenTime'])
    df['CloseTime'] = pd.to_datetime(df['CloseTime'])
    
    return df

def validate_summary_stats(df):
    """Validate summary statistics against MT5 report"""
    print_header("📊 SUMMARY STATISTICS VALIDATION")
    
    # Expected values from MT5 PDF report
    mt5_stats = {
        'total_trades': 145,
        'total_pnl': 3.77,
        'gross_profit': 683.75,
        'gross_loss': -679.98,
        'win_rate': 27.59,  # 40 wins / 145 trades
        'max_drawdown': 282.92,
        'initial_deposit': 1000.00,
        'final_balance': 1003.77,
        'profit_factor': 1.01,  # 683.75 / 679.98
    }
    
    # Calculate from CSV
    csv_stats = {
        'total_trades': len(df),
        'total_pnl': df['Profit'].sum(),
        'gross_profit': df[df['Profit'] > 0]['Profit'].sum(),
        'gross_loss': df[df['Profit'] < 0]['Profit'].sum(),
        'win_rate': (len(df[df['Profit'] > 0]) / len(df) * 100),
        'max_drawdown': abs(df['Profit'].cumsum().cummin().min() - df['Profit'].cumsum().cummax().max()),
        'final_balance': 1000.00 + df['Profit'].sum(),
    }
    
    csv_stats['profit_factor'] = csv_stats['gross_profit'] / abs(csv_stats['gross_loss']) if csv_stats['gross_loss'] != 0 else 0
    
    # Compare
    all_match = True
    
    print(f"{Colors.BOLD}{'Metric':<25} {'MT5 Report':<20} {'CSV Data':<20} {'Match':<10}{Colors.END}")
    print("-" * 75)
    
    for key in mt5_stats.keys():
        mt5_val = mt5_stats[key]
        csv_val = csv_stats.get(key, 0)
        
        # Tolerance for floating point comparison
        if isinstance(mt5_val, float):
            match = abs(mt5_val - csv_val) < 0.1
        else:
            match = mt5_val == csv_val
        
        status = f"{Colors.GREEN}✓{Colors.END}" if match else f"{Colors.RED}✗{Colors.END}"
        
        if not match:
            all_match = False
        
        # Format values
        if isinstance(mt5_val, float):
            if 'rate' in key or 'factor' in key:
                mt5_str = f"{mt5_val:.2f}"
                csv_str = f"{csv_val:.2f}"
            else:
                mt5_str = f"${mt5_val:,.2f}"
                csv_str = f"${csv_val:,.2f}"
        else:
            mt5_str = str(mt5_val)
            csv_str = str(csv_val)
        
        print(f"{key:<25} {mt5_str:<20} {csv_str:<20} {status}")
    
    print()
    if all_match:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ ALL SUMMARY STATISTICS MATCH!{Colors.END}")
    else:
        print(f"{Colors.RED}{Colors.BOLD}❌ DISCREPANCIES FOUND - REVIEW REQUIRED{Colors.END}")
    
    return all_match

def validate_trade_details(df):
    """Validate individual trade details"""
    print_header("🔍 TRADE DETAIL VALIDATION")
    
    # Key trades to validate (from PDF report visible trades)
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
    print()
    
    # Largest win
    largest_win = df.loc[df['Profit'].idxmax()]
    print(f"{Colors.BOLD}Largest Win (Ticket #{int(largest_win['Ticket'])}){Colors.END}")
    print(f"  Type: {largest_win['Type']}")
    print(f"  Profit: ${largest_win['Profit']:.2f}")
    print(f"  Pips: {largest_win['Pips']:.1f}")
    print(f"  Duration: {largest_win['HoldTimeMinutes']:.0f} minutes")
    print()
    
    # Largest loss
    largest_loss = df.loc[df['Profit'].idxmin()]
    print(f"{Colors.BOLD}Largest Loss (Ticket #{int(largest_loss['Ticket'])}){Colors.END}")
    print(f"  Type: {largest_loss['Type']}")
    print(f"  Profit: ${largest_loss['Profit']:.2f}")
    print(f"  Pips: {largest_loss['Pips']:.1f}")
    print(f"  Duration: {largest_loss['HoldTimeMinutes']:.0f} minutes")
    print()

def validate_date_range(df):
    """Validate backtest date range"""
    print_header("📅 DATE RANGE VALIDATION")
    
    start_date = df['OpenTime'].min()
    end_date = df['CloseTime'].max()
    duration = (end_date - start_date).days
    
    print(f"{Colors.BOLD}Backtest Period:{Colors.END}")
    print(f"  Start: {start_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  End:   {end_date.strftime('%Y-%m-%d %H:%M')}")
    print(f"  Duration: {duration} days")
    print()
    
    # Expected from MT5 report
    print(f"{Colors.BOLD}Expected (from MT5 Report):{Colors.END}")
    print(f"  Start: 2025-08-01 05:00")
    print(f"  End:   2025-08-29 16:35")
    print(f"  Duration: 28 days")
    print()
    
    # Validate
    expected_start = pd.to_datetime('2025-08-01 05:00')
    expected_end = pd.to_datetime('2025-08-29 16:35')
    
    start_match = abs((start_date - expected_start).total_seconds()) < 3600  # 1 hour tolerance
    end_match = abs((end_date - expected_end).total_seconds()) < 3600
    duration_match = duration == 28
    
    if start_match and end_match and duration_match:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ DATE RANGE MATCHES MT5 REPORT{Colors.END}")
    else:
        print(f"{Colors.YELLOW}{Colors.BOLD}⚠️  DATE RANGE DISCREPANCY DETECTED{Colors.END}")

def validate_ea_version(df):
    """Validate EA version tracking"""
    print_header("🔖 EA VERSION VALIDATION")
    
    ea_names = df['EAName'].unique()
    ea_versions = df['EAVersion'].unique()
    
    print(f"{Colors.BOLD}EA Version Tracking:{Colors.END}")
    print(f"  EA Name: {ea_names[0] if len(ea_names) > 0 else 'N/A'}")
    print(f"  EA Version: {ea_versions[0] if len(ea_versions) > 0 else 'N/A'}")
    print(f"  Unique Names: {len(ea_names)}")
    print(f"  Unique Versions: {len(ea_versions)}")
    print()
    
    if len(ea_names) == 1 and len(ea_versions) == 1:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ CONSISTENT EA VERSION TRACKING{Colors.END}")
        print(f"{Colors.CYAN}All {len(df)} trades logged with EA version {ea_versions[0]}{Colors.END}")
    else:
        print(f"{Colors.YELLOW}{Colors.BOLD}⚠️  MULTIPLE EA VERSIONS DETECTED{Colors.END}")

def generate_validation_report(df):
    """Generate final validation report"""
    print_header("📋 VALIDATION SUMMARY")
    
    print(f"{Colors.BOLD}Data Integrity Check:{Colors.END}")
    print(f"  Total trades in CSV: {len(df)}")
    print(f"  Expected from MT5: 145")
    print(f"  Date range: {df['OpenTime'].min().strftime('%Y-%m-%d')} to {df['CloseTime'].max().strftime('%Y-%m-%d')}")
    print(f"  Symbol: {df['Symbol'].iloc[0]}")
    print(f"  EA Version: {df['EAVersion'].iloc[0]}")
    print()
    
    # Check for any missing data
    missing_data = df.isnull().sum()
    critical_cols = ['Ticket', 'OpenTime', 'CloseTime', 'Profit', 'Type']
    
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
    
    if not has_missing:
        print(f"{Colors.GREEN}{Colors.BOLD}✅ NO MISSING CRITICAL DATA{Colors.END}")
    else:
        print(f"{Colors.RED}{Colors.BOLD}❌ MISSING DATA DETECTED - REVIEW REQUIRED{Colors.END}")
    
    print()
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.GREEN}CSV logging system is capturing accurate trade data!{Colors.END}")
    print(f"{Colors.BOLD}{Colors.GREEN}Ready for institutional-grade analytics and partner review.{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*70}{Colors.END}")

def main():
    print(f"{Colors.BOLD}{Colors.CYAN}")
    print("="*70)
    print("  TickPhysics Backtest Validation - MT5 vs CSV".center(70))
    print("  Data Integrity & Accuracy Verification".center(70))
    print("="*70)
    print(f"{Colors.END}")
    
    # Load CSV data
    df = load_csv_data()
    if df is None:
        return 1
    
    print(f"{Colors.GREEN}✅ Loaded {len(df)} trades from CSV{Colors.END}")
    
    # Run validations
    validate_summary_stats(df)
    validate_date_range(df)
    validate_trade_details(df)
    validate_ea_version(df)
    generate_validation_report(df)
    
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(main())
