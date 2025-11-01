#!/bin/bash

# SSL Certificate Setup Script for testportal.thegetgroup.co.nz
# Run this AFTER setup-nginx.sh and AFTER DNS is properly configured

set -e

echo "=== SSL Certificate Setup for testportal.thegetgroup.co.nz ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Verify DNS is pointing to this server
echo "Verifying DNS configuration..."
SERVER_IP=$(curl -s ifconfig.me)
DNS_IP=$(dig +short testportal.thegetgroup.co.nz | tail -n1)

echo "Server IP: $SERVER_IP"
echo "DNS points to: $DNS_IP"

if [ "$SERVER_IP" != "$DNS_IP" ]; then
    echo "WARNING: DNS may not be properly configured!"
    echo "Please ensure testportal.thegetgroup.co.nz points to $SERVER_IP"
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Request SSL certificate from Let's Encrypt
echo "Requesting SSL certificate from Let's Encrypt..."
echo "You will be prompted for an email address and to agree to terms of service."
echo ""

certbot --nginx -d testportal.thegetgroup.co.nz

# Set up auto-renewal
echo "Setting up automatic certificate renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

# Test renewal process
echo "Testing certificate renewal..."
certbot renew --dry-run

echo ""
echo "=== SSL Setup Complete ==="
echo ""
echo "Your site should now be accessible at:"
echo "https://testportal.thegetgroup.co.nz"
echo ""
echo "Certificate will auto-renew. To check renewal timer:"
echo "systemctl status certbot.timer"
echo ""
