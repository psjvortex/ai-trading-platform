import { useMemo } from 'react';
import { Trade } from '../types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { ScatterChart, Scatter, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

interface EfficiencyAnalysisProps {
  trades: Trade[];
}

export default function EfficiencyAnalysis({ trades }: EfficiencyAnalysisProps) {
  const data = useMemo(() => {
    return trades.map(t => ({
      mae: t.Trade_MAE,
      mfe: t.Trade_MFE,
      profit: t.NetProfit,
      id: t.IN_Trade_ID
    })).filter(t => t.mae !== undefined && t.mfe !== undefined);
  }, [trades]);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 h-full">
      {/* MAE Analysis */}
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="text-sm font-medium">MAE vs Profit (Stop Loss Efficiency)</CardTitle>
        </CardHeader>
        <CardContent className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis 
                type="number" 
                dataKey="mae" 
                name="MAE" 
                unit=" pips" 
                stroke="#888"
                label={{ value: 'Max Adverse Excursion (Pips)', position: 'bottom', offset: 0, fill: '#666' }}
              />
              <YAxis 
                type="number" 
                dataKey="profit" 
                name="Profit" 
                unit="$" 
                stroke="#888"
                label={{ value: 'Net Profit', angle: -90, position: 'left', fill: '#666' }}
              />
              <Tooltip 
                cursor={{ strokeDasharray: '3 3' }}
                contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
              />
              <Scatter name="Trades" data={data} fill="#8884d8">
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.profit > 0 ? '#10b981' : '#ef4444'} />
                ))}
              </Scatter>
            </ScatterChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* MFE Analysis */}
      <Card className="bg-card border-border">
        <CardHeader>
          <CardTitle className="text-sm font-medium">MFE vs Profit (Take Profit Efficiency)</CardTitle>
        </CardHeader>
        <CardContent className="h-[300px]">
          <ResponsiveContainer width="100%" height="100%">
            <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis 
                type="number" 
                dataKey="mfe" 
                name="MFE" 
                unit=" pips" 
                stroke="#888"
                label={{ value: 'Max Favorable Excursion (Pips)', position: 'bottom', offset: 0, fill: '#666' }}
              />
              <YAxis 
                type="number" 
                dataKey="profit" 
                name="Profit" 
                unit="$" 
                stroke="#888"
                label={{ value: 'Net Profit', angle: -90, position: 'left', fill: '#666' }}
              />
              <Tooltip 
                cursor={{ strokeDasharray: '3 3' }}
                contentStyle={{ backgroundColor: '#111', borderColor: '#333' }}
              />
              <Scatter name="Trades" data={data} fill="#8884d8">
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.profit > 0 ? '#10b981' : '#ef4444'} />
                ))}
              </Scatter>
            </ScatterChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  );
}
