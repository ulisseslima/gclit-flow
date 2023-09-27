#!/bin/bash
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV
source $MYDIR/log.sh
source $MYDIR/db.sh
source $(real require.sh)

old_task=$1
new_task=$1

require -n old_task
require -n new_task

$MYDIR/psql.sh "update executions set task_id = $new_task where task_id=$old_task and start>now()::date returning *;"
# TODO subtract/add elapsed difference