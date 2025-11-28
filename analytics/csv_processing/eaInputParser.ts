/**
 * EA Input Parser
 * Extracts input parameters from MQL5 EA source files
 * Used to populate dashboard with actual EA settings
 */

import * as fs from 'fs';
import * as path from 'path';

export interface EAInputValue {
  name: string;
  type: string;
  value: string | number | boolean;
  comment: string;
  group: string;
}

export interface EAInputs {
  version: string;
  parsedAt: string;
  sourceFile: string;
  inputs: Record<string, EAInputValue>;
}

/**
 * Find the EA source file for a given version
 */
export function findEASourceFile(eaVersion: string, mql5RootPath?: string): string | null {
  // Default paths to search
  const searchPaths = [
    mql5RootPath,
    path.join(process.cwd(), '..', '..', 'MQL5', 'Experts', 'TickPhysics'),
    path.join(process.cwd(), 'MQL5', 'Experts', 'TickPhysics'),
    '/Volumes/Vortex_Trading/ai-trading-platform/MQL5/Experts/TickPhysics'
  ].filter(Boolean) as string[];

  // Convert version like "5.0.0.3" to filename pattern "5_0_0_3"
  const versionPattern = eaVersion.replace(/\./g, '_');
  const filePatterns = [
    `TP_Integrated_EA_Crossover_${versionPattern}.mq5`,
    `TP_Integrated_EA_${versionPattern}.mq5`,
    `*${versionPattern}*.mq5`
  ];

  for (const searchPath of searchPaths) {
    if (!fs.existsSync(searchPath)) continue;

    for (const pattern of filePatterns) {
      if (pattern.includes('*')) {
        // Glob pattern
        const files = fs.readdirSync(searchPath);
        const match = files.find(f => f.includes(versionPattern) && f.endsWith('.mq5'));
        if (match) {
          return path.join(searchPath, match);
        }
      } else {
        // Exact filename
        const fullPath = path.join(searchPath, pattern);
        if (fs.existsSync(fullPath)) {
          return fullPath;
        }
      }
    }
  }

  return null;
}

/**
 * Parse input declarations from EA source code
 */
export function parseEAInputs(sourceCode: string, eaVersion: string): EAInputs {
  const inputs: Record<string, EAInputValue> = {};
  let currentGroup = 'General';

  const lines = sourceCode.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();

    // Track input groups
    const groupMatch = trimmed.match(/^input\s+group\s+"([^"]+)"/);
    if (groupMatch) {
      currentGroup = groupMatch[1];
      continue;
    }

    // Parse input declarations
    // Patterns:
    // input double MinQualityBuy = 60.0;  // Min physics quality for BUY
    // input bool UsePhysicsFilters = true; // Enable physics filtering
    // input int MaxConcurrentTrades = 10;  // Max concurrent positions
    const inputMatch = trimmed.match(
      /^input\s+(double|int|bool|string|ENUM_\w+|INDICATOR_VERSION)\s+(\w+)\s*=\s*([^;]+);(?:\s*\/\/\s*(.*))?/
    );

    if (inputMatch) {
      const [, type, name, rawValue, comment] = inputMatch;
      let value: string | number | boolean = rawValue.trim();

      // Parse value based on type
      if (type === 'bool') {
        value = value.toLowerCase() === 'true';
      } else if (type === 'double') {
        value = parseFloat(value);
      } else if (type === 'int') {
        value = parseInt(value, 10);
      } else if (type.startsWith('ENUM_') || type === 'INDICATOR_VERSION') {
        // Keep as string for enums
        value = value.toString();
      }

      inputs[name] = {
        name,
        type,
        value,
        comment: comment?.trim() || '',
        group: currentGroup
      };
    }
  }

  return {
    version: eaVersion,
    parsedAt: new Date().toISOString(),
    sourceFile: '',
    inputs
  };
}

/**
 * Load and parse EA inputs from a source file
 */
export function loadEAInputs(eaVersion: string, mql5RootPath?: string): EAInputs | null {
  const sourceFile = findEASourceFile(eaVersion, mql5RootPath);
  
  if (!sourceFile) {
    console.warn(`⚠️  Could not find EA source file for version ${eaVersion}`);
    return null;
  }

  console.log(`📄 Found EA source: ${path.basename(sourceFile)}`);
  
  const sourceCode = fs.readFileSync(sourceFile, 'utf-8');
  const inputs = parseEAInputs(sourceCode, eaVersion);
  inputs.sourceFile = sourceFile;

  console.log(`✅ Parsed ${Object.keys(inputs.inputs).length} input parameters`);
  
  return inputs;
}

