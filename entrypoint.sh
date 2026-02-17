#!/bin/bash
set -e

# Create data directory if it doesn't exist
mkdir -p /data

# Setup cron job
CRON_SCHEDULE=${CRON_SCHEDULE:-"*/30 * * * *"}
echo "Setting up speedtest cron job with schedule: $CRON_SCHEDULE"

# Create cron job
echo "$CRON_SCHEDULE cd /app && python3 speedtest_runner.py >> /var/log/speedtest.log 2>&1" | crontab -

# Start cron daemon
service cron start

# Run initial speedtest
python3 speedtest_runner.py

# Start web server
exec python3 web_server.py
