import { useState, useEffect } from 'react';
import { TrendingUp, TrendingDown, Minus, AlertTriangle, CheckCircle } from 'lucide-react';
import { RunIndex, RunInfo, getPassLabel, getSampleLabel, getPassColor, getSampleColor } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';

interface RunMetrics {
  runId: string;
  tradeCount: number;
  netProfit: number;
  winRate: number;
  profitFactor: number;
  avgWin: number;
  avgLoss: number;
  maxDrawdown: number;
}

interface RunComparisonProps {
  onClose: () => void;
}

export function RunComparison({ onClose }: RunComparisonProps) {
  const [runIndex, setRunIndex] = useState<RunIndex | null>(null);
  const [metrics, setMetrics] = useState<Record<string, RunMetrics>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      try {
        // Load run index
        const indexResponse = await fetch('/data/runs/index.json');
        if (!indexResponse.ok) return;
        const index: RunIndex = await indexResponse.json();
        setRunIndex(index);

        // Load metrics for each run
        const metricsMap: Record<string, RunMetrics> = {};
        for (const run of index.runs) {
          try {
            const dataResponse = await fetch(`/data/runs/${run.filename}`);
            if (dataResponse.ok) {
              const data = await dataResponse.json();
              const trades = data.trades || [];
              
              // Calculate metrics
              const wins = trades.filter((t: any) => (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0) > 0);
              const losses = trades.filter((t: any) => (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0) <= 0);
              
              const grossProfit = wins.reduce((sum: number, t: any) => sum + (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0), 0);
              const grossLoss = Math.abs(losses.reduce((sum: number, t: any) => sum + (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0), 0));
              
              metricsMap[run.id] = {
                runId: run.id,
                tradeCount: trades.length,
                netProfit: grossProfit - grossLoss,
                winRate: trades.length > 0 ? (wins.length / trades.length) * 100 : 0,
                profitFactor: grossLoss > 0 ? grossProfit / grossLoss : 0,
                avgWin: wins.length > 0 ? grossProfit / wins.length : 0,
                avgLoss: losses.length > 0 ? grossLoss / losses.length : 0,
                maxDrawdown: 0 // Would need equity curve for this
              };
            }
          } catch (e) {
            console.error(`Failed to load run ${run.id}:`, e);
          }
        }
        setMetrics(metricsMap);
      } catch (error) {
        console.error('Failed to load comparison data:', error);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-slate-900 p-8 rounded-lg">
          <div className="animate-spin w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full mx-auto"></div>
          <p className="text-slate-400 mt-4">Loading comparison data...</p>
        </div>
      </div>
    );
  }

  if (!runIndex || runIndex.runs.length === 0) {
    return null;
  }

  // Group runs by pass for comparison matrix
  const passes = ['BL', 'P1', 'P2', 'P3', 'FN'];
  const samples = ['IS', 'OOS1-BL', 'OOS2-BL', 'OOS3-BL'];

  const getRunByPassSample = (pass: string, sample: string): RunInfo | undefined => {
    return runIndex.runs.find(r => r.pass === pass && r.sampleType === sample);
  };

  const formatProfit = (value: number) => {
    const formatted = Math.abs(value).toFixed(2);
    return value >= 0 ? `+$${formatted}` : `-$${formatted}`;
  };

  const formatPercent = (value: number) => `${value.toFixed(1)}%`;

  const getChangeIndicator = (current: number, baseline: number, higherIsBetter: boolean = true) => {
    if (baseline === 0) return null;
    const change = ((current - baseline) / Math.abs(baseline)) * 100;
    const isImproved = higherIsBetter ? change > 0 : change < 0;
    
    if (Math.abs(change) < 1) {
      return <Minus className="w-4 h-4 text-slate-500" />;
    }
    return isImproved 
      ? <TrendingUp className="w-4 h-4 text-green-400" />
      : <TrendingDown className="w-4 h-4 text-red-400" />;
  };

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
      <div className="bg-slate-900 rounded-xl border border-slate-700 max-w-6xl w-full max-h-[90vh] overflow-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-slate-700 sticky top-0 bg-slate-900">
          <h2 className="text-xl font-bold text-white">Optimization Run Comparison</h2>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white transition-colors px-3 py-1 rounded hover:bg-slate-800"
          >
            Close
          </button>
        </div>

        {/* Comparison Matrix */}
        <div className="p-6">
          {/* Key Metrics Comparison */}
          <div className="mb-8">
            <h3 className="text-lg font-semibold text-white mb-4">Key Metrics by Run</h3>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-slate-700">
                    <th className="text-left py-3 px-4 text-slate-400 font-medium">Run</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Trades</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Net Profit</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Win Rate</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Profit Factor</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Avg Win</th>
                    <th className="text-right py-3 px-4 text-slate-400 font-medium">Avg Loss</th>
                  </tr>
                </thead>
                <tbody>
                  {runIndex.runs.map(run => {
                    const m = metrics[run.id];
                    if (!m) return null;
                    
                    const isIS = run.sampleType === 'IS';
                    const baselineIS = metrics['BL_IS'];
                    
                    return (
                      <tr key={run.id} className="border-b border-slate-800 hover:bg-slate-800/50">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <span className={`text-xs px-2 py-0.5 rounded ${getPassColor(run.pass)}`}>
                              {run.pass}
                            </span>
                            <span className={`text-xs px-2 py-0.5 rounded ${getSampleColor(run.sampleType)}`}>
                              {run.sampleType}
                            </span>
                            <span className="text-sm text-slate-400">{run.dateRange}</span>
                          </div>
                        </td>
                        <td className="text-right py-3 px-4 text-slate-300">{m.tradeCount}</td>
                        <td className={`text-right py-3 px-4 ${m.netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                          {formatProfit(m.netProfit)}
                        </td>
                        <td className="text-right py-3 px-4">
                          <div className="flex items-center justify-end gap-1">
                            <span className="text-slate-300">{formatPercent(m.winRate)}</span>
                            {baselineIS && run.id !== 'BL_IS' && getChangeIndicator(m.winRate, baselineIS.winRate)}
                          </div>
                        </td>
                        <td className="text-right py-3 px-4">
                          <div className="flex items-center justify-end gap-1">
                            <span className="text-slate-300">{m.profitFactor.toFixed(2)}</span>
                            {baselineIS && run.id !== 'BL_IS' && getChangeIndicator(m.profitFactor, baselineIS.profitFactor)}
                          </div>
                        </td>
                        <td className="text-right py-3 px-4 text-green-400">${m.avgWin.toFixed(2)}</td>
                        <td className="text-right py-3 px-4 text-red-400">${m.avgLoss.toFixed(2)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* Overfitting Detection */}
          {runIndex.runs.length > 1 && (
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-amber-400" />
                  Overfitting Detection
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-slate-400 text-sm mb-4">
                  Compare In-Sample (IS) vs Out-of-Sample (OOS) performance. 
                  If IS improves significantly but OOS degrades, this indicates potential overfitting.
                </p>
                
                {metrics['BL_IS'] && (
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {['OOS1-BL', 'OOS2-BL', 'OOS3-BL'].map(sample => {
                      const run = getRunByPassSample('BL', sample);
                      const m = run ? metrics[run.id] : null;
                      const baseline = metrics['BL_IS'];
                      
                      if (!m) {
                        return (
                          <div key={sample} className="p-4 bg-slate-900/50 rounded-lg border border-slate-700 border-dashed">
                            <span className="text-slate-500 text-sm">{sample}</span>
                            <p className="text-slate-600 text-xs mt-1">Not yet processed</p>
                          </div>
                        );
                      }
                      
                      const winRateDiff = m.winRate - baseline.winRate;
                      const pfDiff = m.profitFactor - baseline.profitFactor;
                      const isHealthy = Math.abs(winRateDiff) < 10 && Math.abs(pfDiff) < 0.5;
                      
                      return (
                        <div 
                          key={sample} 
                          className={`p-4 rounded-lg border ${
                            isHealthy 
                              ? 'bg-green-500/10 border-green-500/30' 
                              : 'bg-amber-500/10 border-amber-500/30'
                          }`}
                        >
                          <div className="flex items-center gap-2 mb-2">
                            {isHealthy 
                              ? <CheckCircle className="w-4 h-4 text-green-400" />
                              : <AlertTriangle className="w-4 h-4 text-amber-400" />
                            }
                            <span className="text-sm font-medium text-slate-300">{sample}</span>
                          </div>
                          <div className="space-y-1 text-xs">
                            <div className="flex justify-between">
                              <span className="text-slate-500">Win Rate Δ:</span>
                              <span className={winRateDiff >= 0 ? 'text-green-400' : 'text-red-400'}>
                                {winRateDiff >= 0 ? '+' : ''}{winRateDiff.toFixed(1)}%
                              </span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-slate-500">PF Δ:</span>
                              <span className={pfDiff >= 0 ? 'text-green-400' : 'text-red-400'}>
                                {pfDiff >= 0 ? '+' : ''}{pfDiff.toFixed(2)}
                              </span>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

export default RunComparison;
