import { Trade } from '../types';

// Pearson Correlation Coefficient
export function calculateCorrelation(x: number[], y: number[]): number {
  const n = x.length;
  if (n !== y.length || n === 0) return 0;

  const sumX = x.reduce((a, b) => a + b, 0);
  const sumY = y.reduce((a, b) => a + b, 0);
  const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
  const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0);
  const sumY2 = y.reduce((sum, yi) => sum + yi * yi, 0);

  const numerator = n * sumXY - sumX * sumY;
  const denominator = Math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

  if (denominator === 0) return 0;
  return numerator / denominator;
}

export interface Pattern {
  id: string;
  metric: string;
  condition: string; // e.g., "< -5.0"
  range: [number, number];
  winRate: number;
  totalTrades: number;
  netProfit: number;
  type: 'bullish' | 'bearish' | 'neutral'; // bullish = high win rate, bearish = high loss rate
  confidence: number; // simple score based on sample size and extremity
}

export interface ConfluencePattern {
  id: string;
  metrics: {
    metric: string;
    condition: string;
    range: [number, number];
  }[];
  winRate: number;
  totalTrades: number;
  netProfit: number;
  confidence: number;
}

export interface OptimizationFilter {
  metric: keyof Trade;
  min?: number;
  max?: number;
  type?: 'numeric' | 'categorical';
  selectedValues?: string[];
  enabled: boolean;
}

export interface OptimizationResult {
  totalTrades: number;
  winRate: number;
  netProfit: number;
  profitFactor: number;
  trades: Trade[];
}

// Discretize and find patterns
export function findPatterns(trades: Trade[]): Pattern[] {
  const metrics: (keyof Trade)[] = [
    'EA_Entry_Spread',
    'EA_Entry_ConfluenceSlope',
    'EA_Entry_PhysicsScore',
    'EA_Entry_Speed',
    'EA_Entry_Acceleration',
    'EA_Entry_Momentum'
  ];

  const patterns: Pattern[] = [];
  const minTrades = 20; // Minimum sample size to be significant

  metrics.forEach(metric => {
    // Extract values
    const values = trades.map(t => t[metric] as number).filter(v => !isNaN(v));
    if (values.length === 0) return;

    const min = Math.min(...values);
    const max = Math.max(...values);
    const step = (max - min) / 10; // 10 bins

    // Analyze bins
    for (let i = 0; i < 10; i++) {
      const lower = min + (i * step);
      const upper = min + ((i + 1) * step);
      
      const binTrades = trades.filter(t => {
        const val = t[metric] as number;
        return val >= lower && val < upper;
      });

      if (binTrades.length < minTrades) continue;

      const wins = binTrades.filter(t => t.NetProfit > 0).length;
      const winRate = (wins / binTrades.length) * 100;
      const netProfit = binTrades.reduce((sum, t) => sum + t.NetProfit, 0);

      // Identify significant patterns (High Win Rate or High Loss Rate)
      // Global win rate is ~26%, so "High" is relative.
      // Let's say "High Loss" is < 15% WR, "High Win" is > 40% WR (for this strategy)
      
      let type: Pattern['type'] = 'neutral';
      if (winRate < 15) type = 'bearish'; // Avoid this!
      if (winRate > 40) type = 'bullish'; // Do this!

      if (type !== 'neutral') {
        patterns.push({
          id: `${metric}_${i}`,
          metric: metric.replace('EA_Entry_', ''),
          condition: `${lower.toFixed(2)} to ${upper.toFixed(2)}`,
          range: [lower, upper],
          winRate,
          totalTrades: binTrades.length,
          netProfit,
          type,
          confidence: binTrades.length * Math.abs(winRate - 26) // Weight by deviation from mean
        });
      }
    }
  });

  // Sort by "significance" (confidence)
  return patterns.sort((a, b) => b.confidence - a.confidence);
}

