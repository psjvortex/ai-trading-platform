//============================= CHUNK 4: JSON PART 2 & TRACKING ==========//
// ADD THIS AFTER CHUNK 3
//========================================================================//

//+------------------------------------------------------------------+
//| Optimize parameters based on performance                         |
//+------------------------------------------------------------------+
void OptimizeParameters()
{
   // Reset recommendations
   learningData.adjustQuality = "0";
   learningData.adjustConfluence = "0";
   learningData.adjustSL = "0";
   learningData.adjustTP = "0";
   learningData.adjustRisk = "0";
   learningData.reason = "";
   
   // Decision logic based on win rate
   if(learningData.winRate < 45.0)
   {
      // Poor performance - loosen filters
      learningData.adjustQuality = "-5";
      learningData.adjustConfluence = "-5";
      learningData.reason = "WinRate<45%: Loosening filters to find edge";
      Print("💡 Low win rate - recommending looser filters");
   }
   else if(learningData.winRate >= 45.0 && learningData.winRate < 55.0)
   {
      // Baseline - no change
      learningData.reason = "WinRate 45-55%: Testing current parameters";
      Print("💡 Baseline performance - no adjustments");
   }
   else if(learningData.winRate >= 55.0 && learningData.winRate < 65.0)
   {
      // Good - tighten slightly
      learningData.adjustQuality = "+5";
      learningData.reason = "WinRate 55-65%: Tightening slightly to improve quality";
      Print("💡 Good performance - recommending slight tightening");
   }
   else if(learningData.winRate >= 65.0)
   {
      // Excellent - tighten more
      learningData.adjustQuality = "+10";
      learningData.adjustConfluence = "+5";
      learningData.reason = "WinRate>65%: Excellent! Tightening filters for max quality";
      Print("💡 Excellent performance - recommending tighter filters");
   }
   
   // Adjust based on profit factor
   if(learningData.profitFactor < 1.2)
   {
      learningData.adjustTP = "+0.5";
      learningData.reason += " | PF<1.2: Widening TP";
   }
   
   // Adjust based on drawdown
   if(learningData.maxDrawdown > 15.0)
   {
      learningData.adjustSL = "-0.5";
      learningData.adjustRisk = "-0.5";
      learningData.reason += " | DD>15%: Tightening risk";
   }
}

