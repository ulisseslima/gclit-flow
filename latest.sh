#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

info -n "latest executions:"
$MYDIR/psql.sh "select 
t.name, sum(t.elapsed) 
from executions e
join tasks t on t.id=e.task_id 
group by t.id
order by max(e.id) desc 
limit 10" --full