# TP_CSV_Logger.mqh - Quick Reference Guide

## Overview
Comprehensive CSV logging system for TickPhysics trading signals and trades. Captures 25+ signal fields and 45+ trade fields for analysis and ML training.

---

## 📦 Installation

```cpp
#include <TickPhysics/TP_CSV_Logger.mqh>
```

---

## 🚀 Quick Start

### Basic Setup

```cpp
CCSVLogger g_logger;

int OnInit()
{
   // Configure logger
   LoggerConfig config;
   config.signalLogFile = "TP_Signals_" + _Symbol + ".csv";
   config.tradeLogFile = "TP_Trades_" + _Symbol + ".csv";
   config.createHeaders = true;        // Auto-create CSV headers
   config.appendMode = true;            // Append to existing files
   config.timestampFiles = false;       // Don't add timestamp to filename
   config.logToExpertLog = true;        // Also print to Experts tab
   config.debugMode = true;             // Verbose output
   
   if(!g_logger.Initialize(_Symbol, config))
   {
      Print("Failed to initialize logger");
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}
```

---

## 📊 Signal Logging (25 Fields)

### Create and Log a Signal

```cpp
SignalLogEntry signal;

// Basic Info
signal.timestamp = TimeCurrent();
signal.symbol = _Symbol;
signal.signal = 1;              // 1=BUY, -1=SELL, 0=NONE
signal.signalType = "BUY";

// Physics Metrics (from TP_Physics_Indicator)
signal.quality = g_physics.GetQuality();
signal.confluence = g_physics.GetConfluence();
signal.momentum = g_physics.GetMomentum();
signal.speed = g_physics.GetSpeed();
signal.acceleration = g_physics.GetAcceleration();
signal.entropy = g_physics.GetEntropy();
signal.jerk = g_physics.GetJerk();

// Classification
signal.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
signal.regime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());

// Market Context
signal.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
signal.spread = g_logger.GetCurrentSpread();
signal.highThreshold = g_physics.GetHighThreshold();
signal.lowThreshold = g_physics.GetLowThreshold();

// Account State
signal.balance = AccountInfoDouble(ACCOUNT_BALANCE);
signal.equity = AccountInfoDouble(ACCOUNT_EQUITY);
signal.openPositions = PositionsTotal();

// Filter Status
signal.physicsPass = true;
signal.rejectReason = "PASS";

// Time Context
MqlDateTime dt;
TimeToStruct(TimeCurrent(), dt);
signal.hour = dt.hour;
signal.dayOfWeek = dt.day_of_week;

// Log it
g_logger.LogSignal(signal);
```

### Signal Log Fields (25)

| Field | Type | Description |
|-------|------|-------------|
| Timestamp | datetime | Signal generation time |
| Symbol | string | Trading symbol |
| Signal | int | 1=BUY, -1=SELL, 0=NONE |
| SignalType | string | "BUY", "SELL", "NONE" |
| Quality | double | Trend quality (0-100) |
| Confluence | double | Indicator confluence (0-100) |
| Momentum | double | Price momentum |
| Speed | double | Price velocity |
| Acceleration | double | Price acceleration |
| Entropy | double | Market chaos metric |
| Jerk | double | Rate of acceleration change |
| Zone | string | BULL, BEAR, TRANSITION, AVOID |
| Regime | string | LOW, NORMAL, HIGH |
| Price | double | Current price |
| Spread | double | Current spread (points) |
| HighThreshold | double | Upper momentum threshold |
| LowThreshold | double | Lower momentum threshold |
| Balance | double | Account balance |
| Equity | double | Account equity |
| OpenPositions | int | Number of open positions |
| PhysicsPass | bool | Filter result (PASS/REJECT) |
| RejectReason | string | Rejection reason if failed |
| Hour | int | Hour of day (0-23) |
| DayOfWeek | int | Day of week (0-6) |

---

## 💰 Trade Logging (45 Fields)

### Create and Log a Trade

