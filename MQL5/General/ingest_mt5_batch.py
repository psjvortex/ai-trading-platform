#!/usr/bin/env python3
"""
Batch MT5 Backtest Ingestion & TickPhysics Trades/Signals Integration
=====================================================================
Automates:
  1. Scanning a Desktop drop folder for MT5 backtest report CSVs.
  2. Parsing symbol, timeframe, version from filename (robust regex fallback).
  3. Normalizing filenames into internal convention:
       TP_Integrated_MTBacktest_Report_<SYMBOL>_<VERSION>_<TIMEFRAME>.csv
  4. Creating per-symbol folder under MQL5/Backtest_Reports/<SYMBOL>
  5. Parsing completed trade exits from MT5 backtest report (Direction == 'out').
  6. Locating matching TickPhysics Trades & Signals CSVs in MetaTrader Tester hierarchy.
  7. Computing core metrics (trade count, WR, PF, gross profit/loss, avg win/loss) from both sources.
  8. Emitting per-symbol summary JSON + combined overview JSON.
  9. Evaluating promotion gates (configurable) and flagging pass/fail per symbol.

Usage:
  python ingest_mt5_batch.py \
      --mt5-drop "/Users/patjohnston/Desktop/MT5 EA Backtest CSV Folder" \
      --tester-root "/Users/patjohnston/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/Tester" \
      [--symbols BTCUSD,NAS100] [--min-trades 120 --min-winrate 30 --min-pf 1.05] [--dry-run]

Outputs (example for BTCUSD):
  MQL5/Backtest_Reports/BTCUSD/TP_Integrated_MTBacktest_Report_BTCUSD_3.0_05M.csv
  MQL5/Backtest_Reports/BTCUSD/BTCUSD_v3.0_05M_summary.json
  MQL5/Backtest_Reports/summary_overview.json (aggregate listing)

Filename Patterns Supported (examples):
  TP_Integrated_MTBacktest_BITCOIN_05M_v3.0.csv
  TP_Integrated_MTBacktest_Report_NAS100_3.21_M15.csv
  MTBacktest_NAS100_M15_v2.5.csv

Trades / Signals Pattern (EA generated):
  TP_Integrated_Trades_<SYMBOL>_v<VERSION>.csv
  TP_Integrated_Signals_<SYMBOL>_v<VERSION>.csv
(searched recursively under Tester/**/MQL5/Files/)

Promotion Gates:
  - Trades >= min_trades
  - WinRate >= min_winrate (%)
  - ProfitFactor >= min_pf

If Trades CSV present, its metrics are primary; else MT5 report metrics used.
Signals CSV (if found) adds signal distribution counts.

Limitations:
  - Hold time not computed (would need entry timestamps pairing).
  - ProfitFactor uses gross profit / gross loss; gross loss must be > 0.
  - Version parsing relies on 'v' or numeric token; defaults to 'UNKNOWN' if not found.

"""
from __future__ import annotations
import re, csv, json, argparse, statistics, sys
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any, List

HEADER_EXPECTED = ['Time','Deal','Symbol','Type','Direction','Volume','Price','Order','Commission','Swap','Profit','Balance','Comment']  # trailing empty column tolerated
TIME_FORMAT = '%Y.%m.%d %H:%M:%S'

# ----------------------------- Parsing Helpers ----------------------------- #
FILENAME_REGEXES = [
    # With 'Report' token
    re.compile(r"TP_Integrated_MTBacktest_Report_(?P<symbol>[A-Z0-9]+)_(?P<version>[0-9]+(?:\.[0-9A-Za-z]+)?)_(?P<tf>[0-9A-Z]+)\.csv", re.I),
    # Without 'Report'
    re.compile(r"TP_Integrated_MTBacktest_(?P<symbol>[A-Z0-9]+)_(?P<tf>[0-9A-Z]+)_v(?P<version>[0-9]+(?:\.[0-9A-Za-z]+)?)\.csv", re.I),
    # Generic
    re.compile(r"MTBacktest_(?P<symbol>[A-Z0-9]+)_(?P<tf>[0-9A-Z]+)_v(?P<version>[0-9]+(?:\.[0-9A-Za-z]+)?)\.csv", re.I),
]

