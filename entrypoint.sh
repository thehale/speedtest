#!/bin/bash
set -e

# Setup home directory for current user
export HOME=${HOME:-/tmp}
mkdir -p "$HOME/.config/ookla"
cp "$HOME/speedtest-cli.json" "$HOME/.config/ookla/"

# Generate initial HTML page (before nginx starts)
/app/generate_html.sh

# Start nginx
nginx -g 'daemon off;' &
NGINX_PID=$!

# Run initial speedtest
/app/speedtest_runner.sh

# Setup and start supercronic (cron for containers, runs as non-root)
CRON_SCHEDULE="${CRON_SCHEDULE:-*/30 * * * *}"
echo "Setting up speedtest cron job with schedule: $CRON_SCHEDULE"

mkdir -p /tmp/crontabs
echo "$CRON_SCHEDULE /app/speedtest_runner.sh >> $HOME/speedtest.log 2>&1" > /tmp/crontabs/speedtest
touch "$HOME/speedtest.log"

echo "Starting supercronic..."
exec supercronic -passthrough-logs /tmp/crontabs/speedtest
