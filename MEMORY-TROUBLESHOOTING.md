# Memory Troubleshooting Guide - GG LMS Deployment

## The Problem

When running the deployment script, you encountered this error:

```
FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
```

This happens because **Vite's build process requires significant memory** (typically 1-2GB) to bundle the React application, but the Node.js process has a default memory limit of ~512MB.

---

## Quick Fix (Recommended)

### Option 1: Use the Updated Deployment Script

```bash
# Download the updated deploy-improved.sh to your server
# It already includes memory fixes

bash deploy-improved.sh
```

The updated script automatically sets `NODE_OPTIONS="--max-old-space-size=2048"` which increases Node.js memory limit to 2GB.

### Option 2: Use the Fix Script

```bash
bash fix-memory-and-redeploy.sh
```

This script:
- Detects available RAM
- Sets appropriate memory limits
- Cleans caches
- Runs deployment

### Option 3: Manual Fix + Deploy

```bash
# Set Node.js memory limit (2GB)
export NODE_OPTIONS="--max-old-space-size=2048"

# Add to bashrc for persistence
echo 'export NODE_OPTIONS="--max-old-space-size=2048"' >> ~/.bashrc

# Run deployment
bash deploy-improved.sh
```

---

## System Requirements

### Minimum Requirements
- **RAM:** 1GB (build will be slow and may fail intermittently)
- **Swap:** 2GB recommended to prevent out-of-memory errors
- **Disk:** 5GB free space

### Recommended Requirements
- **RAM:** 2GB or more
- **Swap:** 2GB
- **Disk:** 10GB free space
- **CPU:** 2+ cores

### Check Your System

```bash
# Check total RAM
free -h

# Check available disk space
df -h

# Check CPU cores
nproc
```

---

## Solutions by RAM Size

### Less than 1GB RAM

Your server has insufficient RAM for building the frontend. Options:

#### A) Add Swap Space (Recommended)

```bash
# Create 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

#### B) Build Locally and Deploy

Build on your local machine (with more RAM) and deploy only the built files:

```bash
# On your local machine
cd learners
npm install
npm run build

