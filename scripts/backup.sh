#!/bin/bash

# https://www.journaldev.com/29456/install-7zip-ubuntu
# apt install p7zip-full p7zip-rar
readonly SELF_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SELF_DIR/backup_util.sh

CONFIG_FILE="${CONFIG_FILE:-$HOME/.backup/settings.cfg}"
CONFIG_OVERRIDE_FILE="${CONFIG_OVERRIDE_FILE:-$HOME/.backup/settings_override.cfg}"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "Reading Config_File $CONFIG_FILE"
    source $CONFIG_FILE
fi
if [[ -f "$CONFIG_OVERRIDE_FILE" ]]; then
    echo "Reading Config_Override_File $CONFIG_OVERRIDE_FILE"
    source $CONFIG_OVERRIDE_FILE
fi

BACKUP_DIR="${BACKUP_DIR:-/media/backups}"
BACKUP_SRC="${BACKUP_SRC:-$HOME}"
BACKUP_GAME_DIR="${BACKUP_GAME_DIR:-/media/game-backups}"
BACKUP_GAME_SRC="${BACKUP_GAME_SRC:-~/docker}"

BACKUP_TOOL="${BACKUP_TOOL:-7z}"
BACKUP_CRONTAB_TO="${BACKUP_CRONTAB_TO:-$BACKUP_SRC/backups}"
BACKUP_FSTAB_TO="${BACKUP_FSTAB_TO:-$BACKUP_SRC/backups}"

BACKUP_GAME_SERVERS="${BACKUP_GAME_SERVERS:-false}"

BACKUP_DOW="${BACKUP_DOW:-true}"
BACKUP_DAILY="${BACKUP_DAILY:-true}"
BACKUP_WEEKLY="${BACKUP_WEEKLY:-false}"
BACKUP_MONTHLY="${BACKUP_MONTHLY:-false}"

mkdir -p $BACKUP_CRONTAB_TO
# Backup crontab
crontab -l > $BACKUP_CRONTAB_TO/crontab.backup
# Backup fstab
cp -p /etc/fstab $BACKUP_CRONTAB_TO/fstab.backup

opts=""
if $BACKUP_GAME_SERVERS; then
    # TODO: this really should be dynamic
    opts=$(add_7z_exclude "$opts" "*docker/lgsm*")
fi

if $BACKUP_DOW; then
    do_backup ${BACKUP_DIR}/backup-$(date +%A).7z ${BACKUP_SRC} "$opts"
fi

if $BACKUP_DAILY; then
    do_backup ${BACKUP_DIR}/backup-Daily.7z ${BACKUP_SRC} "$opts"
fi

#Update weekly backup on Mondays
if $BACKUP_WEEKLY; then
    if [[ $(date +%w) == 1 ]]; then
        do_backup ${BACKUP_DIR}/backup-Weekly.7z ${BACKUP_SRC} "$opts"
    fi
fi

#Update monthly
if $BACKUP_MONTHLY; then
    if [[ $(date +%d) == 1 ]]; then
        do_backup ${BACKUP_DIR}/backup-Monthly.7z ${BACKUP_SRC} "$opts"
    fi
fi

if $BACKUP_GAME_SERVERS; then
  source $SELF_DIR/backup_gameservers.sh
fi