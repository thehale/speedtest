#!/bin/bash
set -e

# Docker Publishing Script
# Pushes images to Docker Hub and/or GitHub Container Registry
# Usage: bin/publish.sh [options] [tag]
# Options:
#   --docker    Publish only to Docker Hub
#   --github    Publish only to GitHub Container Registry
#   (no option) Publish to both registries
#
# If no tag provided, uses the current git tag

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-speedtest}"
DOCKER_HUB_REPO="${DOCKER_HUB_REPO:-thehale/speedtest}"
GITHUB_REPO="${GITHUB_REPO:-thehale/speedtest}"
GITHUB_REGISTRY="ghcr.io"

# Parse arguments
PUBLISH_DOCKER=false
PUBLISH_GITHUB=false
TAG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --docker)
            PUBLISH_DOCKER=true
            shift
            ;;
        --github)
            PUBLISH_GITHUB=true
            shift
            ;;
        --help|-h)
            echo "Usage: bin/publish.sh [options] [tag]"
            echo ""
            echo "Options:"
            echo "  --docker    Publish only to Docker Hub"
            echo "  --github    Publish only to GitHub Container Registry"
            echo "  (no option) Publish to both registries"
            echo ""
            echo "If no tag is provided, uses the current git tag"
            exit 0
            ;;
        *)
            # Assume this is the tag
            TAG="$1"
            shift
            ;;
    esac
done

# If no specific registry selected, publish to both
if [ "$PUBLISH_DOCKER" = false ] && [ "$PUBLISH_GITHUB" = false ]; then
    PUBLISH_DOCKER=true
    PUBLISH_GITHUB=true
fi

# Get the tag to publish
if [ -z "$TAG" ]; then
    # Try to get tag from git
    TAG=$(git describe --tags --exact-match 2>/dev/null || echo "")
    if [ -z "$TAG" ]; then
        echo "Error: No tag provided and not currently on a git tag"
        echo "Usage: bin/publish.sh [options] <tag>"
        exit 1
    fi
fi

echo "=== Publishing Docker Image ==="
echo "Image: $IMAGE_NAME"
echo "Tag: $TAG"
echo ""

# Verify we're logged in (skip check in CI environments)
if [ -z "$CI" ]; then
    echo "Checking Docker login status..."
    if ! docker info 2>/dev/null | grep -q "Username"; then
        echo "Error: Not logged in to Docker"
        echo "Please run: docker login"
        exit 1
    fi
fi

# Build the image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:$TAG" .
docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:latest"

# Function to publish to a registry
# Usage: publish_to_registry <registry> <repo> <tag>
publish_to_registry() {
    local registry="$1"
    local repo="$2"
    local tag="$3"
    
    echo ""
    echo "Publishing to $registry..."
    
    # Tag the image
    docker tag "$IMAGE_NAME:$tag" "$repo:$tag"
    docker tag "$IMAGE_NAME:latest" "$repo:latest"
    
    # Push the images
    docker push "$repo:$tag"
    docker push "$repo:latest"
    
    echo "✓ Published to $registry"
}

# Publish to selected registries
if [ "$PUBLISH_DOCKER" = true ]; then
    publish_to_registry "Docker Hub" "$DOCKER_HUB_REPO" "$TAG"
fi

if [ "$PUBLISH_GITHUB" = true ]; then
    publish_to_registry "GitHub Container Registry" "$GITHUB_REGISTRY/$GITHUB_REPO" "$TAG"
fi

echo ""
echo "=== Publishing Complete ==="
echo "Published tags:"
if [ "$PUBLISH_DOCKER" = true ]; then
    echo "  Docker Hub:"
    echo "    - $DOCKER_HUB_REPO:$TAG"
    echo "    - $DOCKER_HUB_REPO:latest"
fi
if [ "$PUBLISH_GITHUB" = true ]; then
    echo "  GitHub Container Registry:"
    echo "    - $GITHUB_REGISTRY/$GITHUB_REPO:$TAG"
    echo "    - $GITHUB_REGISTRY/$GITHUB_REPO:latest"
fi
