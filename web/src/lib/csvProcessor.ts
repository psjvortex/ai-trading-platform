/**
 * Browser-Compatible CSV Processor
 * Joins MT5 backtest reports, EA trades, and EA signals into unified dataset
 * Port of analytics/csv_processing/csvProcessor.ts for browser use with Papa Parse
 */

import Papa from 'papaparse'
import type { Trade } from '../types'

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface MT5ReportRow {
  Deal: string
  Time: string
  Type: string
  Direction: string
  Order: string
  Symbol: string
  Price: string
  Volume: string
  Profit: string
  Balance: string
  Commission: string
  Swap: string
  Comment: string
}

interface EATradeRow {
  RowType: string
  Ticket: number
  Symbol: string
  Type: string
  OpenTime?: string
  CloseTime?: string
  Timestamp?: string
  OpenPrice?: number
  ClosePrice?: number
  Price?: number
  Profit?: number
  ProfitPercent?: number
  Pips?: number
  HoldTimeBars?: number
  HoldTimeMinutes?: number
  RiskPercent?: number
  RRatio?: number
  MFE?: number
  MAE?: number
  MFE_Percent?: number
  MAE_Percent?: number
  MFE_Pips?: number
  MAE_Pips?: number
  MFE_TimeBars?: number
  MAE_TimeBars?: number
  MFEUtilization?: number
  MAEImpact?: number
  ExcursionEfficiency?: number
  RunUp_Price?: number
  RunUp_Pips?: number
  RunUp_Percent?: number
  RunUp_TimeBars?: number
  RunDown_Price?: number
  RunDown_Pips?: number
  RunDown_Percent?: number
  RunDown_TimeBars?: number
  Entry_Quality?: number
  Entry_Confluence?: number
  Entry_Momentum?: number
  Entry_Speed?: number
  Entry_Acceleration?: number
  Entry_Entropy?: number
  Entry_Jerk?: number
  Entry_PhysicsScore?: number
  Entry_SpeedSlope?: number
  Entry_AccelerationSlope?: number
  Entry_MomentumSlope?: number
  Entry_ConfluenceSlope?: number
  Entry_JerkSlope?: number
  Entry_Zone?: string
  Entry_Regime?: string
  Entry_Spread?: number
  Exit_Quality?: number
  Exit_Confluence?: number
  Exit_Momentum?: number
  Exit_Speed?: number
  Exit_Acceleration?: number
  Exit_Entropy?: number
  Exit_Jerk?: number
  Exit_PhysicsScore?: number
  Exit_SpeedSlope?: number
  Exit_AccelerationSlope?: number
  Exit_MomentumSlope?: number
  Exit_ConfluenceSlope?: number
  Exit_JerkSlope?: number
  Exit_Zone?: string
  Exit_Regime?: string
  Exit_Spread?: number
  ExitReason?: string
  ExitQualityClass?: string
  EarlyExitOpportunityCost?: number
  PhysicsScoreDecay?: number
  SpeedDecay?: number
  SpeedSlopeDecay?: number
  ConfluenceDecay?: number
  ZoneTransitioned?: boolean
  EAName?: string
  EAVersion?: string
}

interface EASignalRow {
  Timestamp: string
  Symbol: string
  SignalType: string
  Type: string
  Quality: number
  Confluence: number
  Speed: number
  Acceleration: number
  Momentum: number
  Entropy: number
  Jerk: number
  PhysicsScore: number
  SpeedSlope: number
  AccelerationSlope: number
  MomentumSlope: number
  ConfluenceSlope: number
  JerkSlope: number
  Zone: string
  Regime: string
  PhysicsPass: boolean
  RejectReason?: string
}

interface TimeSegments {
  segment15m: string
  segment30m: string
  segment1h: string
  segment2h: string
  segment3h: string
  segment4h: string
}

interface ProcessedTimeData extends TimeSegments {
  mt5DateTime: string
  mt5Date: string
  mt5Time: string
  mt5Day: string
  mt5Month: string
  cstDate: string
  cstTime: string
  cstDay: string
  cstMonth: string
  session: string
}

