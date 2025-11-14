//============================= CHUNK 6: TRADING FUNCTIONS ===============//
// ADD THIS AFTER CHUNK 5
//========================================================================//

//========================================================================//
//=================== OPEN POSITION ======================================//
//========================================================================//

bool OpenPosition(ENUM_ORDER_TYPE orderType)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
   
   // Calculate SL/TP
   double sl, tp;
   if(!ComputeSLTPFromPercent(price, orderType, InpStopLossPercent, InpTakeProfitPercent, sl, tp))
   {
      Print("❌ Failed to compute SL/TP");
      return false;
   }
   
   // Calculate lot size
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPerTradePercent / 100.0;
   double slDistance = MathAbs(price - sl);
   double lots = CalculateLotSize(riskMoney, slDistance);
   
   if(lots <= 0)
   {
      Print("❌ Invalid lot size: ", lots);
      return false;
   }
   
   // Validate trade
   if(!ValidateTrade(sl, tp, lots))
   {
      return false;
   }
   
   // Execute
   bool success = false;
   if(orderType == ORDER_TYPE_BUY)
   {
      success = trade.Buy(lots, _Symbol, ask, sl, tp, "MA_Crossover_BUY");
   }
   else
   {
      success = trade.Sell(lots, _Symbol, bid, sl, tp, "MA_Crossover_SELL");
   }
   
   if(success)
   {
      ulong ticket = trade.ResultOrder();
      Print("✅ ", (orderType == ORDER_TYPE_BUY ? "BUY" : "SELL"), 
            " opened: Ticket=", ticket, " Lots=", lots, " SL=", sl, " TP=", tp);
      
      // *** v5.0: Track trade with entry conditions ***
      double quality = 0, confluence = 0, zone = 0, regime = 0, entropy = 0;
      if(InpUsePhysics && InpUseTickPhysicsIndicator)
      {
         double qBuf[1], cBuf[1], zBuf[1], rBuf[1], eBuf[1];
         if(CopyBuffer(indicatorHandle, BUFFER_QUALITY, 0, 1, qBuf) > 0) quality = qBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_CONFLUENCE, 0, 1, cBuf) > 0) confluence = cBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_TRADING_ZONE, 0, 1, zBuf) > 0) zone = zBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_VOL_REGIME, 0, 1, rBuf) > 0) regime = rBuf[0];
         if(CopyBuffer(indicatorHandle, BUFFER_ENTROPY, 0, 1, eBuf) > 0) entropy = eBuf[0];
      }
      
      TrackNewTrade(ticket, quality, confluence, zone, regime, entropy);
   }
   else
   {
      Print("❌ Failed to open position: ", trade.ResultRetcodeDescription());
   }
   
   return success;
}

//========================================================================//
//=================== GET MA CROSSOVER SIGNAL ============================//
//========================================================================//

int GetMACrossoverSignal()
{
   if(!InpUseMAEntry)
      return 0;
   
   double maFastEntry[2], maSlowEntry[2];
   
   if(CopyBuffer(maFastEntry_Handle, 0, 0, 2, maFastEntry) < 2)
      return 0;
   if(CopyBuffer(maSlowEntry_Handle, 0, 0, 2, maSlowEntry) < 2)
      return 0;
   
   // BUY: Fast crosses ABOVE Slow
   if(maFastEntry[0] > maSlowEntry[0] && maFastEntry[1] <= maSlowEntry[1])
   {
      Print("📊 MA Crossover: BULLISH (Fast=", maFastEntry[0], " > Slow=", maSlowEntry[0], ")");
      return 1;
   }
   
   // SELL: Fast crosses BELOW Slow
   if(maFastEntry[0] < maSlowEntry[0] && maFastEntry[1] >= maSlowEntry[1])
   {
      Print("📊 MA Crossover: BEARISH (Fast=", maFastEntry[0], " < Slow=", maSlowEntry[0], ")");
      return -1;
   }
   
   return 0;
}

//========================================================================//
//=================== CHECK EXIT SIGNAL ==================================//
//========================================================================//

