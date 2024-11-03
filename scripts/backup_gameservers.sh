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
    *)
      echo "Nothing special to do for $1"
      ;;
  esac

  BACKUP_NAME="slim-backup"
  BACKUP_FILETYPE=".7z"
  # MONTHLY_BACKUP_DAY Is the day of the month to make the backup
  MONTHLY_BACKUP_DAY="02"
  # WEEKLY_BACKUP_RESET_DAY Is the day of the week to make new backup instead of appending to the previous day.
  WEEKLY_BACKUP_RESET_DAY="Monday"
  DAILY_BACKUP_RESET_DAY="Monday"

  MONTHLY_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME-$(date +%B)$(date +"%Y")$BACKUP_FILETYPE
  DOW_PREVIOUS_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME-$(date -d '1 day' +%A)$BACKUP_FILETYPE
  DOW_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME-$(date +%A)$BACKUP_FILETYPE
  DAILY_BACKUP_NAME=$game_backup_dir/$BACKUP_NAME"-Daily"$BACKUP_FILETYPE

  echo $MONTHLY_BACKUP_NAME
  echo $DOW_PREVIOUS_BACKUP_NAME
  echo $DOW_BACKUP_NAME
  echo $DAILY_BACKUP_NAME


  ## Monthly Backup
  if [[ "$(date +%d)" == $MONTHLY_BACKUP_DAY ]]; then
    echo "[Monthly] Starting Backup"
    7z_backup /tmp/$MONTHLY_BACKUP_NAME $3 "$opts"
    mv /tmp/$MONTHLY_BACKUP_NAME $MONTHLY_BACKUP_NAME
    echo "[Monthly] Backup done"
  fi

  ## Day of the Week Backup
  echo "[DOW] Starting pre-Backup tasks"
  rm $DOW_BACKUP_NAME
  if [[ "$(date +%A)" == $WEEKLY_BACKUP_RESET_DAY ]]; then
    if [ -f $MONTHLY_BACKUP_NAME ]; then
      echo "[DOW] Found Monthly backup, Using as base"
      cp $MONTHLY_BACKUP_NAME $DOW_BACKUP_NAME
    fi
  else
    if [ -f $DOW_PREVIOUS_BACKUP_NAME ]; then
      echo "[DOW] Found Previous DOW backup, Using as base"
      cp -p --verbose $DOW_PREVIOUS_BACKUP_NAME $DOW_BACKUP_NAME
    fi
  fi

  if [ -f $DOW_BACKUP_NAME ]; then
    # If the DOW file exists we're adding to an existing archive
    7z_backup $DOW_BACKUP_NAME $3 "$opts"
  else
    # If the DOW file DOES NOT EXIST build new archive locally before moving
    7z_backup /tmp/$DOW_BACKUP_NAME $3 "$opts"
    mv /tmp/$DOW_BACKUP_NAME $DOW_BACKUP_NAME
  fi
  echo "[DOW] Backup done"

  ## Daily Backup
  echo "[Daily] Starting pre-Backup tasks"
  if [[ "$(date +%A)" == $DAILY_BACKUP_RESET_DAY ]]; then
    # Reset backup on Monday
    echo "[Daily] Resetting backup"
    rm $DAILY_BACKUP_NAME
    echo "[Daily] Copying backup from DOW to use as base"
    cp -p $DOW_BACKUP_NAME $DAILY_BACKUP_NAME
  fi
  7z_backup $DAILY_BACKUP_NAME $3 "$opts"

}


for dir in $BACKUP_GAME_SRC/*/
do
    dir=${dir%*/}

    folder_name=${dir##*/}
    echo "testing $folder_name"

    OLDIFS="$IFS"
    IFS='_' read -r -a tokens <<< "$folder_name"
    IFS="$OLDIFS" # restore IFS
    if [[ "${tokens[0]}" != "lgsm" ]]; then
      echo "Skipping non-lgsm folder (${dir##*/})"
      continue
    fi

    echo "Found LGSM gameserver of type ${tokens[1]} called ${tokens[2]}"

    backup_gameserver ${tokens[1]} ${tokens[2]} $dir

done