TIMEFRAME_NORMALIZATION = {
    'M1': '01M', 'M5': '05M', 'M15': '15M', 'M30': '30M', 'H1': 'H1', 'H4': 'H4', 'D1': 'D1'
}

SYMBOL_ALIASES = {
    'BITCOIN': 'BTCUSD', 'BTC': 'BTCUSD'
}

# ----------------------------- Promotion Gates ----------------------------- #
DEFAULT_GATES = {
    'min_trades': 120,
    'min_winrate': 30.0,
    'min_pf': 1.05,
}

# ----------------------------- Core Functions ------------------------------ #

def parse_filename(path: Path) -> Dict[str, str]:
    name = path.name
    for rx in FILENAME_REGEXES:
        m = rx.match(name)
        if m:
            symbol = m.group('symbol').upper()
            symbol = SYMBOL_ALIASES.get(symbol, symbol)
            tf = m.group('tf').upper()
            version = m.group('version')
            # Some patterns embed timeframe with leading zeros differently
            tf_norm = TIMEFRAME_NORMALIZATION.get(tf, tf)
            # ensure version has leading 'v' removed for uniform; we'll store without 'v'
            version_norm = version.lstrip('v')
            return {'symbol': symbol, 'timeframe': tf_norm, 'version': version_norm}
    # Fallback heuristic
    # Look for vX.Y token
    vm = re.search(r"v([0-9]+(?:\.[0-9A-Za-z]+)?)", name, re.I)
    version = vm.group(1) if vm else 'UNKNOWN'
    # Symbol guess: first uppercase block
    sm = re.search(r"([A-Z0-9]{3,8})", name)
    symbol = SYMBOL_ALIASES.get(sm.group(1), sm.group(1)) if sm else 'UNKNOWN'
    # Timeframe guess
    tfm = re.search(r"(_(M\d+|H\d+|D1|\d{2}M)_)", name)
    timeframe = tfm.group(2) if tfm else 'UNK'
    timeframe = TIMEFRAME_NORMALIZATION.get(timeframe, timeframe)
    return {'symbol': symbol, 'timeframe': timeframe, 'version': version}


def parse_time(s: str) -> Optional[datetime]:
    s = s.strip()
    try:
        return datetime.strptime(s, TIME_FORMAT)
    except Exception:
        return None


def clean_profit(p: str) -> float:
    p = p.replace(' ', '').replace('\u202f','').replace('+','').replace('−','-')
    if p in ('', '.', '-', '+'):
        return 0.0
    try:
        return float(p)
    except ValueError:
        # try removing stray spaces around minus
        return float(p.replace(' -', '-')) if p else 0.0


def extract_mt5_metrics(csv_path: Path) -> Dict[str, Any]:
    """Parse MT5 strategy report, tolerating BOM, trailing comma, and minor header variations.

    We only rely on three columns: Time, Direction, Profit. If Profit missing we fail gracefully.
    """
    if not csv_path.exists():
        return {'error': f'file not found: {csv_path}'}
    trade_profits: List[float] = []
    win_profits: List[float] = []
    loss_profits: List[float] = []
    exit_times: List[datetime] = []

    with csv_path.open('r', encoding='utf-8-sig', newline='') as f:  # utf-8-sig strips BOM if present
        reader = csv.reader(f)
        raw_header = next(reader, None)
        if raw_header is None:
            return {'error': 'empty csv'}
        # Strip whitespace and ignore empty trailing column
        header = [h.strip() for h in raw_header if h.strip() != '']
        header_mismatch = header[:len(HEADER_EXPECTED)] != HEADER_EXPECTED
        # Build index map resiliently
        header_map = {col: idx for idx, col in enumerate(raw_header)}  # use raw to keep indexes aligned with rows
        missing_cols = [c for c in ('Profit','Direction','Time') if c not in header_map]
        if missing_cols:
            return {'error': f'required columns missing: {missing_cols}'}
        idx_profit = header_map['Profit']
        idx_direction = header_map['Direction']
        idx_time = header_map['Time']
        for row in reader:
            if not row or len(row) <= idx_direction:
                continue
            # guard for partial rows
            direction = row[idx_direction].strip().lower()
            if direction != 'out':
                continue
            profit = clean_profit(row[idx_profit])
            trade_profits.append(profit)
            if profit >= 0:
                win_profits.append(profit)
            else:
                loss_profits.append(profit)
            t = parse_time(row[idx_time])
            if t:
                exit_times.append(t)

    trade_count = len(trade_profits)
    gross_profit = sum(p for p in trade_profits if p >= 0)
    gross_loss = -sum(p for p in trade_profits if p < 0)
    win_rate = (len(win_profits)/trade_count*100.0) if trade_count else 0.0
    profit_factor = (gross_profit/gross_loss) if gross_loss > 0 else (gross_profit if gross_profit>0 else 0.0)
    avg_win = statistics.mean(win_profits) if win_profits else 0.0
    avg_loss = statistics.mean(loss_profits) if loss_profits else 0.0

    return {
        'trade_count': trade_count,
        'gross_profit': round(gross_profit,2),
        'gross_loss': round(gross_loss,2),
        'win_rate_percent': round(win_rate,2),
        'profit_factor': round(profit_factor,3),
        'average_win': round(avg_win,4),
        'average_loss': round(avg_loss,4),
        'header_mismatch': header_mismatch,
    }


