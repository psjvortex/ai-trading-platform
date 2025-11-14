# URGENT PRE-TRADING CHECKLIST
## ⚠️ CRITICAL ACTIONS REQUIRED BEFORE TRADING

---

## 🔥 IMMEDIATE (Next 30 Minutes)

### **1. RISK SETTINGS - MUST CHANGE!**
```mql5
Current:  input double InpRiskPerTradePercent = 10.0;  ❌ DANGEROUS!
Change to: input double InpRiskPerTradePercent = 2.0;  ✅ SAFE

Location: Line 45 in EA file
```

### **2. DAILY PROTECTION - ENABLE NOW!**
```mql5
Current:  input bool InpPauseOnLimits = false;  ❌ NO PROTECTION!
Change to: input bool InpPauseOnLimits = true;   ✅ PROTECTED

Location: Line 77 in EA file
```

### **3. DEMO TEST - REQUIRED!**
- [ ] Load EA on demo BTCUSD chart
- [ ] Place ONE test trade
- [ ] Verify SL and TP are accepted by broker
- [ ] Check prices make sense (not too tight/too wide)

---

## 📋 PRE-FLIGHT CHECKLIST

### **EA Configuration Verification**
- [ ] Risk per trade: 2% (not 10%!) ✅
- [ ] Daily pause enabled: TRUE ✅
- [ ] Max positions: 1 ✅
- [ ] Max consecutive losses: 3 ✅
- [ ] Stop Loss: 3% of price ✅
- [ ] Take Profit: 2% of price ✅

### **Safety Features**
- [ ] Daily profit target: 5-10% ✅
- [ ] Daily drawdown limit: 5-10% ✅
- [ ] Pause on limits: TRUE ✅
- [ ] Breakeven move: 1.5% ✅

### **System Requirements**
- [ ] Chart timeframe: Your choice (M5/M15/H1)
- [ ] Symbol: BTCUSD or ETHUSD ✅
- [ ] EA loaded and shows green face in corner ✅
- [ ] AutoTrading enabled (top toolbar) ✅

---

## 🎯 FIRST TRADE MONITORING

### **When EA Executes First Trade:**
1. **Check Order Details:**
   - Entry price makes sense
   - SL is 3% below entry (BUY) or above (SELL)
   - TP is 2% above entry (BUY) or below (SELL)
   
2. **Verify in MT5:**
   - Open "Terminal" window (Ctrl+T)
   - Check "Trade" tab shows position
   - Look at "Journal" tab for any errors
   
3. **Monitor CSV Files:**
   - Go to: File → Open Data Folder → MQL5 → Files
   - Look for: TP_Crypto_Signals_Cross_v4_5.csv
   - Look for: TP_Crypto_Trades_Cross_v4_5.csv

---

## ⚠️ WARNING SIGNS - STOP IMMEDIATELY IF:

### **Red Flags:**
- ❌ Order rejected with "invalid stops" error
- ❌ SL/TP prices look wrong (too close or too far)
- ❌ Lot size is 0.00 or extremely large
- ❌ Multiple positions open (should be max 1)
- ❌ EA stops responding after trade
- ❌ Spread > 50 pips at time of entry

### **What to Do:**
1. Disable AutoTrading immediately
2. Close any open positions manually
3. Take screenshots of errors
4. Check broker requirements:
   - Minimum stop distance
   - Minimum lot size
   - Maximum lot size
   - Typical spreads

---

## 📊 CURRENT EA SETTINGS SUMMARY

```mql5
// FROM YOUR v4.5 EA FILE:

RISK MANAGEMENT:
├─ Risk per trade: 10.0% ⚠️ → CHANGE TO 2.0%
├─ Stop Loss: 3.0% of price ✅
├─ Take Profit: 2.0% of price ✅
├─ Breakeven: 1.5% profit ✅
├─ Max positions: 1 ✅
└─ Max consecutive losses: 3 ✅

DAILY GOVERNANCE:
├─ Profit target: 10.0%
├─ Drawdown limit: 10.0%
└─ Pause on limits: FALSE ⚠️ → CHANGE TO TRUE

MA CROSSOVER:
├─ Entry Fast MA: 25
├─ Entry Slow MA: 100
├─ Exit Fast MA: 25
├─ Exit Slow MA: 75
└─ Method: LWMA ✅

PHYSICS FILTERS:
├─ Use Physics: FALSE ✅ (baseline testing)
├─ Use TickPhysics Indicator: FALSE ✅
├─ Entropy Filter: FALSE ✅
└─ Self-Healing: FALSE ✅ (not yet implemented)

TRADING HOURS:
├─ Session Filter: FALSE ✅ (24/7 crypto)
├─ Start: 00:00
└─ End: 23:59
```

