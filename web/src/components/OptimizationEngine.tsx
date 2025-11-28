import { useState, useEffect, useMemo } from 'react';
import { Trade } from '../types';
import { optimizeStrategy, findBestConfiguration, OptimizationFilter } from '../lib/analytics';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Check, Copy, Sliders, Plus, Trash2, Wand2, TrendingUp, BarChart2, Clock, Zap, LogOut } from 'lucide-react';
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
  eaInputs?: Record<string, { value: string | number | boolean; type: string }> | null;
  allEaInputs?: Record<string, any> | null;
  eaVersion?: string;
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
  
  // Time Segment Filters (CST-based, matches EA inputs)
  { key: 'IN_CST_Day_OP_01', label: '📅 Day of Week' },
  { key: 'IN_Segment_15M_OP_01', label: '⏱️ 15-Min Segment' },
  { key: 'IN_Segment_30M_OP_01', label: '⏱️ 30-Min Segment' },
  { key: 'IN_Segment_01H_OP_01', label: '⏱️ 1-Hour Segment' },
  { key: 'IN_Segment_02H_OP_01', label: '⏱️ 2-Hour Segment' },
  { key: 'IN_Segment_03H_OP_01', label: '⏱️ 3-Hour Segment' },
  { key: 'IN_Segment_04H_OP_01', label: '⏱️ 4-Hour Segment' },
];

// Categorical metrics (checkbox selection)
const CATEGORICAL_METRICS = ['Signal_Entry_Zone', 'Signal_Entry_Regime', 'Signal_Exit_Zone', 'Signal_Exit_Regime', 'IN_CST_Day_OP_01'];

// Time segment metrics (numeric range for min/max segment selection)
const TIME_SEGMENT_METRICS = ['IN_Segment_15M_OP_01', 'IN_Segment_30M_OP_01', 'IN_Segment_01H_OP_01', 'IN_Segment_02H_OP_01', 'IN_Segment_03H_OP_01', 'IN_Segment_04H_OP_01'];

// Segment ranges for validation
const SEGMENT_RANGES: Record<string, { min: number; max: number; label: string }> = {
  'IN_Segment_15M_OP_01': { min: 1, max: 96, label: '15-min (1-96)' },
  'IN_Segment_30M_OP_01': { min: 1, max: 48, label: '30-min (1-48)' },
  'IN_Segment_01H_OP_01': { min: 1, max: 24, label: '1-hour (1-24)' },
  'IN_Segment_02H_OP_01': { min: 1, max: 12, label: '2-hour (1-12)' },
  'IN_Segment_03H_OP_01': { min: 1, max: 8, label: '3-hour (1-8)' },
  'IN_Segment_04H_OP_01': { min: 1, max: 6, label: '4-hour (1-6)' },
};

