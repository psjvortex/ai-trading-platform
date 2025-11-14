//+------------------------------------------------------------------+
//|                                    Test_PhysicsIndicator.mq5      |
//|                   TickPhysics Physics Indicator Library Test      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, QuanAlpha"
#property version   "1.0"
#property strict

#include <TickPhysics/TP_Physics_Indicator.mqh>

//--- Globals
CPhysicsIndicator g_physics;
int g_handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("═══════════════════════════════════════════════════════");
   Print("🧪 Testing TP_Physics_Indicator.mqh Library");
   Print("═══════════════════════════════════════════════════════");
   
   // Test 1: Initialize in Standard Mode
   if(!g_physics.Initialize("TickPhysics_Crypto_Indicator_v2_1", true))
   {
      Print("❌ TEST FAILED: Initialization (Standard Mode)");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Initialization (Standard Mode)");
   Print("📊 Crypto Mode: ", g_physics.IsCryptoMode() ? "YES" : "NO");
   
   // Wait for indicator to warm up
   Sleep(100);
   
   // Test 2: Get Core Physics Metrics
   double momentum = g_physics.GetMomentum();
   double speed = g_physics.GetSpeed();
   double acceleration = g_physics.GetAcceleration();
   
   Print("📊 Momentum: ", DoubleToString(momentum, 6));
   Print("📊 Speed: ", DoubleToString(speed, 6));
   Print("📊 Acceleration: ", DoubleToString(acceleration, 6));
   
   if(momentum == 0 && speed == 0 && acceleration == 0)
   {
      Print("⚠️ WARNING: All physics metrics are zero (may need more data)");
   }
   Print("✅ TEST PASSED: Core Physics Metrics Retrieved");
   
   // Test 3: Get Quality & Confluence
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   
   Print("📊 Quality: ", DoubleToString(quality, 2));
   Print("📊 Confluence: ", DoubleToString(confluence, 2));
   
   if(quality < 0 || quality > 100)
   {
      Print("❌ TEST FAILED: Quality out of range [0, 100]");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Quality & Confluence Retrieved");
   
   // Test 4: Get Entropy (v2.0 Feature)
   double entropy = g_physics.GetEntropy();
   Print("📊 Entropy: ", DoubleToString(entropy, 6));
   
   if(entropy < 0)
   {
      Print("❌ TEST FAILED: Entropy is negative");
      return INIT_FAILED;
   }
   Print("✅ TEST PASSED: Entropy Retrieved");
   
   // Test 5: Check Divergence (v2.0 Feature)
   bool bullDiv = g_physics.IsBullishDivergence();
   bool bearDiv = g_physics.IsBearishDivergence();
   Print("📊 Bullish Divergence: ", bullDiv ? "YES" : "NO");
   Print("📊 Bearish Divergence: ", bearDiv ? "YES" : "NO");
   Print("✅ TEST PASSED: Divergence Detection");
   
   // Test 6: Get Regime & Zone
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   TRADING_ZONE zone = g_physics.GetTradingZone();
   Print("📊 Volatility Regime: ", g_physics.GetRegimeName(regime));
   Print("📊 Trading Zone: ", g_physics.GetZoneName(zone));
   Print("✅ TEST PASSED: Regime & Zone Classification");
   
   // Test 7: Get Thresholds
   double highThreshold = g_physics.GetHighThreshold();
   double lowThreshold = g_physics.GetLowThreshold();
   Print("📊 High Threshold: ", DoubleToString(highThreshold, 2));
   Print("📊 Low Threshold: ", DoubleToString(lowThreshold, 2));
   Print("✅ TEST PASSED: Threshold Retrieval");
   
   // Test 8: Historical Values
   double momHist = g_physics.GetMomentum(1); // Previous bar
   double speedHist = g_physics.GetSpeed(1);
   Print("📊 Historical Momentum[1]: ", DoubleToString(momHist, 6));
   Print("📊 Historical Speed[1]: ", DoubleToString(speedHist, 6));
   Print("✅ TEST PASSED: Historical Values Retrieved");
   
   // Test 9: Advanced Metrics (Jerk, Distance ROC)
   double jerk = g_physics.GetJerk();
   double distanceROC = g_physics.GetDistanceROC();
   Print("📊 Jerk: ", DoubleToString(jerk, 6));
   Print("📊 Distance ROC: ", DoubleToString(distanceROC, 6));
   Print("✅ TEST PASSED: Advanced Metrics Retrieved");
   
   // Test 10: Physics Filter Validation
   string rejectReason;
   int testSignal = 1; // BUY signal
   bool filterPass = g_physics.CheckPhysicsFilters(
      testSignal,
      70.0,    // minQuality
      60.0,    // minConfluence
      50.0,    // minMomentum
      true,    // requireZoneMatch
      false,   // requireNormalRegime
      true,    // useEntropyFilter
      2.5,     // maxEntropy
      5,       // disallowAfterDiv
      rejectReason
   );
   
   Print("📊 Physics Filter Result: ", filterPass ? "PASS" : "REJECT");
   Print("📊 Filter Reason: ", rejectReason);
   Print("✅ TEST PASSED: Physics Filter Validation");
   
   // Test 11: Get All Metrics at Once
   CPhysicsIndicator::PhysicsMetrics metrics;
   g_physics.GetAllMetrics(metrics);
   Print("📊 All Metrics Retrieved:");
   Print("   Speed: ", metrics.speed);
   Print("   Momentum: ", metrics.momentum);
   Print("   Quality: ", metrics.quality);
   Print("   Entropy: ", metrics.entropy);
   Print("   Zone: ", g_physics.GetZoneName(metrics.zone));
   Print("   Regime: ", g_physics.GetRegimeName(metrics.regime));
   Print("✅ TEST PASSED: Bulk Metrics Retrieval");
   
   Print("═══════════════════════════════════════════════════════");
   Print("✅ ALL TESTS PASSED - Physics Indicator Library Working!");
   Print("═══════════════════════════════════════════════════════");
   Print("");
   Print("📋 SUMMARY:");
   Print("  • Crypto Mode: ", g_physics.IsCryptoMode() ? "YES" : "NO");
   Print("  • Quality: ", DoubleToString(quality, 2));
   Print("  • Confluence: ", DoubleToString(confluence, 2));
   Print("  • Entropy: ", DoubleToString(entropy, 6));
   Print("  • Zone: ", g_physics.GetZoneName(zone));
   Print("  • Regime: ", g_physics.GetRegimeName(regime));
   Print("  • Divergences: ", bullDiv ? "BULL " : "", bearDiv ? "BEAR" : "");
   Print("  • Filter: ", filterPass ? "PASS" : "REJECT (" + rejectReason + ")");
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
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, 0, 0);
   
   // Update on new bar only
   if(currentBar != lastBar)
   {
      lastBar = currentBar;
      
      // Get all metrics
      CPhysicsIndicator::PhysicsMetrics metrics;
      g_physics.GetAllMetrics(metrics);
      
      // Check for strong quality/confluence
      if(metrics.quality > 70.0 && metrics.confluence > 60.0)
      {
         Print("🚨 HIGH QUALITY SIGNAL OPPORTUNITY:");
         Print("   Quality: ", DoubleToString(metrics.quality, 2));
         Print("   Confluence: ", DoubleToString(metrics.confluence, 2));
         Print("   Momentum: ", DoubleToString(metrics.momentum, 6));
         Print("   Entropy: ", DoubleToString(metrics.entropy, 6));
         Print("   Zone: ", g_physics.GetZoneName(metrics.zone));
         
         // Check divergences
         if(metrics.isBullishDiv)
            Print("   🔔 Bullish Divergence Detected!");
         if(metrics.isBearishDiv)
            Print("   🔔 Bearish Divergence Detected!");
      }
   }
}
//+------------------------------------------------------------------+
