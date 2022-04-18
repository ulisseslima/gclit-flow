#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

if [[ "$RR_ENABLED" != true ]]; then
    debug "run run is not enabled"
    exit 0
fi

json=$($MYDIR/runrun.sh GET "tasks?user_id=$(rr_user_id)&is_working_on=true")
if [[ ! -n "$json" ]]; then
    info "no tasks to sync"
    exit 1
fi

first="[0]"

task_id=$(echo "$json" | $MYDIR/jprop.sh "$first['id']")
if [[ '[]' == "$json" ]]; then
    first=''

    info "no tasks owned by the user are in progress, checking all executions..."
    ongoing=$($MYDIR/runrun.sh GET "tasks?is_working_on=true")
    task_id=$(node $MYDIR/find-user-execution.js $(rr_user_id) "$ongoing")
    if [[ ! -n "$task_id" ]]; then
        info "couldn't find any ongoing tasks"
        exit 1
    fi

    info "found ongoing task $task_id"
    json=$($MYDIR/runrun.sh GET "tasks/$task_id")
fi

if [[ ! -n "$task_id" ]]; then
    err "could not determine current remote task id"
    exit 1
fi

info "syncing to task #$task_id ..."
$MYDIR/rr-pause.sh $task_id > /dev/null 2>&1 && $MYDIR/rr-play.sh $task_id > /dev/null 2>&1
echo $task_id