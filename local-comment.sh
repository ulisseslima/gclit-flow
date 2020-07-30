#!/bin/bash -e
# inserts a local comment
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

comment="$1"
debug "new local comment: $comment"
$MYDIR/psql.sh \
    "insert into comments (task_id, content) select t.id, '$comment' from executions e join tasks t on t.id=e.task_id order by e.id desc limit 1;"