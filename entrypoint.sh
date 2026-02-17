#!/bin/bash
set -e

# Setup home directory for current user
export HOME=${HOME:-/tmp}
mkdir -p "$HOME/.config/ookla"
cp "$HOME/speedtest-cli.json" "$HOME/.config/ookla/" 2>/dev/null || cp /tmp/speedtest-cli.json "$HOME/.config/ookla/"

# Setup cron job
CRON_SCHEDULE="${CRON_SCHEDULE:-*/30 * * * *}"
echo "Setting up speedtest cron job with schedule: $CRON_SCHEDULE"

# Create crontab file for current user
mkdir -p /tmp/crontabs
echo "$CRON_SCHEDULE /app/speedtest_runner.sh >> $HOME/speedtest.log 2>&1" > /tmp/crontabs/speedtest

# Create log file
touch "$HOME/speedtest.log"

# Generate initial HTML page (before nginx starts)
/app/generate_html.sh

# Start nginx
nginx -g 'daemon off;' &
NGINX_PID=$!

# Run initial speedtest
/app/speedtest_runner.sh

# Start cron in foreground (using busybox crond with user crontab)
echo "Starting cron daemon..."
crond -f -l 8 -L "$HOME/cron.log" -c /tmp/crontabs
