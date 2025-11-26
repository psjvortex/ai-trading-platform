/**
 * Time Segment Calculator
 * Handles timezone conversion (MT5 → CST) and calculates trading time segments
 */

import { TimeSegments, ProcessedTimeData } from './types';

export class TimeSegmentCalculator {
  // MT5 typically uses GMT+2 (broker time), CST is GMT-6
  // Therefore: CST = MT5 - 8 hours
  private static readonly MT5_TO_CST_OFFSET_HOURS = -8;

  /**
   * Calculate all time segments for a given CST timestamp
   * @param cstTime Date object in CST timezone
   * @returns Object containing all time segments
   */
  static calculateSegments(cstTime: Date): TimeSegments {
    const hour = cstTime.getHours();
    const minute = cstTime.getMinutes();
    
    // Calculate segment numbers (1-indexed)
    const seg15mNum = hour * 4 + Math.floor(minute / 15) + 1;
    const seg30mNum = hour * 2 + Math.floor(minute / 30) + 1;
    const seg1hNum = hour + 1;
    const seg2hNum = Math.floor(hour / 2) + 1;
    const seg3hNum = Math.floor(hour / 3) + 1;
    const seg4hNum = Math.floor(hour / 4) + 1;
    
    return {
      segment15m: `15-${String(seg15mNum).padStart(3, '0')}`,  // "15-069" (96 segments/day)
      segment30m: `30-${String(seg30mNum).padStart(3, '0')}`,  // "30-035" (48 segments/day)
      segment1h: `1h-${String(seg1hNum).padStart(3, '0')}`,    // "1h-018" (24 segments/day)
      segment2h: `2h-${String(seg2hNum).padStart(3, '0')}`,    // "2h-009" (12 segments/day)
      segment3h: `3h-${String(seg3hNum).padStart(3, '0')}`,    // "3h-006" (8 segments/day)
      segment4h: `4h-${String(seg4hNum).padStart(3, '0')}`     // "4h-005" (6 segments/day)
    };
  }

  /**
   * Convert MT5 timestamp to CST and calculate all segments
   * @param mt5Timestamp MT5 timestamp string (YYYY.MM.DD HH:MM or YYYY.MM.DD HH:MM:SS)
   * @returns Complete time data with segments
   */
  static processTimestamp(mt5Timestamp: string, mt5ToCstOffsetHours: number = TimeSegmentCalculator.MT5_TO_CST_OFFSET_HOURS): ProcessedTimeData {
    // Parse MT5 timestamp (format: YYYY.MM.DD HH:MM or YYYY.MM.DD HH:MM:SS)
    const mt5Date = this.parseMT5Timestamp(mt5Timestamp);
    
    // Convert to CST (subtract 8 hours)
  const cstDate = new Date(mt5Date.getTime() + (mt5ToCstOffsetHours * 60 * 60 * 1000));
    
    // Calculate segments
    const segments = this.calculateSegments(cstDate);
    
    // Determine trading session
    const session = this.determineSession(cstDate);
    
    // Format dates and times
    const mt5DateStr = this.formatDate(mt5Date);
    const mt5TimeStr = this.formatTime(mt5Date);
    const cstDateStr = this.formatDate(cstDate);
    const cstTimeStr = this.formatTime(cstDate);
    
    return {
      mt5DateTime: mt5Timestamp,
      mt5Date: mt5DateStr,
      mt5Time: mt5TimeStr,
      mt5Day: this.getDayName(mt5Date),
      mt5Month: this.getMonthName(mt5Date),
      cstDate: cstDateStr,
      cstTime: cstTimeStr,
      cstDay: this.getDayName(cstDate),
      cstMonth: this.getMonthName(cstDate),
      session: session,
      ...segments
    };
  }

  /**
   * Parse MT5 timestamp string to Date object
   * Handles formats: "YYYY.MM.DD HH:MM" or "YYYY.MM.DD HH:MM:SS"
   */
  private static parseMT5Timestamp(timestamp: string): Date {
    if (!timestamp || typeof timestamp !== 'string') {
      throw new Error(`Invalid timestamp: ${timestamp}`);
    }
    // Replace dots with dashes for standard date parsing
    // "2025.11.17 01:09" → "2025-11-17 01:09"
    const normalized = timestamp.replace(/\./g, '-');
    return new Date(normalized);
  }

  /**
   * Determine trading session based on CST time
   * Sessions according to data model spec:
   * - News: 07:30-08:00
   * - Opening Bell: 08:30-09:00
   * - Floor Session: 09:01-14:44
   * - Closing Bell: 14:45-15:15
   * - After Hours: All other times
   */
  static determineSession(cstTime: Date): string {
    const hour = cstTime.getHours();
    const minute = cstTime.getMinutes();
    const totalMinutes = hour * 60 + minute;
    
    // Define session boundaries (in minutes from midnight)
    const newsStart = 7 * 60 + 30;      // 07:30
    const newsEnd = 8 * 60;             // 08:00
    const openingStart = 8 * 60 + 30;   // 08:30
    const openingEnd = 9 * 60;          // 09:00
    const floorStart = 9 * 60 + 1;      // 09:01
    const floorEnd = 14 * 60 + 44;      // 14:44
    const closingStart = 14 * 60 + 45;  // 14:45
    const closingEnd = 15 * 60 + 15;    // 15:15
    
    if (totalMinutes >= newsStart && totalMinutes <= newsEnd) {
      return "News";
    } else if (totalMinutes >= openingStart && totalMinutes <= openingEnd) {
      return "Opening Bell";
    } else if (totalMinutes >= floorStart && totalMinutes <= floorEnd) {
      return "Floor Session";
    } else if (totalMinutes >= closingStart && totalMinutes <= closingEnd) {
      return "Closing Bell";
    } else {
      return "After Hours";
    }
  }

  /**
   * Format date as YYYY-MM-DD
   */
  private static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Format time as HH:MM:SS
   */
  private static formatTime(date: Date): string {
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  /**
   * Get day name (e.g., "Monday")
   */
  private static getDayName(date: Date): string {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.getDay()];
  }

  /**
   * Get month name (e.g., "January")
   */
  private static getMonthName(date: Date): string {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.getMonth()];
  }

  /**
   * Calculate time delta between two timestamps in minutes
   */
  static calculateTimeDelta(timestamp1: string, timestamp2: string): number {
    const date1 = this.parseMT5Timestamp(timestamp1);
    const date2 = this.parseMT5Timestamp(timestamp2);
    return Math.abs(date2.getTime() - date1.getTime()) / (1000 * 60);
  }
}
