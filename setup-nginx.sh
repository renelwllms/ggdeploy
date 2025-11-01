#!/bin/bash

# Nginx Setup Script for testportal.thegetgroup.co.nz
# This script installs and configures Nginx as a reverse proxy for the Get Group Learner Portal

set -e

echo "=== Starting Nginx Setup for testportal.thegetgroup.co.nz ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Update system packages
echo "Updating system packages..."
apt update
apt upgrade -y

# Install Nginx
echo "Installing Nginx..."
apt install -y nginx

# Install Certbot for SSL (Let's Encrypt)
echo "Installing Certbot for SSL certificates..."
apt install -y certbot python3-certbot-nginx

# Stop Nginx temporarily
systemctl stop nginx

# Create Nginx configuration for testportal.thegetgroup.co.nz
echo "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/testportal.thegetgroup.co.nz <<'EOF'
# HTTP server block - redirects to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name testportal.thegetgroup.co.nz;

    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name testportal.thegetgroup.co.nz;

    # SSL certificate paths (will be configured by Certbot)
    # ssl_certificate /etc/letsencrypt/live/testportal.thegetgroup.co.nz/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/testportal.thegetgroup.co.nz/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Logging
    access_log /var/log/nginx/testportal.thegetgroup.co.nz.access.log;
    error_log /var/log/nginx/testportal.thegetgroup.co.nz.error.log;

    # Client body size (for file uploads)
    client_max_body_size 50M;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # Root location - proxy to Node.js backend
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';

        # Standard proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Disable caching for API requests
        proxy_cache_bypass $http_upgrade;
    }

    # API endpoints - explicitly proxy to backend
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Increase timeouts for API requests
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;

        # Cache static assets
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Create symbolic link to enable the site
echo "Enabling site configuration..."
ln -sf /etc/nginx/sites-available/testportal.thegetgroup.co.nz /etc/nginx/sites-enabled/

# Remove default Nginx site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Removing default Nginx site..."
    rm /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Start Nginx
echo "Starting Nginx..."
systemctl start nginx
systemctl enable nginx

# Configure firewall (if UFW is installed)
if command -v ufw &> /dev/null; then
    echo "Configuring firewall..."
    ufw allow 'Nginx Full'
    ufw allow 'OpenSSH'
    ufw --force enable
fi

echo ""
echo "=== Nginx Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Ensure your Node.js application is running on port 5000"
echo "2. Ensure DNS for testportal.thegetgroup.co.nz points to this server"
echo "3. Run the SSL certificate setup:"
echo "   sudo certbot --nginx -d testportal.thegetgroup.co.nz"
echo ""
echo "To check Nginx status: sudo systemctl status nginx"
echo "To view error logs: sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.error.log"
echo "To view access logs: sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.access.log"
echo ""
