#!/bin/bash
# Convert v2.6 to v2.7 (JSON-driven) EA

FILE="TP_Integrated_EA_Auto_2_7.mq5"

# 1. Update header
sed -i '' 's/TP_Integrated_EA_Crossover_2_6.mq5/TP_Integrated_EA_Auto_2_7.mq5/' "$FILE"
sed -i '' 's/v2.6: Self-Improving EA - Time Filters + Physics/v2.7: Autonomous Self-Learning EA - JSON-Driven Configuration/' "$FILE"
sed -i '' 's/version   "2.6"/version   "2.7"/' "$FILE"
sed -i '' 's/Iterative optimization: v2.5 filters + Time-of-Day filtering (self-learning)/Fully autonomous EA with JSON configuration - Python learning engine updates parameters automatically/' "$FILE"

# 2. Add JSON include after CSV Logger include
sed -i '' '/#include <TickPhysics\/TP_CSV_Logger.mqh>/a\
#include <TickPhysics/TP_JSON_Config.mqh>
' "$FILE"

# 3. Update EA_NAME and EA_VERSION
sed -i '' 's/#define EA_NAME "TP_Integrated_EA"/#define EA_NAME "TP_Integrated_EA_Auto"/' "$FILE"
sed -i '' 's/#define EA_VERSION "2.6"/#define EA_VERSION "2.7"/' "$FILE"

echo "✅ v2.7 EA conversion completed"
