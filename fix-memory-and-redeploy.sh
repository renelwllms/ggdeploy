#!/bin/bash

# ============================================================================
# Quick Fix Script for Memory Issues + Redeploy
# ============================================================================
# This script fixes the memory issue and redeploys the application
# Usage: bash fix-memory-and-redeploy.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Memory Fix + Redeploy Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check available memory
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo -e "${BLUE}ℹ️  Total system memory: ${TOTAL_MEM}MB${NC}"

if [ "$TOTAL_MEM" -lt 1024 ]; then
    echo -e "${YELLOW}⚠️  Warning: Less than 1GB RAM available. Build may be slow.${NC}"
    MEMORY_LIMIT=768
elif [ "$TOTAL_MEM" -lt 2048 ]; then
    echo -e "${YELLOW}ℹ️  1-2GB RAM detected. Setting conservative memory limit.${NC}"
    MEMORY_LIMIT=1024
else
    echo -e "${GREEN}✅ Sufficient RAM detected. Setting optimal memory limit.${NC}"
    MEMORY_LIMIT=2048
fi

echo -e "${BLUE}ℹ️  Node.js memory limit will be set to: ${MEMORY_LIMIT}MB${NC}"
echo ""

# Set Node.js memory limit globally
export NODE_OPTIONS="--max-old-space-size=$MEMORY_LIMIT"

# Add to current user's bashrc for persistence
if ! grep -q "NODE_OPTIONS" ~/.bashrc; then
    echo "export NODE_OPTIONS=\"--max-old-space-size=$MEMORY_LIMIT\"" >> ~/.bashrc
    echo -e "${GREEN}✅ NODE_OPTIONS added to ~/.bashrc${NC}"
else
    echo -e "${BLUE}ℹ️  NODE_OPTIONS already in ~/.bashrc${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Cleaning npm cache and node_modules${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Clean frontend
if [ -d "learners" ]; then
    cd learners
    echo -e "${BLUE}ℹ️  Cleaning frontend cache...${NC}"
    npm cache clean --force 2>/dev/null || true
    rm -rf node_modules 2>/dev/null || true
    rm -rf dist 2>/dev/null || true
    rm -rf .vite 2>/dev/null || true
    cd ..
    echo -e "${GREEN}✅ Frontend cleaned${NC}"
fi

# Clean backend
if [ -d "server" ]; then
    cd server
    echo -e "${BLUE}ℹ️  Cleaning backend cache...${NC}"
    npm cache clean --force 2>/dev/null || true
    rm -rf node_modules 2>/dev/null || true
    cd ..
    echo -e "${GREEN}✅ Backend cleaned${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Running Deployment Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if deploy-improved.sh exists
if [ -f "deploy-improved.sh" ]; then
    bash deploy-improved.sh
elif [ -f "deploy.sh" ]; then
    echo -e "${YELLOW}⚠️  Using original deploy.sh (no memory optimizations)${NC}"
    bash deploy.sh
else
    echo -e "${RED}❌ No deployment script found!${NC}"
    echo -e "${BLUE}ℹ️  Please download deploy-improved.sh and run it manually.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Fix Applied and Deployment Complete${NC}"
echo -e "${GREEN}============================================${NC}"
