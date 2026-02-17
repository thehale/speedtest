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
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
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
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; }
        .stat-box { background: #f0f0f0; padding: 15px; border-radius: 5px; flex: 1; min-width: 150px; }
        .stat-label { font-size: 12px; color: #666; }
        .stat-value { font-size: 24px; font-weight: bold; color: #333; }
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

        const layout = {
            title: 'Internet Speed Over Time',
            xaxis: { title: 'Time' },
            yaxis: { title: 'Speed (Mbps)', side: 'left' },
            yaxis2: { title: 'Ping (ms)', overlaying: 'y', side: 'right' },
            hovermode: 'x unified',
            showlegend: true,
            legend: { x: 0, y: 1.1, orientation: 'h' }
        };

        Plotly.newPlot('chart', [trace1, trace2, trace3], layout, {responsive: true});
    </script>
</body>
</html>
EOF

echo "Generated HTML report at $HTML_FILE"
