#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/require.sh

task_id="$1"

gitlab_prefix=fix

task=$($MYDIR/psql.sh "
    select row_to_json(tasks) 
    from tasks where id = '$task_id'
")

task_repo=$(jprop "$task" repo)
task_name=$(jprop "$task" name)

if [[ -z "$task_repo" ]]; then
    debug "no repo defined"
    exit 0
fi

if [[ -d "$task_repo" ]]; then
    is_gitlab=$(grep -c gitlab "$task_repo/.git/config" || true)
    if [[ $is_gitlab -lt 1 ]]; then
        # TODO support github
        debug "not a gitlab repo: $task_repo"
        exit 0
    fi
fi

if [[ -z "$GITLAB_TOKEN" ]]; then
    debug "GITLAB_TOKEN undefined"
    exit 0
fi

glenv="$task_repo/$GITLAB_ENV"
if [[ ! -f $glenv ]]; then
    err "there must be a file '$glenv' defining gitlab env variables"
fi
source $glenv

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
elif [[ "$duration" != '0m' ]]; then
    info "marking '$duration' as spent on '$issue_id' ..."
    $MYDIR/gitlab-api.sh POST "projects/$GITLAB_PID/issues/$issue_id/add_spent_time?duration=$duration"
fi