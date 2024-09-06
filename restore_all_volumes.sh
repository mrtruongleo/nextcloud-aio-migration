#!/bin/sh

# Define main backup directory
BACKUP_DIR="/root/backup"
VOLUMES_BACKUP_DIR="$BACKUP_DIR/volumes"

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

# Function to restore Docker volumes
restore_volumes() {
    echo "Restoring Docker volumes from $VOLUMES_BACKUP_DIR..."
    VOLUME_FILES=$(find "$VOLUMES_BACKUP_DIR" -name "*_backup.tar.gz")

    if [ -z "$VOLUME_FILES" ]; then
        echo "No volume backup files found to restore."
    else
        for VOLUME_BACKUP in $VOLUME_FILES; do
            VOLUME_NAME=$(basename "$VOLUME_BACKUP" | sed 's/_backup.tar.gz//')
            echo "Creating and restoring volume $VOLUME_NAME..."

            # Create the volume
            docker volume create "$VOLUME_NAME"

            # Restore the volume data using pv to show progress
            docker run --rm -v "$VOLUME_NAME":/volume -v "$VOLUMES_BACKUP_DIR":/backup busybox sh -c "pv /backup/$(basename "$VOLUME_BACKUP") | tar xzf - -C /volume"
        done
    fi

    echo "Docker volumes restored successfully."
}

# Check and install pv if necessary
install_pv

# Perform restore of volumes
restore_volumes

# Instructions for recreating containers
echo "
######################################################################
# Containers need to be recreated manually using Docker Compose or   #
# equivalent commands, since specific runtime configurations are not #
# included in the image and volume backups.                         #
######################################################################

# To recreate containers using Docker Compose:
# 1. Ensure the 'docker-compose.yml' or 'compose.yaml' file is present on the new host.
# 2. Adjust any paths if needed to point to the correct volume names.
# 3. Run the following command to recreate and start your services:

docker-compose up -d

# Make sure to verify the services are running correctly and that all
# data has been restored properly.
"

