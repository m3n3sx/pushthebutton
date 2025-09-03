#!/bin/bash

# Fedora System Backup Tool - Post-install script
# This script is run after the application is installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Fedora System Backup Tool - Post-install script${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
sudo mkdir -p /var/backup/fedora
sudo mkdir -p /var/lib/fedora-backup
sudo mkdir -p /var/log
sudo mkdir -p /etc/fedora_backup

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R root:root /var/backup/fedora
sudo chown -R root:root /var/lib/fedora-backup
sudo chmod 755 /var/backup/fedora
sudo chmod 755 /var/lib/fedora-backup

# Create log file
echo -e "${YELLOW}Creating log file...${NC}"
sudo touch /var/log/fedora_backup.log
sudo chmod 644 /var/log/fedora_backup.log

# Create default configuration
echo -e "${YELLOW}Creating default configuration...${NC}"
sudo tee /etc/fedora_backup/config.json > /dev/null << 'EOF'
{
  "backup_base_path": "/var/backup/fedora",
  "log_file": "/var/log/fedora_backup.log",
  "default_backup_name": "fedora_backup",
  "compression": true,
  "encryption": false,
  "retention_days": 30
}
EOF

# Create cloud configuration template
echo -e "${YELLOW}Creating cloud configuration template...${NC}"
sudo tee /etc/fedora_backup/cloud_config.json > /dev/null << 'EOF'
{
  "nextcloud": {
    "enabled": false,
    "url": "",
    "username": "",
    "password": "",
    "remote_path": "/FedoraBackups"
  },
  "google_drive": {
    "enabled": false,
    "client_id": "",
    "client_secret": "",
    "credentials_file": "",
    "folder_id": ""
  },
  "dropbox": {
    "enabled": false,
    "access_token": "",
    "remote_path": "/FedoraBackups"
  }
}
EOF

# Create scheduler configuration
echo -e "${YELLOW}Creating scheduler configuration...${NC}"
sudo tee /etc/fedora_backup/scheduler_config.json > /dev/null << 'EOF'
{
  "enabled": false,
  "method": "systemd",
  "frequency": "daily",
  "time": "02:00",
  "retention_days": 30
}
EOF

# Set permissions for configuration files
sudo chmod 644 /etc/fedora_backup/*.json

# Reload systemd if available
if command -v systemctl >/dev/null 2>&1; then
    echo -e "${YELLOW}Reloading systemd...${NC}"
    sudo systemctl daemon-reload
fi

# Enable and start timer if systemd is available
if command -v systemctl >/dev/null 2>&1; then
    echo -e "${YELLOW}Enabling systemd timer...${NC}"
    sudo systemctl enable fedora-backup.timer
    sudo systemctl start fedora-backup.timer
fi

echo -e "${GREEN}Post-install script completed successfully!${NC}"
echo -e "${BLUE}The Fedora System Backup Tool is now ready to use.${NC}"
echo -e "${YELLOW}You can run it with: fedora-backup-tool${NC}"
