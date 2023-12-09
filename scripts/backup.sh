#!/bin/bash

BACKUP_DIR="${BACKUP_DIR:-/media/backups}"

# https://www.journaldev.com/29456/install-7zip-ubuntu
# apt install p7zip-full p7zip-rar

mkdir -p ~/backups
# Backup crontab
crontab -l > ~/backups/crontab.backup
# Backup fstab
cp -p /etc/fstab ~/backups/fstab.backup


# 7z is used here because it has better support for updating existing archives than tar.
if [ -z "$1" ]
then
    7z u ${BACKUP_DIR}/backup-$(date +%A).7z ~
else
    #-p allows for a password to be set
    7z -p"$1" u ${BACKUP_DIR}/backup-$(date +%A).7z ~
fi
