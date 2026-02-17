FROM python:3.11-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install Ookla Speedtest CLI
RUN curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash \
    && apt-get update && apt-get install -y speedtest \
    && rm -rf /var/lib/apt/lists/*

# Accept license automatically
RUN mkdir -p ~/.config/ookla && echo '{"Settings": {"LicenseAccepted": "604ec14274326065ea260afd5035643b"}}' > ~/.config/ookla/speedtest-cli.json

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY speedtest_runner.py .
COPY web_server.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Create data directory
RUN mkdir -p /data

# Environment variables with defaults
ENV CRON_SCHEDULE="*/30 * * * *"
ENV HTTP_PORT="8080"
ENV DATA_FILE="/data/speedtest.csv"

# Expose web port
EXPOSE ${HTTP_PORT}

# Volume for persistent data
VOLUME ["/data"]

# Start the application
ENTRYPOINT ["./entrypoint.sh"]
