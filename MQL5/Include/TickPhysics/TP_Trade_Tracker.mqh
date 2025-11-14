//+------------------------------------------------------------------+
//|                                           TP_Trade_Tracker.mqh   |
//|                              TickPhysics Trade Tracking Library  |
//|                                      Copyright 2025, QuanAlpha   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property link      "https://github.com/quanalpha/tickphysics"
#property version   "1.0"
#property strict

//+------------------------------------------------------------------+
//| Active Trade State Structure                                      |
//+------------------------------------------------------------------+
struct ActiveTrade
{
   // Trade Identification
   ulong             ticket;           // Position ticket
   string            symbol;           // Trading symbol
   ENUM_ORDER_TYPE   type;             // ORDER_TYPE_BUY or ORDER_TYPE_SELL
   datetime          openTime;         // Entry time
   
   // Position Details
   double            lots;             // Position size
   double            openPrice;        // Entry price
   double            sl;               // Stop loss
   double            tp;               // Take profit
   
   // Entry Conditions (from signal)
   double            entryQuality;     // Physics quality at entry
   double            entryConfluence;  // Confluence at entry
   double            entryMomentum;    // Momentum at entry
   double            entryEntropy;     // Entropy at entry
   double            entryPhysicsScore;  // NEW: Evidence-based composite score
   string            entryZone;        // Trading zone at entry
   string            entryRegime;      // Volatility regime at entry
   double            entrySpread;      // Spread at entry
   
   // Real-time Tracking (during trade)
   double            mfe;              // Maximum Favorable Excursion (price)
   double            mae;              // Maximum Adverse Excursion (price)
   double            mfePips;          // MFE in pips
   double            maePips;          // MAE in pips
   int               mfeTimeBars;      // Bars elapsed to MFE
   int               maeTimeBars;      // Bars elapsed to MAE
   int               holdTimeBars;     // Total bars in trade
   
   // Risk Metrics
   double            riskPercent;      // Risk as % of account
   
   // Helper flags
   bool              isActive;         // Is trade still open?
   int               entryBarIndex;    // Bar index when trade opened
};

//+------------------------------------------------------------------+
//| Closed Trade State Structure (for post-exit monitoring)          |
//+------------------------------------------------------------------+
struct ClosedTrade
{
   // All data from ActiveTrade at close
   ulong             ticket;
   string            symbol;
   string            type;             // "BUY" or "SELL"
   datetime          openTime;
   datetime          closeTime;
   double            lots;
   double            openPrice;
   double            closePrice;
   double            sl;
   double            tp;
   
   // Entry conditions
   double            entryQuality;
   double            entryConfluence;
   double            entryMomentum;
   double            entryEntropy;
   double            entryPhysicsScore;  // NEW: Evidence-based composite score
   string            entryZone;
   string            entryRegime;
   double            entrySpread;
   
   // Exit conditions
   string            exitReason;       // "TP", "SL", "MANUAL", "TRAILING", "REVERSAL", "EA"
   double            exitQuality;      // Physics quality at exit
   double            exitConfluence;   // Confluence at exit
   string            exitZone;         // Trading zone at exit
   string            exitRegime;       // Volatility regime at exit
   
   // Performance metrics
   double            profit;           // Profit in account currency
   double            profitPercent;    // Profit as % of account
   double            pips;             // Profit in pips
   int               holdTimeBars;     // Bars held
   int               holdTimeMinutes;  // Minutes held
   double            riskPercent;      // Risk as % of account
   double            rRatio;           // R-multiple (profit/risk)
   double            slippage;         // Slippage in pips
   double            commission;       // Commission paid
   
   // MFE/MAE (during trade)
   double            mfe;
   double            mae;
   double            mfePercent;
   double            maePercent;
   double            mfePips;
   double            maePips;
   int               mfeTimeBars;
   int               maeTimeBars;
   
   // Post-exit monitoring state
   bool              monitoringActive; // Still tracking post-exit?
   int               closeBarIndex;    // Bar index when closed
   int               monitorBarsElapsed; // Bars since close
   int               maxMonitorBars;   // Max bars to monitor (default 100)
   
