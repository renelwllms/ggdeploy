# Nginx Commands and Troubleshooting Guide

## Installation Steps (On Ubuntu Server)

1. **Upload scripts to server:**
   ```bash
   # Transfer setup-nginx.sh and nginx-ssl-setup.sh to your Ubuntu server
   scp setup-nginx.sh nginx-ssl-setup.sh user@your-server:/home/user/
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x setup-nginx.sh nginx-ssl-setup.sh
   ```

3. **Run Nginx installation:**
   ```bash
   sudo ./setup-nginx.sh
   ```

4. **Configure DNS:**
   - Point testportal.thegetgroup.co.nz A record to your server's IP address
   - Wait for DNS propagation (can take up to 24 hours)

5. **Install SSL certificate:**
   ```bash
   sudo ./nginx-ssl-setup.sh
   ```

## Useful Nginx Commands

### Service Management
```bash
# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Restart Nginx
sudo systemctl restart nginx

# Reload configuration (no downtime)
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx

# Enable auto-start on boot
sudo systemctl enable nginx
```

### Configuration Testing
```bash
# Test configuration for syntax errors
sudo nginx -t

# Test and show configuration
sudo nginx -T
```

### Log Viewing
```bash
# View error log (real-time)
sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.error.log

# View access log (real-time)
sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.access.log

# View last 100 lines of error log
sudo tail -n 100 /var/log/nginx/testportal.thegetgroup.co.nz.error.log

# View Nginx main error log
sudo tail -f /var/log/nginx/error.log
```

### Configuration Files
```bash
# Edit site configuration
sudo nano /etc/nginx/sites-available/testportal.thegetgroup.co.nz

# View main Nginx configuration
sudo nano /etc/nginx/nginx.conf

# After editing, always test before reloading
sudo nginx -t && sudo systemctl reload nginx
```

### SSL Certificate Management
```bash
# Renew certificates manually
sudo certbot renew

# Test certificate renewal (dry run)
sudo certbot renew --dry-run

# View certificate information
sudo certbot certificates

# Check auto-renewal timer
sudo systemctl status certbot.timer

# View certificates expiry
sudo certbot certificates
```

## Troubleshooting

### Check if Nginx is running
```bash
sudo systemctl status nginx
ps aux | grep nginx
```

### Check if port 80/443 is open
```bash
sudo netstat -tulpn | grep nginx
# or
sudo ss -tulpn | grep nginx
```

### Check firewall status
```bash
sudo ufw status
# Should show: Nginx Full ALLOW
```

### Test backend connection
```bash
# Test if Node.js app is running on port 5000
curl http://localhost:5000

# Check Node.js process
ps aux | grep node
```

### Check DNS resolution
```bash
# Check if DNS points to correct server
dig testportal.thegetgroup.co.nz
nslookup testportal.thegetgroup.co.nz
```

### Common Issues

**Issue: 502 Bad Gateway**
- Check if Node.js app is running on port 5000
- Check Node.js logs: `pm2 logs` or check your app logs
- Verify backend is listening: `sudo netstat -tulpn | grep 5000`

**Issue: 403 Forbidden**
- Check Nginx user permissions
- Verify file ownership: `ls -la /path/to/app`

**Issue: SSL Certificate Error**
- Ensure DNS is properly configured
- Check certificate expiry: `sudo certbot certificates`
- Renew manually: `sudo certbot renew --force-renewal`

**Issue: Connection Timeout**
- Check firewall: `sudo ufw status`
- Verify ports 80 and 443 are open
- Check if Nginx is running: `sudo systemctl status nginx`

## Performance Tuning (Optional)

Edit `/etc/nginx/nginx.conf` and adjust:

```nginx
# Worker processes (set to number of CPU cores)
worker_processes auto;

# Worker connections
events {
    worker_connections 2048;
}

# Enable gzip compression
http {
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript
               application/x-javascript application/xml+rss
               application/json application/javascript;
}
```

After making changes:
```bash
sudo nginx -t && sudo systemctl reload nginx
```

## Monitoring

### Check Nginx access logs for traffic
```bash
sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.access.log
```

### Check error rate
```bash
sudo grep "error" /var/log/nginx/testportal.thegetgroup.co.nz.error.log | tail -20
```

### Monitor in real-time with GoAccess (optional tool)
```bash
sudo apt install goaccess
sudo goaccess /var/log/nginx/testportal.thegetgroup.co.nz.access.log -o report.html --log-format=COMBINED
```

## Important File Locations

- **Site Config**: `/etc/nginx/sites-available/testportal.thegetgroup.co.nz`
- **Enabled Sites**: `/etc/nginx/sites-enabled/`
- **Main Config**: `/etc/nginx/nginx.conf`
- **Error Log**: `/var/log/nginx/testportal.thegetgroup.co.nz.error.log`
- **Access Log**: `/var/log/nginx/testportal.thegetgroup.co.nz.access.log`
- **SSL Certificates**: `/etc/letsencrypt/live/testportal.thegetgroup.co.nz/`

## Quick Deployment Workflow

After updating your code via `deploy.sh`:

```bash
# 1. Pull latest code and rebuild (using your deploy script)
sudo bash deploy.sh

# 2. Restart PM2 apps
pm2 restart all

# 3. Check PM2 status
pm2 status

# 4. Check Nginx is proxying correctly
curl -I https://testportal.thegetgroup.co.nz

# 5. Monitor logs for any errors
pm2 logs
sudo tail -f /var/log/nginx/testportal.thegetgroup.co.nz.error.log
```
