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
if [[ -n "$id" ]]; then
	json=$($MYDIR/runrun.sh GET "tasks/$id")
    
    name=$(echo "$json" | $MYDIR/jprop.sh "['title']")
    ass=$(echo "$json" | $MYDIR/jprop.sh "['assignments'][0]['id']")
else
    id="$(db CURR_TASK_ID)"

    if [[ $(nan "$id") == true ]]; then
        info "no tasks were running"
        exit 0
    fi
    
    name="$(db CURR_TASK_NAME)"
    ass="$(db CURR_TASK_ASS)"
fi

info "delivering #$id: '$name', assignment '$ass' ..."
json=$($MYDIR/runrun.sh POST "tasks/$id/assignments/$ass/deliver")

info "finishing task $id ..."
json=$($MYDIR/runrun.sh POST "tasks/$id/deliver")
if [[ "$json" == *'already delivered'* ]]; then
    info "'$name' was already delivered!"
elif [[ "$json" == *'error'* ]]; then
    err "error delivering '$name'!"
    echo "$json"
else
    db CURR_TASK_ID undefined
    db CURR_TASK_NAME undefined
    db LAST_TASK_ID $id
    info "task '$name' delivered."
fi
