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

# Function to validate build output
validate_build() {
    local app_name=$1
    local source_dir="source/$app_name"
    local dist_file="$source_dir/dist/index.html"

    echo "  → Validating build..."

    # Check if dist/index.html exists
    if [ ! -f "$dist_file" ]; then
        echo -e "${YELLOW}✗ Validation failed: $dist_file not found${NC}"
        return 1
    fi

    # Check file size (should be between 50KB and 500KB for a reasonable build)
    local file_size=$(stat -f%z "$dist_file" 2>/dev/null || stat -c%s "$dist_file" 2>/dev/null)
    if [ "$file_size" -lt 51200 ]; then
        echo -e "${YELLOW}✗ Validation failed: $dist_file too small ($file_size bytes)${NC}"
        return 1
    fi
    if [ "$file_size" -gt 524288 ]; then
        echo -e "${YELLOW}✗ Validation failed: $dist_file too large ($file_size bytes)${NC}"
        return 1
    fi

    # Check for critical content based on app
    case "$app_name" in
        "light-pollution")
            if ! grep -q "Pittsburgh Light Pollution" "$dist_file"; then
                echo -e "${YELLOW}✗ Validation failed: Missing expected title${NC}"
                return 1
            fi
            if ! grep -q "leaflet" "$dist_file"; then
                echo -e "${YELLOW}✗ Validation failed: Missing Leaflet library${NC}"
                return 1
            fi
            ;;
        "shadowbands")
            if ! grep -q "Shadowband" "$dist_file"; then
                echo -e "${YELLOW}✗ Validation failed: Missing expected title${NC}"
                return 1
            fi
            ;;
    esac

    # Check for common build errors
    if grep -q "vite:error" "$dist_file"; then
        echo -e "${YELLOW}✗ Validation failed: Build errors found in output${NC}"
        return 1
    fi

    echo -e "${GREEN}  ✓ Build validated (${file_size} bytes)${NC}"
    return 0
}

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

    # Validate build
    cd "$ROOT_DIR"
    if ! validate_build "$app_name"; then
        echo -e "${YELLOW}Build validation failed for $app_name${NC}"
        return 1
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
