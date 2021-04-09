#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

# optional
task_id="$1"

info "total time worked (overall)"

>&2 $MYDIR/psql.sh "select
    (select coalesce(sum(elapsed), '0 hours') from executions where start between now()::date - interval '1 day' and now()::date) as yesterday,
    (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date) as today,
    (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 week') as last_week,
    (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 month') as last_month,
    (select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 year') as last_year
" --full

if [[ -n "$task_id" ]]; then
    info "total time worked (for task #${task_id})"

    >&2 $MYDIR/psql.sh "select
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start between now()::date - interval '1 day' and now()::date) as yesterday,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date) as today,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 week') as last_week,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 month') as last_month,
        (select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 year') as last_year
    " --full
fi