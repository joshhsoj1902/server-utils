#!/bin/bash

# https://www.journaldev.com/29456/install-7zip-ubuntu
# apt install p7zip-full p7zip-rar

CONFIG_FILE="${CONFIG_FILE:-~/.backup/settings.cfg}"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Reading Config_File $CONFIG_FILE"
    source $CONFIG_FILE
fi

BACKUP_DIR="${BACKUP_DIR:-/media/backups}"
BACKUP_SRC="${BACKUP_SRC:-~}"
BACKUP_TOOL="${BACKUP_TOOL:-7z}"


BACKUP_DOW="${BACKUP_DOW:-true}"
BACKUP_DAILY="${BACKUP_DAILY:-true}"
BACKUP_WEEKLY="${BACKUP_WEEKLY:-false}"
BACKUP_MONTHLY="${BACKUP_MONTHLY:-false}"

7z_backup () {
    opts=""

    if [ -n "$BACKUP_PASSWORD" ]
    then
        #-p allows for a password to be set
        opts=$opts" -p${BACKUP_PASSWORD}"
    fi
    7z $opts u $1 $2
}

do_backup () {
    case $BACKUP_TOOL in

    "7z")
        7z_backup $@
        ;;

    *)
        echo "$BACKUP_TOOL Not supported"
        ;;
    esac
}

mkdir -p ~/backups
# Backup crontab
crontab -l > ~/backups/crontab.backup
# Backup fstab
cp -p /etc/fstab ~/backups/fstab.backup

if $BACKUP_DOW; then
    do_backup ${BACKUP_DIR}/backup-$(date +%A).7z ${BACKUP_SRC}
fi

if $BACKUP_DAILY; then
    do_backup ${BACKUP_DIR}/backup-Daily.7z ${BACKUP_SRC}
fi

#Update weekly backup on Mondays
if $BACKUP_WEEKLY; then
    if [[ $(date +%w) == 1 ]]; then
        do_backup ${BACKUP_DIR}/backup-Weekly.7z ${BACKUP_SRC}
    fi
fi

#Update monthly
if $BACKUP_MONTHLY; then
    if [[ $(date +%d) == 1 ]]; then
        do_backup ${BACKUP_DIR}/backup-Monthly.7z ${BACKUP_SRC}
    fi
fi