---

## 🔍 WHAT TO EXPECT

### **Normal Behavior:**
✅ EA waits for MA crossover
✅ Crossover detected → Instant trade entry
✅ Position opens with SL/TP
✅ Trade managed automatically
✅ CSV logs updated after each bar
✅ Breakeven moves when profit hits 1.5%

### **Entry Frequency:**
- **M5 chart:** 5-15 trades per day (volatile market)
- **M15 chart:** 2-8 trades per day
- **H1 chart:** 1-3 trades per day

### **Win Rate Expectations:**
- **Baseline (no physics):** 50-55%
- **With proper risk:** Sustainable long-term
- **First day:** May be higher or lower (variance)

---

## 📈 PERFORMANCE TRACKING

### **Record These Metrics Daily:**
```
Date: _______________
Starting Balance: $_______
Ending Balance: $_______
Daily P/L: _______%
Trades Taken: _____
Wins: _____
Losses: _____
Win Rate: _______%
Largest Win: $_______
Largest Loss: $_______
Consecutive Losses: _____
```

### **Weekly Review:**
- Total P/L
- Average trade result
- Best/worst day
- Any errors or issues
- Parameter adjustments needed

---

## 🛠️ QUICK FIXES FOR COMMON ISSUES

### **"Invalid Stops" Error:**
```
Problem: Broker rejecting SL/TP
Solutions:
1. Check SYMBOL_TRADE_STOPS_LEVEL
2. Increase InpStopLossPercent to 5%
3. Verify broker allows hedging
4. Try different symbol (EUR/USD vs BTC/USD)
```

### **No Trades Executing:**
```
Problem: EA loaded but no trades
Checks:
1. AutoTrading enabled? (green button)
2. MA crossover occurred? (check chart)
3. Any errors in Journal tab?
4. Daily limits already hit?
5. Consecutive loss limit reached?
```

### **Wrong Lot Size:**
```
Problem: Lot size too small/large
Solutions:
1. Check account balance
2. Verify broker minimum lot
3. Adjust InpRiskPerTradePercent
4. Check GetPointMoneyValue() output
```

---

## 🎓 KEY TAKEAWAYS FROM DEVELOPMENT HISTORY

### **What Was Fixed:**
1. ✅ SL/TP calculation (was using equity, now uses price %)
2. ✅ Crossover detection (now uses buffer [0] and [1])
3. ✅ Point value calculation (3-tier fallback system)
4. ✅ Lot sizing (robust crypto-compatible)

### **What Still Needs Work:**
1. ⚠️ Learning system (JSON optimization not active)
2. ⚠️ Physics filters (indicator not loaded)
3. ⚠️ Spread monitoring (configured but not enforced)
4. ⚠️ Python analysis (not connected)

### **Your Development Journey:**
- 20+ conversations refining the system
- Multiple major bug fixes applied
- Extensive backtest validation
- Ready for live baseline testing

---

## 📞 IF YOU NEED HELP

### **Share These:**
1. Screenshot of EA settings panel
2. Copy/paste Journal tab entries
3. Screenshot of first trade details
4. CSV file contents (first few lines)
5. Account balance before/after

### **Common Questions:**
**Q: Why 2% risk instead of 10%?**
A: 10% = 3 losses = -30% account. Too risky for sustainable trading.

**Q: When to enable physics filters?**
A: After 1 week baseline data, analyze results, then gradually enable.

**Q: How long to test on demo?**
A: Minimum 48 hours or 10+ complete trade cycles.

**Q: What's a good first-day result?**
A: Break-even to +3% is excellent. Don't expect huge wins immediately.

---

## ✅ FINAL GO/NO-GO

### **✅ CLEARED FOR TRADING IF:**
- Risk reduced to 2-3%
- Daily pause enabled
- Demo tested successfully
- All safety features verified
- Monitoring plan in place
- Broker compatibility confirmed

### **❌ DO NOT TRADE IF:**
- Still at 10% risk
- Daily pause disabled
- Haven't tested on demo
- Any "invalid stops" errors
- Unclear about EA operation
- No monitoring plan

---

## 🏁 GOOD LUCK!

You have a solid EA with proper fixes applied. Start conservative, monitor closely, and scale up gradually as you build confidence in the system.

**Remember:**
- Small positions first
- Test everything on demo
- Don't chase losses
- Let the system work
- Analyze results weekly

**Trading starts in hours - take the time to adjust those risk settings NOW! 🚀**

---

*Quick Reference Card - Print or Keep Open While Trading*
*Last Updated: November 2, 2025*
