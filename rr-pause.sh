#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

id="$1"
if [[ ! -n "$id" ]]; then
    id="$(db CURR_TASK_ID)"
fi
name="$(db CURR_TASK_NAME)"

if [[ $(nan "$id") == true ]]; then
    err "arg 1 must be the task id"
fi

if [[ $(nan "$id") == true ]]; then
    info "no tasks were running"
    exit 0
fi

info "pausing task #$id ..."

json=$($MYDIR/runrun.sh POST "tasks/$id/pause")
if [[ "$json" == *'already paused'* ]]; then
    info "'$name' was already paused!"
elif [[ "$json" == *'error'* ]]; then
    err "error pausing '$name'!"
    echo "$json"
else
    info "'$name' paused."
fi