export interface ProcessingResult {
  trades: Trade[]
  statistics: {
    totalMT5Trades: number
    pairedTrades: number
    eaTradesMatched: number
    eaSignalsMatched: number
    processingTimeMs: number
  }
  errors: string[]
}

// ============================================================================
// TIME SEGMENT CALCULATOR (Ported from timeSegmentCalculator.ts)
// ============================================================================

class TimeSegmentCalculator {
  private static readonly MT5_TO_CST_OFFSET_HOURS = -8

  static calculateSegments(cstTime: Date): TimeSegments {
    const hour = cstTime.getHours()
    const minute = cstTime.getMinutes()
    
    const seg15mNum = hour * 4 + Math.floor(minute / 15) + 1
    const seg30mNum = hour * 2 + Math.floor(minute / 30) + 1
    const seg1hNum = hour + 1
    const seg2hNum = Math.floor(hour / 2) + 1
    const seg3hNum = Math.floor(hour / 3) + 1
    const seg4hNum = Math.floor(hour / 4) + 1
    
    return {
      segment15m: `15-${String(seg15mNum).padStart(3, '0')}`,
      segment30m: `30-${String(seg30mNum).padStart(3, '0')}`,
      segment1h: `1h-${String(seg1hNum).padStart(3, '0')}`,
      segment2h: `2h-${String(seg2hNum).padStart(3, '0')}`,
      segment3h: `3h-${String(seg3hNum).padStart(3, '0')}`,
      segment4h: `4h-${String(seg4hNum).padStart(3, '0')}`
    }
  }

  static processTimestamp(mt5Timestamp: string, mt5ToCstOffsetHours: number = TimeSegmentCalculator.MT5_TO_CST_OFFSET_HOURS): ProcessedTimeData {
    const mt5Date = this.parseMT5Timestamp(mt5Timestamp)
    const cstDate = new Date(mt5Date.getTime() + (mt5ToCstOffsetHours * 60 * 60 * 1000))
    const segments = this.calculateSegments(cstDate)
    const session = this.determineSession(cstDate)
    
    return {
      mt5DateTime: mt5Timestamp,
      mt5Date: this.formatDate(mt5Date),
      mt5Time: this.formatTime(mt5Date),
      mt5Day: this.getDayName(mt5Date),
      mt5Month: this.getMonthName(mt5Date),
      cstDate: this.formatDate(cstDate),
      cstTime: this.formatTime(cstDate),
      cstDay: this.getDayName(cstDate),
      cstMonth: this.getMonthName(cstDate),
      session: session,
      ...segments
    }
  }

  private static parseMT5Timestamp(timestamp: string): Date {
    if (!timestamp || typeof timestamp !== 'string') {
      throw new Error(`Invalid timestamp: ${timestamp}`)
    }
    const normalized = timestamp.replace(/\./g, '-')
    return new Date(normalized)
  }

  static determineSession(cstTime: Date): string {
    const hour = cstTime.getHours()
    const minute = cstTime.getMinutes()
    const totalMinutes = hour * 60 + minute
    
    const newsStart = 7 * 60 + 30
    const newsEnd = 8 * 60
    const openingStart = 8 * 60 + 30
    const openingEnd = 9 * 60
    const floorStart = 9 * 60 + 1
    const floorEnd = 14 * 60 + 44
    const closingStart = 14 * 60 + 45
    const closingEnd = 15 * 60 + 15
    
    if (totalMinutes >= newsStart && totalMinutes <= newsEnd) return "News"
    if (totalMinutes >= openingStart && totalMinutes <= openingEnd) return "Opening Bell"
    if (totalMinutes >= floorStart && totalMinutes <= floorEnd) return "Floor Session"
    if (totalMinutes >= closingStart && totalMinutes <= closingEnd) return "Closing Bell"
    return "After Hours"
  }

  private static formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  private static formatTime(date: Date): string {
    const hours = String(date.getHours()).padStart(2, '0')
    const minutes = String(date.getMinutes()).padStart(2, '0')
    const seconds = String(date.getSeconds()).padStart(2, '0')
    return `${hours}:${minutes}:${seconds}`
  }

