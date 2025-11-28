/**
 * DataLoader Component
 * Provides drag-and-drop interface for loading 3 CSV files:
 * - MT5 Report (backtest export)
 * - EA Trades (dual-row ENTRY/EXIT format)
 * - EA Signals (signal log)
 * 
 * Also supports loading from default location (~/Desktop/MT5_Backtest_Files/)
 */

import { useState, useCallback, DragEvent } from 'react'
import { Upload, FileText, CheckCircle2, AlertCircle, Loader2, FolderOpen } from 'lucide-react'
import { BrowserCSVProcessor, ProcessingResult, OptimizationRunMeta } from '../lib/csvProcessor'
import type { Trade } from '../types'

interface DataLoaderProps {
  onDataLoaded: (trades: Trade[], metadata?: OptimizationRunMeta) => void
}

interface FileSlot {
  file: File | null
  status: 'empty' | 'loaded' | 'error'
  error?: string
}

interface DefaultFilesInfo {
  folder: string
  files: {
    mt5Report: string | null
    eaTrades: string | null
    eaSignals: string | null
  }
  allFiles: string[]
}

export function DataLoader({ onDataLoaded }: DataLoaderProps) {
  const [mt5Report, setMt5Report] = useState<FileSlot>({ file: null, status: 'empty' })
  const [eaTrades, setEaTrades] = useState<FileSlot>({ file: null, status: 'empty' })
  const [eaSignals, setEaSignals] = useState<FileSlot>({ file: null, status: 'empty' })
  const [processing, setProcessing] = useState(false)
  const [processingResult, setProcessingResult] = useState<ProcessingResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [defaultFilesInfo, setDefaultFilesInfo] = useState<DefaultFilesInfo | null>(null)
  const [loadingDefault, setLoadingDefault] = useState(false)

  const handleDrop = useCallback((
    e: DragEvent<HTMLDivElement>,
    setSlot: React.Dispatch<React.SetStateAction<FileSlot>>
  ) => {
    e.preventDefault()
    e.stopPropagation()
    
    const files = e.dataTransfer.files
    if (files.length > 0) {
      const file = files[0]
      if (file.name.toLowerCase().endsWith('.csv')) {
        setSlot({ file, status: 'loaded' })
        setError(null)
      } else {
        setSlot({ file: null, status: 'error', error: 'Please drop a CSV file' })
      }
    }
  }, [])

  const handleDragOver = useCallback((e: DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    e.stopPropagation()
  }, [])

  const handleFileSelect = useCallback((
    e: React.ChangeEvent<HTMLInputElement>,
    setSlot: React.Dispatch<React.SetStateAction<FileSlot>>
  ) => {
    const files = e.target.files
    if (files && files.length > 0) {
      const file = files[0]
      if (file.name.toLowerCase().endsWith('.csv')) {
        setSlot({ file, status: 'loaded' })
        setError(null)
      } else {
        setSlot({ file: null, status: 'error', error: 'Please select a CSV file' })
      }
    }
  }, [])

  const processFiles = useCallback(async () => {
    if (!mt5Report.file || !eaTrades.file || !eaSignals.file) {
      setError('Please load all three CSV files before processing')
      return
    }

    setProcessing(true)
    setError(null)
    setProcessingResult(null)

    try {
      const processor = new BrowserCSVProcessor()
      const result = await processor.processAll(
        mt5Report.file,
        eaTrades.file,
        eaSignals.file
      )

      setProcessingResult(result)

      if (result.errors.length > 0) {
        console.warn('Processing warnings:', result.errors)
      }

      // Call parent callback with processed trades and metadata
      onDataLoaded(result.trades, result.metadata)
    } catch (err) {
      console.error('Processing error:', err)
      setError(`Processing failed: ${err instanceof Error ? err.message : 'Unknown error'}`)
    } finally {
      setProcessing(false)
    }
  }, [mt5Report.file, eaTrades.file, eaSignals.file, onDataLoaded])

  // Load files from default location (~/Desktop/MT5_Backtest_Files/)
  const loadFromDefaultLocation = useCallback(async () => {
    setLoadingDefault(true)
    setError(null)
    setProcessingResult(null)

    try {
      // Step 1: Get list of available files
      const infoResponse = await fetch('/api/csv-files')
      if (!infoResponse.ok) {
        throw new Error('Could not access default folder. Make sure the dev server is running.')
      }
      const info: DefaultFilesInfo = await infoResponse.json()
      setDefaultFilesInfo(info)

      // Check if all required files are found
      if (!info.files.mt5Report || !info.files.eaTrades || !info.files.eaSignals) {
        const missing = []
        if (!info.files.mt5Report) missing.push('MT5 Report')
        if (!info.files.eaTrades) missing.push('EA Trades')
        if (!info.files.eaSignals) missing.push('EA Signals')
        throw new Error(`Missing files: ${missing.join(', ')}. Found: ${info.allFiles.join(', ')}`)
      }

      // Step 2: Fetch all three files
      const [mt5Content, tradesContent, signalsContent] = await Promise.all([
        fetch(`/api/csv-content?file=${encodeURIComponent(info.files.mt5Report!)}`).then(r => r.text()),
        fetch(`/api/csv-content?file=${encodeURIComponent(info.files.eaTrades!)}`).then(r => r.text()),
        fetch(`/api/csv-content?file=${encodeURIComponent(info.files.eaSignals!)}`).then(r => r.text())
      ])

      // Step 3: Convert to File objects for the processor
      const mt5File = new File([mt5Content], info.files.mt5Report!, { type: 'text/csv' })
      const tradesFile = new File([tradesContent], info.files.eaTrades!, { type: 'text/csv' })
      const signalsFile = new File([signalsContent], info.files.eaSignals!, { type: 'text/csv' })

      // Update UI to show loaded files
      setMt5Report({ file: mt5File, status: 'loaded' })
      setEaTrades({ file: tradesFile, status: 'loaded' })
      setEaSignals({ file: signalsFile, status: 'loaded' })

      // Step 4: Process immediately
      setProcessing(true)
      const processor = new BrowserCSVProcessor()
      const result = await processor.processAll(mt5File, tradesFile, signalsFile)

      setProcessingResult(result)

      if (result.errors.length > 0) {
        console.warn('Processing warnings:', result.errors)
      }

      // Call parent callback with processed trades and metadata
      onDataLoaded(result.trades, result.metadata)

    } catch (err) {
      console.error('Error loading from default location:', err)
      setError(`Failed to load: ${err instanceof Error ? err.message : 'Unknown error'}`)
    } finally {
      setLoadingDefault(false)
      setProcessing(false)
    }
  }, [onDataLoaded])

  const allFilesLoaded = mt5Report.status === 'loaded' && 
                          eaTrades.status === 'loaded' && 
                          eaSignals.status === 'loaded'

  const DropZone = ({ 
    label, 
    description,
    slot, 
    setSlot,
    inputId 
  }: { 
    label: string
    description: string
    slot: FileSlot
    setSlot: React.Dispatch<React.SetStateAction<FileSlot>>
    inputId: string
  }) => (
    <div
      onDrop={(e) => handleDrop(e, setSlot)}
      onDragOver={handleDragOver}
      className={`
        relative border-2 border-dashed rounded-xl p-6 transition-all duration-200 cursor-pointer
        ${slot.status === 'loaded' 
          ? 'border-green-500 bg-green-500/10' 
          : slot.status === 'error'
            ? 'border-red-500 bg-red-500/10'
            : 'border-gray-600 hover:border-blue-500 hover:bg-blue-500/5'
        }
      `}
      onClick={() => document.getElementById(inputId)?.click()}
    >
      <input
        id={inputId}
        type="file"
        accept=".csv"
        className="hidden"
        onChange={(e) => handleFileSelect(e, setSlot)}
      />
      
      <div className="flex flex-col items-center gap-3 text-center">
        {slot.status === 'loaded' ? (
          <>
            <CheckCircle2 className="w-10 h-10 text-green-500" />
            <div>
              <p className="font-medium text-green-400">{label}</p>
              <p className="text-sm text-gray-400 truncate max-w-[200px]">
                {slot.file?.name}
              </p>
              <p className="text-xs text-gray-500">
                {slot.file && (slot.file.size / 1024).toFixed(1)} KB
              </p>
            </div>
          </>
        ) : slot.status === 'error' ? (
          <>
            <AlertCircle className="w-10 h-10 text-red-500" />
            <div>
              <p className="font-medium text-red-400">{label}</p>
              <p className="text-sm text-red-400">{slot.error}</p>
            </div>
          </>
        ) : (
          <>
            <Upload className="w-10 h-10 text-gray-500" />
            <div>
              <p className="font-medium text-gray-300">{label}</p>
              <p className="text-sm text-gray-500">{description}</p>
            </div>
          </>
        )}
      </div>
    </div>
  )

  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center p-8">
      <div className="max-w-4xl w-full">
        {/* Header */}
        <div className="text-center mb-10">
          <div className="flex items-center justify-center gap-3 mb-4">
            <FileText className="w-12 h-12 text-blue-500" />
            <h1 className="text-3xl font-bold text-white">EA Performance Dashboard</h1>
          </div>
          <p className="text-gray-400 text-lg">
            Load your backtest data to analyze trading performance
          </p>
        </div>

        {/* Quick Load Button */}
        <div className="flex justify-center mb-8">
          <button
            onClick={loadFromDefaultLocation}
            disabled={loadingDefault || processing}
            className={`
              px-6 py-3 rounded-xl font-semibold text-base transition-all duration-200
              flex items-center gap-3
              ${!loadingDefault && !processing
                ? 'bg-green-600 hover:bg-green-700 text-white cursor-pointer shadow-lg shadow-green-500/25'
                : 'bg-gray-700 text-gray-400 cursor-not-allowed'
              }
            `}
          >
            {loadingDefault ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Loading from Desktop...
              </>
            ) : (
              <>
                <FolderOpen className="w-5 h-5" />
                Load from Default Location
              </>
            )}
          </button>
        </div>

        <div className="flex items-center gap-4 mb-8">
          <div className="flex-1 h-px bg-gray-700"></div>
          <span className="text-gray-500 text-sm">or drag & drop files below</span>
          <div className="flex-1 h-px bg-gray-700"></div>
        </div>

        {/* Drop Zones */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <DropZone
            label="MT5 Report"
            description="Backtest deals export"
            slot={mt5Report}
            setSlot={setMt5Report}
            inputId="mt5-input"
          />
          <DropZone
            label="EA Trades"
            description="Trade log with physics"
            slot={eaTrades}
            setSlot={setEaTrades}
            inputId="ea-trades-input"
          />
          <DropZone
            label="EA Signals"
            description="Signal generation log"
            slot={eaSignals}
            setSlot={setEaSignals}
            inputId="ea-signals-input"
          />
        </div>

        {/* Process Button */}
        <div className="flex flex-col items-center gap-4">
          <button
            onClick={processFiles}
            disabled={!allFilesLoaded || processing}
            className={`
              px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-200
              flex items-center gap-3
              ${allFilesLoaded && !processing
                ? 'bg-blue-600 hover:bg-blue-700 text-white cursor-pointer shadow-lg shadow-blue-500/25'
                : 'bg-gray-700 text-gray-400 cursor-not-allowed'
              }
            `}
          >
            {processing ? (
              <>
                <Loader2 className="w-6 h-6 animate-spin" />
                Processing...
              </>
            ) : (
              <>
                <Upload className="w-6 h-6" />
                Process & Load Dashboard
              </>
            )}
          </button>

          {/* Error Display */}
          {error && (
            <div className="bg-red-500/10 border border-red-500 rounded-lg px-6 py-3 text-red-400">
              {error}
            </div>
          )}

          {/* Processing Result */}
          {processingResult && (
            <div className="bg-green-500/10 border border-green-500 rounded-lg px-6 py-4 text-center">
              <p className="text-green-400 font-medium mb-2">
                ✅ Successfully processed {processingResult.trades.length} trades
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm text-gray-400">
                <div>
                  <span className="text-gray-500">MT5 Trades:</span>{' '}
                  {processingResult.statistics.totalMT5Trades}
                </div>
                <div>
                  <span className="text-gray-500">Paired:</span>{' '}
                  {processingResult.statistics.pairedTrades}
                </div>
                <div>
                  <span className="text-gray-500">EA Matched:</span>{' '}
                  {processingResult.statistics.eaTradesMatched}
                </div>
                <div>
                  <span className="text-gray-500">Time:</span>{' '}
                  {processingResult.statistics.processingTimeMs}ms
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Instructions */}
        <div className="mt-12 bg-gray-800/50 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-gray-300 mb-4">📋 Required Files</h3>
          <div className="grid md:grid-cols-3 gap-6 text-sm">
            <div>
              <p className="font-medium text-blue-400 mb-2">MT5 Report</p>
              <p className="text-gray-500">
                Export from MT5: Strategy Tester → Backtest → Right-click → Save as Detailed Report (deals)
              </p>
            </div>
            <div>
              <p className="font-medium text-blue-400 mb-2">EA Trades</p>
              <p className="text-gray-500">
                CSV file from EA with dual-row format (ENTRY/EXIT rows per trade with physics data)
              </p>
            </div>
            <div>
              <p className="font-medium text-blue-400 mb-2">EA Signals</p>
              <p className="text-gray-500">
                CSV file from EA containing all generated signals with physics scores
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
