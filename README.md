# Speedtest Docker

A simple Docker container that runs Ookla Speedtest on a configurable cron schedule and serves graphs of historical results via HTTP.

## Features

- Runs Ookla Speedtest CLI on a configurable cron schedule
- Serves interactive graphs via Flask web server
- Persists historical data to a CSV file
- Simple configuration via environment variables

## Quick Start

### Using Docker Compose (Recommended)

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` to configure your settings:
   ```
   CRON_SCHEDULE=*/30 * * * *  # Every 30 minutes
   HTTP_PORT=8080
   ```

3. Start the container:
   ```bash
   docker-compose up -d
   ```

4. Access the dashboard at http://localhost:8080

### Using Docker Run

```bash
docker run -d \
  --name speedtest \
  -p 8080:8080 \
  -v $(pwd)/data:/data \
  -e CRON_SCHEDULE="*/30 * * * *" \
  -e HTTP_PORT=8080 \
  --restart unless-stopped \
  speedtest
```

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `CRON_SCHEDULE` | `*/30 * * * *` | Cron expression for test frequency |
| `HTTP_PORT` | `8080` | Port for the web dashboard |
| `DATA_FILE` | `/data/speedtest.csv` | Path to the CSV data file |

### Cron Schedule Examples

- Every 15 minutes: `*/15 * * * *`
- Every hour: `0 * * * *`
- Every 6 hours: `0 */6 * * *`
- Daily at midnight: `0 0 * * *`

## Data Persistence

The CSV file containing all speedtest results is stored at `/data/speedtest.csv` inside the container. Mount a volume to persist data:

```bash
-v /path/to/data:/data
```

## Building

```bash
docker build -t speedtest .
```

## Viewing Logs

```bash
# Docker Compose
docker-compose logs -f

# Docker
docker logs -f speedtest
```
