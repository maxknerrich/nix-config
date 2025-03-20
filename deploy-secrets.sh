#!/usr/bin/env bash
set -euo pipefail

# Define paths
LOCAL_SECRETS_DIR="$HOME/Projects/02-Personal/infrastructure/secrets"
TARGET_HOST="titan.local.knerrich.tech"
TARGET_USER="mkn"
REMOTE_SECRETS_DIR="/var/lib/agenix-secrets"

# Ensure local secrets exist
if [ ! -d "$LOCAL_SECRETS_DIR" ]; then
  echo "Error: Local secrets directory not found at $LOCAL_SECRETS_DIR"
  exit 1
fi

# Create temporary directory on remote
echo "Creating temporary directory on remote..."
ssh "$TARGET_USER@$TARGET_HOST" "mkdir -p /tmp/secrets-temp"

# Copy secrets to the target machine
echo "Copying secrets to $TARGET_HOST..."
scp -r "$LOCAL_SECRETS_DIR/"* "$TARGET_USER@$TARGET_HOST:/tmp/secrets-temp/"

# Move secrets to the secure location (requires sudo)
echo "Moving secrets to secure location..."
ssh "$TARGET_USER@$TARGET_HOST" "\
  sudo mkdir -p $REMOTE_SECRETS_DIR && \
  sudo cp /tmp/secrets-temp/* $REMOTE_SECRETS_DIR/ && \
  sudo chown -R root:root $REMOTE_SECRETS_DIR && \
  sudo find $REMOTE_SECRETS_DIR -type f -exec chmod 600 {} \; && \
  rm -rf /tmp/secrets-temp \
"

echo "Secrets deployed successfully!"
