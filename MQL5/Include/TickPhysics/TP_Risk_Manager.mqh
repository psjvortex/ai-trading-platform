//+------------------------------------------------------------------+
//|                                          TP_Risk_Manager.mqh      |
//|                      TickPhysics Institutional Framework (ITPF)   |
//|                                 Risk Management & Position Sizing |
//+------------------------------------------------------------------+
//| Module: Risk Manager                                              |
//| Version: 8.0 (Multi-Asset Edition)                                |
//| Author: Extracted from v5.0 chunks + Grok v8.0 enhancements       |
//| Date: November 4, 2025                                            |
//|                                                                    |
//| Purpose:                                                           |
//|   - Calculate position sizes based on risk percentage             |
//|   - Compute SL/TP levels from percentage of price                 |
//|   - Validate trade parameters before execution                    |
//|   - Multi-asset support (Crypto, Forex, Metals, Indices)          |
//|   - Asset-adaptive normalization                                  |
//|                                                                    |
//| Key Features:                                                      |
//|   ✅ 3-tier fallback for point value calculation                  |
//|   ✅ ChatGPT's v4.5 critical fix (% of price, not equity)         |
//|   ✅ Multi-asset ATR normalization (Grok v8.0)                    |
//|   ✅ Spread filtering with configurable limits                    |
//|   ✅ Broker compliance (min stops, lot steps)                     |
//|   ✅ Cached symbol properties for performance                     |
//|                                                                    |
//| Dependencies: None (standalone library)                           |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2025, QuanAlpha"
#property version   "8.0"
#property strict

//+------------------------------------------------------------------+
//| Asset Class Enumeration (Grok v8.0)                               |
//+------------------------------------------------------------------+
enum ASSET_CLASS
{
   ASSET_FOREX,      // EURUSD, GBPUSD (5 digits, 100 ATR ref)
   ASSET_CRYPTO,     // BTCUSD, ETHUSD (2 digits, 1500 ATR ref)
   ASSET_METAL,      // XAUUSD, XAGUSD (2-3 digits, 800 ATR ref)
   ASSET_INDEX,      // NAS100, SPX500 (1-2 digits, 250 ATR ref)
   ASSET_UNKNOWN     // Default
};

//+------------------------------------------------------------------+
//| Cached Symbol Properties Structure                                |
//+------------------------------------------------------------------+
struct SymbolProperties
{
   string name;
   double volumeStep;
   double volumeMin;
   double volumeMax;
   double tickSize;
   double tickValue;
   double point;
   int digits;
   long minStops;
   double contractSize;
   ASSET_CLASS assetClass;
   double atrReference;      // Asset-specific ATR normalization
   datetime lastUpdate;
};

