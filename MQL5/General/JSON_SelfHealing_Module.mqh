//+------------------------------------------------------------------+
//| JSON_SelfHealing_Module.mqh                                       |
//| Complete self-learning and parameter optimization system          |
//| Reads trade performance and auto-adjusts parameters              |
//+------------------------------------------------------------------+

#property copyright "QuanAlpha"
#property version   "1.00"
#property strict

//===================================================================//
// JSON LEARNING STRUCTURE
//===================================================================//

struct LearningParameters
{
   // Current optimized parameters
   double MinTrendQuality;
   double MinConfluence;
   double MinMomentum;
   double StopLossPercent;
   double TakeProfitPercent;
   double RiskPerTradePercent;
   
   // Performance metrics
   int totalTrades;
   double winRate;
   double profitFactor;
   double sharpeRatio;
   double maxDrawdown;
   double avgWin;
   double avgLoss;
   double avgRRatio;
   
   // Recommendations
   string adjustQuality;
   string adjustConfluence;
   string adjustSL;
   string adjustTP;
   string adjustRisk;
   string reason;
   
   // Metadata
   datetime lastUpdate;
   string version;
   int learningCycle;
};

LearningParameters learningData;

//===================================================================//
// JSON HELPER FUNCTIONS
//===================================================================//

// Simple JSON value extractor
double ExtractJSONValue(string content, string key)
{
   string searchKey = "\"" + key + "\":";
   int pos = StringFind(content, searchKey);
   if(pos < 0) return 0.0;
   
   pos += StringLen(searchKey);
   
   // Skip whitespace
   while(pos < StringLen(content) && (StringGetCharacter(content, pos) == ' ' || 
         StringGetCharacter(content, pos) == '\t' || StringGetCharacter(content, pos) == '\n'))
      pos++;
   
   // Extract number
   string valueStr = "";
   while(pos < StringLen(content))
   {
      ushort ch = StringGetCharacter(content, pos);
      if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == 'e' || ch == 'E' || ch == '+')
         valueStr += ShortToString(ch);
      else
         break;
      pos++;
   }
   
   return StringToDouble(valueStr);
}

string ExtractJSONString(string content, string key)
{
   string searchKey = "\"" + key + "\":\"";
   int pos = StringFind(content, searchKey);
   if(pos < 0) return "";
   
   pos += StringLen(searchKey);
   
   string value = "";
   while(pos < StringLen(content))
   {
      ushort ch = StringGetCharacter(content, pos);
      if(ch == '"') break;  // End of string
      value += ShortToString(ch);
      pos++;
   }
   
   return value;
}

//===================================================================//
// LOAD LEARNING DATA FROM JSON
//===================================================================//

bool LoadLearningData()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled in settings");
      return false;
   }
   
   int handle = FileOpen(InpLearningFile, FILE_READ|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("No existing learning file found - will create new one");
      return false;
   }
   
   string content = "";
   while(!FileIsEnding(handle))
   {
      content += FileReadString(handle);
   }
   FileClose(handle);
   
   if(StringLen(content) < 10)
   {
      Print("Learning file empty or corrupted");
      return false;
   }
   
   // Extract parameters
   learningData.MinTrendQuality = ExtractJSONValue(content, "MinTrendQuality");
   learningData.MinConfluence = ExtractJSONValue(content, "MinConfluence");
   learningData.MinMomentum = ExtractJSONValue(content, "MinMomentum");
   learningData.StopLossPercent = ExtractJSONValue(content, "StopLossPercent");
   learningData.TakeProfitPercent = ExtractJSONValue(content, "TakeProfitPercent");
   learningData.RiskPerTradePercent = ExtractJSONValue(content, "RiskPerTradePercent");
   
   // Extract performance metrics
   learningData.totalTrades = (int)ExtractJSONValue(content, "totalTrades");
   learningData.winRate = ExtractJSONValue(content, "winRate");
   learningData.profitFactor = ExtractJSONValue(content, "profitFactor");
   learningData.maxDrawdown = ExtractJSONValue(content, "maxDrawdown");
   
   // Extract metadata
   learningData.version = ExtractJSONString(content, "version");
   learningData.learningCycle = (int)ExtractJSONValue(content, "learningCycle");
   
   Print("✅ Learning data loaded: Trades=", learningData.totalTrades, 
         " WinRate=", learningData.winRate, "% Cycle=", learningData.learningCycle);
   
   return true;
}

