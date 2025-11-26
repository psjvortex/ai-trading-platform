/**
 * CSV Processor - Main Entry Point
 * Joins MT5 backtest reports, EA trades, and EA signals into unified dataset
 */

import * as fs from 'fs';
import * as path from 'path';
import { parse } from 'csv-parse/sync';
import { stringify } from 'csv-stringify/sync';
import {
  MT5ReportRow,
  EATradeRow,
  EASignalRow,
  ProcessedTradeData,
  ProcessedDataset,
  ValidationError,
  ProcessingStatistics
} from './types';
import { TimeSegmentCalculator } from './timeSegmentCalculator';

export class CSVProcessor {
  private mt5ToCstOffsetHours: number;

  constructor(mt5ToCstOffsetHours: number = -8) {
    this.mt5ToCstOffsetHours = mt5ToCstOffsetHours;
  }
  /**
   * Process all three CSV files and join the data
   */
  async processAll(
    mt5ReportPath: string,
    eaTradesPath: string,
    eaSignalsPath: string
  ): Promise<ProcessedDataset> {
    const startTime = Date.now();
    
    console.log('🚀 Starting CSV processing...');
    console.log(`📄 MT5 Report: ${path.basename(mt5ReportPath)}`);
    console.log(`📄 EA Trades: ${path.basename(eaTradesPath)}`);
    console.log(`📄 EA Signals: ${path.basename(eaSignalsPath)}`);
    
    // Step 1: Load all CSV files
    console.log('\n📂 Loading CSV files...');
    const mt5Rows = this.loadMT5Report(mt5ReportPath);
    const eaTradeRows = this.loadEATrades(eaTradesPath);
    const eaSignalRows = this.loadEASignals(eaSignalsPath);
    
    console.log(`✅ Loaded ${mt5Rows.length} MT5 rows`);
    console.log(`✅ Loaded ${eaTradeRows.length} EA trade rows`);
    console.log(`✅ Loaded ${eaSignalRows.length} EA signal rows`);
    
    // Step 2: Pair MT5 entry/exit trades
    console.log('\n🔗 Pairing MT5 entry/exit trades...');
    const pairedMT5Trades = this.pairMT5Trades(mt5Rows);
    console.log(`✅ Created ${pairedMT5Trades.length} paired trades`);
    
    // Step 3: Separate EA trades into ENTRY and EXIT rows
    console.log('\n📊 Processing EA trades...');
    const eaTradeMap = this.indexEATrades(eaTradeRows);
    console.log(`✅ Indexed ${eaTradeMap.size} EA trade pairs`);
    
    // Step 4: Index EA signals for quick lookup
    console.log('\n🎯 Indexing EA signals...');
    const eaSignalMap = this.indexEASignals(eaSignalRows);
    console.log(`✅ Indexed ${eaSignalMap.size} EA signals`);
    
    // Step 5: Join all data
    console.log('\n🔄 Joining all datasets...');
    const processedTrades: ProcessedTradeData[] = [];
    let matchedEATrades = 0;
    let matchedSignals = 0;
    
    for (const mt5Trade of pairedMT5Trades) {
      const processed = this.joinTradeData(
        mt5Trade,
        eaTradeMap,
        eaSignalMap
      );
      
      if (processed.EA_Entry_PhysicsScore > 0) matchedEATrades++;
      if (processed.Signal_Entry_Matched || processed.Signal_Exit_Matched) matchedSignals++;
      
      processedTrades.push(processed);
    }
    
    console.log(`✅ Matched ${matchedEATrades} EA trades`);
    console.log(`✅ Matched ${matchedSignals} signals`);
    
    // Step 6: Profit Reconciliation Check (QA)
    console.log('\n💰 Profit Reconciliation Check...');
  // Sum MT5 net profit as Profit + Commission + Swap to match MT5 "Total Net Profit"
  const mt5TotalProfit = processedTrades.reduce((sum, t) => sum + (t.OUT_Profit_OP_01 || 0) + (t.OUT_Commission || 0) + (t.OUT_Swap || 0), 0);
  // Sum EA profit ignoring nulls to avoid NaN
  const eaTotalProfit = processedTrades.reduce((sum, t) => sum + ((t.EA_Profit === null || t.EA_Profit === undefined) ? 0 : t.EA_Profit), 0);
    const profitDiff = Math.abs(mt5TotalProfit - eaTotalProfit);
    const profitMatchPercent = mt5TotalProfit !== 0 ? (1 - profitDiff / Math.abs(mt5TotalProfit)) * 100 : 0;
    
    console.log(`   MT5 Total Profit:  $${mt5TotalProfit.toFixed(2)}`);
    console.log(`   EA Total Profit:   $${eaTotalProfit.toFixed(2)}`);
    console.log(`   Difference:        $${profitDiff.toFixed(2)} (${(100 - profitMatchPercent).toFixed(2)}% variance)`);
    
    if (profitDiff < 0.01) {
      console.log(`   ✅ PERFECT MATCH - Profits reconcile!`);
    } else if (profitDiff < 1.00) {
      console.log(`   ✅ CLOSE MATCH - Within $1 tolerance`);
    } else if (profitMatchPercent > 99) {
      console.log(`   ⚠️  ACCEPTABLE - Profits within 1% variance`);
    } else {
      console.log(`   ❌ MISMATCH - Significant profit variance detected!`);
    }
    
    // Step 7: Validate results
    console.log('\n✔️  Validating results...');
    const validation = this.validateDataset(processedTrades);
    console.log(`✅ Data quality score: ${validation.dataQualityScore}/100`);
    
    if (validation.criticalErrors.length > 0) {
      console.log(`⚠️  ${validation.criticalErrors.length} critical errors found`);
    }
    if (validation.warnings.length > 0) {
      console.log(`⚠️  ${validation.warnings.length} warnings found`);
    }
    
    const processingTime = Date.now() - startTime;
    
    const statistics: ProcessingStatistics = {
      totalMT5Trades: mt5Rows.length,
      pairedTrades: pairedMT5Trades.length,
      unmatchedTrades: mt5Rows.length - (pairedMT5Trades.length * 2),
      eaTradesMatched: matchedEATrades,
      eaSignalsMatched: matchedSignals,
      processingTimeMs: processingTime,
      dataQualityScore: validation.dataQualityScore
    };
    
    console.log(`\n✅ Processing complete in ${processingTime}ms`);
  // Export detailed missing EA exit report (if any)
  this.exportMissingEAExitReport(processedTrades);
    
  return {
      metadata: {
        processingTimestamp: new Date().toISOString(),
        dataModelVersion: '2.0.0',
        totalTrades: processedTrades.length,
        sourceFiles: {
          mt5Report: path.basename(mt5ReportPath),
          eaTradesCSV: path.basename(eaTradesPath),
          eaSignalsCSV: path.basename(eaSignalsPath)
        }
      },
      trades: processedTrades,
      statistics,
      validation: {
        isValid: validation.criticalErrors.length === 0,
        criticalErrors: validation.criticalErrors,
        warnings: validation.warnings
      }
    };
  }

