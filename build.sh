#!/bin/bash

# Build script for turnshek.com submodule apps
# This script pulls, builds, and deploys all submodule applications

set -e  # Exit on error

echo "================================================"
echo "Building turnshek.com applications"
echo "================================================"
echo ""

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the root directory
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$ROOT_DIR"

# Function to build an app
build_app() {
    local app_name=$1
    local source_dir="source/$app_name"
    local deploy_dir="$app_name"

    echo -e "${BLUE}Building $app_name...${NC}"

    # Check if source exists
    if [ ! -d "$source_dir" ]; then
        echo -e "${YELLOW}Warning: $source_dir does not exist, skipping${NC}"
        return
    fi

    # Pull latest from git
    echo "  → Pulling latest from git..."
    cd "$source_dir"
    git pull
    cd "$ROOT_DIR"

    # Install dependencies
    echo "  → Installing dependencies..."
    cd "$source_dir"

    # Use pnpm if pnpm-lock.yaml exists, otherwise use npm
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm install
    else
        npm install
    fi

    # Build
    echo "  → Building..."
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm run build
    else
        npm run build
    fi

    # Copy to deployment directory
    echo "  → Copying to $deploy_dir/..."
    cd "$ROOT_DIR"
    mkdir -p "$deploy_dir"

    # Copy index.html
    cp "$source_dir/dist/index.html" "$deploy_dir/index.html"

    # Copy data directory if it exists
    if [ -d "$source_dir/dist/data" ]; then
        echo "  → Copying data directory..."
        cp -r "$source_dir/dist/data" "$deploy_dir/"
    fi

    # Copy any other assets if they exist
    if [ -d "$source_dir/dist/assets" ]; then
        echo "  → Copying assets directory..."
        cp -r "$source_dir/dist/assets" "$deploy_dir/"
    fi

    echo -e "${GREEN}✓ $app_name built successfully${NC}"
    echo ""
}

# Build all apps
build_app "light-pollution"
build_app "shadowbands"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}All apps built successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git status"
echo "  2. Commit the updated apps: git add light-pollution/ && git commit -m 'Update light-pollution app'"
echo "  3. Deploy to GitHub Pages: git push"
