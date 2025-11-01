#!/bin/bash

echo "Updating server repo..."
cd server || exit
git remote set-url origin https://$GITHUB_TOKEN@github.com/renelwllms/ggserver28102025.git
git reset --hard
git clean -fd
git pull origin master

echo "Updating frontend repo..."
cd ../learners || exit
git remote set-url origin https://$GITHUB_TOKEN@github.com/renelwllms/gglearner28102025.git
git reset --hard
git clean -fd
git pull origin master

npm install
npm run build

echo "Copying frontend build to server/public..."
rm -rf ../server/public/*
cp -r dist/* ../server/public/

echo "Restarting PM2 apps..."
pm2 restart all

echo "✅ Deployment complete."
