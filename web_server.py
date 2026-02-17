#!/usr/bin/env python3
import os
import pandas as pd
import plotly.graph_objs as go
from flask import Flask, render_template_string
from datetime import datetime, timedelta

app = Flask(__name__)

DATA_FILE = os.environ.get('DATA_FILE', '/data/speedtest.csv')

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Speedtest Results</title>
    <meta http-equiv="refresh" content="60">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; }
        .stat-box { background: #f0f0f0; padding: 15px; border-radius: 5px; flex: 1; }
        .stat-label { font-size: 12px; color: #666; }
        .stat-value { font-size: 24px; font-weight: bold; color: #333; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Speedtest Results</h1>
        <div class="stats">
            <div class="stat-box">
                <div class="stat-label">Tests Run</div>
                <div class="stat-value">{{ count }}</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Download</div>
                <div class="stat-value">{{ avg_download }} Mbps</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Upload</div>
                <div class="stat-value">{{ avg_upload }} Mbps</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Ping</div>
                <div class="stat-value">{{ avg_ping }} ms</div>
            </div>
        </div>
        <div>{{ graph_html|safe }}</div>
    </div>
</body>
</html>
'''

def load_data():
    """Load speedtest data from CSV"""
    if not os.path.exists(DATA_FILE):
        return None
    
    df = pd.read_csv(DATA_FILE)
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    return df

@app.route('/')
def index():
    df = load_data()
    
    if df is None or df.empty:
        return '<h1>No data available yet</h1><p>Run a speedtest first!</p>'
    
    # Create graphs
    fig = go.Figure()
    
    # Download speed line
    fig.add_trace(go.Scatter(
        x=df['timestamp'],
        y=df['download_mbps'],
        name='Download (Mbps)',
        line=dict(color='green', width=2)
    ))
    
    # Upload speed line
    fig.add_trace(go.Scatter(
        x=df['timestamp'],
        y=df['upload_mbps'],
        name='Upload (Mbps)',
        line=dict(color='blue', width=2)
    ))
    
    # Ping line on secondary y-axis
    fig.add_trace(go.Scatter(
        x=df['timestamp'],
        y=df['ping_ms'],
        name='Ping (ms)',
        line=dict(color='red', width=2),
        yaxis='y2'
    ))
    
    fig.update_layout(
        title='Internet Speed Over Time',
        xaxis_title='Time',
        yaxis_title='Speed (Mbps)',
        yaxis2=dict(
            title='Ping (ms)',
            overlaying='y',
            side='right'
        ),
        hovermode='x unified',
        height=500
    )
    
    # Calculate stats
    stats = {
        'count': len(df),
        'avg_download': round(df['download_mbps'].mean(), 2),
        'avg_upload': round(df['upload_mbps'].mean(), 2),
        'avg_ping': round(df['ping_ms'].mean(), 2),
        'graph_html': fig.to_html(full_html=False, include_plotlyjs='cdn')
    }
    
    return render_template_string(HTML_TEMPLATE, **stats)

if __name__ == '__main__':
    port = int(os.environ.get('HTTP_PORT', '8080'))
    app.run(host='0.0.0.0', port=port, debug=False)
