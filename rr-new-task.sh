#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

name="$1"
if [[ ! -n "$name"　|| "$name" == '-'* ]]; then
    err "arg 1 must be task name"
    exit 1
fi
info "creating runrun task '$name'..."

project_id="$(db CURR_PROJECT_ID)"
type=$(db CURR_TASK_TYPE)
team=$(db CURR_TASK_TEAM)

while test $# -gt 0
do
    case "$1" in
    --like)
        shift
        lid=$1
        task=$($MYDIR/runrun.sh GET "tasks/$lid")
        if [[ ! -n "$task" ]]; then
            err "task #$lid not found"
            exit 1
        fi
        
        project_id=$(echo "$task" | $MYDIR/jprop.sh "['project_id']")
        type=$(echo "$task" | $MYDIR/jprop.sh "['type_id']")
        team=$(echo "$task" | $MYDIR/jprop.sh "['team_id']")
    ;;
    --everyone)
        u_id=''
    ;;
    --project|-p)
        shift
        project_id="$1"
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

while [[ $(nan "$project_id") == true ]]; do
    if [[ ! -n "$project_id" ]]; then
      info "to start a new task you need to be working on a project. enter desired project name:"
      read project_id
    fi

    project_id=$(prompt_project_id "$project_id")
done
debug "project_id: $project_id"

if [[ $(nan "$type") == true ]]; then
    err "current task type is not set correctly. please run gclit-rr-sync-task."
    exit 1
fi
debug "type: $type"

if [[ $(nan "$team") == true ]]; then
    err "current task team is not set correctly. please run gclit-rr-sync-task."
    exit 1
fi
debug "team: $team"

debug "checking if $name already exists..."
matches="$($MYDIR/rr-find-task.sh "$name" -p "$project_id")"
if [[ -n "$matches" ]]; then
  err "task already exists:"
  echo "$matches"

  first=$($MYDIR/get.sh 1 "$matches" | cut -d'=' -f1)
  info "playing the first (#$first)..."
  
  $MYDIR/rr-play.sh $first
  exit 0
fi

debug "creating task $name ..."
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
    err "problem creating task '$name' on project #$project_id:"
    echo "$json" | $MYDIR/jprop.sh "['errors']"
    info "check cached response with $MYDIR/last-response.sh"
else
    debug "parsing task response id..."
    t_id=$(echo "$json" | $MYDIR/jprop.sh "['id']")
    info "'$name' created with ID '$t_id'. playing..."
    $MYDIR/rr-play.sh $t_id
fi
