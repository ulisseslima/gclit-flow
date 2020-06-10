#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

last_id="$(db LAST_TASK_ID)"
if [[ ! -n "$last_id" ]]; then
    err "no task to switch back to"
    exit 1
fi

info "leaving #$(db CURR_TASK_ID) and switching back to #$last_id ..."
$MYDIR/rr-play.sh "$last_id"