export function findConfluencePatterns(trades: Trade[]): ConfluencePattern[] {
  const metrics: (keyof Trade)[] = [
    'EA_Entry_PhysicsScore',
    'EA_Entry_ConfluenceSlope',
    'EA_Entry_Spread'
  ];

  const patterns: ConfluencePattern[] = [];
  const minTrades = 10; // Lower threshold for combinations

  // Helper to get ranges
  const getRanges = (metric: keyof Trade) => {
    const values = trades.map(t => t[metric] as number).filter(v => !isNaN(v));
    if (values.length === 0) return [];
    const min = Math.min(...values);
    const max = Math.max(...values);
    const step = (max - min) / 5; // Coarser bins for combinations (5 bins)
    const ranges = [];
    for (let i = 0; i < 5; i++) {
      ranges.push({
        min: min + (i * step),
        max: min + ((i + 1) * step)
      });
    }
    return ranges;
  };

  const scoreRanges = getRanges('EA_Entry_PhysicsScore');
  const slopeRanges = getRanges('EA_Entry_ConfluenceSlope');

  // Iterate combinations of Score + Slope (Primary Confluence)
  scoreRanges.forEach((scoreRange, sIdx) => {
    slopeRanges.forEach((slopeRange, slIdx) => {
      const binTrades = trades.filter(t => {
        const score = t.EA_Entry_PhysicsScore;
        const slope = t.EA_Entry_ConfluenceSlope;
        return score >= scoreRange.min && score < scoreRange.max &&
               slope >= slopeRange.min && slope < slopeRange.max;
      });

      if (binTrades.length < minTrades) return;

      const wins = binTrades.filter(t => t.NetProfit > 0).length;
      const winRate = (wins / binTrades.length) * 100;
      const netProfit = binTrades.reduce((sum, t) => sum + t.NetProfit, 0);

      // We are looking for "Holy Grail" patterns (High Win Rate)
      if (winRate > 50 || winRate < 10) {
        patterns.push({
          id: `conf_${sIdx}_${slIdx}`,
          metrics: [
            {
              metric: 'PhysicsScore',
              condition: `${scoreRange.min.toFixed(1)} - ${scoreRange.max.toFixed(1)}`,
              range: [scoreRange.min, scoreRange.max]
            },
            {
              metric: 'ConfluenceSlope',
              condition: `${slopeRange.min.toFixed(1)} - ${slopeRange.max.toFixed(1)}`,
              range: [slopeRange.min, slopeRange.max]
            }
          ],
          winRate,
          totalTrades: binTrades.length,
          netProfit,
          confidence: binTrades.length * Math.abs(winRate - 26)
        });
      }
    });
  });

  return patterns.sort((a, b) => b.winRate - a.winRate);
}

export function findDynamicPatterns(
  trades: Trade[], 
  metricA: keyof Trade, 
  metricB: keyof Trade,
  minTrades: number = 10
): ConfluencePattern[] {
  const patterns: ConfluencePattern[] = [];

  // Helper to get ranges
  const getRanges = (metric: keyof Trade) => {
    const values = trades.map(t => t[metric] as number).filter(v => !isNaN(v));
    if (values.length === 0) return [];
    const min = Math.min(...values);
    const max = Math.max(...values);
    
    // If values are all 0 (like Entropy currently), return single range
    if (min === max) return [{ min, max }];

    const step = (max - min) / 5; // 5 bins
    const ranges = [];
    for (let i = 0; i < 5; i++) {
      ranges.push({
        min: min + (i * step),
        max: min + ((i + 1) * step)
      });
    }
    return ranges;
  };

  const rangesA = getRanges(metricA);
  const rangesB = getRanges(metricB);

  // Iterate combinations
  rangesA.forEach((rangeA, idxA) => {
    rangesB.forEach((rangeB, idxB) => {
      const binTrades = trades.filter(t => {
        const valA = t[metricA] as number;
        const valB = t[metricB] as number;
        return valA >= rangeA.min && valA < rangeA.max &&
               valB >= rangeB.min && valB < rangeB.max;
      });

      if (binTrades.length < minTrades) return;

      const wins = binTrades.filter(t => t.NetProfit > 0).length;
      const winRate = (wins / binTrades.length) * 100;
      const netProfit = binTrades.reduce((sum, t) => sum + t.NetProfit, 0);

      patterns.push({
        id: `dyn_${idxA}_${idxB}`,
        metrics: [
          {
            metric: metricA.replace('EA_Entry_', ''),
            condition: `${rangeA.min.toFixed(2)} - ${rangeA.max.toFixed(2)}`,
            range: [rangeA.min, rangeA.max]
          },
          {
            metric: metricB.replace('EA_Entry_', ''),
            condition: `${rangeB.min.toFixed(2)} - ${rangeB.max.toFixed(2)}`,
            range: [rangeB.min, rangeB.max]
          }
        ],
        winRate,
        totalTrades: binTrades.length,
        netProfit,
        confidence: binTrades.length * Math.abs(winRate - 26)
      });
    });
  });

  return patterns.sort((a, b) => b.winRate - a.winRate);
}

export function optimizeStrategy(
  trades: Trade[],
  direction: 'Long' | 'Short' | 'All',
  filters: OptimizationFilter[]
): OptimizationResult {
  // 1. Filter by Direction
  let filtered = trades.filter(t => {
    if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
    if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
    return true;
  });

  // 2. Apply Metric Filters
  filters.forEach(filter => {
    if (filter.enabled) {
      if (filter.type === 'categorical' && filter.selectedValues) {
        filtered = filtered.filter(t => {
          const val = String(t[filter.metric]);
          return filter.selectedValues!.includes(val);
        });
      } else if (filter.min !== undefined && filter.max !== undefined) {
        filtered = filtered.filter(t => {
          const val = t[filter.metric] as number;
          return val >= filter.min! && val <= filter.max!;
        });
      }
    }
  });

  // 3. Calculate Stats
  const wins = filtered.filter(t => t.NetProfit > 0);
  const losses = filtered.filter(t => t.NetProfit <= 0);
  const totalTrades = filtered.length;
  const winRate = totalTrades > 0 ? (wins.length / totalTrades) * 100 : 0;
  const netProfit = filtered.reduce((sum, t) => sum + t.NetProfit, 0);
  
  const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0);
  const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0));
  const profitFactor = grossLoss === 0 ? grossProfit : grossProfit / grossLoss;

  return {
    totalTrades,
    winRate,
    netProfit,
    profitFactor,
    trades: filtered
  };
}