```cpp
TradeLogEntry trade;

// Trade Identification
trade.ticket = 123456789;
trade.openTime = D'2025.11.04 08:00';
trade.closeTime = TimeCurrent();
trade.symbol = _Symbol;
trade.type = "BUY";

// Trade Parameters
trade.lots = 0.1;
trade.openPrice = 3500.0;
trade.closePrice = 3550.0;
trade.sl = 3450.0;
trade.tp = 3600.0;

// Entry Conditions (capture at entry)
trade.entryQuality = 75.5;
trade.entryConfluence = 80.2;
trade.entryMomentum = 125.3;
trade.entryEntropy = 1.2;
trade.entryZone = "BULL";
trade.entryRegime = "NORMAL";
trade.entrySpread = 2.5;

// Exit Conditions (capture at exit)
trade.exitReason = "TP";
trade.exitQuality = 68.0;
trade.exitConfluence = 55.0;
trade.exitZone = "TRANSITION";
trade.exitRegime = "NORMAL";

// Performance Metrics
trade.profit = 500.0;
trade.profitPercent = 0.5;
trade.pips = g_logger.CalculatePips(trade.openPrice, trade.closePrice, true);
trade.holdTimeBars = 60;
trade.holdTimeMinutes = 60;

// Risk Metrics
trade.riskPercent = 2.0;
trade.rRatio = trade.profitPercent / trade.riskPercent;
trade.slippage = 0.5;
trade.commission = 5.0;

// MFE/MAE (Max Favorable/Adverse Excursion)
trade.mfe = 3570.0;              // Best price reached
trade.mae = 3485.0;              // Worst price reached
trade.mfePercent = 2.0;
trade.maePercent = -0.43;
trade.mfePips = 70.0;
trade.maePips = -15.0;
trade.mfeTimeBars = 45;          // When MFE occurred
trade.maeTimeBars = 10;          // When MAE occurred

// Account State
trade.balanceAfter = AccountInfoDouble(ACCOUNT_BALANCE);
trade.equityAfter = AccountInfoDouble(ACCOUNT_EQUITY);
trade.drawdownPercent = 0.0;

// Time Analysis
MqlDateTime entryDt, exitDt;
TimeToStruct(trade.openTime, entryDt);
TimeToStruct(trade.closeTime, exitDt);
trade.entryHour = entryDt.hour;
trade.entryDayOfWeek = entryDt.day_of_week;
trade.exitHour = exitDt.hour;
trade.exitDayOfWeek = exitDt.day_of_week;

// Log it
g_logger.LogTrade(trade);
```

### Trade Log Fields (45)

| Category | Fields | Description |
|----------|--------|-------------|
| **Identification** | Ticket, OpenTime, CloseTime, Symbol, Type | Trade identity |
| **Parameters** | Lots, OpenPrice, ClosePrice, SL, TP | Trade setup |
| **Entry Physics** | Quality, Confluence, Momentum, Entropy, Zone, Regime, Spread | Entry conditions |
| **Exit Conditions** | ExitReason, Quality, Confluence, Zone, Regime | Exit state |
| **Performance** | Profit, ProfitPercent, Pips, HoldTimeBars, HoldTimeMinutes | Results |
| **Risk** | RiskPercent, RRatio, Slippage, Commission | Risk metrics |
| **Excursion** | MFE, MAE (price, %, pips, timing) | Price excursions |
| **Account** | BalanceAfter, EquityAfter, DrawdownPercent | Account impact |
| **Time** | EntryHour, EntryDayOfWeek, ExitHour, ExitDayOfWeek | Timing analysis |

---

## 🛠️ Helper Functions

### Calculate Pips

```cpp
double pips = g_logger.CalculatePips(openPrice, closePrice, isBuy);
```

### Get Current Spread

```cpp
double spread = g_logger.GetCurrentSpread();  // Returns points
```

### Check Logger Status

```cpp
if(g_logger.IsInitialized())
{
   Print("Logger ready");
   Print("Signal log: ", g_logger.GetSignalLogFile());
   Print("Trade log: ", g_logger.GetTradeLogFile());
}
```

---

## 🎯 Integration Example

### Full Integration with Physics Indicator