def find_trades_signals(tester_root: Path, symbol: str, version: str) -> Dict[str, Path]:
    """Locate Trades & Signals CSVs.

    Also searches alias forms (e.g., BITCOIN for BTCUSD) because EA may emit BITCOIN before mapping.
    """
    aliases = {symbol}
    # reverse lookup from SYMBOL_ALIASES
    for k,v in SYMBOL_ALIASES.items():
        if v == symbol:
            aliases.add(k)
    trades_patterns = []
    signals_patterns = []
    for sym in aliases:
        # Exact patterns (rarely sufficient)
        trades_patterns.extend([
            f'TP_Integrated_Trades_{sym}_v{version}.csv',
            f'TP_Integrated_Trades_{sym}_{version}.csv',
            # Pattern used by EA: v<ALIAS>_<TF>_<VERSION>
            f'TP_Integrated_Trades_{sym}_v{sym}_05M_{version}.csv'
        ])
        signals_patterns.extend([
            f'TP_Integrated_Signals_{sym}_v{version}.csv',
            f'TP_Integrated_Signals_{sym}_{version}.csv',
            f'TP_Integrated_Signals_{sym}_v{sym}_05M_{version}.csv'
        ])
    found_trades: Optional[Path] = None
    found_signals: Optional[Path] = None
    if not tester_root.exists():
        return {'trades': None, 'signals': None}
    # Prefer wildcard search to handle EA_VERSION substrings (e.g., vBITCOIN_05M_3.0)
    trade_candidates: List[Path] = []
    signal_candidates: List[Path] = []
    for sym in aliases:
        trade_candidates.extend(tester_root.glob(f"**/MQL5/Files/TP_Integrated_Trades_{sym}_v*{version}*.csv"))
        trade_candidates.extend(tester_root.glob(f"**/MQL5/Files/TP_Integrated_Trades_{sym}_v{sym}_*{version}*.csv"))
        signal_candidates.extend(tester_root.glob(f"**/MQL5/Files/TP_Integrated_Signals_{sym}_v*{version}*.csv"))
        signal_candidates.extend(tester_root.glob(f"**/MQL5/Files/TP_Integrated_Signals_{sym}_v{sym}_*{version}*.csv"))

    # If wildcard missed, fall back to exact name scan
    if not trade_candidates or not signal_candidates:
        for p in tester_root.glob('**/MQL5/Files/TP_Integrated*.csv'):
            n = p.name
            if p not in trade_candidates and n in trades_patterns:
                trade_candidates.append(p)
            if p not in signal_candidates and n in signals_patterns:
                signal_candidates.append(p)

    # Pick latest by mtime
    found_trades = max(trade_candidates, key=lambda p: p.stat().st_mtime) if trade_candidates else None
    found_signals = max(signal_candidates, key=lambda p: p.stat().st_mtime) if signal_candidates else None
    return {'trades': found_trades, 'signals': found_signals}