# Upload built files to server
scp -r dist/* user@server:~/server/public/
```

#### C) Upgrade Server RAM

Consider upgrading to at least 2GB RAM.

### 1-2GB RAM

Your server has minimum RAM. Use conservative settings:

```bash
# Set conservative memory limit (1GB)
export NODE_OPTIONS="--max-old-space-size=1024"

# Disable source maps to save memory
export GENERATE_SOURCEMAP=false

# Run build
cd learners
npm run build
```

Or use the low-memory build script:

```bash
bash build-frontend-low-memory.sh
```

### 2GB+ RAM

Your server has sufficient RAM. Standard settings work:

```bash
export NODE_OPTIONS="--max-old-space-size=2048"
bash deploy-improved.sh
```

---

## Detailed Troubleshooting Steps

### Step 1: Check Current Memory Usage

```bash
# View memory usage
free -h

# View running processes by memory
ps aux --sort=-%mem | head -20

# View Node.js processes specifically
ps aux | grep node
```

### Step 2: Kill Memory-Hogging Processes

```bash
# Stop PM2 apps temporarily
pm2 stop all

# Free up memory
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### Step 3: Clean npm Cache and Rebuild

```bash
cd ~/learners

# Clean npm cache
npm cache clean --force

# Remove old build artifacts
rm -rf node_modules
rm -rf dist
rm -rf .vite
rm -rf node_modules/.cache

# Reinstall dependencies
export NODE_OPTIONS="--max-old-space-size=2048"
npm install

# Build with memory limit
npm run build
```

### Step 4: Monitor Memory During Build

Open a second terminal and run:

```bash
# Watch memory in real-time
watch -n 1 free -h

# Or use htop (more detailed)
htop
```

Then run the build in the first terminal.

---

## Alternative Build Strategies

### Strategy 1: Build with Reduced Parallelism

Create a custom build script that limits parallel processing:

```bash
cd learners

# Edit package.json temporarily
# Change: "vite build"
# To: "vite build --no-parallel"

npm run build
```

### Strategy 2: Use Production Install Only

```bash
# Install only production dependencies (smaller footprint)
npm install --production

# Then install dev dependencies needed for build
npm install --no-save vite @vitejs/plugin-react
```

### Strategy 3: Disable Some Optimizations

Create `vite.config.local.ts` with reduced optimizations:

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    // Reduce chunk size
    chunkSizeWarningLimit: 1000,
    // Reduce number of parallel operations
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
    // Disable minification if needed (larger files but less memory)
    minify: false,
    sourcemap: false,
  },
});
```

Then build:
```bash
vite build --config vite.config.local.ts
```

---

## Permanent Solutions

### Solution 1: Add Permanent Swap Space

```bash
# Create 2GB swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstac

# Adjust swappiness (how aggressively to use swap)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Solution 2: Set Node Memory Limit System-Wide

Add to `/etc/environment`:

```bash
echo 'NODE_OPTIONS="--max-old-space-size=2048"' | sudo tee -a /etc/environment
```

Then restart or re-login.

### Solution 3: Build Frontend in CI/CD Pipeline

Use GitHub Actions to build the frontend:

**.github/workflows/build.yml:**

```yaml
name: Build Frontend

on:
  push:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm install
      - run: npm run build
      - uses: actions/upload-artifact@v2
        with:
          name: frontend-dist
          path: dist/
```

Then on your server, just download and extract the artifact.

---

## Verification

After implementing a fix, verify the build works:

```bash
# Check Node memory setting
echo $NODE_OPTIONS

# Should output: --max-old-space-size=2048 (or similar)

# Try building
cd ~/learners
npm run build

# Verify dist was created
ls -lh dist/

# Check size
du -sh dist/
```

Expected output:
```
dist/
├── index.html
├── assets/
│   ├── index-abc123.js
│   ├── index-abc123.css
│   └── ...
└── ...

Total size: ~5-15MB
```

---

## Common Errors and Fixes

### Error: "JavaScript heap out of memory"

**Cause:** Node.js default memory limit is too low

**Fix:**
```bash
export NODE_OPTIONS="--max-old-space-size=2048"
```

### Error: "ENOMEM: not enough memory"

**Cause:** System is completely out of RAM

**Fix:** Add swap space or free up memory:
```bash
pm2 stop all
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

### Error: "ENOSPC: no space left on device"

**Cause:** Disk is full

**Fix:**
```bash
# Check disk usage
df -h

# Clean npm cache
npm cache clean --force

# Clean old logs
pm2 flush

# Remove old builds
rm -rf ~/learners/dist
rm -rf ~/learners/node_modules/.cache
```

### Error: Build hangs at "transforming"

**Cause:** Insufficient memory causing swap thrashing

**Fix:** Add more RAM or use the low-memory build script:
```bash
bash build-frontend-low-memory.sh
```

---

## Performance Tips

### 1. Close Unnecessary Services During Build

```bash
# Stop PM2 apps
pm2 stop all

# Stop Nginx if running
sudo systemctl stop nginx

# Run build
cd ~/learners
npm run build

# Restart services
pm2 start all
sudo systemctl start nginx
```

### 2. Schedule Builds During Low-Traffic Times

```bash
# Create a cron job for 2 AM builds
crontab -e

# Add:
0 2 * * * cd ~/learners && export NODE_OPTIONS="--max-old-space-size=2048" && npm run build
```

### 3. Use a Build Server

Set up a separate build server with more RAM, build there, and deploy the artifacts.

---

## Getting Help

If you're still having issues:

1. **Check memory:** `free -h`
2. **Check logs:** `cat ~/learners/npm-debug.log` (if exists)
3. **Try low-memory script:** `bash build-frontend-low-memory.sh`
4. **Contact support** with:
   - Output of `free -h`
   - Output of `df -h`
   - Full error message
   - Server specifications

---

## Summary of Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `deploy-improved.sh` | Full deployment with memory fixes | Standard deployment |
| `fix-memory-and-redeploy.sh` | Auto-detect RAM and fix memory issues | First-time setup or after memory errors |
| `build-frontend-low-memory.sh` | Build with aggressive memory optimization | Low-RAM servers (<2GB) |

---

**Last Updated:** January 2025
