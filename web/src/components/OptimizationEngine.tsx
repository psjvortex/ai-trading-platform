import { useState, useEffect, useMemo } from 'react';
import { Trade } from '../types';
import { optimizeStrategy, findBestConfiguration, OptimizationFilter } from '../lib/analytics';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Check, Copy, Sliders, Plus, Trash2, Wand2, TrendingUp, BarChart2 } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

// Format dollar amounts with commas, no decimals
const formatDollar = (value: number): string => {
  return Math.round(value).toLocaleString('en-US');
};

interface OptimizationEngineProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
  longFilters: OptimizationFilter[];
  setLongFilters: (filters: OptimizationFilter[]) => void;
  shortFilters: OptimizationFilter[];
  setShortFilters: (filters: OptimizationFilter[]) => void;
  allFilters: OptimizationFilter[];
  setAllFilters: (filters: OptimizationFilter[]) => void;
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

export default function OptimizationEngine({ 
  trades, 
  direction,
  longFilters,
  setLongFilters,
  shortFilters,
  setShortFilters,
  allFilters,
  setAllFilters
}: OptimizationEngineProps) {
  const [result, setResult] = useState<any>(null);
  const [longStats, setLongStats] = useState<any>(null);
  const [shortStats, setShortStats] = useState<any>(null);
  const [combinedStats, setCombinedStats] = useState<any>(null);
  const [equityCurve, setEquityCurve] = useState<any[]>([]);
  const [copied, setCopied] = useState(false);
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [hasTuned, setHasTuned] = useState(false); // Track if any tuning has been performed

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
        // Skip only if explicitly disabled (enabled === false), not if undefined
        if (currentFilters[i].enabled === false) continue;

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
    setHasTuned(true); // Mark that tuning has been performed
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
        date: t.IN_MT_MASTER_DATE_TIME,
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
      // Add new filter at the BEGINNING (newest on top)
      setFilters([{ metric, type: 'categorical', selectedValues: uniqueValues, enabled: true }, ...filters]);
    } else {
      // Find initial range (min/max of current dataset)
      const values = result.trades.map((t: Trade) => t[metric] as number).filter((v: number) => !isNaN(v));
      const min = Math.min(...values);
      const max = Math.max(...values);

      // Add new filter at the BEGINNING (newest on top)
      setFilters([{ metric, min, max, enabled: true }, ...filters]);
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
    // Reset hasTuned if all filters are removed
    if (newFilters.length === 0) {
      setHasTuned(false);
    }
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
      setHasTuned(true); // Mark that tuning has been performed
    }
  };

  const generateMQL5Code = () => {
    if (!combinedStats) return '';
    
    let code = `// === OPTIMIZED INPUTS (Generated: ${new Date().toLocaleString()}) ===\n`;
    code += `// Total Net: $${formatDollar(combinedStats.netProfit)} | Win Rate: ${combinedStats.winRate.toFixed(1)}% | Trades: ${combinedStats.totalTrades}\n`;
    code += `// Longs: $${formatDollar(longStats?.netProfit || 0)} (${longStats?.winRate.toFixed(1)}%) | Shorts: $${formatDollar(shortStats?.netProfit || 0)} (${shortStats?.winRate.toFixed(1)}%)\n\n`;
    
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

  // Calculate additional metrics for each direction
  const calculateDetailedStats = (tradeList: Trade[]) => {
    if (!tradeList || tradeList.length === 0) {
      return {
        totalTrades: 0,
        wins: 0,
        losses: 0,
        winRate: 0,
        netProfit: 0,
        grossProfit: 0,
        grossLoss: 0,
        profitFactor: 0,
        avgWin: 0,
        avgLoss: 0,
        expectancy: 0,
        maxWin: 0,
        maxLoss: 0,
        avgTrade: 0,
      };
    }

    const wins = tradeList.filter(t => t.NetProfit > 0);
    const losses = tradeList.filter(t => t.NetProfit <= 0);
    const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0);
    const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0));
    const netProfit = grossProfit - grossLoss;
    const profitFactor = grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? Infinity : 0;

    return {
      totalTrades: tradeList.length,
      wins: wins.length,
      losses: losses.length,
      winRate: tradeList.length > 0 ? (wins.length / tradeList.length) * 100 : 0,
      netProfit,
      grossProfit,
      grossLoss,
      profitFactor,
      avgWin: wins.length > 0 ? grossProfit / wins.length : 0,
      avgLoss: losses.length > 0 ? grossLoss / losses.length : 0,
      expectancy: tradeList.length > 0 ? netProfit / tradeList.length : 0,
      maxWin: wins.length > 0 ? Math.max(...wins.map(t => t.NetProfit)) : 0,
      maxLoss: losses.length > 0 ? Math.min(...losses.map(t => t.NetProfit)) : 0,
      avgTrade: tradeList.length > 0 ? netProfit / tradeList.length : 0,
    };
  };

  // Optimized stats (with filters applied)
  const longDetailed = calculateDetailedStats(longStats?.trades || []);
  const shortDetailed = calculateDetailedStats(shortStats?.trades || []);
  const totalDetailed = calculateDetailedStats(combinedStats?.trades || []);

  // Baseline stats (NO filters - raw directional data)
  const longBaseline = useMemo(() => {
    const longTrades = trades.filter(t => t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy');
    return calculateDetailedStats(longTrades);
  }, [trades]);

  const shortBaseline = useMemo(() => {
    const shortTrades = trades.filter(t => t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell');
    return calculateDetailedStats(shortTrades);
  }, [trades]);

  const totalBaseline = useMemo(() => {
    return calculateDetailedStats(trades);
  }, [trades]);

  // Check if optimization has changed from baseline
  const hasLongOptimization = longFilters.some(f => f.enabled !== false);
  const hasShortOptimization = shortFilters.some(f => f.enabled !== false);
  const hasAnyOptimization = hasLongOptimization || hasShortOptimization;

  // Delta calculation helper
  const getDelta = (current: number, baseline: number) => {
    const delta = current - baseline;
    return delta;
  };

  // Stats card component with baseline comparison
  const StatsCard = ({ 
    title, 
    stats, 
    baseline, 
    color, 
    icon,
    hasOptimization,
    isActive 
  }: { 
    title: string; 
    stats: ReturnType<typeof calculateDetailedStats>; 
    baseline: ReturnType<typeof calculateDetailedStats>;
    color: string; 
    icon: React.ReactNode;
    hasOptimization: boolean;
    isActive: boolean;
  }) => {
    const profitDelta = getDelta(stats.netProfit, baseline.netProfit);
    const winRateDelta = getDelta(stats.winRate, baseline.winRate);
    const tradesDelta = getDelta(stats.totalTrades, baseline.totalTrades);
    const winsDelta = getDelta(stats.wins, baseline.wins);
    const lossesDelta = getDelta(stats.losses, baseline.losses);

    const DeltaBadge = ({ delta, suffix = '', invert = false }: { delta: number; suffix?: string; invert?: boolean }) => {
      if (!hasOptimization || delta === 0) return null;
      const isPositive = invert ? delta < 0 : delta > 0;
      const formattedDelta = suffix === '%' ? delta.toFixed(1) : formatDollar(delta);
      return (
        <span className={`ml-1 text-[10px] font-medium ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
          {delta > 0 ? '+' : ''}{formattedDelta}{suffix}
        </span>
      );
    };

    // Dynamic styling based on active state - bright outline instead of background tint
    const borderColor = color === 'green' ? 'border-green-500' : color === 'red' ? 'border-red-500' : 'border-blue-500';
    const cardStyle = isActive 
      ? `bg-zinc-900/50 ${borderColor} border-2` 
      : 'bg-zinc-900/50 border-zinc-700/30 border';
    const titleColor = isActive 
      ? (color === 'green' ? 'text-green-500' : color === 'red' ? 'text-red-500' : 'text-blue-500')
      : 'text-zinc-400';

    return (
      <Card className={`${cardStyle} transition-all duration-200`}>
        <CardHeader className="pb-3">
          <CardTitle className={`text-lg font-bold flex items-center gap-2 ${titleColor} transition-colors`}>
            {icon}
            {title}
            {hasOptimization && isActive && (
              <span className="ml-auto text-[10px] font-normal text-muted-foreground bg-zinc-800 px-2 py-0.5 rounded">
                vs baseline
              </span>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Primary Metrics */}
          <div className="grid grid-cols-2 gap-3">
            <div className="text-center p-3 bg-zinc-800/50 rounded-lg">
              <div className="flex items-center justify-center gap-1">
                <span className={`text-3xl font-bold ${stats.netProfit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${formatDollar(stats.netProfit)}
                </span>
                {isActive && <DeltaBadge delta={profitDelta} />}
              </div>
              <div className="text-xs text-muted-foreground">Net Profit</div>
              {hasOptimization && isActive && (
                <div className="text-[10px] text-zinc-500 mt-0.5">
                  was ${formatDollar(baseline.netProfit)}
                </div>
              )}
            </div>
            <div className="text-center p-3 bg-zinc-800/50 rounded-lg">
              <div className="flex items-center justify-center gap-1">
                <span className={`text-3xl font-bold ${stats.winRate >= 50 ? 'text-green-500' : 'text-yellow-500'}`}>
                  {stats.winRate.toFixed(1)}%
                </span>
                {isActive && <DeltaBadge delta={winRateDelta} suffix="%" />}
              </div>
              <div className="text-xs text-muted-foreground">Win Rate</div>
              {hasOptimization && isActive && (
                <div className="text-[10px] text-zinc-500 mt-0.5">
                  was {baseline.winRate.toFixed(1)}%
                </div>
              )}
            </div>
          </div>

          {/* Secondary Metrics */}
          <div className="grid grid-cols-3 gap-2 text-center">
            <div className="p-2 bg-zinc-800/30 rounded">
              <div className="flex items-center justify-center gap-0.5">
                <span className="text-lg font-semibold">{stats.totalTrades}</span>
                {isActive && <DeltaBadge delta={tradesDelta} />}
              </div>
              <div className="text-[10px] text-muted-foreground">Trades</div>
            </div>
            <div className="p-2 bg-zinc-800/30 rounded">
              <div className="flex items-center justify-center gap-0.5">
                <span className="text-lg font-semibold text-green-400">{stats.wins}</span>
                {isActive && <DeltaBadge delta={winsDelta} />}
              </div>
              <div className="text-[10px] text-muted-foreground">Wins</div>
            </div>
            <div className="p-2 bg-zinc-800/30 rounded">
              <div className="flex items-center justify-center gap-0.5">
                <span className="text-lg font-semibold text-red-400">{stats.losses}</span>
                {isActive && <DeltaBadge delta={lossesDelta} invert />}
              </div>
              <div className="text-[10px] text-muted-foreground">Losses</div>
            </div>
          </div>

          {/* Detailed Metrics Table */}
          <div className="space-y-1 text-sm">
            <div className="flex justify-between py-1 border-b border-zinc-800">
              <span className="text-muted-foreground">Profit Factor</span>
              <span className={`font-mono font-medium ${stats.profitFactor >= 1.5 ? 'text-green-400' : stats.profitFactor >= 1 ? 'text-yellow-400' : 'text-red-400'}`}>
                {stats.profitFactor === Infinity ? '∞' : stats.profitFactor.toFixed(2)}
              </span>
            </div>
            <div className="flex justify-between py-1 border-b border-zinc-800">
              <span className="text-muted-foreground">Expectancy</span>
              <span className={`font-mono font-medium ${stats.expectancy >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                ${formatDollar(stats.expectancy)}
              </span>
            </div>
            <div className="flex justify-between py-1 border-b border-zinc-800">
              <span className="text-muted-foreground">Avg Win</span>
              <span className="font-mono font-medium text-green-400">${formatDollar(stats.avgWin)}</span>
            </div>
            <div className="flex justify-between py-1 border-b border-zinc-800">
              <span className="text-muted-foreground">Avg Loss</span>
              <span className="font-mono font-medium text-red-400">-${formatDollar(stats.avgLoss)}</span>
            </div>
            <div className="flex justify-between py-1 border-b border-zinc-800">
              <span className="text-muted-foreground">Max Win</span>
              <span className="font-mono font-medium text-green-400">${formatDollar(stats.maxWin)}</span>
            </div>
            <div className="flex justify-between py-1">
              <span className="text-muted-foreground">Max Loss</span>
              <span className="font-mono font-medium text-red-400">${formatDollar(Math.abs(stats.maxLoss))}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  };

  // Loading state check - MUST be after all hooks
  if (!result) {
    return <div className="text-center py-8 text-muted-foreground">Loading optimization data...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Row 1: Three Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatsCard 
          title="Longs" 
          stats={longDetailed} 
          baseline={longBaseline}
          color="green"
          icon={<TrendingUp className="h-5 w-5" />}
          hasOptimization={hasLongOptimization}
          isActive={direction === 'Long'}
        />
        <StatsCard 
          title="Shorts" 
          stats={shortDetailed} 
          baseline={shortBaseline}
          color="red"
          icon={<TrendingUp className="h-5 w-5 rotate-180" />}
          hasOptimization={hasShortOptimization}
          isActive={direction === 'Short'}
        />
        <StatsCard 
          title="Combined" 
          stats={totalDetailed} 
          baseline={totalBaseline}
          color="blue"
          icon={<BarChart2 className="h-5 w-5" />}
          hasOptimization={hasAnyOptimization}
          isActive={direction === 'All'}
        />
      </div>

      {/* Row 2: Strategy Optimizer (Full Width) */}
      <Card className="border-primary/20 bg-primary/5">
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="flex items-center gap-2 text-primary">
            <Sliders className="h-5 w-5" />
            Strategy Optimizer
            <span className={`ml-2 px-2 py-0.5 text-xs rounded-full ${
              direction === 'Long' ? 'bg-green-500/20 text-green-400' : 
              direction === 'Short' ? 'bg-red-500/20 text-red-400' : 
              'bg-primary/20 text-primary'
            }`}>
              {direction}
            </span>
          </CardTitle>
          
          <div className="flex items-center gap-2">
            <Button 
              variant="outline" 
              onClick={handleGlobalOptimization}
              disabled={isOptimizing || filters.length === 0 || direction === 'All'}
              className={`gap-2 h-9 px-3 ${
                direction === 'All' 
                  ? 'border-zinc-700 text-zinc-500 cursor-not-allowed' 
                  : 'border-purple-500/50 hover:bg-purple-500/10 text-purple-500'
              }`}
            >
              {isOptimizing ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current" /> : <Wand2 className="h-4 w-4" />}
              Auto-Tune All
            </Button>

            <Select onValueChange={addFilter} disabled={direction === 'All'}>
              <SelectTrigger className={`w-[180px] ${direction === 'All' ? 'opacity-50 cursor-not-allowed' : ''}`}>
                <SelectValue placeholder="+ Add Filter" />
              </SelectTrigger>
              <SelectContent>
                {AVAILABLE_METRICS.map(m => (
                  <SelectItem key={m.key} value={m.key}>{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>

        <CardContent className="space-y-4">
          {/* Two Column Layout: Chart + Filters */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left: Equity Curve Chart */}
            <div className="h-[220px] w-full bg-card border rounded-lg p-2">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={equityCurve}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                  <XAxis dataKey="trade" hide />
                  <YAxis stroke="#888" fontSize={10} tickFormatter={(val) => `$${formatDollar(val)}`} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                    formatter={(val: number, name: string) => [`$${formatDollar(val)}`, name]}
                  />
                  <Legend />
                  {/* Baseline: solid & prominent when not tuned, dashed when tuned */}
                  <Line 
                    type="monotone" 
                    dataKey="Baseline" 
                    stroke={!hasTuned ? '#3b82f6' : '#666'} 
                    dot={false} 
                    strokeWidth={!hasTuned ? 2 : 1}
                    strokeDasharray={!hasTuned ? undefined : '5 5'} 
                  />
                  {/* Optimized: only show after tuning has been performed */}
                  {hasTuned && (
                    <Line 
                      type="monotone" 
                      dataKey="Optimized" 
                      stroke="#10b981" 
                      dot={false} 
                      strokeWidth={2}
                    />
                  )}
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Active Filters List */}
            {filters.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground border-2 border-dashed border-border/50 rounded-lg">
                <Plus className="h-6 w-6 mx-auto mb-2 opacity-50" />
                <p className="text-sm">Add metrics to optimize {direction} trades</p>
              </div>
            ) : (
              <div className="space-y-2">
                {filters.map((filter, idx) => {
                  const label = AVAILABLE_METRICS.find(m => m.key === filter.metric)?.label;
                  
                  if (filter.type === 'categorical') {
                    const allValues = Array.from(new Set(trades.map(t => String(t[filter.metric])))).sort();
                    
                    return (
                      <div key={idx} className="bg-card border rounded-lg p-3 flex items-center gap-3 shadow-sm">
                        <div className="w-28 font-medium text-sm">{label}</div>
                        
                        <div className="flex-1 flex flex-wrap gap-1">
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
                          <Button 
                            variant="ghost" 
                            className="h-7 w-7 p-0" 
                            onClick={() => autoOptimizeFilter(idx)}
                            disabled={direction === 'All'}
                          >
                            <Wand2 className={`h-4 w-4 ${direction === 'All' ? 'text-zinc-600' : 'text-purple-400'}`} />
                          </Button>
                          <Button variant="ghost" className="h-7 w-7 p-0" onClick={() => removeFilter(idx)}>
                            <Trash2 className="h-4 w-4 text-muted-foreground hover:text-destructive" />
                          </Button>
                        </div>
                      </div>
                    );
                  }

                  return (
                    <div key={idx} className="bg-card border rounded-lg p-3 flex items-center gap-3 shadow-sm">
                      <div className="w-28 font-medium text-sm">{label}</div>
                      
                      <div className="flex-1 flex items-center gap-2">
                        <input 
                          type="range" 
                          min={-100} max={100}
                          value={filter.min}
                          onChange={(e) => updateFilter(idx, { min: parseFloat(e.target.value) })}
                          className="flex-1 h-2 bg-secondary rounded-lg appearance-none cursor-pointer"
                        />
                        <div className="flex gap-1 text-xs font-mono">
                          <input 
                            type="number" 
                            value={filter.min}
                            onChange={(e) => updateFilter(idx, { min: parseFloat(e.target.value) })}
                            className="w-16 bg-background border rounded px-1 py-0.5"
                          />
                          <span className="text-muted-foreground">to</span>
                          <input 
                            type="number" 
                            value={filter.max}
                            onChange={(e) => updateFilter(idx, { max: parseFloat(e.target.value) })}
                            className="w-16 bg-background border rounded px-1 py-0.5"
                          />
                        </div>
                      </div>

                      <div className="flex gap-1">
                        <Button 
                          variant="ghost" 
                          className="h-7 w-7 p-0" 
                          onClick={() => autoOptimizeFilter(idx)}
                          disabled={direction === 'All'}
                        >
                          <Wand2 className={`h-4 w-4 ${direction === 'All' ? 'text-zinc-600' : 'text-purple-400'}`} />
                        </Button>
                        <Button variant="ghost" className="h-7 w-7 p-0" onClick={() => removeFilter(idx)}>
                          <Trash2 className="h-4 w-4 text-muted-foreground hover:text-destructive" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Bottom Row: MQL5 Code Generator */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2">
            <Copy className="h-5 w-5" />
            MQL5 Input Generator
            <span className="ml-auto text-xs text-muted-foreground font-normal">
              Copy these inputs to your EA configuration
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-zinc-950 p-4 rounded-lg border border-zinc-800 font-mono text-xs text-zinc-300 overflow-auto whitespace-pre max-h-[300px]">
              {generateMQL5Code()}
            </div>
            <div className="flex flex-col justify-between">
              <div className="space-y-3">
                <div className="p-3 bg-green-500/10 border border-green-500/30 rounded-lg">
                  <div className="text-sm font-medium text-green-400 mb-1">Long Filters Active: {longFilters.filter(f => f.enabled !== false).length}</div>
                  <div className="text-xs text-muted-foreground">
                    {longFilters.filter(f => f.enabled !== false).map(f => 
                      AVAILABLE_METRICS.find(m => m.key === f.metric)?.label
                    ).join(', ') || 'None'}
                  </div>
                </div>
                <div className="p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                  <div className="text-sm font-medium text-red-400 mb-1">Short Filters Active: {shortFilters.filter(f => f.enabled !== false).length}</div>
                  <div className="text-xs text-muted-foreground">
                    {shortFilters.filter(f => f.enabled !== false).map(f => 
                      AVAILABLE_METRICS.find(m => m.key === f.metric)?.label
                    ).join(', ') || 'None'}
                  </div>
                </div>
              </div>
              <Button 
                onClick={handleCopy}
                className="mt-4 w-full gap-2 h-12 text-base"
                variant="default"
              >
                {copied ? <Check className="h-5 w-5" /> : <Copy className="h-5 w-5" />}
                {copied ? 'Copied to Clipboard!' : 'Copy EA Inputs'}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