def load_trades_csv(path: Path) -> Dict[str, Any]:
    try:
        import pandas as pd
    except Exception:
        return {'error': 'pandas not available'}
    if not path or not path.exists():
        return {'error': f'trades csv not found: {path}'}
    df = pd.read_csv(path)
    # Basic expected columns
    profit_col = 'Profit' if 'Profit' in df.columns else None
    if not profit_col:
        return {'error': 'Profit column missing in Trades CSV'}
    total = len(df)
    pnl_series = df[profit_col].fillna(0)
    wins = (pnl_series > 0).sum()
    losses = (pnl_series < 0).sum()
    win_rate = (wins/total*100.0) if total else 0.0
    gross_profit = pnl_series[pnl_series>0].sum()
    gross_loss = -pnl_series[pnl_series<0].sum()
    profit_factor = (gross_profit/gross_loss) if gross_loss>0 else (gross_profit if gross_profit>0 else 0.0)
    avg_win = pnl_series[pnl_series>0].mean() if wins>0 else 0.0
    avg_loss = pnl_series[pnl_series<0].mean() if losses>0 else 0.0
    exit_reason_counts = df['ExitReason'].value_counts().to_dict() if 'ExitReason' in df.columns else {}
    return {
        'trade_count': int(total),
        'win_rate_percent': round(win_rate,2),
        'profit_factor': round(profit_factor,3),
        'gross_profit': round(gross_profit,2),
        'gross_loss': round(gross_loss,2),
        'average_win': round(avg_win,4),
        'average_loss': round(avg_loss,4),
        'exit_reasons': exit_reason_counts,
    }


def load_signals_csv(path: Path) -> Dict[str, Any]:
    try:
        import pandas as pd
    except Exception:
        return {'error': 'pandas not available'}
    if not path or not path.exists():
        return {'error': f'signals csv not found: {path}'}
    df = pd.read_csv(path)
    sig_col = 'signalType' if 'signalType' in df.columns else None
    distribution = df[sig_col].value_counts().to_dict() if sig_col else {}
    return {'signal_count': len(df), 'signal_distribution': distribution}


def evaluate_gates(metrics: Dict[str, Any], gates: Dict[str, float]) -> Dict[str, Any]:
    return {
        'trades_gate': metrics.get('trade_count',0) >= gates['min_trades'],
        'winrate_gate': metrics.get('win_rate_percent',0.0) >= gates['min_winrate'],
        'pf_gate': metrics.get('profit_factor',0.0) >= gates['min_pf'],
    }


def normalize_filename(symbol: str, version: str, timeframe: str) -> str:
    return f"TP_Integrated_MTBacktest_Report_{symbol}_{version}_{timeframe}.csv"


def process_file(path: Path, dest_root: Path, tester_root: Path, gates: Dict[str,float], dry_run: bool=False) -> Dict[str, Any]:
    parsed = parse_filename(path)
    symbol = parsed['symbol']
    timeframe = parsed['timeframe']
    version = parsed['version']
    symbol_folder = dest_root / symbol
    symbol_folder.mkdir(parents=True, exist_ok=True)
    normalized_name = normalize_filename(symbol, version, timeframe)
    dest_csv = symbol_folder / normalized_name

    if not dry_run:
        data = path.read_bytes()
        dest_csv.write_bytes(data)

    mt5_metrics = extract_mt5_metrics(dest_csv if not dry_run else path)
    ts_paths = find_trades_signals(tester_root, symbol, version)
    trades_metrics = load_trades_csv(ts_paths['trades']) if ts_paths['trades'] else {}
    signals_metrics = load_signals_csv(ts_paths['signals']) if ts_paths['signals'] else {}

    # Prefer trades_metrics if available for core trade values
    primary = trades_metrics if trades_metrics and 'trade_count' in trades_metrics else mt5_metrics
    gates_eval = evaluate_gates(primary, gates)

    # Coerce any numpy.bool_ to native bool for JSON
    def _clean(obj: Dict[str, Any]) -> Dict[str, Any]:
        out = {}
        for k,v in obj.items():
            if type(v).__name__ == 'bool_':  # numpy.bool_
                out[k] = bool(v)
            else:
                out[k] = v
        return out
    summary = {
        'symbol': symbol,
        'version': version,
        'timeframe': timeframe,
        'source_file': str(path),
        'normalized_file': str(dest_csv),
        'mt5_metrics': _clean(mt5_metrics) if isinstance(mt5_metrics, dict) else mt5_metrics,
        'trades_metrics': _clean(trades_metrics) if isinstance(trades_metrics, dict) else trades_metrics,
        'signals_metrics': _clean(signals_metrics) if isinstance(signals_metrics, dict) else signals_metrics,
        'primary_metrics': _clean(primary) if isinstance(primary, dict) else primary,
        'gates': _clean(gates_eval),
    }
    if not dry_run:
        summary_path = symbol_folder / f"{symbol}_v{version}_{timeframe}_summary.json"
        summary_path.write_text(json.dumps(summary, indent=2))
    return summary


