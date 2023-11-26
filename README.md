# server-utils

A collection of uitls I use on my servers

## Example crontab

```crontab
0 3 * * * ~/server-utils/scripts/backup.sh
```

## Example fstab

```fstab
${REMOTE_SERVER_IP}:${REMOTE_SERVER_PATH} /media/backups/ nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```
