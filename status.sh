#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

curr=$($MYDIR/rr-curr-task.sh)
db_dump

if [[ -n "$curr" ]]; then
    info -n "task is currently in progress. you can check response by running $MYDIR/last-response.sh"
else
    info -n "task is currently stopped."
fi