def aggregate_overview(summaries: List[Dict[str,Any]], dest_root: Path, dry_run: bool=False):
    overview = {
        'symbols': [s['symbol'] for s in summaries],
        'details': summaries,
    }
    if not dry_run:
        (dest_root / 'summary_overview.json').write_text(json.dumps(overview, indent=2))
    return overview

# ----------------------------- CLI Interface ------------------------------- #

def main():
    ap = argparse.ArgumentParser(description='Batch ingest MT5 backtest CSVs + TickPhysics Trades/Signals.')
    ap.add_argument('--mt5-drop', required=True, type=Path, help='Desktop drop folder containing MT5 backtest CSVs')
    ap.add_argument('--tester-root', required=True, type=Path, help='MetaTrader Tester root directory')
    ap.add_argument('--dest-root', type=Path, default=Path('MQL5/Backtest_Reports'), help='Destination reports root')
    ap.add_argument('--symbols', type=str, default='', help='Comma-separated symbols to restrict (optional)')
    ap.add_argument('--min-trades', type=int, default=DEFAULT_GATES['min_trades'])
    ap.add_argument('--min-winrate', type=float, default=DEFAULT_GATES['min_winrate'])
    ap.add_argument('--min-pf', type=float, default=DEFAULT_GATES['min_pf'])
    ap.add_argument('--dry-run', action='store_true', help='Do not copy or write outputs; just print planned actions')
    args = ap.parse_args()

    gates = {
        'min_trades': args.min_trades,
        'min_winrate': args.min_winrate,
        'min_pf': args.min_pf,
    }

    allowed_symbols = {s.strip().upper() for s in args.symbols.split(',') if s.strip()} if args.symbols else None

    if not args.mt5_drop.exists():
        print(f"❌ MT5 drop folder not found: {args.mt5_drop}")
        return 2
    args.dest_root.mkdir(parents=True, exist_ok=True)

    # Gather candidate CSVs
    candidates = list(args.mt5_drop.glob('*.csv'))
    if not candidates:
        print('⚠️ No CSV files found in drop folder.')
        return 0

    summaries: List[Dict[str,Any]] = []
    print(f"🔍 Found {len(candidates)} candidate CSV files.")
    for c in sorted(candidates):
        meta = parse_filename(c)
        symbol = meta['symbol']
        if allowed_symbols and symbol not in allowed_symbols:
            print(f"⏭️  Skipping {c.name} (symbol {symbol} not in filter set)")
            continue
        print(f"➡️  Processing {c.name} → {symbol} {meta['version']} {meta['timeframe']}")
        summary = process_file(c, args.dest_root, args.tester_root, gates, dry_run=args.dry_run)
        gate_status = summary['gates']
        gate_icons = ''.join(['✅' if v else '⚠️' for v in gate_status.values()])
        primary = summary['primary_metrics']
        print(f"   Trades: {primary.get('trade_count','?')}, WR: {primary.get('win_rate_percent','?')}%, PF: {primary.get('profit_factor','?')} {gate_icons}")
        summaries.append(summary)

    # Aggregate overview
    aggregate_overview(summaries, args.dest_root, dry_run=args.dry_run)
    passed = [s for s in summaries if all(s['gates'].values())]
    print('\n=== Promotion Candidates ===')
    if passed:
        for s in passed:
            pm = s['primary_metrics']
            print(f"  {s['symbol']} v{s['version']} {s['timeframe']}: Trades {pm.get('trade_count')} WR {pm.get('win_rate_percent')}% PF {pm.get('profit_factor')}")
    else:
        print('  (none passed all gates)')

    print('\n✅ Batch ingestion complete.' if not args.dry_run else '\n(Dry run complete)')
    return 0

if __name__ == '__main__':
    sys.exit(main())
