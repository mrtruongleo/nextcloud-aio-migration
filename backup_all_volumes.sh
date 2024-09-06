#!/bin/sh

# Define main backup directory using an absolute path
BACKUP_DIR="/root/nextcloud-backup" # Replace with the absolute path to your backup directory
VOLUMES_BACKUP_DIR="$BACKUP_DIR/volumes"

# Create backup directory if it doesn't exist
mkdir -p "$VOLUMES_BACKUP_DIR"

# List of volumes to backup (space-separated)
VOLUMES_TO_BACKUP="nextcloud_aio_nextcloud nextcloud_aio_database nextcloud_aio_database_dump nextcloud_aio_redis nextcloud_aio_apache"

# Function to check if pv is installed, and install it if not
install_pv() {
    if ! command -v pv > /dev/null 2>&1; then
        echo "Pipe Viewer (pv) is not installed. Installing..."
        
        # Detect package manager and install pv
        if command -v apt-get > /dev/null 2>&1; then
            apt-get install -y pv
        elif command -v apk > /dev/null 2>&1; then
            apk add --no-cache pv
        elif command -v yum > /dev/null 2>&1; then
            yum install -y pv
        elif command -v dnf > /dev/null 2>&1; then
            dnf install -y pv
        else
            echo "Package manager not found or unsupported. Please install pv manually."
            exit 1
        fi
        
        if ! command -v pv > /dev/null 2>&1; then
            echo "Failed to install pv. Please install it manually."
            exit 1
        fi
        
        echo "pv installed successfully."
    else
        echo "Pipe Viewer (pv) is already installed."
    fi
}

# Function to backup specified Docker volumes
backup_volumes() {
    echo "Backing up specified Docker volumes to $VOLUMES_BACKUP_DIR..."
    
    for VOLUME in $VOLUMES_TO_BACKUP; do
        if docker volume inspect "$VOLUME" > /dev/null 2>&1; then
            echo "Backing up volume $VOLUME to $VOLUMES_BACKUP_DIR/${VOLUME}_backup.tar.gz"
            docker run --rm -v "$VOLUME":/volume busybox tar -cf - -C /volume . | pv | gzip > "$VOLUMES_BACKUP_DIR/${VOLUME}_backup.tar.gz"
        else
            echo "Volume $VOLUME not found, skipping..."
        fi
    done
}

# Check and install pv if necessary
install_pv

# Perform backup of specified volumes
backup_volumes

echo "Backup of specified volumes completed successfully."