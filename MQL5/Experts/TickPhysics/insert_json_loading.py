#!/usr/bin/env python3
"""Insert JSON loading code into OnInit()"""

json_loading_code = '''   // 1. Load JSON Configuration
   Print("📁 Loading JSON configuration...");
   if(!g_jsonConfig.Initialize(JSONConfigFile, true))
   {
      Print("❌ FAILED: JSON Config initialization");
      return INIT_FAILED;
   }
   
   if(!g_jsonConfig.LoadConfig(g_config))
   {
      Print("❌ FAILED: Could not load config from ", JSONConfigFile);
      Print("   Make sure file exists in: MQL5/Files/", JSONConfigFile);
      return INIT_FAILED;
   }
   
   Print("✅ Configuration loaded from JSON");
   g_jsonConfig.PrintConfig(g_config);
   
   // Copy time filter arrays to globals
   ArrayResize(g_allowedHours, g_config.allowedHoursCount);
   for(int i = 0; i < g_config.allowedHoursCount; i++)
      g_allowedHours[i] = g_config.allowedHours[i];
   
   ArrayResize(g_blockedHours, g_config.blockedHoursCount);
   for(int i = 0; i < g_config.blockedHoursCount; i++)
      g_blockedHours[i] = g_config.blockedHours[i];
   
   ArrayResize(g_blockedDays, g_config.blockedDaysCount);
   for(int i = 0; i < g_config.blockedDaysCount; i++)
      g_blockedDays[i] = g_config.blockedDays[i];
   
   Print("");
   
   // 2. Initialize Physics Indicator'''

with open('TP_Integrated_EA_Auto_2_7_NEW.mq5', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the OnInit start
old_start = '''   Print("═══════════════════════════════════════════════════════");
   
   // 1. Initialize Physics Indicator'''

new_start = '''   Print("═══════════════════════════════════════════════════════");
   
''' + json_loading_code

if old_start in content:
    content = content.replace(old_start, new_start)
    print("✅ Found and replaced OnInit section")
else:
    print("❌ Could not find target string")
    print("Looking for alternative...")
    # Try alternative
    alt_target = '''   Print("═══════════════════════════════════════════════════════");
   
   // 1. Initialize Physics Indicator
   Print("📊 Initializing Physics Indicator...");'''
    
    if alt_target in content:
        content = content.replace(alt_target, '''   Print("═══════════════════════════════════════════════════════");
   
''' + json_loading_code + '''
   Print("📊 Initializing Physics Indicator...");''')
        print("✅ Used alternative match")
    else:
        print("❌ Alternative also failed")

# Update section numbers (2→3, 3→4, 4→5, 5→6, 6→7)
content = content.replace('   // 2. Initialize Risk Manager', '   // 3. Initialize Risk Manager')
content = content.replace('   // 3. Initialize Trade Tracker', '   // 4. Initialize Trade Tracker')
content = content.replace('   // 4. Initialize CSV Logger', '   // 5. Initialize CSV Logger')
content = content.replace('   // 5. Initialize MA indicators', '   // 6. Initialize MA indicators')
content = content.replace('   // 6. Setup trade execution', '   // 7. Setup trade execution')

with open('TP_Integrated_EA_Auto_2_7_NEW.mq5', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ File updated with JSON loading code!")
print("📊 Section numbers updated: 2→3, 3→4, 4→5, 5→6, 6→7")

