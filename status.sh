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

info "runrun user id: $(rr_user_id)"
db_dump

info -n "local db:"
$MYDIR/psql.sh --connection

t_id=$($MYDIR/rr-sync-task.sh || true)
if [[ -n "$t_id" ]]; then
    info "link: https://runrun.it/en-US/tasks/${t_id}"
fi


info -n "latest local executions:"
$MYDIR/psql.sh "select 
        t.name, coalesce(sum(e.elapsed)::text, 'ongoing...') elapsed
    from executions e 
    join tasks t on t.id=e.task_id 
    where e.start > now()::date 
    group by t.id 
    order by max(e.id) desc
" --full

$MYDIR/elapsed.sh