import { useEffect, useState, useMemo } from 'react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
  LineChart, Line, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar,
  Cell
} from 'recharts';
import { 
  TrendingUp, TrendingDown, ArrowRight, RefreshCw, 
  ChevronDown, ChevronUp, BarChart3, Target
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Trade, RunInfo, getPassLabel, getSampleLabel, getPassColor, getSampleColor } from '../types';

interface RunData {
  info: RunInfo;
  trades: Trade[];
  metrics: RunMetrics;
}

interface RunMetrics {
  totalTrades: number;
  netProfit: number;
  grossProfit: number;
  grossLoss: number;
  winRate: number;
  profitFactor: number;
  avgWin: number;
  avgLoss: number;
  maxWin: number;
  maxLoss: number;
  expectancy: number;
  wins: number;
  losses: number;
  longWinRate: number;
  shortWinRate: number;
  avgTrade: number;
  maxDrawdown: number;
  startingEquity: number;
  endingEquity: number;
}

interface PassGroup {
  pass: string;
  passNumber: number;
  runs: RunData[];
  totals: {
    trades: number;
    netProfit: number;
    avgWinRate: number;
    avgProfitFactor: number;
  };
}

function calculateMetrics(trades: Trade[]): RunMetrics {
  if (!trades || trades.length === 0) {
    return {
      totalTrades: 0, netProfit: 0, grossProfit: 0, grossLoss: 0,
      winRate: 0, profitFactor: 0, avgWin: 0, avgLoss: 0,
      maxWin: 0, maxLoss: 0, expectancy: 0, wins: 0, losses: 0,
      longWinRate: 0, shortWinRate: 0, avgTrade: 0, maxDrawdown: 0,
      startingEquity: 0, endingEquity: 0
    };
  }

  // Case-insensitive check for Trade_Result (handles "Win"/"WIN" and "Loss"/"LOSS")
  const isWin = (t: Trade) => t.Trade_Result?.toLowerCase() === 'win';
  const isLoss = (t: Trade) => t.Trade_Result?.toLowerCase() === 'loss';

  const wins = trades.filter(isWin);
  const losses = trades.filter(isLoss);
  const longs = trades.filter(t => t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy');
  const shorts = trades.filter(t => t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell');
  const longWins = longs.filter(isWin);
  const shortWins = shorts.filter(isWin);

  // Get starting equity from first trade and ending equity from last trade
  const startingEquity = trades[0]?.IN_Balance_OP_01 || 10000;
  const endingEquity = trades[trades.length - 1]?.OUT_Balance_OP_01 || (startingEquity + trades.reduce((sum, t) => sum + (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0), 0));

  const grossProfit = wins.reduce((sum, t) => sum + (t.OUT_Profit_OP_01 || 0), 0);
  const grossLoss = Math.abs(losses.reduce((sum, t) => sum + (t.OUT_Profit_OP_01 || 0), 0));
  const netProfit = trades.reduce((sum, t) => {
    return sum + (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0);
  }, 0);

  // Calculate drawdown
  let peak = 0;
  let maxDrawdown = 0;
  let equity = 0;
  trades.forEach(t => {
    const pnl = (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0);
    equity += pnl;
    if (equity > peak) peak = equity;
    const dd = peak - equity;
    if (dd > maxDrawdown) maxDrawdown = dd;
  });

  return {
    totalTrades: trades.length,
    netProfit,
    grossProfit,
    grossLoss,
    winRate: trades.length > 0 ? (wins.length / trades.length) * 100 : 0,
    profitFactor: grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? Infinity : 0,
    avgWin: wins.length > 0 ? grossProfit / wins.length : 0,
    avgLoss: losses.length > 0 ? grossLoss / losses.length : 0,
    maxWin: wins.length > 0 ? Math.max(...wins.map(t => t.OUT_Profit_OP_01 || 0)) : 0,
    maxLoss: losses.length > 0 ? Math.min(...losses.map(t => t.OUT_Profit_OP_01 || 0)) : 0,
    expectancy: trades.length > 0 ? netProfit / trades.length : 0,
    wins: wins.length,
    losses: losses.length,
    longWinRate: longs.length > 0 ? (longWins.length / longs.length) * 100 : 0,
    shortWinRate: shorts.length > 0 ? (shortWins.length / shorts.length) * 100 : 0,
    avgTrade: trades.length > 0 ? netProfit / trades.length : 0,
    maxDrawdown,
    startingEquity,
    endingEquity
  };
}

export function PassComparison() {
  const [loading, setLoading] = useState(true);
  const [passGroups, setPassGroups] = useState<PassGroup[]>([]);
  const [expandedPasses, setExpandedPasses] = useState<Set<string>>(new Set(['BL']));
  const [selectedMetric, setSelectedMetric] = useState<'netProfit' | 'winRate' | 'profitFactor' | 'expectancy'>('netProfit');

  useEffect(() => {
    loadAllRuns();
  }, []);

  const loadAllRuns = async () => {
    try {
      setLoading(true);
      
      // Load runs index
      const indexResponse = await fetch('/data/runs/index.json');
      if (!indexResponse.ok) {
        console.error('Failed to load runs index');
        return;
      }
      
      const indexData = await indexResponse.json();
      const runs: RunData[] = [];

      // Load each run's data
      for (const runInfo of indexData.runs as RunInfo[]) {
        try {
          const response = await fetch(`/data/runs/${runInfo.filename}`);
          if (response.ok) {
            const jsonData = await response.json();
            const trades = (jsonData.trades || []) as Trade[];
            const metrics = calculateMetrics(trades);
            runs.push({ info: runInfo, trades, metrics });
          }
        } catch (e) {
          console.error(`Error loading run ${runInfo.id}:`, e);
        }
      }

      // Group by pass
      const groupMap = new Map<string, RunData[]>();
      runs.forEach(run => {
        const pass = run.info.pass;
        if (!groupMap.has(pass)) {
          groupMap.set(pass, []);
        }
        groupMap.get(pass)!.push(run);
      });

      // Convert to PassGroup array and sort
      const groups: PassGroup[] = [];
      const passOrder = ['BL', 'P1', 'P2', 'P3', 'FN'];
      
      passOrder.forEach(pass => {
        const passRuns = groupMap.get(pass);
        if (passRuns && passRuns.length > 0) {
          // Sort runs within pass: IS first, then OOS1, OOS2, OOS3
          passRuns.sort((a, b) => {
            if (a.info.isInSample && !b.info.isInSample) return -1;
            if (!a.info.isInSample && b.info.isInSample) return 1;
            return a.info.sampleType.localeCompare(b.info.sampleType);
          });

          const totalTrades = passRuns.reduce((sum, r) => sum + r.metrics.totalTrades, 0);
          const totalProfit = passRuns.reduce((sum, r) => sum + r.metrics.netProfit, 0);
          const avgWinRate = passRuns.reduce((sum, r) => sum + r.metrics.winRate, 0) / passRuns.length;
          const avgPF = passRuns.filter(r => r.metrics.profitFactor !== Infinity)
            .reduce((sum, r, _, arr) => sum + r.metrics.profitFactor / arr.length, 0);

          groups.push({
            pass,
            passNumber: passRuns[0].info.passNumber,
            runs: passRuns,
            totals: {
              trades: totalTrades,
              netProfit: totalProfit,
              avgWinRate,
              avgProfitFactor: avgPF
            }
          });
        }
      });

      setPassGroups(groups);
      // Expand all passes by default
      setExpandedPasses(new Set(groups.map(g => g.pass)));
    } catch (error) {
      console.error('Error loading runs:', error);
    } finally {
      setLoading(false);
    }
  };

  const togglePass = (pass: string) => {
    setExpandedPasses(prev => {
      const next = new Set(prev);
      if (next.has(pass)) {
        next.delete(pass);
      } else {
        next.add(pass);
      }
      return next;
    });
  };

  // Prepare chart data for bar chart comparison
  const chartData = useMemo(() => {
    const data: any[] = [];
    const sampleTypes = ['IS', 'OOS1-BL', 'OOS2-BL', 'OOS3-BL'];
    
    sampleTypes.forEach(sample => {
      const row: any = { sample: sample.replace('-BL', '') };
      passGroups.forEach(group => {
        const run = group.runs.find(r => r.info.sampleType === sample);
        if (run) {
          row[group.pass] = run.metrics[selectedMetric];
        }
      });
      data.push(row);
    });
    
    return data;
  }, [passGroups, selectedMetric]);

  // Prepare equity curve comparison data
  const equityCurveData = useMemo(() => {
    if (passGroups.length === 0) return [];
    
    // Get the baseline pass (BL) runs
    const blGroup = passGroups.find(g => g.pass === 'BL');
    if (!blGroup) return [];

    // Build combined equity curve for each sample type
    const sampleTypes = ['IS', 'OOS1-BL', 'OOS2-BL', 'OOS3-BL'];
    const maxLength = Math.max(...blGroup.runs.map(r => r.trades.length));
    
    const data: any[] = [];
    for (let i = 0; i < Math.min(maxLength, 500); i += 5) { // Sample every 5th trade for performance
      const point: any = { tradeNum: i };
      
      sampleTypes.forEach(sample => {
        const run = blGroup.runs.find(r => r.info.sampleType === sample);
        if (run && run.trades.length > i) {
          let equity = 0;
          for (let j = 0; j <= i && j < run.trades.length; j++) {
            const t = run.trades[j];
            equity += (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0);
          }
          point[sample.replace('-BL', '')] = equity;
        }
      });
      
      data.push(point);
    }
    
    return data;
  }, [passGroups]);

  // Radar chart data for pass comparison
  const radarData = useMemo(() => {
    if (passGroups.length === 0) return [];
    
    // Normalize metrics to 0-100 scale for radar chart
    const metrics = ['winRate', 'profitFactor', 'expectancy', 'avgWin', 'trades'] as const;
    
    return metrics.map(metric => {
      const point: any = { metric: metric === 'profitFactor' ? 'PF' : 
                                  metric === 'expectancy' ? 'Exp' : 
                                  metric === 'avgWin' ? 'Avg Win' : 
                                  metric === 'winRate' ? 'Win %' : 'Trades' };
      
      passGroups.forEach(group => {
        // Average across all runs in the pass
        let value = 0;
        if (metric === 'trades') {
          value = group.totals.trades;
        } else if (metric === 'winRate') {
          value = group.totals.avgWinRate;
        } else if (metric === 'profitFactor') {
          value = Math.min(group.totals.avgProfitFactor * 25, 100); // Scale PF to 0-100
        } else {
          const sum = group.runs.reduce((acc, r) => acc + (r.metrics[metric] as number), 0);
          value = sum / group.runs.length;
          if (metric === 'expectancy') value = Math.max(0, value + 50); // Shift expectancy
          if (metric === 'avgWin') value = Math.min(value / 10, 100); // Scale avg win
        }
        point[group.pass] = value;
      });
      
      return point;
    });
  }, [passGroups]);

  // Delta calculations between passes
  const passDeltas = useMemo(() => {
    if (passGroups.length < 2) return null;
    
    const deltas: { pass: string; vs: string; netProfit: number; winRate: number; profitFactor: number }[] = [];
    
    for (let i = 1; i < passGroups.length; i++) {
      const current = passGroups[i];
      const previous = passGroups[i - 1];
      
      deltas.push({
        pass: current.pass,
        vs: previous.pass,
        netProfit: current.totals.netProfit - previous.totals.netProfit,
        winRate: current.totals.avgWinRate - previous.totals.avgWinRate,
        profitFactor: current.totals.avgProfitFactor - previous.totals.avgProfitFactor
      });
    }
    
    return deltas;
  }, [passGroups]);

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2 }).format(value);
  };

  const formatPercent = (value: number) => `${value.toFixed(2)}%`;
  const formatPF = (value: number) => value === Infinity ? '∞' : value.toFixed(2);

  const getMetricColor = (value: number, isPositiveGood: boolean = true) => {
    if (value === 0) return 'text-muted-foreground';
    return (value > 0) === isPositiveGood ? 'text-green-400' : 'text-red-400';
  };

  const passColors: Record<string, string> = {
    'BL': '#6b7280',
    'P1': '#3b82f6',
    'P2': '#8b5cf6',
    'P3': '#f97316',
    'FN': '#22c55e'
  };

  const sampleColors: Record<string, string> = {
    'IS': '#10b981',
    'OOS1': '#f59e0b',
    'OOS2': '#ef4444',
    'OOS3': '#8b5cf6'
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <RefreshCw className="h-8 w-8 animate-spin text-muted-foreground" />
        <span className="ml-3 text-muted-foreground">Loading optimization runs...</span>
      </div>
    );
  }

  if (passGroups.length === 0) {
    return (
      <Card>
        <CardContent className="flex flex-col items-center justify-center h-64">
          <BarChart3 className="h-12 w-12 text-muted-foreground mb-4" />
          <p className="text-muted-foreground">No optimization runs found</p>
          <p className="text-sm text-muted-foreground mt-2">
            Process backtest files to see comparisons here
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header with metric selector */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Optimization Pass Comparison</h2>
          <p className="text-muted-foreground mt-1">
            Compare performance across optimization passes and sample periods
          </p>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={loadAllRuns}
            className="flex items-center gap-2 px-3 py-2 bg-muted hover:bg-muted/80 rounded-lg text-sm transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh
          </button>
        </div>
      </div>

      {/* Pass Improvement Delta Cards */}
      {passDeltas && passDeltas.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {passDeltas.map(delta => (
            <Card key={delta.pass} className="border-l-4" style={{ borderLeftColor: passColors[delta.pass] }}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-sm font-medium text-muted-foreground">
                    {getPassLabel(delta.vs)} → {getPassLabel(delta.pass)}
                  </span>
                  <ArrowRight className="h-4 w-4 text-muted-foreground" />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <p className="text-xs text-muted-foreground">Net Profit Δ</p>
                    <p className={`text-lg font-bold ${getMetricColor(delta.netProfit)}`}>
                      {delta.netProfit >= 0 ? '+' : ''}{formatCurrency(delta.netProfit)}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">Win Rate Δ</p>
                    <p className={`text-lg font-bold ${getMetricColor(delta.winRate)}`}>
                      {delta.winRate >= 0 ? '+' : ''}{formatPercent(delta.winRate)}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">PF Δ</p>
                    <p className={`text-lg font-bold ${getMetricColor(delta.profitFactor)}`}>
                      {delta.profitFactor >= 0 ? '+' : ''}{delta.profitFactor.toFixed(2)}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Visualization Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bar Chart Comparison */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex items-center justify-between">
              <CardTitle className="text-lg">Performance by Sample Type</CardTitle>
              <select
                value={selectedMetric}
                onChange={(e) => setSelectedMetric(e.target.value as any)}
                className="px-3 py-1 bg-muted rounded text-sm border-0"
              >
                <option value="netProfit">Net Profit</option>
                <option value="winRate">Win Rate %</option>
                <option value="profitFactor">Profit Factor</option>
                <option value="expectancy">Expectancy</option>
              </select>
            </div>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                <XAxis dataKey="sample" stroke="#888" />
                <YAxis stroke="#888" tickFormatter={(v) => 
                  selectedMetric === 'netProfit' ? `$${(v/1000).toFixed(0)}k` :
                  selectedMetric === 'winRate' ? `${v}%` : v.toFixed(1)
                } />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1a1a1a', border: '1px solid #333' }}
                  formatter={(value: number) => [
                    selectedMetric === 'netProfit' ? formatCurrency(value) :
                    selectedMetric === 'winRate' ? formatPercent(value) : 
                    value.toFixed(2),
                    ''
                  ]}
                />
                <Legend />
                {passGroups.map(group => (
                  <Bar 
                    key={group.pass} 
                    dataKey={group.pass} 
                    name={getPassLabel(group.pass)}
                    fill={passColors[group.pass]} 
                  />
                ))}
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Equity Curve Comparison */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Baseline Equity Curves by Sample</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={equityCurveData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                <XAxis dataKey="tradeNum" stroke="#888" label={{ value: 'Trade #', position: 'bottom' }} />
                <YAxis stroke="#888" tickFormatter={(v) => `$${(v/1000).toFixed(1)}k`} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1a1a1a', border: '1px solid #333' }}
                  formatter={(value: number) => [formatCurrency(value), '']}
                />
                <Legend />
                <Line type="monotone" dataKey="IS" name="In-Sample" stroke={sampleColors['IS']} dot={false} strokeWidth={2} />
                <Line type="monotone" dataKey="OOS1" name="OOS1" stroke={sampleColors['OOS1']} dot={false} strokeWidth={2} />
                <Line type="monotone" dataKey="OOS2" name="OOS2" stroke={sampleColors['OOS2']} dot={false} strokeWidth={2} />
                <Line type="monotone" dataKey="OOS3" name="OOS3" stroke={sampleColors['OOS3']} dot={false} strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Detailed Table View */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="h-5 w-5" />
            Detailed Run Metrics
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-3 px-4 font-semibold">Pass / Sample</th>
                  <th className="text-right py-3 px-4 font-semibold">Date Range</th>
                  <th className="text-right py-3 px-4 font-semibold">Start Equity</th>
                  <th className="text-right py-3 px-4 font-semibold">End Equity</th>
                  <th className="text-right py-3 px-4 font-semibold">Trades</th>
                  <th className="text-right py-3 px-4 font-semibold">Net Profit</th>
                  <th className="text-right py-3 px-4 font-semibold">Win Rate</th>
                  <th className="text-right py-3 px-4 font-semibold">PF</th>
                  <th className="text-right py-3 px-4 font-semibold">Expectancy</th>
                  <th className="text-right py-3 px-4 font-semibold">Avg Win</th>
                  <th className="text-right py-3 px-4 font-semibold">Avg Loss</th>
                  <th className="text-right py-3 px-4 font-semibold">Max DD</th>
                </tr>
              </thead>
              <tbody>
                {passGroups.map(group => (
                  <>
                    {/* Pass Header Row */}
                    <tr 
                      key={`pass-${group.pass}`}
                      className="bg-muted/50 cursor-pointer hover:bg-muted/70 transition-colors"
                      onClick={() => togglePass(group.pass)}
                    >
                      <td className="py-3 px-4 font-medium" colSpan={1}>
                        <div className="flex items-center gap-2">
                          {expandedPasses.has(group.pass) ? 
                            <ChevronDown className="h-4 w-4" /> : 
                            <ChevronUp className="h-4 w-4" />
                          }
                          <span 
                            className="px-2 py-1 rounded text-xs font-semibold"
                            style={{ backgroundColor: `${passColors[group.pass]}30`, color: passColors[group.pass] }}
                          >
                            {getPassLabel(group.pass)}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-right text-muted-foreground">
                        {group.runs.length} runs
                      </td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                      <td className="py-3 px-4 text-right font-medium">
                        {group.totals.trades.toLocaleString()}
                      </td>
                      <td className={`py-3 px-4 text-right font-medium ${getMetricColor(group.totals.netProfit)}`}>
                        {formatCurrency(group.totals.netProfit)}
                      </td>
                      <td className={`py-3 px-4 text-right font-medium ${getMetricColor(group.totals.avgWinRate - 50)}`}>
                        {formatPercent(group.totals.avgWinRate)}
                      </td>
                      <td className={`py-3 px-4 text-right font-medium ${getMetricColor(group.totals.avgProfitFactor - 1)}`}>
                        {formatPF(group.totals.avgProfitFactor)}
                      </td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                      <td className="py-3 px-4 text-right text-muted-foreground">—</td>
                    </tr>
                    
                    {/* Individual Run Rows */}
                    {expandedPasses.has(group.pass) && group.runs.map(run => (
                      <tr 
                        key={run.info.id}
                        className="border-b border-border/50 hover:bg-muted/30 transition-colors"
                      >
                        <td className="py-3 px-4 pl-10">
                          <div className="flex items-center gap-2">
                            <span 
                              className={`px-2 py-0.5 rounded text-xs ${
                                run.info.isInSample 
                                  ? 'bg-emerald-500/20 text-emerald-400' 
                                  : 'bg-amber-500/20 text-amber-400'
                              }`}
                            >
                              {getSampleLabel(run.info.sampleType)}
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-right text-muted-foreground">
                          {run.info.dateRange}
                        </td>
                        <td className="py-3 px-4 text-right text-blue-400">
                          {formatCurrency(run.metrics.startingEquity)}
                        </td>
                        <td className={`py-3 px-4 text-right ${run.metrics.endingEquity >= run.metrics.startingEquity ? 'text-green-400' : 'text-red-400'}`}>
                          {formatCurrency(run.metrics.endingEquity)}
                        </td>
                        <td className="py-3 px-4 text-right">
                          {run.metrics.totalTrades.toLocaleString()}
                        </td>
                        <td className={`py-3 px-4 text-right ${getMetricColor(run.metrics.netProfit)}`}>
                          {formatCurrency(run.metrics.netProfit)}
                        </td>
                        <td className={`py-3 px-4 text-right ${getMetricColor(run.metrics.winRate - 50)}`}>
                          {formatPercent(run.metrics.winRate)}
                        </td>
                        <td className={`py-3 px-4 text-right ${getMetricColor(run.metrics.profitFactor - 1)}`}>
                          {formatPF(run.metrics.profitFactor)}
                        </td>
                        <td className={`py-3 px-4 text-right ${getMetricColor(run.metrics.expectancy)}`}>
                          {formatCurrency(run.metrics.expectancy)}
                        </td>
                        <td className="py-3 px-4 text-right text-green-400">
                          {formatCurrency(run.metrics.avgWin)}
                        </td>
                        <td className="py-3 px-4 text-right text-red-400">
                          {formatCurrency(run.metrics.avgLoss)}
                        </td>
                        <td className="py-3 px-4 text-right text-red-400">
                          {formatCurrency(run.metrics.maxDrawdown)}
                        </td>
                      </tr>
                    ))}
                  </>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Summary Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {passGroups.map(group => (
          <Card key={group.pass} className="border-t-4" style={{ borderTopColor: passColors[group.pass] }}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <span 
                  className="px-2 py-1 rounded text-xs font-semibold"
                  style={{ backgroundColor: `${passColors[group.pass]}30`, color: passColors[group.pass] }}
                >
                  {getPassLabel(group.pass)}
                </span>
                <span className="text-xs text-muted-foreground">{group.runs.length} samples</span>
              </div>
              
              <div className="space-y-2 mt-3">
                <div className="flex justify-between">
                  <span className="text-xs text-muted-foreground">Total Trades</span>
                  <span className="text-sm font-medium">{group.totals.trades.toLocaleString()}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-xs text-muted-foreground">Net Profit</span>
                  <span className={`text-sm font-medium ${getMetricColor(group.totals.netProfit)}`}>
                    {formatCurrency(group.totals.netProfit)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-xs text-muted-foreground">Avg Win Rate</span>
                  <span className={`text-sm font-medium ${getMetricColor(group.totals.avgWinRate - 50)}`}>
                    {formatPercent(group.totals.avgWinRate)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-xs text-muted-foreground">Avg PF</span>
                  <span className={`text-sm font-medium ${getMetricColor(group.totals.avgProfitFactor - 1)}`}>
                    {formatPF(group.totals.avgProfitFactor)}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* IS vs OOS Performance Gap Analysis */}
      <Card>
        <CardHeader>
          <CardTitle>In-Sample vs Out-of-Sample Gap Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-3 px-4 font-semibold">Pass</th>
                  <th className="text-right py-3 px-4 font-semibold">IS Net Profit</th>
                  <th className="text-right py-3 px-4 font-semibold">OOS Avg Profit</th>
                  <th className="text-right py-3 px-4 font-semibold">IS/OOS Gap</th>
                  <th className="text-right py-3 px-4 font-semibold">IS Win %</th>
                  <th className="text-right py-3 px-4 font-semibold">OOS Avg Win %</th>
                  <th className="text-right py-3 px-4 font-semibold">IS/OOS Gap</th>
                  <th className="text-center py-3 px-4 font-semibold">Overfitting Risk</th>
                </tr>
              </thead>
              <tbody>
                {passGroups.map(group => {
                  const isRun = group.runs.find(r => r.info.isInSample);
                  const oosRuns = group.runs.filter(r => !r.info.isInSample);
                  
                  if (!isRun || oosRuns.length === 0) return null;

                  const isProfit = isRun.metrics.netProfit;
                  const oosAvgProfit = oosRuns.reduce((sum, r) => sum + r.metrics.netProfit, 0) / oosRuns.length;
                  const profitGap = isProfit - oosAvgProfit;
                  
                  const isWinRate = isRun.metrics.winRate;
                  const oosAvgWinRate = oosRuns.reduce((sum, r) => sum + r.metrics.winRate, 0) / oosRuns.length;
                  const winRateGap = isWinRate - oosAvgWinRate;

                  // Determine overfitting risk based on gaps
                  let riskLevel: 'Low' | 'Medium' | 'High' = 'Low';
                  let riskColor = 'text-green-400';
                  if (winRateGap > 5 || (isProfit > 0 && oosAvgProfit < 0)) {
                    riskLevel = 'High';
                    riskColor = 'text-red-400';
                  } else if (winRateGap > 2 || Math.abs(profitGap) > 1000) {
                    riskLevel = 'Medium';
                    riskColor = 'text-amber-400';
                  }

                  return (
                    <tr key={group.pass} className="border-b border-border/50">
                      <td className="py-3 px-4">
                        <span 
                          className="px-2 py-1 rounded text-xs font-semibold"
                          style={{ backgroundColor: `${passColors[group.pass]}30`, color: passColors[group.pass] }}
                        >
                          {getPassLabel(group.pass)}
                        </span>
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(isProfit)}`}>
                        {formatCurrency(isProfit)}
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(oosAvgProfit)}`}>
                        {formatCurrency(oosAvgProfit)}
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(-profitGap)}`}>
                        {profitGap >= 0 ? '+' : ''}{formatCurrency(profitGap)}
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(isWinRate - 50)}`}>
                        {formatPercent(isWinRate)}
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(oosAvgWinRate - 50)}`}>
                        {formatPercent(oosAvgWinRate)}
                      </td>
                      <td className={`py-3 px-4 text-right ${getMetricColor(-winRateGap)}`}>
                        {winRateGap >= 0 ? '+' : ''}{formatPercent(winRateGap)}
                      </td>
                      <td className={`py-3 px-4 text-center font-medium ${riskColor}`}>
                        {riskLevel}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-muted-foreground mt-4">
            <strong>Overfitting Risk:</strong> Measures the gap between in-sample and out-of-sample performance. 
            Large gaps suggest the strategy may be overfit to historical data.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export default PassComparison;
