#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

id="$(db CURR_TASK_ID)"
name="$(db CURR_TASK_NAME)"

debug "adding comment..."

comment="$1"
if [[ ! -n "$comment" ]]; then
    err "first arg must be comment message"
    exit 1
fi

comment=$(echo $comment)
debug "$comment"

if [[ "$comment" == --local  ]]; then
    shift
    $MYDIR/local-comment.sh "$@"
    exit 0
fi

if [[ $(nan "$id") == true ]]; then
    debug "trying to refresh current task..."
    $MYDIR/rr-sync-task.sh
fi

if [[ $(nan "$id") == true ]]; then
    err "no tasks are running, can't comment"
    exit 1
fi

json=$($MYDIR/runrun.sh POST comments "{
  \"task_id\": $id,
  \"text\": \"$comment\"
}")

if [[ "$json" == *'error'* ]]; then
    err "error posting comment!"
    exit 1
else
    c_id=$(echo "$json" | $MYDIR/jprop.sh "['id']")
    info "comment #$c_id posted: https://runrun.it/en-US/tasks/$(db CURR_TASK_ID)"
    $MYDIR/local-comment.sh "$comment"
fi