  private static getDayName(date: Date): string {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    return days[date.getDay()]
  }

  private static getMonthName(date: Date): string {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ]
    return months[date.getMonth()]
  }

  static calculateTimeDelta(timestamp1: string, timestamp2: string): number {
    const date1 = this.parseMT5Timestamp(timestamp1)
    const date2 = this.parseMT5Timestamp(timestamp2)
    return Math.abs(date2.getTime() - date1.getTime()) / (1000 * 60)
  }
}

// ============================================================================
// CSV PROCESSOR
// ============================================================================

export class BrowserCSVProcessor {
  private mt5ToCstOffsetHours: number

  constructor(mt5ToCstOffsetHours: number = -8) {
    this.mt5ToCstOffsetHours = mt5ToCstOffsetHours
  }

  /**
   * Process all three CSV files and return Trade[] for the dashboard
   */
  async processAll(
    mt5ReportFile: File,
    eaTradesFile: File,
    eaSignalsFile: File
  ): Promise<ProcessingResult> {
    const startTime = Date.now()
    const errors: string[] = []

    console.log('🚀 Starting browser CSV processing...')

    // Step 1: Parse all CSV files
    const mt5Rows = await this.parseCSV<MT5ReportRow>(mt5ReportFile)
    const eaTradeRows = await this.parseEATrades(eaTradesFile)
    const eaSignalRows = await this.parseCSV<EASignalRow>(eaSignalsFile)

    console.log(`✅ Loaded ${mt5Rows.length} MT5 rows`)
    console.log(`✅ Loaded ${eaTradeRows.length} EA trade rows`)
    console.log(`✅ Loaded ${eaSignalRows.length} EA signal rows`)

    // Step 2: Pair MT5 entry/exit trades
    const pairedMT5Trades = this.pairMT5Trades(mt5Rows)
    console.log(`✅ Created ${pairedMT5Trades.length} paired trades`)

    // Step 3: Index EA trades
    const eaTradeMap = this.indexEATrades(eaTradeRows)
    console.log(`✅ Indexed ${eaTradeMap.size} EA trade pairs`)

    // Step 4: Index EA signals
    const eaSignalMap = this.indexEASignals(eaSignalRows)
    console.log(`✅ Indexed ${eaSignalMap.size} EA signals`)

    // Step 5: Join all data
    const trades: Trade[] = []
    let matchedEATrades = 0
    let matchedSignals = 0

    for (const mt5Trade of pairedMT5Trades) {
      try {
        const trade = this.joinTradeData(mt5Trade, eaTradeMap, eaSignalMap)
        if (trade.EA_Entry_PhysicsScore && trade.EA_Entry_PhysicsScore > 0) matchedEATrades++
        if (trade.Signal_Entry_Matched || trade.Signal_Exit_Matched) matchedSignals++
        trades.push(trade)
      } catch (err) {
        errors.push(`Error processing trade ${mt5Trade.entry.Order}: ${err}`)
      }
    }

    console.log(`✅ Matched ${matchedEATrades} EA trades`)
    console.log(`✅ Matched ${matchedSignals} signals`)

    const processingTime = Date.now() - startTime
    console.log(`✅ Processing complete in ${processingTime}ms`)

    return {
      trades,
      statistics: {
        totalMT5Trades: mt5Rows.length,
        pairedTrades: pairedMT5Trades.length,
        eaTradesMatched: matchedEATrades,
        eaSignalsMatched: matchedSignals,
        processingTimeMs: processingTime
      },
      errors
    }
  }

  private parseCSV<T>(file: File): Promise<T[]> {
    return new Promise((resolve, reject) => {
      Papa.parse(file, {
        header: true,
        skipEmptyLines: true,
        transformHeader: (header: string) => header.trim(),
        complete: (results) => {
          resolve(results.data as T[])
        },
        error: (error) => {
          reject(error)
        }
      })
    })
  }

