#!/bin/bash
set -e

# Docker Publishing Script
# Pushes images to both Docker Hub and GitHub Container Registry
# Usage: bin/publish.sh [tag]
# If no tag provided, uses the current git tag

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-speedtest}"
DOCKER_HUB_REPO="${DOCKER_HUB_REPO:-thehale/speedtest}"
GITHUB_REPO="${GITHUB_REPO:-thehale/speedtest}"
GITHUB_REGISTRY="ghcr.io"

# Get the tag to publish
TAG="${1:-}"
if [ -z "$TAG" ]; then
    # Try to get tag from git
    TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
    if [ -z "$TAG" ]; then
        echo "Error: No tag provided and not currently on a git tag"
        echo "Usage: bin/publish.sh <tag>"
        exit 1
    fi
fi

echo "=== Publishing Docker Image ==="
echo "Image: $IMAGE_NAME"
echo "Tag: $TAG"
echo "Docker Hub: $DOCKER_HUB_REPO"
echo "GitHub Registry: $GITHUB_REGISTRY/$GITHUB_REPO"
echo ""

# Verify we're logged in (skip check in CI environments)
if [ -z "$CI" ]; then
    echo "Checking Docker Hub login..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        echo "Error: Not logged in to Docker Hub"
        echo "Please run: docker login"
        exit 1
    fi
fi

# Build the image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:$TAG" .
docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:latest"

# Tag for Docker Hub
echo "Tagging for Docker Hub..."
docker tag "$IMAGE_NAME:$TAG" "$DOCKER_HUB_REPO:$TAG"
docker tag "$IMAGE_NAME:latest" "$DOCKER_HUB_REPO:latest"

# Tag for GitHub Container Registry
echo "Tagging for GitHub Container Registry..."
docker tag "$IMAGE_NAME:$TAG" "$GITHUB_REGISTRY/$GITHUB_REPO:$TAG"
docker tag "$IMAGE_NAME:latest" "$GITHUB_REGISTRY/$GITHUB_REPO:latest"

# Push to Docker Hub
echo ""
echo "Pushing to Docker Hub..."
docker push "$DOCKER_HUB_REPO:$TAG"
docker push "$DOCKER_HUB_REPO:latest"

# Push to GitHub Container Registry
echo ""
echo "Pushing to GitHub Container Registry..."
docker push "$GITHUB_REGISTRY/$GITHUB_REPO:$TAG"
docker push "$GITHUB_REGISTRY/$GITHUB_REPO:latest"

echo ""
echo "=== Publishing Complete ==="
echo "Published tags:"
echo "  - $DOCKER_HUB_REPO:$TAG"
echo "  - $DOCKER_HUB_REPO:latest"
echo "  - $GITHUB_REGISTRY/$GITHUB_REPO:$TAG"
echo "  - $GITHUB_REGISTRY/$GITHUB_REPO:latest"
