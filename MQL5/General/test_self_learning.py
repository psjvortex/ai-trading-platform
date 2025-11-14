#!/usr/bin/env python3
"""
Quick test script for the self-learning system
Validates that all components are working
"""

import json
from pathlib import Path

def test_json_config():
    """Test JSON config file validity"""
    print("=" * 70)
    print("🧪 Testing JSON Configuration")
    print("=" * 70)
    
    config_path = Path("EA_Config_v2_6.json")
    
    if not config_path.exists():
        print("❌ Config file not found!")
        return False
    
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
        print("✅ JSON file is valid")
    except json.JSONDecodeError as e:
        print(f"❌ JSON parsing error: {e}")
        return False
    
    # Check required sections
    required_sections = [
        'meta', 'risk_management', 'entry_system', 
        'physics_filters', 'time_filters', 'learning_parameters'
    ]
    
    for section in required_sections:
        if section in config:
            print(f"✅ Section '{section}' found")
        else:
            print(f"❌ Section '{section}' missing!")
            return False
    
    # Display current settings
    print("\n📋 Current Configuration:")
    print(f"   Version: {config['meta']['config_version']}")
    print(f"   Optimization Cycle: {config['meta']['optimization_cycle']}")
    print(f"   Time Filter: {config['time_filters']['enabled']}")
    print(f"   Allowed Hours: {config['time_filters']['allowed_hours']}")
    print(f"   Blocked Days: {config['time_filters']['blocked_days']}")
    print(f"   Min Quality: {config['physics_filters']['min_quality']}")
    print(f"   Auto-Update: {config['learning_parameters']['auto_update_enabled']}")
    
    return True


def test_python_engine():
    """Test Python learning engine import"""
    print("\n" + "=" * 70)
    print("🧪 Testing Python Learning Engine")
    print("=" * 70)
    
    try:
        from self_learning_engine import SelfLearningEngine
        print("✅ Learning engine module imported successfully")
        
        # Test initialization
        engine = SelfLearningEngine('EA_Config_v2_6.json', 'dummy.csv')
        print("✅ Engine initialized")
        
        # Test config loading
        config = engine.load_config()
        print(f"✅ Config loaded: {config['meta']['config_version']}")
        
        return True
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_file_structure():
    """Check that all required files exist"""
    print("\n" + "=" * 70)
    print("🧪 Testing File Structure")
    print("=" * 70)
    
    required_files = {
        'EA_Config_v2_6.json': 'JSON configuration file',
        'self_learning_engine.py': 'Python learning engine',
        'SELF_LEARNING_README.md': 'Documentation',
        'Include/TickPhysics/TP_JSON_Config.mqh': 'MQL5 JSON parser'
    }
    
    all_exist = True
    for file_path, description in required_files.items():
        path = Path(file_path)
        if path.exists():
            print(f"✅ {file_path:<45} ({description})")
        else:
            print(f"❌ {file_path:<45} MISSING!")
            all_exist = False
    
    return all_exist


def test_csv_detection():
    """Check for existing trade CSV files"""
    print("\n" + "=" * 70)
    print("🧪 Testing Trade CSV Detection")
    print("=" * 70)
    
    csv_files = list(Path('.').glob('TP_Integrated_Trades_*.csv'))
    
    if not csv_files:
        print("⚠️  No trade CSV files found (run a backtest first)")
        return True  # Not a failure, just no data yet
    
    print(f"✅ Found {len(csv_files)} trade CSV file(s):")
    for csv_file in sorted(csv_files):
        size = csv_file.stat().st_size
        print(f"   📄 {csv_file.name} ({size:,} bytes)")
    
    return True


def main():
    """Run all tests"""
    print("\n" + "=" * 70)
    print("🚀 TICKPHYSICS SELF-LEARNING SYSTEM TEST")
    print("=" * 70 + "\n")
    
    tests = [
        ("File Structure", test_file_structure),
        ("JSON Config", test_json_config),
        ("Python Engine", test_python_engine),
        ("CSV Detection", test_csv_detection),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"\n❌ Test '{test_name}' crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 70)
    print("📊 TEST SUMMARY")
    print("=" * 70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}  {test_name}")
    
    print("=" * 70)
    print(f"Result: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All systems operational! Self-learning framework ready.")
        print("\n📚 Next Steps:")
        print("   1. Run v2.6 backtest in MT5")
        print("   2. Generate trade CSV")
        print("   3. Run: python3 self_learning_engine.py --report-only")
        print("   4. Review recommendations and optimize!")
    else:
        print("\n⚠️  Some tests failed. Fix issues before proceeding.")
    
    print("=" * 70 + "\n")
    
    return passed == total


if __name__ == '__main__':
    import sys
    sys.exit(0 if main() else 1)
