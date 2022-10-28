#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV
source $MYDIR/log.sh
source $MYDIR/db.sh

limit=10
filter="and e.finish > (now()::date - interval '1 month')"

while test $# -gt 0
do
    case "$1" in
    --limit|-l)
	shift
      	limit=$1
    ;;
    --all|-a)
      	limit=10000
    ;;
    --filter|-f)
	shift
	filter="and t.name ilike '%$1%'"
    ;;
    -*)
      echo "bad option '$1'"
    ;;
    esac
    shift
done

info -n "latest executions:"
$MYDIR/psql.sh "select
t.id, t.external_id ext, t.name, t.elapsed
from executions e
join tasks t on t.id=e.task_id
where 1=1
$filter
group by t.id
order by max(e.id) desc
limit $limit" --full
