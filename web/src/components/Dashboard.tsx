import { useEffect, useState, useMemo, useCallback } from 'react'
import Papa from 'papaparse'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { Activity, TrendingUp, TrendingDown, BarChart3, Zap, Sliders, FileSpreadsheet, Download, Clock, Calendar, LayoutDashboard, Settings, LineChartIcon, Filter, ArrowUpDown, Upload, GitCompare } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Trade, getPassLabel, getSampleLabel, getPassColor, getSampleColor } from '../types'
import { OptimizationFilter, optimizeStrategy } from '../lib/analytics'
import { OptimizationRunMeta } from '../lib/csvProcessor'
import OptimizationEngine from './OptimizationEngine'
import ExitAnalysis from './ExitAnalysis'
import EfficiencyAnalysis from './EfficiencyAnalysis'
import CorrelationMatrix from './CorrelationMatrix'
import TemporalAnalysis from './TemporalAnalysis'
import SessionAnalysis from './SessionAnalysis'
import PerformanceSummary from './PerformanceSummary'
import { ExcursionAnalysis } from './ExcursionAnalysis'
import { DataLoader } from './DataLoader'
import { RunSelector } from './RunSelector'
import { RunComparison } from './RunComparison'
import { PassComparison } from './PassComparison'

export default function Dashboard() {
  const [trades, setTrades] = useState<Trade[]>([])
  const [loading, setLoading] = useState(true)
  const [showDataLoader, setShowDataLoader] = useState(false)
  const [showComparison, setShowComparison] = useState(false)
  const [currentRunId, setCurrentRunId] = useState<string | null>(null)
  const [runMetadata, setRunMetadata] = useState<OptimizationRunMeta | null>(null)
  const [eaInputs, setEaInputs] = useState<Record<string, any> | null>(null)
  const [allEaInputs, setAllEaInputs] = useState<Record<string, any> | null>(null)
  const [stats, setStats] = useState({
    totalTrades: 0,
    netProfit: 0,
    winRate: 0,
    profitFactor: 0,
    avgWin: 0,
    avgLoss: 0,
    // Extended stats
    wins: 0,
    losses: 0,
    grossProfit: 0,
    grossLoss: 0,
    expectancy: 0,
    maxWin: 0,
    maxLoss: 0,
    maxDrawdown: 0,
    maxDrawdownPct: 0,
    avgHoldTime: 0,
    longsCount: 0,
    shortsCount: 0,
    longWinRate: 0,
    shortWinRate: 0
  })
  
  // Global Direction State - defaults to 'All' to show Combined stats highlighted
  const [direction, setDirection] = useState<'All' | 'Long' | 'Short'>('All');
  
  // Active Tab State
  const [activeTab, setActiveTab] = useState<'overview' | 'summary' | 'temporal' | 'sessions' | 'optimization' | 'excursions' | 'analysis' | 'comparison'>('overview');
  
  // Lifted Optimization Filter State (shared across all tabs)
  const [longFilters, setLongFilters] = useState<OptimizationFilter[]>([]);
  const [shortFilters, setShortFilters] = useState<OptimizationFilter[]>([]);
  const [allFilters, setAllFilters] = useState<OptimizationFilter[]>([]);

  // Handler for when data is loaded from DataLoader
  const handleDataLoaded = useCallback((loadedTrades: Trade[], metadata?: OptimizationRunMeta) => {
    const tradesWithNetProfit = loadedTrades.map(t => ({
      ...t,
      NetProfit: (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0)
    }))
    setTrades(tradesWithNetProfit)
    setRunMetadata(metadata || null)
    setShowDataLoader(false)
    setLoading(false)
  }, [])

  // Calculate optimized trades based on direction and filters
  const optimizedTrades = useMemo(() => {
    if (trades.length === 0) return [];
    
    if (direction === 'All') {
      // For 'All', apply Long filters to longs and Short filters to shorts, then combine
      const longResult = optimizeStrategy(trades, 'Long', longFilters);
      const shortResult = optimizeStrategy(trades, 'Short', shortFilters);
      return [...longResult.trades, ...shortResult.trades];
    } else {
      const filters = direction === 'Long' ? longFilters : shortFilters;
      const result = optimizeStrategy(trades, direction, filters);
      return result.trades;
    }
  }, [trades, direction, longFilters, shortFilters, allFilters]);

  // Check if optimization is active
  const hasActiveFilters = useMemo(() => {
    const activeFilters = direction === 'Long' ? longFilters : direction === 'Short' ? shortFilters : [...longFilters, ...shortFilters];
    return activeFilters.some(f => f.enabled !== false);
  }, [direction, longFilters, shortFilters]);

  // Filter trades based on direction for global stats
  const filteredTrades = trades.filter(t => {
    if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
    if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
    return true;
  });

  // Load a specific run by ID
  const loadRun = useCallback(async (runId: string) => {
    try {
      setLoading(true);
      const response = await fetch(`/data/runs/${runId}.json`);
      if (response.ok) {
        const jsonData = await response.json();
        const parsedTrades = (jsonData.trades || []).map((row: any) => ({
          ...row,
          NetProfit: (row.OUT_Profit_OP_01 || 0) + (row.OUT_Commission || 0) + (row.OUT_Swap || 0)
        })) as Trade[];
        
        if (jsonData.metadata?.optimizationRun) {
          const opt = jsonData.metadata.optimizationRun;
          setRunMetadata({
            symbol: opt.symbol || '',
            timeframe: opt.timeframe || '',
            broker: opt.broker || '',
            pass: opt.pass || '',
            passNumber: opt.passNumber ?? 0,
            sampleType: opt.sampleType || '',
            isInSample: opt.isInSample ?? true,
            oosNumber: opt.oosNumber,
            dateRange: opt.dateRange || '',
            eaVersion: opt.eaVersion || '',
            fileType: opt.fileType || 'trades',
            rawFilename: opt.rawFilename || ''
          });
        }
        
        // Load EA input values if present
        if (jsonData.metadata?.eaInputs) {
          setEaInputs(jsonData.metadata.eaInputs);
          console.log('📊 Loaded EA filter inputs:', Object.keys(jsonData.metadata.eaInputs).length, 'parameters');
        } else {
          setEaInputs(null);
        }
        
        // Load ALL EA inputs for complete block generation
        if (jsonData.metadata?.allEaInputs) {
          setAllEaInputs(jsonData.metadata.allEaInputs);
          console.log('📊 Loaded ALL EA inputs:', Object.keys(jsonData.metadata.allEaInputs).length, 'parameters');
        } else {
          setAllEaInputs(null);
        }
        
        setTrades(parsedTrades);
        setCurrentRunId(runId);
      }
    } catch (error) {
      console.error('Error loading run:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  // Handle run selection from dropdown
  const handleRunSelect = useCallback((runId: string) => {
    loadRun(runId);
  }, [loadRun]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // First check if there's a runs index
        const indexResponse = await fetch('/data/runs/index.json');
        if (indexResponse.ok) {
          const indexData = await indexResponse.json();
          if (indexData.runs && indexData.runs.length > 0) {
            // Load the first run (most recent baseline IS)
            const firstRun = indexData.runs[0];
            await loadRun(firstRun.id);
            return;
          }
        }
        
        // Fallback: try to load JSON (includes metadata)
        const jsonResponse = await fetch('/data/trades.json')
        if (jsonResponse.ok) {
          const jsonText = await jsonResponse.text()
          if (!jsonText.startsWith('<!') && !jsonText.startsWith('<html')) {
            try {
              const jsonData = JSON.parse(jsonText)
              
              // Extract trades from JSON
              const parsedTrades = (jsonData.trades || []).map((row: any) => ({
                ...row,
                NetProfit: (row.OUT_Profit_OP_01 || 0) + (row.OUT_Commission || 0) + (row.OUT_Swap || 0)
              })) as Trade[]
              
              // Extract optimization metadata if present
              if (jsonData.metadata?.optimizationRun) {
                const opt = jsonData.metadata.optimizationRun
                setRunMetadata({
                  symbol: opt.symbol || '',
                  timeframe: opt.timeframe || '',
                  broker: opt.broker || '',
                  pass: opt.pass || '',
                  passNumber: opt.passNumber ?? 0,
                  sampleType: opt.sampleType || '',
                  isInSample: opt.isInSample ?? true,
                  oosNumber: opt.oosNumber,
                  dateRange: opt.dateRange || '',
                  eaVersion: opt.eaVersion || '',
                  fileType: opt.fileType || 'trades',
                  rawFilename: opt.rawFilename || ''
                })
                console.log('Loaded optimization metadata:', opt)
              }
              
              if (parsedTrades.length > 0) {
                setTrades(parsedTrades)
                setLoading(false)
                return
              }
            } catch (e) {
              console.log('JSON parse failed, trying CSV')
            }
          }
        }
        
        // Fallback to CSV
        const response = await fetch('/data/trades.csv')
        
        // Check if response is OK (200-299) 
        if (!response.ok) {
          console.log('No trades.csv found, showing DataLoader')
          setLoading(false)
          return
        }
        
        const csvText = await response.text()
        
        // Check if we got actual CSV data (not HTML error page)
        if (csvText.startsWith('<!') || csvText.startsWith('<html')) {
          console.log('Received HTML instead of CSV, showing DataLoader')
          setLoading(false)
          return
        }
        
        Papa.parse(csvText, {
          header: true,
          dynamicTyping: true,
          skipEmptyLines: true,
          complete: (results: Papa.ParseResult<any>) => {
            const parsedTrades = results.data.map((row: any) => ({
              ...row,
              NetProfit: (row.OUT_Profit_OP_01 || 0) + (row.OUT_Commission || 0) + (row.OUT_Swap || 0)
            })) as Trade[]
            
            if (parsedTrades.length === 0) {
              console.log('No trades in CSV, showing DataLoader')
            }
            
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

  // Recalculate stats whenever optimizedTrades changes
  useEffect(() => {
    calculateStats(optimizedTrades)
  }, [optimizedTrades])

  const calculateStats = (data: Trade[]) => {
    if (data.length === 0) return;
    
    const totalTrades = data.length
    const netProfit = data.reduce((sum, t) => sum + t.NetProfit, 0)
    const wins = data.filter(t => t.NetProfit > 0)
    const losses = data.filter(t => t.NetProfit <= 0)
    const winRate = totalTrades > 0 ? (wins.length / totalTrades) * 100 : 0
    
    const grossProfit = wins.reduce((sum, t) => sum + t.NetProfit, 0)
    const grossLoss = Math.abs(losses.reduce((sum, t) => sum + t.NetProfit, 0))
    const profitFactor = grossLoss === 0 ? (grossProfit > 0 ? Infinity : 0) : grossProfit / grossLoss

    // Max win/loss
    const maxWin = wins.length > 0 ? Math.max(...wins.map(t => t.NetProfit)) : 0
    const maxLoss = losses.length > 0 ? Math.min(...losses.map(t => t.NetProfit)) : 0

    // Calculate max drawdown
    let peak = 0
    let maxDD = 0
    let runningPnL = 0
    data.forEach(t => {
      runningPnL += t.NetProfit
      if (runningPnL > peak) peak = runningPnL
      const dd = peak - runningPnL
      if (dd > maxDD) maxDD = dd
    })
    const startingBalance = 10000
    const maxDrawdownPct = peak > 0 ? (maxDD / (startingBalance + peak)) * 100 : 0

    // Expectancy (average profit per trade)
    const expectancy = totalTrades > 0 ? netProfit / totalTrades : 0

    // Direction breakdown
    const longs = data.filter(t => t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy')
    const shorts = data.filter(t => t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell')
    const longWins = longs.filter(t => t.NetProfit > 0)
    const shortWins = shorts.filter(t => t.NetProfit > 0)

    setStats({
      totalTrades,
      netProfit,
      winRate,
      profitFactor,
      avgWin: wins.length ? grossProfit / wins.length : 0,
      avgLoss: losses.length ? grossLoss / losses.length : 0,
      wins: wins.length,
      losses: losses.length,
      grossProfit,
      grossLoss,
      expectancy,
      maxWin,
      maxLoss,
      maxDrawdown: maxDD,
      maxDrawdownPct,
      avgHoldTime: 0, // Would need duration data
      longsCount: longs.length,
      shortsCount: shorts.length,
      longWinRate: longs.length > 0 ? (longWins.length / longs.length) * 100 : 0,
      shortWinRate: shorts.length > 0 ? (shortWins.length / shorts.length) * 100 : 0
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

  // Show DataLoader if requested or no trades
  if (showDataLoader || trades.length === 0) {
    return <DataLoader onDataLoaded={handleDataLoaded} />
  }

  // Prepare chart data
  let cumulative = 0
  const equityCurve = optimizedTrades.map((t, i) => {
    cumulative += t.NetProfit
    return {
      id: i,
      profit: cumulative,
      date: t.IN_MT_MASTER_DATE_TIME
    }
  })

  return (
    <div className="p-8 space-y-8 max-w-[1600px] mx-auto">
      {/* Comparison Modal */}
      {showComparison && <RunComparison onClose={() => setShowComparison(false)} />}
      
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-foreground">Alpha Physics Dashboard</h1>
          {runMetadata ? (
            <div className="flex items-center gap-2 mt-1">
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${getPassColor(runMetadata.pass)}`}>
                {getPassLabel(runMetadata.pass)}
              </span>
              <span className={`px-2 py-0.5 rounded text-xs font-medium ${getSampleColor(runMetadata.sampleType)}`}>
                {getSampleLabel(runMetadata.sampleType)}
              </span>
              <span className="text-muted-foreground text-sm">
                v{runMetadata.eaVersion} • {runMetadata.symbol} {runMetadata.timeframe} • {runMetadata.broker} • {runMetadata.dateRange} • {stats.totalTrades} Trades
              </span>
            </div>
          ) : (
            <p className="text-muted-foreground mt-1">
              {stats.totalTrades} Trades • <span className="text-zinc-400">$10,000 Starting Balance</span>
            </p>
          )}
        </div>
        <div className="flex items-center gap-4">
          {/* Run Selector */}
          <RunSelector 
            currentRunId={currentRunId}
            onRunSelect={handleRunSelect}
            onCompareToggle={() => setShowComparison(true)}
            compareMode={showComparison}
          />
          <button 
            onClick={() => setShowDataLoader(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Upload className="h-4 w-4" />
            Load New Data
          </button>
          <button 
            onClick={handleExportAll}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Download className="h-4 w-4" />
            Export All Trades
          </button>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="flex items-center justify-between border-b border-border">
        <div className="flex gap-1">
          <button
            onClick={() => setActiveTab('overview')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'overview' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <LayoutDashboard className="h-4 w-4" />
            Overview
          </button>
          <button
            onClick={() => setActiveTab('summary')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'summary' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <BarChart3 className="h-4 w-4" />
            Summary
          </button>
          <button
            onClick={() => setActiveTab('temporal')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'temporal' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <Clock className="h-4 w-4" />
            Temporal
          </button>
          <button
            onClick={() => setActiveTab('sessions')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'sessions' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <Calendar className="h-4 w-4" />
            Sessions
          </button>
          <button
            onClick={() => setActiveTab('optimization')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'optimization' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <Settings className="h-4 w-4" />
            Optimization
          </button>
          <button
            onClick={() => setActiveTab('excursions')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'excursions' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <ArrowUpDown className="h-4 w-4" />
            Excursions
          </button>
          <button
            onClick={() => setActiveTab('analysis')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'analysis' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <LineChartIcon className="h-4 w-4" />
            Analysis
          </button>
          <button
            onClick={() => setActiveTab('comparison')}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === 'comparison' 
                ? 'border-primary text-primary' 
                : 'border-transparent text-muted-foreground hover:text-foreground hover:border-muted'
            }`}
          >
            <GitCompare className="h-4 w-4" />
            Pass Compare
          </button>
        </div>
        
        {/* Filter Indicator + Direction Toggle */}
        <div className="flex items-center gap-3 mb-2">
          {hasActiveFilters && (
            <div className="flex items-center gap-2 px-3 py-1 bg-purple-500/20 border border-purple-500/50 rounded-lg text-purple-400 text-xs font-medium">
              <Filter className="h-3 w-3" />
              Optimization Active
            </div>
          )}
          
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
        </div>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <>
          {/* Primary KPI Grid - Row 1 */}
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {/* Net Profit - Hero Metric */}
            <Card className={`col-span-2 ${stats.netProfit >= 0 ? 'border-green-500/30 bg-green-500/5' : 'border-red-500/30 bg-red-500/5'}`}>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Net Profit</CardTitle>
                {stats.netProfit >= 0 ? <TrendingUp className="h-4 w-4 text-green-500" /> : <TrendingDown className="h-4 w-4 text-red-500" />}
              </CardHeader>
              <CardContent>
                <div className={`text-3xl font-bold ${stats.netProfit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${stats.netProfit.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  {((stats.netProfit / 10000) * 100).toFixed(1)}% return on $10k
                </p>
              </CardContent>
            </Card>

            {/* Win Rate */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Win Rate</CardTitle>
                <BarChart3 className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${stats.winRate >= 50 ? 'text-green-500' : 'text-yellow-500'}`}>
                  {stats.winRate.toFixed(1)}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {stats.wins}W / {stats.losses}L
                </p>
              </CardContent>
            </Card>

            {/* Profit Factor */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Profit Factor</CardTitle>
                <Zap className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${stats.profitFactor >= 1.5 ? 'text-green-500' : stats.profitFactor >= 1 ? 'text-yellow-500' : 'text-red-500'}`}>
                  {stats.profitFactor === Infinity ? '∞' : stats.profitFactor.toFixed(2)}
                </div>
                <p className="text-xs text-muted-foreground">
                  {stats.profitFactor >= 1.5 ? 'Strong' : stats.profitFactor >= 1 ? 'Marginal' : 'Weak'}
                </p>
              </CardContent>
            </Card>

            {/* Expectancy */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Expectancy</CardTitle>
                <Activity className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${stats.expectancy >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                  ${stats.expectancy.toFixed(2)}
                </div>
                <p className="text-xs text-muted-foreground">per trade</p>
              </CardContent>
            </Card>

            {/* Max Drawdown */}
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Max Drawdown</CardTitle>
                <TrendingDown className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-red-500">
                  ${stats.maxDrawdown.toFixed(0)}
                </div>
                <p className="text-xs text-muted-foreground">
                  {stats.maxDrawdownPct.toFixed(1)}% of peak
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Secondary Stats Row */}
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Trades</CardTitle>
                <Activity className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.totalTrades}</div>
                <p className="text-xs text-muted-foreground">{hasActiveFilters ? 'Filtered' : '100% Data Integrity'}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Avg Win</CardTitle>
                <TrendingUp className="h-4 w-4 text-green-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-green-500">${stats.avgWin.toFixed(2)}</div>
                <p className="text-xs text-muted-foreground">max: ${stats.maxWin.toFixed(0)}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Avg Loss</CardTitle>
                <TrendingDown className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-red-500">-${stats.avgLoss.toFixed(2)}</div>
                <p className="text-xs text-muted-foreground">max: ${Math.abs(stats.maxLoss).toFixed(0)}</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Risk/Reward</CardTitle>
                <Zap className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${stats.avgWin / stats.avgLoss >= 1 ? 'text-green-500' : 'text-yellow-500'}`}>
                  {stats.avgLoss > 0 ? (stats.avgWin / stats.avgLoss).toFixed(2) : '∞'}:1
                </div>
                <p className="text-xs text-muted-foreground">win/loss ratio</p>
              </CardContent>
            </Card>

            <Card className="border-green-500/20">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-green-400">Longs</CardTitle>
                <TrendingUp className="h-4 w-4 text-green-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.longsCount}</div>
                <p className="text-xs text-muted-foreground">{stats.longWinRate.toFixed(1)}% win rate</p>
              </CardContent>
            </Card>

            <Card className="border-red-500/20">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-red-400">Shorts</CardTitle>
                <TrendingDown className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{stats.shortsCount}</div>
                <p className="text-xs text-muted-foreground">{stats.shortWinRate.toFixed(1)}% win rate</p>
              </CardContent>
            </Card>
          </div>

          {/* Equity Curve */}
          <Card className="col-span-4">
            <CardHeader>
              <CardTitle>Equity Curve</CardTitle>
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

          {/* Physics Correlation & Pattern Recognition */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div className="h-[500px]">
              <CorrelationMatrix trades={optimizedTrades} direction={direction} />
            </div>
            <div className="h-[500px]">
              <EfficiencyAnalysis trades={optimizedTrades} />
            </div>
          </div>
        </>
      )}

      {activeTab === 'summary' && (
        <PerformanceSummary trades={optimizedTrades} />
      )}

      {activeTab === 'temporal' && (
        <TemporalAnalysis trades={optimizedTrades} direction={direction} />
      )}

      {activeTab === 'sessions' && (
        <SessionAnalysis trades={optimizedTrades} direction={direction} />
      )}

      {activeTab === 'optimization' && (
        <div className="space-y-8">
          <OptimizationEngine 
            trades={trades} 
            direction={direction}
            longFilters={longFilters}
            setLongFilters={setLongFilters}
            shortFilters={shortFilters}
            setShortFilters={setShortFilters}
            allFilters={allFilters}
            setAllFilters={setAllFilters}
            eaInputs={eaInputs}
            allEaInputs={allEaInputs}
            eaVersion={runMetadata?.eaVersion}
          />
        </div>
      )}

      {activeTab === 'excursions' && (
        <div className="space-y-8">
          <ExcursionAnalysis trades={optimizedTrades} direction={direction} />
        </div>
      )}

      {activeTab === 'analysis' && (
        <div className="space-y-8">
          <ExitAnalysis 
            trades={optimizedTrades} 
            direction={direction} 
            eaInputs={eaInputs}
            allEaInputs={allEaInputs}
            eaVersion={runMetadata?.eaVersion}
          />
        </div>
      )}

      {activeTab === 'comparison' && (
        <div className="space-y-8">
          <PassComparison />
        </div>
      )}
    </div>
  )
}
