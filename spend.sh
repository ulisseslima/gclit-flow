#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh
source $MYDIR/require.sh

gitlab_prefix=fix

if [[ -z "$GITLAB_TOKEN" ]]; then
    debug "GITLAB_TOKEN undefined"
    exit 0
fi

glenv="$(db CURR_FEATURE_DIR)/$GITLAB_ENV"
if [[ ! -f $glenv ]]; then
    err "there must be a file '$glenv' defining gitlab env variables"
fi
source $glenv

task_name="$(db CURR_TASK_NAME)"
if [[ "$task_name" != *$gitlab_prefix* ]]; then
    info "'$task_name': does not contain gitlab_prefix: $gitlab_prefix"
    exit 0
fi

issue_id=$(echo $task_name | cut -d'-' -f2)
if [[ $(nan $issue_id) == true ]]; then
    err "couldn't determine issue id from task name: '$task_name', current time spent won't be sent."
    exit 0
fi

duration=$($MYDIR/spent.sh $issue_id)
if [[ -z "$duration" ]]; then
    err "couldn't determine time spent on task id '$issue_id' since last execution"
else
    info "marking '$duration' as spent on '$issue_id' ..."
    $MYDIR/gitlab-api.sh POST "projects/$GITLAB_PID/issues/$issue_id/add_spent_time?duration=$duration"
fi