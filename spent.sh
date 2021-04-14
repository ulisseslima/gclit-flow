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

# minutes spent since last execution
$MYDIR/psql.sh "select 
(EXTRACT(EPOCH FROM (now()-e.start)::INTERVAL)/60)::integer||'m'
from executions e 
join tasks t on t.id=e.task_id 
where t.external_id='$rr_task_id' 
order by e.start desc 
limit 1"