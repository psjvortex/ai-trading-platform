import assert from 'assert';
import { TimeSegmentCalculator } from '../timeSegmentCalculator';
import { CSVProcessor } from '../csvProcessor';
import { MT5ReportRow } from '../types';

// Simple helper to create MT5 rows
function makeMT5Row(time: string, deal: string, direction: string, price = '1000', order = '1', symbol = 'EURUSD') {
  return {
    Time: time,
    Deal: deal,
    Symbol: symbol,
    Type: direction,
    Direction: direction === 'buy' ? 'in' : 'out',
    Volume: '0.01',
    Price: price,
    Order: order,
    Commission: '0',
    Swap: '0',
    Profit: '0',
    Balance: '1000'
  } as unknown as MT5ReportRow;
}

(async () => {
  console.log('\nRunning tests...');

  // TimeSegmentCalculator tests
  const ts = TimeSegmentCalculator.processTimestamp('2025.11.17 10:00');
  assert(ts.mt5Date === '2025-11-17', 'MT5 date should be correct');
  assert(typeof ts.cstTime === 'string', 'CST time field should exist');

  // Ensure CST offset logic works
  const tsOffset = TimeSegmentCalculator.processTimestamp('2025.11.17 10:00', -8);
  // Recompute expected: mt5 10:00 -> cst 02:00 (10 - 8)
  assert(tsOffset.cstTime.startsWith('02:'), `Expected 02:xx, got ${tsOffset.cstTime}`);

  console.log('✔ TimeSegmentCalculator tests passed');

  // Pair MT5 trades tests
  const rows: MT5ReportRow[] = [];
  rows.push(makeMT5Row('2025.11.17 09:00', '1', 'buy', '1000', '101'));
  rows.push(makeMT5Row('2025.11.17 09:15', '2', 'sell', '1005', '101'));
  rows.push(makeMT5Row('2025.11.17 10:00', '3', 'buy', '1000', '102'));
  rows.push(makeMT5Row('2025.11.17 10:30', '4', 'sell', '1002', '102'));

  const processor = new CSVProcessor();
  const paired = (processor as any).pairMT5Trades(rows);
  assert(paired.length === 2, `Expected 2 paired trades, found ${paired.length}`);

  console.log('✔ pairMT5Trades tests passed');

  console.log('\nAll tests passed!');
})();

// Fallback EA matching test (private method via "as any")
(async () => {
  console.log('\nRunning fallback match test...');
  const processor = new CSVProcessor();
  const mt5EntryRow = makeMT5Row('2025.11.17 09:00', '1', 'buy', '1000', '101');
  const mt5ExitRow = makeMT5Row('2025.11.17 09:10', '2', 'sell', '1002', '101');

  // Create EA trade entries with a different ticket but close time and price
  const eaEntry: any = {
    Ticket: 999,
    RowType: 'ENTRY',
    Symbol: 'EURUSD',
    OpenTime: '2025.11.17 08:59',
    OpenPrice: 1000.5,
    Entry_Quality: 95
  };
  const eaExit: any = {
    Ticket: 999,
    RowType: 'EXIT',
    CloseTime: '2025.11.17 09:09',
    ClosePrice: 1002.1
  };

  const eaMap = new Map<number, any>();
  eaMap.set(999, { entry: eaEntry, exit: eaExit });

  const match = (processor as any).findMatchingEATrade({ entry: mt5EntryRow, exit: mt5ExitRow }, eaMap);
  assert(match !== null, 'Expected fallback match to find EA trade');
  console.log('✔ Fallback match test passed');
})();

  // Duplicate EA row dedupe test
  (async () => {
    console.log('\nRunning EA dedupe test...');
    const processor = new CSVProcessor();
    const eaRows: any[] = [];
    // Two identical ENTRY rows
    eaRows.push({ Ticket: 101, RowType: 'ENTRY', Symbol: 'EURUSD', OpenTime: '2025.11.17 09:00', OpenPrice: 1000, Entry_Quality: 90 });
    eaRows.push({ Ticket: 101, RowType: 'ENTRY', Symbol: 'EURUSD', OpenTime: '2025.11.17 09:00', OpenPrice: 1000, Entry_Quality: 90 });
    // Time-tolerant duplicate (2 second difference) for ENTRY
    eaRows.push({ Ticket: 102, RowType: 'ENTRY', Symbol: 'EURUSD', OpenTime: '2025.11.17 09:01:00', OpenPrice: 1001, Entry_Quality: 90 });
    eaRows.push({ Ticket: 102, RowType: 'ENTRY', Symbol: 'EURUSD', OpenTime: '2025.11.17 09:01:01', OpenPrice: 1001, Entry_Quality: 90 });

    const map = (processor as any).indexEATrades(eaRows);
    // Should have 2 tickets (101 and 102)
    assert(map.size === 2, `Expected map.size 2, got ${map.size}`);
    const entry101 = map.get(101);
    const entry102 = map.get(102);
    assert(entry101 && entry101.entry, 'Entry 101 should exist');
    assert(entry102 && entry102.entry, 'Entry 102 should exist');
    console.log('✔ EA dedupe test passed');
  })();
