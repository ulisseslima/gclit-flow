#!/bin/bash -e
# @installable

# TODO bring current task time

MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

echo "MYDIR=$MYDIR"

curr=$($MYDIR/rr-sync-task.sh)
db_dump

info -n "local db:"
$MYDIR/psql.sh --connection

if [[ -n "$curr" ]]; then
    info -n "task is currently in progress. you can check response by running $MYDIR/last-response.sh"
else
    info -n "task is currently stopped."
fi

info -n "latest local executions:"
$MYDIR/psql.sh \
    "select t.name,coalesce(sum(e.elapsed)::text, 'running...') from executions e join tasks t on t.id=e.task_id where e.start > now()::date group by t.id order by t.id desc"
