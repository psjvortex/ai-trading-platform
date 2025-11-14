//+------------------------------------------------------------------+
//|                                          TP_JSON_Config.mqh      |
//|                      TickPhysics JSON Configuration Manager      |
//|         Read and write EA configuration from/to JSON file        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "1.0"

//+------------------------------------------------------------------+
//| JSON Configuration Structure                                      |
//+------------------------------------------------------------------+
struct EAConfig
{
   // Risk Management
   double riskPercentPerTrade;
   double maxDailyRisk;
   int maxConcurrentTrades;
   double minRRatio;
   int stopLossPips;
   int takeProfitPips;
   
   // Entry System
   bool usePhysicsEntry;
   bool useMAEntry;
   int maFastPeriod;
   int maSlowPeriod;
   
   // Physics Filters
   bool physicsFiltersEnabled;
   double minQuality;
   double minConfluence;
   bool zoneFilterEnabled;
   bool regimeFilterEnabled;
   
   // Time Filters
   bool timeFilterEnabled;
   int allowedHours[24];
   int allowedHoursCount;
   int blockedHours[24];
   int blockedHoursCount;
   bool dayFilterEnabled;
   int blockedDays[7];
   int blockedDaysCount;
   
   // Monitoring
   int postExitMonitorBars;
   bool enableRealtimeLogging;
   bool enableDebugMode;
   
   // Learning Parameters
   bool autoUpdateEnabled;
   int minTradesForUpdate;
   int updateFrequencyTrades;
};

//+------------------------------------------------------------------+
//| JSON Configuration Manager Class                                 |
//+------------------------------------------------------------------+
class CJSONConfig
{
private:
   string m_configFile;
   bool m_debugMode;
   
   string ReadFileContents(string filename);
   bool WriteFileContents(string filename, string content);
   int ParseIntArray(string jsonStr, string key, int &output[]);
   double ParseDouble(string jsonStr, string key, double defaultValue);
   int ParseInt(string jsonStr, string key, int defaultValue);
   bool ParseBool(string jsonStr, string key, bool defaultValue);
   string ExtractSection(string jsonStr, string sectionName);
   string ExtractArrayString(string jsonStr, string key);

public:
   CJSONConfig();
   ~CJSONConfig();
   
