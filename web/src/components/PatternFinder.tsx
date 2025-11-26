import { useMemo } from 'react';
import { Trade } from '../types';
import { findPatterns, Pattern } from '../lib/analytics';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { AlertTriangle, CheckCircle2, XCircle } from 'lucide-react';

interface PatternFinderProps {
  trades: Trade[];
  direction: 'Long' | 'Short' | 'All';
}

export default function PatternFinder({ trades, direction }: PatternFinderProps) {
  const patterns = useMemo(() => {
    const filteredTrades = trades.filter(t => {
      if (direction === 'Long') return t.Trade_Direction === 'Long' || t.IN_Order_Direction === 'buy';
      if (direction === 'Short') return t.Trade_Direction === 'Short' || t.IN_Order_Direction === 'sell';
      return true;
    });
    return findPatterns(filteredTrades);
  }, [trades, direction]);

  const bullishPatterns = patterns.filter(p => p.type === 'bullish').slice(0, 5);
  const bearishPatterns = patterns.filter(p => p.type === 'bearish').slice(0, 5);

  const PatternRow = ({ pattern }: { pattern: Pattern }) => (
    <div className="flex items-center justify-between p-3 border rounded-lg bg-card/50 hover:bg-accent/50 transition-colors">
      <div className="flex items-center gap-3">
        {pattern.type === 'bullish' ? (
          <CheckCircle2 className="h-5 w-5 text-green-500" />
        ) : (
          <XCircle className="h-5 w-5 text-red-500" />
        )}
        <div>
          <div className="font-medium text-sm">
            {pattern.metric} <span className="text-muted-foreground">in range</span> {pattern.condition}
          </div>
          <div className="text-xs text-muted-foreground">
            {pattern.totalTrades} trades • Net: ${pattern.netProfit.toFixed(0)}
          </div>
        </div>
      </div>
      <div className="text-right">
        <div className={`text-lg font-bold ${pattern.type === 'bullish' ? 'text-green-500' : 'text-red-500'}`}>
          {pattern.winRate.toFixed(1)}%
        </div>
        <div className="text-[10px] uppercase tracking-wider text-muted-foreground">Win Rate</div>
      </div>
    </div>
  );

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 h-full">
      <Card className="border-red-900/20 bg-red-950/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-500">
            <AlertTriangle className="h-5 w-5" />
            Loss DNA (Avoid These)
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {bearishPatterns.length > 0 ? (
            bearishPatterns.map(p => <PatternRow key={p.id} pattern={p} />)
          ) : (
            <div className="text-center py-8 text-muted-foreground">No strong loss patterns found.</div>
          )}
        </CardContent>
      </Card>

      <Card className="border-green-900/20 bg-green-950/5">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-green-500">
            <CheckCircle2 className="h-5 w-5" />
            Win DNA (Target These)
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {bullishPatterns.length > 0 ? (
            bullishPatterns.map(p => <PatternRow key={p.id} pattern={p} />)
          ) : (
            <div className="text-center py-8 text-muted-foreground">No strong win patterns found.</div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