// Helper to find "Best Range" for a single metric given current context
export function findBestRange(
  currentTrades: Trade[],
  metric: keyof Trade
): { min: number, max: number, winRate: number } | null {
  if (currentTrades.length < 10) return null;

  const values = currentTrades.map(t => t[metric] as number).filter(v => !isNaN(v));
  if (values.length === 0) return null;

  const min = Math.min(...values);
  const max = Math.max(...values);
  
  // Simple optimization: Try deciles and find the contiguous range with best WR
  // This is a simplified version; a real optimizer would be more complex.
  // For now, let's just split into 4 quartiles and pick the best one to suggest.
  
  const step = (max - min) / 4;
  let bestRange = { min, max, winRate: 0 };

  for (let i = 0; i < 4; i++) {
    const lower = min + (i * step);
    const upper = min + ((i + 1) * step);
    
    const binTrades = currentTrades.filter(t => {
      const val = t[metric] as number;
      return val >= lower && val <= upper;
    });

    if (binTrades.length < 5) continue;

    const wins = binTrades.filter(t => t.NetProfit > 0).length;
    const wr = (wins / binTrades.length) * 100;

    if (wr > bestRange.winRate) {
      bestRange = { min: lower, max: upper, winRate: wr };
    }
  }

  return bestRange.winRate > 0 ? bestRange : null;
}

// Helper to generate power set for categorical optimization
function getSubsets<T>(array: T[]): T[][] {
  return array.reduce(
    (subsets, value) => subsets.concat(subsets.map(set => [value, ...set])),
    [[]] as T[][]
  ).filter(s => s.length > 0);
}

export function findBestConfiguration(
  currentTrades: Trade[],
  metric: keyof Trade,
  type: 'numeric' | 'categorical'
): { min?: number, max?: number, selectedValues?: string[], netProfit: number } | null {
  if (currentTrades.length < 5) return null;

  if (type === 'categorical') {
    const values = Array.from(new Set(currentTrades.map(t => String(t[metric]))));
    // Limit to 10 values to prevent performance issues with power set (2^10 = 1024 iterations)
    if (values.length > 10) return null;

    const subsets = getSubsets(values);
    
    let bestSubset = { selectedValues: [] as string[], netProfit: -Infinity };

    subsets.forEach(subset => {
      const subsetTrades = currentTrades.filter(t => subset.includes(String(t[metric])));
      if (subsetTrades.length < 3) return; // Min sample size

      const netProfit = subsetTrades.reduce((sum, t) => sum + t.NetProfit, 0);
      if (netProfit > bestSubset.netProfit) {
        bestSubset = { selectedValues: subset, netProfit };
      }
    });

    return bestSubset.netProfit > -Infinity ? bestSubset : null;
  } else {
    // Numeric optimization
    const values = currentTrades.map(t => t[metric] as number).filter(v => !isNaN(v));
    if (values.length === 0) return null;

    const min = Math.min(...values);
    const max = Math.max(...values);
    
    // Create 20 bins for finer granularity
    const bins = 20;
    const step = (max - min) / bins;
    
    // Pre-calculate stats for each bin to avoid repeated filtering
    const binStats = [];
    for (let i = 0; i < bins; i++) {
      const lower = min + (i * step);
      const upper = min + ((i + 1) * step);
      // For the last bin, include the max value
      const isLast = i === bins - 1;
      
      const tradesInBin = currentTrades.filter(t => {
        const val = t[metric] as number;
        return val >= lower && (isLast ? val <= upper : val < upper);
      });
      
      binStats.push({
        lower,
        upper,
        trades: tradesInBin,
        netProfit: tradesInBin.reduce((sum, t) => sum + t.NetProfit, 0)
      });
    }

    let bestRange = { min, max, netProfit: -Infinity };

    // Check all contiguous ranges of bins
    for (let start = 0; start < bins; start++) {
      let currentProfit = 0;
      let currentTradesCount = 0;
      
      for (let end = start; end < bins; end++) {
        currentProfit += binStats[end].netProfit;
        currentTradesCount += binStats[end].trades.length;
        
        if (currentTradesCount < 5) continue; // Min sample size

        if (currentProfit > bestRange.netProfit) {
          bestRange = {
            min: binStats[start].lower,
            max: binStats[end].upper,
            netProfit: currentProfit
          };
        }
      }
    }

    return bestRange.netProfit > -Infinity ? bestRange : null;
  }
}
