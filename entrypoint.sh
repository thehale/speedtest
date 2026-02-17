#!/bin/bash
set -e

# Setup cron job
CRON_SCHEDULE="${CRON_SCHEDULE:-*/30 * * * *}"
echo "Setting up speedtest cron job with schedule: $CRON_SCHEDULE"

# Create crontab file
echo "$CRON_SCHEDULE /app/speedtest_runner.sh >> /var/log/speedtest.log 2>&1" > /etc/crontabs/root

# Create log file
touch /var/log/speedtest.log

# Start nginx
nginx

# Run initial speedtest
/app/speedtest_runner.sh

# Start cron in foreground (using busybox crond)
echo "Starting cron daemon..."
crond -f -l 8 -L /var/log/cron.log
