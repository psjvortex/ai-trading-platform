#!/usr/bin/env python3
"""
Complete TickPhysics QA Workflow Example
Demonstrates the full validation process for self-learning and self-healing
"""

import pandas as pd
from pathlib import Path
import json
from analyze_backtest import TickPhysicsAnalyzer, compare_backtests


def run_complete_qa_workflow():
    """
    Complete QA workflow demonstrating:
    1. Baseline analysis
    2. Optimized analysis
    3. Comparison
    4. Learning state validation
    """
    
    print("\n" + "="*80)
    print("🚀 TICKPHYSICS COMPLETE QA WORKFLOW")
    print("="*80)
    
    # Directory setup
    results_dir = Path("backtest_results")
    baseline_dir = results_dir / "baseline"
    optimized_dir = results_dir / "optimized"
    
    # Check for baseline files
    baseline_signals = baseline_dir / "signals_baseline.csv"
    baseline_trades = baseline_dir / "trades_baseline.csv"
    
    if not baseline_signals.exists() or not baseline_trades.exists():
        print("\n⚠️  BASELINE FILES NOT FOUND")
        print("\nPlease complete the baseline backtest first:")
        print("1. Run MT5 Strategy Tester with conservative settings")
        print("2. Copy CSV files to backtest_results/baseline/")
        print("   - signals_baseline.csv")
        print("   - trades_baseline.csv")
        return
        
    # Check for optimized files
    optimized_signals = optimized_dir / "signals_optimized.csv"
    optimized_trades = optimized_dir / "trades_optimized.csv"
    
    if not optimized_signals.exists() or not optimized_trades.exists():
        print("\n⚠️  OPTIMIZED FILES NOT FOUND")
        print("\nPlease complete the optimized backtest:")
        print("1. Review baseline analysis suggestions")
        print("2. Update EA parameters (MinQuality, MinConfluence, etc.)")
        print("3. Re-run backtest with same date range")
        print("4. Copy CSV files to backtest_results/optimized/")
        return
        
    # === PHASE 1: BASELINE ANALYSIS ===
    print("\n" + "="*80)
    print("📊 PHASE 1: BASELINE ANALYSIS")
    print("="*80)
    
    baseline_analyzer = TickPhysicsAnalyzer(
        str(baseline_signals),
        str(baseline_trades)
    )
    
    print("\n📈 Baseline Performance:")
    baseline_metrics = baseline_analyzer.calculate_performance_metrics()
    print(f"  Total Trades: {baseline_metrics.get('total_trades', 0)}")
    print(f"  Win Rate: {baseline_metrics.get('win_rate', 0):.1f}%")
    print(f"  Profit Factor: {baseline_metrics.get('profit_factor', 0):.2f}")
    print(f"  Total Profit: ${baseline_metrics.get('total_profit', 0):.2f}")
    
    print("\n🎯 Signal Analysis:")
    baseline_signals_analysis = baseline_analyzer.analyze_signal_vs_trade_ratio()
    print(f"  Total Signals: {baseline_signals_analysis.get('total_signals', 0)}")
    print(f"  Executed Trades: {baseline_signals_analysis.get('total_trades', 0)}")
    print(f"  Skip Rate: {baseline_signals_analysis.get('skip_rate', 0):.1f}%")
    
    print("\n💡 Optimization Suggestions:")
    suggestions = baseline_analyzer.generate_optimization_suggestions()
    for i, suggestion in enumerate(suggestions, 1):
        print(f"  {i}. {suggestion}")
        
    # === PHASE 2: OPTIMIZED ANALYSIS ===
    print("\n" + "="*80)
    print("📊 PHASE 2: OPTIMIZED ANALYSIS")
    print("="*80)
    
    optimized_analyzer = TickPhysicsAnalyzer(
        str(optimized_signals),
        str(optimized_trades)
    )
    
    print("\n📈 Optimized Performance:")
    optimized_metrics = optimized_analyzer.calculate_performance_metrics()
    print(f"  Total Trades: {optimized_metrics.get('total_trades', 0)}")
    print(f"  Win Rate: {optimized_metrics.get('win_rate', 0):.1f}%")
    print(f"  Profit Factor: {optimized_metrics.get('profit_factor', 0):.2f}")
    print(f"  Total Profit: ${optimized_metrics.get('total_profit', 0):.2f}")
    
    print("\n🎯 Signal Analysis:")
    optimized_signals_analysis = optimized_analyzer.analyze_signal_vs_trade_ratio()
    print(f"  Total Signals: {optimized_signals_analysis.get('total_signals', 0)}")
    print(f"  Executed Trades: {optimized_signals_analysis.get('total_trades', 0)}")
    print(f"  Skip Rate: {optimized_signals_analysis.get('skip_rate', 0):.1f}%")
    
    # === PHASE 3: COMPARISON ===
    print("\n" + "="*80)
    print("📊 PHASE 3: BASELINE vs OPTIMIZED COMPARISON")
    print("="*80)
    
    compare_backtests(baseline_analyzer, optimized_analyzer)
    
    # Calculate improvements
    print("\n🎯 KEY IMPROVEMENTS:")
    
    win_rate_improvement = optimized_metrics.get('win_rate', 0) - baseline_metrics.get('win_rate', 0)
    pf_improvement = optimized_metrics.get('profit_factor', 0) - baseline_metrics.get('profit_factor', 0)
    profit_improvement = optimized_metrics.get('total_profit', 0) - baseline_metrics.get('total_profit', 0)
    skip_rate_increase = optimized_signals_analysis.get('skip_rate', 0) - baseline_signals_analysis.get('skip_rate', 0)
    
    print(f"  Win Rate: {win_rate_improvement:+.1f}% {'✅' if win_rate_improvement > 0 else '❌'}")
    print(f"  Profit Factor: {pf_improvement:+.2f} {'✅' if pf_improvement > 0 else '❌'}")
    print(f"  Total Profit: ${profit_improvement:+.2f} {'✅' if profit_improvement > 0 else '❌'}")
    print(f"  Skip Rate: {skip_rate_increase:+.1f}% {'✅' if skip_rate_increase > 0 else '❌'}")
    
    # === PHASE 4: VALIDATION SUMMARY ===
    print("\n" + "="*80)
    print("✅ SELF-LEARNING & SELF-HEALING VALIDATION")
    print("="*80)
    
    validation_checks = []
    
    # Check 1: Skip rate increased
    if skip_rate_increase > 5:
        validation_checks.append(("✅", "Skip rate increased - Self-healing filter is active"))
    else:
        validation_checks.append(("⚠️", "Skip rate change minimal - Review filter settings"))
        
    # Check 2: Win rate improved
    if win_rate_improvement > 3:
        validation_checks.append(("✅", "Win rate improved - Better trade selection"))
    elif win_rate_improvement > 0:
        validation_checks.append(("✅", "Win rate improved slightly"))
    else:
        validation_checks.append(("❌", "Win rate did not improve - Review parameters"))
        
    # Check 3: Profit factor improved
    if pf_improvement > 0.3:
        validation_checks.append(("✅", "Profit factor significantly improved"))
    elif pf_improvement > 0:
        validation_checks.append(("✅", "Profit factor improved"))
    else:
        validation_checks.append(("❌", "Profit factor did not improve"))
        
    # Check 4: Fewer total trades (but better quality)
    trade_reduction = baseline_metrics.get('total_trades', 0) - optimized_metrics.get('total_trades', 0)
    if trade_reduction > 0 and optimized_metrics.get('total_profit', 0) >= baseline_metrics.get('total_profit', 0):
        validation_checks.append(("✅", "Fewer trades with equal/better profit - Quality over quantity"))
    elif trade_reduction > 0:
        validation_checks.append(("⚠️", "Fewer trades but also lower profit - May be over-filtering"))
    else:
        validation_checks.append(("⚠️", "Trade count similar or increased"))
        
    print("\n")
    for symbol, message in validation_checks:
        print(f"{symbol} {message}")
        
    # Overall assessment
    passed_checks = sum(1 for s, _ in validation_checks if s == "✅")
    total_checks = len(validation_checks)
    
    print(f"\n📊 Overall Score: {passed_checks}/{total_checks} validation checks passed")
    
    if passed_checks == total_checks:
        print("🎉 EXCELLENT! Self-learning and self-healing are working as intended!")
        print("✅ Ready to present to business partner")
    elif passed_checks >= total_checks * 0.75:
        print("👍 GOOD! System is learning, but there's room for optimization")
        print("💡 Consider further parameter tuning")
    else:
        print("⚠️  NEEDS ATTENTION - Review EA configuration and learning logic")
        print("🔍 Check JSON learning state file and EA logs")
        
    # === PHASE 5: EXPORT RESULTS ===
    print("\n" + "="*80)
    print("💾 EXPORTING RESULTS")
    print("="*80)
    
    # Export comprehensive report
    report = {
        "timestamp": pd.Timestamp.now().isoformat(),
        "baseline": {
            "metrics": baseline_metrics,
            "signal_analysis": baseline_signals_analysis,
            "suggestions": suggestions
        },
        "optimized": {
            "metrics": optimized_metrics,
            "signal_analysis": optimized_signals_analysis
        },
        "improvements": {
            "win_rate": float(win_rate_improvement),
            "profit_factor": float(pf_improvement),
            "total_profit": float(profit_improvement),
            "skip_rate_increase": float(skip_rate_increase)
        },
        "validation": {
            "checks_passed": passed_checks,
            "total_checks": total_checks,
            "score_pct": (passed_checks / total_checks * 100) if total_checks > 0 else 0
        }
    }
    
    report_file = results_dir / "qa_report.json"
    with open(report_file, 'w') as f:
        json.dump(report, f, indent=2)
        
    print(f"✅ Comprehensive report exported to: {report_file}")
    
    # === NEXT STEPS ===
    print("\n" + "="*80)
    print("🚀 NEXT STEPS")
    print("="*80)
    print("\n1. Launch Dashboard:")
    print(f"   python3 dashboard.py \\")
    print(f"       {optimized_signals} \\")
    print(f"       {optimized_trades}")
    print("\n2. Inspect Learning State:")
    print("   python3 inspect_learning_state.py ~/Library/Application\\ Support/MetaQuotes/Terminal/*/MQL5/Files/TP_Learning_State_v2.0.json")
    print("\n3. Forward Testing:")
    print("   - Attach EA to demo account")
    print("   - Monitor for 1-2 weeks")
    print("   - Validate real-time learning")
    print("\n4. Business Presentation:")
    print("   - Use dashboard for visual demo")
    print("   - Highlight key improvements")
    print("   - Explain self-healing mechanism")
    
    print("\n" + "="*80)
    print("✅ QA WORKFLOW COMPLETE!")
    print("="*80 + "\n")


if __name__ == '__main__':
    run_complete_qa_workflow()
