import { useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  ScatterChart, Scatter, Cell, ReferenceLine,
  ComposedChart, Area, Line
} from 'recharts';
import { TrendingUp, TrendingDown, Target, Clock, ArrowUpRight, ArrowDownRight, Gauge, AlertTriangle } from 'lucide-react';

interface ExcursionAnalysisProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

// Format dollar amounts with commas, no decimals
const formatDollar = (value: number): string => {
  return Math.round(value).toLocaleString('en-US');
};

export function ExcursionAnalysis({ trades, direction }: ExcursionAnalysisProps) {
  // Filter trades by direction
  const filteredTrades = useMemo(() => {
    if (direction === 'All') return trades;
    return trades.filter(t => t.Trade_Direction === direction);
  }, [trades, direction]);

  // === 1. Exit Reason Performance ===
  const exitReasonStats = useMemo(() => {
    const byReason: Record<string, { trades: Trade[]; totalProfit: number; wins: number; losses: number }> = {};
    
    filteredTrades.forEach(trade => {
      const reason = trade.EA_ExitReason || 'Unknown';
      if (!byReason[reason]) {
        byReason[reason] = { trades: [], totalProfit: 0, wins: 0, losses: 0 };
      }
      byReason[reason].trades.push(trade);
      byReason[reason].totalProfit += trade.NetProfit;
      if (trade.Trade_Result === 'WIN') {
        byReason[reason].wins++;
      } else {
        byReason[reason].losses++;
      }
    });

    return Object.entries(byReason).map(([reason, data]) => ({
      reason,
      count: data.trades.length,
      totalProfit: data.totalProfit,
      avgProfit: data.totalProfit / data.trades.length,
      winRate: (data.wins / data.trades.length) * 100,
      wins: data.wins,
      losses: data.losses,
      avgMFE: data.trades.reduce((sum, t) => sum + (t.EA_MFE_Pips || 0), 0) / data.trades.length,
      avgMAE: data.trades.reduce((sum, t) => sum + Math.abs(t.EA_MAE_Pips || 0), 0) / data.trades.length,
      avgMFEUtilization: data.trades.reduce((sum, t) => sum + (t.EA_MFEUtilization || 0), 0) / data.trades.length,
    })).sort((a, b) => b.count - a.count);
  }, [filteredTrades]);

  // === 2. MFE/MAE Distribution ===
  const mfeDistribution = useMemo(() => {
    const buckets: Record<string, { mfe: number; mae: number; count: number }> = {};
    const bucketSize = 20; // 20 pip buckets
    
    filteredTrades.forEach(trade => {
      const mfe = trade.EA_MFE_Pips || 0;
      const mae = Math.abs(trade.EA_MAE_Pips || 0);
      const mfeBucket = Math.floor(mfe / bucketSize) * bucketSize;
      const key = `${mfeBucket}`;
      
      if (!buckets[key]) {
        buckets[key] = { mfe: mfeBucket, mae: 0, count: 0 };
      }
      buckets[key].mae += mae;
      buckets[key].count++;
    });

    // Calculate average MAE per MFE bucket
    return Object.values(buckets)
      .map(b => ({
        mfe: b.mfe,
        avgMae: b.mae / b.count,
        count: b.count,
        label: `${b.mfe}-${b.mfe + bucketSize}`
      }))
      .sort((a, b) => a.mfe - b.mfe);
  }, [filteredTrades]);

  const mfeHistogram = useMemo(() => {
    const buckets: Record<number, number> = {};
    const bucketSize = 10;
    
    filteredTrades.forEach(trade => {
      const mfe = Math.floor((trade.EA_MFE_Pips || 0) / bucketSize) * bucketSize;
      buckets[mfe] = (buckets[mfe] || 0) + 1;
    });

    return Object.entries(buckets)
      .map(([mfe, count]) => ({ mfe: parseInt(mfe), count }))
      .sort((a, b) => a.mfe - b.mfe);
  }, [filteredTrades]);

  const maeHistogram = useMemo(() => {
    const buckets: Record<number, number> = {};
    const bucketSize = 10;
    
    filteredTrades.forEach(trade => {
      const mae = Math.floor(Math.abs(trade.EA_MAE_Pips || 0) / bucketSize) * bucketSize;
      buckets[mae] = (buckets[mae] || 0) + 1;
    });

    return Object.entries(buckets)
      .map(([mae, count]) => ({ mae: parseInt(mae), count }))
      .sort((a, b) => a.mae - b.mae);
  }, [filteredTrades]);

  // === 3. Optimal TP/SL Finder ===
  const optimalLevels = useMemo(() => {
    if (filteredTrades.length === 0) return null;

    const mfeValues = filteredTrades.map(t => t.EA_MFE_Pips || 0).sort((a, b) => a - b);
    const maeValues = filteredTrades.map(t => Math.abs(t.EA_MAE_Pips || 0)).sort((a, b) => a - b);

    // Calculate percentiles
    const getPercentile = (arr: number[], p: number) => {
      const idx = Math.floor(arr.length * p);
      return arr[idx] || 0;
    };

    // Simulate different TP levels
    const tpSimulations = [20, 30, 40, 50, 60, 80, 100, 120, 150].map(tp => {
      let wins = 0;
      let totalProfit = 0;
      
      filteredTrades.forEach(trade => {
        const mfe = trade.EA_MFE_Pips || 0;
        const mae = Math.abs(trade.EA_MAE_Pips || 0);
        const currentSL = 50; // Assume 50 pip SL for simulation
        
        if (mfe >= tp) {
          // Would have hit TP
          wins++;
          totalProfit += tp; // Simplified - actual would depend on lot size
        } else if (mae >= currentSL) {
          // Would have hit SL
          totalProfit -= currentSL;
        } else {
          // Exited at actual profit
          totalProfit += trade.NetProfit > 0 ? mfe * 0.5 : -mae * 0.5;
        }
      });

      return {
        tp,
        winRate: (wins / filteredTrades.length) * 100,
        expectedProfit: totalProfit / filteredTrades.length,
        hitsTP: wins
      };
    });

    // Simulate different SL levels
    const slSimulations = [20, 30, 40, 50, 60, 80, 100].map(sl => {
      let stopped = 0;
      let survivors = 0;
      
      filteredTrades.forEach(trade => {
        const mae = Math.abs(trade.EA_MAE_Pips || 0);
        if (mae >= sl) {
          stopped++;
        } else {
          survivors++;
        }
      });

      return {
        sl,
        stopRate: (stopped / filteredTrades.length) * 100,
        survivalRate: (survivors / filteredTrades.length) * 100,
        stopped,
        survivors
      };
    });

    return {
      avgMFE: mfeValues.reduce((a, b) => a + b, 0) / mfeValues.length,
      avgMAE: maeValues.reduce((a, b) => a + b, 0) / maeValues.length,
      medianMFE: getPercentile(mfeValues, 0.5),
      medianMAE: getPercentile(maeValues, 0.5),
      mfe75: getPercentile(mfeValues, 0.75),
      mfe90: getPercentile(mfeValues, 0.90),
      mae75: getPercentile(maeValues, 0.75),
      mae90: getPercentile(maeValues, 0.90),
      tpSimulations,
      slSimulations,
      // Recommended based on 75th percentile
      recommendedTP: Math.round(getPercentile(mfeValues, 0.6)),
      recommendedSL: Math.round(getPercentile(maeValues, 0.85)),
    };
  }, [filteredTrades]);

  // === 4. Post-Exit Analysis ===
  const postExitData = useMemo(() => {
    const tradesWithRunUp = filteredTrades.filter(t => 
      t.EA_RunUp_Pips !== undefined && t.EA_RunUp_Pips !== null
    );

    if (tradesWithRunUp.length === 0) return null;

    const scatterData = tradesWithRunUp.map(trade => ({
      profit: trade.NetProfit,
      runUp: trade.EA_RunUp_Pips || 0,
      runDown: Math.abs(trade.EA_RunDown_Pips || 0),
      opportunityCost: trade.EA_EarlyExitOpportunityCost || 0,
      mfeUtilization: trade.EA_MFEUtilization || 0,
      result: trade.Trade_Result,
      direction: trade.Trade_Direction,
    }));

    // Calculate stats
    const avgRunUp = tradesWithRunUp.reduce((sum, t) => sum + (t.EA_RunUp_Pips || 0), 0) / tradesWithRunUp.length;
    const avgRunDown = tradesWithRunUp.reduce((sum, t) => sum + Math.abs(t.EA_RunDown_Pips || 0), 0) / tradesWithRunUp.length;
    const avgOpportunityCost = tradesWithRunUp.reduce((sum, t) => sum + (t.EA_EarlyExitOpportunityCost || 0), 0) / tradesWithRunUp.length;
    
    // Trades where we left money on table (positive RunUp after exit)
    const earlyExits = tradesWithRunUp.filter(t => (t.EA_RunUp_Pips || 0) > 10);
    const savedByExit = tradesWithRunUp.filter(t => Math.abs(t.EA_RunDown_Pips || 0) > 30);

    return {
      scatterData,
      avgRunUp,
      avgRunDown,
      avgOpportunityCost,
      earlyExitCount: earlyExits.length,
      earlyExitPercent: (earlyExits.length / tradesWithRunUp.length) * 100,
      savedByExitCount: savedByExit.length,
      savedByExitPercent: (savedByExit.length / tradesWithRunUp.length) * 100,
      totalTrades: tradesWithRunUp.length,
    };
  }, [filteredTrades]);

  // Average MFE Utilization
  const avgMFEUtilization = useMemo(() => {
    const withUtil = filteredTrades.filter(t => t.EA_MFEUtilization !== undefined);
    if (withUtil.length === 0) return 0;
    return withUtil.reduce((sum, t) => sum + (t.EA_MFEUtilization || 0), 0) / withUtil.length;
  }, [filteredTrades]);

  if (filteredTrades.length === 0) {
    return (
      <div className="text-center py-12 text-muted-foreground">
        <AlertTriangle className="h-12 w-12 mx-auto mb-4 opacity-50" />
        <p>No trades available for excursion analysis.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards Row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardContent className="pt-4">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <TrendingUp className="h-4 w-4 text-green-500" />
              <span className="text-xs">Avg MFE</span>
            </div>
            <div className="text-2xl font-bold text-green-500">
              {optimalLevels?.avgMFE.toFixed(1)} <span className="text-sm font-normal">pips</span>
            </div>
            <div className="text-xs text-muted-foreground mt-1">
              Median: {optimalLevels?.medianMFE.toFixed(1)} pips
            </div>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardContent className="pt-4">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <TrendingDown className="h-4 w-4 text-red-500" />
              <span className="text-xs">Avg MAE</span>
            </div>
            <div className="text-2xl font-bold text-red-500">
              {optimalLevels?.avgMAE.toFixed(1)} <span className="text-sm font-normal">pips</span>
            </div>
            <div className="text-xs text-muted-foreground mt-1">
              Median: {optimalLevels?.medianMAE.toFixed(1)} pips
            </div>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardContent className="pt-4">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <Gauge className="h-4 w-4 text-blue-500" />
              <span className="text-xs">MFE Utilization</span>
            </div>
            <div className="text-2xl font-bold text-blue-500">
              {avgMFEUtilization.toFixed(1)}<span className="text-sm font-normal">%</span>
            </div>
            <div className="text-xs text-muted-foreground mt-1">
              Of available move captured
            </div>
          </CardContent>
        </Card>

        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardContent className="pt-4">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <Target className="h-4 w-4 text-yellow-500" />
              <span className="text-xs">Recommended TP/SL</span>
            </div>
            <div className="text-lg font-bold">
              <span className="text-green-500">{optimalLevels?.recommendedTP}</span>
              <span className="text-muted-foreground mx-1">/</span>
              <span className="text-red-500">{optimalLevels?.recommendedSL}</span>
              <span className="text-sm font-normal text-muted-foreground"> pips</span>
            </div>
            <div className="text-xs text-muted-foreground mt-1">
              Based on MFE/MAE distribution
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Row 1: Exit Reason Performance + MFE/MAE Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Exit Reason Performance */}
        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <ArrowUpRight className="h-5 w-5 text-primary" />
              Exit Reason Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {exitReasonStats.map((stat, idx) => (
                <div key={stat.reason} className="flex items-center justify-between p-3 bg-zinc-800/50 rounded-lg">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full ${
                        stat.reason.includes('TP') || stat.reason.includes('TakeProfit') ? 'bg-green-500' :
                        stat.reason.includes('SL') || stat.reason.includes('StopLoss') ? 'bg-red-500' :
                        stat.reason.includes('Strategy') ? 'bg-blue-500' :
                        'bg-yellow-500'
                      }`} />
                      <span className="font-medium">{stat.reason}</span>
                      <span className="text-xs text-muted-foreground">({stat.count} trades)</span>
                    </div>
                    <div className="flex gap-4 mt-1 text-xs text-muted-foreground">
                      <span>Win Rate: <span className={stat.winRate >= 50 ? 'text-green-400' : 'text-red-400'}>{stat.winRate.toFixed(1)}%</span></span>
                      <span>Avg MFE: <span className="text-green-400">{stat.avgMFE.toFixed(1)}</span></span>
                      <span>Avg MAE: <span className="text-red-400">{stat.avgMAE.toFixed(1)}</span></span>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className={`text-lg font-bold ${stat.totalProfit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                      ${formatDollar(stat.totalProfit)}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      Avg: ${formatDollar(stat.avgProfit)}
                    </div>
                  </div>
                </div>
              ))}
              {exitReasonStats.length === 0 && (
                <div className="text-center py-4 text-muted-foreground">
                  No exit reason data available
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* MFE/MAE Distribution */}
        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-500" />
              MFE Distribution
              <span className="text-xs font-normal text-muted-foreground ml-2">(Max Favorable Excursion)</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={mfeHistogram}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                  <XAxis dataKey="mfe" stroke="#888" fontSize={10} tickFormatter={(v) => `${v}`} />
                  <YAxis stroke="#888" fontSize={10} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                    formatter={(value: number) => [value, 'Trades']}
                    labelFormatter={(label) => `${label}-${parseInt(label) + 10} pips`}
                  />
                  <Bar dataKey="count" fill="#22c55e" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 grid grid-cols-3 gap-2 text-center text-xs">
              <div className="p-2 bg-zinc-800/50 rounded">
                <div className="text-muted-foreground">75th Percentile</div>
                <div className="font-bold text-green-400">{optimalLevels?.mfe75.toFixed(0)} pips</div>
              </div>
              <div className="p-2 bg-zinc-800/50 rounded">
                <div className="text-muted-foreground">90th Percentile</div>
                <div className="font-bold text-green-400">{optimalLevels?.mfe90.toFixed(0)} pips</div>
              </div>
              <div className="p-2 bg-zinc-800/50 rounded">
                <div className="text-muted-foreground">Rec. TP</div>
                <div className="font-bold text-green-500">{optimalLevels?.recommendedTP} pips</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Row 2: Optimal TP/SL Finder */}
      <Card className="bg-zinc-900/50 border-zinc-700/30">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg flex items-center gap-2">
            <Target className="h-5 w-5 text-yellow-500" />
            Optimal TP/SL Analysis
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* TP Simulation */}
            <div>
              <h4 className="text-sm font-medium mb-3 text-green-400">Take Profit Simulation</h4>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={optimalLevels?.tpSimulations || []}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                    <XAxis dataKey="tp" stroke="#888" fontSize={10} tickFormatter={(v) => `${v}p`} />
                    <YAxis yAxisId="left" stroke="#22c55e" fontSize={10} tickFormatter={(v) => `${v}%`} />
                    <YAxis yAxisId="right" orientation="right" stroke="#3b82f6" fontSize={10} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                      formatter={(value: number, name: string) => [
                        name === 'winRate' ? `${value.toFixed(1)}%` : value.toFixed(0),
                        name === 'winRate' ? 'Win Rate' : 'Trades Hit TP'
                      ]}
                      labelFormatter={(label) => `TP: ${label} pips`}
                    />
                    <Bar yAxisId="right" dataKey="hitsTP" fill="#3b82f6" opacity={0.3} radius={[4, 4, 0, 0]} />
                    <Line yAxisId="left" type="monotone" dataKey="winRate" stroke="#22c55e" strokeWidth={2} dot />
                    <ReferenceLine yAxisId="left" y={50} stroke="#666" strokeDasharray="3 3" />
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
              <div className="mt-2 text-xs text-muted-foreground text-center">
                Higher TP = fewer hits but larger wins when hit
              </div>
            </div>

            {/* SL Simulation */}
            <div>
              <h4 className="text-sm font-medium mb-3 text-red-400">Stop Loss Survival Analysis</h4>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={optimalLevels?.slSimulations || []}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                    <XAxis dataKey="sl" stroke="#888" fontSize={10} tickFormatter={(v) => `${v}p`} />
                    <YAxis yAxisId="left" stroke="#22c55e" fontSize={10} tickFormatter={(v) => `${v}%`} />
                    <YAxis yAxisId="right" orientation="right" stroke="#ef4444" fontSize={10} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                      formatter={(value: number, name: string) => [
                        `${value.toFixed(1)}%`,
                        name === 'survivalRate' ? 'Survival Rate' : 'Stop Rate'
                      ]}
                      labelFormatter={(label) => `SL: ${label} pips`}
                    />
                    <Area yAxisId="left" type="monotone" dataKey="survivalRate" fill="#22c55e" fillOpacity={0.2} stroke="#22c55e" />
                    <Line yAxisId="left" type="monotone" dataKey="stopRate" stroke="#ef4444" strokeWidth={2} dot />
                    <ReferenceLine yAxisId="left" y={80} stroke="#666" strokeDasharray="3 3" label={{ value: '80%', fill: '#666', fontSize: 10 }} />
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
              <div className="mt-2 text-xs text-muted-foreground text-center">
                Tighter SL = more stops | Wider SL = better survival but larger losses
              </div>
            </div>
          </div>

          {/* Recommendation Box */}
          <div className="mt-4 p-4 bg-primary/10 border border-primary/30 rounded-lg">
            <div className="flex items-start gap-3">
              <Target className="h-5 w-5 text-primary mt-0.5" />
              <div>
                <div className="font-medium text-primary">Recommended Settings</div>
                <div className="text-sm text-muted-foreground mt-1">
                  Based on your MFE/MAE distribution, consider:
                </div>
                <div className="flex gap-6 mt-2">
                  <div>
                    <span className="text-green-500 font-bold text-lg">{optimalLevels?.recommendedTP}</span>
                    <span className="text-muted-foreground text-sm ml-1">pips TP</span>
                    <div className="text-xs text-muted-foreground">~60% of trades reach this</div>
                  </div>
                  <div>
                    <span className="text-red-500 font-bold text-lg">{optimalLevels?.recommendedSL}</span>
                    <span className="text-muted-foreground text-sm ml-1">pips SL</span>
                    <div className="text-xs text-muted-foreground">~85% survival rate</div>
                  </div>
                  <div>
                    <span className="text-blue-500 font-bold text-lg">
                      {optimalLevels ? (optimalLevels.recommendedTP / optimalLevels.recommendedSL).toFixed(1) : '-'}
                    </span>
                    <span className="text-muted-foreground text-sm ml-1">R:R Ratio</span>
                    <div className="text-xs text-muted-foreground">Risk to Reward</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Row 3: Post-Exit Analysis */}
      {postExitData && (
        <Card className="bg-zinc-900/50 border-zinc-700/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-lg flex items-center gap-2">
              <Clock className="h-5 w-5 text-purple-500" />
              Post-Exit Analysis
              <span className="text-xs font-normal text-muted-foreground ml-2">(What happened after you exited?)</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Scatter Plot */}
              <div>
                <h4 className="text-sm font-medium mb-3">Profit vs Post-Exit Run Up</h4>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <ScatterChart>
                      <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                      <XAxis 
                        dataKey="profit" 
                        stroke="#888" 
                        fontSize={10} 
                        name="Profit"
                        tickFormatter={(v) => `$${v}`}
                      />
                      <YAxis 
                        dataKey="runUp" 
                        stroke="#888" 
                        fontSize={10} 
                        name="Run Up"
                        tickFormatter={(v) => `${v}p`}
                      />
                      <Tooltip 
                        contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
                        formatter={(value: number, name: string) => [
                          name === 'profit' ? `$${formatDollar(value)}` : `${value.toFixed(1)} pips`,
                          name === 'profit' ? 'Profit' : 'Post-Exit Run Up'
                        ]}
                      />
                      <ReferenceLine x={0} stroke="#666" />
                      <ReferenceLine y={0} stroke="#666" />
                      <Scatter 
                        data={postExitData.scatterData} 
                        fill="#8b5cf6"
                      >
                        {postExitData.scatterData.map((entry, index) => (
                          <Cell 
                            key={`cell-${index}`} 
                            fill={entry.result === 'WIN' ? '#22c55e' : '#ef4444'}
                            opacity={0.7}
                          />
                        ))}
                      </Scatter>
                    </ScatterChart>
                  </ResponsiveContainer>
                </div>
                <div className="text-xs text-muted-foreground text-center mt-2">
                  Points in upper-left = exited too early (left money on table)
                </div>
              </div>

              {/* Stats Summary */}
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-zinc-800/50 rounded-lg">
                    <div className="flex items-center gap-2 text-muted-foreground mb-2">
                      <ArrowUpRight className="h-4 w-4 text-green-500" />
                      <span className="text-xs">Avg Post-Exit Run Up</span>
                    </div>
                    <div className="text-xl font-bold text-green-500">
                      {postExitData.avgRunUp.toFixed(1)} <span className="text-sm font-normal">pips</span>
                    </div>
                    <div className="text-xs text-muted-foreground mt-1">
                      Price moved favorably after exit
                    </div>
                  </div>

                  <div className="p-4 bg-zinc-800/50 rounded-lg">
                    <div className="flex items-center gap-2 text-muted-foreground mb-2">
                      <ArrowDownRight className="h-4 w-4 text-red-500" />
                      <span className="text-xs">Avg Post-Exit Run Down</span>
                    </div>
                    <div className="text-xl font-bold text-red-500">
                      {postExitData.avgRunDown.toFixed(1)} <span className="text-sm font-normal">pips</span>
                    </div>
                    <div className="text-xs text-muted-foreground mt-1">
                      Price moved adversely after exit
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm font-medium text-green-400">Early Exits (Left Money)</div>
                      <div className="text-xs text-muted-foreground">Trades where price ran 10+ pips favorably after exit</div>
                    </div>
                    <div className="text-right">
                      <div className="text-2xl font-bold text-green-500">{postExitData.earlyExitPercent.toFixed(1)}%</div>
                      <div className="text-xs text-muted-foreground">{postExitData.earlyExitCount} of {postExitData.totalTrades}</div>
                    </div>
                  </div>
                </div>

                <div className="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm font-medium text-blue-400">Good Exits (Saved by Exit)</div>
                      <div className="text-xs text-muted-foreground">Trades where price ran 30+ pips adversely after exit</div>
                    </div>
                    <div className="text-right">
                      <div className="text-2xl font-bold text-blue-500">{postExitData.savedByExitPercent.toFixed(1)}%</div>
                      <div className="text-xs text-muted-foreground">{postExitData.savedByExitCount} of {postExitData.totalTrades}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