//+------------------------------------------------------------------+
//| Risk Manager Class                                                |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   SymbolProperties m_props;
   bool m_initialized;
   bool m_debug;
   
   //+------------------------------------------------------------------+
   //| Detect Asset Class from Symbol Name                               |
   //+------------------------------------------------------------------+
   ASSET_CLASS DetectAssetClass(string symbol)
   {
      // Crypto detection
      if(StringFind(symbol, "BTC") >= 0 || 
         StringFind(symbol, "ETH") >= 0 || 
         StringFind(symbol, "XRP") >= 0 ||
         StringFind(symbol, "LTC") >= 0 ||
         StringFind(symbol, "ADA") >= 0)
         return ASSET_CRYPTO;
      
      // Metal detection
      if(StringFind(symbol, "XAU") >= 0 || 
         StringFind(symbol, "XAG") >= 0 || 
         StringFind(symbol, "GOLD") >= 0 ||
         StringFind(symbol, "SILVER") >= 0)
         return ASSET_METAL;
      
      // Index detection
      if(StringFind(symbol, "NAS") >= 0 || 
         StringFind(symbol, "SPX") >= 0 || 
         StringFind(symbol, "DOW") >= 0 ||
         StringFind(symbol, "DAX") >= 0 ||
         StringFind(symbol, "US30") >= 0 ||
         StringFind(symbol, "US100") >= 0 ||
         StringFind(symbol, "US500") >= 0)
         return ASSET_INDEX;
      
      // Forex default
      return ASSET_FOREX;
   }
   
   //+------------------------------------------------------------------+
   //| Get ATR Reference by Asset Class (Grok v8.0)                      |
   //+------------------------------------------------------------------+
   double GetATRReference(ASSET_CLASS assetClass)
   {
      switch(assetClass)
      {
         case ASSET_CRYPTO: return 1500.0;  // BTC typical ATR
         case ASSET_METAL:  return 800.0;   // XAUUSD typical ATR
         case ASSET_INDEX:  return 250.0;   // NAS100 typical ATR
         case ASSET_FOREX:  return 100.0;   // EURUSD typical ATR
         default:           return 100.0;   // Safe default
      }
   }
   
   //+------------------------------------------------------------------+
   //| Get Asset Class Name                                              |
   //+------------------------------------------------------------------+
   string GetAssetClassName(ASSET_CLASS assetClass)
   {
      switch(assetClass)
      {
         case ASSET_CRYPTO: return "CRYPTO";
         case ASSET_METAL:  return "METAL";
         case ASSET_INDEX:  return "INDEX";
         case ASSET_FOREX:  return "FOREX";
         default:           return "UNKNOWN";
      }
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   CRiskManager()
   {
      m_initialized = false;
      m_debug = false;
   }
   
   //+------------------------------------------------------------------+
   //| Initialize Risk Manager for Symbol                                |
   //+------------------------------------------------------------------+
   bool Initialize(string symbol, bool enableDebug = false)
   {
      m_debug = enableDebug;
      
      if(m_debug)
         Print("🔧 Initializing Risk Manager for ", symbol);
      
      // Cache all symbol properties
      m_props.name = symbol;
      m_props.volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      m_props.volumeMin = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      m_props.volumeMax = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      m_props.tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      m_props.tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      m_props.point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      m_props.digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      m_props.minStops = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
      m_props.contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      m_props.lastUpdate = TimeCurrent();
      
      // Detect asset class and set ATR reference
      m_props.assetClass = DetectAssetClass(symbol);
      m_props.atrReference = GetATRReference(m_props.assetClass);
      
      // Validation
      if(m_props.point <= 0 || m_props.volumeMin <= 0)
      {
         Print("❌ ERROR: Invalid symbol properties for ", symbol);
         return false;
      }
      
      m_initialized = true;
      
      if(m_debug)
      {
         Print("✅ Risk Manager Initialized:");
         Print("   Symbol: ", m_props.name);
         Print("   Asset Class: ", GetAssetClassName(m_props.assetClass));
         Print("   Digits: ", m_props.digits);
         Print("   Point: ", m_props.point);
         Print("   Tick Size: ", m_props.tickSize);
         Print("   Tick Value: ", m_props.tickValue);
         Print("   ATR Reference: ", m_props.atrReference);
         Print("   Min Lot: ", m_props.volumeMin);
         Print("   Max Lot: ", m_props.volumeMax);
         Print("   Lot Step: ", m_props.volumeStep);
         Print("   Min Stops: ", m_props.minStops, " points");
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Get Point Money Value (v4.5 Critical Fix - 3-tier fallback)       |
   //+------------------------------------------------------------------+
   double GetPointMoneyValue()
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Risk Manager not initialized");
         return 0.0;
      }
      
      // ✅ PRIMARY METHOD: tickValue and tickSize (most accurate)
      if(m_props.tickSize > 0.0 && m_props.tickValue > 0.0)
      {
         double pointValue = m_props.tickValue * (m_props.point / m_props.tickSize);
         if(m_debug)
            Print("💰 Point Value (Primary): ", pointValue, " (tickValue=", m_props.tickValue, " tickSize=", m_props.tickSize, ")");
         return pointValue;
      }
      
      // ✅ FALLBACK 1: contract size * point
      if(m_props.contractSize > 0.0)
      {
         double pointValue = m_props.contractSize * m_props.point;
         if(m_debug)
            Print("💰 Point Value (Fallback 1): ", pointValue, " (contractSize=", m_props.contractSize, ")");
         return pointValue;
      }
      
      // ✅ FALLBACK 2: price * point (last resort)
      double ask = SymbolInfoDouble(m_props.name, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_props.name, SYMBOL_BID);
      double price = (ask > 0 ? ask : (bid > 0 ? bid : 1.0));
      double pointValue = price * m_props.point;
      
      if(m_debug)
         Print("💰 Point Value (Fallback 2 - APPROXIMATION): ", pointValue, " (price=", price, ")");
      
      return pointValue;
   }
   
   //+------------------------------------------------------------------+
   //| Compute SL/TP from Percentage of Price (v4.5 Critical Fix)        |
   //+------------------------------------------------------------------+
   bool ComputeSLTPFromPercent(
      double price,                // Current entry price
      ENUM_ORDER_TYPE orderType,   // ORDER_TYPE_BUY or ORDER_TYPE_SELL
      double stopPercent,          // SL as % of PRICE (not equity!)
      double tpPercent,            // TP as % of PRICE (not equity!)
      double &out_sl,              // Output: SL price level
      double &out_tp               // Output: TP price level
   )
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Risk Manager not initialized");
         return false;
      }
      
      // ✅ v4.5 FIX: Calculate SL/TP as % of PRICE, not equity
      double slDistance = price * (stopPercent / 100.0);
      double tpDistance = price * (tpPercent / 100.0);
      
      // Convert to points
      double slPoints = slDistance / m_props.point;
      double tpPoints = tpDistance / m_props.point;
      
      // ✅ Enforce broker minimum stops level
      if(m_props.minStops > 0)
      {
         double minStopsDouble = (double)m_props.minStops;  // ✅ FIX: Explicit cast to double
         
         if(slPoints < minStopsDouble) 
         {
            if(m_debug)
               Print("⚠️ SL adjusted from ", slPoints, " to min stops ", minStopsDouble);
            slPoints = minStopsDouble;
         }
         if(tpPoints < minStopsDouble) 
         {
            if(m_debug)
               Print("⚠️ TP adjusted from ", tpPoints, " to min stops ", minStopsDouble);
            tpPoints = minStopsDouble;
         }
      }
      
      // Calculate actual price levels
      if(orderType == ORDER_TYPE_BUY)
      {
         out_sl = NormalizeDouble(price - slPoints * m_props.point, m_props.digits);
         out_tp = NormalizeDouble(price + tpPoints * m_props.point, m_props.digits);
      }
      else  // ORDER_TYPE_SELL
      {
         out_sl = NormalizeDouble(price + slPoints * m_props.point, m_props.digits);
         out_tp = NormalizeDouble(price - tpPoints * m_props.point, m_props.digits);
      }
      
      // Validation
      if(out_sl <= 0 || out_tp <= 0)
      {
         Print("❌ ERROR: Invalid SL/TP calculated: SL=", out_sl, " TP=", out_tp);
         return false;
      }
      
      if(m_debug)
      {
         Print("📊 SL/TP Calculated:");
         Print("   Entry Price: ", price);
         Print("   SL Distance: ", slDistance, " (", stopPercent, "% of price)");
         Print("   TP Distance: ", tpDistance, " (", tpPercent, "% of price)");
         Print("   SL Level: ", out_sl);
         Print("   TP Level: ", out_tp);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Calculate Lot Size Based on Risk                                  |
   //+------------------------------------------------------------------+
   double CalculateLotSize(
      double riskMoney,     // Amount of money to risk (e.g., $100)
      double slDistance     // Distance to SL in price units
   )
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Risk Manager not initialized");
         return 0.0;
      }
      
      if(slDistance <= 0)
      {
         Print("❌ ERROR: Invalid SL distance: ", slDistance);
         return 0.0;
      }
      
      if(riskMoney <= 0)
      {
         Print("❌ ERROR: Invalid risk amount: ", riskMoney);
         return 0.0;
      }
      
      // Get point money value
      double pointMoneyValue = GetPointMoneyValue();
      if(pointMoneyValue <= 0)
      {
         Print("❌ ERROR: Cannot calculate lot size - point value is 0");
         return 0.0;
      }
      
      // Convert SL distance to points
      double slDistancePoints = slDistance / m_props.point;
      if(slDistancePoints <= 0)
      {
         Print("❌ ERROR: SL distance in points is 0");
         return 0.0;
      }
      
      // Calculate lot size
      double lots = riskMoney / (slDistancePoints * pointMoneyValue);
      
      // ✅ Apply broker constraints (cached properties)
      lots = MathMax(lots, m_props.volumeMin);
      lots = MathMin(lots, m_props.volumeMax);
      
      // ✅ Round to lot step
      lots = MathFloor(lots / m_props.volumeStep) * m_props.volumeStep;
      lots = NormalizeDouble(lots, 2);
      
      // Final validation
      if(lots < m_props.volumeMin)
         lots = m_props.volumeMin;
      
      if(m_debug)
      {
         Print("💼 Lot Size Calculated:");
         Print("   Risk Money: $", riskMoney);
         Print("   SL Distance: ", slDistance, " (", slDistancePoints, " points)");
         Print("   Point Value: $", pointMoneyValue);
         Print("   Raw Lots: ", riskMoney / (slDistancePoints * pointMoneyValue));
         Print("   Final Lots: ", lots);
      }
      
      return lots;
   }
   
   //+------------------------------------------------------------------+
   //| Validate Trade Parameters                                         |
   //+------------------------------------------------------------------+
   bool ValidateTrade(
      double sl,
      double tp,
      double lots,
      string &errorMessage
   )
   {
      if(!m_initialized)
      {
         errorMessage = "Risk Manager not initialized";
         return false;
      }
      
      // Check SL/TP validity
      if(sl <= 0 || tp <= 0)
      {
         errorMessage = StringFormat("Invalid SL/TP: SL=%.5f TP=%.5f", sl, tp);
         return false;
      }
      
      // Check lot size
      if(lots < m_props.volumeMin)
      {
         errorMessage = StringFormat("Lot size too small: %.2f < %.2f", lots, m_props.volumeMin);
         return false;
      }
      
      if(lots > m_props.volumeMax)
      {
         errorMessage = StringFormat("Lot size too large: %.2f > %.2f", lots, m_props.volumeMax);
         return false;
      }
      
      // Check lot step compliance
      // Normalize both values to account for floating-point precision
      double normalizedLots = NormalizeDouble(lots, 2);
      double normalizedStep = NormalizeDouble(m_props.volumeStep, 2);
      double lotRemainder = NormalizeDouble(MathMod(normalizedLots, normalizedStep), 2);
      
      // Allow for floating-point tolerance based on step size
      double tolerance = normalizedStep * 0.01; // 1% of step size
      if(tolerance < 0.0001) tolerance = 0.0001; // Minimum tolerance
      
      if(lotRemainder > tolerance && (normalizedStep - lotRemainder) > tolerance)
      {
         errorMessage = StringFormat("Lot size not aligned to step: %.2f (step=%.2f, remainder=%.4f)", 
                                     lots, m_props.volumeStep, lotRemainder);
         return false;
      }
      
      errorMessage = "All validations passed";
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Check Spread Filter                                               |
   //+------------------------------------------------------------------+
   bool CheckSpreadFilter(double maxSpreadPoints, double &currentSpread)
   {
      if(!m_initialized)
      {
         Print("❌ ERROR: Risk Manager not initialized");
         return false;
      }
      
      double ask = SymbolInfoDouble(m_props.name, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_props.name, SYMBOL_BID);
      
      currentSpread = (ask - bid) / m_props.point;
      
      if(currentSpread > maxSpreadPoints)
      {
         if(m_debug)
            Print("❌ SPREAD FILTER REJECT: Current=", currentSpread, " points > Max=", maxSpreadPoints);
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Get Symbol Properties (for logging/debugging)                     |
   //+------------------------------------------------------------------+
   void GetSymbolProperties(SymbolProperties &props)
   {
      props = m_props;
   }
   
   //+------------------------------------------------------------------+
   //| Get Asset Class                                                    |
   //+------------------------------------------------------------------+
   ASSET_CLASS GetAssetClass()
   {
      return m_props.assetClass;
   }
   
   //+------------------------------------------------------------------+
   //| Get ATR Reference                                                  |
   //+------------------------------------------------------------------+
   double GetATRReference()
   {
      return m_props.atrReference;
   }
   
   //+------------------------------------------------------------------+
   //| Enable/Disable Debug Output                                       |
   //+------------------------------------------------------------------+
   void SetDebug(bool enable)
   {
      m_debug = enable;
   }
};

//+------------------------------------------------------------------+
//| END OF TP_Risk_Manager.mqh                                        |
//+------------------------------------------------------------------+

/*
USAGE EXAMPLE:

#include <TickPhysics/TP_Risk_Manager.mqh>

CRiskManager g_risk;

int OnInit()
{
   if(!g_risk.Initialize(_Symbol, true))  // Enable debug
   {
      Print("Failed to initialize Risk Manager");
      return INIT_FAILED;
   }
   
   Print("Asset Class: ", g_risk.GetAssetClass());
   Print("ATR Reference: ", g_risk.GetATRReference());
   
   return INIT_SUCCEEDED;
}

void OnTick()
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // Calculate SL/TP
   double sl, tp;
   if(!g_risk.ComputeSLTPFromPercent(price, ORDER_TYPE_BUY, 3.0, 2.0, sl, tp))
   {
      Print("Failed to compute SL/TP");
      return;
   }
   
   // Calculate lot size (risk 2% of $10,000 = $200)
   double equity = 10000.0;
   double riskPercent = 2.0;
   double riskMoney = equity * (riskPercent / 100.0);
   double slDistance = MathAbs(price - sl);
   double lots = g_risk.CalculateLotSize(riskMoney, slDistance);
   
   // Validate
   string error;
   if(!g_risk.ValidateTrade(sl, tp, lots, error))
   {
      Print("Validation failed: ", error);
      return;
   }
   
   // Ready to trade!
   Print("Trade validated: Lots=", lots, " SL=", sl, " TP=", tp);
}
*/
