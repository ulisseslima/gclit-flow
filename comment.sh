#!/bin/bash -e
# @installable
# inserts a local comment
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

comment="$@"
debug "new local comment: $comment"
$MYDIR/psql.sh "
    insert into comments 
        (task_id, content) 
    select 
        t.id, '$comment' 
    from executions e 
    join tasks t on t.id=e.task_id 
    order by e.id desc 
    limit 1
"

info "last comments..."
$MYDIR/psql.sh "
    select 
        stamp, coalesce(max(t.external_id), max(t.id)::text) id, max(t.name) task, content 
    from executions e 
    join tasks t on t.id=e.task_id 
    join comments c on c.task_id=t.id 
    group by c.id 
    order by c.id desc 
    limit 5
" --full
