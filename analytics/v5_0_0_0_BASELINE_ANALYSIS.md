# v5.0.0.0 Baseline Analysis Report

**Date:** November 26, 2025
**Dataset:** v5.0.0.0 Master Backtest (Quality 60, Score 30)
**Symbol:** NAS100
**Timeframe:** M5

## 1. Executive Summary
The baseline run with relaxed thresholds (Quality 60, Score 30) generated a rich dataset of 2,287 trades. While the overall result was negative (Profit Factor 0.83), this was expected and desired to capture a wide range of market conditions for optimization.

**Key Finding:** The "Physics" metrics show extremely strong predictive power. There is a massive divergence between Winners and Losers in Speed, Slope, and Acceleration, validating the core thesis of the strategy.

## 2. Performance Overview
- **Total Trades:** 2,287
- **Win Rate:** 33.2%
- **Total Profit:** -$8,123.45
- **Profit Factor:** 0.83
- **Expectancy:** -$3.61 per trade

## 3. Physics Metrics Validation
The following metrics show significant separation between winning and losing trades, making them ideal candidates for optimization filters:

| Metric | Winners (Avg) | Losers (Avg) | Difference | Insight |
|--------|--------------|--------------|------------|---------|
| **Speed** | **143.87** | **-193.03** | **+336.91** | **Strongest Predictor.** Winners have positive speed; losers have negative speed. |
| **SpeedSlope** | **317.21** | **34.86** | **+282.35** | Strong predictor. Winners have rapidly increasing speed. |
| **AccelerationSlope** | **267.43** | **-42.59** | **+310.02** | Strong predictor. Winners are accelerating. |
| **PhysicsScore** | 59.62 | 55.18 | +4.45 | Positive correlation, but less dramatic than raw kinematics. |
| **Confluence** | 84.01 | 81.85 | +2.15 | Weak positive correlation. |

## 4. Time Analysis
- **Best Window:** 12:00 - 14:00 (Server Time)
    - 12:00: +$1,216
    - 13:00: +$878
- **Worst Window:** 08:00 - 10:00 (Server Time)
    - 08:00: -$3,609
    - 09:00: -$2,574
    - *Recommendation:* Consider a "no-trade" window or stricter filters during the 08:00-10:00 pre-market/open volatility.

## 5. Data Integrity
- **Match Rate:** 100% (2,287/2,287 trades matched between EA and MT5).
- **Profit Variance:** ~4.2% discrepancy (MT5: -$8,482 vs EA: -$8,123). Likely due to swaps/commissions. Acceptable for pattern recognition but requires awareness for final validation.

## 6. Next Steps
1.  **Optimize Filters:** Apply the "Physics" findings. Specifically, test requiring `Speed > 0` and `SpeedSlope > 100`.
2.  **Time Filtering:** Test excluding the 08:00-10:00 window.
3.  **Granular Optimization:** Use the new `MinQualityBuy`/`MinQualitySell` inputs to tune directional bias (Shorts performed slightly better than Longs in this dataset).
