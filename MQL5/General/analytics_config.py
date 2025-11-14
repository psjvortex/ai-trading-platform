"""
TickPhysics Analytics Configuration
Institutional-grade dual-pipeline setup for backtest vs live validation
"""
import os
from pathlib import Path

# CSV File Paths - Backtest vs Live
PATHS = {
    'backtest': {
        'root': '/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester/Agent-127.0.0.1-3000/MQL5/Files',
        'trades': 'TP_Integrated_Trades_{symbol}_{timeframe}_v{version}.csv',
        'signals': 'TP_Integrated_Signals_{symbol}_{timeframe}_v{version}.csv'
    },
    'live': {
        'root': '/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Files',
        'trades': 'TP_Integrated_Trades_{symbol}_{timeframe}_v{version}.csv',
        'signals': 'TP_Integrated_Signals_{symbol}_{timeframe}_v{version}.csv'
    }
}

# Default parameters
DEFAULT_SYMBOL = 'NAS100'
DEFAULT_TIMEFRAME = 'M15'
DEFAULT_VERSION = '1_7'

# Output paths
OUTPUT_DIR = Path(__file__).parent / 'analytics_output'
OUTPUT_DIR.mkdir(exist_ok=True)

REPORTS_DIR = OUTPUT_DIR / 'reports'
REPORTS_DIR.mkdir(exist_ok=True)

CHARTS_DIR = OUTPUT_DIR / 'charts'
CHARTS_DIR.mkdir(exist_ok=True)

# Validation thresholds for backtest vs live comparison
VALIDATION_THRESHOLDS = {
    'win_rate_tolerance': 0.05,      # 5% tolerance (backtest 55% vs live 50% = OK)
    'avg_pips_tolerance': 0.15,       # 15% tolerance for slippage
    'profit_factor_tolerance': 0.20,  # 20% tolerance
    'max_acceptable_degradation': 0.25,  # 25% performance drop = RED FLAG
}

# Alert levels
ALERT_LEVELS = {
    'green': 'Performance matches or exceeds backtest',
    'yellow': 'Slight degradation within acceptable range',
    'red': 'Significant degradation - investigate immediately'
}

def get_csv_path(mode, file_type, symbol=DEFAULT_SYMBOL, version=DEFAULT_VERSION):
    """
    Get full path to CSV file
    
    Args:
        mode: 'backtest' or 'live'
        file_type: 'trades' or 'signals'
        symbol: Trading symbol
        version: EA version
        
    Returns:
        Full path to CSV file
    """
    if mode not in PATHS:
        raise ValueError(f"Invalid mode: {mode}. Must be 'backtest' or 'live'")
    
    root = PATHS[mode]['root']
    filename = PATHS[mode][file_type].format(symbol=symbol, version=version)
    
    return os.path.join(root, filename)

def get_output_path(report_type, mode=None, symbol=DEFAULT_SYMBOL, version=DEFAULT_VERSION):
    """
    Get output path for reports
    
    Args:
        report_type: 'html', 'csv', 'chart'
        mode: 'backtest', 'live', or 'comparison' (None for comparison)
        symbol: Trading symbol
        version: EA version
        
    Returns:
        Full path to output file
    """
    mode_str = mode if mode else 'comparison'
    timestamp = Path(__file__).stem
    
    if report_type == 'html':
        filename = f"TP_Analytics_{mode_str}_{symbol}_v{version}.html"
        return REPORTS_DIR / filename
    elif report_type == 'csv':
        filename = f"TP_Metrics_{mode_str}_{symbol}_v{version}.csv"
        return OUTPUT_DIR / filename
    elif report_type == 'chart':
        return CHARTS_DIR / f"{mode_str}_{symbol}_v{version}"
    else:
        raise ValueError(f"Invalid report_type: {report_type}")

# Display configuration
print("═══════════════════════════════════════════════════════")
print("📊 TickPhysics Analytics Configuration Loaded")
print("═══════════════════════════════════════════════════════")
print(f"Backtest Path: {PATHS['backtest']['root']}")
print(f"Live Path: {PATHS['live']['root']}")
print(f"Output Directory: {OUTPUT_DIR}")
print(f"Default Symbol: {DEFAULT_SYMBOL}")
print(f"Default Version: {DEFAULT_VERSION}")
print("═══════════════════════════════════════════════════════")
