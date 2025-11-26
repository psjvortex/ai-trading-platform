import { useMemo } from 'react';
import { Trade } from '../types';
import { calculateCorrelation } from '../lib/analytics';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { cn } from '../lib/utils';

interface CorrelationMatrixProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

const METRICS = [
  { key: 'NetProfit', label: 'Profit' },
  { key: 'EA_Entry_PhysicsScore', label: 'Score' },
  { key: 'EA_Entry_ConfluenceSlope', label: 'Slope' },
  { key: 'EA_Entry_Spread', label: 'Spread' },
  { key: 'EA_Entry_Speed', label: 'Speed' },
  { key: 'EA_Entry_Momentum', label: 'Momtm' },
  { key: 'EA_Entry_Acceleration', label: 'Accel' },
];

export default function CorrelationMatrix({ trades, direction }: CorrelationMatrixProps) {
  const matrix = useMemo(() => {
    // Filter trades by direction first
    const filteredTrades = trades.filter(t => {
      if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
      if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
      return true;
    });

    if (filteredTrades.length === 0) return [];

    return METRICS.map(rowMetric => {
      return METRICS.map(colMetric => {
        if (rowMetric.key === colMetric.key) return 1;
        
        const x = filteredTrades.map(t => t[rowMetric.key as keyof Trade] as number);
        const y = filteredTrades.map(t => t[colMetric.key as keyof Trade] as number);
        return calculateCorrelation(x, y);
      });
    });
  }, [trades, direction]);

  const getColor = (value: number) => {
    // -1 (Red) -> 0 (Transparent/Gray) -> 1 (Green)
    if (value > 0) {
      const intensity = Math.min(Math.abs(value) * 100, 100); // Amplify for visibility
      return `rgba(16, 185, 129, ${intensity / 100})`; // Green-500
    } else {
      const intensity = Math.min(Math.abs(value) * 100, 100);
      return `rgba(239, 68, 68, ${intensity / 100})`; // Red-500
    }
  };

  return (
    <Card className="h-full">
      <CardHeader>
        <CardTitle>Physics Correlation Matrix</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead>
              <tr>
                <th className="p-2"></th>
                {METRICS.map(m => (
                  <th key={m.key} className="p-2 text-muted-foreground font-medium rotate-0">{m.label}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {METRICS.map((row, i) => (
                <tr key={row.key}>
                  <td className="p-2 font-medium text-muted-foreground text-right">{row.label}</td>
                  {matrix[i]?.map((value, j) => (
                    <td key={`${i}-${j}`} className="p-1">
                      <div 
                        className={cn(
                          "w-full h-8 flex items-center justify-center rounded text-[10px] font-mono transition-colors hover:ring-1 ring-white/20",
                          Math.abs(value) > 0.1 ? "text-white" : "text-transparent"
                        )}
                        style={{ backgroundColor: getColor(value) }}
                        title={`${METRICS[i].label} vs ${METRICS[j].label}: ${value.toFixed(4)}`}
                      >
                        {value.toFixed(2)}
                      </div>
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="mt-4 flex justify-center gap-4 text-xs text-muted-foreground">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded bg-green-500/50"></div>
            <span>Positive Correlation</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded bg-red-500/50"></div>
            <span>Negative Correlation</span>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
