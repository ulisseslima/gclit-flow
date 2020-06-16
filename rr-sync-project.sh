#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/prop.sh
source $MYDIR/db.sh

json=$($MYDIR/runrun.sh GET "tasks?user_id=$(rr_user_id)&is_working_on=true")
if [[ -n "$json" && "$json" != '[]' ]]; then
    # TODO abstrair pra não ter que duplicar e chamar no pause
    p_id=$(echo "$json" | $MYDIR/jprop.sh "[0]['project_id']")
    db CURR_PROJECT_ID "${p_id}"
    p_name=$(echo "$json" | $MYDIR/jprop.sh "[0]['project_name']")
    db CURR_PROJECT_NAME "${p_name}"
    
    t_id=$(echo "$json" | $MYDIR/jprop.sh "[0]['id']")
    db CURR_TASK_ID "${t_id}"
    t_name=$(echo "$json" | $MYDIR/jprop.sh "[0]['title']")
    db CURR_TASK_NAME "${t_name}"
    t_type=$(echo "$json" | $MYDIR/jprop.sh "[0]['type_id']")
    db CURR_TASK_TYPE "${t_type}"

    t_team=$(echo "$json" | $MYDIR/jprop.sh "[0]['team_id']")
    db CURR_TASK_TEAM "${t_team}"

    t_ass=$(echo "$json" | $MYDIR/jprop.sh "['assignments'][0]['id']")
    db CURR_TASK_ASS "${t_ass}"

    echo "${p_id}=${p_name}"
fi
