# 🎨 MA Color Setup - Quick Reference

## After EA Starts, Follow These Steps:

### 1️⃣ Check the Experts Log
Look for these messages:
```
✅ Entry MA lines added: Fast(25), Slow(100)
   💡 TIP: Right-click each MA line → Properties → Set colors:
      Fast(25) = Blue, Slow(100) = Yellow
✅ Exit MA line added: (50)
   💡 TIP: Right-click MA line → Properties → Set color to White
```

### 2️⃣ Set Colors for Each MA

**Fast Entry MA (25 periods):**
1. Right-click the MA(25) line on chart
2. Select "Properties" or "Parameters"
3. Click "Colors" tab
4. Change color to **Blue** (clrDodgerBlue or any blue you prefer)
5. Click OK

**Slow Entry MA (100 periods):**
1. Right-click the MA(100) line on chart
2. Select "Properties"
3. Click "Colors" tab
4. Change color to **Yellow**
5. Click OK

**Exit MA (50 periods):**
1. Right-click the MA(50) line on chart
2. Select "Properties"
3. Click "Colors" tab
4. Change color to **White**
5. Click OK

### 3️⃣ Optional: Adjust Line Width
In the same Properties dialog:
- Go to "Parameters" or "Style" tab
- Adjust line width (1-5)
- Change line style if desired
- Click OK

### 4️⃣ Save Template (Recommended)
To preserve your color settings:
1. Right-click anywhere on chart
2. Select "Template" → "Save Template"
3. Give it a name (e.g., "TP_Crypto_QA")
4. Next time, just load this template!

---

## Visual Result

After setup, your chart will show:

```
Price Chart:
  🔵 Blue line   = Fast Entry MA (25)  - Bullish when above yellow
  🟡 Yellow line = Slow Entry MA (100) - Main trend reference
  ⚪ White line  = Exit MA (50)        - Exit trigger

Comment Box (Top-Left):
  Shows real-time MA crossover status
  Color-coded indicators (🔵🔴🟢⚪)
  All settings visible at a glance
```

---

## Troubleshooting

**Q: I don't see any MA lines**
- Check EA inputs: `InpShowMALines = true`
- Check EA inputs: `InpUseMAEntry = true` and `InpUseMAExit = true`
- Restart EA if needed

**Q: Colors didn't save**
- Colors are chart-specific, not EA-specific
- Save as a chart template to preserve settings
- When you open a new chart, apply the template

**Q: Which line is which?**
- Look at the indicator name in the Indicators list (Ctrl+I)
- Names show period: "iMA(BTCUSD, M5, 25)" = 25-period MA
- Or check the Experts log tips when EA starts

**Q: Can I use different colors?**
- Yes! Use any colors you prefer
- Blue/Yellow/White are just recommendations
- Choose colors that contrast with your chart background

---

## Why Manual Setup?

MT5 prevents EAs from changing indicator colors programmatically for security reasons. This protects users from malicious code altering chart appearance without permission.

**Good News:**
- Setup is one-time per chart template
- Takes less than 1 minute
- Colors persist across sessions
- Can be saved and shared via templates

---

**That's it! Enjoy your color-coded MA visual QA system!** 🎨✅