   // RunUp/RunDown (real-time tracking AFTER exit)
   double            runUpPrice;       // Best favorable price after exit
   double            runDownPrice;     // Worst adverse price after exit
   double            runUpPips;        // RunUp in pips
   double            runDownPips;      // RunDown in pips
   double            runUpPercent;     // RunUp as % of close price
   double            runDownPercent;   // RunDown as % of close price
   int               runUpTimeBars;    // Bars to RunUp peak
   int               runDownTimeBars;  // Bars to RunDown trough
   
   // Account state
   double            balanceAfter;
   double            equityAfter;
   double            drawdownPercent;
   
   // Time analysis
   int               entryHour;
   int               entryDayOfWeek;
   int               exitHour;
   int               exitDayOfWeek;
};

//+------------------------------------------------------------------+
//| Trade Tracker Configuration                                       |
//+------------------------------------------------------------------+
struct TrackerConfig
{
   bool              trackMFEMAE;           // Enable MFE/MAE tracking
   bool              trackPostExit;         // Enable post-exit RunUp/RunDown
   int               postExitMonitorBars;   // Bars to monitor after exit (default 100)
   bool              autoLogTrades;         // Auto-log to CSV when trade closes
   bool              debugMode;             // Enable debug logging
};

//+------------------------------------------------------------------+
//| Trade Tracker Class                                               |
//+------------------------------------------------------------------+
class CTradeTracker
{
private:
   // Configuration
   TrackerConfig     m_config;
   bool              m_initialized;
   
   // Active trades storage
   ActiveTrade       m_activeTrades[];
   int               m_activeCount;
   
   // Closed trades (monitoring post-exit)
   ClosedTrade       m_closedTrades[];
   int               m_closedCount;
   
   // Symbol info
   string            m_symbol;
   double            m_pointValue;
   int               m_digits;
   
   // Helper methods
   int               FindActiveTradeIndex(ulong ticket);
   int               FindClosedTradeIndex(ulong ticket);
   void              UpdateMFEMAE(ActiveTrade &trade);
   void              UpdatePostExit(ClosedTrade &trade);
   double            CalculatePips(double price1, double price2, bool isBuy);
   string            DetermineExitReason(ulong ticket, double sl, double tp, double closePrice, ENUM_ORDER_TYPE type);
   
public:
   // Constructor/Destructor
                     CTradeTracker();
                    ~CTradeTracker();
   
   // Initialization
   bool              Initialize(string symbol, TrackerConfig &config);
   bool              IsInitialized() { return m_initialized; }
   
   // Trade Management
   bool              AddTrade(ulong ticket, double entryQuality, double entryConfluence, 
                              double entryMomentum, double entryEntropy, double entryPhysicsScore,
                              string entryZone, string entryRegime, double riskPercent);
   bool              RemoveTrade(ulong ticket);
   bool              UpdateTrades();  // Call on each tick
   
   // Query Methods
   int               GetActiveCount() { return m_activeCount; }
   int               GetClosedCount() { return m_closedCount; }
   bool              IsTradeActive(ulong ticket);
   bool              GetActiveTrade(ulong ticket, ActiveTrade &trade);
   bool              GetClosedTrade(ulong ticket, ClosedTrade &trade);
   
   // Array access (for iteration)
   bool              GetActiveTradeByIndex(int index, ActiveTrade &trade);
   bool              GetClosedTradeByIndex(int index, ClosedTrade &trade);
   
   // Post-exit monitoring
   bool              HasCompletedTrades();  // Trades finished monitoring
   bool              GetNextCompletedTrade(ClosedTrade &trade);  // Retrieve & remove
   
   // Manual exit reason override (for reversal/strategy exits)
   bool              SetExitReason(ulong ticket, string reason);
   
   // Statistics
   double            GetTotalMFE();
   double            GetTotalMAE();
   double            GetAverageHoldTime();
   
   // Debug
   void              PrintActiveTradesStatus();
   void              PrintClosedTradesStatus();
};