  private async parseEATrades(file: File): Promise<EATradeRow[]> {
    const raw = await this.parseCSV<any>(file)
    
    return raw.map(row => {
      const cleaner = (v: any) => {
        if (v === undefined || v === null) return ''
        const s = String(v).trim()
        return s.replace(/,/g, '').replace(/\s+/g, '')
      }
      
      return {
        ...row,
        RowType: row.RowType ? String(row.RowType).toUpperCase() : '',
        Ticket: parseInt(cleaner(row.Ticket)) || 0,
        OpenPrice: parseFloat(cleaner(row.OpenPrice)) || 0,
        ClosePrice: parseFloat(cleaner(row.ClosePrice)) || 0,
        Price: parseFloat(cleaner(row.Price)) || 0,
        Profit: parseFloat(cleaner(row.Profit)) || 0,
        ProfitPercent: parseFloat(cleaner(row.ProfitPercent)) || 0,
        Pips: parseFloat(cleaner(row.Pips)) || 0,
        HoldTimeBars: parseInt(cleaner(row.HoldTimeBars)) || 0,
        HoldTimeMinutes: parseFloat(cleaner(row.HoldTimeMinutes)) || 0,
        RiskPercent: parseFloat(cleaner(row.RiskPercent)) || 0,
        RRatio: parseFloat(cleaner(row.RRatio)) || 0,
        MFE: parseFloat(cleaner(row.MFE)) || 0,
        MAE: parseFloat(cleaner(row.MAE)) || 0,
        MFE_Percent: parseFloat(cleaner(row.MFE_Percent)) || 0,
        MAE_Percent: parseFloat(cleaner(row.MAE_Percent)) || 0,
        MFE_Pips: parseFloat(cleaner(row.MFE_Pips)) || 0,
        MAE_Pips: parseFloat(cleaner(row.MAE_Pips)) || 0,
        MFE_TimeBars: parseInt(cleaner(row.MFE_TimeBars)) || 0,
        MAE_TimeBars: parseInt(cleaner(row.MAE_TimeBars)) || 0,
        MFEUtilization: parseFloat(cleaner(row.MFEUtilization)) || 0,
        MAEImpact: parseFloat(cleaner(row.MAEImpact)) || 0,
        ExcursionEfficiency: parseFloat(cleaner(row.ExcursionEfficiency)) || 0,
        RunUp_Price: parseFloat(cleaner(row.RunUp_Price)) || 0,
        RunUp_Pips: parseFloat(cleaner(row.RunUp_Pips)) || 0,
        RunUp_Percent: parseFloat(cleaner(row.RunUp_Percent)) || 0,
        RunUp_TimeBars: parseInt(cleaner(row.RunUp_TimeBars)) || 0,
        RunDown_Price: parseFloat(cleaner(row.RunDown_Price)) || 0,
        RunDown_Pips: parseFloat(cleaner(row.RunDown_Pips)) || 0,
        RunDown_Percent: parseFloat(cleaner(row.RunDown_Percent)) || 0,
        RunDown_TimeBars: parseInt(cleaner(row.RunDown_TimeBars)) || 0,
        Entry_Quality: parseFloat(cleaner(row.Entry_Quality)) || 0,
        Entry_Confluence: parseFloat(cleaner(row.Entry_Confluence)) || 0,
        Entry_Momentum: parseFloat(cleaner(row.Entry_Momentum)) || 0,
        Entry_Speed: parseFloat(cleaner(row.Entry_Speed)) || 0,
        Entry_Acceleration: parseFloat(cleaner(row.Entry_Acceleration)) || 0,
        Entry_Entropy: parseFloat(cleaner(row.Entry_Entropy)) || 0,
        Entry_Jerk: parseFloat(cleaner(row.Entry_Jerk)) || 0,
        Entry_PhysicsScore: parseFloat(cleaner(row.Entry_PhysicsScore)) || 0,
        Entry_SpeedSlope: parseFloat(cleaner(row.Entry_SpeedSlope)) || 0,
        Entry_AccelerationSlope: parseFloat(cleaner(row.Entry_AccelerationSlope)) || 0,
        Entry_MomentumSlope: parseFloat(cleaner(row.Entry_MomentumSlope)) || 0,
        Entry_ConfluenceSlope: parseFloat(cleaner(row.Entry_ConfluenceSlope)) || 0,
        Entry_JerkSlope: parseFloat(cleaner(row.Entry_JerkSlope)) || 0,
        Entry_Spread: parseFloat(cleaner(row.Entry_Spread)) || 0,
        Exit_Quality: parseFloat(cleaner(row.Exit_Quality)) || 0,
        Exit_Confluence: parseFloat(cleaner(row.Exit_Confluence)) || 0,
        Exit_Momentum: parseFloat(cleaner(row.Exit_Momentum)) || 0,
        Exit_Speed: parseFloat(cleaner(row.Exit_Speed)) || 0,
        Exit_Acceleration: parseFloat(cleaner(row.Exit_Acceleration)) || 0,
        Exit_Entropy: parseFloat(cleaner(row.Exit_Entropy)) || 0,
        Exit_Jerk: parseFloat(cleaner(row.Exit_Jerk)) || 0,
        Exit_PhysicsScore: parseFloat(cleaner(row.Exit_PhysicsScore)) || 0,
        Exit_SpeedSlope: parseFloat(cleaner(row.Exit_SpeedSlope)) || 0,
        Exit_AccelerationSlope: parseFloat(cleaner(row.Exit_AccelerationSlope)) || 0,
        Exit_MomentumSlope: parseFloat(cleaner(row.Exit_MomentumSlope)) || 0,
        Exit_ConfluenceSlope: parseFloat(cleaner(row.Exit_ConfluenceSlope)) || 0,
        Exit_JerkSlope: parseFloat(cleaner(row.Exit_JerkSlope)) || 0,
        Exit_Spread: parseFloat(cleaner(row.Exit_Spread)) || 0,
        EarlyExitOpportunityCost: parseFloat(cleaner(row.EarlyExitOpportunityCost)) || 0,
        PhysicsScoreDecay: parseFloat(cleaner(row.PhysicsScoreDecay)) || 0,
        SpeedDecay: parseFloat(cleaner(row.SpeedDecay)) || 0,
        SpeedSlopeDecay: parseFloat(cleaner(row.SpeedSlopeDecay)) || 0,
        ConfluenceDecay: parseFloat(cleaner(row.ConfluenceDecay)) || 0,
        ZoneTransitioned: row.ZoneTransitioned === 'TRUE' || row.ZoneTransitioned === 'true' || row.ZoneTransitioned === '1'
      }
    })
  }