//===================================================================//
// SAVE LEARNING DATA TO JSON
//===================================================================//

bool SaveLearningData()
{
   if(!InpEnableLearning) return false;
   
   int handle = FileOpen(InpLearningFile, FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot create learning file: ", InpLearningFile);
      return false;
   }
   
   // Write JSON structure
   FileWriteString(handle, "{\n");
   FileWriteString(handle, "  \"version\": \"" + learningData.version + "\",\n");
   FileWriteString(handle, "  \"lastUpdate\": \"" + TimeToString(TimeCurrent()) + "\",\n");
   FileWriteString(handle, "  \"learningCycle\": " + IntegerToString(learningData.learningCycle) + ",\n");
   FileWriteString(handle, "  \"totalTrades\": " + IntegerToString(learningData.totalTrades) + ",\n");
   FileWriteString(handle, "  \"parameters\": {\n");
   FileWriteString(handle, "    \"MinTrendQuality\": " + DoubleToString(learningData.MinTrendQuality, 1) + ",\n");
   FileWriteString(handle, "    \"MinConfluence\": " + DoubleToString(learningData.MinConfluence, 1) + ",\n");
   FileWriteString(handle, "    \"MinMomentum\": " + DoubleToString(learningData.MinMomentum, 1) + ",\n");
   FileWriteString(handle, "    \"StopLossPercent\": " + DoubleToString(learningData.StopLossPercent, 1) + ",\n");
   FileWriteString(handle, "    \"TakeProfitPercent\": " + DoubleToString(learningData.TakeProfitPercent, 1) + ",\n");
   FileWriteString(handle, "    \"RiskPerTradePercent\": " + DoubleToString(learningData.RiskPerTradePercent, 1) + "\n");
   FileWriteString(handle, "  },\n");
   FileWriteString(handle, "  \"performance\": {\n");
   FileWriteString(handle, "    \"winRate\": " + DoubleToString(learningData.winRate, 2) + ",\n");
   FileWriteString(handle, "    \"profitFactor\": " + DoubleToString(learningData.profitFactor, 2) + ",\n");
   FileWriteString(handle, "    \"sharpeRatio\": " + DoubleToString(learningData.sharpeRatio, 2) + ",\n");
   FileWriteString(handle, "    \"maxDrawdown\": " + DoubleToString(learningData.maxDrawdown, 2) + ",\n");
   FileWriteString(handle, "    \"avgWin\": " + DoubleToString(learningData.avgWin, 2) + ",\n");
   FileWriteString(handle, "    \"avgLoss\": " + DoubleToString(learningData.avgLoss, 2) + ",\n");
   FileWriteString(handle, "    \"avgRRatio\": " + DoubleToString(learningData.avgRRatio, 2) + "\n");
   FileWriteString(handle, "  },\n");
   FileWriteString(handle, "  \"recommendations\": {\n");
   FileWriteString(handle, "    \"adjustQuality\": \"" + learningData.adjustQuality + "\",\n");
   FileWriteString(handle, "    \"adjustConfluence\": \"" + learningData.adjustConfluence + "\",\n");
   FileWriteString(handle, "    \"adjustSL\": \"" + learningData.adjustSL + "\",\n");
   FileWriteString(handle, "    \"adjustTP\": \"" + learningData.adjustTP + "\",\n");
   FileWriteString(handle, "    \"adjustRisk\": \"" + learningData.adjustRisk + "\",\n");
   FileWriteString(handle, "    \"reason\": \"" + learningData.reason + "\"\n");
   FileWriteString(handle, "  }\n");
   FileWriteString(handle, "}\n");
   
   FileClose(handle);
   
   Print("✅ Learning data saved: Cycle=", learningData.learningCycle);
   return true;
}

//===================================================================//
// ANALYZE TRADE PERFORMANCE FROM CSV
//===================================================================//

