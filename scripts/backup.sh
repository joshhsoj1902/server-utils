#!/bin/bash

BACKUP_DIR="${BACKUP_DIR:-'/media/backups'}"

# https://www.journaldev.com/29456/install-7zip-ubuntu
# apt install p7zip-full p7zip-rar

# Backup crontab
crontab -l > ~/backups/crontab.backup

# Backup fstab
cp -p /etc/fstab ~/backups/fstab.backup


# 7z is used here because it has better support for updating existing archives than tar.
7z u ${BACKUP_DIR}/backup-$(date +%A).7z ~
