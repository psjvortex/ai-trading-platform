#!/usr/bin/env python3
"""
Ingest BTCUSD baseline MT5 backtest CSV (MTBacktest report) dropped externally (e.g. Desktop)
into the project structure and derive quick baseline metrics.

Usage:
  python ingest_btcusd_baseline.py /Users/you/Desktop/TP_Integrated_MTBacktest_BITCOIN_05M_v3.0.csv 
Optional flags:
  --dest-folder MQL5/Backtest_Reports/BTCUSD

This script:
  1. Validates source file exists
  2. Normalizes filename to internal convention: TP_Integrated_MTBacktest_Report_BITCOIN_3.0_05M.csv
  3. Copies into symbol folder
  4. Parses trade rows (matching NAS100 structure) and computes:
       - trade_count (completed round turns counted by 'out' direction)
       - gross_profit, gross_loss
       - win_rate
       - profit_factor
       - average_win, average_loss
       - median_hold_minutes (approx from Time sequence) -- heuristic if timestamps available
  5. Saves a small summary JSON alongside CSV for downstream pipeline.

Assumptions:
  - CSV format matches existing NAS100 MTBacktest report with header:
      Time,Deal,Symbol,Type,Direction,Volume,Price,Order,Commission,Swap,Profit,Balance,Comment
  - Completed trade exit rows are those with Direction 'out'. Profit column contains signed value.

If format mismatch occurs, script will emit warnings and still copy raw file.
"""
from __future__ import annotations
import sys, os, csv, json, statistics
from pathlib import Path
from datetime import datetime

DEFAULT_DEST = Path('MQL5/Backtest_Reports/BTCUSD')
NORMALIZED_NAME = 'TP_Integrated_MTBacktest_Report_BITCOIN_3.0_05M.csv'
SUMMARY_NAME = 'BTCUSD_v3_0_baseline_summary.json'

HEADER_EXPECTED = ['Time','Deal','Symbol','Type','Direction','Volume','Price','Order','Commission','Swap','Profit','Balance','Comment']

def parse_time(s: str) -> datetime | None:
    s = s.strip()
    try:
        # MT5 format: YYYY.MM.DD HH:MM:SS
        return datetime.strptime(s, '%Y.%m.%d %H:%M:%S')
    except Exception:
        return None

def ingest(src_path: Path, dest_folder: Path):
    if not src_path.exists():
        print(f"❌ Source file not found: {src_path}")
        return 1
    dest_folder.mkdir(parents=True, exist_ok=True)
    dest_path = dest_folder / NORMALIZED_NAME

    # Copy file
    data = src_path.read_bytes()
    dest_path.write_bytes(data)
    print(f"✅ Copied BTCUSD baseline report → {dest_path} ({len(data):,} bytes)")

    # Parse metrics
    trade_profits = []
    win_profits = []
    loss_profits = []
    exit_times = []

    with dest_path.open('r', newline='') as f:
        reader = csv.reader(f)
        header = next(reader, None)
        if header is None:
            print('⚠️ Empty CSV; aborting metric parse.')
            return 2
        if header != HEADER_EXPECTED:
            print('⚠️ Header mismatch – metrics may be unreliable.')
        profit_idx = header.index('Profit') if 'Profit' in header else None
        direction_idx = header.index('Direction') if 'Direction' in header else None
        time_idx = header.index('Time') if 'Time' in header else None

        for row in reader:
            if not row or len(row) < len(header):
                continue
            direction = row[direction_idx].strip() if direction_idx is not None else ''
            if direction.lower() != 'out':
                continue  # only count completed exits
            profit_raw = row[profit_idx].replace(' ', '').replace('\u202f','') if profit_idx is not None else '0'
            profit_raw = profit_raw.replace('+','')
            profit_raw = profit_raw.replace('−','-')  # handle possible unicode minus
            try:
                profit = float(profit_raw)
            except ValueError:
                # MT5 sometimes prefixes with '-' and space
                profit = float(profit_raw.replace(' -', '-')) if profit_raw else 0.0
            trade_profits.append(profit)
            if profit >= 0:
                win_profits.append(profit)
            else:
                loss_profits.append(profit)
            if time_idx is not None:
                t = parse_time(row[time_idx])
                if t:
                    exit_times.append(t)

    trade_count = len(trade_profits)
    gross_profit = sum(p for p in trade_profits if p >= 0)
    gross_loss = -sum(p for p in trade_profits if p < 0)
    win_rate = (len(win_profits) / trade_count * 100.0) if trade_count else 0.0
    profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else (gross_profit if gross_profit > 0 else 0.0)
    avg_win = statistics.mean(win_profits) if win_profits else 0.0
    avg_loss = statistics.mean(loss_profits) if loss_profits else 0.0

    # Simple hold time heuristic not available from single exit rows (need pairing); skip for now
    median_hold_minutes = None

    summary = {
        'symbol': 'BTCUSD',
        'version': '3.0',
        'timeframe': '05M',
        'trade_count': trade_count,
        'win_rate_percent': round(win_rate, 2),
        'profit_factor': round(profit_factor, 3),
        'gross_profit': round(gross_profit, 2),
        'gross_loss': round(gross_loss, 2),
        'average_win': round(avg_win, 4),
        'average_loss': round(avg_loss, 4),
        'median_hold_minutes': median_hold_minutes,
        'data_file': str(dest_path),
    }

    summary_path = dest_folder / SUMMARY_NAME
    summary_path.write_text(json.dumps(summary, indent=2))
    print('📊 Baseline Summary:')
    for k, v in summary.items():
        print(f"  {k}: {v}")
    print(f"✅ Summary saved → {summary_path}")

    # Gate suggestions
    print('\n🔍 Promotion Gate Check (to proceed to v3.1):')
    gates = [
        (trade_count >= 120, f"Trades >=120 ({trade_count})"),
        (win_rate >= 30.0, f"WinRate >=30% ({win_rate:.2f}%)"),
        (profit_factor >= 1.05, f"PF >=1.05 ({profit_factor:.3f})"),
    ]
    for ok, label in gates:
        print(f"  {'✅' if ok else '⚠️'} {label}")

    return 0

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python ingest_btcusd_baseline.py /path/to/TP_Integrated_MTBacktest_BITCOIN_05M_v3.0.csv')
        sys.exit(1)
    src = Path(sys.argv[1])
    dest_arg = None
    for i,a in enumerate(sys.argv):
        if a == '--dest-folder' and i+1 < len(sys.argv):
            dest_arg = Path(sys.argv[i+1])
    dest = dest_arg if dest_arg else DEFAULT_DEST
    rc = ingest(src, dest)
    sys.exit(rc)
