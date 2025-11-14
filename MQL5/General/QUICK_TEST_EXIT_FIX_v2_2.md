# QUICK TEST GUIDE - v2.2 Continuous Exit Logic

## What Was Fixed
Changed the exit logic from **crossover-only** to **continuous check**:
- **Before**: Only exited on the exact bar where Fast MA crossed below/above Slow Exit MA
- **After**: Exits **every bar** where Fast MA is below (long) or above (short) the Slow Exit MA

## Why This Matters
Your screenshot showed a long position with Fast MA clearly below Slow Exit MA, but the trade was still open. This is because the crossover bar was missed. The new logic fixes this—trades will now exit as soon as the condition is met.

---

## Quick Test Procedure

### 1. Compile the EA
1. Open **MetaEditor** (F4 from MT5)
2. Open `TickPhysics_Crypto_SelfHealing_Crossover_EA_v2_2`
3. Press **F7** to compile
4. Verify "0 error(s), 0 warning(s)" in the log

### 2. Run Visual Backtest
1. Open **Strategy Tester** (Ctrl+R in MT5)
2. Select the EA: `TickPhysics_Crypto_SelfHealing_Crossover_EA_v2_2`
3. Symbol: **ETHUSD** (or your preferred crypto pair)
4. Timeframe: **M5** (5-minute)
5. Period: Recent data (e.g., last month)
6. **Enable visualization** (checkbox at bottom)
7. Make sure these inputs are set:
   - `InpUseMAExit = true` ✅
   - `InpFastExitMAPeriod = 10`
   - `InpSlowExitMAPeriod = 30`
8. Click **Start**

### 3. What to Watch For

#### During Entry
- Wait for a trade to open (you'll see the entry MAs cross)
- Note the position type (long or short)

#### During Exit - CRITICAL TEST ✅
**For LONG positions:**
1. Watch the **blue MA (Fast Exit, period 10)**
2. Watch the **white MA (Slow Exit, period 30)**
3. When the blue MA drops below the white MA:
   - ✅ **Trade should close immediately** (same bar or next tick)
   - ❌ **NOT** wait for price action or further signals

**For SHORT positions:**
1. Watch the **blue MA (Fast Exit, period 10)**
2. Watch the **white MA (Slow Exit, period 30)**
3. When the blue MA rises above the white MA:
   - ✅ **Trade should close immediately** (same bar or next tick)
   - ❌ **NOT** wait for price action or further signals

### 4. Check the Expert Log
Look for these log entries (Experts tab at bottom of MT5):

```
DEBUG Exit MAs: Fast[0]=1850.23 Fast[1]=1852.45 | Slow[0]=1865.78 Slow[1]=1864.32
⚪ EXIT LONG SIGNAL: Fast Exit MA (1850.23) < Slow Exit MA (1865.78)
```

- The debug line prints every bar showing current MA values
- The exit signal line should appear **as soon as** Fast < Slow (long) or Fast > Slow (short)

---

## Expected Results

### Before the Fix (Old Behavior)
- Trade only exits if crossover happens on a specific bar
- If crossover is "missed," trade stays open indefinitely
- Your screenshot scenario: Long open with Fast < Slow ❌

### After the Fix (New Behavior)
- Trade exits **every bar** where exit condition is true
- No missed exits—if Fast < Slow, long exits immediately ✅
- Your screenshot scenario: Long would close as soon as Fast < Slow ✅

---

## Screenshots to Capture

1. **Before Exit**: Trade open, Fast MA still above Slow Exit MA
2. **At Exit Condition**: Moment when Fast crosses below Slow (or is already below)
3. **After Exit**: Trade closed, verify in Terminal and on chart

---

## If Exit Still Doesn't Work

1. **Verify `InpUseMAExit = true`** in EA inputs
2. **Check Expert log** for debug MA values—are they being printed?
3. **Verify MA overlay** on chart—are both Fast and Slow Exit MAs visible?
4. **Check position list**—is there actually an open position?
5. **Share screenshot** with:
   - Chart showing MAs and open position
   - Expert log showing debug values
   - EA inputs panel showing settings

---

## Trade-Off Reminder

### ⚠️ This may exit trades earlier than before
- The continuous check is **more aggressive** in exiting
- You may see more frequent exits if MAs are choppy
- This is **correct behavior**—it protects you from adverse moves

### If you want to hold trades longer:
- Increase `InpSlowExitMAPeriod` (e.g., from 30 to 50)
- Use a wider MA spread (e.g., Fast=20, Slow=50)
- Or disable MA exit and use only SL/TP

---

## Success Criteria ✅

- [ ] EA compiles without errors
- [ ] Visual backtest runs successfully  
- [ ] MA lines display on chart (blue Fast, white Slow)
- [ ] Long positions exit immediately when Fast < Slow
- [ ] Short positions exit immediately when Fast > Slow
- [ ] Expert log shows exit signals with MA values
- [ ] No "hung" trades that stay open despite exit condition being met

---

**Ready to test!** 🚀

Once you verify the fix works, you can use this version for live trading with confidence that trades will exit when the MA condition is met.
