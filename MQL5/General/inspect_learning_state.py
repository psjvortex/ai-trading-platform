#!/usr/bin/env python3
"""
JSON Learning State Inspector
Validates and visualizes the EA's self-learning state
"""

import json
import sys
from pathlib import Path
from datetime import datetime


def inspect_learning_state(json_file: str):
    """Inspect and validate the JSON learning state file"""
    
    json_path = Path(json_file)
    
    if not json_path.exists():
        print(f"❌ JSON file not found: {json_file}")
        print("\n💡 Expected location: ~/Library/Application Support/MetaQuotes/Terminal/<ID>/MQL5/Files/")
        return False
        
    try:
        with open(json_path, 'r') as f:
            state = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON format: {e}")
        return False
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return False
        
    print("\n" + "="*80)
    print("🔍 TICKPHYSICS LEARNING STATE INSPECTION")
    print("="*80)
    
    print(f"\n📁 File: {json_file}")
    print(f"📅 Last Modified: {datetime.fromtimestamp(json_path.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📊 File Size: {json_path.stat().st_size} bytes")
    
    # Top-level keys
    print(f"\n🗝️  Top-Level Keys: {list(state.keys())}")
    
    # Analyze structure based on common patterns
    if 'trades' in state:
        print(f"\n📈 Trade History:")
        print(f"   Total Trades Logged: {len(state['trades'])}")
        
        if len(state['trades']) > 0:
            # Analyze win/loss distribution
            wins = sum(1 for t in state['trades'] if t.get('profit', 0) > 0)
            losses = sum(1 for t in state['trades'] if t.get('profit', 0) < 0)
            print(f"   Wins: {wins} | Losses: {losses}")
            
            # Show last few trades
            print(f"\n   Last 5 Trades:")
            for i, trade in enumerate(state['trades'][-5:], 1):
                profit = trade.get('profit', 0)
                symbol = "✅" if profit > 0 else "❌"
                print(f"   {symbol} Trade {i}: Profit=${profit:.2f}, Type={trade.get('type', 'N/A')}")
                
    if 'learned_patterns' in state:
        print(f"\n🧠 Learned Patterns:")
        patterns = state['learned_patterns']
        print(f"   Total Patterns: {len(patterns)}")
        
        # Show pattern types
        pattern_types = {}
        for pattern in patterns:
            ptype = pattern.get('type', 'unknown')
            pattern_types[ptype] = pattern_types.get(ptype, 0) + 1
            
        for ptype, count in pattern_types.items():
            print(f"   - {ptype}: {count}")
            
    if 'adaptations' in state:
        print(f"\n⚙️  Active Adaptations:")
        adaptations = state['adaptations']
        print(f"   Total Adaptations: {len(adaptations)}")
        
        for i, adapt in enumerate(adaptations[:5], 1):
            print(f"   {i}. {adapt.get('description', 'N/A')}")
            
    if 'statistics' in state:
        print(f"\n📊 Statistics:")
        stats = state['statistics']
        for key, value in stats.items():
            if isinstance(value, float):
                print(f"   {key.replace('_', ' ').title()}: {value:.2f}")
            else:
                print(f"   {key.replace('_', ' ').title()}: {value}")
                
    # Check for timestamps
    if 'last_updated' in state:
        print(f"\n⏰ Last Updated: {state['last_updated']}")
        
    if 'version' in state:
        print(f"🔖 Version: {state['version']}")
        
    # Validation checks
    print("\n" + "="*80)
    print("✅ VALIDATION CHECKS")
    print("="*80)
    
    checks_passed = 0
    total_checks = 0
    
    # Check 1: File is not empty
    total_checks += 1
    if json_path.stat().st_size > 0:
        print("✅ File is not empty")
        checks_passed += 1
    else:
        print("❌ File is empty")
        
    # Check 2: Has trade history
    total_checks += 1
    if 'trades' in state and len(state['trades']) > 0:
        print("✅ Contains trade history")
        checks_passed += 1
    else:
        print("⚠️  No trade history found")
        
    # Check 3: Has recent activity
    total_checks += 1
    file_age_hours = (datetime.now().timestamp() - json_path.stat().st_mtime) / 3600
    if file_age_hours < 24:
        print(f"✅ Recently modified ({file_age_hours:.1f} hours ago)")
        checks_passed += 1
    else:
        print(f"⚠️  File is old ({file_age_hours:.1f} hours ago)")
        
    # Check 4: Structure is valid
    total_checks += 1
    required_keys = ['trades', 'statistics']
    has_required = all(key in state for key in required_keys)
    if has_required:
        print("✅ Has required structure")
        checks_passed += 1
    else:
        print(f"⚠️  Missing some expected keys: {[k for k in required_keys if k not in state]}")
        
    print(f"\n📊 Validation Score: {checks_passed}/{total_checks} checks passed")
    
    if checks_passed == total_checks:
        print("✅ Learning state appears healthy and active!")
    elif checks_passed >= total_checks * 0.7:
        print("⚠️  Learning state is functional but may need attention")
    else:
        print("❌ Learning state may have issues - review EA logs")
        
    print("\n" + "="*80)
    
    return True


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python3 inspect_learning_state.py <path_to_json_file>")
        print("\nExample:")
        print("  python3 inspect_learning_state.py ~/Library/Application\\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Learning_State_v2.0.json")
        sys.exit(1)
        
    json_file = sys.argv[1]
    inspect_learning_state(json_file)


if __name__ == '__main__':
    main()
