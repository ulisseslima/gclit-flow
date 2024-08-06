#!/bin/bash -e
# @installable
# task execution history
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV
source $MYDIR/log.sh
source $MYDIR/db.sh
source $(real require.sh)

task="$1"
require task
shift

limit=10

while test $# -gt 0
do
    case "$1" in
    --limit|-l|--max|-m)
        shift
        limit=$1
    ;;
    --all|-a)
        limit=100000
    ;;
    -*)
      echo "bad option '$1'"
      exit 1
    ;;
    esac
    shift
done

info -n "latest executions from '$task':"
query="select 
x.* 
from executions x 
join tasks task on task.id=x.task_id 
where task.name ilike '%$task%' 
order by id desc 
limit $limit
"

$MYDIR/psql.sh "$query" --full

$MYDIR/elapsed.sh "$task" --exclude-overall
