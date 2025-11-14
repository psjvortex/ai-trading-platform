//+------------------------------------------------------------------+
//|                                          Test_CSVLogger.mq5       |
//|                     TickPhysics CSV Logger Library Test           |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "1.0"
#property strict

#include <TickPhysics/TP_CSV_Logger.mqh>
#include <TickPhysics/TP_Physics_Indicator.mqh>

//--- Globals
CCSVLogger g_logger;
CPhysicsIndicator g_physics;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🧪 Testing TP_CSV_Logger.mqh Library");
   Print("═══════════════════════════════════════════════════════");
   
   // Test 1: Initialize Logger
   LoggerConfig config;
   config.signalLogFile = "TP_Test_Signals_" + _Symbol + ".csv";
   config.tradeLogFile = "TP_Test_Trades_" + _Symbol + ".csv";
   config.createHeaders = true;
   config.appendMode = true;
   config.timestampFiles = false;
   config.logToExpertLog = true;
   config.debugMode = true;
   
   if(!g_logger.Initialize(_Symbol, config))
   {
      Print("❌ TEST FAILED: Logger initialization");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Logger Initialization");
   Print("📊 Signal Log: ", g_logger.GetSignalLogFile());
   Print("📊 Trade Log: ", g_logger.GetTradeLogFile());
   
   // Test 2: Initialize Physics Indicator (for realistic data)
   if(!g_physics.Initialize("TickPhysics_Crypto_Indicator_v2_1", false))
   {
      Print("⚠️ WARNING: Physics indicator not available, using mock data");
   }
   else
   {
      Print("✅ TEST PASSED: Physics Indicator Ready");
      Sleep(100);  // Let it warm up
   }
   
   // Test 3: Log Test Signal (BUY)
   SignalLogEntry signal;
   signal.timestamp = TimeCurrent();
   signal.symbol = _Symbol;
   signal.signal = 1;
   signal.signalType = "BUY";
   
   // Get real physics metrics if available
   if(g_physics.IsInitialized())
   {
      signal.quality = g_physics.GetQuality();
      signal.confluence = g_physics.GetConfluence();
      signal.momentum = g_physics.GetMomentum();
      signal.speed = g_physics.GetSpeed();
      signal.acceleration = g_physics.GetAcceleration();
      signal.entropy = g_physics.GetEntropy();
      signal.jerk = g_physics.GetJerk();
      signal.zone = g_physics.GetZoneName(g_physics.GetTradingZone());
      signal.regime = g_physics.GetRegimeName(g_physics.GetVolatilityRegime());
      signal.highThreshold = g_physics.GetHighThreshold();
      signal.lowThreshold = g_physics.GetLowThreshold();
   }
   else
   {
      // Mock data
      signal.quality = 75.5;
      signal.confluence = 80.2;
      signal.momentum = 125.3;
      signal.speed = 2500.0;
      signal.acceleration = 15000.0;
      signal.entropy = 1.2;
      signal.jerk = 5000.0;
      signal.zone = "BULL";
      signal.regime = "NORMAL";
      signal.highThreshold = 600.0;
      signal.lowThreshold = -600.0;
   }
   
   signal.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   signal.spread = g_logger.GetCurrentSpread();
   signal.balance = AccountInfoDouble(ACCOUNT_BALANCE);
   signal.equity = AccountInfoDouble(ACCOUNT_EQUITY);
   signal.openPositions = PositionsTotal();
   signal.physicsPass = true;
   signal.rejectReason = "PASS";
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   signal.hour = dt.hour;
   signal.dayOfWeek = dt.day_of_week;
   
   if(!g_logger.LogSignal(signal))
   {
      Print("❌ TEST FAILED: Signal logging");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: BUY Signal Logged");
   
   // Test 4: Log Test Signal (SELL)
   signal.signal = -1;
   signal.signalType = "SELL";
   signal.physicsPass = false;
   signal.rejectReason = "Quality_Low_62.3<70.0";
   
   if(!g_logger.LogSignal(signal))
   {
      Print("❌ TEST FAILED: SELL signal logging");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: SELL Signal Logged (Rejected)");
   
   // Test 5: Log Test Signal (NONE)
   signal.signal = 0;
   signal.signalType = "NONE";
   signal.physicsPass = true;
   signal.rejectReason = "No_Signal";
   
   if(!g_logger.LogSignal(signal))
   {
      Print("❌ TEST FAILED: NONE signal logging");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: NONE Signal Logged");
   
   // Test 6: Log Winning Trade (TP hit, but price continued higher)
   TradeLogEntry trade;
   trade.ticket = 123456789;
   trade.openTime = TimeCurrent() - 3600;  // 1 hour ago
   trade.closeTime = TimeCurrent();
   trade.symbol = _Symbol;
   trade.type = "BUY";
   trade.lots = 0.1;
   trade.openPrice = 3500.0;
   trade.closePrice = 3550.0;
   trade.sl = 3450.0;
   trade.tp = 3600.0;
   
   // Entry conditions
   trade.entryQuality = 75.5;
   trade.entryConfluence = 80.2;
   trade.entryMomentum = 125.3;
   trade.entryEntropy = 1.2;
   trade.entryZone = "BULL";
   trade.entryRegime = "NORMAL";
   trade.entrySpread = 2.5;
   
   // Exit conditions
   trade.exitReason = "TP";
   trade.exitQuality = 68.0;
   trade.exitConfluence = 55.0;
   trade.exitZone = "TRANSITION";
   trade.exitRegime = "NORMAL";
   
   // Calculate performance metrics
   trade.profit = 500.0;
   trade.profitPercent = 0.5;  // 0.5% of account
   trade.pips = g_logger.CalculatePips(trade.openPrice, trade.closePrice, true);
   trade.holdTimeBars = 60;
   trade.holdTimeMinutes = 60;
   
   // Risk metrics
   trade.riskPercent = 2.0;
   trade.rRatio = trade.profitPercent / trade.riskPercent;  // 0.25 R
   trade.slippage = 0.5;
   trade.commission = 5.0;
   
   // MFE/MAE (During Trade)
   trade.mfe = 3570.0;  // Best price reached DURING trade
   trade.mae = 3485.0;  // Worst price reached DURING trade
   trade.mfePercent = g_logger.CalculatePips(trade.openPrice, trade.mfe, true) / 100.0;
   trade.maePercent = g_logger.CalculatePips(trade.openPrice, trade.mae, true) / 100.0;
   trade.mfePips = g_logger.CalculatePips(trade.openPrice, trade.mfe, true);
   trade.maePips = g_logger.CalculatePips(trade.openPrice, trade.mae, true);
   trade.mfeTimeBars = 45;
   trade.maeTimeBars = 10;
   
   // RunUp/RunDown (After Trade Closed)
   // Scenario: Hit TP at 3550, but price continued to 3620 (70 pip runup!)
   trade.runUpPrice = 3620.0;   // Price continued favorably AFTER exit
   trade.runUpPips = g_logger.CalculatePips(trade.closePrice, trade.runUpPrice, true);
   trade.runUpPercent = (trade.runUpPrice - trade.closePrice) / trade.closePrice * 100.0;
   trade.runUpTimeBars = 25;    // Runup occurred 25 bars after exit
   
   trade.runDownPrice = 3545.0; // Minor pullback after exit
   trade.runDownPips = g_logger.CalculatePips(trade.closePrice, trade.runDownPrice, true);
   trade.runDownPercent = (trade.runDownPrice - trade.closePrice) / trade.closePrice * 100.0;
   trade.runDownTimeBars = 5;   // Pullback occurred 5 bars after exit
   
   // Account state
   trade.balanceAfter = AccountInfoDouble(ACCOUNT_BALANCE) + trade.profit;
   trade.equityAfter = AccountInfoDouble(ACCOUNT_EQUITY) + trade.profit;
   trade.drawdownPercent = 0.0;
   
   // Time analysis
   MqlDateTime entryDt, exitDt;
   TimeToStruct(trade.openTime, entryDt);
   TimeToStruct(trade.closeTime, exitDt);
   trade.entryHour = entryDt.hour;
   trade.entryDayOfWeek = entryDt.day_of_week;
   trade.exitHour = exitDt.hour;
   trade.exitDayOfWeek = exitDt.day_of_week;
   
   if(!g_logger.LogTrade(trade))
   {
      Print("❌ TEST FAILED: Winning trade logging");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Winning Trade Logged");
   Print("   Profit: $", trade.profit, " | Pips: ", trade.pips, " | R: ", trade.rRatio);
   Print("   RunUp: +", trade.runUpPips, " pips (TP too early! Left $$ on table)");
   
   // Test 7: Log Losing Trade (SL hit, but price reversed after - got shaken out!)
   trade.ticket = 987654321;
   trade.type = "SELL";
   trade.openPrice = 3500.0;
   trade.closePrice = 3530.0;  // Loss for SELL
   trade.sl = 3550.0;
   trade.tp = 3450.0;
   trade.exitReason = "SL";
   trade.profit = -300.0;
   trade.profitPercent = -0.3;
   trade.pips = g_logger.CalculatePips(trade.openPrice, trade.closePrice, false);
   trade.rRatio = trade.profitPercent / trade.riskPercent;  // -0.15 R
   trade.mfe = 3480.0;
   trade.mae = 3550.0;
   
   // RunUp/RunDown (After Trade Closed)
   // Scenario: Hit SL at 3530, but price reversed to 3460 (would have been profit!)
   trade.runUpPrice = 3520.0;   // Minor favorable move after exit
   trade.runUpPips = g_logger.CalculatePips(trade.closePrice, trade.runUpPrice, false);
   trade.runUpPercent = (trade.runUpPrice - trade.closePrice) / trade.closePrice * 100.0;
   trade.runUpTimeBars = 8;
   
   trade.runDownPrice = 3460.0; // Price reversed AFTER we were stopped out!
   trade.runDownPips = g_logger.CalculatePips(trade.closePrice, trade.runDownPrice, false);
   trade.runDownPercent = (trade.runDownPrice - trade.closePrice) / trade.closePrice * 100.0;
   trade.runDownTimeBars = 45;  // Reversal happened 45 bars after SL
   
   if(!g_logger.LogTrade(trade))
   {
      Print("❌ TEST FAILED: Losing trade logging");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Losing Trade Logged");
   Print("   Profit: $", trade.profit, " | Pips: ", trade.pips, " | R: ", trade.rRatio);
   
   Print("═══════════════════════════════════════════════════════");
   Print("✅ ALL TESTS PASSED - CSV Logger Library Working!");
   Print("═══════════════════════════════════════════════════════");
   Print("");
   Print("📋 FILES CREATED:");
   Print("  • ", g_logger.GetSignalLogFile(), " (3 signals)");
   Print("  • ", g_logger.GetTradeLogFile(), " (2 trades)");
   Print("");
   Print("📊 Check the MQL5/Files folder for CSV outputs!");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("🛑 Test completed, reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // No tick processing needed for test
}
//+------------------------------------------------------------------+
