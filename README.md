# server-utils

A collection of uitls I use on my servers

## Example crontab

```crontab
0 12 * * * ~/server-utils/scripts/start-portainer.sh
0 2 * * * cd ~/server-utils && git pull
0 3 * * * ~/server-utils/scripts/backup.sh
0 1 * * * ~/server-utils/scripts/image_prune.sh
```

```crontab
0 3 * * * ~/server-utils/scripts/backup.sh > "$HOME/log/backup-$(date +\%Y-\%m-\%d_\%H:\%M).log" 2>&1
```

## Example fstab

```fstab
${REMOTE_SERVER_IP}:${REMOTE_SERVER_PATH} /media/backups/ nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```

## TODO

- Add https://github.com/seamusdemora/RonR-RPi-image-utils as a sub module
- Look at restructuring server folder structure to not use home dirs Look at https://whimsical.com/fhs-L6iL5t8kBtCFzAQywZyP4X
- Need to support regular TAR so that nginx-proxy-manager backups work (symlinks usually get messed up)
