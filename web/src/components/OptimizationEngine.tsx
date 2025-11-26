import { useState, useEffect } from 'react';
import { Trade } from '../types';
import { optimizeStrategy, findBestConfiguration, OptimizationFilter } from '../lib/analytics';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Check, Copy, Sliders, Plus, Trash2, Wand2, TrendingUp } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface OptimizationEngineProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

export const AVAILABLE_METRICS: { key: keyof Trade; label: string }[] = [
  // Entry Signals
  { key: 'Signal_Entry_Quality', label: 'Entry Quality' },
  { key: 'Signal_Entry_Confluence', label: 'Entry Confluence' },
  { key: 'Signal_Entry_Momentum', label: 'Entry Momentum' },
  { key: 'Signal_Entry_Speed', label: 'Entry Speed' },
  { key: 'Signal_Entry_Acceleration', label: 'Entry Acceleration' },
  { key: 'Signal_Entry_Jerk', label: 'Entry Jerk' },
  { key: 'Signal_Entry_PhysicsScore', label: 'Entry Physics Score' },
  { key: 'Signal_Entry_SpeedSlope', label: 'Entry Speed Slope' },
  { key: 'Signal_Entry_AccelerationSlope', label: 'Entry Accel Slope' },
  { key: 'Signal_Entry_MomentumSlope', label: 'Entry Mom Slope' },
  { key: 'Signal_Entry_ConfluenceSlope', label: 'Entry Conf Slope' },
  { key: 'Signal_Entry_JerkSlope', label: 'Entry Jerk Slope' },
  { key: 'Signal_Entry_Zone', label: 'Entry Zone' },
  { key: 'Signal_Entry_Regime', label: 'Entry Regime' },
  { key: 'EA_Entry_Spread', label: 'Entry Spread' }, // Spread is usually EA specific (execution)

  // Exit Signals
  { key: 'Signal_Exit_Quality', label: 'Exit Quality' },
  { key: 'Signal_Exit_Confluence', label: 'Exit Confluence' },
  { key: 'Signal_Exit_Momentum', label: 'Exit Momentum' },
  { key: 'Signal_Exit_Speed', label: 'Exit Speed' },
  { key: 'Signal_Exit_Acceleration', label: 'Exit Acceleration' },
  { key: 'Signal_Exit_Jerk', label: 'Exit Jerk' },
  { key: 'Signal_Exit_PhysicsScore', label: 'Exit Physics Score' },
  { key: 'Signal_Exit_Zone', label: 'Exit Zone' },
  { key: 'Signal_Exit_Regime', label: 'Exit Regime' },
];

const CATEGORICAL_METRICS = ['Signal_Entry_Zone', 'Signal_Entry_Regime', 'Signal_Exit_Zone', 'Signal_Exit_Regime'];

