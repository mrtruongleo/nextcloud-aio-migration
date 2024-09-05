# Nextcloud Server Migration Guide

### Overview

This guide outlines the process to migrate a Nextcloud server from an old server to a new one. The migration involves putting Nextcloud into maintenance mode, backing up and restoring Docker volumes, and ensuring that the configuration is correctly replicated on the new server.

#### Current Setup

- Old Server: A Raspberry Pi 5 (arm64) running Proxmox on top of Raspbian OS, with Nextcloud installed in an LXC container using an Ubuntu template.
- New Server: A PC (amd64/x86_64) with Proxmox and will have Nextcloud running in an LXC container using a Debian Bookworm template.

Although the old and new servers have different architectures and operating systems, the migration is straightforward due to the similar setup of the Nextcloud installation on both servers.

- Installation Method: I use a manual installation method with a Docker Compose file, rather than an all-in-one master container. This allows for separate configuration of each container. This approach is based on the official manual guide here. I use a latest.yml file and copy the content of sample.conf to the .env file, then adjust the TODO fields.
- The use of this method on both servers simplifies the migration process.

### 0. Preparing

- Install docker and docker compose in new server

  ```
  curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
  ```

### 1. Put Nextcloud into Maintenance Mode

On the old server, put Nextcloud into maintenance mode to prevent any changes during the migration:

```
docker exec -it nextcloud-aio-nextcloud sudo -u www-data php occ maintenance:mode --on
```

### 2. Backup Docker Volumes

On the old server, back up all Docker volumes related to Nextcloud. You can use a backup script to simplify this process. Ensure you have the backup script available in your repository.

```sh
# Example command to back up volumes (adjust paths and volume names as needed)
docker run --rm -v <volume_name>:/volume -v /path/to/backup:/backup busybox tar czf /backup/<volume_name>_backup.tar.gz -C /volume .
```

### 3. Transfer Backup to New Server

Copy the backup folder from the old server to the new server. You can use scp or another file transfer method:

```sh
scp -r /path/to/backup.tar.gz user@new-server-ip:/path/to/new/backup.tar.gz
```

### 4. Restore Docker Volumes on the New Server

On the new server, restore the Docker volumes from the backup. You can use a restore script available in your repository:

```sh
# Example command to restore volumes (adjust paths and volume names as needed)
docker run --rm -v <volume_name>:/volume -v /path/to/backup:/backup busybox sh -c "tar xzf /backup/<volume_name>_backup.tar.gz -C /volume"
```

### 5. Update Docker Compose Configuration

Ensure that the docker-compose.yml file on the new server is configured to use the restored volumes. Add the external: true flag to the volumes section to avoid re-creating volumes:

```yaml
volumes:
  nextcloud_aio_nextcloud:
    external: true
  nextcloud_aio_apache:
    external: true
  nextcloud_aio_redis:
    external: true
  nextcloud_aio_database:
    external: true
  nextcloud_aio_database_dump:
    external: true
```

### 6. Mount User Data

If user data was mounted on the old server (e.g., /mnt/userdata), ensure the same path is mounted on the new server and that it contains the same data.

### 7. Start the New Server

Start the Docker containers on the new server:

```sh
docker-compose up -d
```

### 8. Disable Maintenance Mode

Once the containers are up and running, disable maintenance mode:

```sh
docker exec -it nextcloud-aio-nextcloud sudo -u www-data php occ maintenance:mode --off
```

### 9. Verify the Migration

Access your Nextcloud instance on the new server and verify that everything is functioning correctly. Ensure that all data is present and that services are running as expected.

## Additional Notes

- Backup and Restore Scripts: You can find the backup and restore volume scripts in this repository. Ensure you make the scripts executable with chmod +x <script> before running them.
- Configuration Files: Verify that all configuration files (e.g., .env, docker-compose.yml) on the new server match those of the old server, with appropriate adjustments for paths and environment-specific settings.

## Troubleshooting

- Volume Already Exists: If you encounter warnings about volumes already existing, ensure that the volumes are correctly marked as external in docker-compose.yml.
- Data Inconsistencies: Double-check that all data has been correctly restored and that the volumes contain the expected data.

By following these steps, you should be able to migrate your Nextcloud server to a new machine while retaining all your data and configuration settings.
