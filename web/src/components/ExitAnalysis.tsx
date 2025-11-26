import React, { useState, useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardHeader, CardTitle, CardContent } from './ui/card';
import { Activity, Zap, Wind, Gauge, Download, Copy, Check } from 'lucide-react';
import { AVAILABLE_METRICS } from './OptimizationEngine';
import { Button } from './ui/button';

interface ExitAnalysisProps {
  trades: Trade[];
  direction: 'All' | 'Long' | 'Short';
}

const EA_MAPPINGS: Record<string, any> = {
  'Signal_Entry_Quality': { buyInput: 'MinQualityBuy', sellInput: 'MinQualitySell', defaultBuy: 70.0, defaultSell: 70.0, type: 'min_threshold' },
  'Signal_Entry_PhysicsScore': { buyInput: 'MinPhysicsScoreBuy', sellInput: 'MinPhysicsScoreSell', defaultBuy: 40.0, defaultSell: 40.0, type: 'min_threshold' },
  'EA_Entry_Spread': { buyInput: 'MaxSpreadPipsBuy', sellInput: 'MaxSpreadPipsSell', defaultBuy: 25.0, defaultSell: 25.0, type: 'max_threshold' },
  'Signal_Entry_ConfluenceSlope': { buyInput: 'MinConfluenceSlopeBuy', sellInput: 'MinConfluenceSlopeSell', defaultBuy: 1.0, defaultSell: 1.0, type: 'min_threshold' },
  
  'Signal_Entry_Speed': { buyInput: 'MinSpeedBuy', sellInput: 'MinSpeedSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  'Signal_Entry_Acceleration': { buyInput: 'MinAccelerationBuy', sellInput: 'MinAccelerationSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  'Signal_Entry_Momentum': { buyInput: 'MinMomentumBuy', sellInput: 'MinMomentumSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  
  'Signal_Entry_SpeedSlope': { buyInput: 'MinSpeedSlopeBuy', sellInput: 'MinSpeedSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  'Signal_Entry_AccelerationSlope': { buyInput: 'MinAccelerationSlopeBuy', sellInput: 'MinAccelerationSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  'Signal_Entry_MomentumSlope': { buyInput: 'MinMomentumSlopeBuy', sellInput: 'MinMomentumSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
  'Signal_Entry_JerkSlope': { buyInput: 'MinJerkSlopeBuy', sellInput: 'MinJerkSlopeSell', defaultBuy: 1.0, defaultSell: -1.0, type: 'range_buy_min_sell_max' },
};

export default function ExitAnalysis({ trades, direction }: ExitAnalysisProps) {
  const [activeTab, setActiveTab] = useState<'TP' | 'SL'>('TP');
  const [copied, setCopied] = useState(false);

  // Ignore global direction filter for this report to show all TP/SL events
  const tpTrades = useMemo(() => trades.filter(t => {
    const comment = t.OUT_Comment?.toLowerCase() || '';
    const reason = t.EA_ExitReason?.toLowerCase() || '';
    return comment.includes('tp') || comment.includes('take profit') || reason === 'tp' || reason === 'takeprofit';
  }), [trades]);

  const slTrades = useMemo(() => trades.filter(t => {
    const comment = t.OUT_Comment?.toLowerCase() || '';
    const reason = t.EA_ExitReason?.toLowerCase() || '';
    return comment.includes('sl') || comment.includes('stop loss') || reason === 'sl' || reason === 'stoploss';
  }), [trades]);

  const activeTrades = activeTab === 'TP' ? tpTrades : slTrades;

  const longTrades = useMemo(() => activeTrades.filter(t => t.Trade_Direction === 'Long'), [activeTrades]);
  const shortTrades = useMemo(() => activeTrades.filter(t => t.Trade_Direction === 'Short'), [activeTrades]);
  
  const getStats = (trades: Trade[]) => ({
    count: trades.length,
    profit: trades.reduce((sum, t) => sum + t.NetProfit, 0),
  });

  const longStats = getStats(longTrades);
  const shortStats = getStats(shortTrades);
  const totalStats = getStats(activeTrades);

  const handleExportCSV = () => {
    if (activeTrades.length === 0) return;

    const t = trades[0];
    const symbol = t?.Symbol_OP_03 || 'Unknown';
    let tf = t?.Chart_TF_OP_01 || 'Unknown';
    
    // Pad single digit timeframes (e.g. M5 -> M05)
    if (tf.match(/^[A-Z]\d$/)) {
      tf = tf.charAt(0) + '0' + tf.charAt(1);
    }

    const version = t?.Strategy_Version_ID_OP_03 || 'Unknown';
    const type = activeTab === 'TP' ? 'TakeProfit' : 'StopLoss';
    const filename = `${symbol}_${tf}_${version}_${type}.csv`;

    // Get all keys from the first trade object to ensure we have all columns
    const headers = Object.keys(trades[0]);

    const csvContent = [
      headers.join(','),
      ...activeTrades.map(trade => {
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

  const generateMQL5Code = () => {
    // Calculate averages for TP trades (Long vs Short)
    const tpLong = tpTrades.filter(t => t.Trade_Direction === 'Long');
    const tpShort = tpTrades.filter(t => t.Trade_Direction === 'Short');

    const getAvg = (data: Trade[], key: string) => {
      if (data.length === 0) return undefined;
      const validValues = data.map(t => Number(t[key as keyof Trade])).filter(v => !isNaN(v));
      if (validValues.length === 0) return undefined;
      return validValues.reduce((a, b) => a + b, 0) / validValues.length;
    };

    // Get EA Version from first trade
    const eaVersion = tpTrades[0]?.Strategy_Version_ID_OP_03 || 'Unknown';

    let code = `// === TP ANALYSIS INPUTS (Generated: ${new Date().toLocaleString()}) ===\n`;
    code += `// Based on ${tpTrades.length} Take Profit Trades (Long: ${tpLong.length}, Short: ${tpShort.length})\n`;
    code += `// EA Version: ${eaVersion}\n`;
    code += `input group "🎯 TP Analysis Filters"\n`;

    AVAILABLE_METRICS.forEach(m => {
      const mapping = EA_MAPPINGS[m.key];
      if (!mapping) return;

      // Global Settings
      if (mapping.globalInput) {
        const avgVal = getAvg(tpTrades, m.key);
        const val = avgVal !== undefined ? avgVal : mapping.defaultGlobal;
        code += `input double ${mapping.globalInput} = ${val.toFixed(2)};\n`;
      }

      // Buy/Sell Specific Settings
      if (mapping.buyInput && mapping.sellInput) {
        const buyAvg = getAvg(tpLong, m.key);
        const sellAvg = getAvg(tpShort, m.key);

        const buyVal = buyAvg !== undefined ? buyAvg : mapping.defaultBuy;
        const sellVal = sellAvg !== undefined ? sellAvg : mapping.defaultSell;

        code += `input double ${mapping.buyInput} = ${buyVal.toFixed(2)};\n`;
        code += `input double ${mapping.sellInput} = ${sellVal.toFixed(2)};\n`;
      }
    });

    return code;
  };

  const handleCopyMQL5 = () => {
    navigator.clipboard.writeText(generateMQL5Code());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const calculateMetrics = (data: Trade[]) => {
    if (data.length === 0) return null;
    const avg = (key: keyof Trade) => data.reduce((sum, t) => sum + (Number(t[key]) || 0), 0) / data.length;
    
    return {
      speed: avg('Signal_Entry_Speed'),
      acceleration: avg('Signal_Entry_Acceleration'),
      momentum: avg('Signal_Entry_Momentum'),
      jerk: avg('Signal_Entry_Jerk'),
      confluence: avg('Signal_Entry_Confluence'),
      physicsScore: avg('Signal_Entry_PhysicsScore'),
      entropy: avg('Signal_Entry_Entropy'),
    };
  };

  const tpMetrics = calculateMetrics(tpTrades);
  const slMetrics = calculateMetrics(slTrades);

  const renderMetricRow = (label: string, tpVal: number | undefined, slVal: number | undefined, icon: React.ReactNode) => (
    <div className="flex items-center justify-between py-3 border-b border-gray-800 last:border-0">
      <div className="flex items-center gap-2 text-muted-foreground">
        {icon}
        <span>{label}</span>
      </div>
      <div className="flex gap-8">
        <span className="font-mono text-green-500 w-24 text-right">{tpVal?.toFixed(2) ?? '-'}</span>
        <span className="font-mono text-red-500 w-24 text-right">{slVal?.toFixed(2) ?? '-'}</span>
      </div>
    </div>
  );

  const generatedCode = useMemo(() => generateMQL5Code(), [tpTrades]);

  return (
    <Card className="h-full flex flex-col">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Activity className="h-5 w-5 text-primary" />
          Exit Physics Analysis (Entry Metrics)
        </CardTitle>
      </CardHeader>
      <CardContent className="flex-1 overflow-hidden flex flex-col gap-6">
        {/* Performance Summary */}
        <div className="grid grid-cols-3 gap-4 text-center bg-muted/30 p-4 rounded-lg border border-gray-800">
          <div>
            <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b border-gray-700 pb-1 mb-2">Long</div>
            <div className="text-2xl font-bold">{longStats.count}</div>
            <div className="text-xs text-muted-foreground mb-1">trades</div>
            <div className={`text-lg font-mono ${longStats.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
              ${longStats.profit.toFixed(0)}
            </div>
          </div>
          <div>
            <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b border-gray-700 pb-1 mb-2">Short</div>
            <div className="text-2xl font-bold">{shortStats.count}</div>
            <div className="text-xs text-muted-foreground mb-1">trades</div>
            <div className={`text-lg font-mono ${shortStats.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
              ${shortStats.profit.toFixed(0)}
            </div>
          </div>
          <div>
            <div className="text-xs font-bold text-muted-foreground uppercase tracking-wider border-b border-gray-700 pb-1 mb-2">Total</div>
            <div className="text-2xl font-bold text-primary">{totalStats.count}</div>
            <div className="text-xs text-muted-foreground mb-1">trades</div>
            <div className={`text-lg font-mono ${totalStats.profit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
              ${totalStats.profit.toFixed(0)}
            </div>
          </div>
        </div>

        {/* Metrics Comparison */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-muted/30 rounded-lg p-4">
            <div className="flex justify-between mb-4 text-sm font-medium text-muted-foreground border-b border-gray-700 pb-2">
              <span>Entry Metric</span>
              <div className="flex gap-8">
                <span className="w-24 text-right text-green-500">Take Profit (Avg)</span>
                <span className="w-24 text-right text-red-500">Stop Loss (Avg)</span>
              </div>
            </div>
            {renderMetricRow('Entry Speed', tpMetrics?.speed, slMetrics?.speed, <Wind className="h-4 w-4" />)}
            {renderMetricRow('Entry Acceleration', tpMetrics?.acceleration, slMetrics?.acceleration, <Zap className="h-4 w-4" />)}
            {renderMetricRow('Entry Momentum', tpMetrics?.momentum, slMetrics?.momentum, <Activity className="h-4 w-4" />)}
            {renderMetricRow('Entry Physics Score', tpMetrics?.physicsScore, slMetrics?.physicsScore, <Gauge className="h-4 w-4" />)}
          </div>

          {/* Generated Code Preview */}
          <div className="bg-zinc-950 rounded-lg border border-zinc-800 flex flex-col overflow-hidden">
            <div className="flex items-center justify-between p-2 bg-zinc-900 border-b border-zinc-800">
              <span className="text-xs font-medium text-zinc-400">Generated MQL5 Inputs (Preview)</span>
              <Button 
                variant="ghost" 
                className="h-6 px-2 text-xs gap-1 hover:bg-zinc-800 hover:text-zinc-200"
                onClick={handleCopyMQL5}
              >
                {copied ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                {copied ? 'Copied' : 'Copy'}
              </Button>
            </div>
            <textarea 
              readOnly
              value={generatedCode}
              className="flex-1 bg-transparent p-3 font-mono text-xs text-zinc-400 resize-none focus:outline-none"
            />
          </div>
        </div>

        {/* Trade List */}
        <div className="flex-1 flex flex-col min-h-0">
          <div className="flex justify-between mb-4">
            <div className="flex gap-2">
              <button
                onClick={() => setActiveTab('TP')}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                  activeTab === 'TP' 
                    ? 'bg-green-500/20 text-green-500 border border-green-500/50' 
                    : 'text-muted-foreground hover:bg-muted'
                }`}
              >
                Take Profit Trades ({tpTrades.length})
              </button>
              <button
                onClick={() => setActiveTab('SL')}
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                  activeTab === 'SL' 
                    ? 'bg-red-500/20 text-red-500 border border-red-500/50' 
                    : 'text-muted-foreground hover:bg-muted'
                }`}
              >
                Stop Loss Trades ({slTrades.length})
              </button>
            </div>
            <button
              onClick={handleExportCSV}
              className="px-4 py-2 rounded-md text-sm font-medium bg-primary/10 text-primary hover:bg-primary/20 transition-colors flex items-center gap-2"
            >
              <Download className="h-4 w-4" />
              Export CSV
            </button>
          </div>

          <div className="flex-1 overflow-auto border rounded-lg">
            <table className="w-full text-sm text-left">
              <thead className="bg-muted/50 sticky top-0">
                <tr>
                  <th className="p-3 font-medium">ID</th>
                  <th className="p-3 font-medium">Time</th>
                  <th className="p-3 font-medium">Symbol</th>
                  <th className="p-3 font-medium">Direction</th>
                  <th className="p-3 font-medium text-right">Profit</th>
                  {AVAILABLE_METRICS.map((m) => (
                    <th key={m.key} className="p-3 font-medium text-right whitespace-nowrap">
                      {m.label}
                    </th>
                  ))}
                  <th className="p-3 font-medium">Reason</th>
                </tr>
              </thead>
              <tbody>
                {activeTrades.map((t) => (
                  <tr key={t.IN_Trade_ID} className="border-b border-gray-800 hover:bg-muted/20">
                    <td className="p-3 font-mono text-xs">{t.IN_Trade_ID}</td>
                    <td className="p-3 text-xs text-muted-foreground">{t.IN_MT_MASTER_DATE_TIME?.split(' ')[1]}</td>
                    <td className="p-3">{t.Symbol_OP_03}</td>
                    <td className="p-3">
                      <span className={`px-2 py-1 rounded text-xs ${
                        t.Trade_Direction === 'Long' ? 'bg-green-500/20 text-green-500' : 'bg-red-500/20 text-red-500'
                      }`}>
                        {t.Trade_Direction}
                      </span>
                    </td>
                    <td className={`p-3 text-right font-mono ${t.NetProfit >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                      ${t.NetProfit.toFixed(2)}
                    </td>
                    {AVAILABLE_METRICS.map((m) => (
                      <td key={m.key} className="p-3 text-right font-mono">
                        {typeof t[m.key] === 'number' 
                          ? (t[m.key] as number).toFixed(2) 
                          : t[m.key]?.toString() || '-'}
                      </td>
                    ))}
                    <td className="p-3 text-xs text-muted-foreground">{t.OUT_Comment || t.EA_ExitReason}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
