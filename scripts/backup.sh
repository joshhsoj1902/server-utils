#!/bin/bash

BACKUP_DIR="${BACKUP_DIR:-/media/backups}"

# https://www.journaldev.com/29456/install-7zip-ubuntu
# apt install p7zip-full p7zip-rar

mkdir -p ~/backups
# Backup crontab
crontab -l > ~/backups/crontab.backup
# Backup fstab
cp -p /etc/fstab ~/backups/fstab.backup

opts=""
if [ -n "$1" ]
then
    #-p allows for a password to be set
    opts=$opts" -p${1}"
fi

7z $opts u ${BACKUP_DIR}/backup-$(date +%A).7z ~

#Update weekly backup on Mondays
if [[ $(date +%w) == 1 ]]; then
    7z $opts u ${BACKUP_DIR}/backup-Weekly.7z ~
fi

#Update monthly
if [[ $(date +%d) == 1 ]]; then
    7z $opts u ${BACKUP_DIR}/backup-Monthly.7z ~
fi
