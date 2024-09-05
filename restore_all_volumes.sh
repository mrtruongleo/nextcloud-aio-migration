#!/bin/bash

# Define main backup directory
BACKUP_DIR="/path/to/backup"
IMAGES_BACKUP_DIR="$BACKUP_DIR/images"
VOLUMES_BACKUP_DIR="$BACKUP_DIR/volumes"

# Restore Docker images
# uncomment if you need to restore all images.
# echo "Restoring Docker images from $IMAGES_BACKUP_DIR..."
# IMAGE_FILES=$(find $IMAGES_BACKUP_DIR -name "*.tar")

# if [ -z "$IMAGE_FILES" ]; then
#     echo "No image tar files found to restore."
# else
#     for IMAGE in $IMAGE_FILES; do
#         echo "Loading image from $IMAGE..."
#         docker load -i $IMAGE
#     done
# fi

# Restore Docker volumes
echo "Restoring Docker volumes from $VOLUMES_BACKUP_DIR..."
VOLUME_FILES=$(find $VOLUMES_BACKUP_DIR -name "*_backup.tar.gz")

if [ -z "$VOLUME_FILES" ]; then
    echo "No volume backup files found to restore."
else
    for VOLUME_BACKUP in $VOLUME_FILES; do
        VOLUME_NAME=$(basename $VOLUME_BACKUP | sed 's/_backup.tar.gz//')
        echo "Creating and restoring volume $VOLUME_NAME..."

        # Create the volume
        docker volume create $VOLUME_NAME

        # Restore the volume data
        docker run --rm -v $VOLUME_NAME:/volume -v $VOLUMES_BACKUP_DIR:/backup busybox tar xzf /backup/$(basename $VOLUME_BACKUP) -C /volume
    done
fi

echo "Docker images and volumes restored successfully."

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
