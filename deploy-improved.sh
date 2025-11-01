#!/bin/bash

# ============================================================================
# GG LMS Deployment Script (Improved)
# ============================================================================
# This script pulls the latest code and deploys the application
# Run this script whenever you want to update the application
#
# Prerequisites:
#   - Run server-setup.sh first (one time only)
#   - Set GITHUB_TOKEN environment variable
#   - Configure .env file with database credentials
#
# Usage: bash deploy-improved.sh
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo "============================================"
    echo -e "${BLUE}$1${NC}"
    echo "============================================"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

print_header "Pre-flight Checks"

# Check if running in the correct directory
if [ ! -f "deploy.sh" ] && [ ! -f "deploy-improved.sh" ]; then
    print_error "Not in the correct directory. Please cd to the deployment directory."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please run server-setup.sh first."
    exit 1
fi
print_success "Node.js found: $(node --version)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please run server-setup.sh first."
    exit 1
fi
print_success "npm found: $(npm --version)"

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    print_error "PM2 is not installed. Please run server-setup.sh first."
    exit 1
fi
print_success "PM2 found: $(pm2 --version)"

# Check if Git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please run server-setup.sh first."
    exit 1
fi
print_success "Git found: $(git --version)"

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    print_warning "GITHUB_TOKEN environment variable is not set."
    print_info "Attempting to pull without authentication (may fail for private repos)."
    GITHUB_URL_PREFIX=""
else
    print_success "GITHUB_TOKEN is set"
    GITHUB_URL_PREFIX="https://$GITHUB_TOKEN@"
fi

print_success "Pre-flight checks passed"

# ============================================================================
# Update Server Repository
# ============================================================================

print_header "Updating Server Repository"

# Check if server directory exists
if [ ! -d "server" ]; then
    print_info "Server directory not found. Cloning repository..."
    git clone ${GITHUB_URL_PREFIX}github.com/renelwllms/ggserver28102025.git server
    print_success "Server repository cloned"
else
    cd server || exit 1

    # Set remote URL (with or without token)
    if [ -n "$GITHUB_TOKEN" ]; then
        git remote set-url origin ${GITHUB_URL_PREFIX}github.com/renelwllms/ggserver28102025.git
    fi

    print_info "Resetting local changes..."
    git reset --hard
    git clean -fd

    print_info "Pulling latest changes..."
    git pull origin master

    cd ..
    print_success "Server repository updated"
fi

# ============================================================================
# Update Frontend Repository
# ============================================================================

print_header "Updating Frontend Repository"

# Check if learners directory exists
if [ ! -d "learners" ]; then
    print_info "Learners directory not found. Cloning repository..."
    git clone ${GITHUB_URL_PREFIX}github.com/renelwllms/gglearner28102025.git learners
    print_success "Learners repository cloned"
else
    cd learners || exit 1

    # Set remote URL (with or without token)
    if [ -n "$GITHUB_TOKEN" ]; then
        git remote set-url origin ${GITHUB_URL_PREFIX}github.com/renelwllms/gglearner28102025.git
    fi

    print_info "Resetting local changes..."
    git reset --hard
    git clean -fd

    print_info "Pulling latest changes..."
    git pull origin master

    cd ..
    print_success "Learners repository updated"
fi

# ============================================================================
# Install Frontend Dependencies
# ============================================================================

print_header "Installing Frontend Dependencies"

cd learners || exit 1

print_info "Running npm install..."

# Set memory limit for npm install as well (4GB)
export NODE_OPTIONS="--max-old-space-size=4096"

npm install

print_success "Frontend dependencies installed"

# ============================================================================
# Build Frontend Application
# ============================================================================

print_header "Building Frontend Application"

print_info "Running npm run build with increased memory limit..."

# Increase Node.js memory limit for build (especially for Vite/esbuild) - 4GB
export NODE_OPTIONS="--max-old-space-size=4096"

npm run build

# Check if build was successful
if [ ! -d "dist" ]; then
    print_error "Build failed - dist directory not found"
    exit 1
