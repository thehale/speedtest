#!/bin/bash
set -e

DATA_FILE="${DATA_FILE:-/data/speedtest.csv}"
HTML_FILE="${HTML_FILE:-/usr/share/nginx/html/index.html}"

# Ensure data directory exists
mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$HTML_FILE")"

# Run speedtest and capture JSON output
result=$(speedtest --format=json --accept-license --accept-gdpr 2>/dev/null)

if [ -z "$result" ]; then
    echo "Speedtest failed or returned empty result"
    exit 1
fi

# Parse results using jq
timestamp=$(date -Iseconds)
download_raw=$(echo "$result" | jq -r '.download.bandwidth')
upload_raw=$(echo "$result" | jq -r '.upload.bandwidth')
ping_ms=$(echo "$result" | jq -r '.ping.latency')
jitter_ms=$(echo "$result" | jq -r '.ping.jitter // 0')
server_name=$(echo "$result" | jq -r '.server.name')
server_location=$(echo "$result" | jq -r '.server.location')

# Convert bytes/sec to Mbps (multiply by 8, divide by 1,000,000)
download_mbps=$(echo "scale=2; $download_raw * 8 / 1000000" | bc)
upload_mbps=$(echo "scale=2; $upload_raw * 8 / 1000000" | bc)

# Write CSV header if file doesn't exist
if [ ! -f "$DATA_FILE" ]; then
    echo "timestamp,download_mbps,upload_mbps,ping_ms,jitter_ms,server_name,server_location" > "$DATA_FILE"
fi

# Append results to CSV
echo "$timestamp,$download_mbps,$upload_mbps,$ping_ms,$jitter_ms,$server_name,$server_location" >> "$DATA_FILE"

echo "Saved speedtest result at $timestamp"
echo "  Download: ${download_mbps} Mbps"
echo "  Upload: ${upload_mbps} Mbps"
echo "  Ping: ${ping_ms} ms"

# Regenerate HTML
/app/generate_html.sh