  /**
   * Load MT5 backtest report CSV
   */
  private loadMT5Report(filePath: string): MT5ReportRow[] {
    const content = fs.readFileSync(filePath, 'utf-8');
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
      bom: true,  // Handle UTF-8 BOM
      relax_column_count: true  // Handle inconsistent column counts
    });
    return records as MT5ReportRow[];
  }

  /**
   * Load EA trades CSV (dual-row ENTRY/EXIT format)
   */
  private loadEATrades(filePath: string): EATradeRow[] {
    const content = fs.readFileSync(filePath, 'utf-8');
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
      cast: (value, context) => {
        const raw = value === undefined || value === null ? '' : String(value);
        const cleaned = raw.trim().replace(/,/g, '').replace(/\s+/g, '');
        // Cast numeric and boolean fields appropriately
        if (context.column === 'Ticket' || context.column === 'Hour' || 
            context.column === 'DayOfWeek' || context.column === 'EntryHour' ||
            context.column === 'EntryDayOfWeek' || context.column === 'ExitHour' ||
            context.column === 'ExitDayOfWeek' || context.column === 'HoldTimeBars' ||
            context.column === 'OpenPositions' || context.column === 'MFE_TimeBars' ||
            context.column === 'MAE_TimeBars' || context.column === 'RunUp_TimeBars' ||
            context.column === 'RunDown_TimeBars') {
          return parseInt(cleaned) || 0;
        }
        if (context.column === 'IsWeekend' || context.column === 'IsPreMarket' ||
            context.column === 'SignalPhysicsPass' || context.column === 'ZoneTransitioned') {
          return cleaned === 'TRUE' || cleaned === 'true' || cleaned === '1';
        }
        // Normalize RowType values for case-insensitive checks later
        if (context.column === 'RowType') {
          return cleaned.toUpperCase();
        }
        if (context.column && (
            (cleaned.match(/^-?\d+\.?\d*$/) || cleaned.match(/^-?\d{1,3}(,\d{3})*(\.\d+)?$/))) && 
            !['RowType', 'Type', 'ExitReason', 'TimeSegment15M', 'TimeSegment30M',
              'TimeSegment1H', 'TimeSegment2H', 'TimeSegment3H', 'TimeSegment4H',
              'TradingSession', 'Entry_Zone', 'Entry_Regime', 'Exit_Zone', 'Exit_Regime',
              'ExitQualityClass', 'ValidationFlags', 'SignalRejectReason', 'Symbol',
              'EAName', 'EAVersion', 'OpenTime', 'CloseTime', 'Timestamp', 'SignalTimestamp'].includes(String(context.column))
  ) {
          return parseFloat(cleaned) || 0;
        }
        return value;
      }
    });
    // Ensure Ticket is numeric and RowType is normalized at read-time
    const typed = (records as any[]).map(r => ({
      ...r,
      Ticket: parseInt(String(r.Ticket || '0')) || 0,
      RowType: r.RowType ? String(r.RowType).toUpperCase() : ''
    }));
    return typed as EATradeRow[];
  }

  /**
   * Load EA signals CSV
   */
  private loadEASignals(filePath: string): EASignalRow[] {
    const content = fs.readFileSync(filePath, 'utf-8');
    const records = parse(content, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
      cast: (value, context) => {
        const raw = value === undefined || value === null ? '' : String(value);
        const cleaned = raw.trim().replace(/,/g, '').replace(/\s+/g, '');
        if (context.column === 'Hour' || context.column === 'DayOfWeek' || 
            context.column === 'OpenPositions') {
          return parseInt(cleaned) || 0;
        }
        if (context.column === 'PhysicsPass') {
          return cleaned === 'TRUE' || cleaned === 'true' || cleaned === '1';
        }
        if (context.column && (cleaned.match(/^-?\d+\.?\d*$/) || cleaned.match(/^-?\d{1,3}(,\d{3})*(\.\d+)?$/)) && 
            !['Time', 'Symbol', 'Type', 'Zone', 'Regime', 'RejectReason', 
              'EAName', 'EAVersion'].includes(String(context.column))) {
          return parseFloat(cleaned) || 0;
        }
        return value;
      }
    });
    return records as EASignalRow[];
  }

  /**
   * Pair MT5 trades (match entry "in" with exit "out" by Order ID)
   */
  /**
   * Pair MT5 entry/exit trades
   * Strategy: MT5 backtest reports have alternating in/out trades by Deal ID sequence
   */
  private pairMT5Trades(rows: MT5ReportRow[]): Array<{entry: MT5ReportRow, exit: MT5ReportRow}> {
    const paired: Array<{entry: MT5ReportRow, exit: MT5ReportRow}> = [];
    
    // Sort by Deal ID to ensure correct sequence
    const sortedRows = [...rows].sort((a, b) => parseInt(a.Deal) - parseInt(b.Deal));
    
    for (let i = 0; i < sortedRows.length - 1; i++) {
      const current = sortedRows[i];
      const next = sortedRows[i + 1];
      
      // Look for consecutive in/out pairs for the same symbol
      if (current.Direction.toLowerCase() === 'in' && 
          next.Direction.toLowerCase() === 'out' &&
          current.Symbol === next.Symbol) {
        paired.push({ entry: current, exit: next });
        i++; // Skip the exit row since we've paired it
      }
    }
    
    return paired;
  }

  /**
   * Index EA trades by ticket number for quick lookup
   * Returns map: ticket -> {entry: EATradeRow, exit: EATradeRow}
   */
  private indexEATrades(rows: EATradeRow[]): Map<number, {entry: EATradeRow, exit: EATradeRow | null}> {
    const map = new Map<number, {entry: EATradeRow, exit: EATradeRow | null}>();
    const seen = new Set<string>();
    let duplicateCount = 0;
    
  rows.forEach(row => {
      // Simple dedupe: fingerprint = ticket|rowType|openPrice|closePrice|profit
  const ticketNum = Number(row.Ticket) || 0;
  const rt = row.RowType ? String(row.RowType).toUpperCase() : '';
  const fp = `${ticketNum}:${rt}:${row.OpenPrice || row.Price || ''}:${row.ClosePrice || row.Price || ''}:${row.Profit || 0}`;
  const key = `${ticketNum}:${rt}:${fp}`;
      if (seen.has(key)) {
        duplicateCount++;
        // Skip exact duplicate
        return;
      }
      seen.add(key);
      if (!map.has(ticketNum)) {
        map.set(ticketNum, { entry: null as any, exit: null });
      }

      const record = map.get(ticketNum)!;
      if (rt === 'ENTRY') {
        // Time-tolerant dedupe: if an existing ENTRY exists with similar timestamp (<=2s), skip
        if (record.entry) {
          const prevTime = new Date(record.entry.OpenTime || record.entry.Timestamp || '').getTime();
          const curTime = new Date(row.OpenTime || row.Timestamp || '').getTime();
          if (!isNaN(prevTime) && !isNaN(curTime)) {
            const delta = Math.abs(prevTime - curTime);
            if (delta <= 2000) { duplicateCount++; return; }
          }
        }
        record.entry = row;
      } else if (rt === 'EXIT') {
        // Time-tolerant dedupe for exit rows: if existing exit within 2s, skip
        if (record.exit) {
          const prevTime = new Date(record.exit.CloseTime || record.exit.Timestamp || '').getTime();
          const curTime = new Date(row.CloseTime || row.Timestamp || '').getTime();
          if (!isNaN(prevTime) && !isNaN(curTime)) {
            const delta = Math.abs(prevTime - curTime);
            if (delta <= 2000) { duplicateCount++; return; }
          }
        }
        record.exit = row;
      } else {
        // Unknown row type - ignore but log for diagnostics
        // We don't want to spam the console; collect or handle later if needed
      }
    });
    if (duplicateCount > 0) {
      console.log(`⚠️  Ignored ${duplicateCount} duplicate EA trade rows while indexing`);
    }
    
    return map;
  }

  /**
   * Index EA signals by symbol and timestamp for matching
   */
  private indexEASignals(rows: EASignalRow[]): Map<string, EASignalRow[]> {
    const map = new Map<string, EASignalRow[]>();
    
    rows.forEach(row => {
      if (!map.has(row.Symbol)) {
        map.set(row.Symbol, []);
      }
      map.get(row.Symbol)!.push(row);
    });
    
    // Sort by timestamp for each symbol
    map.forEach(signals => {
      signals.sort((a, b) => new Date(a.Timestamp).getTime() - new Date(b.Timestamp).getTime());
    });
    
    return map;
  }

  /**
   * Join MT5 trade with EA trade and signal data
   */
  private joinTradeData(
    mt5Trade: {entry: MT5ReportRow, exit: MT5ReportRow},
    eaTradeMap: Map<number, {entry: EATradeRow, exit: EATradeRow | null}>,
    eaSignalMap: Map<string, EASignalRow[]>
  ): ProcessedTradeData {
    // Process entry timestamp
  const entryTime = TimeSegmentCalculator.processTimestamp(mt5Trade.entry.Time, this.mt5ToCstOffsetHours);
  const exitTime = TimeSegmentCalculator.processTimestamp(mt5Trade.exit.Time, this.mt5ToCstOffsetHours);
    
    // Try to find matching EA trade by timestamp proximity
    const matchedEATrade = this.findMatchingEATrade(mt5Trade, eaTradeMap);
    
    // Find matching entry signal (before trade opens)
    const matchedEntrySignal = this.findMatchingSignal(
      mt5Trade.entry.Symbol,
      mt5Trade.entry.Time,
      mt5Trade.entry.Type,
      eaSignalMap
    );
    
    // Find matching exit signal (before trade closes)
    const matchedExitSignal = this.findMatchingSignal(
      mt5Trade.exit.Symbol,
      mt5Trade.exit.Time,
      mt5Trade.exit.Type, // Use exit type directly (e.g. 'sell' exit looks for 'SELL' signal)
      eaSignalMap
    );
    
    // Calculate derived metrics with validation
    const profitRaw = mt5Trade.exit.Profit;
    // Strip spaces from profit string (MT5 exports negative numbers with spaces like "- 264.14")
    const profitClean = typeof profitRaw === 'string' ? profitRaw.replace(/\s+/g, '') : profitRaw;
    let profit = parseFloat(profitClean);
    
    // Validate profit value and log issues
    if (isNaN(profit) || profitRaw === null || profitRaw === undefined || profitRaw === '') {
      console.warn(`⚠️  Invalid profit for Trade ${mt5Trade.entry.Order} -> ${mt5Trade.exit.Order}: "${profitRaw}" (Deal Entry: ${mt5Trade.entry.Deal}, Deal Exit: ${mt5Trade.exit.Deal})`);
      profit = 0; // Default to 0 for NaN values
    }
    
    const tradeResult: 'Win' | 'Loss' | 'Breakeven' | 'DataError' = 
      profitRaw === null || profitRaw === undefined || profitRaw === '' || isNaN(parseFloat(profitClean)) ? 'DataError' :
      profit > 0.01 ? 'Win' :      // Use small threshold to avoid floating point issues
      profit < -0.01 ? 'Loss' : 
      'Breakeven';
    
    const tradeDirection: 'Long' | 'Short' = mt5Trade.entry.Type.toLowerCase() === 'buy' ? 'Long' : 'Short';
    
    const entryDate = new Date(entryTime.mt5DateTime);
    const exitDate = new Date(exitTime.mt5DateTime);
    const durationMinutes = Math.floor((exitDate.getTime() - entryDate.getTime()) / (1000 * 60));
    
    const cleaner = (v: any) => {
      if (v === undefined || v === null) return '';
      const s = String(v).trim();
      return s.replace(/,/g, '').replace(/\s+/g, '');
    };

    const entryPrice = parseFloat(cleaner(mt5Trade.entry.Price));
    const exitPrice = parseFloat(cleaner(mt5Trade.exit.Price));
    const entryBalance = parseFloat(mt5Trade.entry.Balance);
    const roi = (profit / entryBalance) * 100;
    
    // Extract EA and signal data first
    const eaData = this.extractEATradeData(matchedEATrade);

    // OVERRIDE: Detect Exit Reason from MT5 Comment (TP/SL)
    // MT5 comments for TP/SL usually look like "tp 154.23" or "sl 150.00"
    const mt5Comment = mt5Trade.exit.Comment || '';
    const isTP = /\btp\b/i.test(mt5Comment);
    const isSL = /\bsl\b/i.test(mt5Comment);
    
    if (isTP) {
      eaData.EA_ExitReason = 'TP';
    } else if (isSL) {
      eaData.EA_ExitReason = 'SL';
    }

    const entrySignalData = this.extractSignalData(matchedEntrySignal, mt5Trade.entry.Time, 'Entry');
    const exitSignalData = this.extractSignalData(matchedExitSignal, mt5Trade.exit.Time, 'Exit');
    
    // Build the complete processed trade data
    const processed: ProcessedTradeData = {
      // Entry Data
      IN_Deal: parseInt(mt5Trade.entry.Deal),
      Report_Source: 'MT5_Backtest',
      IN_Trade_ID: parseInt(mt5Trade.entry.Order),
      IN_MT_MASTER_DATE_TIME: mt5Trade.entry.Time,
      IN_MT_Date: entryTime.mt5Date,
      IN_MT_Time: entryTime.mt5Time,
      IN_MT_Day: entryTime.mt5Day,
      IN_MT_Month: entryTime.mt5Month,
      IN_CST_Date_OP_01: entryTime.cstDate,
      IN_CST_Time_OP_01: entryTime.cstTime,
      IN_CST_Day_OP_01: entryTime.cstDay,
      IN_CST_Month_OP_01: entryTime.cstMonth,
      
      // Time Windows (Entry)
      IN_Segment_15M_OP_01: entryTime.segment15m,
      IN_Segment_30M_OP_01: entryTime.segment30m,
      IN_Segment_01H_OP_01: entryTime.segment1h,
      IN_Segment_02H_OP_01: entryTime.segment2h,
      IN_Segment_03H_OP_01: entryTime.segment3h,
      IN_Segment_04H_OP_01: entryTime.segment4h,
      IN_Session_Name_OP_02: entryTime.session,
      
      // Strategy Info
      Strategy_ID_OP_03: matchedEATrade?.entry.EAName || 'Unknown',
      Strategy_Version_ID_OP_03: matchedEATrade?.entry.EAVersion || 'Unknown',
      Optimization_ID_OP_03: '',
      Report_Broker_OP_03: 'MT5',
      Symbol_OP_03: mt5Trade.entry.Symbol,
      Chart_TF_OP_01: 'M1',
      
      // Order Info (Entry)
      IN_Order_Type_OP_01: mt5Trade.entry.Type.toLowerCase(),
      IN_Order_Direction: 'in',
      Volume_OP_03: parseFloat(mt5Trade.entry.Volume),
      IN_Symbol_Price_OP_03: entryPrice,
      IN_Balance_OP_01: entryBalance,
      
      // Exit Data
      OUT_Profit_OP_01: profit,
      OUT_Balance_OP_01: parseFloat(mt5Trade.exit.Balance),
      OUT_Trade_ID: parseInt(mt5Trade.exit.Order),
      OUT_Deal: parseInt(mt5Trade.exit.Deal),
      OUT_CST_Date_OP_03: exitTime.cstDate,
      OUT_CST_Time_OP_03: exitTime.cstTime,
      OUT_CST_Day_OP_03: exitTime.cstDay,
      OUT_CST_Month_OP_03: exitTime.cstMonth,
      
      // Exit Windows
      OUT_Segment_15M_OP_03: exitTime.segment15m,
      OUT_Segment_30M_OP_03: exitTime.segment30m,
      OUT_Segment_01H_OP_03: exitTime.segment1h,
      OUT_Segment_02H_OP_03: exitTime.segment2h,
      OUT_Segment_03H_OP_03: exitTime.segment3h,
      OUT_Segment_04H_OP_03: exitTime.segment4h,
      OUT_Session_Name_OP_03: exitTime.session,
      
      // Exit Details
      OUT_Order_Type: mt5Trade.exit.Type.toLowerCase(),
      OUT_Order_Direction: 'out',
      OUT_Symbol_Price_OP_01: exitPrice,
      OUT_Commission: parseFloat(cleaner(mt5Trade.exit.Commission)) || 0,
      OUT_Swap: parseFloat(cleaner(mt5Trade.exit.Swap)) || 0,
      OUT_Comment: mt5Trade.exit.Comment || '',
      OUT_Symbol: mt5Trade.exit.Symbol,
      
      // Result Info
      Trade_Result: tradeResult,
      Trade_Direction: tradeDirection,
      
      // Performance Metrics
      Trade_Duration_Minutes: durationMinutes,
      Trade_ROI_Percentage: roi,
      Trade_Risk_Reward_Ratio: matchedEATrade?.exit?.RRatio || 0,
      Trade_MAE: matchedEATrade?.exit?.MAE || 0,
      Trade_MFE: matchedEATrade?.exit?.MFE || 0,
      
      // EA Enhanced Data (from matched EA trade) - spread after base fields
      ...eaData,
      
      // Entry Signal Data (from matched entry signal) - spread after EA data
      ...entrySignalData,
      
      // Exit Signal Data (from matched exit signal) - spread after entry signal
      ...exitSignalData,
      
      // Data Quality
      DataQuality: {
        score: this.calculateTradeQualityScore(matchedEATrade, matchedEntrySignal, matchedExitSignal),
        missingFields: this.getMissingFields(matchedEATrade, matchedEntrySignal, matchedExitSignal),
        validationFlags: this.getValidationFlags(mt5Trade, matchedEATrade)
      },
      ProcessingTimestamp: new Date().toISOString(),
      SourceFiles: {
        mt5Report: 'MT5_Backtest',
        eaTradesCSV: matchedEATrade ? 'EA_Trades' : 'Not Found',
        eaSignalsCSV: (matchedEntrySignal || matchedExitSignal) ? 'EA_Signals' : 'Not Found'
      }
    } as ProcessedTradeData;
    
    return processed;
  }

  /**
   * Find matching EA trade by Order ID
   * MT5 uses sequential Order IDs for entry (even) and exit (odd)
   * EA uses the entry Order ID as the Ticket number (even numbers only)
   * So MT5 Entry Order 2 → EA Ticket 2, MT5 Entry Order 6 → EA Ticket 6
   */
  private findMatchingEATrade(
    mt5Trade: {entry: MT5ReportRow, exit: MT5ReportRow},
    eaTradeMap: Map<number, {entry: EATradeRow, exit: EATradeRow | null}>
  ): {entry: EATradeRow, exit: EATradeRow | null} | null {
    // Direct match: MT5 entry Order ID = EA Ticket number
    const entryOrderId = parseInt(mt5Trade.entry.Order);
    
    if (eaTradeMap.has(entryOrderId)) {
      return eaTradeMap.get(entryOrderId)!;
    }
    
  // Fallback: Try time/price proximity matching if direct match fails
  const mt5EntryTime = new Date(mt5Trade.entry.Time).getTime();
    const mt5EntryPrice = parseFloat(mt5Trade.entry.Price);
    const mt5Symbol = mt5Trade.entry.Symbol;
    
    let bestMatch: {entry: EATradeRow, exit: EATradeRow | null} | null = null;
    let bestTimeDelta = Infinity;
    
    for (const [ticket, eaTrade] of eaTradeMap) {
      if (!eaTrade.entry) continue;
      
      // Must match symbol
      if (eaTrade.entry.Symbol !== mt5Symbol) continue;
      
      const eaEntryTime = new Date(eaTrade.entry.OpenTime).getTime();
      const eaEntryPrice = eaTrade.entry.OpenPrice;
      
      // Check time proximity (within 1 minute)
      const timeDelta = Math.abs(eaEntryTime - mt5EntryTime);
  if (timeDelta > 60000) continue; // More than 1 minute
      
      // Check price proximity (within 0.1%)
      const priceDelta = Math.abs(eaEntryPrice - mt5EntryPrice) / mt5EntryPrice;
  if (priceDelta > 0.001) continue; // More than 0.1%
      if (timeDelta < bestTimeDelta) {
        bestTimeDelta = timeDelta;
        bestMatch = eaTrade;
      }
    }

    // SECONDARY FALLBACK: Find an EXIT row by matching exit time/price/symbol to MT5 exit if entry-based fallback fails
    const mt5ExitTime = new Date(mt5Trade.exit.Time).getTime();
    const mt5ExitPrice = parseFloat(mt5Trade.exit.Price);
    for (const [ticket, eaTrade] of eaTradeMap) {
      if (!eaTrade.exit) continue;
      if (eaTrade.exit.Symbol !== mt5Symbol) continue; // Symbol must match
      const eaExitTime = new Date(eaTrade.exit.CloseTime || eaTrade.exit.Timestamp || '').getTime();
      const timeDelta = Math.abs(eaExitTime - mt5ExitTime);
      if (timeDelta > 60000) continue; // More than 1 minute
      const eaExitPrice = eaTrade.exit.ClosePrice || eaTrade.exit.Price || 0;
      const priceDelta = Math.abs(eaExitPrice - mt5ExitPrice) / mt5ExitPrice;
      if (priceDelta > 0.001) continue; // More than 0.1% price mismatch

      // Found a viable EXIT-based match
      console.log(`⚠️  Fallback EA EXIT match used for MT5 Order ${mt5Trade.entry.Order} -> Ticket ~${ticket || 'unknown'} (exitTimeDeltaMs=${timeDelta})`);
      bestMatch = eaTrade;
      break;
    }
    
    // If we found a best match using fallback heuristics, log debug info
    if (bestMatch && bestTimeDelta < Infinity) {
      // Attempt to find the ticket number that corresponds to the bestMatch
      const ticketKey = [...eaTradeMap.entries()].find(([k, v]) => v === bestMatch)?.[0];
      console.log(`⚠️  Fallback EA match used for MT5 Order ${mt5Trade.entry.Order} -> Ticket ~${ticketKey || 'unknown'} (timeDeltaMs=${bestTimeDelta})`);
    }
    
    return bestMatch;
  }

  /**
   * Find matching signal by symbol, time proximity, and direction
   */
  private findMatchingSignal(
    symbol: string,
    entryTime: string,
    orderType: string,
    signalMap: Map<string, EASignalRow[]>
  ): EASignalRow | null {
    const signals = signalMap.get(symbol);
    if (!signals || signals.length === 0) return null;
    
    const entryDate = new Date(entryTime);
    const entryTimestamp = entryDate.getTime();
    
    // Find signal within 10 minutes before entry
    let bestMatch: EASignalRow | null = null;
    let bestDelta = Infinity;
    
    for (const signal of signals) {
      const signalDate = new Date(signal.Timestamp);
      const signalTimestamp = signalDate.getTime();
      
      // Signal must be before or at entry time
      if (signalTimestamp > entryTimestamp) continue;
      
      // Within 10 minutes
      const delta = entryTimestamp - signalTimestamp;
      if (delta > 600000) continue; // More than 10 minutes
      
      // Must match direction
      if (!signal.SignalType || !orderType) continue;
      const signalIsBuy = signal.SignalType.toUpperCase().includes('BUY');
      const orderIsBuy = orderType.toLowerCase() === 'buy';
      if (signalIsBuy !== orderIsBuy) continue;
      
      if (delta < bestDelta) {
        bestDelta = delta;
        bestMatch = signal;
      }
    }
    
    return bestMatch;
  }

  /**
   * Extract EA trade data into flat structure
   */
  private extractEATradeData(eaTrade: {entry: EATradeRow, exit: EATradeRow | null} | null): Partial<ProcessedTradeData> {
    if (!eaTrade || !eaTrade.entry) {
      return {
        EA_Entry_Quality: 0,
        EA_Entry_Confluence: 0,
        EA_Entry_Momentum: 0,
        EA_Entry_Speed: 0,
        EA_Entry_Acceleration: 0,
        EA_Entry_Entropy: 0,
        EA_Entry_Jerk: 0,
        EA_Entry_PhysicsScore: 0,
        EA_Entry_SpeedSlope: 0,
        EA_Entry_AccelerationSlope: 0,
        EA_Entry_MomentumSlope: 0,
        EA_Entry_ConfluenceSlope: 0,
        EA_Entry_JerkSlope: 0,
        EA_Entry_Zone: '',
        EA_Entry_Regime: '',
        EA_Entry_Spread: 0,
        EA_ExitReason: '',
        EA_Exit_Quality: 0,
        EA_Exit_Confluence: 0,
        EA_Exit_Momentum: 0,
        EA_Exit_Speed: 0,
        EA_Exit_Acceleration: 0,
        EA_Exit_Entropy: 0,
        EA_Exit_Jerk: 0,
        EA_Exit_PhysicsScore: 0,
        EA_Exit_SpeedSlope: 0,
        EA_Exit_AccelerationSlope: 0,
        EA_Exit_MomentumSlope: 0,
        EA_Exit_ConfluenceSlope: 0,
        EA_Exit_JerkSlope: 0,
        EA_Exit_Zone: '',
        EA_Exit_Regime: '',
        EA_Exit_Spread: 0,
        EA_ProfitPercent: 0,
        EA_Pips: 0,
        EA_HoldTimeBars: 0,
        EA_HoldTimeMinutes: 0,
        EA_RiskPercent: 0,
        EA_RRatio: 0,
        EA_MFE: 0,
        EA_MAE: 0,
        EA_MFE_Percent: 0,
        EA_MAE_Percent: 0,
        EA_MFE_Pips: 0,
        EA_MAE_Pips: 0,
        EA_MFE_TimeBars: 0,
        EA_MAE_TimeBars: 0,
        EA_MFEUtilization: 0,
        EA_MAEImpact: 0,
        EA_ExcursionEfficiency: 0,
        EA_RunUp_Price: 0,
        EA_RunUp_Pips: 0,
        EA_RunUp_Percent: 0,
        EA_RunUp_TimeBars: 0,
        EA_RunDown_Price: 0,
        EA_RunDown_Pips: 0,
        EA_RunDown_Percent: 0,
        EA_RunDown_TimeBars: 0,
        EA_ExitQualityClass: '',
        EA_EarlyExitOpportunityCost: 0,
        EA_PhysicsScoreDecay: 0,
        EA_SpeedDecay: 0,
        EA_SpeedSlopeDecay: 0,
        EA_ConfluenceDecay: 0,
        EA_ZoneTransitioned: false
      };
    }
    
    return {
      // Entry Physics
  EA_Entry_Quality: eaTrade.entry.Entry_Quality || 0,
  EA_Entry_Symbol: eaTrade.entry.Symbol || '',
      EA_Entry_Confluence: eaTrade.entry.Entry_Confluence || 0,
      EA_Entry_Momentum: eaTrade.entry.Entry_Momentum || 0,
      EA_Entry_Speed: eaTrade.entry.Entry_Speed || 0,
      EA_Entry_Acceleration: eaTrade.entry.Entry_Acceleration || 0,
      EA_Entry_Entropy: eaTrade.entry.Entry_Entropy || 0,
      EA_Entry_Jerk: eaTrade.entry.Entry_Jerk || 0,
      EA_Entry_PhysicsScore: eaTrade.entry.Entry_PhysicsScore || 0,
      EA_Entry_SpeedSlope: eaTrade.entry.Entry_SpeedSlope || 0,
      EA_Entry_AccelerationSlope: eaTrade.entry.Entry_AccelerationSlope || 0,
      EA_Entry_MomentumSlope: eaTrade.entry.Entry_MomentumSlope || 0,
      EA_Entry_ConfluenceSlope: eaTrade.entry.Entry_ConfluenceSlope || 0,
      EA_Entry_JerkSlope: eaTrade.entry.Entry_JerkSlope || 0,
      EA_Entry_Zone: eaTrade.entry.Entry_Zone || '',
      EA_Entry_Regime: eaTrade.entry.Entry_Regime || '',
      EA_Entry_Spread: eaTrade.entry.Entry_Spread || 0,
      
      // Exit Physics (from exit row)
  EA_ExitReason: eaTrade.exit?.ExitReason || '',
  EA_Exit_Symbol: eaTrade.exit?.Symbol || '',
      EA_Exit_Quality: eaTrade.exit?.Exit_Quality || 0,
      EA_Exit_Confluence: eaTrade.exit?.Exit_Confluence || 0,
      EA_Exit_Momentum: eaTrade.exit?.Exit_Momentum || 0,
      EA_Exit_Speed: eaTrade.exit?.Exit_Speed || 0,
      EA_Exit_Acceleration: eaTrade.exit?.Exit_Acceleration || 0,
      EA_Exit_Entropy: eaTrade.exit?.Exit_Entropy || 0,
      EA_Exit_Jerk: eaTrade.exit?.Exit_Jerk || 0,
      EA_Exit_PhysicsScore: eaTrade.exit?.Exit_PhysicsScore || 0,
      EA_Exit_SpeedSlope: eaTrade.exit?.Exit_SpeedSlope || 0,
      EA_Exit_AccelerationSlope: eaTrade.exit?.Exit_AccelerationSlope || 0,
      EA_Exit_MomentumSlope: eaTrade.exit?.Exit_MomentumSlope || 0,
      EA_Exit_ConfluenceSlope: eaTrade.exit?.Exit_ConfluenceSlope || 0,
      EA_Exit_JerkSlope: eaTrade.exit?.Exit_JerkSlope || 0,
      EA_Exit_Zone: eaTrade.exit?.Exit_Zone || '',
      EA_Exit_Regime: eaTrade.exit?.Exit_Regime || '',
      EA_Exit_Spread: eaTrade.exit?.Exit_Spread || 0,
      
      // Performance Metrics
      EA_Profit: eaTrade.exit?.Profit || 0,
      EA_ProfitPercent: eaTrade.exit?.ProfitPercent || 0,
      EA_Pips: eaTrade.exit?.Pips || 0,
      EA_HoldTimeBars: eaTrade.exit?.HoldTimeBars || 0,
      EA_HoldTimeMinutes: eaTrade.exit?.HoldTimeMinutes || 0,
      EA_RiskPercent: eaTrade.exit?.RiskPercent || 0,
      EA_RRatio: eaTrade.exit?.RRatio || 0,
      
      // Excursion
      EA_MFE: eaTrade.exit?.MFE || 0,
      EA_MAE: eaTrade.exit?.MAE || 0,
      EA_MFE_Percent: eaTrade.exit?.MFE_Percent || 0,
      EA_MAE_Percent: eaTrade.exit?.MAE_Percent || 0,
      EA_MFE_Pips: eaTrade.exit?.MFE_Pips || 0,
      EA_MAE_Pips: eaTrade.exit?.MAE_Pips || 0,
      EA_MFE_TimeBars: eaTrade.exit?.MFE_TimeBars || 0,
      EA_MAE_TimeBars: eaTrade.exit?.MAE_TimeBars || 0,
      EA_MFEUtilization: eaTrade.exit?.MFEUtilization || 0,
      EA_MAEImpact: eaTrade.exit?.MAEImpact || 0,
      EA_ExcursionEfficiency: eaTrade.exit?.ExcursionEfficiency || 0,
      
      // RunUp/RunDown
      EA_RunUp_Price: eaTrade.exit?.RunUp_Price || 0,
      EA_RunUp_Pips: eaTrade.exit?.RunUp_Pips || 0,
      EA_RunUp_Percent: eaTrade.exit?.RunUp_Percent || 0,
      EA_RunUp_TimeBars: eaTrade.exit?.RunUp_TimeBars || 0,
      EA_RunDown_Price: eaTrade.exit?.RunDown_Price || 0,
      EA_RunDown_Pips: eaTrade.exit?.RunDown_Pips || 0,
      EA_RunDown_Percent: eaTrade.exit?.RunDown_Percent || 0,
      EA_RunDown_TimeBars: eaTrade.exit?.RunDown_TimeBars || 0,
      EA_ExitQualityClass: eaTrade.exit?.ExitQualityClass || '',
      EA_EarlyExitOpportunityCost: eaTrade.exit?.EarlyExitOpportunityCost || 0,
      
      // Physics Decay
      EA_PhysicsScoreDecay: eaTrade.exit?.PhysicsScoreDecay || 0,
      EA_SpeedDecay: eaTrade.exit?.SpeedDecay || 0,
      EA_SpeedSlopeDecay: eaTrade.exit?.SpeedSlopeDecay || 0,
      EA_ConfluenceDecay: eaTrade.exit?.ConfluenceDecay || 0,
      EA_ZoneTransitioned: eaTrade.exit?.ZoneTransitioned || false
    };
  }

  /**
   * Extract signal data into flat structure
   * @param signal The signal row to extract
   * @param timestamp The trade timestamp to calculate delta
   * @param prefix 'Entry' or 'Exit' to distinguish signal types
   */
  private extractSignalData(signal: EASignalRow | null, timestamp: string, prefix: 'Entry' | 'Exit'): Partial<ProcessedTradeData> {
    const fields: any = {};
    
    if (!signal) {
      fields[`Signal_${prefix}_Matched`] = false;
      fields[`Signal_${prefix}_Timestamp`] = null;
      fields[`Signal_${prefix}_TimeDelta`] = null;
      fields[`Signal_${prefix}_Quality`] = null;
      fields[`Signal_${prefix}_Confluence`] = null;
      fields[`Signal_${prefix}_Speed`] = null;
      fields[`Signal_${prefix}_Acceleration`] = null;
      fields[`Signal_${prefix}_Momentum`] = null;
      fields[`Signal_${prefix}_Entropy`] = null;
      fields[`Signal_${prefix}_Jerk`] = null;
      fields[`Signal_${prefix}_PhysicsScore`] = null;
      fields[`Signal_${prefix}_SpeedSlope`] = null;
      fields[`Signal_${prefix}_AccelerationSlope`] = null;
      fields[`Signal_${prefix}_MomentumSlope`] = null;
      fields[`Signal_${prefix}_ConfluenceSlope`] = null;
      fields[`Signal_${prefix}_JerkSlope`] = null;
      fields[`Signal_${prefix}_Zone`] = null;
      fields[`Signal_${prefix}_Regime`] = null;
      fields[`Signal_${prefix}_PhysicsPass`] = null;
      fields[`Signal_${prefix}_RejectReason`] = null;
      return fields;
    }
    
    const timeDelta = TimeSegmentCalculator.calculateTimeDelta(signal.Timestamp, timestamp);
    
    fields[`Signal_${prefix}_Matched`] = true;
    fields[`Signal_${prefix}_Timestamp`] = signal.Timestamp;
    fields[`Signal_${prefix}_TimeDelta`] = timeDelta;
    fields[`Signal_${prefix}_Quality`] = signal.Quality;
    fields[`Signal_${prefix}_Confluence`] = signal.Confluence;
    fields[`Signal_${prefix}_Speed`] = signal.Speed;
    fields[`Signal_${prefix}_Acceleration`] = signal.Acceleration;
    fields[`Signal_${prefix}_Momentum`] = signal.Momentum;
    fields[`Signal_${prefix}_Entropy`] = signal.Entropy;
    fields[`Signal_${prefix}_Jerk`] = signal.Jerk;
    fields[`Signal_${prefix}_PhysicsScore`] = signal.PhysicsScore;
    fields[`Signal_${prefix}_SpeedSlope`] = signal.SpeedSlope;
    fields[`Signal_${prefix}_AccelerationSlope`] = signal.AccelerationSlope;
    fields[`Signal_${prefix}_MomentumSlope`] = signal.MomentumSlope;
    fields[`Signal_${prefix}_ConfluenceSlope`] = signal.ConfluenceSlope;
    fields[`Signal_${prefix}_JerkSlope`] = signal.JerkSlope;
    fields[`Signal_${prefix}_Zone`] = signal.Zone;
    fields[`Signal_${prefix}_Regime`] = signal.Regime;
    fields[`Signal_${prefix}_PhysicsPass`] = signal.PhysicsPass;
    fields[`Signal_${prefix}_RejectReason`] = signal.RejectReason || null;
    
    return fields;
  }

  /**
   * Calculate data quality score for a trade
   */
  private calculateTradeQualityScore(
    eaTrade: {entry: EATradeRow, exit: EATradeRow | null} | null,
    entrySignal: EASignalRow | null,
    exitSignal: EASignalRow | null
  ): number {
    let score = 100;
    
    if (!eaTrade || !eaTrade.entry) score -= 30;
    if (!eaTrade?.exit) score -= 20;
    if (!entrySignal) score -= 15;
    if (!exitSignal) score -= 15;
    
    return Math.max(0, score);
  }

  /**
   * Get list of missing fields
   */
  private getMissingFields(
    eaTrade: {entry: EATradeRow, exit: EATradeRow | null} | null,
    entrySignal: EASignalRow | null,
    exitSignal: EASignalRow | null
  ): string[] {
    const missing: string[] = [];
    
    if (!eaTrade || !eaTrade.entry) {
      missing.push('EA_Entry_Data');
    }
    if (!eaTrade?.exit) {
      missing.push('EA_Exit_Data');
    }
    if (!entrySignal) {
      missing.push('Entry_Signal_Data');
    }
    if (!exitSignal) {
      missing.push('Exit_Signal_Data');
    }
    
    return missing;
  }

  /**
   * Get validation flags
   */
  private getValidationFlags(
    mt5Trade: {entry: MT5ReportRow, exit: MT5ReportRow},
    eaTrade: {entry: EATradeRow, exit: EATradeRow | null} | null
  ): string[] {
    const flags: string[] = [];
    
    if (!eaTrade) {
      flags.push('NO_EA_MATCH');
    }
    
    if (eaTrade?.exit?.ZoneTransitioned) {
      flags.push('ZONE_TRANSITION');
    }
    
    if (eaTrade?.exit?.ExitQualityClass === 'Early') {
      flags.push('EARLY_EXIT');
    }
    
    return flags;
  }

  /**
   * Validate complete dataset
   */
  private validateDataset(trades: ProcessedTradeData[]): {
    dataQualityScore: number;
    criticalErrors: ValidationError[];
    warnings: ValidationError[];
  } {
    const criticalErrors: ValidationError[] = [];
    const warnings: ValidationError[] = [];
    
    trades.forEach((trade, index) => {
      // Check for trade ID consistency
      // In MT5, entry and exit Trade IDs may differ; treat as a warning by default
      if (trade.IN_Trade_ID !== trade.OUT_Trade_ID) {
        warnings.push({
          type: 'TRADE_ID_MISMATCH',
          tradeIndex: index,
          message: `Trade ID mismatch: IN=${trade.IN_Trade_ID}, OUT=${trade.OUT_Trade_ID}`,
          severity: 'WARNING'
        });
      }
      
      // Check for symbol consistency between entry and exit
      if (trade.Symbol_OP_03 !== trade.OUT_Symbol) {
        criticalErrors.push({
          type: 'SYMBOL_MISMATCH',
          tradeIndex: index,
          message: `Symbol inconsistency: IN=${trade.Symbol_OP_03}, OUT=${trade.OUT_Symbol}`,
          severity: 'CRITICAL'
        });
      }

      // Check EA ENTRY symbol matches MT5 entry symbol
      if (trade.EA_Entry_Symbol && trade.Symbol_OP_03 !== trade.EA_Entry_Symbol) {
        criticalErrors.push({
          type: 'SYMBOL_MISMATCH_EA_ENTRY',
          tradeIndex: index,
          message: `EA Entry symbol (${trade.EA_Entry_Symbol}) does not match MT5 entry (${trade.Symbol_OP_03})`,
          severity: 'CRITICAL'
        });
      }

      // Check EA EXIT symbol matches MT5 exit symbol
      if (trade.EA_Exit_Symbol && trade.OUT_Symbol && trade.OUT_Symbol !== trade.EA_Exit_Symbol) {
        criticalErrors.push({
          type: 'SYMBOL_MISMATCH_EA_EXIT',
          tradeIndex: index,
          message: `EA Exit symbol (${trade.EA_Exit_Symbol}) does not match MT5 exit (${trade.OUT_Symbol})`,
          severity: 'CRITICAL'
        });
      }
      
      // Warn if no EA data
      if (trade.EA_Entry_PhysicsScore === 0) {
        warnings.push({
          type: 'NO_EA_DATA',
          tradeIndex: index,
          message: 'No matching EA trade data found',
          severity: 'WARNING'
        });
      }
      
      // Warn if no entry or exit signal
      if (!trade.Signal_Entry_Matched) {
        warnings.push({
          type: 'NO_ENTRY_SIGNAL_MATCH',
          tradeIndex: index,
          message: 'No matching entry signal found',
          severity: 'WARNING'
        });
      }
      
      if (!trade.Signal_Exit_Matched) {
        warnings.push({
          type: 'NO_EXIT_SIGNAL_MATCH',
          tradeIndex: index,
          message: 'No matching exit signal found',
          severity: 'WARNING'
        });
      }
    });
    
    const totalIssues = criticalErrors.length + warnings.length;
    const dataQualityScore = Math.max(0, 100 - (criticalErrors.length * 10) - (warnings.length * 2));
    
    return {
      dataQualityScore,
      criticalErrors,
      warnings
    };
  }

  /**
   * Export processed dataset to JSON
   */
  async exportJSON(dataset: ProcessedDataset, outputPath: string): Promise<void> {
    const json = JSON.stringify(dataset, null, 2);
    fs.writeFileSync(outputPath, json, 'utf-8');
    console.log(`✅ Exported JSON to: ${outputPath}`);
  }

  /**
   * Export processed dataset to CSV
   */
  async exportCSV(dataset: ProcessedDataset, outputPath: string): Promise<void> {
    const csv = stringify(dataset.trades, {
      header: true,
      columns: Object.keys(dataset.trades[0])
    });
    fs.writeFileSync(outputPath, csv, 'utf-8');
    console.log(`✅ Exported CSV to: ${outputPath}`);
  }

  /**
   * Export a simple CSV listing EA tickets with missing EXIT row data
   */
  exportMissingEAExitReport(trades: ProcessedTradeData[], outputDir = path.join(__dirname, 'output')): void {
    const missing = trades.filter(t => {
      const missingFields = t.DataQuality?.missingFields || [];
      return missingFields.includes('EA_Exit_Data') || !t.EA_Exit_Symbol || t.EA_Exit_PhysicsScore === 0;
    });

    if (missing.length === 0) {
      console.log('✅ No missing EA exit rows detected');
      return;
    }

    // Build CSV rows
    const rows = missing.map(t => ({
      Ticket: t.IN_Trade_ID,
      IN_Deal: t.IN_Deal,
      IN_Order: t.IN_Trade_ID,
      OUT_Deal: t.OUT_Deal,
      OUT_Trade_ID: t.OUT_Trade_ID,
      IN_MT_MASTER_DATE_TIME: t.IN_MT_MASTER_DATE_TIME,
      EA_Entry_Symbol: t.EA_Entry_Symbol || '',
      EA_Entry_PhysicsScore: t.EA_Entry_PhysicsScore || 0,
      EA_Exit_Symbol: t.EA_Exit_Symbol || '',
      EA_Exit_PhysicsScore: t.EA_Exit_PhysicsScore || 0,
      MissingFields: (t.DataQuality?.missingFields || []).join(';')
    }));

    try {
      if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
      const csv = stringify(rows, { header: true });
      const outPath = path.join(outputDir, `ea_exit_missing_trades_detailed.csv`);
      fs.writeFileSync(outPath, csv, 'utf-8');
      console.log(`✅ Exported missing EA exit trades report to: ${outPath}`);
    } catch (err) {
      console.warn('⚠️  Failed to write EA missing exits report:', err);
    }
  }
}