fi

print_success "Frontend build completed"

cd ..

# ============================================================================
# Install Backend Dependencies
# ============================================================================

print_header "Installing Backend Dependencies"

cd server || exit 1

print_info "Running npm install..."
npm install

# Set Puppeteer to skip Chromium download (we installed system Chromium)
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

print_success "Backend dependencies installed"

cd ..

# ============================================================================
# Deploy Frontend Build to Server
# ============================================================================

print_header "Deploying Frontend to Server"

print_info "Cleaning old frontend files..."
rm -rf server/public/*

print_info "Copying new frontend build..."
cp -r learners/dist/* server/public/

# Verify deployment
if [ ! -f "server/public/index.html" ]; then
    print_error "Frontend deployment failed - index.html not found in server/public"
    exit 1
fi

print_success "Frontend deployed to server/public"

# ============================================================================
# Configure PM2 Application
# ============================================================================

print_header "Configuring PM2 Application"

cd server || exit 1

# Check if PM2 ecosystem file exists, if not create one
if [ ! -f "ecosystem.config.js" ]; then
    print_info "Creating PM2 ecosystem configuration..."

    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'gg-lms-server',
    script: './app.js',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      PUPPETEER_SKIP_CHROMIUM_DOWNLOAD: 'true',
      PUPPETEER_EXECUTABLE_PATH: '/usr/bin/chromium-browser'
    },
    error_file: '../logs/err.log',
    out_file: '../logs/out.log',
    log_file: '../logs/combined.log',
    time: true,
    merge_logs: true
  }]
};
EOF

    print_success "PM2 ecosystem configuration created"
fi

cd ..

# ============================================================================
# Restart Application with PM2
# ============================================================================

print_header "Restarting Application"

# Check if app is already running
if pm2 describe gg-lms-server &> /dev/null; then
    print_info "Restarting existing PM2 app..."
    pm2 restart gg-lms-server
else
    print_info "Starting new PM2 app..."
    cd server
    pm2 start ecosystem.config.js
    cd ..
fi

# Save PM2 configuration
pm2 save

print_success "Application restarted"

# ============================================================================
# Health Check
# ============================================================================

print_header "Health Check"

print_info "Waiting for application to start..."
sleep 5

# Check if process is running
if pm2 describe gg-lms-server | grep -q "online"; then
    print_success "Application is running"
else
    print_error "Application failed to start"
    print_info "Check logs with: pm2 logs gg-lms-server"
    exit 1
fi

# Test HTTP endpoint
if command -v curl &> /dev/null; then
    print_info "Testing HTTP endpoint..."
    if curl -f -s -o /dev/null http://localhost:5000; then
        print_success "HTTP endpoint responding"
    else
        print_warning "HTTP endpoint not responding (may still be starting up)"
    fi
fi

# ============================================================================
# Display Status
# ============================================================================

print_header "Deployment Status"

echo ""
pm2 status

echo ""
print_info "View logs with: pm2 logs gg-lms-server"
print_info "Monitor app with: pm2 monit"
print_info "Stop app with: pm2 stop gg-lms-server"
print_info "Restart app with: pm2 restart gg-lms-server"

# ============================================================================
# Deployment Complete
# ============================================================================

print_header "✅ Deployment Complete!"

echo ""
print_success "Server repository: $(cd server && git rev-parse --short HEAD)"
print_success "Frontend repository: $(cd learners && git rev-parse --short HEAD)"
echo ""
print_info "Application is running on: http://localhost:5000"

if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "unknown")
    if [ "$PUBLIC_IP" != "unknown" ]; then
        print_info "Public URL: http://$PUBLIC_IP"
    fi
fi

echo ""
print_header "Deployment Summary"
echo "  - Server code updated: ✅"
echo "  - Frontend code updated: ✅"
echo "  - Dependencies installed: ✅"
echo "  - Frontend built: ✅"
echo "  - Frontend deployed: ✅"
echo "  - Application restarted: ✅"
echo ""