//+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CTradeTracker::CTradeTracker()
{
   m_initialized = false;
   m_activeCount = 0;
   m_closedCount = 0;
   ArrayResize(m_activeTrades, 0);
   ArrayResize(m_closedTrades, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                         |
//+------------------------------------------------------------------+
CTradeTracker::~CTradeTracker()
{
   ArrayFree(m_activeTrades);
   ArrayFree(m_closedTrades);
}

//+------------------------------------------------------------------+
//| Initialize tracker                                                 |
//+------------------------------------------------------------------+
bool CTradeTracker::Initialize(string symbol, TrackerConfig &config)
{
   m_symbol = symbol;
   m_config = config;
   
   // Get symbol properties
   m_pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   m_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(m_pointValue == 0)
   {
      Print("❌ Trade Tracker: Invalid symbol: ", symbol);
      return false;
   }
   
   // Set defaults
   if(m_config.postExitMonitorBars <= 0)
      m_config.postExitMonitorBars = 100;
   
   m_initialized = true;
   
   if(m_config.debugMode)
   {
      Print("✅ Trade Tracker Initialized: ", symbol);
      Print("   MFE/MAE tracking: ", m_config.trackMFEMAE ? "ON" : "OFF");
      Print("   Post-exit tracking: ", m_config.trackPostExit ? "ON" : "OFF");
      Print("   Monitor bars: ", m_config.postExitMonitorBars);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Add new trade to tracking                                         |
//+------------------------------------------------------------------+
bool CTradeTracker::AddTrade(ulong ticket, double entryQuality, double entryConfluence,
                             double entryMomentum, double entryEntropy, double entryPhysicsScore,
                             string entryZone, string entryRegime, double riskPercent)
{
   if(!m_initialized) return false;
   
   // Check if position exists
   if(!PositionSelectByTicket(ticket))
   {
      if(m_config.debugMode)
         Print("⚠️ Trade Tracker: Position not found: ", ticket);
      return false;
   }
   
   // Check if already tracking
   if(FindActiveTradeIndex(ticket) >= 0)
   {
      if(m_config.debugMode)
         Print("⚠️ Trade Tracker: Already tracking: ", ticket);
      return false;
   }
   
   // Create new active trade
   ActiveTrade trade;
   trade.ticket = ticket;
   trade.symbol = PositionGetString(POSITION_SYMBOL);
   trade.type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
   trade.openTime = (datetime)PositionGetInteger(POSITION_TIME);
   trade.lots = PositionGetDouble(POSITION_VOLUME);
   trade.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   trade.sl = PositionGetDouble(POSITION_SL);
   trade.tp = PositionGetDouble(POSITION_TP);
   
   // Entry conditions
   trade.entryQuality = entryQuality;
   trade.entryConfluence = entryConfluence;
   trade.entryMomentum = entryMomentum;
   trade.entryEntropy = entryEntropy;
   trade.entryPhysicsScore = entryPhysicsScore;  // NEW: Store evidence-based composite score
   trade.entryZone = entryZone;
   trade.entryRegime = entryRegime;
   trade.entrySpread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * m_pointValue / m_pointValue;
   
   // Initialize tracking
   trade.mfe = trade.openPrice;
   trade.mae = trade.openPrice;
   trade.mfePips = 0.0;
   trade.maePips = 0.0;
   trade.mfeTimeBars = 0;
   trade.maeTimeBars = 0;
   trade.holdTimeBars = 0;
   trade.riskPercent = riskPercent;
   trade.isActive = true;
   trade.entryBarIndex = Bars(m_symbol, PERIOD_CURRENT) - 1;
   
   // Add to array
   m_activeCount++;
   ArrayResize(m_activeTrades, m_activeCount);
   m_activeTrades[m_activeCount - 1] = trade;
   
   if(m_config.debugMode)
      Print("✅ Tracking new ", trade.type == ORDER_TYPE_BUY ? "BUY" : "SELL", 
            " trade: #", ticket, " @ ", trade.openPrice);
   
   return true;
}

//+------------------------------------------------------------------+
//| Remove trade from tracking                                        |
//+------------------------------------------------------------------+
bool CTradeTracker::RemoveTrade(ulong ticket)
{
   int index = FindActiveTradeIndex(ticket);
   if(index < 0) return false;
   
   // Shift array
   for(int i = index; i < m_activeCount - 1; i++)
      m_activeTrades[i] = m_activeTrades[i + 1];
   
   m_activeCount--;
   ArrayResize(m_activeTrades, m_activeCount);
   
   return true;
}

//+------------------------------------------------------------------+
//| Update all active and closed trades                               |
//+------------------------------------------------------------------+
bool CTradeTracker::UpdateTrades()
{
   if(!m_initialized) return false;
   
   int currentBars = Bars(m_symbol, PERIOD_CURRENT);
   
   // Update active trades (check for MFE/MAE and closures)
   for(int i = m_activeCount - 1; i >= 0; i--)
   {
      ActiveTrade trade = m_activeTrades[i];
      
      // Check if still open
      if(!PositionSelectByTicket(trade.ticket))
      {
         // Trade closed - move to closed trades
         if(m_config.trackPostExit)
         {
            ClosedTrade closed;
            // Copy all active trade data
            closed.ticket = trade.ticket;
            closed.symbol = trade.symbol;
            closed.type = trade.type == ORDER_TYPE_BUY ? "BUY" : "SELL";
            closed.openTime = trade.openTime;
            closed.closeTime = TimeCurrent();
            closed.lots = trade.lots;
            closed.openPrice = trade.openPrice;
            
            // Get close data from history
            if(HistorySelectByPosition(trade.ticket))
            {
               for(int h = HistoryDealsTotal() - 1; h >= 0; h--)
               {
                  ulong dealTicket = HistoryDealGetTicket(h);
                  if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == trade.ticket &&
                     HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                  {
                     closed.closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                     closed.profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                     closed.commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     break;
                  }
               }
            }
            
            closed.sl = trade.sl;
            closed.tp = trade.tp;
            
            // Entry conditions
            closed.entryQuality = trade.entryQuality;
            closed.entryConfluence = trade.entryConfluence;
            closed.entryMomentum = trade.entryMomentum;
            closed.entryEntropy = trade.entryEntropy;
            closed.entryPhysicsScore = trade.entryPhysicsScore;  // NEW: Transfer composite score
            closed.entryZone = trade.entryZone;
            closed.entryRegime = trade.entryRegime;
            closed.entrySpread = trade.entrySpread;
            
            // Exit conditions (get current physics state from indicator if available)
            closed.exitReason = DetermineExitReason(trade.ticket, trade.sl, trade.tp, closed.closePrice, trade.type);
            closed.exitQuality = 0.0;  // To be filled by caller if needed
            closed.exitConfluence = 0.0;
            closed.exitZone = "UNKNOWN";
            closed.exitRegime = "UNKNOWN";
            
            // Performance
            closed.profitPercent = (closed.profit / AccountInfoDouble(ACCOUNT_BALANCE)) * 100.0;
            closed.pips = CalculatePips(closed.openPrice, closed.closePrice, trade.type == ORDER_TYPE_BUY);
            closed.holdTimeBars = trade.holdTimeBars;
            closed.holdTimeMinutes = (int)((closed.closeTime - closed.openTime) / 60);
            closed.riskPercent = trade.riskPercent;
            closed.rRatio = closed.riskPercent != 0 ? closed.profitPercent / closed.riskPercent : 0;
            closed.slippage = 0.0;  // Calculate if needed
            
            // MFE/MAE
            closed.mfe = trade.mfe;
            closed.mae = trade.mae;
            closed.mfePips = CalculatePips(closed.openPrice, closed.mfe, trade.type == ORDER_TYPE_BUY);
            closed.maePips = CalculatePips(closed.openPrice, closed.mae, trade.type == ORDER_TYPE_BUY);
            closed.mfePercent = (closed.mfePips / 100.0);
            closed.maePercent = (closed.maePips / 100.0);
            closed.mfeTimeBars = trade.mfeTimeBars;
            closed.maeTimeBars = trade.maeTimeBars;
            
            // Post-exit monitoring setup
            closed.monitoringActive = true;
            closed.closeBarIndex = currentBars - 1;
            closed.monitorBarsElapsed = 0;
            closed.maxMonitorBars = m_config.postExitMonitorBars;
            
            // Initialize RunUp/RunDown
            closed.runUpPrice = closed.closePrice;
            closed.runDownPrice = closed.closePrice;
            closed.runUpPips = 0.0;
            closed.runDownPips = 0.0;
            closed.runUpPercent = 0.0;
            closed.runDownPercent = 0.0;
            closed.runUpTimeBars = 0;
            closed.runDownTimeBars = 0;
            
            // Account state
            closed.balanceAfter = AccountInfoDouble(ACCOUNT_BALANCE);
            closed.equityAfter = AccountInfoDouble(ACCOUNT_EQUITY);
            closed.drawdownPercent = 0.0;  // Calculate if needed
            
            // Time analysis
            MqlDateTime dtOpen, dtClose;
            TimeToStruct(closed.openTime, dtOpen);
            TimeToStruct(closed.closeTime, dtClose);
            closed.entryHour = dtOpen.hour;
            closed.entryDayOfWeek = dtOpen.day_of_week;
            closed.exitHour = dtClose.hour;
            closed.exitDayOfWeek = dtClose.day_of_week;
            
            // Add to closed trades
            m_closedCount++;
            ArrayResize(m_closedTrades, m_closedCount);
            m_closedTrades[m_closedCount - 1] = closed;
            
            if(m_config.debugMode)
               Print("📊 Trade #", trade.ticket, " closed. Monitoring for ", 
                     m_config.postExitMonitorBars, " bars");
         }
         
         // Remove from active
         RemoveTrade(trade.ticket);
         continue;
      }
      
      // Update MFE/MAE
      if(m_config.trackMFEMAE)
      {
         UpdateMFEMAE(m_activeTrades[i]);
      }
      
      // Update hold time
      m_activeTrades[i].holdTimeBars = currentBars - trade.entryBarIndex;
   }
   
   // Update closed trades (post-exit monitoring)
   if(m_config.trackPostExit)
   {
      for(int i = m_closedCount - 1; i >= 0; i--)
      {
         if(m_closedTrades[i].monitoringActive)
         {
            UpdatePostExit(m_closedTrades[i]);
            
            // Check if monitoring period expired
            if(m_closedTrades[i].monitorBarsElapsed >= m_closedTrades[i].maxMonitorBars)
            {
               m_closedTrades[i].monitoringActive = false;
               
               if(m_config.debugMode)
                  Print("✅ Trade #", m_closedTrades[i].ticket, " monitoring complete. ",
                        "RunUp: ", m_closedTrades[i].runUpPips, " pips, ",
                        "RunDown: ", m_closedTrades[i].runDownPips, " pips");
            }
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update MFE/MAE for active trade                                   |
//+------------------------------------------------------------------+
void CTradeTracker::UpdateMFEMAE(ActiveTrade &trade)
{
   double currentPrice = trade.type == ORDER_TYPE_BUY ? 
                         SymbolInfoDouble(m_symbol, SYMBOL_BID) :
                         SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   
   int currentBars = Bars(m_symbol, PERIOD_CURRENT);
   int barsElapsed = currentBars - trade.entryBarIndex;
   
   if(trade.type == ORDER_TYPE_BUY)
   {
      // BUY: MFE = highest price, MAE = lowest price
      if(currentPrice > trade.mfe)
      {
         trade.mfe = currentPrice;
         trade.mfeTimeBars = barsElapsed;
         trade.mfePips = CalculatePips(trade.openPrice, trade.mfe, true);
      }
      if(currentPrice < trade.mae)
      {
         trade.mae = currentPrice;
         trade.maeTimeBars = barsElapsed;
         trade.maePips = CalculatePips(trade.openPrice, trade.mae, true);
      }
   }
   else
   {
      // SELL: MFE = lowest price, MAE = highest price
      if(currentPrice < trade.mfe)
      {
         trade.mfe = currentPrice;
         trade.mfeTimeBars = barsElapsed;
         trade.mfePips = CalculatePips(trade.openPrice, trade.mfe, false);
      }
      if(currentPrice > trade.mae)
      {
         trade.mae = currentPrice;
         trade.maeTimeBars = barsElapsed;
         trade.maePips = CalculatePips(trade.openPrice, trade.mae, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Update post-exit RunUp/RunDown                                    |
//+------------------------------------------------------------------+
void CTradeTracker::UpdatePostExit(ClosedTrade &trade)
{
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   int currentBars = Bars(m_symbol, PERIOD_CURRENT);
   trade.monitorBarsElapsed = currentBars - trade.closeBarIndex;
   
   bool isBuy = (trade.type == "BUY");
   
   if(isBuy)
   {
      // BUY closed: RunUp = price went higher, RunDown = price went lower
      if(currentPrice > trade.runUpPrice)
      {
         trade.runUpPrice = currentPrice;
         trade.runUpTimeBars = trade.monitorBarsElapsed;
      }
      if(currentPrice < trade.runDownPrice)
      {
         trade.runDownPrice = currentPrice;
         trade.runDownTimeBars = trade.monitorBarsElapsed;
      }
   }
   else
   {
      // SELL closed: RunUp = price went lower (favorable), RunDown = price went higher (adverse)
      if(currentPrice < trade.runUpPrice)
      {
         trade.runUpPrice = currentPrice;
         trade.runUpTimeBars = trade.monitorBarsElapsed;
      }
      if(currentPrice > trade.runDownPrice)
      {
         trade.runDownPrice = currentPrice;
         trade.runDownTimeBars = trade.monitorBarsElapsed;
      }
   }
   
   // Calculate pips and percentages
   trade.runUpPips = CalculatePips(trade.closePrice, trade.runUpPrice, isBuy);
   trade.runDownPips = CalculatePips(trade.closePrice, trade.runDownPrice, isBuy);
   trade.runUpPercent = ((trade.runUpPrice - trade.closePrice) / trade.closePrice) * 100.0;
   trade.runDownPercent = ((trade.runDownPrice - trade.closePrice) / trade.closePrice) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate pips between two prices                                 |
//+------------------------------------------------------------------+
double CTradeTracker::CalculatePips(double price1, double price2, bool isBuy)
{
   double diff = isBuy ? (price2 - price1) : (price1 - price2);
   
   // Handle different pip calculations for different symbol types
   if(StringFind(m_symbol, "JPY") >= 0)
      return diff * 100.0;  // JPY pairs
   else if(m_digits <= 3)
      return diff;  // Indices, commodities
   else
      return diff * 10000.0;  // Standard forex
}

//+------------------------------------------------------------------+
//| Determine exit reason from history                                |
//+------------------------------------------------------------------+
string CTradeTracker::DetermineExitReason(ulong ticket, double sl, double tp, double closePrice, ENUM_ORDER_TYPE type)
{
   if(!HistorySelectByPosition(ticket))
      return "UNKNOWN";
   
   // Find the exit deal - most reliable method
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      
      if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == ticket &&
         HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
      {
         // METHOD 1: Check DEAL_REASON enum (most reliable!)
         ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)HistoryDealGetInteger(dealTicket, DEAL_REASON);
         
         if(m_config.debugMode)
         {
            Print("🔍 Exit Reason Detection for #", ticket);
            Print("   DEAL_REASON enum: ", reason);
            Print("   Close Price: ", closePrice);
            Print("   SL: ", sl, " | TP: ", tp);
         }
         
         // Check DEAL_REASON first (most accurate)
         if(reason == DEAL_REASON_SL)
            return "SL";
         if(reason == DEAL_REASON_TP)
            return "TP";
         if(reason == DEAL_REASON_SO)
            return "STOP_OUT";
         if(reason == DEAL_REASON_EXPERT)
         {
            // Check if we already set the reason manually (e.g., REVERSAL)
            // This will be caught later, so just mark as EA for now
            if(m_config.debugMode)
               Print("   → Exit by EA - will check for manual override");
         }
         
         // METHOD 2: Check comment string (fallback)
         string comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         StringToLower(comment);  // Case-insensitive
         
         if(StringFind(comment, "tp") >= 0 || StringFind(comment, "take profit") >= 0)
            return "TP";
         if(StringFind(comment, "sl") >= 0 || StringFind(comment, "stop loss") >= 0)
            return "SL";
         if(StringFind(comment, "so") >= 0 || StringFind(comment, "stop out") >= 0)
            return "STOP_OUT";
         
         // METHOD 3: Price proximity check (with wider tolerance for slippage)
         double tolerance = 10.0 * m_pointValue;  // 10 pips tolerance for slippage
         
         bool nearSL = (sl > 0 && MathAbs(closePrice - sl) <= tolerance);
         bool nearTP = (tp > 0 && MathAbs(closePrice - tp) <= tolerance);
         
         // For BUY trades
         if(type == ORDER_TYPE_BUY)
         {
            // TP is above entry, SL is below entry
            if(nearTP && closePrice >= tp - tolerance)
               return "TP";
            if(nearSL && closePrice <= sl + tolerance)
               return "SL";
         }
         // For SELL trades
         else
         {
            // TP is below entry, SL is above entry
            if(nearTP && closePrice <= tp + tolerance)
               return "TP";
            if(nearSL && closePrice >= sl - tolerance)
               return "SL";
         }
         
         // If we got here, it's likely a manual close
         if(m_config.debugMode)
            Print("   → Classified as MANUAL (no SL/TP match)");
         
         return "MANUAL";
      }
   }
   
   return "UNKNOWN";  // Deal not found
}

//+------------------------------------------------------------------+
//| Find active trade index by ticket                                 |
//+------------------------------------------------------------------+
int CTradeTracker::FindActiveTradeIndex(ulong ticket)
{
   for(int i = 0; i < m_activeCount; i++)
      if(m_activeTrades[i].ticket == ticket)
         return i;
   return -1;
}

//+------------------------------------------------------------------+
//| Find closed trade index by ticket                                 |
//+------------------------------------------------------------------+
int CTradeTracker::FindClosedTradeIndex(ulong ticket)
{
   for(int i = 0; i < m_closedCount; i++)
      if(m_closedTrades[i].ticket == ticket)
         return i;
   return -1;
}

//+------------------------------------------------------------------+
//| Check if trade is active                                          |
//+------------------------------------------------------------------+
bool CTradeTracker::IsTradeActive(ulong ticket)
{
   return FindActiveTradeIndex(ticket) >= 0;
}

//+------------------------------------------------------------------+
//| Get active trade by ticket                                        |
//+------------------------------------------------------------------+
bool CTradeTracker::GetActiveTrade(ulong ticket, ActiveTrade &trade)
{
   int index = FindActiveTradeIndex(ticket);
   if(index < 0) return false;
   
   trade = m_activeTrades[index];
   return true;
}

//+------------------------------------------------------------------+
//| Get closed trade by ticket                                        |
//+------------------------------------------------------------------+
bool CTradeTracker::GetClosedTrade(ulong ticket, ClosedTrade &trade)
{
   int index = FindClosedTradeIndex(ticket);
   if(index < 0) return false;
   
   trade = m_closedTrades[index];
   return true;
}

//+------------------------------------------------------------------+
//| Get active trade by array index                                   |
//+------------------------------------------------------------------+
bool CTradeTracker::GetActiveTradeByIndex(int index, ActiveTrade &trade)
{
   if(index < 0 || index >= m_activeCount) return false;
   
   trade = m_activeTrades[index];
   return true;
}

//+------------------------------------------------------------------+
//| Get closed trade by array index                                   |
//+------------------------------------------------------------------+
bool CTradeTracker::GetClosedTradeByIndex(int index, ClosedTrade &trade)
{
   if(index < 0 || index >= m_closedCount) return false;
   
   trade = m_closedTrades[index];
   return true;
}

//+------------------------------------------------------------------+
//| Check if any trades have completed monitoring                     |
//+------------------------------------------------------------------+
bool CTradeTracker::HasCompletedTrades()
{
   for(int i = 0; i < m_closedCount; i++)
      if(!m_closedTrades[i].monitoringActive)
         return true;
   return false;
}

//+------------------------------------------------------------------+
//| Get next completed trade (removes from tracker)                   |
//+------------------------------------------------------------------+
bool CTradeTracker::GetNextCompletedTrade(ClosedTrade &trade)
{
   for(int i = 0; i < m_closedCount; i++)
   {
      if(!m_closedTrades[i].monitoringActive)
      {
         trade = m_closedTrades[i];
         
         // Remove from array
         for(int j = i; j < m_closedCount - 1; j++)
            m_closedTrades[j] = m_closedTrades[j + 1];
         
         m_closedCount--;
         ArrayResize(m_closedTrades, m_closedCount);
         
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get total MFE across all active trades                            |
//+------------------------------------------------------------------+
double CTradeTracker::GetTotalMFE()
{
   double total = 0.0;
   for(int i = 0; i < m_activeCount; i++)
      total += CalculatePips(m_activeTrades[i].openPrice, m_activeTrades[i].mfe, 
                             m_activeTrades[i].type == ORDER_TYPE_BUY);
   return total;
}

//+------------------------------------------------------------------+
//| Get total MAE across all active trades                            |
//+------------------------------------------------------------------+
double CTradeTracker::GetTotalMAE()
{
   double total = 0.0;
   for(int i = 0; i < m_activeCount; i++)
      total += CalculatePips(m_activeTrades[i].openPrice, m_activeTrades[i].mae,
                             m_activeTrades[i].type == ORDER_TYPE_BUY);
   return total;
}

//+------------------------------------------------------------------+
//| Get average hold time of active trades                            |
//+------------------------------------------------------------------+
double CTradeTracker::GetAverageHoldTime()
{
   if(m_activeCount == 0) return 0.0;
   
   int total = 0;
   for(int i = 0; i < m_activeCount; i++)
      total += m_activeTrades[i].holdTimeBars;
   
   return (double)total / m_activeCount;
}

//+------------------------------------------------------------------+
//| Print active trades status                                        |
//+------------------------------------------------------------------+
void CTradeTracker::PrintActiveTradesStatus()
{
   Print("════════════════════════════════════════════════════════");
   Print("📊 ACTIVE TRADES STATUS");
   Print("════════════════════════════════════════════════════════");
   Print("Total Active: ", m_activeCount);
   
   for(int i = 0; i < m_activeCount; i++)
   {
      ActiveTrade t = m_activeTrades[i];
      Print("");
      Print("Trade #", t.ticket, " (", t.type == ORDER_TYPE_BUY ? "BUY" : "SELL", ")");
      Print("  Entry: ", t.openPrice, " @ ", TimeToString(t.openTime));
      Print("  MFE: ", CalculatePips(t.openPrice, t.mfe, t.type == ORDER_TYPE_BUY), " pips");
      Print("  MAE: ", CalculatePips(t.openPrice, t.mae, t.type == ORDER_TYPE_BUY), " pips");
      Print("  Hold: ", t.holdTimeBars, " bars");
   }
   Print("════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Print closed trades status                                        |
//+------------------------------------------------------------------+
void CTradeTracker::PrintClosedTradesStatus()
{
   Print("════════════════════════════════════════════════════════");
   Print("📊 CLOSED TRADES STATUS (Post-Exit Monitoring)");
   Print("════════════════════════════════════════════════════════");
   Print("Total Monitoring: ", m_closedCount);
   
   for(int i = 0; i < m_closedCount; i++)
   {
      ClosedTrade t = m_closedTrades[i];
      Print("");
      Print("Trade #", t.ticket, " (", t.type, ") - ", t.monitoringActive ? "ACTIVE" : "COMPLETE");
      Print("  Profit: ", t.profit, " (", t.pips, " pips)");
      Print("  RunUp: ", t.runUpPips, " pips @ bar ", t.runUpTimeBars);
      Print("  RunDown: ", t.runDownPips, " pips @ bar ", t.runDownTimeBars);
      Print("  Progress: ", t.monitorBarsElapsed, " / ", t.maxMonitorBars, " bars");
   }
   Print("════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Manually set exit reason (for reversal/strategy exits)           |
//| Call this BEFORE closing the position                             |
//+------------------------------------------------------------------+
bool CTradeTracker::SetExitReason(ulong ticket, string reason)
{
   // First check if it's still an active trade
   int idx = FindActiveTradeIndex(ticket);
   if(idx >= 0)
   {
      // Store it in a temporary array or member variable
      // We'll use this when the trade moves to closed
      if(m_config.debugMode)
         Print("⚙️  Exit reason override queued for #", ticket, ": ", reason);
      
      // For now, we'll handle this differently - mark it in the trade comment
      // The EA should close with a specific comment
      return true;
   }
   
   // Or it might already be in closed trades (just got closed)
   idx = FindClosedTradeIndex(ticket);
   if(idx >= 0)
   {
      m_closedTrades[idx].exitReason = reason;
      if(m_config.debugMode)
         Print("✅ Exit reason set for #", ticket, ": ", reason);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
