# GG LMS Deployment Guide for Ubuntu

This guide explains how to deploy the GG LMS application on a brand new Ubuntu server.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Server Setup](#initial-server-setup)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Managing the Application](#managing-the-application)
6. [Troubleshooting](#troubleshooting)
7. [Updating the Application](#updating-the-application)

---

## Prerequisites

- Ubuntu 20.04 LTS or Ubuntu 22.04 LTS
- Root or sudo access
- GitHub Personal Access Token (for private repositories)
- Database credentials (MS SQL Server)
- Azure AD credentials (Tenant ID, Client ID, Client Secret)

---

## Initial Server Setup

### Step 1: Connect to Your Server

```bash
ssh epladmin@your-server-ip
```

### Step 2: Upload Setup Scripts

Upload the following files to your home directory:
- `server-setup.sh` - One-time server setup script
- `deploy-improved.sh` - Deployment script
- `.env.template` - Environment variables template

You can use `scp` to upload files:

```bash
# From your local machine
scp server-setup.sh epladmin@your-server-ip:~/
scp deploy-improved.sh epladmin@your-server-ip:~/
scp .env.template epladmin@your-server-ip:~/
```

### Step 3: Run the Server Setup Script

This script installs all required dependencies (Node.js, PM2, SQL Server drivers, Chromium, etc.)

**⚠️ Run this ONCE on a brand new server:**

```bash
sudo bash server-setup.sh
```

**What this script does:**
- Updates system packages
- Installs Node.js 18.x LTS
- Installs PM2 process manager
- Installs Git
- Installs SQL Server ODBC driver
- Installs build tools (gcc, python3)
- Installs Chromium (for PDF generation)
- Creates application directories
- Configures firewall (UFW)
- Optionally installs Nginx as reverse proxy
- Creates environment template file

**Duration:** 5-10 minutes depending on server speed

---

## Configuration

### Step 4: Configure Environment Variables

After the setup script completes, configure your environment variables:

```bash
cd ~
cp .env.template .env
nano .env
```

**Fill in your actual values:**

```bash
# GitHub Personal Access Token
GITHUB_TOKEN=ghp_your_actual_github_token_here

# Database Configuration
DB_USER=your_database_username
DB_PASSWORD=your_database_password
DB_SERVER=your_database_server.database.windows.net
DB_DATABASE=your_database_name
DB_PORT=1433

# Azure AD Configuration
AZURE_TENANT_ID=807cd602-32e3-4a35-a30e-2ac56ecf53d6
AZURE_CLIENT_ID=e8d3a4a4-2922-44fa-8487-dc994f065e56
AZURE_CLIENT_SECRET=your_azure_client_secret

# Email Configuration
EMAIL_SENDER=noreply@thegetgroup.co.nz

# Application Configuration
NODE_ENV=production
PORT=5000
```

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

### Step 5: Load Environment Variables

```bash
# Load environment variables into current session
source .env

# Add to .bashrc for persistence
echo "source ~/.env" >> ~/.bashrc
```

**Verify the GITHUB_TOKEN is set:**

```bash
echo $GITHUB_TOKEN
```

You should see your token printed (not empty).

---

## Deployment

### Step 6: Run the Deployment Script

Now you can deploy the application:

```bash
bash deploy-improved.sh
```

**What this script does:**
1. ✅ Pre-flight checks (Node.js, npm, PM2, Git, GITHUB_TOKEN)
2. 📥 Clones/updates server repository from GitHub
3. 📥 Clones/updates frontend repository from GitHub
4. 📦 Installs backend dependencies (`npm install`)
5. 📦 Installs frontend dependencies (`npm install`)
6. 🏗️ Builds frontend application (`npm run build`)
7. 📋 Copies frontend build to `server/public/`
8. ⚙️ Creates PM2 ecosystem configuration
9. 🔄 Starts/restarts application with PM2
10. ✅ Performs health check

**Duration:** 3-5 minutes depending on internet speed

### Expected Output

You should see output like this:

```
============================================
Pre-flight Checks
============================================
✅ Node.js found: v18.x.x
✅ npm found: 9.x.x
✅ PM2 found: 5.x.x
✅ Git found: 2.x.x
✅ GITHUB_TOKEN is set
✅ Pre-flight checks passed

============================================
Updating Server Repository
============================================
ℹ️  Resetting local changes...
ℹ️  Pulling latest changes...
✅ Server repository updated

... (more output) ...

============================================
✅ Deployment Complete!
============================================

✅ Server repository: 9488eb5
✅ Frontend repository: 9dcc4b9

ℹ️  Application is running on: http://localhost:5000
ℹ️  Public URL: http://your-server-ip
```

---

## Managing the Application

### View Application Status

```bash
pm2 status
```

### View Real-time Logs

```bash
pm2 logs gg-lms-server
```

### View Last 100 Log Lines

```bash
pm2 logs gg-lms-server --lines 100
```

### Monitor CPU and Memory Usage

```bash
pm2 monit
```

### Restart Application

```bash
pm2 restart gg-lms-server
```

### Stop Application

```bash
pm2 stop gg-lms-server
```

### Start Application

```bash
pm2 start gg-lms-server
```

### View Application Details

```bash
pm2 describe gg-lms-server
```

---

## Troubleshooting

### Issue: "npm: command not found"

**Solution:** Run the server setup script first:
```bash
sudo bash server-setup.sh
```

### Issue: "pm2: command not found"

**Solution:** Run the server setup script first or install PM2 manually:
```bash
sudo npm install -g pm2
```

### Issue: "GITHUB_TOKEN is not set"

**Solution:** Set the environment variable:
```bash
export GITHUB_TOKEN='your_token_here'
echo 'export GITHUB_TOKEN="your_token_here"' >> ~/.bashrc
```

### Issue: "cp: cannot stat 'dist/*': No such file or directory"

**Cause:** Frontend build failed

**Solution:** Check the build logs:
```bash
cd ~/learners
npm run build
```

Look for errors in the build output.

### Issue: Application won't start

**Check logs:**
```bash
pm2 logs gg-lms-server --lines 50
```

**Common causes:**
- Database connection failure (check DB credentials in `.env`)
- Missing environment variables
- Port 5000 already in use

**Check database connection:**
```bash
cd ~/server
node -e "require('./routes/utils.js')"
```

### Issue: "Cannot connect to database"

**Solution:** Verify database credentials:
```bash
cat ~/.env | grep DB_
```

Test database connection:
```bash
# Install sqlcmd if not already installed
sudo apt-get install mssql-tools18

# Test connection
/opt/mssql-tools18/bin/sqlcmd -S your_server -U your_user -P your_password -d your_database
```

### Issue: Port 5000 in use

**Find process using port 5000:**
```bash
sudo lsof -i :5000
```

**Kill the process:**
```bash
sudo kill -9 <PID>
```

### View System Logs

```bash
# PM2 logs
pm2 logs

# Application logs
tail -f ~/logs/*.log

# System logs
sudo journalctl -u nginx  # if using Nginx
```

---

## Updating the Application

### Update to Latest Code

Simply re-run the deployment script:

```bash
bash deploy-improved.sh
```

This will:
- Pull latest code from GitHub
- Rebuild frontend
- Restart application

### Update Dependencies

If `package.json` has changed:

```bash
cd ~/server
npm install

cd ~/learners
npm install

pm2 restart gg-lms-server
```

### Database Schema Updates

If database schema has changed, run migration scripts:

```bash
cd ~/server/database

# Apply indexes
sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -d $DB_DATABASE -i add-indexes.sql

# Apply microcredential migration
sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -d $DB_DATABASE -i add-microcredential-fields.sql
```

---

## Server Maintenance

### Automatic Updates with Cron

Create a cron job to automatically deploy updates:

```bash
crontab -e
```

Add this line to deploy every day at 2 AM:

```
0 2 * * * cd /home/epladmin && bash deploy-improved.sh >> /home/epladmin/logs/deploy.log 2>&1
```

### Monitor Disk Space

```bash
df -h
```

### Clean Old Logs

PM2 logs can grow large. Rotate them:

```bash
pm2 flush  # Clear all logs
```

Or set up automatic log rotation in `ecosystem.config.js`:

```javascript
log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
max_size: '10M',
retain: 7,  // Keep 7 days of logs
```

### Backup Database

```bash
# Create backup directory
mkdir -p ~/backups

# Backup database
sqlcmd -S $DB_SERVER -U $DB_USER -P $DB_PASSWORD -Q "BACKUP DATABASE [$DB_DATABASE] TO DISK='/path/to/backup.bak'"
```

---

## Security Best Practices

### 1. Keep System Updated

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### 2. Configure Firewall

The setup script configures UFW. Verify:

```bash
sudo ufw status
```

### 3. Use SSL/TLS (HTTPS)

Install Certbot for Let's Encrypt SSL:

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx
```

### 4. Restrict SSH Access

Edit SSH config:

```bash
sudo nano /etc/ssh/sshd_config
```

Change:
```
PermitRootLogin no
PasswordAuthentication no  # Use SSH keys only
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

### 5. Monitor Application

Set up monitoring with PM2 Plus (optional):

```bash
pm2 link <secret_key> <public_key>
```

---

## Nginx Configuration (Optional)

If you installed Nginx during setup, configure it as a reverse proxy:

### Basic Configuration

File: `/etc/nginx/sites-available/gg-lms`

```nginx
server {
    listen 80;
    server_name portal.thegetgroup.co.nz;

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
    }
}
```

### Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/gg-lms /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Deploy application | `bash deploy-improved.sh` |
| View status | `pm2 status` |
| View logs | `pm2 logs gg-lms-server` |
| Restart app | `pm2 restart gg-lms-server` |
| Stop app | `pm2 stop gg-lms-server` |
| Start app | `pm2 start gg-lms-server` |
| Monitor app | `pm2 monit` |
| View disk space | `df -h` |
| Check firewall | `sudo ufw status` |
| Test database | `sqlcmd -S $DB_SERVER -U $DB_USER` |

---

## Support

For issues or questions:

- **Email:** support@edgepoint.co.nz
- **Documentation:** Check the `CLAUDE.md` file in the repository
- **Logs:** Always check `pm2 logs` first

---

## Appendix: Manual Installation (Without Scripts)

If you prefer to install dependencies manually:

### Install Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install PM2

```bash
sudo npm install -g pm2
```

### Install SQL Server ODBC

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev
```

### Install Chromium

```bash
sudo apt-get install -y chromium-browser libnss3 libatk-bridge2.0-0
```

Then follow the deployment steps manually.

---

**Last Updated:** January 2025
**Version:** 1.0
