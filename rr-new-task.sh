#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

project_id="$(db CURR_PROJECT_ID)"
if [[ $(nan "$project_id") == true ]]; then
    info "to start a new task you need to be working on a project. enter desired project name:"
    read name_or_id

    project_id=$(prompt_project_id "$name_or_id")
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

matches="$($MYDIR/rr-find-task.sh "$name")"
if [[ -n "$matches" ]]; then
  err "task already exists:"
  echo "$matches"

  first=$($MYDIR/get.sh 1 "$matches" | cut -d'=' -f1)
  $MYDIR/rr-play.sh $first
  exit 0
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

if [[ "$json" == *'error'* ]]; then
    err "problem creating task '$name', check cached response with $MYDIR/last-response.sh"
else
    t_id=$(echo "$json" | $MYDIR/jprop.sh "['id']")
    info "'$name' created with ID '$t_id'. playing..."
    $MYDIR/rr-play.sh $t_id
fi
