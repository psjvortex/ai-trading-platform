import { useEffect, useState } from 'react'
import Papa from 'papaparse'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { Activity, TrendingUp, TrendingDown, BarChart3, Zap, Sliders, FileSpreadsheet, Download } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Trade } from '../types'
import OptimizationEngine from './OptimizationEngine'
import ExitAnalysis from './ExitAnalysis'
import EfficiencyAnalysis from './EfficiencyAnalysis'
import CorrelationMatrix from './CorrelationMatrix'

export default function Dashboard() {
  const [trades, setTrades] = useState<Trade[]>([])
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState({
    totalTrades: 0,
    netProfit: 0,
    winRate: 0,
    profitFactor: 0,
    avgWin: 0,
    avgLoss: 0
  })
  
  // Global Direction State
  const [direction, setDirection] = useState<'All' | 'Long' | 'Short'>('Long');

  // Filter trades based on direction for global stats
  const filteredTrades = trades.filter(t => {
    if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
    if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
    return true;
  });

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('/data/trades.csv')
        const csvText = await response.text()
        
        Papa.parse(csvText, {
          header: true,
          dynamicTyping: true,
          skipEmptyLines: true,
          complete: (results: Papa.ParseResult<any>) => {
            const parsedTrades = results.data.map((row: any) => ({
              ...row,
              NetProfit: (row.OUT_Profit_OP_01 || 0) + (row.OUT_Commission || 0) + (row.OUT_Swap || 0)
            })) as Trade[]
            
            setTrades(parsedTrades)
            setLoading(false)
          }
        })
      } catch (error) {
        console.error('Error loading data:', error)
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  // Recalculate stats whenever filteredTrades changes
  useEffect(() => {
    calculateStats(filteredTrades)
  }, [filteredTrades])

  const calculateStats = (data: Trade[]) => {
    const totalTrades = data.length
    const netProfit = data.reduce((sum, t) => sum + t.NetProfit, 0)
    const wins = data.filter(t => t.NetProfit > 0)
    const losses = data.filter(t => t.NetProfit <= 0)
    const winRate = (wins.length / totalTrades) * 100
    
    const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0)
    const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0))
    const profitFactor = grossLoss === 0 ? grossProfit : grossProfit / grossLoss

    setStats({
      totalTrades,
      netProfit,
      winRate,
      profitFactor,
      avgWin: wins.length ? grossProfit / wins.length : 0,
      avgLoss: losses.length ? grossLoss / losses.length : 0
    })
  }

  const handleExportAll = () => {
    if (trades.length === 0) return;

    const t = trades[0];
    const symbol = t.Symbol_OP_03 || 'Unknown';
    let tf = t.Chart_TF_OP_01 || 'Unknown';
    
    // Pad single digit timeframes (e.g. M5 -> M05)
    if (tf.match(/^[A-Z]\d$/)) {
      tf = tf.charAt(0) + '0' + tf.charAt(1);
    }

    const version = t.Strategy_Version_ID_OP_03 || 'Unknown';
    const filename = `${symbol}_${tf}_${version}_AllTrades.csv`;

    // Get all keys from the first trade object
    const headers = Object.keys(trades[0]);
    
    const csvContent = [
      headers.join(','),
      ...trades.map(trade => {
        return headers.map(key => {
          const val = trade[key as keyof Trade];
          if (val === null || val === undefined) return '';
          
          // Prevent Excel scientific notation for IDs by prepending tab
          if ((key === 'IN_Trade_ID' || key === 'IN_Deal' || key === 'OUT_Trade_ID' || key === 'OUT_Deal') && val) {
            return `"\t${val}"`;
          }

          if (typeof val === 'string' && val.includes(',')) return `"${val}"`;
          return val;
        }).join(',');
      })
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-background text-primary">
        <div className="animate-pulse flex flex-col items-center">
          <Activity className="h-12 w-12 mb-4 animate-spin" />
          <span className="text-lg font-medium">Loading Physics Data...</span>
        </div>
      </div>
    )
  }

  // Prepare chart data
  let cumulative = 0
  const equityCurve = filteredTrades.map((t, i) => {
    cumulative += t.NetProfit
    return {
      id: i,
      profit: cumulative,
      date: t.IN_MT_MASTER_DATE_TIME
    }
  })

  return (
    <div className="p-8 space-y-8 max-w-[1600px] mx-auto">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-foreground">Alpha Physics Dashboard</h1>
          <p className="text-muted-foreground mt-1">v4.2.0.6 Analysis • 820 Trades • ML Optimization Mode</p>
        </div>
        <div className="flex gap-4">
          <button 
            onClick={handleExportAll}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Download className="h-4 w-4" />
            Export All Trades
          </button>
          <div className="px-4 py-2 bg-card border rounded-lg text-sm font-mono">
            <span className="text-muted-foreground">Net Result:</span>
            <span className={stats.netProfit >= 0 ? "text-green-500 ml-2" : "text-red-500 ml-2"}>
              ${stats.netProfit.toLocaleString(undefined, { minimumFractionDigits: 2 })}
            </span>
          </div>
        </div>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Trades</CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalTrades}</div>
            <p className="text-xs text-muted-foreground">100% Data Integrity</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Win Rate</CardTitle>
            <BarChart3 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.winRate.toFixed(1)}%</div>
            <p className="text-xs text-muted-foreground">
              PF: {stats.profitFactor.toFixed(2)}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Win</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-500">${stats.avgWin.toFixed(2)}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Loss</CardTitle>
            <TrendingDown className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-500">-${stats.avgLoss.toFixed(2)}</div>
          </CardContent>
        </Card>
      </div>

      {/* Equity Curve */}
      <Card className="col-span-4">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Equity Curve</CardTitle>
          
          {/* Global Direction Toggle */}
          <div className="flex bg-background rounded-lg border p-1">
            <button
              onClick={() => setDirection('All')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${direction === 'All' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}`}
            >
              All
            </button>
            <button
              onClick={() => setDirection('Long')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${direction === 'Long' ? 'bg-green-500 text-white' : 'text-muted-foreground hover:text-foreground'}`}
            >
              Longs
            </button>
            <button
              onClick={() => setDirection('Short')}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${direction === 'Short' ? 'bg-red-500 text-white' : 'text-muted-foreground hover:text-foreground'}`}
            >
              Shorts
            </button>
          </div>
        </CardHeader>
        <CardContent className="pl-2">
          <div className="h-[350px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={equityCurve}>
                <CartesianGrid strokeDasharray="3 3" stroke="#333" vertical={false} />
                <XAxis 
                  dataKey="id" 
                  stroke="#666" 
                  tick={{fill: '#666'}} 
                  tickLine={false}
                  axisLine={false}
                />
                <YAxis 
                  stroke="#666" 
                  tick={{fill: '#666'}} 
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={(value) => `$${value}`}
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#18181b', border: '1px solid #333', borderRadius: '8px' }}
                  itemStyle={{ color: '#fff' }}
                  formatter={(value: number) => [`$${value.toFixed(2)}`, 'Equity']}
                />
                <Line 
                  type="monotone" 
                  dataKey="profit" 
                  stroke="#3b82f6" 
                  strokeWidth={2} 
                  dot={false} 
                  activeDot={{ r: 6, fill: '#3b82f6' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Physics Correlation & Pattern Recognition (Moved Up) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="h-[500px]">
          <CorrelationMatrix trades={trades} direction={direction} />
        </div>
        <div className="h-[500px]">
          <EfficiencyAnalysis trades={trades} />
        </div>
      </div>

      {/* Exit Analysis */}
      <div className="h-[800px]">
        <ExitAnalysis trades={trades} direction={direction} />
      </div>

      {/* Optimization Engine */}
      <div className="h-[600px]">
        <OptimizationEngine trades={trades} direction={direction} />
      </div>
    </div>
  )
}