  private pairMT5Trades(rows: MT5ReportRow[]): Array<{entry: MT5ReportRow, exit: MT5ReportRow}> {
    const paired: Array<{entry: MT5ReportRow, exit: MT5ReportRow}> = []
    const sortedRows = [...rows].sort((a, b) => parseInt(a.Deal) - parseInt(b.Deal))
    
    for (let i = 0; i < sortedRows.length - 1; i++) {
      const current = sortedRows[i]
      const next = sortedRows[i + 1]
      
      if (current.Direction.toLowerCase() === 'in' && 
          next.Direction.toLowerCase() === 'out' &&
          current.Symbol === next.Symbol) {
        paired.push({ entry: current, exit: next })
        i++
      }
    }
    
    return paired
  }

  private indexEATrades(rows: EATradeRow[]): Map<number, {entry: EATradeRow, exit: EATradeRow | null}> {
    const map = new Map<number, {entry: EATradeRow, exit: EATradeRow | null}>()
    const seen = new Set<string>()
    
    rows.forEach(row => {
      const ticketNum = Number(row.Ticket) || 0
      const rt = row.RowType ? String(row.RowType).toUpperCase() : ''
      const fp = `${ticketNum}:${rt}:${row.OpenPrice || row.Price || ''}:${row.ClosePrice || row.Price || ''}:${row.Profit || 0}`
      const key = `${ticketNum}:${rt}:${fp}`
      
      if (seen.has(key)) return
      seen.add(key)
      
      if (!map.has(ticketNum)) {
        map.set(ticketNum, { entry: null as any, exit: null })
      }

      const record = map.get(ticketNum)!
      if (rt === 'ENTRY') {
        record.entry = row
      } else if (rt === 'EXIT') {
        record.exit = row
      }
    })
    
    return map
  }

