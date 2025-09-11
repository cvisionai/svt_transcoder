#!/bin/bash

# Setup Docker buildx for multiarch builds
# This script creates a new buildx builder that supports both amd64 and arm64

set -e

BUILDER_NAME="tator-multiarch"

# Check if builder already exists
if docker buildx ls | grep -q "$BUILDER_NAME"; then
    echo "Builder '$BUILDER_NAME' already exists, using it..."
    docker buildx use "$BUILDER_NAME"
else
    echo "Creating new buildx builder '$BUILDER_NAME'..."
    docker buildx create --name "$BUILDER_NAME" --platform linux/amd64,linux/arm64 --use
fi

# Bootstrap the builder
echo "Bootstrapping builder..."
docker buildx inspect --bootstrap

echo "Builder setup complete. Current builder:"
docker buildx ls | grep "\*"

echo ""
echo "To build multiarch images, run:"
echo "  make svt-image-multiarch"
echo ""
echo "Note: The multiarch target will push images directly to the registry."
echo "Make sure you're logged in to your Docker registry first."