```cpp
#include <TickPhysics/TP_CSV_Logger.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>

CCSVLogger g_logger;
CPhysicsIndicator g_physics;

int OnInit()
{
   // Initialize physics
   g_physics.Initialize("TickPhysics_Crypto_Indicator_v2_1", false);
   
   // Initialize logger
   LoggerConfig config;
   config.signalLogFile = "Signals_" + _Symbol + ".csv";
   config.tradeLogFile = "Trades_" + _Symbol + ".csv";
   config.createHeaders = true;
   config.debugMode = true;
   
   g_logger.Initialize(_Symbol, config);
   
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // Check for signal
   CPhysicsIndicator::PhysicsMetrics metrics;
   g_physics.GetAllMetrics(metrics);
   
   string reason;
   int signal = (metrics.momentum > 0) ? 1 : -1;
   bool pass = g_physics.CheckPhysicsFilters(signal, 70, 60, 50, true, false, true, 2.5, 5, reason);
   
   // Log signal
   SignalLogEntry sigLog;
   sigLog.timestamp = TimeCurrent();
   sigLog.symbol = _Symbol;
   sigLog.signal = pass ? signal : 0;
   sigLog.signalType = pass ? (signal > 0 ? "BUY" : "SELL") : "NONE";
   sigLog.quality = metrics.quality;
   sigLog.confluence = metrics.confluence;
   sigLog.momentum = metrics.momentum;
   sigLog.speed = metrics.speed;
   sigLog.acceleration = metrics.acceleration;
   sigLog.entropy = metrics.entropy;
   sigLog.zone = g_physics.GetZoneName(metrics.zone);
   sigLog.regime = g_physics.GetRegimeName(metrics.regime);
   sigLog.physicsPass = pass;
   sigLog.rejectReason = reason;
   // ... fill other fields ...
   
   g_logger.LogSignal(sigLog);
   
   if(pass)
   {
      // Open trade and track for logging on close
   }
}
```

---

## 📁 Output Files

CSV files are created in: `MQL5/Files/`

**File naming:**
- Default: `TP_Signals_SYMBOL.csv`, `TP_Trades_SYMBOL.csv`
- With timestamp: `TP_Signals_SYMBOL_2025_11_04.csv`

**Import to Python:**
```python
import pandas as pd

signals = pd.read_csv('TP_Signals_ETHEREUM.csv')
trades = pd.read_csv('TP_Trades_ETHEREUM.csv')

print(signals.head())
print(f"Total signals: {len(signals)}")
print(f"Pass rate: {signals['PhysicsPass'].sum() / len(signals) * 100:.1f}%")

print(trades.head())
print(f"Win rate: {(trades['Profit'] > 0).sum() / len(trades) * 100:.1f}%")
print(f"Avg R-Ratio: {trades['RRatio'].mean():.2f}")
```

---

## ⚙️ Configuration Options

```cpp
LoggerConfig config;

// File Settings
config.signalLogFile = "signals.csv";     // Signal log filename
config.tradeLogFile = "trades.csv";       // Trade log filename
config.createHeaders = true;              // Create CSV headers
config.appendMode = true;                 // Append vs overwrite
config.timestampFiles = false;            // Add timestamp suffix

// Output Settings
config.logToExpertLog = true;             // Print to Experts tab
config.debugMode = false;                 // Verbose debug output
```

---

## 🔍 Troubleshooting

### Logger not initializing
```cpp
// Check if files directory exists
// MetaTrader creates MQL5/Files automatically
// But verify permissions
```

### No data in CSV
```cpp
// Verify logger initialized
if(!g_logger.IsInitialized())
{
   Print("ERROR: Logger not initialized!");
}

// Check file handle errors in Experts tab
```

### CSV format issues
```cpp
// Headers auto-created if createHeaders = true
// To recreate headers, delete CSV file and restart
```

---

## 📊 Performance

- **Overhead**: Minimal (~1-2ms per log entry)
- **File I/O**: Buffered writes, no performance impact
- **Memory**: ~5KB per 100 entries
- **Recommended**: Log on bar close, not every tick

---

## ✅ Best Practices

1. **Initialize once** in OnInit()
2. **Log signals** when filter checks complete
3. **Log trades** on close (in OnTradeTransaction)
4. **Use appendMode** for continuous logging
5. **Enable debug** during development, disable in production
6. **Timestamp files** for session separation
7. **Archive old CSVs** to prevent huge files

---

## 📚 See Also

- **TP_Risk_Manager.mqh** - Risk calculation and position sizing
- **TP_Physics_Indicator.mqh** - Physics metrics source
- **Test_CSVLogger.mq5** - Complete test examples

---

**Version:** 8.0  
**Date:** November 4, 2025  
**License:** Copyright 2025, QuanAlpha
