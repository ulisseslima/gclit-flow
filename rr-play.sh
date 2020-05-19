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

if [[ $(nan "$id") == true ]]; then
    err "arg 1 must the task id, received '$id'"
    exit 1
fi

info "resuming task #$id ..."
json=$($MYDIR/runrun.sh POST "tasks/$id/play")
if [[ "$json" == *'already in progress'* ]]; then
    debug "'$(db CURR_TASK_NAME)' was already in progress!"
    echo "$(db CURR_TASK_ID)=$(db CURR_TASK_NAME)"
    exit 0
fi

if [[ -n "$json" ]]; then
    if [[ "$json" == *'error'* ]]; then
        err "error resuming task!"
        echo "$json"
        exit 1
    fi

    t_id=$(echo "$json" | $MYDIR/jprop.sh "['id']")
    t_name=$(echo "$json" | $MYDIR/jprop.sh "['title']")
    t_type=$(echo "$json" | $MYDIR/jprop.sh "['type_id']")

    if [[ ! -n "$t_id" ]]; then
        err "problem resuming task: $json"
        exit 1
    fi

    p_id=$(echo "$json" | $MYDIR/jprop.sh "['project_id']")
    p_name=$(echo "$json" | $MYDIR/jprop.sh "['project_name']")

    db CURR_PROJECT_ID "${p_id}"
    db CURR_PROJECT_NAME "${p_name}"
    
    db CURR_TASK_ID "${t_id}"
    db CURR_TASK_NAME "${t_name}"
    db CURR_TASK_TYPE "${t_type}"

    t_team=$(echo "$json" | $MYDIR/jprop.sh "['team_id']")
    db CURR_TASK_TEAM "${t_team}"

    echo "${t_id}=${t_name}"
fi