export default function OptimizationEngine({ trades, direction }: OptimizationEngineProps) {
  // State for Longs
  const [longFilters, setLongFilters] = useState<OptimizationFilter[]>([]);
  // State for Shorts
  const [shortFilters, setShortFilters] = useState<OptimizationFilter[]>([]);
  // State for All
  const [allFilters, setAllFilters] = useState<OptimizationFilter[]>([]);
  
  const [result, setResult] = useState<any>(null);
  const [longStats, setLongStats] = useState<any>(null);
  const [shortStats, setShortStats] = useState<any>(null);
  const [combinedStats, setCombinedStats] = useState<any>(null);
  const [equityCurve, setEquityCurve] = useState<any[]>([]);
  const [copied, setCopied] = useState(false);
  const [isOptimizing, setIsOptimizing] = useState(false);

  // Derived state based on current direction
  let filters: OptimizationFilter[];
  if (direction === 'Long') filters = longFilters;
  else if (direction === 'Short') filters = shortFilters;
  else filters = allFilters;
  
  const setFilters = (newFilters: OptimizationFilter[]) => {
    if (direction === 'Long') setLongFilters(newFilters);
    else if (direction === 'Short') setShortFilters(newFilters);
    else setAllFilters(newFilters);
  };

  const handleGlobalOptimization = async () => {
    if (filters.length === 0) return;
    setIsOptimizing(true);
    
    // Allow UI to update
    await new Promise(resolve => setTimeout(resolve, 10));

    let currentFilters = [...filters];
    const passes = 2; // Run multiple passes to allow filters to adjust to each other

    for (let pass = 0; pass < passes; pass++) {
      for (let i = 0; i < currentFilters.length; i++) {
        if (!currentFilters[i].enabled) continue;

        // Optimize this filter against the context of all OTHER filters
        const otherFilters = currentFilters.filter((_, idx) => idx !== i);
        const contextResult = optimizeStrategy(trades, direction, otherFilters);
        
        if (contextResult.trades.length < 5) continue;

        const bestConfig = findBestConfiguration(
          contextResult.trades, 
          currentFilters[i].metric, 
          currentFilters[i].type || 'numeric'
        );

        if (bestConfig) {
           const updatedFilter = { ...currentFilters[i] };
           if (updatedFilter.type === 'categorical' && bestConfig.selectedValues) {
             updatedFilter.selectedValues = bestConfig.selectedValues;
           } else if (bestConfig.min !== undefined && bestConfig.max !== undefined) {
             updatedFilter.min = bestConfig.min;
             updatedFilter.max = bestConfig.max;
           }
           currentFilters[i] = updatedFilter;
        }
      }
    }

    setFilters(currentFilters);
    setIsOptimizing(false);
  };

  // Initial calculation
  useEffect(() => {
    // Always calculate individual stats
    const longRes = optimizeStrategy(trades, 'Long', longFilters);
    const shortRes = optimizeStrategy(trades, 'Short', shortFilters);
    
    setLongStats(longRes);
    setShortStats(shortRes);

    // Calculate Combined Stats
    const combinedTrades = [...longRes.trades, ...shortRes.trades];
    const wins = combinedTrades.filter(t => t.NetProfit > 0);
    const losses = combinedTrades.filter(t => t.NetProfit <= 0);
    const totalTrades = combinedTrades.length;
    const winRate = totalTrades > 0 ? (wins.length / totalTrades) * 100 : 0;
    const netProfit = combinedTrades.reduce((sum, t) => sum + t.NetProfit, 0);
    const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0);
    const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0));
    const profitFactor = grossLoss === 0 ? grossProfit : grossProfit / grossLoss;

    const combined = {
      totalTrades,
      winRate,
      netProfit,
      profitFactor,
      trades: combinedTrades
    };
    setCombinedStats(combined);

    let res;
    if (direction === 'All') {
      res = combined;
    } else {
      res = optimizeStrategy(trades, direction, filters);
    }
    setResult(res);

    // Calculate Equity Curves
    // 1. Sort trades by time
    const sortedTrades = [...trades].sort((a, b) => 
      new Date(a.IN_MT_MASTER_DATE_TIME).getTime() - new Date(b.IN_MT_MASTER_DATE_TIME).getTime()
    );

    // 2. Filter for Baseline (just direction)
    const baselineTrades = sortedTrades.filter(t => {
      if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
      if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
      return true;
    });

    // 3. Filter for Optimized (direction + filters)
    let optimizedTradeIds: Set<string>;
    if (direction === 'All') {
       // For All, we need to check if a trade passed its respective filter set
       optimizedTradeIds = new Set([...longRes.trades, ...shortRes.trades].map(t => t.IN_Trade_ID));
    } else {
       optimizedTradeIds = new Set(res.trades.map(t => t.IN_Trade_ID));
    }

    let runningBaseline = 0;
    let runningOptimized = 0;
    
    const curve = baselineTrades.map((t, i) => {
      runningBaseline += t.NetProfit;
      
      // Only add to optimized running total if this trade passed the filters
      if (optimizedTradeIds.has(t.IN_Trade_ID)) {
        runningOptimized += t.NetProfit;
      }

      // Downsample for performance if needed (every 5th trade if > 1000 trades)
      return {
        trade: i + 1,
        date: t.IN_MT_Date || t.IN_MT_MASTER_DATE_TIME,
        Baseline: runningBaseline,
        Optimized: runningOptimized
      };
    });

    setEquityCurve(curve);
  }, [trades, direction, filters, longFilters, shortFilters]);

  const addFilter = (metricKey: string) => {
    const metric = metricKey as keyof Trade;
    // Don't add duplicate filters
    if (filters.find(f => f.metric === metric)) return;

    const isCategorical = CATEGORICAL_METRICS.includes(metricKey);

    if (isCategorical) {
      // Find all unique values in the current dataset
      const uniqueValues = Array.from(new Set(result.trades.map((t: Trade) => String(t[metric])))) as string[];
      setFilters([...filters, { metric, type: 'categorical', selectedValues: uniqueValues, enabled: true }]);
    } else {
      // Find initial range (min/max of current dataset)
      const values = result.trades.map((t: Trade) => t[metric] as number).filter((v: number) => !isNaN(v));
      const min = Math.min(...values);
      const max = Math.max(...values);

      setFilters([...filters, { metric, min, max, enabled: true }]);
    }
  };

  const updateFilter = (index: number, updates: Partial<OptimizationFilter>) => {
    const newFilters = [...filters];
    newFilters[index] = { ...newFilters[index], ...updates };
    setFilters(newFilters);
  };

  const removeFilter = (index: number) => {
    const newFilters = filters.filter((_, i) => i !== index);
    setFilters(newFilters);
  };

  const autoOptimizeFilter = (index: number) => {
    const filter = filters[index];
    // Run optimization on the CURRENT filtered set (excluding this filter temporarily to find best range within others)
    const otherFilters = filters.filter((_, i) => i !== index);
    const currentContext = optimizeStrategy(trades, direction, otherFilters).trades;
    
    const bestConfig = findBestConfiguration(currentContext, filter.metric, filter.type || 'numeric');
    
    if (bestConfig) {
      if (filter.type === 'categorical' && bestConfig.selectedValues) {
        updateFilter(index, { selectedValues: bestConfig.selectedValues });
      } else if (bestConfig.min !== undefined && bestConfig.max !== undefined) {
        updateFilter(index, { min: bestConfig.min, max: bestConfig.max });
      }
    }
  };

  const generateMQL5Code = () => {
    if (!combinedStats) return '';
    
    let code = `// === OPTIMIZED INPUTS (Generated: ${new Date().toLocaleString()}) ===\n`;
    code += `// Total Net: $${combinedStats.netProfit.toFixed(0)} | Win Rate: ${combinedStats.winRate.toFixed(1)}% | Trades: ${combinedStats.totalTrades}\n`;
    code += `// Longs: $${longStats?.netProfit.toFixed(0)} (${longStats?.winRate.toFixed(1)}%) | Shorts: $${shortStats?.netProfit.toFixed(0)} (${shortStats?.winRate.toFixed(1)}%)\n\n`;
    
    code += `input group "🎯 Optimized Filters"\n`;

    // Mapping of Dashboard Metrics to EA Inputs
    const EA_MAPPINGS: Record<string, any> = {
      'Signal_Entry_Quality': { buyInput: 'MinQualityBuy', sellInput: 'MinQualitySell', defaultBuy: 70.0, defaultSell: 70.0, type: 'min_threshold' },
      'Signal_Entry_PhysicsScore': { buyInput: 'MinPhysicsScoreBuy', sellInput: 'MinPhysicsScoreSell', defaultBuy: 40.0, defaultSell: 40.0, type: 'min_threshold' },
      'EA_Entry_Spread': { buyInput: 'MaxSpreadPipsBuy', sellInput: 'MaxSpreadPipsSell', defaultBuy: 25.0, defaultSell: 25.0, type: 'max_threshold' },
      'Signal_Entry_ConfluenceSlope': { buyInput: 'MinConfluenceSlopeBuy', sellInput: 'MinConfluenceSlopeSell', defaultBuy: 1.0, defaultSell: 1.0, type: 'min_threshold' },
      
      'Signal_Entry_Speed': { buyInput: 'MinSpeedBuy', sellInput: 'MinSpeedSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      'Signal_Entry_Acceleration': { buyInput: 'MinAccelerationBuy', sellInput: 'MinAccelerationSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      'Signal_Entry_Momentum': { buyInput: 'MinMomentumBuy', sellInput: 'MinMomentumSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      
      'Signal_Entry_SpeedSlope': { buyInput: 'MinSpeedSlopeBuy', sellInput: 'MinSpeedSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      'Signal_Entry_AccelerationSlope': { buyInput: 'MinAccelerationSlopeBuy', sellInput: 'MinAccelerationSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      'Signal_Entry_MomentumSlope': { buyInput: 'MinMomentumSlopeBuy', sellInput: 'MinMomentumSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
      'Signal_Entry_JerkSlope': { buyInput: 'MinJerkSlopeBuy', sellInput: 'MinJerkSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
    };

    AVAILABLE_METRICS.forEach(m => {
      const mapping = EA_MAPPINGS[m.key];
      if (!mapping) return; // Skip metrics not in EA

      // --- GLOBAL SETTINGS ---
      if (mapping.globalInput) {
        // Check if filtered in Long or Short (assuming global applies if either is filtered)
        const filter = longFilters.find(f => f.metric === m.key && f.enabled) || 
                       shortFilters.find(f => f.metric === m.key && f.enabled) ||
                       allFilters.find(f => f.metric === m.key && f.enabled);
        
        let value = mapping.defaultGlobal;
        if (filter) {
           if (mapping.type === 'min_threshold') value = filter.min ?? value;
           if (mapping.type === 'max_threshold') value = filter.max ?? value;
        }
        code += `input double ${mapping.globalInput} = ${value.toFixed(2)};\n`;
      }

      // --- BUY/SELL SPECIFIC SETTINGS ---
      if (mapping.buyInput && mapping.sellInput) {
        // Buy
        const buyFilter = longFilters.find(f => f.metric === m.key && f.enabled);
        let buyValue = mapping.defaultBuy;
        if (buyFilter) {
           if (mapping.type === 'max_threshold') {
             buyValue = buyFilter.max ?? buyValue;
           } else {
             // Default to min for min_threshold and range_buy_min...
             buyValue = buyFilter.min ?? buyValue;
           }
        }
        code += `input double ${mapping.buyInput} = ${buyValue.toFixed(2)};\n`;

        // Sell
        const sellFilter = shortFilters.find(f => f.metric === m.key && f.enabled);
        let sellValue = mapping.defaultSell;
        if (sellFilter) {
           if (mapping.type === 'range_buy_min_sell_max') {
             // Special case for negative values where we want the "max" (ceiling)
             sellValue = sellFilter.max ?? sellValue;
           } else if (mapping.type === 'max_threshold') {
             sellValue = sellFilter.max ?? sellValue;
           } else {
             // min_threshold (e.g. Quality > 80 for Sell too)
             sellValue = sellFilter.min ?? sellValue;
           }
        }
        code += `input double ${mapping.sellInput} = ${sellValue.toFixed(2)};\n`;
      }
    });
    
    // Handle Categorical/Boolean separately
    // Zone Filter
    const zoneFilter = longFilters.find(f => f.metric === 'Signal_Entry_Zone' && f.enabled) || 
                       shortFilters.find(f => f.metric === 'Signal_Entry_Zone' && f.enabled);
    
    if (zoneFilter && zoneFilter.selectedValues) {
       const avoidsTransition = !zoneFilter.selectedValues.includes('Transition') && !zoneFilter.selectedValues.includes('Avoid');
       code += `input bool AvoidTransitionZone = ${avoidsTransition ? 'true' : 'false'};\n`;
    } else {
       code += `input bool AvoidTransitionZone = true; // Default\n`;
    }

    return code;
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(generateMQL5Code());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (!result) return <div>Loading...</div>;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-full">
      {/* Left: Controls */}
      <Card className="lg:col-span-2 border-primary/20 bg-primary/5 flex flex-col h-full">
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <div className="flex items-center gap-4">
            <CardTitle className="flex items-center gap-2 text-primary">
              <Sliders className="h-5 w-5" />
              Strategy Optimizer
            </CardTitle>
            <div className="flex bg-background rounded-lg border p-1 opacity-50 cursor-not-allowed" title="Controlled by Dashboard">
              <button
                disabled
                className={`px-3 py-1 text-sm rounded-md transition-colors ${direction === 'All' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground'}`}
              >
                All
              </button>
              <button
                disabled
                className={`px-3 py-1 text-sm rounded-md transition-colors ${direction === 'Long' ? 'bg-green-500 text-white' : 'text-muted-foreground'}`}
              >
                Longs
              </button>
              <button
                disabled
                className={`px-3 py-1 text-sm rounded-md transition-colors ${direction === 'Short' ? 'bg-red-500 text-white' : 'text-muted-foreground'}`}
              >
                Shorts
              </button>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <Button 
              variant="outline" 
              onClick={handleGlobalOptimization}
              disabled={isOptimizing || filters.length === 0}
              className="gap-2 border-purple-500/50 hover:bg-purple-500/10 text-purple-500 h-9 px-3"
            >
              {isOptimizing ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current" /> : <Wand2 className="h-4 w-4" />}
              Auto-Tune All
            </Button>

            <Select onValueChange={addFilter}>
              <SelectTrigger className="w-[200px]">
                <SelectValue placeholder="+ Add Metric Filter" />
              </SelectTrigger>
              <SelectContent>
                {AVAILABLE_METRICS.map(m => (
                  <SelectItem key={m.key} value={m.key}>{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>

        <CardContent className="flex-1 overflow-auto space-y-4">
          {/* Equity Curve Chart */}
          <div className="h-[200px] w-full bg-card border rounded-lg p-2 mb-4">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={equityCurve}>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                <XAxis dataKey="trade" hide />
                <YAxis stroke="#888" fontSize={10} tickFormatter={(val) => `$${val}`} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                  formatter={(val: number) => [`$${val.toFixed(0)}`, '']}
                />
                <Legend />
                <Line 
                  type="monotone" 
                  dataKey="Baseline" 
                  stroke="#666" 
                  dot={false} 
                  strokeWidth={1}
                  strokeDasharray="5 5" 
                />
                <Line 
                  type="monotone" 
                  dataKey="Optimized" 
                  stroke="#10b981" 
                  dot={false} 
                  strokeWidth={2} 
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Active Filters List */}
          {filters.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground border-2 border-dashed border-border/50 rounded-lg">
              <Plus className="h-8 w-8 mx-auto mb-2 opacity-50" />
              <p>Add metrics to start optimizing {direction} trades.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {filters.map((filter, idx) => {
                const label = AVAILABLE_METRICS.find(m => m.key === filter.metric)?.label;
                
                if (filter.type === 'categorical') {
                  // Get all possible values from the original dataset (not filtered) to ensure options remain available
                  const allValues = Array.from(new Set(trades.map(t => String(t[filter.metric])))).sort();
                  
                  return (
                    <div key={idx} className="bg-card border rounded-lg p-4 flex items-center gap-4 shadow-sm">
                      <div className="w-32 font-medium text-sm">{label}</div>
                      
                      <div className="flex-1 flex flex-wrap gap-2">
                        {allValues.map(val => (
                          <label key={val} className={`flex items-center gap-1 text-xs cursor-pointer px-2 py-1 rounded border transition-colors ${filter.selectedValues?.includes(val) ? 'bg-primary/20 border-primary text-primary' : 'bg-secondary/50 border-transparent text-muted-foreground hover:bg-secondary'}`}>
                            <input 
                              type="checkbox"
                              className="hidden"
                              checked={filter.selectedValues?.includes(val)}
                              onChange={(e) => {
                                const current = filter.selectedValues || [];
                                let newValues;
                                if (e.target.checked) {
                                  newValues = [...current, val];
                                } else {
                                  newValues = current.filter(v => v !== val);
                                }
                                updateFilter(idx, { selectedValues: newValues });
                              }}
                            />
                            {val}
                          </label>
                        ))}
                      </div>

                      <div className="flex gap-1">
                        <Button variant="ghost" className="h-8 w-8 p-0" onClick={() => removeFilter(idx)} title="Remove Filter">
                          <Trash2 className="h-4 w-4 text-muted-foreground hover:text-destructive" />
                        </Button>
                      </div>
                    </div>
                  );
                }

                return (
                  <div key={idx} className="bg-card border rounded-lg p-4 flex items-center gap-4 shadow-sm">
                    <div className="w-32 font-medium text-sm">{label}</div>
                    
                    <div className="flex-1 flex items-center gap-2">
                      <input 
                        type="range" 
                        min={-100} max={100} // Simplified range for UI demo, ideally dynamic
                        value={filter.min}
                        onChange={(e) => updateFilter(idx, { min: parseFloat(e.target.value) })}
                        className="flex-1 h-2 bg-secondary rounded-lg appearance-none cursor-pointer"
                      />
                      <div className="flex gap-2 text-xs font-mono w-32 justify-end">
                        <input 
                          type="number" 
                          value={filter.min}
                          onChange={(e) => updateFilter(idx, { min: parseFloat(e.target.value) })}
                          className="w-16 bg-background border rounded px-1"
                        />
                        <span>to</span>
                        <input 
                          type="number" 
                          value={filter.max}
                          onChange={(e) => updateFilter(idx, { max: parseFloat(e.target.value) })}
                          className="w-16 bg-background border rounded px-1"
                        />
                      </div>
                    </div>

                    <div className="flex gap-1">
                      <Button variant="ghost" className="h-8 w-8 p-0" onClick={() => autoOptimizeFilter(idx)} title="Auto-Find Best Range">
                        <Wand2 className="h-4 w-4 text-purple-400" />
                      </Button>
                      <Button variant="ghost" className="h-8 w-8 p-0" onClick={() => removeFilter(idx)} title="Remove Filter">
                        <Trash2 className="h-4 w-4 text-muted-foreground hover:text-destructive" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Right: Results & Code */}
      <div className="flex flex-col gap-6 h-full">
        {/* Live Stats Card */}
        <Card className="bg-card border-border shadow-lg">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Projected Performance</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-3 gap-4 mb-4 text-center">
              {/* Long Column */}
              <div>
                <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b pb-1 mb-2">Long</div>
                <div className="text-2xl font-bold">{longStats?.winRate.toFixed(1)}%</div>
                <div className="text-xs text-muted-foreground mb-1">{longStats?.totalTrades} trades</div>
                <div className={`text-lg font-bold ${longStats?.netProfit > 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${longStats?.netProfit.toFixed(0)}
                </div>
              </div>

              {/* Short Column */}
              <div>
                <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b pb-1 mb-2">Short</div>
                <div className="text-2xl font-bold">{shortStats?.winRate.toFixed(1)}%</div>
                <div className="text-xs text-muted-foreground mb-1">{shortStats?.totalTrades} trades</div>
                <div className={`text-lg font-bold ${shortStats?.netProfit > 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${shortStats?.netProfit.toFixed(0)}
                </div>
              </div>

              {/* Total Column */}
              <div>
                <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b pb-1 mb-2">Total</div>
                <div className="text-2xl font-bold text-primary">{combinedStats?.winRate.toFixed(1)}%</div>
                <div className="text-xs text-muted-foreground mb-1">{combinedStats?.totalTrades} trades</div>
                <div className={`text-lg font-bold ${combinedStats?.netProfit > 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${combinedStats?.netProfit.toFixed(0)}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Code Generator */}
        <Card className="flex-1 flex flex-col">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Copy className="h-5 w-5" />
              MQL5 Input Generator
            </CardTitle>
          </CardHeader>
          <CardContent className="flex-1 flex flex-col">
            <div className="flex-1 bg-zinc-950 p-4 rounded-lg border border-zinc-800 font-mono text-xs text-zinc-300 overflow-auto whitespace-pre">
              {generateMQL5Code()}
            </div>
            <Button 
              onClick={handleCopy}
              className="mt-4 w-full gap-2"
              variant="default"
            >
              {copied ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
              {copied ? 'Copied to Clipboard' : 'Copy Inputs'}
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
