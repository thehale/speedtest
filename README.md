# Speedtest Docker

A lightweight Docker container (~25MB) that runs Ookla Speedtest on a configurable cron schedule and serves interactive graphs via nginx.

## Quick Start

### Using Docker Compose

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Start the container:
   ```bash
   docker-compose up -d
   ```

3. Access the dashboard at http://localhost:8080

### Using Docker Run

```bash
docker run -d \
  --name speedtest \
  -p 8080:8080 \
  -v $(pwd)/data:/data \
  -e CRON_SCHEDULE="*/30 * * * *" \
  --restart unless-stopped \
  speedtest
```

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `CRON_SCHEDULE` | `*/30 * * * *` | Cron expression for test frequency |

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

## Architecture

- **Base image**: `nginx:stable-alpine-slim` (~12MB)
- **Speedtest**: Ookla's official CLI
- **Scheduling**: dcron (cron daemon)
- **Graphs**: Plotly.js (loaded from CDN) renders CSV data client-side
- **Image size**: ~25MB total (vs 648MB for Python-based image)

## Viewing Logs

```bash
# Docker Compose
docker-compose logs -f

# Docker
docker logs -f speedtest
```
