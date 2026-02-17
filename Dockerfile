FROM nginx:stable-alpine-slim

# Install required packages
RUN apk add --no-cache \
    curl \
    bash \
    jq \
    coreutils \
    bc \
    dcron

# Install Ookla Speedtest CLI
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -sL https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz | tar -xzf - -C /usr/local/bin; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -sL https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-arm64.tgz | tar -xzf - -C /usr/local/bin; \
    fi && \
    chmod +x /usr/local/bin/speedtest

# Accept license automatically
RUN mkdir -p /root/.config/ookla && \
    echo '{"Settings": {"LicenseAccepted": "604ec14274326065ea260afd5035643b"}}' > /root/.config/ookla/speedtest-cli.json

# Create directories
RUN mkdir -p /data /app

# Copy application files
COPY speedtest_runner.sh /app/
COPY generate_html.sh /app/
COPY entrypoint.sh /app/
RUN chmod +x /app/*.sh

# Environment variables with defaults
ENV CRON_SCHEDULE="*/30 * * * *"
ENV DATA_FILE="/data/speedtest.csv"
ENV HTML_FILE="/usr/share/nginx/html/index.html"

# Nginx configuration for port 8080
RUN sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen  \[::\]:80;/listen  [::]:8080;/g' /etc/nginx/conf.d/default.conf

# Expose web port
EXPOSE 8080

# Volume for persistent data
VOLUME ["/data"]

# Start the application
ENTRYPOINT ["/app/entrypoint.sh"]
