#!/usr/bin/env ts-node

/**
 * CLI Tool for CSV Processing
 * 
 * Auto-discovery mode (searches /Users/patjohnston/Desktop/MT5_Backtest_Files):
 *   npm run process
 * 
 * Manual mode:
 *   npm run process -- \
 *     --mt5 path/to/MT5Report.csv \
 *     --trades path/to/EA_Trades.csv \
 *     --signals path/to/EA_Signals.csv \
 *     --output path/to/output
 */

import { Command } from 'commander';
import * as path from 'path';
import * as fs from 'fs';
import { CSVProcessor } from './csvProcessor';

const program = new Command();

// Default directory to search for CSV files
const DEFAULT_CSV_DIRECTORY = '/Users/patjohnston/Desktop/MT5_Backtest_Files';

/**
 * Auto-discover CSV files in the default directory
 */
function autoDiscoverFiles(directory: string): { mt5?: string; trades?: string; signals?: string } {
  console.log(`\n🔍 Auto-discovering CSV files in: ${directory}`);
  
  if (!fs.existsSync(directory)) {
    console.log(`⚠️  Directory not found: ${directory}`);
    return {};
  }
  
  const files = fs.readdirSync(directory);
  const csvFiles = files.filter(f => f.toLowerCase().endsWith('.csv'));
  
  console.log(`📄 Found ${csvFiles.length} CSV files:`);
  csvFiles.forEach(f => console.log(`   - ${f}`));
  
  // Find files by pattern matching
  const mt5File = csvFiles.find(f => 
    f.includes('MT5Report') || f.includes('MTBacktest') && !f.includes('trades') && !f.includes('signals')
  );
  const tradesFile = csvFiles.find(f => 
    f.includes('trades') && f.toLowerCase().endsWith('.csv')
  );
  const signalsFile = csvFiles.find(f => 
    f.includes('signals') && f.toLowerCase().endsWith('.csv')
  );
  
  const result: { mt5?: string; trades?: string; signals?: string } = {};
  
  if (mt5File) {
    result.mt5 = path.join(directory, mt5File);
    console.log(`✅ MT5 Report: ${mt5File}`);
  } else {
    console.log(`⚠️  MT5 Report not found (looking for *MT5Report*.csv or *MTBacktest*.csv)`);
  }
  
  if (tradesFile) {
    result.trades = path.join(directory, tradesFile);
    console.log(`✅ EA Trades: ${tradesFile}`);
  } else {
    console.log(`⚠️  EA Trades not found (looking for *trades*.csv)`);
  }
  
  if (signalsFile) {
    result.signals = path.join(directory, signalsFile);
    console.log(`✅ EA Signals: ${signalsFile}`);
  } else {
    console.log(`⚠️  EA Signals not found (looking for *signals*.csv)`);
  }
  
  return result;
}

program
  .name('csv-processor')
  .description('Process MT5 backtest reports, EA trades, and EA signals')
  .version('2.0.0');

