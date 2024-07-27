#!/bin/bash

7z_backup () {
    opts=$3

    if [ -n "$BACKUP_PASSWORD" ]
    then
        #-p allows for a password to be set
        opts=$opts" -p${BACKUP_PASSWORD}"
    fi
    echo "7z opts $opts"
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