//+------------------------------------------------------------------+
//| Apply optimized parameters                                       |
//+------------------------------------------------------------------+
void ApplyOptimizedParameters()
{
   // NOTE: In MQL5, we cannot directly modify input parameters at runtime
   // So we store the recommendations in the JSON file for manual application
   
   // Apply Quality adjustment
   double qualityAdj = StringToDouble(learningData.adjustQuality);
   if(qualityAdj != 0)
   {
      double newQuality = InpMinTrendQuality + qualityAdj;
      newQuality = MathMax(50.0, MathMin(90.0, newQuality));
      
      if(newQuality != InpMinTrendQuality)
      {
         Print("📈 Adjusting MinTrendQuality: ", InpMinTrendQuality, " → ", newQuality);
         learningData.MinTrendQuality = newQuality;
      }
   }
   
   // Apply Confluence adjustment
   double confluenceAdj = StringToDouble(learningData.adjustConfluence);
   if(confluenceAdj != 0)
   {
      double newConfluence = InpMinConfluence + confluenceAdj;
      newConfluence = MathMax(40.0, MathMin(80.0, newConfluence));
      
      if(newConfluence != InpMinConfluence)
      {
         Print("📈 Adjusting MinConfluence: ", InpMinConfluence, " → ", newConfluence);
         learningData.MinConfluence = newConfluence;
      }
   }
   
   // Apply SL adjustment
   double slAdj = StringToDouble(learningData.adjustSL);
   if(slAdj != 0)
   {
      double newSL = InpStopLossPercent + slAdj;
      newSL = MathMax(2.0, MathMin(5.0, newSL));
      
      if(newSL != InpStopLossPercent)
      {
         Print("📈 Adjusting StopLossPercent: ", InpStopLossPercent, " → ", newSL);
         learningData.StopLossPercent = newSL;
      }
   }
   
   // Apply TP adjustment
   double tpAdj = StringToDouble(learningData.adjustTP);
   if(tpAdj != 0)
   {
      double newTP = InpTakeProfitPercent + tpAdj;
      newTP = MathMax(1.0, MathMin(4.0, newTP));
      
      if(newTP != InpTakeProfitPercent)
      {
         Print("📈 Adjusting TakeProfitPercent: ", InpTakeProfitPercent, " → ", newTP);
         learningData.TakeProfitPercent = newTP;
      }
   }
   
   // Apply Risk adjustment
   double riskAdj = StringToDouble(learningData.adjustRisk);
   if(riskAdj != 0)
   {
      double newRisk = InpRiskPerTradePercent + riskAdj;
      newRisk = MathMax(0.5, MathMin(5.0, newRisk));
      
      if(newRisk != InpRiskPerTradePercent)
      {
         Print("📈 Adjusting RiskPerTradePercent: ", InpRiskPerTradePercent, " → ", newRisk);
         learningData.RiskPerTradePercent = newRisk;
      }
   }
   
   Print("💡 RECOMMENDED ADJUSTMENTS:");
   Print("   Quality: ", InpMinTrendQuality, " → ", learningData.MinTrendQuality);
   Print("   Confluence: ", InpMinConfluence, " → ", learningData.MinConfluence);
   Print("   Stop Loss: ", InpStopLossPercent, " → ", learningData.StopLossPercent);
   Print("   Take Profit: ", InpTakeProfitPercent, " → ", learningData.TakeProfitPercent);
   Print("   Risk: ", InpRiskPerTradePercent, " → ", learningData.RiskPerTradePercent);
   Print("   Reason: ", learningData.reason);
}

//+------------------------------------------------------------------+
//| Run learning cycle                                               |
//+------------------------------------------------------------------+
void RunLearningCycle()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled");
      return;
   }
   
   Print("🧠 ========== LEARNING CYCLE START ==========");
   
   // 1. Analyze recent performance
   if(!AnalyzePerformance())
   {
      Print("❌ Learning cycle aborted - analysis failed");
      return;
   }
   
   // 2. Determine optimal adjustments
   OptimizeParameters();
   
   // 3. Apply adjustments (store recommendations)
   ApplyOptimizedParameters();
   
   // 4. Save learning data
   learningData.version = EA_VERSION;
   learningData.lastUpdate = TimeCurrent();
   learningData.learningCycle++;
   
   if(!SaveLearningData())
   {
      Print("❌ Failed to save learning data");
      return;
   }
   
   Print("🧠 ========== LEARNING CYCLE COMPLETE ==========");
   Print("📊 Next cycle after 20 more trades");
}

//+------------------------------------------------------------------+
//| Initialize learning system                                       |
//+------------------------------------------------------------------+
bool InitLearningSystem()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled in EA settings");
      return true;
   }
   
   // Try to load existing learning data
   if(LoadLearningData())
   {
      Print("✅ Continuing from learning cycle ", learningData.learningCycle);
      Print("   Current parameters will be used for next ", 20 - (learningData.totalTrades % 20), " trades");
      return true;
   }
   
   // No existing data - initialize with current EA settings
   learningData.MinTrendQuality = InpMinTrendQuality;
   learningData.MinConfluence = InpMinConfluence;
   learningData.MinMomentum = InpMinMomentum;
   learningData.StopLossPercent = InpStopLossPercent;
   learningData.TakeProfitPercent = InpTakeProfitPercent;
   learningData.RiskPerTradePercent = InpRiskPerTradePercent;
   learningData.totalTrades = 0;
   learningData.learningCycle = 0;
   learningData.version = EA_VERSION;
   
   Print("✅ Learning system initialized - starting baseline data collection");
   return true;
}