/**
 * Extract filter-related inputs for dashboard
 * Returns objects with value and type for use in OptimizationEngine
 */
export function getFilterInputs(eaInputs: EAInputs): Record<string, { value: string | number | boolean; type: string }> {
  const filterKeys = [
    // Quality
    'MinQualityBuy', 'MinQualitySell',
    // Physics Score
    'MinPhysicsScoreBuy', 'MinPhysicsScoreSell',
    // Speed
    'MinSpeedBuy', 'MinSpeedSell',
    // Acceleration  
    'MinAccelerationBuy', 'MinAccelerationSell',
    // Momentum
    'MinMomentumBuy', 'MinMomentumSell',
    // Slopes
    'MinSpeedSlopeBuy', 'MinSpeedSlopeSell',
    'MinAccelerationSlopeBuy', 'MinAccelerationSlopeSell',
    'MinMomentumSlopeBuy', 'MinMomentumSlopeSell',
    'MinConfluenceSlopeBuy', 'MinConfluenceSlopeSell',
    'MinJerkSlopeBuy', 'MinJerkSlopeSell',
    // Spread
    'MaxSpreadPips', 'MaxSpreadPipsBuy', 'MaxSpreadPipsSell',
    // Toggles
    'UsePhysicsFilters', 'UseSpreadFilter', 'AvoidTransitionZone',
    'UseRegimeFilter', 'UseAccelerationFilter', 'UseSpeedFilter',
    'UseMomentumFilter', 'UseSlopeFilters', 'UsePhysicsScoreFilter',
    'UseSpeedSlope', 'UseAccelerationSlope', 'UseConfluenceSlope',
    'UseMomentumSlope', 'UseJerkSlope'
  ];

  const result: Record<string, { value: string | number | boolean; type: string }> = {};
  
  for (const key of filterKeys) {
    if (eaInputs.inputs[key]) {
      result[key] = {
        value: eaInputs.inputs[key].value,
        type: eaInputs.inputs[key].type
      };
    }
  }

  return result;
}

/**
 * Get ALL EA inputs with full metadata (group, comment, type, value)
 * Used for generating complete MQL5 input blocks
 */
export function getAllInputs(eaInputs: EAInputs): Record<string, EAInputValue> {
  return eaInputs.inputs;
}

/**
 * Generate summary of EA settings for display
 */
export function generateEASettingsSummary(eaInputs: EAInputs): string {
  const filters = getFilterInputs(eaInputs);
  
  let summary = `// EA v${eaInputs.version} Current Settings\n`;
  summary += `// Parsed from: ${path.basename(eaInputs.sourceFile)}\n\n`;
  
  // Group by category
  const categories: Record<string, string[]> = {
    'Quality/Score': ['MinQualityBuy', 'MinQualitySell', 'MinPhysicsScoreBuy', 'MinPhysicsScoreSell'],
    'Speed/Accel/Momentum': ['MinSpeedBuy', 'MinSpeedSell', 'MinAccelerationBuy', 'MinAccelerationSell', 'MinMomentumBuy', 'MinMomentumSell'],
    'Slopes': ['MinSpeedSlopeBuy', 'MinSpeedSlopeSell', 'MinAccelerationSlopeBuy', 'MinAccelerationSlopeSell', 'MinMomentumSlopeBuy', 'MinMomentumSlopeSell', 'MinConfluenceSlopeBuy', 'MinConfluenceSlopeSell', 'MinJerkSlopeBuy', 'MinJerkSlopeSell'],
    'Spread': ['MaxSpreadPips']
  };

  for (const [category, keys] of Object.entries(categories)) {
    summary += `// ${category}\n`;
    for (const key of keys) {
      const filterInput = filters[key];
      if (filterInput !== undefined) {
        const input = eaInputs.inputs[key];
        const val = filterInput.value;
        const value = typeof val === 'number' ? val.toFixed(2) : val;
        summary += `input double ${key} = ${value};  // ${input?.comment || ''}\n`;
      }
    }
    summary += '\n';
  }

  return summary;
}

export default {
  findEASourceFile,
  parseEAInputs,
  loadEAInputs,
  getFilterInputs,
  generateEASettingsSummary
};
