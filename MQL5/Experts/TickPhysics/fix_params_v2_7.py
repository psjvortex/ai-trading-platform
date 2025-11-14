#!/usr/bin/env python3
"""
Fix all parameter references in v2.7 EA
Replace old names with g_config.* equivalents
"""

# Parameter mapping: old_name -> g_config.field_name
PARAM_MAP = {
    # Debug/Monitoring
    'EnableDebugMode': 'g_config.enableDebugMode',
    'EnableRealTimeLogging': 'g_config.enableRealtimeLogging',
    'PostExitMonitorBars': 'g_config.postExitMonitorBars',
    
    # Entry System
    'UsePhysicsEntry': 'g_config.usePhysicsEntry',
    'UseMAEntry': 'g_config.useMAEntry',
    'MA_Fast': 'g_config.maFastPeriod',
    'MA_Slow': 'g_config.maSlowPeriod',
    'MA_Method': 'MODE_EMA',  # Hardcoded for now
    'MA_Price': 'PRICE_CLOSE',  # Hardcoded for now
    
    # Physics Filters
    'UsePhysicsFilters': 'g_config.physicsFiltersEnabled',
    'MinQuality': 'g_config.minQuality',
    'MinConfluence': 'g_config.minConfluence',
    'UseZoneFilter': 'g_config.zoneFilterEnabled',
    'UseRegimeFilter': 'g_config.regimeFilterEnabled',
    
    # Risk Management
    'RiskPercentPerTrade': 'g_config.riskPercentPerTrade',
    'MaxDailyRisk': 'g_config.maxDailyRisk',
    'MaxConcurrentTrades': 'g_config.maxConcurrentTrades',
    'MinRRatio': 'g_config.minRRatio',
    'StopLossPips': 'g_config.stopLossPips',
    'TakeProfitPips': 'g_config.takeProfitPips',
}

def replace_parameters(filepath):
    """Replace all old parameter names with g_config equivalents"""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    replacements = 0
    
    # Replace each parameter
    for old_name, new_name in PARAM_MAP.items():
        count = content.count(old_name)
        if count > 0:
            content = content.replace(old_name, new_name)
            replacements += count
            print(f"  ✓ {old_name:30s} -> {new_name:35s} ({count:2d} occurrences)")
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return replacements

if __name__ == '__main__':
    filepath = 'TP_Integrated_EA_Auto_2_7_NEW.mq5'
    
    print("🔧 Fixing parameter references in v2.7 EA...")
    print("=" * 80)
    
    replacements = replace_parameters(filepath)
    
    print("=" * 80)
    print(f"✅ Fixed {replacements} parameter references!")
    print(f"📄 Updated: {filepath}")
    print("\n💡 Next: Compile in MetaEditor (F7) - should get 0 errors now!")

