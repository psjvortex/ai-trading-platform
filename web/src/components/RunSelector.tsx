import { useState, useEffect } from 'react';
import { ChevronDown, GitCompare, Check } from 'lucide-react';
import { RunIndex, RunInfo, getPassLabel, getSampleLabel, getPassColor, getSampleColor } from '../types';

interface RunSelectorProps {
  currentRunId: string | null;
  onRunSelect: (runId: string) => void;
  onCompareToggle?: () => void;
  compareMode?: boolean;
}

export function RunSelector({ currentRunId, onRunSelect, onCompareToggle, compareMode }: RunSelectorProps) {
  const [runIndex, setRunIndex] = useState<RunIndex | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadRunIndex = async () => {
      try {
        const response = await fetch('/data/runs/index.json');
        if (response.ok) {
          const data = await response.json();
          setRunIndex(data);
        }
      } catch (error) {
        console.error('Failed to load run index:', error);
      } finally {
        setLoading(false);
      }
    };
    loadRunIndex();
  }, []);

  if (loading || !runIndex || runIndex.runs.length === 0) {
    return null;
  }

  const currentRun = runIndex.runs.find(r => r.id === currentRunId);
  
  // Group runs by pass
  const runsByPass: Record<string, RunInfo[]> = {};
  runIndex.runs.forEach(run => {
    const passKey = run.pass;
    if (!runsByPass[passKey]) runsByPass[passKey] = [];
    runsByPass[passKey].push(run);
  });

  return (
    <div className="relative">
      <div className="flex items-center gap-2">
        {/* Run Selector Dropdown */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="flex items-center gap-2 px-3 py-1.5 bg-slate-800 border border-slate-700 rounded-lg hover:bg-slate-700 transition-colors"
        >
          <span className="text-sm text-slate-300">
            {currentRun ? `${currentRun.pass}_${currentRun.sampleType}` : 'Select Run'}
          </span>
          <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
        </button>

        {/* Compare Mode Toggle */}
        {onCompareToggle && runIndex.runs.length > 1 && (
          <button
            onClick={onCompareToggle}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-colors ${
              compareMode 
                ? 'bg-blue-500/20 text-blue-400 border border-blue-500/50' 
                : 'bg-slate-800 text-slate-400 border border-slate-700 hover:bg-slate-700'
            }`}
          >
            <GitCompare className="w-4 h-4" />
            <span className="text-sm">Compare</span>
          </button>
        )}
      </div>

      {/* Dropdown Menu */}
      {isOpen && (
        <div className="absolute top-full left-0 mt-1 w-64 bg-slate-800 border border-slate-700 rounded-lg shadow-xl z-50">
          <div className="p-2 border-b border-slate-700">
            <span className="text-xs text-slate-500 uppercase tracking-wide">Available Runs</span>
          </div>
          <div className="max-h-64 overflow-y-auto">
            {Object.entries(runsByPass).map(([pass, runs]) => (
              <div key={pass}>
                <div className="px-3 py-1.5 bg-slate-900/50">
                  <span className={`text-xs font-medium px-2 py-0.5 rounded ${getPassColor(pass)}`}>
                    {getPassLabel(pass)}
                  </span>
                </div>
                {runs.map(run => (
                  <button
                    key={run.id}
                    onClick={() => {
                      onRunSelect(run.id);
                      setIsOpen(false);
                    }}
                    className={`w-full flex items-center justify-between px-3 py-2 hover:bg-slate-700/50 transition-colors ${
                      currentRunId === run.id ? 'bg-slate-700/30' : ''
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <span className={`text-xs px-1.5 py-0.5 rounded ${getSampleColor(run.sampleType)}`}>
                        {run.sampleType}
                      </span>
                      <span className="text-sm text-slate-300">{run.dateRange}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-slate-500">{run.tradeCount} trades</span>
                      {currentRunId === run.id && <Check className="w-4 h-4 text-green-400" />}
                    </div>
                  </button>
                ))}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default RunSelector;