bool CheckExitSignal(ENUM_ORDER_TYPE posType)
{
   if(!InpUseMAExit)
      return false;
   
   double maFastExit[2], maSlowExit[2];
   
   if(CopyBuffer(maFastExit_Handle, 0, 0, 2, maFastExit) < 2)
      return false;
   if(CopyBuffer(maSlowExit_Handle, 0, 0, 2, maSlowExit) < 2)
      return false;
   
   if(posType == ORDER_TYPE_BUY)
   {
      // Exit BUY when Fast crosses BELOW Slow
      if(maFastExit[0] < maSlowExit[0] && maFastExit[1] >= maSlowExit[1])
      {
         Print("🚪 Exit signal: BUY position (Fast crossed below Slow)");
         return true;
      }
   }
   else if(posType == ORDER_TYPE_SELL)
   {
      // Exit SELL when Fast crosses ABOVE Slow
      if(maFastExit[0] > maSlowExit[0] && maFastExit[1] <= maSlowExit[1])
      {
         Print("🚪 Exit signal: SELL position (Fast crossed above Slow)");
         return true;
      }
   }
   
   return false;
}

//========================================================================//
//=================== MANAGE POSITIONS ===================================//
//========================================================================//

void ManagePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      
      ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // Check for MA exit signal
      if(CheckExitSignal(orderType))
      {
         if(trade.PositionClose(ticket))
         {
            Print("✅ Position closed on MA exit signal: #", ticket);
            LogTradeClose(ticket, "MA_Exit_Signal");  // *** v5.0: Log the close
         }
         continue;
      }
      
      // Move to breakeven logic
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentPrice = (orderType == ORDER_TYPE_BUY) ? 
         SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double profitPercent = 0;
      if(orderType == ORDER_TYPE_BUY)
         profitPercent = ((currentPrice - openPrice) / openPrice) * 100.0;
      else
         profitPercent = ((openPrice - currentPrice) / openPrice) * 100.0;
      
      if(profitPercent >= InpMoveToBEAtPercent)
      {
         bool needUpdate = false;
         
         if(orderType == ORDER_TYPE_BUY && currentSL < openPrice)
            needUpdate = true;
         else if(orderType == ORDER_TYPE_SELL && currentSL > openPrice)
            needUpdate = true;
         
         if(needUpdate)
         {
            if(trade.PositionModify(ticket, openPrice, PositionGetDouble(POSITION_TP)))
            {
               Print("✅ Moved to breakeven: #", ticket);
            }
         }
      }
   }
}

//========================================================================//
//=================== COUNT POSITIONS ====================================//
//========================================================================//

int CountPositions()
{
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         count++;
   }
   return count;
}

//========================================================================//
//=================== GET DAILY P/L ======================================//
//========================================================================//

double GetDailyPnL()
{
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(dailyStartBalance <= 0) return 0;
   return ((currentBalance - dailyStartBalance) / dailyStartBalance) * 100.0;
}

//========================================================================//
//=================== CHECK DAILY RESET ==================================//
//========================================================================//

void CheckDailyReset()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   MqlDateTime lastCheckStruct;
   TimeToStruct(lastDayCheck, lastCheckStruct);
   
   if(timeStruct.day != lastCheckStruct.day)
   {
      Print("📅 Daily reset - New trading day");
      dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      dailyTradeCount = 0;
      consecutiveLosses = 0;
      dailyPaused = false;
      lastDayCheck = TimeCurrent();
   }
   
   double pnl = GetDailyPnL();
   
   if(InpPauseOnLimits)
   {
      if(pnl >= InpDailyProfitTarget)
      {
         Print("✅ Daily profit target reached: ", pnl, "%");
         dailyPaused = true;
      }
      else if(pnl <= -InpDailyDrawdownLimit)
      {
         Print("⛔ Daily drawdown limit reached: ", pnl, "%");
         dailyPaused = true;
      }
   }
}

//========================================================================//
//=================== CHECK SESSION ======================================//
//========================================================================//

bool IsWithinSession()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   
   string startParts[];
   string endParts[];
   StringSplit(InpSessionStart, ':', startParts);
   StringSplit(InpSessionEnd, ':', endParts);
   
   int startMinutes = (int)StringToInteger(startParts[0]) * 60 + (int)StringToInteger(startParts[1]);
   int endMinutes = (int)StringToInteger(endParts[0]) * 60 + (int)StringToInteger(endParts[1]);
   
   if(startMinutes <= endMinutes)
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
   else
      return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
}

//============================= END OF CHUNK 6 ===========================//
// NEXT: Copy Chunk 7 (CSV init functions and UpdateDisplay)