program
  .command('process')
  .description('Process and join CSV files (auto-discovers files if paths not provided)')
  .option('--mt5 <path>', 'Path to MT5 backtest report CSV (optional if using auto-discovery)')
  .option('--trades <path>', 'Path to EA trades CSV (optional if using auto-discovery)')
  .option('--signals <path>', 'Path to EA signals CSV (optional if using auto-discovery)')
  .option('--dir <path>', `Directory to search for CSV files (default: ${DEFAULT_CSV_DIRECTORY})`)
  .option('--output <path>', 'Output directory for processed files', './output')
  .option('--format <type>', 'Output format: json, csv, or both', 'both')
  .option('--mt5-to-cst-offset <hours>', 'MT5 to CST offset in hours (negative value: subtract from MT5). Default: -8', '-8')
  .action(async (options) => {
    try {
      console.log('\n🚀 CSV Processor v2.0.0');
      console.log('=' .repeat(60));
      
      // Determine file paths
      let mt5Path = options.mt5;
      let tradesPath = options.trades;
      let signalsPath = options.signals;
      
      // If any path is missing, try auto-discovery
      if (!mt5Path || !tradesPath || !signalsPath) {
        const searchDir = options.dir || DEFAULT_CSV_DIRECTORY;
        const discovered = autoDiscoverFiles(searchDir);
        
        // Use discovered paths if manual paths not provided
        mt5Path = mt5Path || discovered.mt5;
        tradesPath = tradesPath || discovered.trades;
        signalsPath = signalsPath || discovered.signals;
      }
      
      // Validate we have all required files
      if (!mt5Path) {
        console.error('\n❌ Error: MT5 Report CSV not found');
        console.error('Please specify --mt5 path or ensure file exists in search directory');
        process.exit(1);
      }
      if (!tradesPath) {
        console.error('\n❌ Error: EA Trades CSV not found');
        console.error('Please specify --trades path or ensure file exists in search directory');
        process.exit(1);
      }
      if (!signalsPath) {
        console.error('\n❌ Error: EA Signals CSV not found');
        console.error('Please specify --signals path or ensure file exists in search directory');
        process.exit(1);
      }
      
      // Verify files exist
      if (!fs.existsSync(mt5Path)) {
        console.error(`\n❌ Error: MT5 file not found: ${mt5Path}`);
        process.exit(1);
      }
      if (!fs.existsSync(tradesPath)) {
        console.error(`\n❌ Error: Trades file not found: ${tradesPath}`);
        process.exit(1);
      }
      if (!fs.existsSync(signalsPath)) {
        console.error(`\n❌ Error: Signals file not found: ${signalsPath}`);
        process.exit(1);
      }
      
      console.log('\n📂 Using files:');
      console.log(`   MT5:     ${path.basename(mt5Path)}`);
      console.log(`   Trades:  ${path.basename(tradesPath)}`);
      console.log(`   Signals: ${path.basename(signalsPath)}`);
      
  const mt5ToCstOffset = parseInt(options.mt5ToCstOffset || options.mt5ToCstOffsetHours || '-8', 10) || -8;
  const processor = new CSVProcessor(mt5ToCstOffset);
      
      // Process all CSVs
      const dataset = await processor.processAll(
        mt5Path,
        tradesPath,
        signalsPath
      );
      
      // Generate output filenames
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
      const baseFilename = `processed_trades_${timestamp}`;
      
      // Export results
      console.log('\n📁 Exporting results...');
      
      if (options.format === 'json' || options.format === 'both') {
        const jsonPath = path.join(options.output, `${baseFilename}.json`);
        await processor.exportJSON(dataset, jsonPath);
      }
      
      if (options.format === 'csv' || options.format === 'both') {
        const csvPath = path.join(options.output, `${baseFilename}.csv`);
        await processor.exportCSV(dataset, csvPath);
      }
      
      // Print summary
      console.log('\n📊 Processing Summary');
      console.log('=' .repeat(60));
      console.log(`Total Trades:        ${dataset.statistics.totalMT5Trades}`);
      console.log(`Paired Trades:       ${dataset.statistics.pairedTrades}`);
      console.log(`EA Matches:          ${dataset.statistics.eaTradesMatched}`);
      console.log(`Signal Matches:      ${dataset.statistics.eaSignalsMatched}`);
      console.log(`Data Quality Score:  ${dataset.statistics.dataQualityScore}/100`);
      console.log(`Processing Time:     ${dataset.statistics.processingTimeMs}ms`);
      
      if (dataset.validation.criticalErrors.length > 0) {
        console.log(`\n⚠️  Critical Errors:   ${dataset.validation.criticalErrors.length}`);
        dataset.validation.criticalErrors.slice(0, 5).forEach(err => {
          console.log(`   - ${err.message}`);
        });
      }
      
      if (dataset.validation.warnings.length > 0) {
        console.log(`\n⚠️  Warnings:          ${dataset.validation.warnings.length}`);
      }
      
      console.log('\n✅ Processing complete!');
      console.log('=' .repeat(60) + '\n');
      
    } catch (error) {
      console.error('\n❌ Error:', error);
      process.exit(1);
    }
  });

program.parse();
