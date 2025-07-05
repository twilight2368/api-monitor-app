#!/bin/bash

# === CONFIGURATION ===
SERVER_IP="123.12.12.12"                 # Your server's IP
USER="root"                              # SSH user
REMOTE_DIR="/root/api-monitor-deploy"   # Remote deploy folder
COMPOSE_FILE="docker-compose.prod.yml"  # Use your prod compose file

# === Step 1: Create remote dir if not exists ===
echo "📂 Ensuring remote directory exists..."
ssh $USER@$SERVER_IP "mkdir -p $REMOTE_DIR"

# === Step 2: Rsync project (exclude dev envs, node_modules, cache) ===
echo "🚚 Copying code to $USER@$SERVER_IP:$REMOTE_DIR ..."
rsync -av --progress \
  --exclude='.env.development' \
  --exclude='.env' \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  docker-compose.yml \
  docker-compose.prod.yml \
  api-status-monitor \
  api-status-monitor-server \
  $USER@$SERVER_IP:$REMOTE_DIR

# === Step 3: Copy only production .env files ===
echo "🔐 Copying production .env files..."
scp \
  api-status-monitor/.env.production \
  api-status-monitor-server/service_monitor/.env \
  $USER@$SERVER_IP:$REMOTE_DIR

# === Step 4: SSH in and run docker-compose ===
echo "🐳 Starting Docker containers on remote..."
ssh $USER@$SERVER_IP "cd $REMOTE_DIR && docker compose -f $COMPOSE_FILE up -d --build"

echo "✅ Deployment complete!"
