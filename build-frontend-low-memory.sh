#!/bin/bash

# ============================================================================
# Low Memory Frontend Build Script
# ============================================================================
# Use this script if the standard build fails due to memory issues
# This script uses aggressive optimization for low-memory environments
#
# Usage: bash build-frontend-low-memory.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Low Memory Frontend Build${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d "learners" ]; then
    echo -e "${RED}❌ Error: 'learners' directory not found${NC}"
    echo -e "${BLUE}ℹ️  Please run this script from the deployment directory${NC}"
    exit 1
fi

cd learners

# Get system memory
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo -e "${BLUE}ℹ️  System memory: ${TOTAL_MEM}MB${NC}"

# Calculate optimal memory limit (use 70% of available RAM)
MEMORY_LIMIT=$((TOTAL_MEM * 70 / 100))

# Minimum 512MB, maximum 4096MB
if [ "$MEMORY_LIMIT" -lt 512 ]; then
    MEMORY_LIMIT=512
elif [ "$MEMORY_LIMIT" -gt 4096 ]; then
    MEMORY_LIMIT=4096
fi

echo -e "${BLUE}ℹ️  Node.js memory limit: ${MEMORY_LIMIT}MB${NC}"
echo ""

# Set environment variables for build optimization
export NODE_OPTIONS="--max-old-space-size=$MEMORY_LIMIT"
export NODE_ENV=production

# Disable source maps to save memory
export GENERATE_SOURCEMAP=false

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules not found. Installing dependencies...${NC}"
    npm install --production=false
fi

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Starting Build Process${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Clean previous build
echo -e "${BLUE}ℹ️  Cleaning previous build...${NC}"
rm -rf dist
rm -rf .vite

# Run build with progress monitoring
echo -e "${BLUE}ℹ️  Building application (this may take 2-5 minutes)...${NC}"
echo ""

# Create a temporary file to capture build output
BUILD_LOG=$(mktemp)

# Run build in background with output to log
npm run build > "$BUILD_LOG" 2>&1 &
BUILD_PID=$!

# Show spinner while building
SPIN='-\|/'
i=0
while kill -0 $BUILD_PID 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${BLUE}Building... ${SPIN:$i:1}${NC}"
    sleep 0.5
done

# Wait for process to complete
wait $BUILD_PID
BUILD_EXIT_CODE=$?

echo ""

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    # Check if dist directory was created
    if [ -d "dist" ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"

        # Show build size
        DIST_SIZE=$(du -sh dist | cut -f1)
        echo -e "${BLUE}ℹ️  Build size: ${DIST_SIZE}${NC}"

        # Show file count
        FILE_COUNT=$(find dist -type f | wc -l)
        echo -e "${BLUE}ℹ️  Files generated: ${FILE_COUNT}${NC}"

        echo ""
        echo -e "${GREEN}✅ Frontend build complete!${NC}"
        echo -e "${BLUE}ℹ️  Output directory: $(pwd)/dist${NC}"

        # Clean up log file
        rm -f "$BUILD_LOG"

        exit 0
    else
        echo -e "${RED}❌ Build failed - dist directory not created${NC}"
        echo -e "${YELLOW}Build output:${NC}"
        cat "$BUILD_LOG"
        rm -f "$BUILD_LOG"
        exit 1
    fi
else
    echo -e "${RED}❌ Build failed with exit code: $BUILD_EXIT_CODE${NC}"
    echo ""
    echo -e "${YELLOW}Last 50 lines of build output:${NC}"
    tail -n 50 "$BUILD_LOG"
    rm -f "$BUILD_LOG"

    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo -e "  1. Check available memory: ${BLUE}free -h${NC}"
    echo -e "  2. Close other applications to free up memory"
    echo -e "  3. Try running: ${BLUE}npm cache clean --force${NC}"
    echo -e "  4. Delete node_modules and reinstall: ${BLUE}rm -rf node_modules && npm install${NC}"
    echo -e "  5. Consider upgrading server RAM to at least 2GB"

    exit 1
fi
