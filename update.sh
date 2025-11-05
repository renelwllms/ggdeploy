#!/bin/bash

# GG LMS Quick Update Script
# This script pulls the latest changes from git and rebuilds the application
# WITHOUT doing full setup (no npm install, no server restart)

set -e  # Exit on any error

echo "=================================="
echo "GG LMS Quick Update Script"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

FRONTEND_DIR="$SCRIPT_DIR/leaner_V1.1-main/leaner_V1.1-main"
BACKEND_DIR="$SCRIPT_DIR/server_V1.1-main/server_V1.1-main"

echo -e "${BLUE}Step 1: Pulling latest frontend changes...${NC}"
cd "$FRONTEND_DIR"
git pull origin master
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend updated successfully${NC}"
else
    echo -e "${RED}✗ Failed to pull frontend changes${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 2: Pulling latest backend changes...${NC}"
cd "$BACKEND_DIR"
git pull origin master
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend updated successfully${NC}"
else
    echo -e "${RED}✗ Failed to pull backend changes${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 3: Rebuilding frontend...${NC}"
cd "$FRONTEND_DIR"
npm run build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build frontend${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 4: Deploying frontend to backend...${NC}"
cd "$BACKEND_DIR"
rm -rf public/*
cp -r "$FRONTEND_DIR/dist/"* public/
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend deployed successfully${NC}"
else
    echo -e "${RED}✗ Failed to deploy frontend${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}=================================="
echo "✓ Update completed successfully!"
echo "==================================${NC}"
echo ""
echo -e "${YELLOW}Note: You may need to restart the server for backend changes to take effect:${NC}"
echo "  pm2 restart gg-lms"
echo ""
echo -e "${YELLOW}Or if running manually:${NC}"
echo "  1. Stop the current server (Ctrl+C)"
echo "  2. cd $BACKEND_DIR"
echo "  3. node app.js"
echo ""
