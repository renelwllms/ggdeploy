#!/bin/bash

# ============================================================================
# Server Setup Script for GG LMS - Ubuntu
# ============================================================================
# This script installs all required dependencies for the GG LMS application
# Run this ONCE on a brand new Ubuntu server before deployment
#
# Usage: sudo bash server-setup.sh
# ============================================================================

set -e  # Exit on any error

echo "============================================"
echo "GG LMS Server Setup Script"
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo "❌ Error: This script must be run with sudo"
   echo "Usage: sudo bash server-setup.sh"
   exit 1
fi

# Get the actual user who ran sudo (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
echo "📋 Setting up server for user: $ACTUAL_USER"
echo ""

# ============================================================================
# 1. Update System Packages
# ============================================================================
echo "📦 Step 1: Updating system packages..."
apt-get update
apt-get upgrade -y
echo "✅ System packages updated"
echo ""

# ============================================================================
# 2. Install Node.js 18.x LTS
# ============================================================================
echo "📦 Step 2: Installing Node.js 18.x LTS..."

# Remove old Node.js versions if they exist
apt-get remove -y nodejs npm 2>/dev/null || true

# Install Node.js 18.x from NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Verify installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo "✅ Node.js installed: $NODE_VERSION"
echo "✅ npm installed: $NPM_VERSION"
echo ""

# ============================================================================
# 3. Install PM2 Process Manager
# ============================================================================
echo "📦 Step 3: Installing PM2 process manager..."
npm install -g pm2

# Configure PM2 to start on system boot
pm2 startup systemd -u "$ACTUAL_USER" --hp "/home/$ACTUAL_USER"

# Save PM2 configuration
runuser -u "$ACTUAL_USER" -- pm2 save

echo "✅ PM2 installed and configured"
echo ""

# ============================================================================
# 4. Install Git (if not already installed)
# ============================================================================
echo "📦 Step 4: Checking Git installation..."
if ! command -v git &> /dev/null; then
    apt-get install -y git
    echo "✅ Git installed"
else
    GIT_VERSION=$(git --version)
    echo "✅ Git already installed: $GIT_VERSION"
fi
echo ""

# ============================================================================
# 5. Install SQL Server ODBC Driver (for MS SQL Server)
# ============================================================================
echo "📦 Step 5: Installing SQL Server ODBC Driver..."

# Add Microsoft repository
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Update package list
apt-get update

# Install ODBC driver and tools
ACCEPT_EULA=Y apt-get install -y msodbcsql18
ACCEPT_EULA=Y apt-get install -y mssql-tools18

# Add mssql-tools to PATH
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /home/$ACTUAL_USER/.bashrc

# Install unixODBC development headers
apt-get install -y unixodbc-dev

echo "✅ SQL Server ODBC Driver installed"
echo ""

# ============================================================================
# 6. Install Build Tools (for native npm modules)
# ============================================================================
echo "📦 Step 6: Installing build tools..."
apt-get install -y build-essential python3

echo "✅ Build tools installed"
echo ""

# ============================================================================
# 7. Install Chromium (for Puppeteer/PDF generation)
# ============================================================================
echo "📦 Step 7: Installing Chromium for PDF generation..."
apt-get install -y chromium-browser

# Install required dependencies for Chromium
apt-get install -y \
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2

echo "✅ Chromium and dependencies installed"
echo ""

# ============================================================================
# 8. Create Application Directories
# ============================================================================
echo "📁 Step 8: Creating application directories..."

# Create directories as the actual user (not root)
runuser -u "$ACTUAL_USER" -- mkdir -p /home/$ACTUAL_USER/server
runuser -u "$ACTUAL_USER" -- mkdir -p /home/$ACTUAL_USER/learners
runuser -u "$ACTUAL_USER" -- mkdir -p /home/$ACTUAL_USER/logs

echo "✅ Application directories created"
echo ""

# ============================================================================
# 9. Configure Firewall (UFW)
# ============================================================================
echo "🔥 Step 9: Configuring firewall..."

# Install UFW if not installed
apt-get install -y ufw

# Allow SSH (important!)
ufw allow ssh
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow Node.js app port (5000)
ufw allow 5000/tcp

# Enable firewall
echo "y" | ufw enable

ufw status

echo "✅ Firewall configured"
echo ""

# ============================================================================
# 10. Install Nginx (optional - as reverse proxy)
# ============================================================================
read -p "📦 Do you want to install Nginx as a reverse proxy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt-get install -y nginx

    # Create basic Nginx configuration
    cat > /etc/nginx/sites-available/gg-lms << 'EOF'
server {
    listen 80;
    server_name _;

    # Frontend static files and API proxy
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Increase timeouts for long-running requests
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/gg-lms /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    # Test configuration
    nginx -t

    # Restart Nginx
    systemctl restart nginx
    systemctl enable nginx

    echo "✅ Nginx installed and configured"
else
    echo "⏭️  Skipping Nginx installation"
fi
echo ""

# ============================================================================
# 11. Set up Environment Variables Template
# ============================================================================
echo "📝 Step 11: Creating environment template..."

cat > /home/$ACTUAL_USER/.env.template << 'EOF'
# ============================================================================
# GG LMS Environment Variables Template
# ============================================================================
# Copy this file to .env and fill in your actual values
# Usage: cp .env.template .env && nano .env
# ============================================================================

# GitHub Personal Access Token (for git pull)
GITHUB_TOKEN=your_github_token_here

# Database Configuration
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_SERVER=your_database_server
DB_DATABASE=your_database_name
DB_PORT=1433

# Azure AD Configuration
AZURE_TENANT_ID=your_azure_tenant_id
AZURE_CLIENT_ID=your_azure_client_id
AZURE_CLIENT_SECRET=your_azure_client_secret

# Email Configuration
EMAIL_SENDER=noreply@yourdomain.com

# Application Configuration
NODE_ENV=production
PORT=5000
EOF

chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.env.template

echo "✅ Environment template created at: /home/$ACTUAL_USER/.env.template"
echo ""

# ============================================================================
# Setup Complete
# ============================================================================
echo "============================================"
echo "✅ Server Setup Complete!"
echo "============================================"
echo ""
echo "Next Steps:"
echo ""
echo "1. Configure environment variables:"
echo "   cd /home/$ACTUAL_USER"
echo "   cp .env.template .env"
echo "   nano .env"
echo ""
echo "2. Set your GITHUB_TOKEN:"
echo "   export GITHUB_TOKEN='your_token_here'"
echo "   echo 'export GITHUB_TOKEN=\"your_token_here\"' >> ~/.bashrc"
echo ""
echo "3. Run the deployment script:"
echo "   bash deploy.sh"
echo ""
echo "4. Check PM2 status:"
echo "   pm2 status"
echo "   pm2 logs"
echo ""
echo "5. Monitor logs:"
echo "   pm2 logs --lines 100"
echo ""
echo "Installed versions:"
echo "  - Node.js: $(node --version)"
echo "  - npm: $(npm --version)"
echo "  - PM2: $(pm2 --version)"
echo "  - Git: $(git --version)"
echo ""
echo "============================================"
