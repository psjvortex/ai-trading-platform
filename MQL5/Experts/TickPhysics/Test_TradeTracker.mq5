//+------------------------------------------------------------------+
//|                                       Test_TradeTracker.mq5       |
//|                    TickPhysics Trade Tracker Library Test         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "1.0"
#property strict

#include <Trade/Trade.mqh>
#include <TickPhysics/TP_Trade_Tracker.mqh>
#include <TickPhysics/TP_CSV_Logger.mqh>

//--- Globals
CTradeTracker g_tracker;
CCSVLogger g_logger;
CTrade g_trade;

//--- Test parameters
input double TestLots = 0.1;
input int TestSLPips = 50;
input int TestTPPips = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🧪 Testing TP_Trade_Tracker.mqh Library");
   Print("═══════════════════════════════════════════════════════");
   
   // Initialize Trade Tracker
   TrackerConfig trackerConfig;
   trackerConfig.trackMFEMAE = true;
   trackerConfig.trackPostExit = true;
   trackerConfig.postExitMonitorBars = 5;  // Monitor 5 bars after exit (FAST TEST)
   trackerConfig.autoLogTrades = false;  // We'll log manually
   trackerConfig.debugMode = true;
   
   if(!g_tracker.Initialize(_Symbol, trackerConfig))
   {
      Print("❌ TEST FAILED: Tracker initialization");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Tracker Initialization");
   
   // Initialize CSV Logger
   LoggerConfig loggerConfig;
   loggerConfig.signalLogFile = "TP_Tracker_Test_Signals_" + _Symbol + ".csv";
   loggerConfig.tradeLogFile = "TP_Tracker_Test_Trades_" + _Symbol + ".csv";
   loggerConfig.createHeaders = true;
   loggerConfig.appendMode = false;  // Fresh file for test
   loggerConfig.timestampFiles = false;
   loggerConfig.logToExpertLog = true;
   loggerConfig.debugMode = true;
   
   if(!g_logger.Initialize(_Symbol, loggerConfig))
   {
      Print("❌ TEST FAILED: Logger initialization");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Logger Initialization");
   
   // Setup trade execution
   g_trade.SetExpertMagicNumber(123456);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   Print("");
   Print("📋 TEST PLAN:");
   Print("1. Open a BUY position");
   Print("2. Track MFE/MAE in real-time");
   Print("3. Close position manually");
   Print("4. Monitor RunUp/RunDown for 5 bars (FAST TEST)");
   Print("5. Log completed trade to CSV");
   Print("");
   Print("⚠️ MANUAL TEST REQUIRED:");
   Print("   - This EA will open a small position");
   Print("   - Watch the logs for MFE/MAE updates");
   Print("   - Manually close the position to test post-exit tracking");
   Print("   - Or wait for TP/SL to hit");
   Print("═══════════════════════════════════════════════════════");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("═══════════════════════════════════════════════════════");
   Print("🛑 Test completed, reason: ", reason);
   
   // Print final status
   g_tracker.PrintActiveTradesStatus();
   g_tracker.PrintClosedTradesStatus();
   
   // Log any remaining completed trades
   ClosedTrade trade;
   int logged = 0;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      LogCompletedTrade(trade);
      logged++;
   }
   
   if(logged > 0)
      Print("✅ Logged ", logged, " completed trades to CSV");
   
   Print("═══════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   static bool positionOpened = false;
   static int tickCount = 0;
   
   tickCount++;
   
   // Open test position on first tick
   if(!positionOpened && PositionsTotal() == 0)
   {
      Print("");
      Print("🔵 Opening test BUY position...");
      
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      
      double sl = ask - TestSLPips * point * (digits == 3 || digits == 5 ? 10 : 1);
      double tp = ask + TestTPPips * point * (digits == 3 || digits == 5 ? 10 : 1);
      
      if(g_trade.Buy(TestLots, _Symbol, ask, sl, tp, "TradeTracker Test"))
      {
         ulong ticket = g_trade.ResultOrder();
         Print("✅ Position opened: #", ticket);
         
         // Add to tracker with mock physics data
         if(g_tracker.AddTrade(ticket, 
                              75.5,   // entryQuality
                              80.2,   // entryConfluence
                              125.3,  // entryMomentum
                              1.2,    // entryEntropy
                              "BULL", // entryZone
                              "NORMAL", // entryRegime
                              2.0))   // riskPercent
         {
            Print("✅ Trade added to tracker");
            positionOpened = true;
         }
         else
         {
            Print("❌ Failed to add trade to tracker");
         }
      }
      else
      {
         Print("❌ Failed to open position: ", g_trade.ResultRetcodeDescription());
      }
   }
   
   // Update tracker every tick
   g_tracker.UpdateTrades();
   
   // Print status every 100 ticks
   if(tickCount % 100 == 0 && g_tracker.GetActiveCount() > 0)
   {
      Print("");
      Print("📊 Tracker Update (tick ", tickCount, "):");
      Print("   Active trades: ", g_tracker.GetActiveCount());
      Print("   Total MFE: ", DoubleToString(g_tracker.GetTotalMFE(), 1), " pips");
      Print("   Total MAE: ", DoubleToString(g_tracker.GetTotalMAE(), 1), " pips");
      Print("   Avg hold time: ", DoubleToString(g_tracker.GetAverageHoldTime(), 0), " bars");
   }
   
   // Check for completed trades (finished post-exit monitoring)
   ClosedTrade trade;
   while(g_tracker.GetNextCompletedTrade(trade))
   {
      Print("");
      Print("✅ TRADE MONITORING COMPLETE!");
      Print("   Ticket: #", trade.ticket);
      Print("   Profit: ", trade.profit, " (", trade.pips, " pips)");
      Print("   Exit: ", trade.exitReason);
      Print("   MFE: ", trade.mfePips, " pips @ bar ", trade.mfeTimeBars);
      Print("   MAE: ", trade.maePips, " pips @ bar ", trade.maeTimeBars);
      Print("   RunUp: ", trade.runUpPips, " pips @ bar ", trade.runUpTimeBars);
      Print("   RunDown: ", trade.runDownPips, " pips @ bar ", trade.runDownTimeBars);
      
      // Log to CSV
      if(LogCompletedTrade(trade))
      {
         Print("✅ Trade logged to CSV");
      }
   }
   
   // Print monitoring status every 500 ticks if we have closed trades
   if(tickCount % 500 == 0 && g_tracker.GetClosedCount() > 0)
   {
      g_tracker.PrintClosedTradesStatus();
   }
}

//+------------------------------------------------------------------+
//| Log completed trade to CSV                                        |
//+------------------------------------------------------------------+
bool LogCompletedTrade(ClosedTrade &trade)
{
   TradeLogEntry log;
   
   // Basic info
   log.ticket = trade.ticket;
   log.openTime = trade.openTime;
   log.closeTime = trade.closeTime;
   log.symbol = trade.symbol;
   log.type = trade.type;
   log.lots = trade.lots;
   log.openPrice = trade.openPrice;
   log.closePrice = trade.closePrice;
   log.sl = trade.sl;
   log.tp = trade.tp;
   
   // Entry conditions
   log.entryQuality = trade.entryQuality;
   log.entryConfluence = trade.entryConfluence;
   log.entryMomentum = trade.entryMomentum;
   log.entryEntropy = trade.entryEntropy;
   log.entryZone = trade.entryZone;
   log.entryRegime = trade.entryRegime;
   log.entrySpread = trade.entrySpread;
   
   // Exit conditions
   log.exitReason = trade.exitReason;
   log.exitQuality = trade.exitQuality;
   log.exitConfluence = trade.exitConfluence;
   log.exitZone = trade.exitZone;
   log.exitRegime = trade.exitRegime;
   
   // Performance
   log.profit = trade.profit;
   log.profitPercent = trade.profitPercent;
   log.pips = trade.pips;
   log.holdTimeBars = trade.holdTimeBars;
   log.holdTimeMinutes = trade.holdTimeMinutes;
   log.riskPercent = trade.riskPercent;
   log.rRatio = trade.rRatio;
   log.slippage = trade.slippage;
   log.commission = trade.commission;
   
   // MFE/MAE
   log.mfe = trade.mfe;
   log.mae = trade.mae;
   log.mfePercent = trade.mfePercent;
   log.maePercent = trade.maePercent;
   log.mfePips = trade.mfePips;
   log.maePips = trade.maePips;
   log.mfeTimeBars = trade.mfeTimeBars;
   log.maeTimeBars = trade.maeTimeBars;
   
   // RunUp/RunDown
   log.runUpPrice = trade.runUpPrice;
   log.runUpPips = trade.runUpPips;
   log.runUpPercent = trade.runUpPercent;
   log.runUpTimeBars = trade.runUpTimeBars;
   log.runDownPrice = trade.runDownPrice;
   log.runDownPips = trade.runDownPips;
   log.runDownPercent = trade.runDownPercent;
   log.runDownTimeBars = trade.runDownTimeBars;
   
   // Account state
   log.balanceAfter = trade.balanceAfter;
   log.equityAfter = trade.equityAfter;
   log.drawdownPercent = trade.drawdownPercent;
   
   // Time analysis
   log.entryHour = trade.entryHour;
   log.entryDayOfWeek = trade.entryDayOfWeek;
   log.exitHour = trade.exitHour;
   log.exitDayOfWeek = trade.exitDayOfWeek;
   
   return g_logger.LogTrade(log);
}
//+------------------------------------------------------------------+
