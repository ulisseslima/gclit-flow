#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

exclude_overall=false
# optional
task_id="$1"
shift

while test $# -gt 0
do
    case "$1" in
    --exclude-overall)
        exclude_overall=true
    ;;
    -*)
      echo "bad option '$1'"
      exit 1
    ;;
    esac
    shift
done

if [[ $exclude_overall == false ]]; then
    info "total time worked (overall)"

    >&2 $MYDIR/psql.sh "select
        (select coalesce(sum(elapsed), '0 hours') from executions where start between now()::date - interval '1 day' and now()::date) as yesterday,
        (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date) as today,
        (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 week') as last_week,
        (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 month') as last_month,
        (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 year') as last_year
    " --full
fi

if [[ -n "$task_id" ]]; then
    if [[ $(nan $task_id) == true ]]; then
        task_name="$task_id"
        task_id=$($MYDIR/psql.sh "select id from tasks where name ilike '%$task_name%' order by id desc limit 1")
        task_name=$($MYDIR/psql.sh "select name from tasks where id = $task_id")
        if [[ -z "$task_id" ]]; then
            err "task not found: $task_name"
            exit 1
        else
            info "found task: $task_name"
        fi
    fi

    info "total time worked (for task #${task_id})"

    >&2 $MYDIR/psql.sh "select
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start between now()::date - interval '1 day' and now()::date) as yesterday,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date) as today,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 week') as last_week,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 month') as last_month,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 year') as last_year
    " --full
fi