#!/usr/bin/env python3
"""
TickPhysics Professional Dashboard
Interactive web-based dashboard for visualizing EA performance and self-learning behavior
"""

import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from dash import Dash, dcc, html, Input, Output, callback
import argparse
from pathlib import Path
from datetime import datetime


class TickPhysicsDashboard:
    """Professional dashboard for TickPhysics EA analysis"""
    
    def __init__(self, signals_file: str, trades_file: str, title: str = "TickPhysics Backtest Analysis"):
        """Initialize dashboard with data files"""
        self.signals_file = Path(signals_file)
        self.trades_file = Path(trades_file)
        self.title = title
        
        # Load data
        self.signals_df = pd.read_csv(signals_file) if Path(signals_file).exists() else pd.DataFrame()
        self.trades_df = pd.read_csv(trades_file) if Path(trades_file).exists() else pd.DataFrame()
        
        # Initialize Dash app
        self.app = Dash(__name__)
        self.setup_layout()
        
    def create_equity_curve(self):
        """Create equity curve visualization"""
        if self.trades_df.empty or 'Balance' not in self.trades_df.columns:
            return go.Figure()
            
        fig = go.Figure()
        
        # Equity curve
        fig.add_trace(go.Scatter(
            x=list(range(len(self.trades_df))),
            y=self.trades_df['Balance'],
            mode='lines',
            name='Balance',
            line=dict(color='#2E86AB', width=2),
            fill='tozeroy',
            fillcolor='rgba(46, 134, 171, 0.1)'
        ))
        
        # Mark winning and losing trades
        wins = self.trades_df[self.trades_df['Profit'] > 0]
        losses = self.trades_df[self.trades_df['Profit'] < 0]
        
        if not wins.empty:
            fig.add_trace(go.Scatter(
                x=wins.index,
                y=wins['Balance'],
                mode='markers',
                name='Winning Trades',
                marker=dict(color='#06D6A0', size=8, symbol='triangle-up')
            ))
            
        if not losses.empty:
            fig.add_trace(go.Scatter(
                x=losses.index,
                y=losses['Balance'],
                mode='markers',
                name='Losing Trades',
                marker=dict(color='#EF476F', size=8, symbol='triangle-down')
            ))
        
        fig.update_layout(
            title='Equity Curve',
            xaxis_title='Trade Number',
            yaxis_title='Balance ($)',
            hovermode='x unified',
            template='plotly_white',
            height=400
        )
        
        return fig
        
    def create_performance_metrics_cards(self):
        """Create metric cards for key performance indicators"""
        if self.trades_df.empty:
            return html.Div("No trade data available")
            
        # Calculate metrics
        total_trades = len(self.trades_df)
        wins = len(self.trades_df[self.trades_df['Profit'] > 0])
        losses = len(self.trades_df[self.trades_df['Profit'] < 0])
        win_rate = (wins / total_trades * 100) if total_trades > 0 else 0
        
        total_profit = self.trades_df['Profit'].sum()
        gross_profit = self.trades_df[self.trades_df['Profit'] > 0]['Profit'].sum()
        gross_loss = abs(self.trades_df[self.trades_df['Profit'] < 0]['Profit'].sum())
        profit_factor = (gross_profit / gross_loss) if gross_loss > 0 else 0
        
        # Calculate max drawdown
        if 'Balance' in self.trades_df.columns:
            cumulative_max = self.trades_df['Balance'].cummax()
            drawdown = (self.trades_df['Balance'] - cumulative_max) / cumulative_max * 100
            max_dd = abs(drawdown.min())
        else:
            max_dd = 0
        
        # Create cards
        cards = html.Div([
            html.Div([
                self._create_metric_card("Total Trades", f"{total_trades}", "#2E86AB"),
                self._create_metric_card("Win Rate", f"{win_rate:.1f}%", "#06D6A0" if win_rate > 50 else "#EF476F"),
                self._create_metric_card("Profit Factor", f"{profit_factor:.2f}", "#06D6A0" if profit_factor > 1.5 else "#EF476F"),
                self._create_metric_card("Total Profit", f"${total_profit:.2f}", "#06D6A0" if total_profit > 0 else "#EF476F"),
                self._create_metric_card("Max Drawdown", f"{max_dd:.1f}%", "#EF476F" if max_dd > 20 else "#FFD23F"),
            ], style={'display': 'flex', 'justify-content': 'space-around', 'margin': '20px 0'})
        ])
        
        return cards
        
    def _create_metric_card(self, title, value, color):
        """Helper to create a single metric card"""
        return html.Div([
            html.H4(title, style={'margin': '0', 'color': '#666', 'font-size': '14px'}),
            html.H2(value, style={'margin': '10px 0 0 0', 'color': color, 'font-size': '32px', 'font-weight': 'bold'})
        ], style={
            'background': 'white',
            'padding': '20px',
            'border-radius': '8px',
            'box-shadow': '0 2px 4px rgba(0,0,0,0.1)',
            'min-width': '150px',
            'text-align': 'center'
        })
        
    def create_signal_analysis_chart(self):
        """Create chart showing signal types and trade execution"""
        if self.signals_df.empty:
            return go.Figure()
            
        # Count signals by type
        signal_counts = self.signals_df['Signal'].value_counts()
        
        fig = go.Figure(data=[
            go.Bar(
                x=signal_counts.index,
                y=signal_counts.values,
                marker_color=['#06D6A0' if s == 'BUY' else '#EF476F' if s == 'SELL' else '#FFD23F' 
                              for s in signal_counts.index],
                text=signal_counts.values,
                textposition='auto',
            )
        ])
        
        fig.update_layout(
            title='Signal Distribution (Self-Healing Filter Analysis)',
            xaxis_title='Signal Type',
            yaxis_title='Count',
            template='plotly_white',
            height=350
        )
        
        return fig
        
    def create_profit_distribution(self):
        """Create profit distribution histogram"""
        if self.trades_df.empty:
            return go.Figure()
            
        fig = go.Figure()
        
        # Separate wins and losses
        wins = self.trades_df[self.trades_df['Profit'] > 0]['Profit']
        losses = self.trades_df[self.trades_df['Profit'] < 0]['Profit']
        
        fig.add_trace(go.Histogram(
            x=wins,
            name='Wins',
            marker_color='#06D6A0',
            opacity=0.7,
            nbinsx=20
        ))
        
        fig.add_trace(go.Histogram(
            x=losses,
            name='Losses',
            marker_color='#EF476F',
            opacity=0.7,
            nbinsx=20
        ))
        
        fig.update_layout(
            title='Profit Distribution',
            xaxis_title='Profit ($)',
            yaxis_title='Frequency',
            barmode='overlay',
            template='plotly_white',
            height=350
        )
        
        return fig
        
    def create_learning_state_timeline(self):
        """Create timeline showing self-learning adaptations"""
        if self.signals_df.empty:
            return go.Figure()
            
        # Group signals by time periods and calculate skip rate
        # This shows how the EA's filtering behavior changes over time
        window_size = max(len(self.signals_df) // 10, 50)  # 10 periods or min 50 signals
        
        skip_rates = []
        periods = []
        
        for i in range(0, len(self.signals_df), window_size):
            window = self.signals_df.iloc[i:i+window_size]
            skips = len(window[window['Signal'] == 'SKIP'])
            total = len(window)
            skip_rate = (skips / total * 100) if total > 0 else 0
            skip_rates.append(skip_rate)
            periods.append(f"Period {len(periods)+1}")
            
        fig = go.Figure()
        
        fig.add_trace(go.Scatter(
            x=periods,
            y=skip_rates,
            mode='lines+markers',
            name='Skip Rate',
            line=dict(color='#A23B72', width=3),
            marker=dict(size=10),
            fill='tozeroy',
            fillcolor='rgba(162, 59, 114, 0.1)'
        ))
        
        fig.update_layout(
            title='Self-Learning Evolution: Signal Skip Rate Over Time',
            xaxis_title='Time Period',
            yaxis_title='Skip Rate (%)',
            template='plotly_white',
            height=350
        )
        
        return fig
        
    def create_comparison_charts(self, baseline_signals: str, baseline_trades: str):
        """Create before/after comparison charts"""
        baseline_signals_df = pd.read_csv(baseline_signals) if Path(baseline_signals).exists() else pd.DataFrame()
        baseline_trades_df = pd.read_csv(baseline_trades) if Path(baseline_trades).exists() else pd.DataFrame()
        
        # Create subplot with comparison metrics
        fig = make_subplots(
            rows=2, cols=2,
            subplot_titles=('Win Rate Comparison', 'Profit Factor Comparison', 
                          'Trade Count Comparison', 'Total Profit Comparison'),
            specs=[[{"type": "bar"}, {"type": "bar"}],
                   [{"type": "bar"}, {"type": "bar"}]]
        )
        
        # Calculate metrics for both
        def calc_metrics(trades_df):
            if trades_df.empty:
                return 0, 0, 0, 0
            wins = len(trades_df[trades_df['Profit'] > 0])
            total = len(trades_df)
            win_rate = (wins / total * 100) if total > 0 else 0
            
            gross_profit = trades_df[trades_df['Profit'] > 0]['Profit'].sum()
            gross_loss = abs(trades_df[trades_df['Profit'] < 0]['Profit'].sum())
            pf = (gross_profit / gross_loss) if gross_loss > 0 else 0
            
            return win_rate, pf, total, trades_df['Profit'].sum()
        
        baseline_wr, baseline_pf, baseline_count, baseline_profit = calc_metrics(baseline_trades_df)
        optimized_wr, optimized_pf, optimized_count, optimized_profit = calc_metrics(self.trades_df)
        
        # Win Rate
        fig.add_trace(go.Bar(x=['Baseline', 'Optimized'], y=[baseline_wr, optimized_wr],
                            marker_color=['#A23B72', '#06D6A0']), row=1, col=1)
        
        # Profit Factor
        fig.add_trace(go.Bar(x=['Baseline', 'Optimized'], y=[baseline_pf, optimized_pf],
                            marker_color=['#A23B72', '#06D6A0']), row=1, col=2)
        
        # Trade Count
        fig.add_trace(go.Bar(x=['Baseline', 'Optimized'], y=[baseline_count, optimized_count],
                            marker_color=['#A23B72', '#06D6A0']), row=2, col=1)
        
        # Total Profit
        fig.add_trace(go.Bar(x=['Baseline', 'Optimized'], y=[baseline_profit, optimized_profit],
                            marker_color=['#A23B72', '#06D6A0']), row=2, col=2)
        
        fig.update_layout(
            title_text="Baseline vs Optimized Performance",
            showlegend=False,
            template='plotly_white',
            height=600
        )
        
        return fig
        
    def setup_layout(self):
        """Setup the dashboard layout"""
        self.app.layout = html.Div([
            # Header
            html.Div([
                html.H1(self.title, style={
                    'text-align': 'center',
                    'color': '#2E86AB',
                    'margin': '20px 0',
                    'font-size': '36px'
                }),
                html.P(f"Analysis generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", 
                       style={'text-align': 'center', 'color': '#666'})
            ]),
            
            # Metrics Cards
            self.create_performance_metrics_cards(),
            
            # Charts
            html.Div([
                # Equity Curve
                dcc.Graph(figure=self.create_equity_curve()),
                
                # Row with two charts
                html.Div([
                    html.Div([
                        dcc.Graph(figure=self.create_signal_analysis_chart())
                    ], style={'width': '48%', 'display': 'inline-block'}),
                    
                    html.Div([
                        dcc.Graph(figure=self.create_profit_distribution())
                    ], style={'width': '48%', 'display': 'inline-block', 'float': 'right'}),
                ]),
                
                # Learning Timeline
                dcc.Graph(figure=self.create_learning_state_timeline()),
                
            ], style={'padding': '20px'}),
            
            # Footer
            html.Div([
                html.Hr(),
                html.P("TickPhysics Crypto Trading System - Self-Learning EA Dashboard", 
                       style={'text-align': 'center', 'color': '#999', 'margin': '20px 0'})
            ])
            
        ], style={
            'font-family': 'Arial, sans-serif',
            'background-color': '#f5f5f5',
            'padding': '20px'
        })
        
    def run(self, debug=True, port=8050):
        """Run the dashboard server"""
        print(f"\n🚀 Starting TickPhysics Dashboard...")
        print(f"📊 Dashboard URL: http://localhost:{port}")
        print(f"💡 Press Ctrl+C to stop the server\n")
        self.app.run_server(debug=debug, port=port)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Launch TickPhysics EA Dashboard')
    parser.add_argument('signals_file', help='Path to signals CSV file')
    parser.add_argument('trades_file', help='Path to trades CSV file')
    parser.add_argument('--port', type=int, default=8050, help='Dashboard port (default: 8050)')
    parser.add_argument('--title', default='TickPhysics Backtest Analysis', help='Dashboard title')
    
    args = parser.parse_args()
    
    dashboard = TickPhysicsDashboard(args.signals_file, args.trades_file, args.title)
    dashboard.run(port=args.port)


if __name__ == '__main__':
    main()