//+------------------------------------------------------------------+
//| Check if learning trigger should fire                            |
//+------------------------------------------------------------------+
void CheckLearningTrigger()
{
   if(!InpEnableLearning) return;
   
   // Count closed trades
   static int lastTradeCount = 0;
   int currentTradeCount = 0;
   
   // Count trades from CSV
   int handle = FileOpen(InpTradeLogFile, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(handle != INVALID_HANDLE)
   {
      while(!FileIsEnding(handle))
      {
         string line = FileReadString(handle);
         if(StringFind(line, "CLOSE") >= 0)
            currentTradeCount++;
      }
      FileClose(handle);
   }
   
   // Trigger learning every 20 trades
   if(currentTradeCount >= lastTradeCount + 20 && currentTradeCount >= 20)
   {
      Print("🔔 Learning trigger: ", currentTradeCount, " trades completed");
      RunLearningCycle();
      lastTradeCount = currentTradeCount;
   }
}

//========================================================================//
//=================== v5.0: TRACK NEW TRADE ==============================//
//========================================================================//

void TrackNewTrade(ulong ticket, double quality, double confluence, double zone,
                   double regime, double entropy)
{
   if(ticket == 0) return;
   
   // Select the position
   if(!PositionSelectByTicket(ticket))
   {
      Print("ERROR: Cannot select position for tracking: ", ticket);
      return;
   }
   
   // Create new tracker
   int size = ArraySize(currentTrades);
   ArrayResize(currentTrades, size + 1);
   
   // Fill tracker data
   currentTrades[size].ticket = ticket;
   currentTrades[size].openTime = (datetime)PositionGetInteger(POSITION_TIME);
   currentTrades[size].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   currentTrades[size].sl = PositionGetDouble(POSITION_SL);
   currentTrades[size].tp = PositionGetDouble(POSITION_TP);
   currentTrades[size].lots = PositionGetDouble(POSITION_VOLUME);
   currentTrades[size].type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
   
   // Store entry conditions
   currentTrades[size].entryQuality = quality;
   currentTrades[size].entryConfluence = confluence;
   currentTrades[size].entryZone = zone;
   currentTrades[size].entryRegime = regime;
   currentTrades[size].entryEntropy = entropy;
   
   // Get MA values
   double maFast[1], maSlow[1];
   CopyBuffer(maFastEntry_Handle, 0, 0, 1, maFast);
   CopyBuffer(maSlowEntry_Handle, 0, 0, 1, maSlow);
   currentTrades[size].entryMAFast = maFast[0];
   currentTrades[size].entryMASlow = maSlow[0];
   
   // Get spread
   double spread = 0;
   CheckSpreadFilter(spread);
   currentTrades[size].entrySpread = spread;
   
   // Initialize MFE/MAE
   currentTrades[size].mfe = currentTrades[size].openPrice;
   currentTrades[size].mae = currentTrades[size].openPrice;
   
   Print("✅ Trade tracked: #", ticket, " Quality=", quality, " Confluence=", confluence);
}

//========================================================================//
//=================== v5.0: UPDATE MFE/MAE ===============================//
//========================================================================//

void UpdateMFEMAE()
{
   for(int i = 0; i < ArraySize(currentTrades); i++)
   {
      if(!PositionSelectByTicket(currentTrades[i].ticket))
         continue;
      
      double currentPrice = (currentTrades[i].type == ORDER_TYPE_BUY) ?
         SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(currentTrades[i].type == ORDER_TYPE_BUY)
      {
         // For BUY: MFE = highest price, MAE = lowest price
         if(currentPrice > currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice < currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
      else  // SELL
      {
         // For SELL: MFE = lowest price, MAE = highest price
         if(currentPrice < currentTrades[i].mfe)
            currentTrades[i].mfe = currentPrice;
         if(currentPrice > currentTrades[i].mae)
            currentTrades[i].mae = currentPrice;
      }
   }
}

//============================= END OF CHUNK 4 ===========================//
// NEXT: Copy Chunk 5 (LogTradeClose and LogSignal functions)
