#!/usr/bin/env ts-node

import * as fs from 'fs';
import * as path from 'path';
import { CSVProcessor } from '../csvProcessor';

async function main() {
  const jsonPath = path.join(__dirname, '../output/processed_trades_2025-11-24.json');
  if (!fs.existsSync(jsonPath)) {
    console.error('Processed JSON not found:', jsonPath);
    process.exit(1);
  }

  const content = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
  const trades = content.trades;

  const p = new CSVProcessor(-8);
  p.exportMissingEAExitReport(trades, path.join(__dirname, '../output'));
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
