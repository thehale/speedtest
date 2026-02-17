#!/bin/bash
set -e

DATA_FILE="${DATA_FILE:-/data/speedtest.csv}"
HTML_FILE="${HTML_FILE:-/usr/share/nginx/html/index.html}"

# If no data exists yet, create a placeholder
if [ ! -f "$DATA_FILE" ] || [ ! -s "$DATA_FILE" ]; then
    cat > "$HTML_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Speedtest Results</title>
    <meta http-equiv="refresh" content="60">
    <style>
        :root { color-scheme: light dark; }
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            text-align: center;
            background: light-dark(#f5f5f5, #1a1a1a);
            color: light-dark(#333, #e0e0e0);
        }
        .container { max-width: 800px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Speedtest Results</h1>
        <p>No data available yet. Please wait for the first speedtest to complete.</p>
    </div>
</body>
</html>
EOF
    exit 0
fi

# Count records (excluding header)
count=$(tail -n +2 "$DATA_FILE" | wc -l)

# Calculate averages using awk
stats=$(tail -n +2 "$DATA_FILE" | awk -F',' '
    { 
        download_sum += $2; 
        upload_sum += $3; 
        ping_sum += $4; 
        count++ 
    } 
    END { 
        printf "%.2f %.2f %.2f", 
            (count > 0 ? download_sum/count : 0), 
            (count > 0 ? upload_sum/count : 0), 
            (count > 0 ? ping_sum/count : 0) 
    }'
)

avg_download=$(echo "$stats" | awk '{print $1}')
avg_upload=$(echo "$stats" | awk '{print $2}')
avg_ping=$(echo "$stats" | awk '{print $3}')

# Generate JavaScript data arrays from CSV
data_js=$(tail -n +2 "$DATA_FILE" | awk -F',' '
    BEGIN { print "const data = [" }
    { 
        gsub(/"/, "\\\"", $6); 
        gsub(/"/, "\\\"", $7);
        printf "  {timestamp: \"%s\", download: %s, upload: %s, ping: %s, jitter: %s, server: \"%s (%s)\"},\n", 
            $1, $2, $3, $4, $5, $6, $7
    }
    END { print "];" }'
)

# Create HTML with embedded data and Plotly.js
cat > "$HTML_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Speedtest Results</title>
    <meta http-equiv="refresh" content="60">
    <script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
    <style>
        :root { color-scheme: light dark; }
        body { font-family: Arial, sans-serif; margin: 20px; background: light-dark(#f5f5f5, #1a1a1a); color: light-dark(#333, #e0e0e0); }
        .container { max-width: 1200px; margin: 0 auto; background: light-dark(white, #2a2a2a); padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px light-dark(rgba(0,0,0,0.1), rgba(0,0,0,0.3)); }
        h1 { color: light-dark(#333, #e0e0e0); }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; }
        .stat-box { background: light-dark(#f0f0f0, #3a3a3a); padding: 15px; border-radius: 5px; flex: 1; min-width: 150px; }
        .stat-label { font-size: 12px; color: light-dark(#666, #999); }
        .stat-value { font-size: 24px; font-weight: bold; color: light-dark(#333, #f0f0f0); }
        #chart { width: 100%; height: 500px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Speedtest Results</h1>
        <div class="stats">
            <div class="stat-box">
                <div class="stat-label">Tests Run</div>
                <div class="stat-value">$count</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Download</div>
                <div class="stat-value">${avg_download} Mbps</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Upload</div>
                <div class="stat-value">${avg_upload} Mbps</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Avg Ping</div>
                <div class="stat-value">${avg_ping} ms</div>
            </div>
        </div>
        <div id="chart"></div>
    </div>
    
    <script>
$data_js

        // Prepare data for Plotly
        const timestamps = data.map(d => d.timestamp);
        const downloads = data.map(d => d.download);
        const uploads = data.map(d => d.upload);
        const pings = data.map(d => d.ping);

        const trace1 = {
            x: timestamps,
            y: downloads,
            name: 'Download (Mbps)',
            type: 'scatter',
            mode: 'lines+markers',
            line: { color: 'green', width: 2 },
            marker: { size: 6 }
        };

        const trace2 = {
            x: timestamps,
            y: uploads,
            name: 'Upload (Mbps)',
            type: 'scatter',
            mode: 'lines+markers',
            line: { color: 'blue', width: 2 },
            marker: { size: 6 }
        };

        const trace3 = {
            x: timestamps,
            y: pings,
            name: 'Ping (ms)',
            type: 'scatter',
            mode: 'lines+markers',
            yaxis: 'y2',
            line: { color: 'red', width: 2 },
            marker: { size: 6 }
        };

        // Detect dark mode preference
        const isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

        const layout = {
            title: {
                text: 'Internet Speed Over Time',
                font: { color: isDark ? '#e0e0e0' : '#333' }
            },
            paper_bgcolor: isDark ? '#2a2a2a' : 'white',
            plot_bgcolor: isDark ? '#2a2a2a' : 'white',
            font: { color: isDark ? '#e0e0e0' : '#333' },
            xaxis: { title: { text: 'Time', font: { color: isDark ? '#e0e0e0' : '#333' } }, gridcolor: isDark ? '#444' : '#e0e0e0', tickfont: { color: isDark ? '#999' : '#666' } },
            yaxis: { title: { text: 'Speed (Mbps)', font: { color: isDark ? '#e0e0e0' : '#333' } }, gridcolor: isDark ? '#444' : '#e0e0e0', tickfont: { color: isDark ? '#999' : '#666' }, side: 'left' },
            yaxis2: { title: { text: 'Ping (ms)', font: { color: isDark ? '#e0e0e0' : '#333' } }, gridcolor: isDark ? '#444' : '#e0e0e0', tickfont: { color: isDark ? '#999' : '#666' }, overlaying: 'y', side: 'right' },
            hovermode: 'x unified',
            showlegend: true,
            legend: { x: 0, y: 1.1, orientation: 'h', font: { color: isDark ? '#e0e0e0' : '#333' } }
        };

        Plotly.newPlot('chart', [trace1, trace2, trace3], layout, {responsive: true});

        // Update chart when system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
            location.reload();
        });
    </script>
</body>
</html>
EOF

echo "Generated HTML report at $HTML_FILE"
