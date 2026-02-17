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

# Set HOME environment variable for use in subsequent commands
ENV HOME=/home/speedtest

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

# Create nginx config that works with non-root user
RUN mkdir -p /tmp/nginx && chmod 777 /tmp/nginx && \
    sed -i 's/listen       80;/listen       8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen  \[::\]:80;/listen  [::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/user nginx;/# user nginx;/g' /etc/nginx/nginx.conf && \
    sed -i '/pid/d' /etc/nginx/nginx.conf && \
    sed -i 's|root   /usr/share/nginx/html|root   /app/html|g' /etc/nginx/conf.d/default.conf && \
    echo 'client_body_temp_path /tmp/nginx/client_temp;' >> /etc/nginx/nginx.conf && \
    echo 'proxy_temp_path /tmp/nginx/proxy_temp;' >> /etc/nginx/nginx.conf && \
    echo 'fastcgi_temp_path /tmp/nginx/fastcgi_temp;' >> /etc/nginx/nginx.conf && \
    echo 'uwsgi_temp_path /tmp/nginx/uwsgi_temp;' >> /etc/nginx/nginx.conf && \
    echo 'scgi_temp_path /tmp/nginx/scgi_temp;' >> /etc/nginx/nginx.conf

# Environment variables with defaults
ENV CRON_SCHEDULE="*/30 * * * *"
ENV DATA_FILE="/data/speedtest.csv"
ENV HTML_FILE="/app/html/index.html"

# Expose web port
EXPOSE 8080

# Volume for persistent data
VOLUME ["/data"]

# Start the application
ENTRYPOINT ["/app/entrypoint.sh"]
