#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh
source $MYDIR/require.sh

rr_task_id="$1"
require rr_task_id

if [[ -n "$GITLAB_TOKEN" ]]; then
    task_name="$(db CURR_TASK_NAME)"
    if [[ "$task_name" == *fix* ]]; then
        glenv="$(db CURR_FEATURE_DIR)/$GITLAB_ENV"

        if [[ ! -f $glenv ]]; then
            err "there must be a file '$glenv' defining gitlab env variables"
        else
            source $glenv

            issue_id=$(echo $task_name | cut -d'-' -f2)
            if [[ $(nan $issue_id) == true ]]; then
                err "couldn't determine issue id from branch name: '$task_name', current time spent won't be sent."
            else
                duration=$($MYDIR/spent.sh $rr_task_id)
                $MYDIR/gitlab-api.sh POST "projects/$GITLAB_PID/issues/$issue_id/add_spent_time?duration=$duration"
            fi
        fi
    fi
fi