  private indexEASignals(rows: EASignalRow[]): Map<string, EASignalRow[]> {
    const map = new Map<string, EASignalRow[]>()
    
    rows.forEach(row => {
      if (!map.has(row.Symbol)) {
        map.set(row.Symbol, [])
      }
      map.get(row.Symbol)!.push(row)
    })
    
    map.forEach(signals => {
      signals.sort((a, b) => new Date(a.Timestamp).getTime() - new Date(b.Timestamp).getTime())
    })
    
    return map
  }

  private joinTradeData(
    mt5Trade: {entry: MT5ReportRow, exit: MT5ReportRow},
    eaTradeMap: Map<number, {entry: EATradeRow, exit: EATradeRow | null}>,
    eaSignalMap: Map<string, EASignalRow[]>
  ): Trade {
    const entryTime = TimeSegmentCalculator.processTimestamp(mt5Trade.entry.Time, this.mt5ToCstOffsetHours)
    const exitTime = TimeSegmentCalculator.processTimestamp(mt5Trade.exit.Time, this.mt5ToCstOffsetHours)
    
    const matchedEATrade = this.findMatchingEATrade(mt5Trade, eaTradeMap)
    const matchedEntrySignal = this.findMatchingSignal(
      mt5Trade.entry.Symbol,
      mt5Trade.entry.Time,
      mt5Trade.entry.Type,
      eaSignalMap
    )
    const matchedExitSignal = this.findMatchingSignal(
      mt5Trade.exit.Symbol,
      mt5Trade.exit.Time,
      mt5Trade.exit.Type,
      eaSignalMap
    )

    const cleaner = (v: any) => {
      if (v === undefined || v === null) return ''
      const s = String(v).trim()
      return s.replace(/,/g, '').replace(/\s+/g, '')
    }

    const profitRaw = mt5Trade.exit.Profit
    const profitClean = typeof profitRaw === 'string' ? profitRaw.replace(/\s+/g, '') : profitRaw
    let profit = parseFloat(cleaner(profitClean))
    if (isNaN(profit)) profit = 0

    const tradeResult: 'Win' | 'Loss' | 'Breakeven' | 'DataError' = 
      profit > 0.01 ? 'Win' : profit < -0.01 ? 'Loss' : 'Breakeven'
    
    const tradeDirection: 'Long' | 'Short' = mt5Trade.entry.Type.toLowerCase() === 'buy' ? 'Long' : 'Short'
    
    const entryDate = new Date(entryTime.mt5DateTime.replace(/\./g, '-'))
    const exitDate = new Date(exitTime.mt5DateTime.replace(/\./g, '-'))
    const durationMinutes = Math.floor((exitDate.getTime() - entryDate.getTime()) / (1000 * 60))
    
    const entryPrice = parseFloat(cleaner(mt5Trade.entry.Price))
    const exitPrice = parseFloat(cleaner(mt5Trade.exit.Price))
    const entryBalance = parseFloat(cleaner(mt5Trade.entry.Balance))
    const roi = entryBalance ? (profit / entryBalance) * 100 : 0

    // Extract EA data
    const eaData = this.extractEATradeData(matchedEATrade)
    
    // Override exit reason from MT5 comment
    const mt5Comment = mt5Trade.exit.Comment || ''
    if (/\btp\b/i.test(mt5Comment)) {
      eaData.EA_ExitReason = 'TP'
    } else if (/\bsl\b/i.test(mt5Comment)) {
      eaData.EA_ExitReason = 'SL'
    }

    const entrySignalData = this.extractSignalData(matchedEntrySignal, mt5Trade.entry.Time, 'Entry')
    const exitSignalData = this.extractSignalData(matchedExitSignal, mt5Trade.exit.Time, 'Exit')

    return {
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
      Strategy_ID_OP_03: matchedEATrade?.entry?.EAName || 'Unknown',
      Strategy_Version_ID_OP_03: matchedEATrade?.entry?.EAVersion || 'Unknown',
      Symbol_OP_03: mt5Trade.entry.Symbol,
      
      // Order Info (Entry)
      IN_Order_Type_OP_01: mt5Trade.entry.Type.toLowerCase(),
      IN_Order_Direction: 'in',
      Volume_OP_03: parseFloat(mt5Trade.entry.Volume),
      IN_Symbol_Price_OP_03: entryPrice,
      IN_Balance_OP_01: entryBalance,
      
      // Exit Data
      OUT_Profit_OP_01: profit,
      OUT_Balance_OP_01: parseFloat(cleaner(mt5Trade.exit.Balance)),
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
      
      // EA Enhanced Data
      ...eaData,
      
      // Signal Data
      ...entrySignalData,
      ...exitSignalData,
    } as Trade
  }

