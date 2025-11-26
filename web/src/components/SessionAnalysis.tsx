import { useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Globe, Sun, Moon, Sunrise, TrendingUp, TrendingDown, BarChart3 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell, PieChart, Pie, Legend } from 'recharts';

interface SessionAnalysisProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

// Trading session definitions (in broker/MT5 server time, typically UTC+2/+3)
const SESSIONS = {
  'Asian': { start: 0, end: 8, color: '#8b5cf6', icon: Moon },      // 00:00 - 08:00
  'London': { start: 8, end: 16, color: '#3b82f6', icon: Sunrise }, // 08:00 - 16:00
  'New York': { start: 13, end: 21, color: '#22c55e', icon: Sun },  // 13:00 - 21:00 (overlap with London)
  'Late NY': { start: 21, end: 24, color: '#f59e0b', icon: Globe }, // 21:00 - 24:00
};

// Session overlap detection
const SESSION_OVERLAPS = {
  'London-NY': { start: 13, end: 16, color: '#14b8a6' }, // Peak liquidity
};

export default function SessionAnalysis({ trades, direction }: SessionAnalysisProps) {
  // Filter trades by direction
  const filteredTrades = useMemo(() => {
    return trades.filter(t => {
      if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
      if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
      return true;
    });
  }, [trades, direction]);

  // Get hour from trade
  const getTradeHour = (t: Trade): number | undefined => {
    const timeStr = (t as any).IN_MT_Time || (t as any).IN_CST_Time_OP_01;
    if (timeStr && typeof timeStr === 'string') {
      const parts = timeStr.split(':');
      if (parts.length >= 1) {
        return parseInt(parts[0], 10);
      }
    }
    if (t.IN_MT_MASTER_DATE_TIME) {
      const date = new Date(t.IN_MT_MASTER_DATE_TIME);
      return date.getHours();
    }
    return undefined;
  };

  // Determine session from hour
  const getSession = (hour: number): string => {
    // Check for London-NY overlap first (peak liquidity)
    if (hour >= 13 && hour < 16) return 'London-NY Overlap';
    if (hour >= 0 && hour < 8) return 'Asian';
    if (hour >= 8 && hour < 13) return 'London';
    if (hour >= 16 && hour < 21) return 'New York';
    return 'Late NY';
  };

  // Calculate session stats
  const sessionStats = useMemo(() => {
    const stats: Record<string, { 
      trades: number; 
      wins: number; 
      losses: number;
      profit: number; 
      avgProfit: number;
      avgWin: number;
      avgLoss: number;
      winRate: number;
      profitFactor: number;
    }> = {};

    // Initialize all sessions
    ['Asian', 'London', 'London-NY Overlap', 'New York', 'Late NY'].forEach(session => {
      stats[session] = { 
        trades: 0, wins: 0, losses: 0, profit: 0, 
        avgProfit: 0, avgWin: 0, avgLoss: 0, winRate: 0, profitFactor: 0 
      };
    });

    // Aggregate trade data
    filteredTrades.forEach(t => {
      const hour = getTradeHour(t);
      if (hour === undefined) return;
      
      const session = getSession(hour);
      if (!stats[session]) return;

      stats[session].trades++;
      stats[session].profit += t.NetProfit;
      
      if (t.NetProfit > 0) {
        stats[session].wins++;
      } else {
        stats[session].losses++;
      }
    });

    // Calculate derived metrics
    Object.keys(stats).forEach(session => {
      const s = stats[session];
      if (s.trades > 0) {
        s.avgProfit = s.profit / s.trades;
        s.winRate = (s.wins / s.trades) * 100;
        
        // Calculate avg win/loss
        const sessionTrades = filteredTrades.filter(t => {
          const hour = getTradeHour(t);
          return hour !== undefined && getSession(hour) === session;
        });
        
        const winningTrades = sessionTrades.filter(t => t.NetProfit > 0);
        const losingTrades = sessionTrades.filter(t => t.NetProfit <= 0);
        
        s.avgWin = winningTrades.length > 0 
          ? winningTrades.reduce((sum, t) => sum + t.NetProfit, 0) / winningTrades.length 
          : 0;
        s.avgLoss = losingTrades.length > 0 
          ? Math.abs(losingTrades.reduce((sum, t) => sum + t.NetProfit, 0) / losingTrades.length)
          : 0;
        
        s.profitFactor = s.avgLoss > 0 
          ? (s.wins * s.avgWin) / (s.losses * s.avgLoss) 
          : s.avgWin > 0 ? Infinity : 0;
      }
    });

    return stats;
  }, [filteredTrades]);

  // Session from CSV field if available
  const sessionFromCSV = useMemo(() => {
    const stats: Record<string, { trades: number; wins: number; profit: number }> = {};
    
    filteredTrades.forEach(t => {
      const session = (t as any).IN_Session_Name_OP_02;
      if (!session) return;
      
      if (!stats[session]) {
        stats[session] = { trades: 0, wins: 0, profit: 0 };
      }
      
      stats[session].trades++;
      stats[session].profit += t.NetProfit;
      if (t.NetProfit > 0) stats[session].wins++;
    });

    return Object.keys(stats).length > 0 ? stats : null;
  }, [filteredTrades]);

  // Chart data for sessions
  const chartData = useMemo(() => {
    return Object.entries(sessionStats)
      .filter(([_, s]) => s.trades > 0)
      .map(([name, s]) => ({
        name,
        profit: s.profit,
        trades: s.trades,
        winRate: s.winRate,
        avgProfit: s.avgProfit,
      }))
      .sort((a, b) => {
        const order = ['Asian', 'London', 'London-NY Overlap', 'New York', 'Late NY'];
        return order.indexOf(a.name) - order.indexOf(b.name);
      });
  }, [sessionStats]);

  // Pie chart data for trade distribution
  const pieData = useMemo(() => {
    return Object.entries(sessionStats)
      .filter(([_, s]) => s.trades > 0)
      .map(([name, s]) => ({
        name,
        value: s.trades,
        profit: s.profit,
      }));
  }, [sessionStats]);

  const COLORS = ['#8b5cf6', '#3b82f6', '#14b8a6', '#22c55e', '#f59e0b'];

  // Best and worst sessions
  const bestSession = useMemo(() => {
    let best = { name: '', profit: -Infinity, winRate: 0, trades: 0 };
    Object.entries(sessionStats).forEach(([name, s]) => {
      if (s.trades >= 5 && s.profit > best.profit) {
        best = { name, profit: s.profit, winRate: s.winRate, trades: s.trades };
      }
    });
    return best;
  }, [sessionStats]);

  const worstSession = useMemo(() => {
    let worst = { name: '', profit: Infinity, winRate: 0, trades: 0 };
    Object.entries(sessionStats).forEach(([name, s]) => {
      if (s.trades >= 5 && s.profit < worst.profit) {
        worst = { name, profit: s.profit, winRate: s.winRate, trades: s.trades };
      }
    });
    return worst;
  }, [sessionStats]);

  return (
    <div className="space-y-6">
      {/* Session Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        {Object.entries(sessionStats).map(([name, s]) => {
          const isPositive = s.profit >= 0;
          const isBest = name === bestSession.name && s.trades >= 5;
          const isWorst = name === worstSession.name && s.trades >= 5 && s.profit < 0;
          
          return (
            <Card 
              key={name} 
              className={`
                ${isBest ? 'border-green-500/50 bg-green-500/5' : ''}
                ${isWorst ? 'border-red-500/50 bg-red-500/5' : ''}
              `}
            >
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium flex items-center gap-2">
                  <Globe className="h-4 w-4 text-muted-foreground" />
                  {name}
                  {isBest && <span className="text-xs text-green-500">★ BEST</span>}
                  {isWorst && <span className="text-xs text-red-500">⚠ AVOID</span>}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${isPositive ? 'text-green-500' : 'text-red-500'}`}>
                  ${s.profit.toFixed(0)}
                </div>
                <div className="text-xs text-muted-foreground space-y-1 mt-2">
                  <div className="flex justify-between">
                    <span>Trades:</span>
                    <span className="font-medium">{s.trades}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Win Rate:</span>
                    <span className={`font-medium ${s.winRate >= 50 ? 'text-green-400' : 'text-red-400'}`}>
                      {s.winRate.toFixed(1)}%
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span>Profit Factor:</span>
                    <span className={`font-medium ${s.profitFactor >= 1.5 ? 'text-green-400' : s.profitFactor >= 1 ? 'text-yellow-400' : 'text-red-400'}`}>
                      {s.profitFactor === Infinity ? '∞' : s.profitFactor.toFixed(2)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Profit by Session Bar Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Profit by Trading Session
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#333" />
                  <XAxis type="number" stroke="#666" tickFormatter={(v) => `$${v}`} />
                  <YAxis type="category" dataKey="name" stroke="#666" width={120} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#18181b', border: '1px solid #333' }}
                    formatter={(value: number, name: string) => {
                      if (name === 'profit') return [`$${value.toFixed(2)}`, 'Profit'];
                      return [value, name];
                    }}
                  />
                  <Bar dataKey="profit" radius={[0, 4, 4, 0]}>
                    {chartData.map((entry, index) => (
                      <Cell 
                        key={`cell-${index}`} 
                        fill={entry.profit >= 0 ? '#22c55e' : '#ef4444'} 
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Trade Distribution Pie Chart */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Globe className="h-5 w-5" />
              Trade Distribution by Session
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={2}
                    dataKey="value"
                    label={({ name, percent }) => `${name} (${((percent || 0) * 100).toFixed(0)}%)`}
                    labelLine={{ stroke: '#666' }}
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#18181b', border: '1px solid #333' }}
                    formatter={(value: number, name: string, props: any) => {
                      return [`${value} trades ($${props.payload.profit.toFixed(0)})`, props.payload.name];
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Detailed Session Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Session Performance Details
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-zinc-700">
                  <th className="text-left p-3">Session</th>
                  <th className="text-right p-3">Hours (Server)</th>
                  <th className="text-right p-3">Trades</th>
                  <th className="text-right p-3">Wins</th>
                  <th className="text-right p-3">Losses</th>
                  <th className="text-right p-3">Win Rate</th>
                  <th className="text-right p-3">Net Profit</th>
                  <th className="text-right p-3">Avg Win</th>
                  <th className="text-right p-3">Avg Loss</th>
                  <th className="text-right p-3">Profit Factor</th>
                </tr>
              </thead>
              <tbody>
                {Object.entries(sessionStats)
                  .filter(([_, s]) => s.trades > 0)
                  .sort((a, b) => {
                    const order = ['Asian', 'London', 'London-NY Overlap', 'New York', 'Late NY'];
                    return order.indexOf(a[0]) - order.indexOf(b[0]);
                  })
                  .map(([name, s]) => {
                    const hours = name === 'Asian' ? '00:00-08:00' :
                                  name === 'London' ? '08:00-13:00' :
                                  name === 'London-NY Overlap' ? '13:00-16:00' :
                                  name === 'New York' ? '16:00-21:00' :
                                  '21:00-24:00';
                    
                    return (
                      <tr key={name} className="border-b border-zinc-800 hover:bg-zinc-800/50">
                        <td className="p-3 font-medium">{name}</td>
                        <td className="p-3 text-right text-muted-foreground">{hours}</td>
                        <td className="p-3 text-right">{s.trades}</td>
                        <td className="p-3 text-right text-green-400">{s.wins}</td>
                        <td className="p-3 text-right text-red-400">{s.losses}</td>
                        <td className={`p-3 text-right font-medium ${s.winRate >= 50 ? 'text-green-400' : 'text-red-400'}`}>
                          {s.winRate.toFixed(1)}%
                        </td>
                        <td className={`p-3 text-right font-bold ${s.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                          ${s.profit.toFixed(2)}
                        </td>
                        <td className="p-3 text-right text-green-400">${s.avgWin.toFixed(2)}</td>
                        <td className="p-3 text-right text-red-400">${s.avgLoss.toFixed(2)}</td>
                        <td className={`p-3 text-right font-medium ${s.profitFactor >= 1.5 ? 'text-green-400' : s.profitFactor >= 1 ? 'text-yellow-400' : 'text-red-400'}`}>
                          {s.profitFactor === Infinity ? '∞' : s.profitFactor.toFixed(2)}
                        </td>
                      </tr>
                    );
                  })}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Session-based CSV data (if available) */}
      {sessionFromCSV && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Globe className="h-5 w-5" />
              Session Data from EA (IN_Session_Name_OP_02)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {Object.entries(sessionFromCSV).map(([session, s]) => {
                const winRate = s.trades > 0 ? (s.wins / s.trades) * 100 : 0;
                return (
                  <div key={session} className="p-4 bg-zinc-800/50 rounded-lg">
                    <div className="text-sm font-medium text-muted-foreground">{session}</div>
                    <div className={`text-xl font-bold ${s.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                      ${s.profit.toFixed(0)}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {s.trades} trades • {winRate.toFixed(0)}% WR
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recommendations */}
      <Card className="border-primary/30 bg-primary/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-primary">
            <TrendingUp className="h-5 w-5" />
            Session Trading Recommendations
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
              <h4 className="font-semibold text-green-400 mb-2">✅ Optimal Sessions</h4>
              <ul className="text-sm space-y-2 text-muted-foreground">
                {bestSession.trades >= 5 && (
                  <li>
                    <strong className="text-green-400">{bestSession.name}</strong>: 
                    Best profitability (+${bestSession.profit.toFixed(0)}, {bestSession.winRate.toFixed(0)}% WR)
                  </li>
                )}
                <li>
                  <strong className="text-teal-400">London-NY Overlap (13:00-16:00)</strong>: 
                  Peak liquidity, tighter spreads, better fills
                </li>
                <li>Consider concentrating trades during high-volume sessions</li>
              </ul>
            </div>
            
            <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
              <h4 className="font-semibold text-red-400 mb-2">⚠️ Caution Sessions</h4>
              <ul className="text-sm space-y-2 text-muted-foreground">
                {worstSession.trades >= 5 && worstSession.profit < 0 && (
                  <li>
                    <strong className="text-red-400">{worstSession.name}</strong>: 
                    Underperforming (${worstSession.profit.toFixed(0)}, {worstSession.winRate.toFixed(0)}% WR)
                  </li>
                )}
                <li>
                  <strong>Late NY (21:00-24:00)</strong>: 
                  Lower liquidity, wider spreads common
                </li>
                <li>Consider reducing size or avoiding weak sessions entirely</li>
              </ul>
            </div>
          </div>

          <div className="p-4 bg-zinc-800/50 rounded-lg">
            <h4 className="font-semibold mb-2">📊 EA Session Filter Suggestion</h4>
            <p className="text-sm text-muted-foreground mb-2">
              Based on your data, consider these session-based time filters:
            </p>
            <code className="text-xs bg-zinc-900 p-2 rounded block overflow-x-auto">
{`// Optimized session-based time filter
input bool UseTimeFilter = true;
input int TradingStartHour = 8;   // Start at London open
input int TradingEndHour = 21;    // End at NY close
// This captures London, London-NY Overlap, and NY sessions`}
            </code>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
