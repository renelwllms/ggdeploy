# The Get Group LMS - Deployment Scripts

This repository contains deployment and setup scripts for The Get Group Learner Management System.

## Overview

The Get Group LMS consists of two main components:
- **Frontend (Learner Portal)**: React + TypeScript application
  - Repository: https://github.com/renelwllms/gglearner28102025
- **Backend (API Server)**: Node.js/Express REST API
  - Repository: https://github.com/renelwllms/ggserver28102025

## Scripts

### Main Deployment Scripts

- **`deploy-improved.sh`** - Main deployment script (recommended)
  - Pulls latest code from both repositories
  - Installs dependencies
  - Builds frontend with 4GB memory allocation
  - Deploys to server and restarts with PM2

- **`deploy.sh`** - Simple deployment script
  - Basic deployment without advanced features

### Setup Scripts

- **`server-setup.sh`** - Initial server setup
  - Installs Node.js, npm, PM2, and system dependencies
  - Run this once on a new server

- **`setup-nginx.sh`** - Nginx configuration
  - Sets up reverse proxy for the application

- **`nginx-ssl-setup.sh`** - SSL/HTTPS setup
  - Configures SSL certificates for HTTPS

### Utility Scripts

- **`build-frontend-low-memory.sh`** - Build frontend with lower memory requirements
- **`fix-memory-and-redeploy.sh`** - Fix memory issues and redeploy

## Configuration Files

- **`ecosystem.config.js`** - PM2 process manager configuration
- **`.gitignore`** - Git ignore rules

## Documentation

- **`DEPLOYMENT-README.md`** - Detailed deployment instructions
- **`MEMORY-TROUBLESHOOTING.md`** - Memory issues troubleshooting guide
- **`nginx-commands.md`** - Nginx commands reference
- **`IMPROVEMENTS_IMPLEMENTED.md`** - Implementation history
- **`MICROCREDENTIAL_CUSTOMIZATION_COMPLETE.md`** - Microcredential features
- **`SETTINGS_PAGE_IMPROVEMENT_SUGGESTIONS.md`** - Settings page improvements

## Quick Start

### First Time Setup

1. Clone this repository on your server:
   ```bash
   git clone https://github.com/renelwllms/gg-deployment.git
   cd gg-deployment
   ```

2. Run the server setup (one time only):
   ```bash
   bash server-setup.sh
   ```

3. Set your GitHub token:
   ```bash
   export GITHUB_TOKEN="your_github_personal_access_token"
   ```

4. Run the deployment:
   ```bash
   bash deploy-improved.sh
   ```

### Regular Updates

Simply run:
```bash
export GITHUB_TOKEN="your_token"
bash deploy-improved.sh
```

## Memory Requirements

The build process requires at least 4GB of available memory. The deployment script automatically sets:
- `NODE_OPTIONS="--max-old-space-size=4096"` (4GB allocation)

If you encounter out-of-memory errors:
1. Check available RAM: `free -h`
2. Add swap space if needed (see MEMORY-TROUBLESHOOTING.md)
3. Increase memory limit in deploy-improved.sh

## Support

For issues or questions, contact The Get Group technical team.

## License

Proprietary - The Get Group
