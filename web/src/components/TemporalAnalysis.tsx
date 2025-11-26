import { useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Calendar, Clock, TrendingUp, TrendingDown, AlertTriangle, CheckCircle } from 'lucide-react';

interface TemporalAnalysisProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

// Days of week for display
const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const SHORT_DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

// Hours for display (0-23)
const HOURS = Array.from({ length: 24 }, (_, i) => i);

export default function TemporalAnalysis({ trades, direction }: TemporalAnalysisProps) {
  // Filter trades by direction
  const filteredTrades = useMemo(() => {
    return trades.filter(t => {
      if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
      if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
      return true;
    });
  }, [trades, direction]);

  // Calculate day-of-week stats
  const dayStats = useMemo(() => {
    const stats: Record<string, { trades: number; wins: number; profit: number; avgProfit: number }> = {};
    
    DAYS.forEach(day => {
      stats[day] = { trades: 0, wins: 0, profit: 0, avgProfit: 0 };
    });

    filteredTrades.forEach(t => {
      // Try to get day from IN_MT_Day or IN_CST_Day_OP_01
      let day = (t as any).IN_MT_Day || (t as any).IN_CST_Day_OP_01;
      
      // If not available, parse from datetime
      if (!day && t.IN_MT_MASTER_DATE_TIME) {
        const date = new Date(t.IN_MT_MASTER_DATE_TIME);
        day = DAYS[date.getDay()];
      }
      
      if (day && stats[day]) {
        stats[day].trades++;
        stats[day].profit += t.NetProfit;
        if (t.NetProfit > 0) stats[day].wins++;
      }
    });

    // Calculate averages and win rates
    Object.keys(stats).forEach(day => {
      if (stats[day].trades > 0) {
        stats[day].avgProfit = stats[day].profit / stats[day].trades;
      }
    });

    return stats;
  }, [filteredTrades]);

  // Calculate hour-of-day stats
  const hourStats = useMemo(() => {
    const stats: Record<number, { trades: number; wins: number; profit: number; avgProfit: number }> = {};
    
    HOURS.forEach(hour => {
      stats[hour] = { trades: 0, wins: 0, profit: 0, avgProfit: 0 };
    });

    filteredTrades.forEach(t => {
      // Try to get hour from IN_MT_Time or parse from datetime
      let hour: number | undefined;
      
      const timeStr = (t as any).IN_MT_Time || (t as any).IN_CST_Time_OP_01;
      if (timeStr && typeof timeStr === 'string') {
        const parts = timeStr.split(':');
        if (parts.length >= 1) {
          hour = parseInt(parts[0], 10);
        }
      }
      
      // Fallback to parsing datetime
      if (hour === undefined && t.IN_MT_MASTER_DATE_TIME) {
        const date = new Date(t.IN_MT_MASTER_DATE_TIME);
        hour = date.getHours();
      }
      
      if (hour !== undefined && stats[hour]) {
        stats[hour].trades++;
        stats[hour].profit += t.NetProfit;
        if (t.NetProfit > 0) stats[hour].wins++;
      }
    });

    // Calculate averages
    Object.keys(stats).forEach(h => {
      const hour = parseInt(h, 10);
      if (stats[hour].trades > 0) {
        stats[hour].avgProfit = stats[hour].profit / stats[hour].trades;
      }
    });

    return stats;
  }, [filteredTrades]);

  // Create day/hour heatmap data
  const heatmapData = useMemo(() => {
    const data: Record<string, Record<number, { trades: number; wins: number; profit: number }>> = {};
    
    DAYS.forEach(day => {
      data[day] = {};
      HOURS.forEach(hour => {
        data[day][hour] = { trades: 0, wins: 0, profit: 0 };
      });
    });

    filteredTrades.forEach(t => {
      let day: string | undefined;
      let hour: number | undefined;
      
      // Get day
      day = (t as any).IN_MT_Day || (t as any).IN_CST_Day_OP_01;
      if (!day && t.IN_MT_MASTER_DATE_TIME) {
        const date = new Date(t.IN_MT_MASTER_DATE_TIME);
        day = DAYS[date.getDay()];
      }
      
      // Get hour
      const timeStr = (t as any).IN_MT_Time || (t as any).IN_CST_Time_OP_01;
      if (timeStr && typeof timeStr === 'string') {
        const parts = timeStr.split(':');
        if (parts.length >= 1) {
          hour = parseInt(parts[0], 10);
        }
      }
      if (hour === undefined && t.IN_MT_MASTER_DATE_TIME) {
        const date = new Date(t.IN_MT_MASTER_DATE_TIME);
        hour = date.getHours();
      }
      
      if (day && hour !== undefined && data[day] && data[day][hour]) {
        data[day][hour].trades++;
        data[day][hour].profit += t.NetProfit;
        if (t.NetProfit > 0) data[day][hour].wins++;
      }
    });

    return data;
  }, [filteredTrades]);

  // Find best and worst periods
  const bestDay = useMemo(() => {
    let best = { day: '', profit: -Infinity, winRate: 0, trades: 0 };
    Object.entries(dayStats).forEach(([day, stats]) => {
      if (stats.trades >= 5 && stats.profit > best.profit) {
        best = { day, profit: stats.profit, winRate: (stats.wins / stats.trades) * 100, trades: stats.trades };
      }
    });
    return best;
  }, [dayStats]);

  const worstDay = useMemo(() => {
    let worst = { day: '', profit: Infinity, winRate: 0, trades: 0 };
    Object.entries(dayStats).forEach(([day, stats]) => {
      if (stats.trades >= 5 && stats.profit < worst.profit) {
        worst = { day, profit: stats.profit, winRate: (stats.wins / stats.trades) * 100, trades: stats.trades };
      }
    });
    return worst;
  }, [dayStats]);

  const bestHour = useMemo(() => {
    let best = { hour: 0, profit: -Infinity, winRate: 0, trades: 0 };
    Object.entries(hourStats).forEach(([h, stats]) => {
      const hour = parseInt(h, 10);
      if (stats.trades >= 3 && stats.profit > best.profit) {
        best = { hour, profit: stats.profit, winRate: (stats.wins / stats.trades) * 100, trades: stats.trades };
      }
    });
    return best;
  }, [hourStats]);

  const worstHour = useMemo(() => {
    let worst = { hour: 0, profit: Infinity, winRate: 0, trades: 0 };
    Object.entries(hourStats).forEach(([h, stats]) => {
      const hour = parseInt(h, 10);
      if (stats.trades >= 3 && stats.profit < worst.profit) {
        worst = { hour, profit: stats.profit, winRate: (stats.wins / stats.trades) * 100, trades: stats.trades };
      }
    });
    return worst;
  }, [hourStats]);

  // Color scale for heatmap
  const getWinRateColor = (wins: number, trades: number) => {
    if (trades === 0) return 'bg-zinc-800';
    const winRate = wins / trades;
    if (winRate >= 0.6) return 'bg-green-600';
    if (winRate >= 0.5) return 'bg-green-500/70';
    if (winRate >= 0.4) return 'bg-yellow-500/70';
    if (winRate >= 0.3) return 'bg-orange-500/70';
    return 'bg-red-500/70';
  };

  const getProfitColor = (profit: number, maxProfit: number, minProfit: number) => {
    if (profit === 0) return 'bg-zinc-800';
    const range = Math.max(Math.abs(maxProfit), Math.abs(minProfit));
    const normalized = profit / range;
    
    if (normalized >= 0.5) return 'bg-green-600';
    if (normalized >= 0.2) return 'bg-green-500/70';
    if (normalized >= 0) return 'bg-green-500/40';
    if (normalized >= -0.2) return 'bg-red-500/40';
    if (normalized >= -0.5) return 'bg-red-500/70';
    return 'bg-red-600';
  };

  // Calculate max/min for color scaling
  const { maxProfit, minProfit } = useMemo(() => {
    let max = 0, min = 0;
    Object.values(dayStats).forEach(s => {
      if (s.profit > max) max = s.profit;
      if (s.profit < min) min = s.profit;
    });
    return { maxProfit: max, minProfit: min };
  }, [dayStats]);

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="bg-green-500/10 border-green-500/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              Best Day
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-500">{bestDay.day || 'N/A'}</div>
            <p className="text-xs text-muted-foreground">
              ${bestDay.profit.toFixed(0)} ({bestDay.winRate.toFixed(0)}% WR, {bestDay.trades} trades)
            </p>
          </CardContent>
        </Card>

        <Card className="bg-red-500/10 border-red-500/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-red-500" />
              Worst Day
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-500">{worstDay.day || 'N/A'}</div>
            <p className="text-xs text-muted-foreground">
              ${worstDay.profit.toFixed(0)} ({worstDay.winRate.toFixed(0)}% WR, {worstDay.trades} trades)
            </p>
          </CardContent>
        </Card>

        <Card className="bg-green-500/10 border-green-500/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="h-4 w-4 text-green-500" />
              Best Hour
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-500">
              {bestHour.hour.toString().padStart(2, '0')}:00
            </div>
            <p className="text-xs text-muted-foreground">
              ${bestHour.profit.toFixed(0)} ({bestHour.winRate.toFixed(0)}% WR, {bestHour.trades} trades)
            </p>
          </CardContent>
        </Card>

        <Card className="bg-red-500/10 border-red-500/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Clock className="h-4 w-4 text-red-500" />
              Worst Hour
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-500">
              {worstHour.hour.toString().padStart(2, '0')}:00
            </div>
            <p className="text-xs text-muted-foreground">
              ${worstHour.profit.toFixed(0)} ({worstHour.winRate.toFixed(0)}% WR, {worstHour.trades} trades)
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Day of Week Bar Chart */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Performance by Day of Week
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {DAYS.map(day => {
              const stats = dayStats[day];
              const winRate = stats.trades > 0 ? (stats.wins / stats.trades) * 100 : 0;
              const maxDayProfit = Math.max(...Object.values(dayStats).map(s => Math.abs(s.profit)));
              const barWidth = maxDayProfit > 0 ? (Math.abs(stats.profit) / maxDayProfit) * 100 : 0;
              
              return (
                <div key={day} className="flex items-center gap-4">
                  <div className="w-24 text-sm font-medium">{day}</div>
                  <div className="flex-1 flex items-center gap-2">
                    <div className="flex-1 h-8 bg-zinc-800 rounded-lg overflow-hidden relative">
                      <div 
                        className={`h-full ${stats.profit >= 0 ? 'bg-green-500' : 'bg-red-500'} transition-all duration-300`}
                        style={{ width: `${barWidth}%` }}
                      />
                      <div className="absolute inset-0 flex items-center px-2 justify-between">
                        <span className="text-xs font-mono">
                          {stats.trades} trades
                        </span>
                        <span className={`text-xs font-bold ${stats.profit >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                          ${stats.profit.toFixed(0)}
                        </span>
                      </div>
                    </div>
                    <div className="w-16 text-right text-sm">
                      <span className={winRate >= 50 ? 'text-green-400' : 'text-red-400'}>
                        {winRate.toFixed(0)}%
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Hour of Day Chart */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Performance by Hour (Broker Time)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-12 gap-1">
            {HOURS.map(hour => {
              const stats = hourStats[hour];
              const winRate = stats.trades > 0 ? (stats.wins / stats.trades) * 100 : 0;
              const maxHourProfit = Math.max(...Object.values(hourStats).map(s => Math.abs(s.profit)));
              const barHeight = maxHourProfit > 0 ? (Math.abs(stats.profit) / maxHourProfit) * 100 : 0;
              
              return (
                <div key={hour} className="flex flex-col items-center">
                  <div className="h-24 w-full flex items-end justify-center mb-1">
                    <div 
                      className={`w-full max-w-6 rounded-t ${stats.profit >= 0 ? 'bg-green-500' : 'bg-red-500'} transition-all duration-300`}
                      style={{ height: `${Math.max(barHeight, 4)}%` }}
                      title={`$${stats.profit.toFixed(0)} | ${stats.trades} trades | ${winRate.toFixed(0)}% WR`}
                    />
                  </div>
                  <div className="text-xs text-muted-foreground">
                    {hour.toString().padStart(2, '0')}
                  </div>
                  <div className={`text-xs font-medium ${winRate >= 50 ? 'text-green-400' : winRate > 0 ? 'text-red-400' : 'text-zinc-600'}`}>
                    {stats.trades > 0 ? `${winRate.toFixed(0)}%` : '-'}
                  </div>
                </div>
              );
            })}
          </div>
          <div className="mt-4 text-xs text-muted-foreground text-center">
            Hover over bars for details. Hours shown in broker server time.
          </div>
        </CardContent>
      </Card>

      {/* Day/Hour Heatmap */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Win Rate Heatmap (Day × Hour)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto pb-2">
            {/* Hour Headers */}
            <div className="flex items-center gap-1 mb-2">
              <div className="w-12 text-xs text-muted-foreground font-medium">Day</div>
              {HOURS.map(h => (
                <div 
                  key={h} 
                  className="w-9 h-6 flex items-center justify-center text-xs text-muted-foreground font-medium"
                >
                  {h.toString().padStart(2, '0')}
                </div>
              ))}
            </div>
            
            {/* Heatmap Rows */}
            <div className="space-y-1">
              {DAYS.map(day => (
                <div key={day} className="flex items-center gap-1">
                  <div className="w-12 text-xs font-medium text-foreground">
                    {SHORT_DAYS[DAYS.indexOf(day)]}
                  </div>
                  {HOURS.map(hour => {
                    const cell = heatmapData[day][hour];
                    const winRate = cell.trades > 0 ? cell.wins / cell.trades : 0;
                    
                    // Better color function with smooth transitions
                    const getCellStyle = () => {
                      if (cell.trades === 0) return 'bg-zinc-800/50 text-zinc-600';
                      if (winRate >= 0.6) return 'bg-emerald-500 text-emerald-950 font-semibold';
                      if (winRate >= 0.5) return 'bg-green-500/80 text-green-950 font-medium';
                      if (winRate >= 0.4) return 'bg-yellow-500/80 text-yellow-950 font-medium';
                      if (winRate >= 0.3) return 'bg-orange-500/80 text-orange-950 font-medium';
                      return 'bg-red-500/80 text-red-950 font-medium';
                    };
                    
                    return (
                      <div 
                        key={hour} 
                        className={`w-9 h-9 flex items-center justify-center text-xs rounded-md cursor-default transition-all hover:scale-110 hover:z-10 hover:shadow-lg ${getCellStyle()}`}
                        title={`${day} ${hour.toString().padStart(2, '0')}:00\n${cell.trades} trades\n${(winRate * 100).toFixed(0)}% win rate\n$${cell.profit.toFixed(0)} profit`}
                      >
                        {cell.trades > 0 ? cell.trades : ''}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
          
          {/* Legend */}
          <div className="mt-6 flex items-center justify-center gap-6 text-xs">
            <span className="text-muted-foreground font-medium">Win Rate:</span>
            <div className="flex items-center gap-1.5">
              <div className="w-5 h-5 bg-red-500/80 rounded-md" />
              <span className="text-muted-foreground">&lt;30%</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-5 h-5 bg-orange-500/80 rounded-md" />
              <span className="text-muted-foreground">30-40%</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-5 h-5 bg-yellow-500/80 rounded-md" />
              <span className="text-muted-foreground">40-50%</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-5 h-5 bg-green-500/80 rounded-md" />
              <span className="text-muted-foreground">50-60%</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-5 h-5 bg-emerald-500 rounded-md" />
              <span className="text-muted-foreground">&gt;60%</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Recommendations */}
      <Card className="border-primary/30 bg-primary/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-primary">
            <TrendingUp className="h-5 w-5" />
            Optimization Recommendations
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
              <h4 className="font-semibold text-green-400 mb-2">✅ Recommended Trading Windows</h4>
              <ul className="text-sm space-y-1 text-muted-foreground">
                {bestDay.trades >= 5 && (
                  <li>• <strong>{bestDay.day}</strong>: Best performing day (+${bestDay.profit.toFixed(0)})</li>
                )}
                {bestHour.trades >= 3 && (
                  <li>• <strong>{bestHour.hour.toString().padStart(2, '0')}:00</strong>: Most profitable hour</li>
                )}
                <li>• Consider increasing position size during peak hours</li>
              </ul>
            </div>
            
            <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
              <h4 className="font-semibold text-red-400 mb-2">⚠️ Consider Avoiding</h4>
              <ul className="text-sm space-y-1 text-muted-foreground">
                {worstDay.trades >= 5 && worstDay.profit < 0 && (
                  <li>• <strong>{worstDay.day}</strong>: Worst performing day (${worstDay.profit.toFixed(0)})</li>
                )}
                {worstHour.trades >= 3 && worstHour.profit < 0 && (
                  <li>• <strong>{worstHour.hour.toString().padStart(2, '0')}:00</strong>: Least profitable hour</li>
                )}
                <li>• Use EA time filters to block unprofitable periods</li>
              </ul>
            </div>
          </div>
          
          <div className="p-4 bg-zinc-800/50 rounded-lg">
            <h4 className="font-semibold mb-2">📊 EA Filter Suggestion</h4>
            <code className="text-xs bg-zinc-900 p-2 rounded block overflow-x-auto">
              {`// Suggested EA Time Filters based on analysis
input bool UseTimeFilter = true;
input int TradingStartHour = ${bestHour.hour > 2 ? bestHour.hour - 2 : 0};
input int TradingEndHour = ${bestHour.hour < 21 ? bestHour.hour + 3 : 23};
input bool UseDayOfWeekFilter = true;
input bool TradeOn${worstDay.day} = ${worstDay.profit >= 0 ? 'true' : 'false'}; // ${worstDay.profit >= 0 ? 'Profitable' : 'Unprofitable'}`}
            </code>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
