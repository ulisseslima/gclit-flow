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
if [[ -n "$json" && "$json" != '[]' ]]; then
    p_name=$(echo "$json" | $MYDIR/jprop.sh "[0]['project_name']")
    p_id=$(echo "$json" | $MYDIR/jprop.sh "[0]['project_id']")

    t_name=$(echo "$json" | $MYDIR/jprop.sh "[0]['title']")
    t_id=$(echo "$json" | $MYDIR/jprop.sh "[0]['id']")
    t_type=$(echo "$json" | $MYDIR/jprop.sh "[0]['type_id']")

    db CURR_PROJECT_ID "${p_id}"
    db CURR_PROJECT_NAME "${p_name}"

    db CURR_TASK_ID "${t_id}"
    db CURR_TASK_NAME "${t_name}"
    db CURR_TASK_TYPE "${t_type}"

    t_team=$(echo "$json" | $MYDIR/jprop.sh "[0]['team_id']")
    db CURR_TASK_TEAM "${t_team}"

    echo "${t_id}=${t_name}"
fi
