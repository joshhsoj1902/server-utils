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
  opts=$(add_7z_exclude "$opts" "$source_folder_name/config-lgsm/")

  case $1 in
    "pz")
       opts=$(add_7z_exclude "$opts" "*/serverfiles")
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
       opts=$(add_7z_exclude "$opts" "$source_folder_name/log/")
      ;;
    *)
      echo "Nothing special to do for $1"
      ;;
  esac

  if $BACKUP_DOW; then
    if [[ "$(date +%A)" == "Monday" ]]; then
      # Reset backup on Monday
      echo "[DOW] Resetting backup since it is Monday"
      rm $game_backup_dir/slim-backup-$(date +%A).7z
    else
      # If not monday, Copy yesterdays backup as starting point
      echo "[DOW] Copying backup from yesterday to use as base"
      rm $game_backup_dir/slim-backup-$(date +%A).7z
      cp -p $game_backup_dir/slim-backup-$(date -d '1 day' +%A).7z $game_backup_dir/slim-backup-$(date +%A).7z
    fi
    7z_backup $game_backup_dir/slim-backup-$(date +%A).7z $3 "$opts"
    echo "[DOW] bacjup done"
  fi

  if $BACKUP_DAILY; then
    if [[ "$(date +%A)" == "Monday" ]]; then
      # Reset backup on Monday
      echo "[Daily] Resetting backup since it is Monday"
      rm $game_backup_dir/slim-backup-Daily.7z
      if $BACKUP_DOW; then
        echo "[Daily] Copying backup from DOW to use as base"
        cp -p $game_backup_dir/slim-backup-$(date +%A).7z $game_backup_dir/slim-backup-Daily.7z
      fi
    fi
    7z_backup $game_backup_dir/slim-backup-Daily.7z $3 "$opts"
  fi

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
