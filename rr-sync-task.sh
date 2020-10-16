#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

json=$($MYDIR/runrun.sh GET "tasks?user_id=$(rr_user_id)&is_working_on=true")
if [[ ! -n "$json" ]]; then
    info "no tasks to sync"
    exit 1
fi

first="[0]"

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

info "syncing..."
p_name=$(echo "$json" | $MYDIR/jprop.sh "$first['project_name']")
p_id=$(echo "$json" | $MYDIR/jprop.sh "$first['project_id']")

t_name=$(echo "$json" | $MYDIR/jprop.sh "$first['title']")
t_id=$(echo "$json" | $MYDIR/jprop.sh "$first['id']")
t_type=$(echo "$json" | $MYDIR/jprop.sh "$first['type_id']")

db CURR_PROJECT_ID "${p_id}"
db CURR_PROJECT_NAME "${p_name}"

db CURR_TASK_ID "${t_id}"
db CURR_TASK_NAME "${t_name}"
db CURR_TASK_TYPE "${t_type}"

t_team=$(echo "$json" | $MYDIR/jprop.sh "$first['team_id']")
if [[ ! -n "$t_team" || "$t_team" == null || "$t_team" == None ]]; then
    t_team=$(echo "$json" | $MYDIR/jprop.sh "$first['assignments'][0]['team_id']")
fi
db CURR_TASK_TEAM "${t_team}"

t_ass=$(echo "$json" | $MYDIR/jprop.sh "$first['assignments'][0]['id']")
db CURR_TASK_ASS "${t_ass}"

echo "${t_id}=${t_name}"