# Speedtest Docker - AI Agent Instructions

## Pre-Commit Verification

**CRITICAL: Run the CI script before every commit to verify the container builds and runs correctly.**

```bash
./bin/ci.sh
```

This script will:
1. Build the Docker image
2. Start a test container
3. Verify nginx responds on port 8080
4. Check the HTML page loads with expected content
5. Verify dark theme support
6. Check for errors in container logs

**DO NOT COMMIT if the CI script fails.** Fix the issues first.

## Project Overview

This is a lightweight Docker container (~35MB) that:
- Runs Ookla Speedtest CLI on a configurable cron schedule
- Generates interactive graphs using Plotly.js (client-side rendering)
- Serves results via nginx (unprivileged)
- Supports automatic dark/light theme switching

## Architecture

- **Base**: `nginxinc/nginx-unprivileged:alpine-slim`
- **Speedtest**: Ookla official CLI (downloaded at build time)
- **Cron**: dcron for scheduling
- **Graphs**: Plotly.js from CDN, data embedded in HTML
- **Security**: Runs as non-root (nginx user, uid 101)

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Container build instructions |
| `docker-compose.yml` | Local development orchestration |
| `speedtest_runner.sh` | Runs speedtest, saves to CSV |
| `generate_html.sh` | Generates static HTML from CSV data |
| `entrypoint.sh` | Container startup orchestration |
| `bin/ci.sh` | **Pre-commit verification script** |

## Common Issues

### Permission Denied Errors
The container runs as non-root. All directories that need writing must have 777 permissions or be owned by uid 101.

### Nginx Configuration
- Uses port 8080 (unprivileged)
- HTML served from `/app/html/`
- Configuration in `/etc/nginx/conf.d/default.conf`

### Build Failures
If `docker build` fails:
1. Check the nginx-unprivileged base image is accessible
2. Verify apk packages are available
3. Ensure speedtest CLI download URLs are valid

## Development Workflow

1. Make changes to source files
2. **Run `./bin/ci.sh`** to verify
3. Fix any failures
4. Commit with descriptive message
5. Push

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CRON_SCHEDULE` | `0 */5 * * *` | Speedtest frequency (every 5 hours) |
| `HOME` | `/tmp` | Required for non-root operation |
| `DATA_FILE` | `/data/speedtest.csv` | CSV data location |
| `HTML_FILE` | `/app/html/index.html` | Generated HTML location |

## Testing Locally

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Access dashboard
open http://localhost:8080
```

## CI Checklist

Before committing, verify:
- [ ] `./bin/ci.sh` passes completely
- [ ] Container builds without errors
- [ ] Container starts and stays running
- [ ] HTTP endpoint responds
- [ ] HTML contains "Speedtest Results"
- [ ] No errors in container logs
