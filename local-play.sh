#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

##
# @return task if created
function new_task() {
    name="$1"
    project_id="$2"

    $MYDIR/psql.sh "WITH existing_task AS (
     select * from tasks 
     where name = '$name' and project_id = $project_id
     ) INSERT INTO tasks
     (name, project_id) 
     SELECT '$name', $project_id 
     WHERE NOT EXISTS (SELECT * FROM existing_task)
     RETURNING *
    ;"
}

##
# @return execution if created
function play() {
    task_id="$1"

    $MYDIR/psql.sh "WITH open_execution AS (
     select * from executions where task_id = $task_id AND finish is null
     ) INSERT INTO executions
     (task_id, start)
     SELECT $task_id, now()
     WHERE NOT EXISTS (SELECT * FROM open_execution)
     RETURNING *
    ;"
}

##
# @return 
function pause() {
    task_id="$1"

    $MYDIR/psql.sh "WITH execution AS (
     UPDATE executions 
     SET finish = now(), elapsed = (now() - start)
     WHERE task_id = $task_id AND finish is null
     RETURNING *
     ) update tasks set elapsed = elapsed + (select elapsed from execution)
     where id = $task_id
     returning *
    ;"
}

name="$1"
project_id="${2:-1}"
new=false

if [[ -n "$name" ]]; then
    debug "will work with task '$name' ..."
    task=$(new_task "$name" $project_id)
    if [[ -n "$task" ]]; then
        task_id=$(echo "$task" | cut -d'|' -f1)
        info "task $name created with id $task_id"
        new=true
    else
        task=$($MYDIR/psql.sh "select t.id,e.finish from tasks t join executions e on e.task_id=t.id where t.name = '$name' order by e.id desc limit 1")
        task_id=$(echo $task | cut -d'|' -f1)
        finish=$(echo $task | cut -d'|' -f2)
    fi
else
    task=$($MYDIR/psql.sh "select t.id,e.finish,t.name from tasks t join executions e on e.task_id=t.id order by e.id desc limit 1")
    task_id=$(echo $task | cut -d'|' -f1)
    finish=$(echo $task | cut -d'|' -f2)
    name=$(echo $task | cut -d'|' -f3)
fi

if [[ -n "$finish" || $new == true ]]; then
    debug "finish: '$finish', new: $new"
    execution=$(play $task_id)
    if [[ -n "$execution" ]]; then
        info "playing '$name' !"
    else
        err "couldn't play '$name' ..."
    fi
else
    debug "null finish"
    execution=$(pause $task_id)
    if [[ -n "$execution" ]]; then
        info "paused '$name' !"
    else
        err "couldn't pause '$name' ..."
    fi
fi

info -n "latest executions:"
$MYDIR/psql.sh "select * from executions where task_id = $task_id order by id desc limit 5" --full
