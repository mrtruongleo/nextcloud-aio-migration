#!/bin/bash

# Define main backup directory using an absolute path
BACKUP_DIR="/absolute/path/to/backup" # Replace with the absolute path to your backup directory
IMAGES_BACKUP_DIR="$BACKUP_DIR/images"
VOLUMES_BACKUP_DIR="$BACKUP_DIR/volumes"

# Create backup directories if they don't exist
mkdir -p "$IMAGES_BACKUP_DIR"
mkdir -p "$VOLUMES_BACKUP_DIR"

# Function to backup Docker images
backup_images() {
    echo "Backing up Docker images to $IMAGES_BACKUP_DIR..."
    IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}")

    if [ -z "$IMAGES" ]; then
        echo "No images found to backup."
    else
        for IMAGE in $IMAGES; do
            IMAGE_NAME=$(echo $IMAGE | sed 's/[\/:]/_/g')  # Replace slashes and colons with underscores for filenames
            echo "Saving image $IMAGE to $IMAGES_BACKUP_DIR/${IMAGE_NAME}.tar"
            docker save -o "$IMAGES_BACKUP_DIR/${IMAGE_NAME}.tar" $IMAGE
        done
    fi
}

# Function to backup Docker volumes
backup_volumes() {
    echo "Backing up Docker volumes to $VOLUMES_BACKUP_DIR..."
    VOLUMES=$(docker volume ls --format "{{.Name}}")

    if [ -z "$VOLUMES" ]; then
        echo "No volumes found to backup."
    else
        for VOLUME in $VOLUMES; do
            echo "Backing up volume $VOLUME to $VOLUMES_BACKUP_DIR/${VOLUME}_backup.tar.gz"
            docker run --rm -v $VOLUME:/volume -v "$VOLUMES_BACKUP_DIR":/backup busybox tar czf /backup/${VOLUME}_backup.tar.gz -C /volume .
        done
    fi
}

# Parse command-line options
show_usage() {
    echo "Usage: $0 [--images] [--volumes] [--all]"
    echo "  --images    Backup Docker images only."
    echo "  --volumes   Backup Docker volumes only."
    echo "  --all       Backup both images and volumes (default)."
    exit 1
}

# Default to backing up everything if no options are provided
BACKUP_IMAGES=false
BACKUP_VOLUMES=false

# Check command-line arguments
if [ $# -eq 0 ]; then
    BACKUP_IMAGES=true
    BACKUP_VOLUMES=true
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --images)
                BACKUP_IMAGES=true
                ;;
            --volumes)
                BACKUP_VOLUMES=true
                ;;
            --all)
                BACKUP_IMAGES=true
                BACKUP_VOLUMES=true
                ;;
            *)
                show_usage
                ;;
        esac
        shift
    done
fi

# Perform backups based on chosen options
# uncomment if you need to backup all images too
# if [ "$BACKUP_IMAGES" = true ]; then
#     backup_images
# fi

if [ "$BACKUP_VOLUMES" = true ]; then
    backup_volumes
fi

echo "Backup completed successfully."
