#!/bin/bash

SELF_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ -z "${USERNAME}" ]]; then
    echo "USERNAME env var must be set"
    exit
fi

UPDATE_SERVER_UTILS="${UPDATE_SERVER_UTILS:-true}"
UPDATE_PORTAINER="${UPDATE_PORTAINER:-true}"
PRUNE_DOCKER="${PRUNE_DOCKER:-true}"
BACKUP_CRONTAB="${BACKUP_CRONTAB:-true}"
BACKUP_SERVER="${BACKUP_CRONTAB:-true}"

if [[ $UPDATE_SERVER_UTILS ]]; then
    echo "Updating Server Utils"
    su -l $USERNAME -c "cd ~/server-utils && git pull" || true
fi

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
    su -l $USERNAME -c "crontab -l > /home/$USERNAME/backups/crontab.backup" || true
fi

if [[ $BACKUP_SERVER ]]; then
    echo "Backup Server"
    su -l $USERNAME -c "/home/$USERNAME/server-utils/scripts/backup.sh"
fi
