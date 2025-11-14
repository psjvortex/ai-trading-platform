//============================= CHUNK 3: JSON LEARNING ===================//
// ADD THIS AFTER CHUNK 2
//========================================================================//

//========================================================================//
//===================== v5.0: JSON LEARNING FUNCTIONS ====================//
//========================================================================//

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

//+------------------------------------------------------------------+
//| Load learning data from JSON                                     |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Save learning data to JSON                                       |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Analyze performance from CSV                                     |
//+------------------------------------------------------------------+
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
   double totalProfit = 0;
   double totalLoss = 0;
   double sumWins = 0;
   double sumLosses = 0;
   double maxDD = 0;
   double runningBalance = 0;
   double peak = 0;
   
   // Read all trades
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(StringLen(line) < 10) continue;
      
      // Parse CSV line - profit is column 20 (index 19)
      string parts[];
      int count = StringSplit(line, ',', parts);
      
      if(count < 20) continue;
      
      double profit = StringToDouble(parts[19]);
      totalTrades++;
      
      if(profit > 0)
      {
         wins++;
         sumWins += profit;
         totalProfit += profit;
      }
      else if(profit < 0)
      {
         sumLosses += MathAbs(profit);
         totalLoss += profit;
      }
      
      // Track drawdown
      runningBalance += profit;
      if(runningBalance > peak)
         peak = runningBalance;
      
      double dd = peak - runningBalance;
      if(dd > maxDD)
         maxDD = dd;
   }
   
   FileClose(handle);
   
   if(totalTrades < 5)
   {
      Print("Not enough trades for analysis: ", totalTrades);
      return false;
   }
   
   // Calculate metrics
   learningData.totalTrades = totalTrades;
   learningData.winRate = (totalTrades > 0) ? (wins * 100.0 / totalTrades) : 0;
   learningData.profitFactor = (sumLosses > 0) ? (sumWins / sumLosses) : 0;
   learningData.avgWin = (wins > 0) ? (sumWins / wins) : 0;
   learningData.avgLoss = ((totalTrades - wins) > 0) ? (sumLosses / (totalTrades - wins)) : 0;
   learningData.maxDrawdown = maxDD;
   learningData.avgRRatio = (learningData.avgLoss != 0) ? (learningData.avgWin / learningData.avgLoss) : 0;
   
   // Calculate Sharpe (simplified)
   double avgProfit = (totalProfit + totalLoss) / totalTrades;
   learningData.sharpeRatio = (avgProfit > 0 && totalTrades > 1) ? (avgProfit / MathSqrt(totalTrades)) : 0;
   
   Print("📊 Performance Analysis:");
   Print("   Total Trades: ", totalTrades);
   Print("   Win Rate: ", learningData.winRate, "%");
   Print("   Profit Factor: ", learningData.profitFactor);
   Print("   Avg Win: ", learningData.avgWin);
   Print("   Avg Loss: ", learningData.avgLoss);
   Print("   Max DD: ", learningData.maxDrawdown);
   Print("   R:R Ratio: ", learningData.avgRRatio);
   
   return true;
}

//============================= END OF CHUNK 3 ===========================//
// NEXT: Copy Chunk 4 (More JSON functions + logging functions)
