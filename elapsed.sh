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

info "today: "
$MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date"

info "last week: "
$MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 week'"

info "last month: "
$MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 month'"

info "last year: "
$MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where start > now()::date - interval '1 year'"

if [[ -n "$task_id" ]]; then
    info "total time worked (for task #${task_id})"

    info "today: "
    $MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date"

    info "last week: "
    $MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 week'"

    info "last month: "
    $MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 month'"

    info "last year: "
    $MYDIR/psql.sh "select coalesce(sum(elapsed), '0 hours') from executions where task_id = $task_id and start > now()::date - interval '1 year'"
fi