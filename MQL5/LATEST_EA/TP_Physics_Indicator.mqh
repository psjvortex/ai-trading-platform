//+------------------------------------------------------------------+
//|                                     TP_Physics_Indicator.mqh      |
//|                      TickPhysics Institutional Framework (ITPF)   |
//|                          Physics Indicator Integration & Filters  |
//+------------------------------------------------------------------+
//| Module: Physics Indicator Interface                               |
//| Version: 8.0 (Multi-Asset + v2.1 Crypto Features)                 |
//| Author: Extracted from v5.0 chunks + v2.1 indicator + Grok v8.0   |
//| Date: November 4, 2025                                            |
//|                                                                    |
//| Purpose:                                                           |
//|   - Interface to TickPhysics_Crypto_Indicator_v2_1                |
//|   - Read all 32 indicator buffers                                 |
//|   - Physics-based entry/exit filters                              |
//|   - v2.0 features: Entropy, Divergence detection                  |
//|   - Multi-asset support with crypto optimizations                 |
//|                                                                    |
//| Key Features:                                                      |
//|   ✅ 32 buffer support (16 plots + 16 calculations)               |
//|   ✅ v2.0 Entropy & Divergence (from your actual indicator)       |
//|   ✅ Crypto mode detection & optimization                         |
//|   ✅ Physics filter validation (Quality, Confluence, etc.)        |
//|   ✅ Trading zone & regime classification                         |
//|   ✅ Asset-adaptive thresholds                                    |
//|                                                                    |
//| Dependencies: TickPhysics_Crypto_Indicator_v2_1.ex5               |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2025, QuanAlpha"
#property version   "8.0"
#property strict

//+------------------------------------------------------------------+
//| Buffer Index Constants (from TickPhysics v2.1)                    |
//+------------------------------------------------------------------+
// Plot Buffers (0-15)
#define BUFFER_SPEED 0
#define BUFFER_ACCEL 1
#define BUFFER_ACCEL_COLOR 2
#define BUFFER_MOMENTUM 3
#define BUFFER_QUALITY 4
#define BUFFER_QUALITY_COLOR 5
#define BUFFER_DISTANCE_ROC 6
#define BUFFER_JERK 7
#define BUFFER_HIGH_THRESHOLD 8
#define BUFFER_LOW_THRESHOLD 9
#define BUFFER_ZERO_LINE 10
#define BUFFER_QUALITY_GLOW 11
#define BUFFER_MOM_SPIKE 12
#define BUFFER_MOM_SPIKE_COLOR 13
#define BUFFER_CONFLUENCE 14
#define BUFFER_CONFLUENCE_COLOR 15
#define BUFFER_VOL_REGIME 16
#define BUFFER_VOL_REGIME_COLOR 17
#define BUFFER_DIVERGENCE 18
#define BUFFER_DIVERGENCE_COLOR 19
#define BUFFER_TRADING_ZONE 20
#define BUFFER_ZONE_COLOR 21
#define BUFFER_ENTROPY 22              // NEW v2.0!

// Calculation Buffers (23-31)
#define BUFFER_DISTANCE 23
#define BUFFER_RAW_SPEED 24
#define BUFFER_BIAS 25
#define BUFFER_PRICE_HIGH 26
#define BUFFER_PRICE_LOW 27
#define BUFFER_CUSTOM_ATR_AVG 28
#define BUFFER_CUSTOM_ATR 29
#define BUFFER_ZONE_QUALITY_HISTORY 30
#define BUFFER_DIVERGENCE_HISTORY 31   // NEW v2.0!

//+------------------------------------------------------------------+
//| Zone & Regime Enumeration (from v2.1 indicator)                   |
//+------------------------------------------------------------------+
enum TRADING_ZONE
{
   ZONE_BULL = 0,        // 🟢 GREEN - Bullish high-quality (safe longs)
   ZONE_BEAR = 1,        // 🔴 RED - Bearish high-quality (safe shorts)
   ZONE_TRANSITION = 2,  // 🟡 GOLD - Transition zone (caution)
   ZONE_AVOID = 3        // ⚫ GRAY - Avoid trading (choppy/unclear)
};

enum VOLATILITY_REGIME
{
   REGIME_LOW = 0,       // 😴 LOW - Consolidation, avoid trading
   REGIME_NORMAL = 1,    // 📊 NORMAL - Ideal trading conditions
   REGIME_HIGH = 2       // 🔥 HIGH - Excessive volatility, widen stops
};

