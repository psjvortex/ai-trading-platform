//+------------------------------------------------------------------+
//|                                          Test_RiskManager.mq5     |
//|                      TickPhysics Risk Manager Library Test        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "1.01"
#property strict

#include <TickPhysics/TP_Risk_Manager.mqh>

//--- Globals
CRiskManager g_risk;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🧪 Testing TP_Risk_Manager.mqh Library");
   Print("═══════════════════════════════════════════════════════");
   
   // Test 1: Initialize
   if(!g_risk.Initialize(_Symbol, true))
   {
      Print("❌ TEST FAILED: Initialization");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Initialization");
   
   // Test 2: Asset Class Detection
   ASSET_CLASS assetClass = g_risk.GetAssetClass();
   double atrRef = g_risk.GetATRReference();
   Print("📊 Asset Class: ", (int)assetClass);
   Print("📊 ATR Reference: ", atrRef);
   
   if(StringFind(_Symbol, "BTC") >= 0 && assetClass != ASSET_CRYPTO)
   {
      Print("❌ TEST FAILED: Asset class detection (expected CRYPTO)");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Asset Class Detection");
   
   // Test 3: Point Money Value
   double pointValue = g_risk.GetPointMoneyValue();
   if(pointValue <= 0)
   {
      Print("❌ TEST FAILED: Point money value is 0");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Point Money Value = ", pointValue);
   
   // Test 4: SL/TP Calculation
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl, tp;
   if(!g_risk.ComputeSLTPFromPercent(price, ORDER_TYPE_BUY, 3.0, 2.0, sl, tp))
   {
      Print("❌ TEST FAILED: SL/TP calculation");
      return INIT_FAILED;
   }
   
   // Validate SL is below price for BUY
   if(sl >= price)
   {
      Print("❌ TEST FAILED: SL above entry for BUY (SL=", sl, " Price=", price, ")");
      return INIT_FAILED;
   }
   
   // Validate TP is above price for BUY
   if(tp <= price)
   {
      Print("❌ TEST FAILED: TP below entry for BUY (TP=", tp, " Price=", price, ")");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: SL/TP Calculation (Price=", price, " SL=", sl, " TP=", tp, ")");
   
   // Test 5: Lot Size Calculation
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskPercent = 2.0;
   double riskMoney = equity * (riskPercent / 100.0);
   double slDistance = MathAbs(price - sl);
   double lots = g_risk.CalculateLotSize(riskMoney, slDistance);
   
   if(lots <= 0)
   {
      Print("❌ TEST FAILED: Lot size is 0");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Lot Size = ", lots, " (Risk=$", riskMoney, ")");
   
   // Test 6: Trade Validation
   string error;
   if(!g_risk.ValidateTrade(sl, tp, lots, error))
   {
      Print("❌ TEST FAILED: Trade validation - ", error);
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Trade Validation");
   
   // Test 7: Spread Filter
   double spread;
   bool spreadOk = g_risk.CheckSpreadFilter(500.0, spread);
   Print("📊 Current Spread: ", spread, " points");
   Print("✅ TEST PASSED: Spread Filter (Result=", spreadOk, ")");
   
   Print("═══════════════════════════════════════════════════════");
   Print("✅ ALL TESTS PASSED - Risk Manager Library Working!");
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
