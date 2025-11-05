# GG LMS Quick Update Guide

This guide explains how to quickly update your GG LMS deployment by pulling the latest changes from git and rebuilding the application.

## Prerequisites

- Git repositories already cloned and set up
- Node.js and npm already installed
- Dependencies already installed (`node_modules` present)

## Update Scripts

Three update scripts are provided for different environments:

### 1. **Windows PowerShell** (Recommended for Windows)

```powershell
.\update.ps1
```

**Note:** You may need to enable script execution first:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. **Windows Batch File** (Simple)

```cmd
update.bat
```

Double-click the file or run from command prompt.

### 3. **Bash Script** (Linux/Mac/Git Bash)

```bash
./update.sh
```

Make it executable first:
```bash
chmod +x update.sh
```

## What the Scripts Do

1. **Pull Frontend Changes** - Updates the React frontend code from GitHub
2. **Pull Backend Changes** - Updates the Node.js backend code from GitHub
3. **Rebuild Frontend** - Compiles the React app into production-ready files
4. **Deploy Frontend** - Copies built files to the backend's public directory

## After Running the Update Script

### If Using PM2 (Production)

Restart the server to apply backend changes:
```bash
pm2 restart gg-lms
```

Check status:
```bash
pm2 status
pm2 logs gg-lms
```

### If Running Manually (Development)

1. Stop the current server (press `Ctrl+C`)
2. Navigate to the backend directory:
   ```bash
   cd server_V1.1-main/server_V1.1-main
   ```
3. Start the server again:
   ```bash
   node app.js
   ```

## What the Scripts DON'T Do

These quick update scripts **skip** the following steps (compared to full deployment):

- ❌ Installing new npm dependencies
- ❌ Database migrations
- ❌ Environment variable updates
- ❌ Server restarts

## When to Use Full Deployment Instead

Use the full deployment scripts (`deploy.sh` or `deploy-improved.sh`) when:

- New npm packages were added
- Database schema changed
- Environment variables were modified
- This is the first time deploying
- You encounter errors with the quick update

## Troubleshooting

### "Failed to pull changes"

**Solution:** Commit or stash your local changes first:
```bash
cd leaner_V1.1-main/leaner_V1.1-main
git stash
git pull origin master

cd ../../server_V1.1-main/server_V1.1-main
git stash
git pull origin master
```

### "npm run build failed"

**Solution:** You may need to reinstall dependencies:
```bash
cd leaner_V1.1-main/leaner_V1.1-main
npm install
npm run build
```

### "Module not found" errors after update

**Solution:** New dependencies were added. Install them:
```bash
# Frontend
cd leaner_V1.1-main/leaner_V1.1-main
npm install

# Backend
cd ../../server_V1.1-main/server_V1.1-main
npm install
```

Then restart the server.

## Typical Workflow

1. **Developer pushes changes** to GitHub
2. **Run update script** on the server
3. **Restart the server** (PM2 or manual)
4. **Test the application** to verify updates

## Quick Reference

```bash
# Windows PowerShell
.\update.ps1

# Windows Batch
update.bat

# Linux/Mac/Git Bash
./update.sh

# After update, restart server
pm2 restart gg-lms

# Or manually
cd server_V1.1-main/server_V1.1-main
node app.js
```

## Need Help?

- Check the full deployment guide: `DEPLOYMENT-README.md`
- Review the repository README: `README.md`
- Check server logs: `pm2 logs gg-lms`
