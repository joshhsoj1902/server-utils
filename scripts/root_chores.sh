#!/bin/bash

SELF_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ -z "${USERNAME}" ]]; then
    echo "USERNAME env var must be set"
    exit
fi

UPDATE_PORTAINER="${UPDATE_PORTAINER:-true}"
PRUNE_DOCKER="${PRUNE_DOCKER:-true}"
BACKUP_CRONTAB="${BACKUP_CRONTAB:-true}"
BACKUP_SERVER="${BACKUP_CRONTAB:-true}"

if [[ $UPDATE_PORTAINER ]]; then
    echo "Updating Portainer"
    /bin/bash $SELF_DIR/start-portainer.sh
fi

if [[ $PRUNE_DOCKER ]]; then
    echo "Pruning Docker Images"
    /bin/bash $SELF_DIR/image_prune.sh
fi

if [[ $BACKUP_CRONTAB ]]; then
    echo "Backup Crontabs"
    crontab -l > /home/$USERNAME/backups/root-crontab.backup
    su -l $USERNAME -c 'crontab -l > /home/$USERNAME/backups/crontab.backup' || true
fi


# 0 12 * * * /home/jellyfin/server-utils/scripts/start-portainer.sh
# 30 12 * * * crontab -l > /home/jellyfin/backups/root-crontab.backup
# 0 23 * * * docker start immich-josh-import-1
# 0 1 * * * /home/jellyfin/server-utils/scripts/backup.sh
