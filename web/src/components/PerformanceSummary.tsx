import { useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { 
  TrendingUp, TrendingDown, Target, AlertTriangle, CheckCircle, 
  DollarSign, Percent, BarChart3, Zap, Shield, Award
} from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';

interface PerformanceSummaryProps {
  trades: Trade[];
}

export default function PerformanceSummary({ trades }: PerformanceSummaryProps) {
  // Overall stats
  const overallStats = useMemo(() => {
    const total = trades.length;
    const wins = trades.filter(t => t.NetProfit > 0);
    const losses = trades.filter(t => t.NetProfit <= 0);
    
    const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0);
    const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0));
    const netProfit = grossProfit - grossLoss;
    
    const winRate = total > 0 ? (wins.length / total) * 100 : 0;
    const profitFactor = grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? Infinity : 0;
    const avgWin = wins.length > 0 ? grossProfit / wins.length : 0;
    const avgLoss = losses.length > 0 ? grossLoss / losses.length : 0;
    const expectancy = total > 0 ? netProfit / total : 0;
    const rrRatio = avgLoss > 0 ? avgWin / avgLoss : avgWin > 0 ? Infinity : 0;
    
    // Calculate max drawdown
    let peak = 0;
    let maxDrawdown = 0;
    let cumulative = 0;
    
    trades.forEach(t => {
      cumulative += t.NetProfit;
      if (cumulative > peak) peak = cumulative;
      const drawdown = peak - cumulative;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    });
    
    const maxDrawdownPercent = peak > 0 ? (maxDrawdown / peak) * 100 : 0;
    
    // Calculate consecutive wins/losses
    let maxConsecWins = 0, maxConsecLosses = 0;
    let currentConsecWins = 0, currentConsecLosses = 0;
    
    trades.forEach(t => {
      if (t.NetProfit > 0) {
        currentConsecWins++;
        currentConsecLosses = 0;
        if (currentConsecWins > maxConsecWins) maxConsecWins = currentConsecWins;
      } else {
        currentConsecLosses++;
        currentConsecWins = 0;
        if (currentConsecLosses > maxConsecLosses) maxConsecLosses = currentConsecLosses;
      }
    });
    
    return {
      total,
      wins: wins.length,
      losses: losses.length,
      grossProfit,
      grossLoss,
      netProfit,
      winRate,
      profitFactor,
      avgWin,
      avgLoss,
      expectancy,
      rrRatio,
      maxDrawdown,
      maxDrawdownPercent,
      maxConsecWins,
      maxConsecLosses,
    };
  }, [trades]);

  // Long vs Short breakdown
  const directionStats = useMemo(() => {
    const longs = trades.filter(t => t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy');
    const shorts = trades.filter(t => t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell');
    
    const calcStats = (arr: Trade[]) => {
      const wins = arr.filter(t => t.NetProfit > 0);
      const profit = arr.reduce((sum, t) => sum + t.NetProfit, 0);
      return {
        count: arr.length,
        wins: wins.length,
        profit,
        winRate: arr.length > 0 ? (wins.length / arr.length) * 100 : 0,
      };
    };
    
    return {
      long: calcStats(longs),
      short: calcStats(shorts),
    };
  }, [trades]);

  // Equity curve data
  const equityCurve = useMemo(() => {
    let cumulative = 0;
    let peak = 0;
    
    return trades.map((t, i) => {
      cumulative += t.NetProfit;
      if (cumulative > peak) peak = cumulative;
      
      return {
        trade: i + 1,
        equity: cumulative,
        peak,
        drawdown: peak - cumulative,
      };
    });
  }, [trades]);

  // Performance grade
  const grade = useMemo(() => {
    let score = 0;
    
    // Win rate scoring (max 25 points)
    if (overallStats.winRate >= 60) score += 25;
    else if (overallStats.winRate >= 50) score += 20;
    else if (overallStats.winRate >= 40) score += 15;
    else if (overallStats.winRate >= 30) score += 10;
    else score += 5;
    
    // Profit factor scoring (max 25 points)
    if (overallStats.profitFactor >= 2.0) score += 25;
    else if (overallStats.profitFactor >= 1.5) score += 20;
    else if (overallStats.profitFactor >= 1.2) score += 15;
    else if (overallStats.profitFactor >= 1.0) score += 10;
    else score += 0;
    
    // Expectancy scoring (max 25 points)
    if (overallStats.expectancy >= 5) score += 25;
    else if (overallStats.expectancy >= 2) score += 20;
    else if (overallStats.expectancy >= 1) score += 15;
    else if (overallStats.expectancy >= 0) score += 10;
    else score += 0;
    
    // Drawdown scoring (max 25 points)
    if (overallStats.maxDrawdownPercent <= 10) score += 25;
    else if (overallStats.maxDrawdownPercent <= 20) score += 20;
    else if (overallStats.maxDrawdownPercent <= 30) score += 15;
    else if (overallStats.maxDrawdownPercent <= 50) score += 10;
    else score += 5;
    
    let letter = 'F';
    let color = 'text-red-500';
    
    if (score >= 90) { letter = 'A+'; color = 'text-green-400'; }
    else if (score >= 80) { letter = 'A'; color = 'text-green-500'; }
    else if (score >= 70) { letter = 'B+'; color = 'text-lime-500'; }
    else if (score >= 60) { letter = 'B'; color = 'text-yellow-500'; }
    else if (score >= 50) { letter = 'C'; color = 'text-orange-500'; }
    else if (score >= 40) { letter = 'D'; color = 'text-orange-600'; }
    
    return { score, letter, color };
  }, [overallStats]);

  // Key insights
  const insights = useMemo(() => {
    const list: { type: 'success' | 'warning' | 'info'; message: string }[] = [];
    
    // Positive insights
    if (overallStats.profitFactor >= 1.5) {
      list.push({ type: 'success', message: `Strong profit factor of ${overallStats.profitFactor.toFixed(2)} indicates consistent edge` });
    }
    if (overallStats.winRate >= 55) {
      list.push({ type: 'success', message: `Above-average win rate of ${overallStats.winRate.toFixed(1)}%` });
    }
    if (overallStats.rrRatio >= 1.5) {
      list.push({ type: 'success', message: `Good risk/reward ratio of ${overallStats.rrRatio.toFixed(2)}:1` });
    }
    if (overallStats.expectancy > 0) {
      list.push({ type: 'success', message: `Positive expectancy of $${overallStats.expectancy.toFixed(2)} per trade` });
    }
    
    // Warnings
    if (overallStats.maxDrawdownPercent > 30) {
      list.push({ type: 'warning', message: `High max drawdown of ${overallStats.maxDrawdownPercent.toFixed(1)}% - consider tighter risk management` });
    }
    if (overallStats.maxConsecLosses >= 5) {
      list.push({ type: 'warning', message: `${overallStats.maxConsecLosses} consecutive losses occurred - ensure proper position sizing` });
    }
    if (overallStats.profitFactor < 1.0 && overallStats.profitFactor !== Infinity) {
      list.push({ type: 'warning', message: `Profit factor below 1.0 indicates losing strategy - review entry criteria` });
    }
    
    // Direction imbalance
    const longPct = directionStats.long.count / overallStats.total * 100;
    if (longPct > 70) {
      list.push({ type: 'info', message: `${longPct.toFixed(0)}% of trades are Longs - consider short opportunities` });
    } else if (longPct < 30) {
      list.push({ type: 'info', message: `Only ${longPct.toFixed(0)}% of trades are Longs - consider long opportunities` });
    }
    
    return list;
  }, [overallStats, directionStats]);

  return (
    <div className="space-y-6">
      {/* Header with Grade */}
      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-2xl font-bold">Strategy Performance Summary</h2>
          <p className="text-muted-foreground mt-1">
            Comprehensive analysis of {overallStats.total.toLocaleString()} trades
          </p>
        </div>
        <Card className="w-32 text-center">
          <CardContent className="pt-4">
            <div className={`text-4xl font-bold ${grade.color}`}>{grade.letter}</div>
            <div className="text-xs text-muted-foreground mt-1">Score: {grade.score}/100</div>
          </CardContent>
        </Card>
      </div>

      {/* Key Metrics Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <DollarSign className="h-3 w-3" /> Net Profit
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.netProfit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
              ${overallStats.netProfit.toFixed(2)}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <Percent className="h-3 w-3" /> Win Rate
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.winRate >= 50 ? 'text-green-500' : 'text-red-500'}`}>
              {overallStats.winRate.toFixed(1)}%
            </div>
            <p className="text-xs text-muted-foreground">{overallStats.wins}W / {overallStats.losses}L</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <BarChart3 className="h-3 w-3" /> Profit Factor
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.profitFactor >= 1.5 ? 'text-green-500' : overallStats.profitFactor >= 1 ? 'text-yellow-500' : 'text-red-500'}`}>
              {overallStats.profitFactor === Infinity ? '∞' : overallStats.profitFactor.toFixed(2)}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <Zap className="h-3 w-3" /> Expectancy
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.expectancy >= 0 ? 'text-green-500' : 'text-red-500'}`}>
              ${overallStats.expectancy.toFixed(2)}
            </div>
            <p className="text-xs text-muted-foreground">per trade</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <Target className="h-3 w-3" /> R:R Ratio
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.rrRatio >= 1.5 ? 'text-green-500' : overallStats.rrRatio >= 1 ? 'text-yellow-500' : 'text-red-500'}`}>
              {overallStats.rrRatio === Infinity ? '∞' : overallStats.rrRatio.toFixed(2)}:1
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground flex items-center gap-1">
              <Shield className="h-3 w-3" /> Max Drawdown
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className={`text-2xl font-bold ${overallStats.maxDrawdownPercent <= 20 ? 'text-green-500' : overallStats.maxDrawdownPercent <= 40 ? 'text-yellow-500' : 'text-red-500'}`}>
              {overallStats.maxDrawdownPercent.toFixed(1)}%
            </div>
            <p className="text-xs text-muted-foreground">${overallStats.maxDrawdown.toFixed(0)}</p>
          </CardContent>
        </Card>
      </div>

      {/* Equity Curve */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Equity Curve with Drawdown
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={equityCurve}>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                <XAxis dataKey="trade" stroke="#666" />
                <YAxis stroke="#666" tickFormatter={(v) => `$${v}`} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#18181b', border: '1px solid #333' }}
                  formatter={(value: number, name: string) => [`$${value.toFixed(2)}`, name === 'equity' ? 'Equity' : 'Peak']}
                />
                <ReferenceLine y={0} stroke="#666" strokeDasharray="3 3" />
                <Line type="monotone" dataKey="peak" stroke="#666" strokeDasharray="5 5" dot={false} strokeWidth={1} />
                <Line type="monotone" dataKey="equity" stroke="#3b82f6" dot={false} strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Long vs Short Comparison */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className={directionStats.long.profit >= 0 ? 'border-green-500/30' : 'border-red-500/30'}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-500" />
              Long Trades Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-3xl font-bold">{directionStats.long.count}</div>
                <div className="text-sm text-muted-foreground">Total Trades</div>
              </div>
              <div>
                <div className={`text-3xl font-bold ${directionStats.long.winRate >= 50 ? 'text-green-500' : 'text-red-500'}`}>
                  {directionStats.long.winRate.toFixed(1)}%
                </div>
                <div className="text-sm text-muted-foreground">Win Rate</div>
              </div>
              <div className="col-span-2">
                <div className={`text-3xl font-bold ${directionStats.long.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${directionStats.long.profit.toFixed(2)}
                </div>
                <div className="text-sm text-muted-foreground">Net Profit</div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className={directionStats.short.profit >= 0 ? 'border-green-500/30' : 'border-red-500/30'}>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingDown className="h-5 w-5 text-red-500" />
              Short Trades Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-3xl font-bold">{directionStats.short.count}</div>
                <div className="text-sm text-muted-foreground">Total Trades</div>
              </div>
              <div>
                <div className={`text-3xl font-bold ${directionStats.short.winRate >= 50 ? 'text-green-500' : 'text-red-500'}`}>
                  {directionStats.short.winRate.toFixed(1)}%
                </div>
                <div className="text-sm text-muted-foreground">Win Rate</div>
              </div>
              <div className="col-span-2">
                <div className={`text-3xl font-bold ${directionStats.short.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${directionStats.short.profit.toFixed(2)}
                </div>
                <div className="text-sm text-muted-foreground">Net Profit</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground">Avg Win</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold text-green-500">${overallStats.avgWin.toFixed(2)}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground">Avg Loss</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold text-red-500">${overallStats.avgLoss.toFixed(2)}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground">Max Consec. Wins</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold text-green-500">{overallStats.maxConsecWins}</div>
          </CardContent>
        </Card>
        
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-xs font-medium text-muted-foreground">Max Consec. Losses</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-xl font-bold text-red-500">{overallStats.maxConsecLosses}</div>
          </CardContent>
        </Card>
      </div>

      {/* Key Insights */}
      <Card className="border-primary/30 bg-primary/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-primary">
            <Award className="h-5 w-5" />
            Key Insights & Recommendations
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {insights.map((insight, i) => (
              <div 
                key={i} 
                className={`flex items-start gap-3 p-3 rounded-lg ${
                  insight.type === 'success' ? 'bg-green-500/10 border border-green-500/30' :
                  insight.type === 'warning' ? 'bg-red-500/10 border border-red-500/30' :
                  'bg-blue-500/10 border border-blue-500/30'
                }`}
              >
                {insight.type === 'success' && <CheckCircle className="h-5 w-5 text-green-500 mt-0.5" />}
                {insight.type === 'warning' && <AlertTriangle className="h-5 w-5 text-red-500 mt-0.5" />}
                {insight.type === 'info' && <Zap className="h-5 w-5 text-blue-500 mt-0.5" />}
                <span className="text-sm">{insight.message}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Executive Summary for Partner */}
      <Card className="bg-gradient-to-br from-zinc-900 to-zinc-800 border-zinc-700">
        <CardHeader>
          <CardTitle className="text-lg">📊 Executive Summary</CardTitle>
        </CardHeader>
        <CardContent className="prose prose-invert prose-sm max-w-none">
          <p>
            This strategy has been tested across <strong>{overallStats.total.toLocaleString()} trades</strong> with a 
            <strong className={overallStats.netProfit >= 0 ? ' text-green-400' : ' text-red-400'}>
              {' '}${overallStats.netProfit.toFixed(2)} net profit
            </strong>.
          </p>
          
          <p>
            The <strong>win rate of {overallStats.winRate.toFixed(1)}%</strong> combined with 
            a <strong>profit factor of {overallStats.profitFactor === Infinity ? '∞' : overallStats.profitFactor.toFixed(2)}</strong> indicates
            {overallStats.profitFactor >= 1.5 ? ' a robust trading edge' : 
             overallStats.profitFactor >= 1.0 ? ' a marginally profitable system' : 
             ' the strategy needs optimization'}.
          </p>
          
          <p>
            Each trade has an expected value of <strong>${overallStats.expectancy.toFixed(2)}</strong>, 
            with winners averaging <strong className="text-green-400">${overallStats.avgWin.toFixed(2)}</strong> and 
            losers averaging <strong className="text-red-400">${overallStats.avgLoss.toFixed(2)}</strong>.
          </p>
          
          <p>
            Risk management shows a maximum drawdown of <strong>{overallStats.maxDrawdownPercent.toFixed(1)}%</strong>, 
            which is {overallStats.maxDrawdownPercent <= 20 ? 'within acceptable limits' : 
                      overallStats.maxDrawdownPercent <= 40 ? 'moderate and should be monitored' : 
                      'high and requires attention'}.
          </p>
          
          <div className="mt-4 p-4 bg-zinc-800/50 rounded-lg">
            <strong>Bottom Line:</strong> 
            {grade.score >= 70 
              ? ` With a grade of ${grade.letter}, this strategy shows strong potential for consistent profitability.`
              : grade.score >= 50
              ? ` With a grade of ${grade.letter}, this strategy has room for improvement but shows promise.`
              : ` With a grade of ${grade.letter}, significant optimization is recommended before live deployment.`
            }
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
