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

echo "runrun user id: $(rr_user_id)"
db_dump

info -n "local db:"
$MYDIR/psql.sh --connection

curr=$($MYDIR/rr-sync-task.sh || true)
if [[ -n "$curr" ]]; then
    t_id=$(echo $curr | cut -d'=' -f1)
    t_name=$(echo $curr | cut -d'=' -f2)
    
    info -n "task is currently in progress. you can check response by running $MYDIR/last-response.sh"
    echo "$t_name - https://runrun.it/en-US/tasks/${t_id}"
else
    info -n "task is currently stopped."
fi

info -n "latest local executions:"
$MYDIR/psql.sh \
    "select t.name,coalesce(sum(e.elapsed)::text, 'running...') from executions e join tasks t on t.id=e.task_id where e.start > now()::date group by t.id order by max(e.id) desc"

$MYDIR/elapsed.sh