bool AnalyzePerformance()
{
   if(!InpEnableTradeLog)
   {
      Print("Trade logging disabled - cannot analyze performance");
      return false;
   }
   
   int handle = FileOpen(InpTradeLogFile, FILE_READ|FILE_CSV|FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      Print("Cannot open trade log file for analysis");
      return false;
   }
   
   // Skip header
   string header = FileReadString(handle);
   
   int totalTrades = 0;
   int wins = 0;
   int losses = 0;
   double totalWinProfit = 0;
   double totalLossProfit = 0;
   double allProfits[];
   ArrayResize(allProfits, 0);
   
   // Read all trades
   while(!FileIsEnding(handle))
   {
      string timestamp = FileReadString(handle);
      if(timestamp == "") break;  // Empty line
      
      string ticket = FileReadString(handle);
      string symbol = FileReadString(handle);
      string action = FileReadString(handle);
      
      // Only process CLOSE actions (complete trades)
      if(action != "CLOSE") 
      {
         // Skip rest of line
         for(int i = 0; i < 30; i++) FileReadString(handle);
         continue;
      }
      
      // Skip to profit column (column 20)
      for(int i = 0; i < 16; i++) FileReadString(handle);
      
      double profit = StringToDouble(FileReadString(handle));
      
      if(profit > 0)
      {
         wins++;
         totalWinProfit += profit;
      }
      else if(profit < 0)
      {
         losses++;
         totalLossProfit += MathAbs(profit);
      }
      
      totalTrades++;
      ArrayResize(allProfits, totalTrades);
      allProfits[totalTrades - 1] = profit;
      
      // Skip rest of columns
      while(StringLen(FileReadString(handle)) > 0 && !FileIsLineEnding(handle));
   }
   
   FileClose(handle);
   
   if(totalTrades < 10)
   {
      Print("Insufficient trades for analysis: ", totalTrades, " < 10");
      return false;
   }
   
   // Calculate metrics
   learningData.totalTrades = totalTrades;
   learningData.winRate = (totalTrades > 0) ? ((double)wins / totalTrades) * 100.0 : 0;
   learningData.profitFactor = (totalLossProfit > 0) ? (totalWinProfit / totalLossProfit) : 0;
   learningData.avgWin = (wins > 0) ? (totalWinProfit / wins) : 0;
   learningData.avgLoss = (losses > 0) ? (totalLossProfit / losses) : 0;
   
   // Calculate max drawdown
   double peak = 0;
   double maxDD = 0;
   double runningTotal = 0;
   for(int i = 0; i < totalTrades; i++)
   {
      runningTotal += allProfits[i];
      if(runningTotal > peak) peak = runningTotal;
      double drawdown = peak - runningTotal;
      if(drawdown > maxDD) maxDD = drawdown;
   }
   learningData.maxDrawdown = (peak > 0) ? (maxDD / peak) * 100.0 : 0;
   
   Print("📊 Performance Analysis:");
   Print("   Trades: ", totalTrades, " | Wins: ", wins, " | Losses: ", losses);
   Print("   Win Rate: ", learningData.winRate, "%");
   Print("   Profit Factor: ", learningData.profitFactor);
   Print("   Avg Win: $", learningData.avgWin, " | Avg Loss: $", learningData.avgLoss);
   Print("   Max Drawdown: ", learningData.maxDrawdown, "%");
   
   return true;
}

//===================================================================//
// OPTIMIZE PARAMETERS BASED ON PERFORMANCE
//===================================================================//

void OptimizeParameters()
{
   learningData.adjustQuality = "0";
   learningData.adjustConfluence = "0";
   learningData.adjustSL = "0";
   learningData.adjustTP = "0";
   learningData.adjustRisk = "0";
   learningData.reason = "";
   
   // Strategy: Adjust based on win rate and profit factor
   
   // 1. Win rate too low → Loosen entry filters
   if(learningData.winRate < 45.0)
   {
      learningData.adjustQuality = "-5";
      learningData.adjustConfluence = "-5";
      learningData.reason += "Low win rate - loosening filters. ";
      Print("🔧 Optimization: Low win rate (", learningData.winRate, "%) - Loosening filters");
   }
   
   // 2. Win rate good but profit factor low → Improve exits
   else if(learningData.winRate >= 50.0 && learningData.profitFactor < 1.2)
   {
      learningData.adjustTP = "+0.5";
      learningData.reason += "Low profit factor - widening TP. ";
      Print("🔧 Optimization: Low PF (", learningData.profitFactor, ") - Widening TP");
   }
   
   // 3. Win rate high → Tighten entry filters for quality
   else if(learningData.winRate > 65.0)
   {
      learningData.adjustQuality = "+10";
      learningData.adjustConfluence = "+5";
      learningData.reason += "High win rate - tightening filters for better quality. ";
      Print("🔧 Optimization: High win rate (", learningData.winRate, "%) - Tightening filters");
   }
   
   // 4. Win rate moderate → Slight tightening
   else if(learningData.winRate >= 55.0 && learningData.winRate <= 65.0)
   {
      learningData.adjustQuality = "+5";
      learningData.reason += "Good win rate - slight filter tightening. ";
      Print("🔧 Optimization: Moderate win rate (", learningData.winRate, "%) - Slight tightening");
   }
   
   // 5. Max drawdown too high → Tighten SL
   if(learningData.maxDrawdown > 15.0)
   {
      learningData.adjustSL = "-0.5";
      learningData.adjustRisk = "-0.5";
      learningData.reason += "High drawdown - tightening SL and reducing risk. ";
      Print("🔧 Optimization: High DD (", learningData.maxDrawdown, "%) - Reducing risk");
   }
   
   if(learningData.reason == "")
   {
      learningData.reason = "Performance stable - no adjustments needed.";
      Print("✅ Performance stable - no parameter changes");
   }
}

