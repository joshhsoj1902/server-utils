#!/bin/bash

SELF_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SELF_DIR/backup_util.sh

backup_gameserver () {
  game_backup_dir=${BACKUP_GAME_DIR}/$1_$2
  source_folder_name="lgsm_$1_$2"
  mkdir -p $game_backup_dir

  # All gameservers take a full backup every week and month.
  # These are full backups with no files being excluded.

  #Update weekly backup on Mondays
  if $BACKUP_WEEKLY; then
      if [[ $(date +%w) == 1 ]]; then
          7z_backup $game_backup_dir/complete-backup-Weekly.7z $3
      fi
  fi

  #Update monthly
  if $BACKUP_MONTHLY; then
      if [[ $(date +%d) == 1 ]]; then
          7z_backup $game_backup_dir/complete-backup-Monthly.7z $3
      fi
  fi

  opts=""
  opts=$(add_7z_exclude "$opts" "$source_folder_name/.bash_history")
  opts=$(add_7z_exclude "$opts" "$source_folder_name/.steam/")
  opts=$(add_7z_exclude "$opts" "$source_folder_name/.local/share/Steam/")
  opts=$(add_7z_exclude "$opts" "$source_folder_name/.npm")
  opts=$(add_7z_exclude "$opts" "$source_folder_name/log")
  opts=$(add_7z_exclude "$opts" "$source_folder_name/config-lgsm/")

  case $1 in
    "pz")
       opts=$(add_7z_exclude "$opts" "*/serverfiles")
       opts=$(add_7z_exclude "$opts" "$source_folder_name/Zomboid/Logs")
      ;;
    "sf")
       opts=$(add_7z_exclude "$opts" "*/serverfiles")
      ;;
    "7dtd")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/7DaysToDieServer_Data")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/Data")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/Logos")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/Licenses")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/steamclient.so")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/UnityPlayer.so")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/7DaysToDieServer.x86_64")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/mono_crash.mem*")
       opts=$(add_7z_exclude "$opts" "*/serverfiles/libstdc++.so.6")
      ;;
    "mc")
       opts=$(add_7z_exclude "$opts" "$source_folder_name/data/serverfiles/logs")
      ;;
    *)
      echo "Nothing special to do for $1"
      ;;
  esac

  BACKUP_NAME="slim-backup"
  BACKUP_FILETYPE=".7z"
  # MONTHLY_BACKUP_DAY Is the day of the month to make the backup
  MONTHLY_BACKUP_DAY="01"
  DAILY_BACKUP_RESET_DAY="Monday"

  MONTHLY_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME"-Monthly"$BACKUP_FILETYPE
  DAILY_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME"-Daily"$BACKUP_FILETYPE

  FILES_CHANGED_COUNT=$(find $3 -type f -mtime -1 | wc -l)

  ## Monthly Backup
  if [[ "$(date +%d)" == $MONTHLY_BACKUP_DAY ]]; then
    echo "[Monthly] Starting Backup"
    7z_backup /tmp/$MONTHLY_BACKUP_NAME $3 "$opts"

    OLD_FILESIZE=$(stat -c%s "$MONTHLY_BACKUP_NAME")
    NEW_FILESIZE=$(stat -c%s "/tmp$MONTHLY_BACKUP_NAME")

    if [[ "$OLD_FILESIZE" != "$NEW_FILESIZE" ]]; then
      echo "[Monthly] Moving old monthly backup"
      mv $MONTHLY_BACKUP_NAME $game_backup_dir/$BACKUP_NAME-$(date -r $MONTHLY_BACKUP_NAME +%B)$(date -r $MONTHLY_BACKUP_NAME +"%Y")$BACKUP_FILETYPE
      echo "[Monthly] Moving new monthly backup into position"
      mv /tmp/$MONTHLY_BACKUP_NAME $MONTHLY_BACKUP_NAME
    else
      echo "[Monthly] Backup size hasn't changed. Skipping upload"
      rm /tmp/$MONTHLY_BACKUP_NAME
    fi

    echo "[Monthly] Backup done"
  else
    echo "[Monthly] Today ($(date +%d)) is not $MONTHLY_BACKUP_DAY. Skipping Monthly backup"
  fi

  # Remove previously DOW
  rm $game_backup_dir/$BACKUP_NAME-$(date +%A)$BACKUP_FILETYPE
  if [[ "$FILES_CHANGED_COUNT" -gt "0" ]]; then
    ## Daily Backup
    echo "[Daily] $FILES_CHANGED_COUNT Files have changed in the last day, doing daily backup"
    echo "[Daily] Starting pre-Backup tasks"

    # If the current Daily backup was updated in the last 7 days, copy it as a DOW backup
    if [[ "$(find $DAILY_BACKUP_NAME -type f -mtime -7 | wc -l)" -gt "0" ]]; then
      echo "[Daily] Creating DOW backup"
      cp $DAILY_BACKUP_NAME $game_backup_dir/$BACKUP_NAME-$(date -r $DAILY_BACKUP_NAME +%A)$BACKUP_FILETYPE
    fi

    if [[ "$(date +%A)" == $DAILY_BACKUP_RESET_DAY ]]; then
      # Reset backup on Monday
      echo "[Daily] Resetting backup"
      rm $DAILY_BACKUP_NAME
      echo "[Daily] Using monthly backup as the base"
      cp -p $MONTHLY_BACKUP_NAME $DAILY_BACKUP_NAME
    fi
    7z_backup $DAILY_BACKUP_NAME $3 "$opts"
    echo "[Daily] Backup done"
  else
    echo "[Daily] No files have changed in the last 24 hours. Skipping daily backup"
  fi
}

echo ""
echo "###############################"
echo "# Starting Gameserver Backups #"
echo "###############################"
echo ""

for dir in $BACKUP_GAME_SRC/*/
do
    dir=${dir%*/}
    folder_name=${dir##*/}

    OLDIFS="$IFS"
    IFS='_' read -r -a tokens <<< "$folder_name"
    IFS="$OLDIFS" # restore IFS
    if [[ "${tokens[0]}" != "lgsm" ]]; then
      echo "Skipping non-lgsm folder (${dir##*/})"
      continue
    fi

    #Rebuild gamename in cases where the name includes _ (like a21_feb2024)
    gamename=""
    for i in $(seq 2 ${#tokens[@]});
    do
      if [[ "${tokens[$i]}" != "" ]]; then
        if [[ "$gamename" == "" ]]; then
          gamename="${tokens[$i]}"
        else
          gamename="${gamename}_${tokens[$i]}"
        fi
      fi
    done

    # echo "Found LGSM gameserver of type ${tokens[1]} called $gamename"

    echo ""
    echo "###################################"
    echo "## Starting backup for $gamename"
    echo "## Gametype is ${tokens[1]}"
    echo ""
    backup_gameserver ${tokens[1]} $gamename $dir
    echo ""
    echo "## Finished backup for $gamename"
    echo "###################################"
    echo ""
done

echo ""
echo "###############################"
echo "# Finished Gameserver Backups #"
echo "###############################"
echo ""