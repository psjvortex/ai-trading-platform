# AI Trading Platform - Chat Log

This file captures important conversations and decisions for project continuity.

---

## Session: November 27, 2025

### Topic: v5.0.0.0 Scalping Strategy Development

**Context**: Developing a NAS100 scalping EA with tight 200-point SL/TP (1:1 ratio) to identify Physics-based edge.

**Key Decisions**:
1. **Timeframe**: M2 (2-minute) recommended over M1 (too noisy) or M5 (too slow for scalping)
2. **Spread Filter**: Must set MaxSpreadPips < StopLoss (e.g., 20 pips max for 200-point target)
3. **Exit Logic**: Current EA uses only Hard SL/TP + Signal Reversal (no trailing stop implemented yet)

**Strategy Rationale**:
- Flattened all Physics filters to allow maximum entries (data farming phase)
- 1:1 R:R ratio isolates the Physics edge - if we can get 55-60% win rate, the system is profitable
- M2 smooths M1 noise while reacting 2.5x faster than M5

**Files Modified**:
- `web/src/components/ExitAnalysis.tsx` - Updated CSV export to include ALL columns (matching full trade list)
- Git commit `df8cd5b` - Saved state before project folder move

**Next Steps**:
1. Run M2 backtest with loose filters
2. Generate trades CSV
3. Analyze Physics signatures of TP vs SL trades
4. Identify winning thresholds

---

## How to Use This Log

When starting a new chat or reopening a session, type `Log.` at the end of your message to request the AI append the conversation summary to this file.

