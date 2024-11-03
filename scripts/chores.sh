#!/bin/bash

SELF_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


source $SELF_DIR/backup_util.sh


/bin/bash $SELF_DIR/image_prune.sh