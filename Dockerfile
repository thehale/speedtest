FROM nginxinc/nginx-unprivileged:alpine-slim

# Switch to root for package installation
USER root

# Install required packages
RUN apk add --no-cache \
    curl \
    bash \
    jq \
    coreutils \
    bc

# Install Supercronic (cron for containers)
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.43/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=f97b92132b61a8f827c3faf67106dc0e4467ccf2
RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  supercronic-linux-amd64" | sha1sum -c - \
    && chmod +x supercronic-linux-amd64 \
    && mv supercronic-linux-amd64 /usr/local/bin/supercronic

# Install Ookla Speedtest CLI
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -sL https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz | tar -xzf - -C /usr/local/bin; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -sL https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-arm64.tgz | tar -xzf - -C /usr/local/bin; \
    fi && \
    chmod +x /usr/local/bin/speedtest

# Set HOME to /tmp for the nginx user (nginx-unprivileged runs as uid 101)
ENV HOME=/tmp

# Create directories with wide permissions for any UID
RUN mkdir -p /data /app/html $HOME/.config/ookla && \
    chmod 777 /data $HOME /app/html && \
    chmod -R 777 $HOME/.config

# Accept license automatically (will be copied to user's home at runtime)
RUN echo '{"Settings": {"LicenseAccepted": "604ec14274326065ea260afd5035643b"}}' > $HOME/speedtest-cli.json

# Copy application files
COPY speedtest_runner.sh /app/
COPY generate_html.sh /app/
COPY entrypoint.sh /app/
RUN chmod +x /app/*.sh && chmod 777 /app

# Configure nginx to serve from our html directory
RUN sed -i 's|root   /usr/share/nginx/html|root   /app/html|g' /etc/nginx/conf.d/default.conf

# Switch back to non-root user for runtime
USER nginx

# Environment variables with defaults
ENV CRON_SCHEDULE="*/30 * * * *"
ENV DATA_FILE="/data/speedtest.csv"
ENV HTML_FILE="/app/html/index.html"

# Expose web port (nginx-unprivileged uses 8080 by default)
EXPOSE 8080

# Volume for persistent data
VOLUME ["/data"]

# Start the application
ENTRYPOINT ["/app/entrypoint.sh"]