//===================================================================//
// APPLY OPTIMIZED PARAMETERS
//===================================================================//

void ApplyOptimizedParameters()
{
   // Apply Quality adjustment
   double qualityAdj = StringToDouble(learningData.adjustQuality);
   if(qualityAdj != 0)
   {
      double newQuality = InpMinTrendQuality + qualityAdj;
      newQuality = MathMax(50.0, MathMin(90.0, newQuality));  // Limit 50-90
      
      if(newQuality != InpMinTrendQuality)
      {
         Print("📈 Adjusting MinTrendQuality: ", InpMinTrendQuality, " → ", newQuality);
         // Note: In MQL5 you can't change input parameters at runtime
         // So we store the recommendation for manual application
         learningData.MinTrendQuality = newQuality;
      }
   }
   
   // Apply Confluence adjustment
   double confluenceAdj = StringToDouble(learningData.adjustConfluence);
   if(confluenceAdj != 0)
   {
      double newConfluence = InpMinConfluence + confluenceAdj;
      newConfluence = MathMax(40.0, MathMin(80.0, newConfluence));  // Limit 40-80
      
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
      newSL = MathMax(2.0, MathMin(5.0, newSL));  // Limit 2-5%
      
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
      newTP = MathMax(1.0, MathMin(4.0, newTP));  // Limit 1-4%
      
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
      newRisk = MathMax(0.5, MathMin(5.0, newRisk));  // Limit 0.5-5%
      
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

//===================================================================//
// MAIN LEARNING CYCLE - CALL THIS EVERY 20 TRADES
//===================================================================//

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

//===================================================================//
// INITIALIZE LEARNING SYSTEM - CALL THIS IN OnInit()
//===================================================================//

bool InitLearningSystem()
{
   if(!InpEnableLearning)
   {
      Print("Self-learning disabled in EA settings");
      return true;  // Not an error, just disabled
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

//===================================================================//
// CHECK IF LEARNING CYCLE SHOULD RUN - CALL IN OnTick()
//===================================================================//

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

//===================================================================//
// INTEGRATION INSTRUCTIONS
//===================================================================//

/*
TO INTEGRATE JSON LEARNING:

1. ADD TO OnInit():
   InitLearningSystem();

2. ADD TO OnTick() (at the end):
   CheckLearningTrigger();

3. TESTING:
   - Run EA with InpEnableLearning = false first (baseline)
   - Collect 20+ trades
   - Set InpEnableLearning = true
   - Watch for learning cycle triggers
   - Check JSON file in MQL5/Files/
   - Review recommendations
   - Manually apply suggested parameter changes
   - Run for another 20 trades
   - Verify improvements

4. MANUAL PARAMETER APPLICATION:
   After each learning cycle, the EA will print recommendations.
   You must manually change the EA input parameters to the
   recommended values and restart the EA.
   
   Future enhancement: Implement dynamic parameter adjustment
   (requires more complex coding with global variables or files)

EXPECTED BEHAVIOR:
- First 20 trades: Baseline data collection
- After 20 trades: First learning cycle runs
- JSON file created with recommendations
- Console shows suggested parameter changes
- After 40 trades: Second learning cycle
- Adjustments based on trade 21-40 performance
- Process continues every 20 trades

LEARNING STRATEGY:
- Win rate < 45%: Loosen filters (more trades, find edge)
- Win rate 45-55%: No change (testing current parameters)
- Win rate 55-65%: Tighten slightly (improve quality)
- Win rate > 65%: Tighten more (maximize quality)
- High drawdown: Reduce risk and tighten SL
- Low profit factor: Widen TP
*/