  private findMatchingEATrade(
    mt5Trade: {entry: MT5ReportRow, exit: MT5ReportRow},
    eaTradeMap: Map<number, {entry: EATradeRow, exit: EATradeRow | null}>
  ): {entry: EATradeRow, exit: EATradeRow | null} | null {
    const entryOrderId = parseInt(mt5Trade.entry.Order)
    
    if (eaTradeMap.has(entryOrderId)) {
      return eaTradeMap.get(entryOrderId)!
    }
    
    // Fallback: time/price proximity matching
    const mt5EntryTime = new Date(mt5Trade.entry.Time.replace(/\./g, '-')).getTime()
    const mt5EntryPrice = parseFloat(mt5Trade.entry.Price)
    const mt5Symbol = mt5Trade.entry.Symbol
    
    let bestMatch: {entry: EATradeRow, exit: EATradeRow | null} | null = null
    let bestTimeDelta = Infinity
    
    for (const [, eaTrade] of eaTradeMap) {
      if (!eaTrade.entry) continue
      if (eaTrade.entry.Symbol !== mt5Symbol) continue
      
      const eaEntryTime = new Date(eaTrade.entry.OpenTime || '').getTime()
      const eaEntryPrice = eaTrade.entry.OpenPrice || 0
      
      const timeDelta = Math.abs(eaEntryTime - mt5EntryTime)
      if (timeDelta > 60000) continue
      
      const priceDelta = Math.abs(eaEntryPrice - mt5EntryPrice) / mt5EntryPrice
      if (priceDelta > 0.001) continue
      
      if (timeDelta < bestTimeDelta) {
        bestTimeDelta = timeDelta
        bestMatch = eaTrade
      }
    }
    
    return bestMatch
  }

  private findMatchingSignal(
    symbol: string,
    entryTime: string,
    orderType: string,
    signalMap: Map<string, EASignalRow[]>
  ): EASignalRow | null {
    const signals = signalMap.get(symbol)
    if (!signals || signals.length === 0) return null
    
    const entryDate = new Date(entryTime.replace(/\./g, '-'))
    const entryTimestamp = entryDate.getTime()
    
    let bestMatch: EASignalRow | null = null
    let bestDelta = Infinity
    
    for (const signal of signals) {
      const signalDate = new Date(signal.Timestamp)
      const signalTimestamp = signalDate.getTime()
      
      if (signalTimestamp > entryTimestamp) continue
      
      const delta = entryTimestamp - signalTimestamp
      if (delta > 600000) continue
      
      if (!signal.SignalType || !orderType) continue
      const signalIsBuy = signal.SignalType.toUpperCase().includes('BUY')
      const orderIsBuy = orderType.toLowerCase() === 'buy'
      if (signalIsBuy !== orderIsBuy) continue
      
      if (delta < bestDelta) {
        bestDelta = delta
        bestMatch = signal
      }
    }
    
    return bestMatch
  }