   bool Initialize(string configFile, bool debugMode = false);
   bool LoadConfig(EAConfig &config);
   bool SaveConfig(const EAConfig &config);
   bool ConfigExists();
   void PrintConfig(const EAConfig &config);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CJSONConfig::CJSONConfig()
{
   m_configFile = "";
   m_debugMode = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CJSONConfig::~CJSONConfig()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CJSONConfig::Initialize(string configFile, bool debugMode = false)
{
   m_configFile = configFile;
   m_debugMode = debugMode;
   
   if(m_debugMode)
      Print("📁 JSON Config initialized: ", m_configFile);
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if config file exists                                       |
//+------------------------------------------------------------------+
bool CJSONConfig::ConfigExists()
{
   // Try FILE_COMMON first (for tester agents), then regular path
   int handle = FileOpen(m_configFile, FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      // Fallback to non-common path
      handle = FileOpen(m_configFile, FILE_READ|FILE_TXT);
      if(handle == INVALID_HANDLE)
      {
         int error = GetLastError();
         Print("⚠️  FileOpen failed: Error ", error);
         Print("   Attempted path: ", m_configFile);
         Print("   Common folder: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
         Print("   Data folder: ", TerminalInfoString(TERMINAL_DATA_PATH));
         return false;
      }
   }
   
   FileClose(handle);
   return true;
}

//+------------------------------------------------------------------+
//| Read entire file contents                                         |
//+------------------------------------------------------------------+
string CJSONConfig::ReadFileContents(string filename)
{
   Print("🔍 Attempting to open file: ", filename);
   Print("   Files location: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files");
   
   // Try FILE_COMMON first (for tester agents), then regular path
   int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      // Fallback to non-common path
      handle = FileOpen(filename, FILE_READ|FILE_TXT);
      if(handle == INVALID_HANDLE)
      {
         int error = GetLastError();
         Print("❌ Failed to open file: ", filename, " Error: ", error);
         Print("   Error 5002 = File not found");
         Print("   Error 5004 = Access denied");
         Print("   Try placing file in: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files\\", filename);
         return "";
      }
   }
   
   Print("✅ File opened successfully, handle: ", handle);
   
   string content = "";
   while(!FileIsEnding(handle))
   {
      content += FileReadString(handle) + "\n";
   }
   
   FileClose(handle);
   Print("✅ File read successfully, ", StringLen(content), " characters");
   return content;
}

//+------------------------------------------------------------------+
//| Write entire file contents                                        |
//+------------------------------------------------------------------+
bool CJSONConfig::WriteFileContents(string filename, string content)
{
   int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Failed to create file: ", filename, " Error: ", GetLastError());
      return false;
   }
   
   FileWriteString(handle, content);
   FileClose(handle);
   return true;
}

//+------------------------------------------------------------------+
//| Extract JSON section by name                                      |
//+------------------------------------------------------------------+
string CJSONConfig::ExtractSection(string jsonStr, string sectionName)
{
   string searchKey = "\"" + sectionName + "\":";
   int startPos = StringFind(jsonStr, searchKey);
   if(startPos < 0)
      return "";
   
   startPos = StringFind(jsonStr, "{", startPos);
   if(startPos < 0)
      return "";
   
   int braceCount = 1;
   int pos = startPos + 1;
   
   while(pos < StringLen(jsonStr) && braceCount > 0)
   {
      ushort ch = StringGetCharacter(jsonStr, pos);
      if(ch == '{') braceCount++;
      else if(ch == '}') braceCount--;
      pos++;
   }
   
   return StringSubstr(jsonStr, startPos, pos - startPos);
}

//+------------------------------------------------------------------+
//| Parse double value from JSON                                      |
//+------------------------------------------------------------------+
double CJSONConfig::ParseDouble(string jsonStr, string key, double defaultValue)
{
   string searchKey = "\"" + key + "\":";
   int startPos = StringFind(jsonStr, searchKey);
   if(startPos < 0)
      return defaultValue;
   
   startPos += StringLen(searchKey);
   
   // Skip whitespace
   while(startPos < StringLen(jsonStr) && StringGetCharacter(jsonStr, startPos) == ' ')
      startPos++;
   
   int endPos = startPos;
   while(endPos < StringLen(jsonStr))
   {
      ushort ch = StringGetCharacter(jsonStr, endPos);
      if(ch == ',' || ch == '}' || ch == '\n' || ch == '\r')
         break;
      endPos++;
   }
   
   string valueStr = StringSubstr(jsonStr, startPos, endPos - startPos);
   StringTrimLeft(valueStr);
   StringTrimRight(valueStr);
   
   return StringToDouble(valueStr);
}

//+------------------------------------------------------------------+
//| Parse int value from JSON                                         |
//+------------------------------------------------------------------+
int CJSONConfig::ParseInt(string jsonStr, string key, int defaultValue)
{
   return (int)ParseDouble(jsonStr, key, defaultValue);
}

//+------------------------------------------------------------------+
//| Parse bool value from JSON                                        |
//+------------------------------------------------------------------+
bool CJSONConfig::ParseBool(string jsonStr, string key, bool defaultValue)
{
   string searchKey = "\"" + key + "\":";
   int startPos = StringFind(jsonStr, searchKey);
   if(startPos < 0)
      return defaultValue;
   
   startPos += StringLen(searchKey);
   
   // Skip whitespace
   while(startPos < StringLen(jsonStr) && StringGetCharacter(jsonStr, startPos) == ' ')
      startPos++;
   
   int endPos = startPos;
   while(endPos < StringLen(jsonStr))
   {
      ushort ch = StringGetCharacter(jsonStr, endPos);
      if(ch == ',' || ch == '}' || ch == '\n' || ch == '\r')
         break;
      endPos++;
   }
   
   string valueStr = StringSubstr(jsonStr, startPos, endPos - startPos);
   StringTrimLeft(valueStr);
   StringTrimRight(valueStr);
   
   return (valueStr == "true");
}

//+------------------------------------------------------------------+
//| Extract array string from JSON                                    |
//+------------------------------------------------------------------+
string CJSONConfig::ExtractArrayString(string jsonStr, string key)
{
   string searchKey = "\"" + key + "\":";
   int startPos = StringFind(jsonStr, searchKey);
   if(startPos < 0)
      return "";
   
   startPos = StringFind(jsonStr, "[", startPos);
   if(startPos < 0)
      return "";
   
   int endPos = StringFind(jsonStr, "]", startPos);
   if(endPos < 0)
      return "";
   
   return StringSubstr(jsonStr, startPos + 1, endPos - startPos - 1);
}

//+------------------------------------------------------------------+
//| Parse integer array from JSON                                     |
//+------------------------------------------------------------------+
int CJSONConfig::ParseIntArray(string jsonStr, string key, int &output[])
{
   string arrayStr = ExtractArrayString(jsonStr, key);
   if(arrayStr == "")
      return 0;
   
   // Remove spaces
   StringReplace(arrayStr, " ", "");
   
   // Split by comma
   string parts[];
   ushort separator = StringGetCharacter(",", 0);
   int count = StringSplit(arrayStr, separator, parts);
   
   ArrayResize(output, 0);
   int validCount = 0;
   
   for(int i = 0; i < count; i++)
   {
      StringTrimLeft(parts[i]);
      StringTrimRight(parts[i]);
      
      if(StringLen(parts[i]) > 0)
      {
         ArrayResize(output, validCount + 1);
         output[validCount] = (int)StringToInteger(parts[i]);
         validCount++;
      }
   }
   
   return validCount;
}

//+------------------------------------------------------------------+
//| Load configuration from JSON file                                 |
//+------------------------------------------------------------------+
bool CJSONConfig::LoadConfig(EAConfig &config)
{
   if(!ConfigExists())
   {
      Print("⚠️  Config file not found: ", m_configFile);
      return false;
   }
   
   string jsonContent = ReadFileContents(m_configFile);
   if(jsonContent == "")
   {
      Print("❌ Failed to read config file");
      return false;
   }
   
   if(m_debugMode)
      Print("📖 Reading config from JSON...");
   
   // Parse Risk Management
   string riskSection = ExtractSection(jsonContent, "risk_management");
   config.riskPercentPerTrade = ParseDouble(riskSection, "risk_percent_per_trade", 1.0);
   config.maxDailyRisk = ParseDouble(riskSection, "max_daily_risk", 3.0);
   config.maxConcurrentTrades = ParseInt(riskSection, "max_concurrent_trades", 3);
   config.minRRatio = ParseDouble(riskSection, "min_r_ratio", 1.5);
   config.stopLossPips = ParseInt(riskSection, "stop_loss_pips", 50);
   config.takeProfitPips = ParseInt(riskSection, "take_profit_pips", 100);
   
   // Parse Entry System
   string entrySection = ExtractSection(jsonContent, "entry_system");
   config.usePhysicsEntry = ParseBool(entrySection, "use_physics_entry", false);
   config.useMAEntry = ParseBool(entrySection, "use_ma_entry", true);
   config.maFastPeriod = ParseInt(entrySection, "ma_fast_period", 10);
   config.maSlowPeriod = ParseInt(entrySection, "ma_slow_period", 50);
   
   // Parse Physics Filters
   string physicsSection = ExtractSection(jsonContent, "physics_filters");
   config.physicsFiltersEnabled = ParseBool(physicsSection, "enabled", true);
   config.minQuality = ParseDouble(physicsSection, "min_quality", 70.0);
   config.minConfluence = ParseDouble(physicsSection, "min_confluence", 70.0);
   config.zoneFilterEnabled = ParseBool(physicsSection, "zone_filter_enabled", true);
   config.regimeFilterEnabled = ParseBool(physicsSection, "regime_filter_enabled", true);
   
   // Parse Time Filters
   string timeSection = ExtractSection(jsonContent, "time_filters");
   config.timeFilterEnabled = ParseBool(timeSection, "enabled", true);
   config.allowedHoursCount = ParseIntArray(timeSection, "allowed_hours", config.allowedHours);
   config.blockedHoursCount = ParseIntArray(timeSection, "blocked_hours", config.blockedHours);
   config.dayFilterEnabled = ParseBool(timeSection, "day_filter_enabled", true);
   config.blockedDaysCount = ParseIntArray(timeSection, "blocked_days", config.blockedDays);
   
   // Parse Monitoring
   string monitorSection = ExtractSection(jsonContent, "monitoring");
   config.postExitMonitorBars = ParseInt(monitorSection, "post_exit_monitor_bars", 50);
   config.enableRealtimeLogging = ParseBool(monitorSection, "enable_realtime_logging", true);
   config.enableDebugMode = ParseBool(monitorSection, "enable_debug_mode", true);
   
   // Parse Learning Parameters
   string learningSection = ExtractSection(jsonContent, "learning_parameters");
   config.autoUpdateEnabled = ParseBool(learningSection, "auto_update_enabled", false);
   config.minTradesForUpdate = ParseInt(learningSection, "min_trades_for_update", 100);
   config.updateFrequencyTrades = ParseInt(learningSection, "update_frequency_trades", 50);
   
   if(m_debugMode)
      Print("✅ Config loaded successfully from JSON");
   
   return true;
}

//+------------------------------------------------------------------+
//| Print configuration                                               |
//+------------------------------------------------------------------+
void CJSONConfig::PrintConfig(const EAConfig &config)
{
   Print("═══════════════════════════════════════════════════════");
   Print("📋 CURRENT EA CONFIGURATION (from JSON)");
   Print("═══════════════════════════════════════════════════════");
   
   Print("💰 Risk Management:");
   Print("   Risk/Trade: ", config.riskPercentPerTrade, "%");
   Print("   Max Daily Risk: ", config.maxDailyRisk, "%");
   Print("   Max Concurrent: ", config.maxConcurrentTrades);
   Print("   SL/TP: ", config.stopLossPips, "/", config.takeProfitPips, " pips");
   
   Print("");
   Print("🎯 Physics Filters:");
   Print("   Enabled: ", config.physicsFiltersEnabled ? "YES" : "NO");
   Print("   Min Quality: ", config.minQuality);
   Print("   Min Confluence: ", config.minConfluence);
   Print("   Zone Filter: ", config.zoneFilterEnabled ? "YES" : "NO");
   Print("   Regime Filter: ", config.regimeFilterEnabled ? "YES" : "NO");
   
   Print("");
   Print("🕐 Time Filters:");
   Print("   Enabled: ", config.timeFilterEnabled ? "YES" : "NO");
   
   if(config.allowedHoursCount > 0)
   {
      string hours = "";
      for(int i = 0; i < config.allowedHoursCount; i++)
      {
         if(i > 0) hours += ", ";
         hours += IntegerToString(config.allowedHours[i]);
      }
      Print("   Allowed Hours: ", hours);
   }
   
   if(config.blockedHoursCount > 0)
   {
      string hours = "";
      for(int i = 0; i < config.blockedHoursCount; i++)
      {
         if(i > 0) hours += ", ";
         hours += IntegerToString(config.blockedHours[i]);
      }
      Print("   Blocked Hours: ", hours);
   }
   
   if(config.blockedDaysCount > 0)
   {
      string days = "";
      string dayNames[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
      for(int i = 0; i < config.blockedDaysCount; i++)
      {
         if(i > 0) days += ", ";
         days += dayNames[config.blockedDays[i]];
      }
      Print("   Blocked Days: ", days);
   }
   
   Print("");
   Print("🧠 Learning:");
   Print("   Auto-Update: ", config.autoUpdateEnabled ? "ENABLED" : "DISABLED");
   Print("   Min Trades for Update: ", config.minTradesForUpdate);
   
   Print("═══════════════════════════════════════════════════════");
}
//+------------------------------------------------------------------+
