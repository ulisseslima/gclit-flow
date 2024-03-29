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
    err "run run is not enabled"
    exit 1
fi

id="$1"
if [[ ! -n "$id" ]]; then
    id="$(db CURR_TASK_ID)"
fi

if [[ "$id" == '#'* ]]; then
    debug "removing hash..."
    id="${id/#/}"
fi

if [[ $(nan "$id") == true ]]; then
    err "arg 1 must be the task id"
    if [[ -n "$id" ]]; then
        info "showing results for '$id' on project #$(db CURR_PROJECT_ID) ..."
        matches=$($MYDIR/rr-find-task.sh "$@")
        
        $MYDIR/iterate.sh "$matches" '[$n] $line'
        info "choose one [1]:"
        read one
        [[ ! -n "$one" ]] && one=1

        task=$($MYDIR/get.sh $one "$matches")
        id=$(echo "$task" | cut -d'=' -f1)
    fi
    
    if [[ $(nan "$id") == true ]]; then
        info "choose an ID and try again"
        exit 1
    fi
fi

info "resuming task #$id ..."
json=$($MYDIR/runrun.sh POST "tasks/$id/play")
if [[ "$json" == *'already in progress'* ]]; then
    info "< '$(db CURR_TASK_NAME)' was already in progress >"
    echo "$(db CURR_TASK_ID)=$(db CURR_TASK_NAME)"
    exit 1
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

    db LAST_TASK_ID "$(db CURR_TASK_ID)"

    db CURR_PROJECT_ID "${p_id}"
    db CURR_PROJECT_NAME "${p_name}"
    
    db CURR_TASK_ID "${t_id}"
    db CURR_TASK_NAME "${t_name}"
    db CURR_TASK_TYPE "${t_type}"
    
    t_team=$(echo "$json" | $MYDIR/jprop.sh "['team_id']")
    if [[ ! -n "$t_team" || "$t_team" == null || "$t_team" == None ]]; then
        t_team=$(echo "$json" | $MYDIR/jprop.sh "['assignments'][0]['team_id']")
    fi
    db CURR_TASK_TEAM "${t_team}"
    
    t_ass=$(echo "$json" | $MYDIR/jprop.sh "['assignments'][0]['id']")
    db CURR_TASK_ASS "${t_ass}"

    echo "$t_name - https://runrun.it/en-US/tasks/${t_id}"
    $MYDIR/play.sh "$t_name" --ex $t_id
fi
