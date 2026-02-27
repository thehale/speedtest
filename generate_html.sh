#!/bin/bash
set -e

DATA_FILE="${DATA_FILE:-/data/speedtest.csv}"
HTML_FILE="${HTML_FILE:-/usr/share/nginx/html/index.html}"

FOOTER_HTML='    <footer style="text-align: center; margin-top: 20px; font-size: 12px; color: light-dark(#666, #999);">
        <a href="https://github.com/thehale/speedtest" style="color: inherit;">github.com/thehale/speedtest</a>
        &nbsp;|&nbsp;
        <a href="https://github.com/sponsors/thehale"><img src="https://badgen.net/badge/icon/Sponsor/pink?icon=github&label" alt="Sponsor" style="vertical-align: middle;"></a>
    </footer>'

# If no data exists yet, create a placeholder
if [ ! -f "$DATA_FILE" ] || [ ! -s "$DATA_FILE" ]; then
    cat > "$HTML_FILE" << EOF
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
$FOOTER_HTML
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
        .stat-box { padding: 15px; border-radius: 5px; flex: 1; min-width: 150px; color: white; }
        .stat-box.count { background: light-dark(#6c757d, #495057); }
        .stat-box.download { background: light-dark(#28a745, #2d8a3e); }
        .stat-box.upload { background: light-dark(#007bff, #0069d9); }
        .stat-box.ping { background: light-dark(#dc3545, #c82333); }
        .stat-label { font-size: 12px; opacity: 0.9; }
        .stat-value { font-size: 24px; font-weight: bold; }
        #bandwidth-chart { width: 100%; height: 400px; }
        #ping-chart { width: 100%; height: 300px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Speedtest Results</h1>
        <div class="stats">
            <div class="stat-box count">
                <div class="stat-label">Tests Run</div>
                <div class="stat-value">$count</div>
            </div>
            <div class="stat-box download">
                <div class="stat-label">Avg Download</div>
                <div class="stat-value">${avg_download} Mbps</div>
            </div>
            <div class="stat-box upload">
                <div class="stat-label">Avg Upload</div>
                <div class="stat-value">${avg_upload} Mbps</div>
            </div>
            <div class="stat-box ping">
                <div class="stat-label">Avg Ping</div>
                <div class="stat-value">${avg_ping} ms</div>
            </div>
        </div>
        <div id="bandwidth-chart"></div>
        <div id="ping-chart"></div>
    </div>
$FOOTER_HTML
    
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
            hovermode: 'x unified',
            showlegend: false
        };

        Plotly.newPlot('bandwidth-chart', [trace1, trace2], layout, {responsive: true});

        const pingLayout = {
            title: {
                text: 'Ping Over Time',
                font: { color: isDark ? '#e0e0e0' : '#333' }
            },
            paper_bgcolor: isDark ? '#2a2a2a' : 'white',
            plot_bgcolor: isDark ? '#2a2a2a' : 'white',
            font: { color: isDark ? '#e0e0e0' : '#333' },
            xaxis: { title: { text: 'Time', font: { color: isDark ? '#e0e0e0' : '#333' } }, gridcolor: isDark ? '#444' : '#e0e0e0', tickfont: { color: isDark ? '#999' : '#666' } },
            yaxis: { title: { text: 'Ping (ms)', font: { color: isDark ? '#e0e0e0' : '#333' } }, gridcolor: isDark ? '#444' : '#e0e0e0', tickfont: { color: isDark ? '#999' : '#666' } },
            hovermode: 'x unified',
            showlegend: false
        };

        Plotly.newPlot('ping-chart', [trace3], pingLayout, {responsive: true});

        // Update chart when system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
            location.reload();
        });
    </script>
</body>
</html>
EOF

echo "Generated HTML report at $HTML_FILE"