export default function OptimizationEngine({ 
  trades, 
  direction,
  longFilters,
  setLongFilters,
  shortFilters,
  setShortFilters,
  allFilters,
  setAllFilters,
  eaInputs,
  allEaInputs,
  eaVersion
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
    let optimizedTradeIds: Set<string | number>;
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
    const isTimeSegment = TIME_SEGMENT_METRICS.includes(metricKey);

    if (isCategorical) {
      // Find all unique values in the current dataset
      const uniqueValues = Array.from(new Set(result.trades.map((t: Trade) => String(t[metric])))) as string[];
      // Add new filter at the BEGINNING (newest on top)
      setFilters([{ metric, type: 'categorical', selectedValues: uniqueValues, enabled: true }, ...filters]);
    } else if (isTimeSegment) {
      // Time segment filters use numeric ranges (segment numbers)
      // Parse segment number from format like "15-045" or "1h-012"
      const values = result.trades.map((t: Trade) => {
        const val = String(t[metric]);
        const match = val.match(/\d+$/);  // Extract trailing numbers
        return match ? parseInt(match[0], 10) : 0;
      }).filter((v: number) => v > 0);
      
      const segmentRange = SEGMENT_RANGES[metricKey];
      const min = segmentRange?.min || Math.min(...values);
      const max = segmentRange?.max || Math.max(...values);

      // Add new filter with segment range
      setFilters([{ metric, min, max, type: 'numeric', enabled: true }, ...filters]);
    } else {
      // Regular numeric filter
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

  // Entry metrics for "Optimize All Entry" button
  const ENTRY_METRICS = AVAILABLE_METRICS.filter(m => 
    m.key.startsWith('Signal_Entry_') || 
    m.key.startsWith('EA_Entry_') || 
    m.key.startsWith('IN_CST_Day') || 
    m.key.startsWith('IN_Segment_')
  );

  // Exit metrics for "Optimize All Exit" button
  const EXIT_METRICS = AVAILABLE_METRICS.filter(m => 
    m.key.startsWith('Signal_Exit_')
  );

  // State for optimization progress
  const [optimizeProgress, setOptimizeProgress] = useState<{ current: number; total: number; metric: string } | null>(null);

  // Optimize All Entry Filters
  const handleOptimizeAllEntry = async () => {
    setIsOptimizing(true);
    setOptimizeProgress({ current: 0, total: ENTRY_METRICS.length, metric: 'Starting...' });
    
    // Allow UI to update
    await new Promise(resolve => setTimeout(resolve, 10));

    let newFilters: OptimizationFilter[] = [];
    let appliedCount = 0;

    // Get baseline trades for current direction
    const baselineTrades = optimizeStrategy(trades, direction, []).trades;
    
    for (let i = 0; i < ENTRY_METRICS.length; i++) {
      const metric = ENTRY_METRICS[i];
      setOptimizeProgress({ current: i + 1, total: ENTRY_METRICS.length, metric: metric.label });
      await new Promise(resolve => setTimeout(resolve, 5)); // Allow UI update
      
      const isCategorical = CATEGORICAL_METRICS.includes(metric.key);
      const isTimeSegment = TIME_SEGMENT_METRICS.includes(metric.key);
      const metricType = isCategorical ? 'categorical' : 'numeric';
      
      // Find best configuration for this metric against all currently applied filters
      const contextTrades = newFilters.length > 0 
        ? optimizeStrategy(trades, direction, newFilters).trades 
        : baselineTrades;
      
      if (contextTrades.length < 10) continue;
      
      const bestConfig = findBestConfiguration(contextTrades, metric.key, metricType);
      
      if (bestConfig && bestConfig.netProfit > 0) {
        // Only add filter if it improves profit
        const testFilter: OptimizationFilter = {
          metric: metric.key,
          enabled: true,
          type: metricType,
          ...(metricType === 'categorical' 
            ? { selectedValues: bestConfig.selectedValues }
            : { min: bestConfig.min, max: bestConfig.max }
          )
        };
        
        // Verify this filter actually improves results
        const withFilter = optimizeStrategy(trades, direction, [...newFilters, testFilter]);
        const withoutFilter = optimizeStrategy(trades, direction, newFilters);
        
        if (withFilter.netProfit > withoutFilter.netProfit && withFilter.trades.length >= 10) {
          newFilters.push(testFilter);
          appliedCount++;
        }
      }
    }
    
    // Merge with existing filters (keep existing, add new ones that don't duplicate)
    const existingMetrics = new Set(filters.map(f => f.metric));
    const additionalFilters = newFilters.filter(f => !existingMetrics.has(f.metric));
    
    if (additionalFilters.length > 0) {
      setFilters([...additionalFilters, ...filters]);
    }
    
    setHasTuned(true);
    setOptimizeProgress(null);
    setIsOptimizing(false);
    
    console.log(`✅ Optimize All Entry: Applied ${appliedCount} new filters`);
  };

  // Optimize All Exit Filters
  const handleOptimizeAllExit = async () => {
    setIsOptimizing(true);
    setOptimizeProgress({ current: 0, total: EXIT_METRICS.length, metric: 'Starting...' });
    
    await new Promise(resolve => setTimeout(resolve, 10));

    let newFilters: OptimizationFilter[] = [];
    let appliedCount = 0;

    // Get current filtered trades (with entry filters applied)
    const baselineTrades = optimizeStrategy(trades, direction, filters).trades;
    
    for (let i = 0; i < EXIT_METRICS.length; i++) {
      const metric = EXIT_METRICS[i];
      setOptimizeProgress({ current: i + 1, total: EXIT_METRICS.length, metric: metric.label });
      await new Promise(resolve => setTimeout(resolve, 5));
      
      const isCategorical = CATEGORICAL_METRICS.includes(metric.key);
      const metricType = isCategorical ? 'categorical' : 'numeric';
      
      // Find best configuration against current context
      const contextTrades = newFilters.length > 0 
        ? optimizeStrategy(trades, direction, [...filters, ...newFilters]).trades 
        : baselineTrades;
      
      if (contextTrades.length < 10) continue;
      
      const bestConfig = findBestConfiguration(contextTrades, metric.key, metricType);
      
      if (bestConfig && bestConfig.netProfit > 0) {
        const testFilter: OptimizationFilter = {
          metric: metric.key,
          enabled: true,
          type: metricType,
          ...(metricType === 'categorical' 
            ? { selectedValues: bestConfig.selectedValues }
            : { min: bestConfig.min, max: bestConfig.max }
          )
        };
        
        // Verify improvement
        const withFilter = optimizeStrategy(trades, direction, [...filters, ...newFilters, testFilter]);
        const withoutFilter = optimizeStrategy(trades, direction, [...filters, ...newFilters]);
        
        if (withFilter.netProfit > withoutFilter.netProfit && withFilter.trades.length >= 10) {
          newFilters.push(testFilter);
          appliedCount++;
        }
      }
    }
    
    // Merge with existing filters
    const existingMetrics = new Set(filters.map(f => f.metric));
    const additionalFilters = newFilters.filter(f => !existingMetrics.has(f.metric));
    
    if (additionalFilters.length > 0) {
      setFilters([...filters, ...additionalFilters]);
    }
    
    setHasTuned(true);
    setOptimizeProgress(null);
    setIsOptimizing(false);
    
    console.log(`✅ Optimize All Exit: Applied ${appliedCount} new filters`);
  };

  // Helper to get EA input value from parsed inputs
  const getEAInputValue = (inputName: string, fallback: number): number => {
    if (eaInputs && eaInputs[inputName]) {
      const val = eaInputs[inputName].value;
      return typeof val === 'number' ? val : parseFloat(String(val)) || fallback;
    }
    return fallback;
  };

  const generateMQL5Code = () => {
    if (!combinedStats) return '';
    
    // Build a map of optimized filter values from the current filter configuration
    const optimizedValues: Array<{ name: string; value: number; comment: string }> = [];
    
    // EA Input name mapping from dashboard metrics to EA input names
    // v5.0.0.5: Now includes both Min (floor) and Max (ceiling) inputs
    const EA_MAPPINGS: Record<string, { 
      minBuyInput: string; 
      maxBuyInput: string;
      minSellInput: string; 
      maxSellInput: string;
      type: string 
    }> = {
      'Signal_Entry_Quality': { 
        minBuyInput: 'MinQualityBuy', maxBuyInput: 'MaxQualityBuy',
        minSellInput: 'MinQualitySell', maxSellInput: 'MaxQualitySell',
        type: 'min_threshold' 
      },
      'Signal_Entry_PhysicsScore': { 
        minBuyInput: 'MinPhysicsScoreBuy', maxBuyInput: 'MaxPhysicsScoreBuy',
        minSellInput: 'MinPhysicsScoreSell', maxSellInput: 'MaxPhysicsScoreSell',
        type: 'min_threshold' 
      },
      'EA_Entry_Spread': { 
        minBuyInput: 'MinSpreadPipsBuy', maxBuyInput: 'MaxSpreadPipsBuy',
        minSellInput: 'MinSpreadPipsSell', maxSellInput: 'MaxSpreadPipsSell',
        type: 'max_threshold' 
      },
      'Signal_Entry_ConfluenceSlope': { 
        minBuyInput: 'MinConfluenceSlopeBuy', maxBuyInput: 'MaxConfluenceSlopeBuy',
        minSellInput: 'MinConfluenceSlopeSell', maxSellInput: 'MaxConfluenceSlopeSell',
        type: 'min_threshold' 
      },
      'Signal_Entry_Speed': { 
        minBuyInput: 'MinSpeedBuy', maxBuyInput: 'MaxSpeedBuy',
        minSellInput: 'MinSpeedSell', maxSellInput: 'MaxSpeedSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_Acceleration': { 
        minBuyInput: 'MinAccelerationBuy', maxBuyInput: 'MaxAccelerationBuy',
        minSellInput: 'MinAccelerationSell', maxSellInput: 'MaxAccelerationSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_Momentum': { 
        minBuyInput: 'MinMomentumBuy', maxBuyInput: 'MaxMomentumBuy',
        minSellInput: 'MinMomentumSell', maxSellInput: 'MaxMomentumSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_SpeedSlope': { 
        minBuyInput: 'MinSpeedSlopeBuy', maxBuyInput: 'MaxSpeedSlopeBuy',
        minSellInput: 'MinSpeedSlopeSell', maxSellInput: 'MaxSpeedSlopeSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_AccelerationSlope': { 
        minBuyInput: 'MinAccelerationSlopeBuy', maxBuyInput: 'MaxAccelerationSlopeBuy',
        minSellInput: 'MinAccelerationSlopeSell', maxSellInput: 'MaxAccelerationSlopeSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_MomentumSlope': { 
        minBuyInput: 'MinMomentumSlopeBuy', maxBuyInput: 'MaxMomentumSlopeBuy',
        minSellInput: 'MinMomentumSlopeSell', maxSellInput: 'MaxMomentumSlopeSell',
        type: 'range_buy_min_sell_max' 
      },
      'Signal_Entry_JerkSlope': { 
        minBuyInput: 'MinJerkSlopeBuy', maxBuyInput: 'MaxJerkSlopeBuy',
        minSellInput: 'MinJerkSlopeSell', maxSellInput: 'MaxJerkSlopeSell',
        type: 'range_buy_min_sell_max' 
      },
    };
    
    // Time Segment EA Mappings (shared for both directions since time applies to all)
    const TIME_SEGMENT_EA_MAPPINGS: Record<string, { 
      enableInput: string;
      minInput: string; 
      maxInput: string;
      segmentCount: number;
    }> = {
      'IN_Segment_15M_OP_01': { enableInput: 'UseSegment15M', minInput: 'Segment15M_Min', maxInput: 'Segment15M_Max', segmentCount: 96 },
      'IN_Segment_30M_OP_01': { enableInput: 'UseSegment30M', minInput: 'Segment30M_Min', maxInput: 'Segment30M_Max', segmentCount: 48 },
      'IN_Segment_01H_OP_01': { enableInput: 'UseSegment01H', minInput: 'Segment01H_Min', maxInput: 'Segment01H_Max', segmentCount: 24 },
      'IN_Segment_02H_OP_01': { enableInput: 'UseSegment02H', minInput: 'Segment02H_Min', maxInput: 'Segment02H_Max', segmentCount: 12 },
      'IN_Segment_03H_OP_01': { enableInput: 'UseSegment03H', minInput: 'Segment03H_Min', maxInput: 'Segment03H_Max', segmentCount: 8 },
      'IN_Segment_04H_OP_01': { enableInput: 'UseSegment04H', minInput: 'Segment04H_Min', maxInput: 'Segment04H_Max', segmentCount: 6 },
    };
    
    // Day of week mapping
    const DAY_MAPPING: Record<string, string> = {
      'Sunday': 'AllowSunday',
      'Monday': 'AllowMonday', 
      'Tuesday': 'AllowTuesday',
      'Wednesday': 'AllowWednesday',
      'Thursday': 'AllowThursday',
      'Friday': 'AllowFriday',
      'Saturday': 'AllowSaturday',
    };
    
    // Collect optimized values from enabled filters
    AVAILABLE_METRICS.forEach(m => {
      const mapping = EA_MAPPINGS[m.key];
      if (!mapping) return;
      
      // BUY filter (from longFilters)
      const buyFilter = longFilters.find(f => f.metric === m.key && f.enabled);
      if (buyFilter) {
        // Floor (Min) threshold
        if (mapping.type === 'max_threshold') {
          // For spread, the "min" in our filter is actually the max spread allowed
          if (buyFilter.max !== undefined) {
            optimizedValues.push({ name: mapping.maxBuyInput, value: buyFilter.max, comment: `${m.label} BUY max (spread ceiling)` });
          }
        } else {
          // Regular min threshold
          if (buyFilter.min !== undefined) {
            optimizedValues.push({ name: mapping.minBuyInput, value: buyFilter.min, comment: `${m.label} BUY min (floor)` });
          }
        }
        
        // Ceiling (Max) threshold - anti-spike protection
        if (buyFilter.useCeiling && buyFilter.ceilingMax !== undefined) {
          optimizedValues.push({ name: mapping.maxBuyInput, value: buyFilter.ceilingMax, comment: `${m.label} BUY max (ceiling)` });
        }
      }
      
      // SELL filter (from shortFilters)
      const sellFilter = shortFilters.find(f => f.metric === m.key && f.enabled);
      if (sellFilter) {
        if (mapping.type === 'range_buy_min_sell_max') {
          // For directional metrics, SELL uses the max value as floor (most negative)
          if (sellFilter.max !== undefined) {
            optimizedValues.push({ name: mapping.minSellInput, value: sellFilter.max, comment: `${m.label} SELL min (floor, negative)` });
          }
          // Ceiling for SELL (most negative limit - anti-spike)
          if (sellFilter.useCeiling && sellFilter.ceilingMin !== undefined) {
            optimizedValues.push({ name: mapping.maxSellInput, value: sellFilter.ceilingMin, comment: `${m.label} SELL max (ceiling, negative)` });
          }
        } else if (mapping.type === 'max_threshold') {
          if (sellFilter.max !== undefined) {
            optimizedValues.push({ name: mapping.maxSellInput, value: sellFilter.max, comment: `${m.label} SELL max` });
          }
        } else {
          if (sellFilter.min !== undefined) {
            optimizedValues.push({ name: mapping.minSellInput, value: sellFilter.min, comment: `${m.label} SELL min (floor)` });
          }
          if (sellFilter.useCeiling && sellFilter.ceilingMax !== undefined) {
            optimizedValues.push({ name: mapping.maxSellInput, value: sellFilter.ceilingMax, comment: `${m.label} SELL max (ceiling)` });
          }
        }
      }
    });
    
    // Check for Zone filter (AvoidTransitionZone)
    const zoneFilter = longFilters.find(f => f.metric === 'Signal_Entry_Zone' && f.enabled) ||
                       shortFilters.find(f => f.metric === 'Signal_Entry_Zone' && f.enabled);
    
    if (zoneFilter && zoneFilter.selectedValues) {
      const avoidsTransition = !zoneFilter.selectedValues.includes('Transition') && !zoneFilter.selectedValues.includes('Avoid');
      optimizedValues.push({ name: 'AvoidTransitionZone', value: avoidsTransition ? 1 : 0, comment: 'Zone filter' });
    }
    
    // Time Segment Filters (check both long and short, use allFilters for shared filters)
    const allFiltersList = [...longFilters, ...shortFilters, ...allFilters];
    
    // Day of Week filter
    const dayFilter = allFiltersList.find(f => f.metric === 'IN_CST_Day_OP_01' && f.enabled);
    if (dayFilter && dayFilter.selectedValues) {
      optimizedValues.push({ name: 'UseDayFilter', value: 1, comment: 'Enable day filter' });
      const allDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      allDays.forEach(day => {
        const allowed = dayFilter.selectedValues?.includes(day) ? 1 : 0;
        optimizedValues.push({ name: DAY_MAPPING[day], value: allowed, comment: `Allow ${day}` });
      });
    }
    
    // Time Segment range filters
    Object.entries(TIME_SEGMENT_EA_MAPPINGS).forEach(([metricKey, mapping]) => {
      const segmentFilter = allFiltersList.find(f => f.metric === metricKey && f.enabled);
      if (segmentFilter && segmentFilter.min !== undefined && segmentFilter.max !== undefined) {
        optimizedValues.push({ name: mapping.enableInput, value: 1, comment: `Enable ${metricKey} filter` });
        optimizedValues.push({ name: mapping.minInput, value: segmentFilter.min, comment: `Min segment (1-${mapping.segmentCount})` });
        optimizedValues.push({ name: mapping.maxInput, value: segmentFilter.max, comment: `Max segment (1-${mapping.segmentCount})` });
      }
    });
    
    // If no optimizations, show message
    if (optimizedValues.length === 0) {
      return `// No filter optimizations applied yet.\n// Enable filters and adjust values, then copy this output.\n`;
    }
    
    // Build simple output - just the changed values
    let code = `// === OPTIMIZED FILTER VALUES ===\n`;
    code += `// EA: v${eaVersion || 'Unknown'} | Generated: ${new Date().toLocaleString()}\n`;
    code += `// Stats: Net $${formatDollar(combinedStats.netProfit)} | WR ${combinedStats.winRate.toFixed(1)}% | Trades: ${combinedStats.totalTrades}\n`;
    code += `// Copy this list and paste to Claude to update the EA\n\n`;
    
    for (const opt of optimizedValues) {
      const valueStr = typeof opt.value === 'boolean' 
        ? (opt.value ? 'true' : 'false')
        : opt.value.toFixed(2);
      code += `${opt.name} = ${valueStr}\n`;
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
            {/* Optimize All Entry Button */}
            <Button 
              variant="outline" 
              onClick={handleOptimizeAllEntry}
              disabled={isOptimizing || direction === 'All'}
              className={`gap-2 h-9 px-3 ${
                direction === 'All' 
                  ? 'border-zinc-700 text-zinc-500 cursor-not-allowed' 
                  : 'border-emerald-500/50 hover:bg-emerald-500/10 text-emerald-500'
              }`}
              title="Optimize all entry metrics automatically"
            >
              {isOptimizing && optimizeProgress?.metric.includes('Entry') 
                ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current" /> 
                : <Zap className="h-4 w-4" />}
              <span className="hidden sm:inline">⚡ Entry</span>
            </Button>

            {/* Optimize All Exit Button */}
            <Button 
              variant="outline" 
              onClick={handleOptimizeAllExit}
              disabled={isOptimizing || direction === 'All'}
              className={`gap-2 h-9 px-3 ${
                direction === 'All' 
                  ? 'border-zinc-700 text-zinc-500 cursor-not-allowed' 
                  : 'border-orange-500/50 hover:bg-orange-500/10 text-orange-500'
              }`}
              title="Optimize all exit metrics automatically"
            >
              {isOptimizing && optimizeProgress?.metric.includes('Exit') 
                ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current" /> 
                : <LogOut className="h-4 w-4" />}
              <span className="hidden sm:inline">📤 Exit</span>
            </Button>

            {/* Original Auto-Tune All (for existing filters) */}
            <Button 
              variant="outline" 
              onClick={handleGlobalOptimization}
              disabled={isOptimizing || filters.length === 0 || direction === 'All'}
              className={`gap-2 h-9 px-3 ${
                direction === 'All' 
                  ? 'border-zinc-700 text-zinc-500 cursor-not-allowed' 
                  : 'border-purple-500/50 hover:bg-purple-500/10 text-purple-500'
              }`}
              title="Auto-tune existing filters"
            >
              {isOptimizing ? <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current" /> : <Wand2 className="h-4 w-4" />}
              <span className="hidden sm:inline">Tune</span>
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

        {/* Progress Indicator for Optimize All */}
        {optimizeProgress && (
          <div className="mx-6 mb-2 p-3 bg-zinc-900/50 border border-zinc-700 rounded-lg">
            <div className="flex items-center justify-between text-sm">
              <span className="text-zinc-400">
                Optimizing: <span className="text-white font-medium">{optimizeProgress.metric}</span>
              </span>
              <span className="text-zinc-500">
                {optimizeProgress.current} / {optimizeProgress.total}
              </span>
            </div>
            <div className="mt-2 h-1.5 bg-zinc-800 rounded-full overflow-hidden">
              <div 
                className="h-full bg-gradient-to-r from-emerald-500 to-blue-500 transition-all duration-300"
                style={{ width: `${(optimizeProgress.current / optimizeProgress.total) * 100}%` }}
              />
            </div>
          </div>
        )}

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

                  // Check if this is an Entry metric that supports ceiling filters
                  const isEntryMetric = filter.metric.toString().includes('Entry_') && 
                    !['Signal_Entry_Zone', 'Signal_Entry_Regime'].includes(filter.metric.toString());

                  return (
                    <div key={idx} className="bg-card border rounded-lg p-3 shadow-sm">
                      <div className="flex items-center gap-3">
                        <div className="w-28 font-medium text-sm">{label}</div>
                        
                        <div className="flex-1 space-y-2">
                          {/* Floor (Min) Threshold Row */}
                          <div className="flex items-center gap-2">
                            <span className="text-xs text-green-400 w-12">Min ≥</span>
                            <input 
                              type="number" 
                              value={filter.min}
                              onChange={(e) => updateFilter(idx, { min: parseFloat(e.target.value) })}
                              className="w-20 bg-background border border-green-500/30 rounded px-2 py-1 text-xs font-mono"
                              placeholder="Floor"
                            />
                            <span className="text-xs text-muted-foreground">to</span>
                            <input 
                              type="number" 
                              value={filter.max}
                              onChange={(e) => updateFilter(idx, { max: parseFloat(e.target.value) })}
                              className="w-20 bg-background border rounded px-2 py-1 text-xs font-mono"
                            />
                            <span className="text-[10px] text-muted-foreground">(range)</span>
                          </div>
                          
                          {/* Ceiling (Max) Threshold Row - Only for Entry metrics */}
                          {isEntryMetric && (
                            <div className="flex items-center gap-2">
                              <label className="flex items-center gap-1 cursor-pointer hover:bg-orange-500/10 rounded px-1 py-0.5">
                                <input 
                                  type="checkbox"
                                  checked={filter.useCeiling || false}
                                  onChange={(e) => updateFilter(idx, { useCeiling: e.target.checked })}
                                  className="w-4 h-4 accent-orange-500 cursor-pointer"
                                />
                                <span className="text-xs text-orange-400 w-10">Max ≤</span>
                              </label>
                              <input 
                                type="number" 
                                value={filter.ceilingMax ?? 99999}
                                onChange={(e) => updateFilter(idx, { ceilingMax: parseFloat(e.target.value) })}
                                disabled={!filter.useCeiling}
                                className={`w-20 bg-background border rounded px-2 py-1 text-xs font-mono ${
                                  filter.useCeiling ? 'border-orange-500/30' : 'opacity-40'
                                }`}
                                placeholder="Ceiling"
                              />
                              <span className="text-[10px] text-orange-400/70">
                                {filter.useCeiling ? '🛡️ Anti-spike' : '(disabled)'}
                              </span>
                            </div>
                          )}
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
