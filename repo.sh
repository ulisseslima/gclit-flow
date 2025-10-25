#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

$MYDIR/psql.sh "select t.repo from tasks t join executions e on e.task_id=t.id order by e.id desc limit 1"