  private extractEATradeData(eaTrade: {entry: EATradeRow, exit: EATradeRow | null} | null): Partial<Trade> {
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
      }
    }
    
    return {
      EA_Entry_Quality: eaTrade.entry.Entry_Quality || 0,
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
      
      EA_ExitReason: eaTrade.exit?.ExitReason || '',
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
      
      EA_Profit: eaTrade.exit?.Profit || 0,
      EA_ProfitPercent: eaTrade.exit?.ProfitPercent || 0,
      EA_Pips: eaTrade.exit?.Pips || 0,
      EA_HoldTimeBars: eaTrade.exit?.HoldTimeBars || 0,
      EA_HoldTimeMinutes: eaTrade.exit?.HoldTimeMinutes || 0,
      EA_RiskPercent: eaTrade.exit?.RiskPercent || 0,
      EA_RRatio: eaTrade.exit?.RRatio || 0,
      
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
      
      EA_PhysicsScoreDecay: eaTrade.exit?.PhysicsScoreDecay || 0,
      EA_SpeedDecay: eaTrade.exit?.SpeedDecay || 0,
      EA_SpeedSlopeDecay: eaTrade.exit?.SpeedSlopeDecay || 0,
      EA_ConfluenceDecay: eaTrade.exit?.ConfluenceDecay || 0,
      EA_ZoneTransitioned: eaTrade.exit?.ZoneTransitioned || false
    }
  }

  private extractSignalData(signal: EASignalRow | null, timestamp: string, prefix: 'Entry' | 'Exit'): Partial<Trade> {
    const fields: any = {}
    
    if (!signal) {
      fields[`Signal_${prefix}_Matched`] = false
      fields[`Signal_${prefix}_Timestamp`] = null
      fields[`Signal_${prefix}_TimeDelta`] = null
      fields[`Signal_${prefix}_Quality`] = null
      fields[`Signal_${prefix}_Confluence`] = null
      fields[`Signal_${prefix}_Speed`] = null
      fields[`Signal_${prefix}_Acceleration`] = null
      fields[`Signal_${prefix}_Momentum`] = null
      fields[`Signal_${prefix}_Entropy`] = null
      fields[`Signal_${prefix}_Jerk`] = null
      fields[`Signal_${prefix}_PhysicsScore`] = null
      fields[`Signal_${prefix}_SpeedSlope`] = null
      fields[`Signal_${prefix}_AccelerationSlope`] = null
      fields[`Signal_${prefix}_MomentumSlope`] = null
      fields[`Signal_${prefix}_ConfluenceSlope`] = null
      fields[`Signal_${prefix}_JerkSlope`] = null
      fields[`Signal_${prefix}_Zone`] = null
      fields[`Signal_${prefix}_Regime`] = null
      fields[`Signal_${prefix}_PhysicsPass`] = null
      fields[`Signal_${prefix}_RejectReason`] = null
      return fields
    }
    
    const timeDelta = TimeSegmentCalculator.calculateTimeDelta(signal.Timestamp, timestamp)
    
    fields[`Signal_${prefix}_Matched`] = true
    fields[`Signal_${prefix}_Timestamp`] = signal.Timestamp
    fields[`Signal_${prefix}_TimeDelta`] = timeDelta
    fields[`Signal_${prefix}_Quality`] = signal.Quality
    fields[`Signal_${prefix}_Confluence`] = signal.Confluence
    fields[`Signal_${prefix}_Speed`] = signal.Speed
    fields[`Signal_${prefix}_Acceleration`] = signal.Acceleration
    fields[`Signal_${prefix}_Momentum`] = signal.Momentum
    fields[`Signal_${prefix}_Entropy`] = signal.Entropy
    fields[`Signal_${prefix}_Jerk`] = signal.Jerk
    fields[`Signal_${prefix}_PhysicsScore`] = signal.PhysicsScore
    fields[`Signal_${prefix}_SpeedSlope`] = signal.SpeedSlope
    fields[`Signal_${prefix}_AccelerationSlope`] = signal.AccelerationSlope
    fields[`Signal_${prefix}_MomentumSlope`] = signal.MomentumSlope
    fields[`Signal_${prefix}_ConfluenceSlope`] = signal.ConfluenceSlope
    fields[`Signal_${prefix}_JerkSlope`] = signal.JerkSlope
    fields[`Signal_${prefix}_Zone`] = signal.Zone
    fields[`Signal_${prefix}_Regime`] = signal.Regime
    fields[`Signal_${prefix}_PhysicsPass`] = signal.PhysicsPass
    fields[`Signal_${prefix}_RejectReason`] = signal.RejectReason || null
    
    return fields
  }
}
