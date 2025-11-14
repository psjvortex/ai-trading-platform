//============================= CHUNK 2: CORE FUNCTIONS ==================//
// ADD THIS AFTER CHUNK 1
//========================================================================//

//============================= ROBUST POINT VALUE =======================//
double GetPointMoneyValue()
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Primary method: tickValue and tickSize
   if(tickSize > 0.0 && tickValue > 0.0)
   {
      return tickValue * (point / tickSize);
   }
   
   // Fallback 1: contract size * point
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(contractSize > 0.0 && point > 0.0)
   {
      return contractSize * point;
   }
   
   // Fallback 2: price * point (last resort)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = (ask > 0 ? ask : (bid > 0 ? bid : 1.0));
   double approx = price * point;
   if(approx > 0.0) return approx;
   
   // Last resort: failure
   Print("ERROR: GetPointMoneyValue() - Cannot determine point value!");
   return 0.0;
}

//============================= FIXED SL/TP CALCULATION ==================//
bool ComputeSLTPFromPercent(double price, ENUM_ORDER_TYPE orderType, 
                           double stopPercent, double tpPercent,
                           double &out_sl, double &out_tp)
{
   // Use % of PRICE, not equity!
   double slDistance = price * stopPercent / 100.0;
   double tpDistance = price * tpPercent / 100.0;
   
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   // Calculate SL/TP prices
   if(orderType == ORDER_TYPE_BUY)
   {
      out_sl = NormalizeDouble(price - slDistance, digits);
      out_tp = NormalizeDouble(price + tpDistance, digits);
   }
   else
   {
      out_sl = NormalizeDouble(price + slDistance, digits);
      out_tp = NormalizeDouble(price - tpDistance, digits);
   }
   
   // Validate
   if(out_sl <= 0 || out_tp <= 0)
   {
      Print("ERROR: Invalid SL/TP: sl=", out_sl, " tp=", out_tp);
      return false;
   }
   
   return true;
}

//============================= LOT SIZE CALCULATION =====================//
double CalculateLotSize(double riskMoney, double slDistance)
{
   if(slDistance <= 0)
   {
      Print("ERROR: Invalid SL distance: ", slDistance);
      return 0;
   }
   
   double pointMoneyValue = GetPointMoneyValue();
   if(pointMoneyValue <= 0)
   {
      Print("ERROR: Cannot calculate lot size - point value is 0");
      return 0;
   }
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0)
   {
      Print("ERROR: Invalid point size");
      return 0;
   }
   
   double slDistancePoints = slDistance / point;
   if(slDistancePoints <= 0)
   {
      Print("ERROR: SL distance in points is 0");
      return 0;
   }
   
   double lots = riskMoney / (slDistancePoints * pointMoneyValue);
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = NormalizeDouble(lots, 2);
   
   if(lots < minLot)
      lots = minLot;
   
   return lots;
}

//========================================================================//
//========================= v5.0: PHYSICS FILTERS ========================//
//========================================================================//
// *** CRITICAL FIX v5.0: This function now ACTUALLY USED for entries ***
//========================================================================//

bool CheckPhysicsFilters(int signal, double quality, double confluence, 
                        double zone, double regime, double entropy,
                        string &rejectReason)
{
   // If physics not enabled, pass all trades
   if(!InpUsePhysics || !InpUseTickPhysicsIndicator)
   {
      rejectReason = "PhysicsDisabled";
      return true;
   }
   
   // Quality filter
   if(quality < InpMinTrendQuality)
   {
      rejectReason = StringFormat("QualityLow_%.1f<%.1f", quality, InpMinTrendQuality);
      Print("❌ Physics Filter REJECT: Quality too low: ", quality, " < ", InpMinTrendQuality);
      return false;
   }
   
   // Confluence filter
   if(confluence < InpMinConfluence)
   {
      rejectReason = StringFormat("ConfluenceLow_%.1f<%.1f", confluence, InpMinConfluence);
      Print("❌ Physics Filter REJECT: Confluence too low: ", confluence, " < ", InpMinConfluence);
      return false;
   }
   
   // Trading Zone filter
   if(InpRequireGreenZone)
   {
      // Zone encoding from indicator:
      // 0 = GREEN (bull high-quality)
      // 1 = RED (bear high-quality)
      // 2 = GOLD (transition)
      // 3 = GRAY (avoid)
      
      if(signal == 1)  // BUY signal
      {
         if(zone != 0)  // Require GREEN zone
         {
            string zoneStr = (zone == 1) ? "RED" : (zone == 2) ? "GOLD" : "GRAY";
            rejectReason = StringFormat("ZoneMismatch_BUY_in_%s", zoneStr);
            Print("❌ Physics Filter REJECT: BUY signal but not in GREEN zone. Zone=", zoneStr);
            return false;
         }
      }
      else if(signal == -1)  // SELL signal
      {
         if(zone != 1)  // Require RED zone
         {
            string zoneStr = (zone == 0) ? "GREEN" : (zone == 2) ? "GOLD" : "GRAY";
            rejectReason = StringFormat("ZoneMismatch_SELL_in_%s", zoneStr);
            Print("❌ Physics Filter REJECT: SELL signal but not in RED zone. Zone=", zoneStr);
            return false;
         }
      }
   }
   
   // Volatility Regime filter
   if(InpTradeOnlyNormalRegime)
   {
      // Regime encoding from indicator:
      // 0 = LOW volatility
      // 1 = NORMAL volatility
      // 2 = HIGH volatility
      
      if(regime != 1)
      {
         string regimeStr = (regime == 0) ? "LOW" : "HIGH";
         rejectReason = StringFormat("RegimeWrong_%s", regimeStr);
         Print("❌ Physics Filter REJECT: Not in NORMAL regime. Regime=", regimeStr);
         return false;
      }
   }
   
   // Entropy (chaos) filter
   if(InpUseEntropyFilter)
   {
      if(entropy > InpMaxEntropy)
      {
         rejectReason = StringFormat("EntropyChaotic_%.2f>%.2f", entropy, InpMaxEntropy);
         Print("❌ Physics Filter REJECT: Entropy too high (market chaos): ", entropy, " > ", InpMaxEntropy);
         return false;
      }
   }
   
   // All filters passed!
   rejectReason = "PASS";
   Print("✅ Physics Filter PASS: Quality=", quality, " Confluence=", confluence, 
         " Zone=", zone, " Regime=", regime, " Entropy=", entropy);
   return true;
}

//========================================================================//
//========================= v5.0: SPREAD FILTER ==========================//
//========================================================================//

bool CheckSpreadFilter(double &spreadValue)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   if(point <= 0) return false;
   
   spreadValue = (ask - bid) / point;
   
   if(spreadValue > InpMaxSpread)
   {
      Print("❌ SPREAD FILTER REJECT: Spread=", spreadValue, " points > Max=", InpMaxSpread);
      return false;
   }
   
   return true;
}

//============================= END OF CHUNK 2 ===========================//
// NEXT: Copy Chunk 3 (JSON learning functions)
