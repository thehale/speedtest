#!/bin/bash
set -e

echo "=== Speedtest Docker CI ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_IMAGE="speedtest-ci-test"
TEST_CONTAINER="speedtest-ci-container"
TEST_PORT="18080"

cleanup() {
    echo "Cleaning up..."
    docker rm -f "$TEST_CONTAINER" 2>/dev/null || true
    docker rmi "$TEST_IMAGE" 2>/dev/null || true
}

# Ensure cleanup on exit
trap cleanup EXIT

echo "Step 1: Building Docker image..."
if docker build -t "$TEST_IMAGE" . 2>&1; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

echo ""
echo "Step 2: Starting container..."
if docker run -d \
    --name "$TEST_CONTAINER" \
    -p "$TEST_PORT:8080" \
    "$TEST_IMAGE" 2>&1; then
    echo -e "${GREEN}✓ Container started${NC}"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    exit 1
fi

echo ""
echo "Step 3: Waiting for nginx to be ready..."
RETRIES=30
while [ $RETRIES -gt 0 ]; do
    if curl -s "http://localhost:$TEST_PORT" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Nginx is responding${NC}"
        break
    fi
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES -eq 0 ]; then
        echo -e "${RED}✗ Nginx failed to respond${NC}"
        echo "Container logs:"
        docker logs "$TEST_CONTAINER"
        exit 1
    fi
    sleep 1
done

echo ""
echo "Step 4: Verifying HTML response..."
RESPONSE=$(curl -s "http://localhost:$TEST_PORT")
if echo "$RESPONSE" | grep -q "Speedtest Results"; then
    echo -e "${GREEN}✓ HTML page loads correctly${NC}"
else
    echo -e "${RED}✗ HTML page does not contain expected content${NC}"
    echo "Response:"
    echo "$RESPONSE" | head -20
    exit 1
fi

echo ""
echo "Step 5: Checking dark theme support..."
if echo "$RESPONSE" | grep -q "color-scheme: light dark"; then
    echo -e "${GREEN}✓ Dark theme support detected${NC}"
else
    echo -e "${YELLOW}⚠ Dark theme support not detected${NC}"
fi

echo ""
echo "Step 6: Checking container logs for errors..."
if docker logs "$TEST_CONTAINER" 2>&1 | grep -i "error\|fatal" > /dev/null; then
    echo -e "${RED}✗ Errors found in container logs${NC}"
    docker logs "$TEST_CONTAINER"
    exit 1
else
    echo -e "${GREEN}✓ No errors in logs${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}All CI checks passed!${NC}"
echo "================================"