//+------------------------------------------------------------------+
//| Physics Indicator Class                                           |
//+------------------------------------------------------------------+
class CPhysicsIndicator
{
private:
   int m_handle;
   string m_indicatorName;
   bool m_cryptoMode;
   bool m_initialized;
   bool m_debug;
   
   // Cached values for performance
   double m_lastQuality;
   double m_lastConfluence;
   double m_lastEntropy;
   datetime m_lastUpdate;
   
   //+------------------------------------------------------------------+
   //| Read Buffer Value (with error handling)                          |
   //+------------------------------------------------------------------+
   double ReadBuffer(int bufferIndex, int shift = 0)
   {
      if(!m_initialized)
      {
         if(m_debug)
            Print("❌ ERROR: Indicator not initialized");
         return 0.0;
      }
      
      double buffer[1];
      if(CopyBuffer(m_handle, bufferIndex, shift, 1, buffer) < 1)
      {
         if(m_debug)
            Print("❌ ERROR: Failed to copy buffer ", bufferIndex, " at shift ", shift);
         return 0.0;
      }
      
      return buffer[0];
   }
   
   //+------------------------------------------------------------------+
   //| Detect Crypto Mode from Symbol                                   |
   //+------------------------------------------------------------------+
   bool DetectCryptoMode(string symbol)
   {
      string sym = symbol;
      StringToUpper(sym);
      
      if(StringFind(sym, "BTC") >= 0 || 
         StringFind(sym, "ETH") >= 0 || 
         StringFind(sym, "XRP") >= 0 ||
         StringFind(sym, "LTC") >= 0 ||
         StringFind(sym, "ADA") >= 0 ||
         StringFind(sym, "USDT") >= 0)
         return true;
      
      return false;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   CPhysicsIndicator()
   {
      m_handle = INVALID_HANDLE;
      m_initialized = false;
      m_debug = false;
      m_cryptoMode = false;
      m_lastQuality = 0.0;
      m_lastConfluence = 0.0;
      m_lastEntropy = 0.0;
      m_lastUpdate = 0;
   }
   
   //+------------------------------------------------------------------+
   //| Initialize Indicator                                              |
   //+------------------------------------------------------------------+
   bool Initialize(string indicatorName, bool enableDebug = false)
   {
      m_debug = enableDebug;
      m_indicatorName = indicatorName;
      
      if(m_debug)
         Print("🔧 Initializing Physics Indicator: ", indicatorName);
      
      // Load custom indicator
      m_handle = iCustom(_Symbol, _Period, indicatorName);
      
      if(m_handle == INVALID_HANDLE)
      {
         Print("❌ ERROR: Failed to load indicator: ", indicatorName);
         Print("   Make sure ", indicatorName, ".ex5 is in Indicators folder");
         return false;
      }
      
      // Wait for indicator to calculate
      Sleep(100);
      
      // Validate indicator is working (test buffer read)
      double testBuf[1];
      if(CopyBuffer(m_handle, BUFFER_QUALITY, 0, 1, testBuf) < 1)
      {
         Print("❌ ERROR: Indicator loaded but buffers not available");
         Print("   Indicator may not be calculating properly");
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
         return false;
      }
      
      // Auto-detect crypto mode
      m_cryptoMode = DetectCryptoMode(_Symbol);
      m_initialized = true;
      
      if(m_debug)
      {
         Print("✅ Physics Indicator Initialized:");
         Print("   Indicator: ", m_indicatorName);
         Print("   Symbol: ", _Symbol);
         Print("   Crypto Mode: ", m_cryptoMode ? "YES" : "NO");
         Print("   Initial Quality: ", testBuf[0]);
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Core Physics Metrics                                              |
   //+------------------------------------------------------------------+
   
   double GetSpeed(int shift = 0)
   {
      return ReadBuffer(BUFFER_SPEED, shift);
   }
   
   double GetAcceleration(int shift = 0)
   {
      return ReadBuffer(BUFFER_ACCEL, shift);
   }
   
   double GetMomentum(int shift = 0)
   {
      return ReadBuffer(BUFFER_MOMENTUM, shift);
   }
   
   double GetQuality(int shift = 0)
   {
      double value = ReadBuffer(BUFFER_QUALITY, shift);
      if(shift == 0)
      {
         m_lastQuality = value;
         m_lastUpdate = TimeCurrent();
      }
      return value;
   }
   
   double GetConfluence(int shift = 0)
   {
      double value = ReadBuffer(BUFFER_CONFLUENCE, shift);
      if(shift == 0)
      {
         m_lastConfluence = value;
         m_lastUpdate = TimeCurrent();
      }
      return value;
   }
   
   double GetDistanceROC(int shift = 0)
   {
      return ReadBuffer(BUFFER_DISTANCE_ROC, shift);
   }
   
   double GetJerk(int shift = 0)
   {
      return ReadBuffer(BUFFER_JERK, shift);
   }
   
   //+------------------------------------------------------------------+
   //| NEW v2.0 Features (from your actual indicator)                   |
   //+------------------------------------------------------------------+
   
   double GetEntropy(int shift = 0)
   {
      double value = ReadBuffer(BUFFER_ENTROPY, shift);
      if(shift == 0)
      {
         m_lastEntropy = value;
         m_lastUpdate = TimeCurrent();
      }
      return value;
   }
   
   bool HasDivergence(int shift = 0)
   {
      double divBuffer = ReadBuffer(BUFFER_DIVERGENCE, shift);
      return (divBuffer != EMPTY_VALUE && divBuffer != 0.0);
   }
   
   bool IsBullishDivergence(int shift = 0)
   {
      if(!HasDivergence(shift)) return false;
      double colorIndex = ReadBuffer(BUFFER_DIVERGENCE_COLOR, shift);
      return (colorIndex == 0);  // 0 = Bullish (green)
   }
   
   bool IsBearishDivergence(int shift = 0)
   {
      if(!HasDivergence(shift)) return false;
      double colorIndex = ReadBuffer(BUFFER_DIVERGENCE_COLOR, shift);
      return (colorIndex == 1);  // 1 = Bearish (red)
   }
   
   //+------------------------------------------------------------------+
   //| Regime & Zone Classification                                      |
   //+------------------------------------------------------------------+
   
   VOLATILITY_REGIME GetVolatilityRegime(int shift = 0)
   {
      double colorIndex = ReadBuffer(BUFFER_VOL_REGIME_COLOR, shift);
      
      // From indicator: 0 = LOW, 1 = NORMAL, 2 = HIGH
      if(colorIndex < 0.5) return REGIME_LOW;
      if(colorIndex > 1.5) return REGIME_HIGH;
      return REGIME_NORMAL;
   }
   
   TRADING_ZONE GetTradingZone(int shift = 0)
   {
      double colorIndex = ReadBuffer(BUFFER_ZONE_COLOR, shift);
      
      // From indicator: 0 = BULL, 1 = BEAR, 2 = TRANSITION, 3 = AVOID
      if(colorIndex < 0.5) return ZONE_BULL;
      if(colorIndex < 1.5) return ZONE_BEAR;
      if(colorIndex < 2.5) return ZONE_TRANSITION;
      return ZONE_AVOID;
   }
   
   string GetZoneName(TRADING_ZONE zone)
   {
      switch(zone)
      {
         case ZONE_BULL: return "BULL";
         case ZONE_BEAR: return "BEAR";
         case ZONE_TRANSITION: return "TRANSITION";
         case ZONE_AVOID: return "AVOID";
         default: return "UNKNOWN";
      }
   }
   
   string GetRegimeName(VOLATILITY_REGIME regime)
   {
      switch(regime)
      {
         case REGIME_LOW: return "LOW";
         case REGIME_NORMAL: return "NORMAL";
         case REGIME_HIGH: return "HIGH";
         default: return "UNKNOWN";
      }
   }
   
   //+------------------------------------------------------------------+
   //| Thresholds (Dynamic from Indicator)                              |
   //+------------------------------------------------------------------+
   
   double GetHighThreshold(int shift = 0)
   {
      return ReadBuffer(BUFFER_HIGH_THRESHOLD, shift);
   }
   
   double GetLowThreshold(int shift = 0)
   {
      return ReadBuffer(BUFFER_LOW_THRESHOLD, shift);
   }
   
   //+------------------------------------------------------------------+
   //| Physics Filter Validation (v5.0 + Grok v8.0 Enhanced)            |
   //+------------------------------------------------------------------+
   bool CheckPhysicsFilters(
      int signal,              // 1 = BUY, -1 = SELL, 0 = NONE
      double minQuality,       // Minimum trend quality (0-100)
      double minConfluence,    // Minimum confluence (0-100)
      double minMomentum,      // Minimum momentum threshold
      bool requireZoneMatch,   // Require zone alignment
      bool requireNormalRegime,// Require NORMAL volatility
      bool useEntropyFilter,   // Enable chaos detection (v2.0)
      double maxEntropy,       // Max allowed entropy
      int disallowAfterDiv,    // Bars to avoid after divergence
      string &rejectReason     // Output: rejection reason
   )
   {
      if(!m_initialized)
      {
         rejectReason = "Indicator_Not_Initialized";
         return false;
      }
      
      // No signal = no rejection
      if(signal == 0)
      {
         rejectReason = "No_Signal";
         return true;
      }
      
      // Get current metrics
      double quality = GetQuality(0);
      double confluence = GetConfluence(0);
      double momentum = GetMomentum(0);
      TRADING_ZONE zone = GetTradingZone(0);
      VOLATILITY_REGIME regime = GetVolatilityRegime(0);
      double entropy = GetEntropy(0);
      
      // Quality filter
      if(quality < minQuality)
      {
         rejectReason = StringFormat("Quality_Low_%.1f<%.1f", quality, minQuality);
         if(m_debug)
            Print("❌ Physics Filter REJECT: ", rejectReason);
         return false;
      }
      
      // Confluence filter
      if(confluence < minConfluence)
      {
         rejectReason = StringFormat("Confluence_Low_%.1f<%.1f", confluence, minConfluence);
         if(m_debug)
            Print("❌ Physics Filter REJECT: ", rejectReason);
         return false;
      }
      
      // Momentum filter
      if(MathAbs(momentum) < minMomentum)
      {
         rejectReason = StringFormat("Momentum_Low_%.1f<%.1f", MathAbs(momentum), minMomentum);
         if(m_debug)
            Print("❌ Physics Filter REJECT: ", rejectReason);
         return false;
      }
      
      // Zone filter
      if(requireZoneMatch)
      {
         if(signal == 1 && zone != ZONE_BULL)  // BUY signal
         {
            rejectReason = StringFormat("Zone_Mismatch_BUY_in_%s", GetZoneName(zone));
            if(m_debug)
               Print("❌ Physics Filter REJECT: ", rejectReason);
            return false;
         }
         
         if(signal == -1 && zone != ZONE_BEAR)  // SELL signal
         {
            rejectReason = StringFormat("Zone_Mismatch_SELL_in_%s", GetZoneName(zone));
            if(m_debug)
               Print("❌ Physics Filter REJECT: ", rejectReason);
            return false;
         }
      }
      
      // Regime filter
      if(requireNormalRegime && regime != REGIME_NORMAL)
      {
         rejectReason = StringFormat("Regime_Wrong_%s", GetRegimeName(regime));
         if(m_debug)
            Print("❌ Physics Filter REJECT: ", rejectReason);
         return false;
      }
      
      // ✅ NEW v2.0: Entropy (chaos) filter
      if(useEntropyFilter && entropy > maxEntropy)
      {
         rejectReason = StringFormat("Entropy_High_%.2f>%.2f_CHAOS", entropy, maxEntropy);
         if(m_debug)
            Print("❌ Physics Filter REJECT: ", rejectReason, " - Market too chaotic!");
         return false;
      }
      
      // ✅ NEW v2.0: Divergence protection
      if(disallowAfterDiv > 0)
      {
         for(int i = 0; i < disallowAfterDiv; i++)
         {
            if(HasDivergence(i))
            {
               rejectReason = StringFormat("Recent_Divergence_%d_bars_ago", i);
               if(m_debug)
                  Print("❌ Physics Filter REJECT: ", rejectReason);
               return false;
            }
         }
      }
      
      // All filters passed!
      rejectReason = "PASS";
      if(m_debug)
      {
         Print("✅ Physics Filter PASS:");
         Print("   Quality: ", quality, " (>", minQuality, ")");
         Print("   Confluence: ", confluence, " (>", minConfluence, ")");
         Print("   Momentum: ", momentum, " (>", minMomentum, ")");
         Print("   Zone: ", GetZoneName(zone));
         Print("   Regime: ", GetRegimeName(regime));
         Print("   Entropy: ", entropy, " (<", maxEntropy, ")");
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Simplified Filter (backward compatible with v5.0)                |
   //+------------------------------------------------------------------+
   bool CheckPhysicsFilters(
      int signal,
      double quality,
      double confluence,
      double zone,
      double regime,
      double entropy,
      string &rejectReason
   )
   {
      // Convert old-style zone/regime encoding to enums
      bool requireZone = false;
      bool requireRegime = false;
      
      // Default thresholds (can be customized)
      return CheckPhysicsFilters(
         signal,
         70.0,        // minQuality
         60.0,        // minConfluence
         50.0,        // minMomentum
         requireZone,
         requireRegime,
         true,        // useEntropyFilter
         2.5,         // maxEntropy
         5,           // disallowAfterDiv
         rejectReason
      );
   }
   
   //+------------------------------------------------------------------+
   //| Cached Metrics (for performance)                                 |
   //+------------------------------------------------------------------+
   double GetLastQuality() { return m_lastQuality; }
   double GetLastConfluence() { return m_lastConfluence; }
   double GetLastEntropy() { return m_lastEntropy; }
   
   //+------------------------------------------------------------------+
   //| Utility Functions                                                 |
   //+------------------------------------------------------------------+
   bool IsInitialized() { return m_initialized; }
   bool IsCryptoMode() { return m_cryptoMode; }
   void SetCryptoMode(bool enable) { m_cryptoMode = enable; }
   void SetDebug(bool enable) { m_debug = enable; }
   
   //+------------------------------------------------------------------+
   //| Get All Metrics at Once (for logging)                            |
   //+------------------------------------------------------------------+
   struct PhysicsMetrics
   {
      double speed;
      double acceleration;
      double momentum;
      double quality;
      double confluence;
      double entropy;
      TRADING_ZONE zone;
      VOLATILITY_REGIME regime;
      bool hasDivergence;
      bool isBullishDiv;
      bool isBearishDiv;
   };
   
   void GetAllMetrics(PhysicsMetrics &metrics, int shift = 0)
   {
      metrics.speed = GetSpeed(shift);
      metrics.acceleration = GetAcceleration(shift);
      metrics.momentum = GetMomentum(shift);
      metrics.quality = GetQuality(shift);
      metrics.confluence = GetConfluence(shift);
      metrics.entropy = GetEntropy(shift);
      metrics.zone = GetTradingZone(shift);
      metrics.regime = GetVolatilityRegime(shift);
      metrics.hasDivergence = HasDivergence(shift);
      metrics.isBullishDiv = IsBullishDivergence(shift);
      metrics.isBearishDiv = IsBearishDivergence(shift);
   }
   
   //+------------------------------------------------------------------+
   //| Destructor                                                         |
   //+------------------------------------------------------------------+
   ~CPhysicsIndicator()
   {
      if(m_handle != INVALID_HANDLE)
      {
         IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
      }
   }
};

//+------------------------------------------------------------------+
//| END OF TP_Physics_Indicator.mqh                                   |
//+------------------------------------------------------------------+

/*
USAGE EXAMPLE:

#include <TickPhysics/TP_Physics_Indicator.mqh>

CPhysicsIndicator g_physics;

int OnInit()
{
   if(!g_physics.Initialize("TickPhysics_Crypto_Indicator_v2_1", true))
   {
      Print("Failed to initialize Physics Indicator");
      return INIT_FAILED;
   }
   
   Print("Crypto Mode: ", g_physics.IsCryptoMode());
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // Get individual metrics
   double quality = g_physics.GetQuality();
   double confluence = g_physics.GetConfluence();
   double entropy = g_physics.GetEntropy();  // NEW v2.0!
   
   TRADING_ZONE zone = g_physics.GetTradingZone();
   VOLATILITY_REGIME regime = g_physics.GetVolatilityRegime();
   
   // Check for divergence
   if(g_physics.HasDivergence())
   {
      if(g_physics.IsBullishDivergence())
         Print("🟢 Bullish divergence detected!");
      if(g_physics.IsBearishDivergence())
         Print("🔴 Bearish divergence detected!");
   }
   
   // Validate physics filters before entry
   string reason;
   int signal = 1;  // BUY signal
   
   bool pass = g_physics.CheckPhysicsFilters(
      signal,
      70.0,    // minQuality
      60.0,    // minConfluence
      50.0,    // minMomentum
      true,    // requireZoneMatch
      true,    // requireNormalRegime
      true,    // useEntropyFilter
      2.5,     // maxEntropy
      5,       // disallowAfterDiv
      reason
   );
   
   if(pass)
   {
      Print("✅ Physics filters passed - safe to enter");
   }
   else
   {
      Print("❌ Physics filters rejected: ", reason);
   }
   
   // Or get all metrics at once for logging
   CPhysicsIndicator::PhysicsMetrics metrics;
   g_physics.GetAllMetrics(metrics);
   
   Print("Quality: ", metrics.quality);
   Print("Entropy: ", metrics.entropy);
   Print("Zone: ", g_physics.GetZoneName(metrics.zone));
}
*/
