#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

project_id="$(db CURR_PROJECT_ID)"
if [[ $(nan "$project_id") == true ]]; then
    err "to start a new task you need to be working on a project. please run gclit-rr-curr-task."
    exit 1
fi

type=$(db CURR_TASK_TYPE)
if [[ $(nan "$type") == true ]]; then
    err "current task type is not set correctly. please run gclit-rr-curr-task."
    exit 1
fi

team=$(db CURR_TASK_TEAM)
if [[ $(nan "$team") == true ]]; then
    err "current task team is not set correctly. please run gclit-rr-curr-task."
    exit 1
fi

name="$1"
if [[ ! -n "$name" ]]; then
    err "arg 1 must be task name"
    exit 1
fi

json=$($MYDIR/runrun.sh POST tasks "{
  \"task\": {
    \"scheduled_start_time\": null,
    \"desired_date_with_time\": null,
    \"on_going\": false,
    \"project_id\": $project_id,
    \"title\": \"$name\",
    \"type_id\": $type,
    \"assignments\": [
      {
        \"assignee_id\": \"$(rr_user_id)\",
        \"team_id\": $team
      }
    ]
  }
}")

if [[ "$json" == *'already paused'* ]]; then
    info "'$name' was already paused!"
else
    info "'$name' created"
    #$MYDIR/rr-play.sh
fi
