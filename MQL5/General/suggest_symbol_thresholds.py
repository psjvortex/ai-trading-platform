#!/usr/bin/env python3
"""
Suggest thresholds for a new symbol/timeframe using Trades CSV:
- MinMomentum: 10th and 20th percentile of winners' EntryMomentum
- Hourly WR: recommend blocked hours (WR < 20% with >= N trades)

Usage:
  python3 suggest_symbol_thresholds.py --symbol BTCUSD --version v3.0_05M
  python3 suggest_symbol_thresholds.py --file ../Backtest_Reports/TP_Integrated_Trades_BTCUSD_v3.0_05M.csv

Outputs recommendations to console and writes a JSON file next to the CSV.
"""
import argparse
import json
from pathlib import Path
import pandas as pd

DEFAULT_BACKTEST_DIR = Path(__file__).parent.parent / "Backtest_Reports"


def infer_csv_path(symbol: str, version: str) -> Path:
    # We use the naming pattern produced by the EA CSV logger
    fname = f"TP_Integrated_Trades_{symbol}_{version}.csv"
    return DEFAULT_BACKTEST_DIR / fname


def load_csv(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    # Basic sanity
    required = [
        "Profit",
        "EntryMomentum",
        "OpenTime",
    ]
    for col in required:
        if col not in df.columns:
            raise ValueError(f"Missing required column: {col}")
    return df


def compute_recommendations(df: pd.DataFrame, symbol: str, version: str):
    df = df.copy()
    # winners/losers
    winners = df[df["Profit"] > 0]
    losers = df[df["Profit"] <= 0]

    # Momentum quantiles from winners
    q10 = float(winners["EntryMomentum"].quantile(0.10)) if len(winners) else None
    q20 = float(winners["EntryMomentum"].quantile(0.20)) if len(winners) else None

    # Hourly WR
    df["Hour"] = pd.to_datetime(df["OpenTime"]).dt.hour
    hourly = (
        df.groupby("Hour").agg(
            trades=("Profit", "count"),
            wins=("Profit", lambda s: (s > 0).sum()),
        )
    )
    hourly["wr"] = (hourly["wins"] / hourly["trades"] * 100).fillna(0.0)

    # Recommend blocked hours: low WR and enough samples
    min_trades = max(5, int(df.shape[0] * 0.02))  # at least 2% of total, min 5
    blocked = hourly[(hourly["trades"] >= min_trades) & (hourly["wr"] < 20.0)].index.tolist()

    rec = {
        "symbol": symbol,
        "version": version,
        "total_trades": int(df.shape[0]),
        "win_rate": float((df["Profit"] > 0).mean() * 100),
        "momentum_recommendation": {
            "winners_q10": q10,
            "winners_q20": q20,
            "suggested_MinMomentum": q10,  # start conservative at 10th percentile
        },
        "hourly_wr": hourly.reset_index().to_dict(orient="records"),
        "suggested_blocked_hours": blocked,
    }
    return rec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--symbol", help="Symbol, e.g., BTCUSD")
    ap.add_argument("--version", default="v3.0_05M", help="CSV version suffix, e.g., v3.0_05M")
    ap.add_argument("--file", help="Direct path to Trades CSV (overrides symbol/version)")
    args = ap.parse_args()

    if args.file:
        csv_path = Path(args.file)
        symbol = args.symbol or csv_path.stem.split("_")[3]
        version = args.version or "_".join(csv_path.stem.split("_")[-2:])
    else:
        if not args.symbol:
            raise SystemExit("Provide --symbol or --file")
        csv_path = infer_csv_path(args.symbol, args.version)
        symbol = args.symbol
        version = args.version

    if not csv_path.exists():
        raise SystemExit(f"CSV not found: {csv_path}")

    df = load_csv(csv_path)
    rec = compute_recommendations(df, symbol, version)

    # Print concise summary
    print("=" * 80)
    print(f"Recommendations for {symbol} ({version})")
    print("=" * 80)
    print(f"Trades: {rec['total_trades']} | WR: {rec['win_rate']:.1f}%")
    mm = rec["momentum_recommendation"]
    print(f"Momentum winners Q10: {mm['winners_q10']}")
    print(f"Momentum winners Q20: {mm['winners_q20']}")
    print(f"Suggested MinMomentum: {mm['suggested_MinMomentum']}")
    print()
    blocked = rec["suggested_blocked_hours"]
    print(f"Suggested blocked hours (WR < 20% with enough samples): {blocked}")

    # Save JSON next to CSV
    out_json = csv_path.with_name(csv_path.stem + "_recommendations.json")
    with open(out_json, "w") as f:
        json.dump(rec, f, indent=2)
    print(f"\nSaved: {out_json}")


if __name__ == "__main__":
    main()
