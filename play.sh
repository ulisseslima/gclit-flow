#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV
source $MYDIR/log.sh
source $MYDIR/db.sh

# @return task if created
function new_task() {
    name="$1"
    project_id="$2"

    old_task=$($MYDIR/psql.sh "
        select * from tasks 
        where name = '$name' 
        and project_id = $project_id
    ")

    if [[ -z "$old_task" ]]; then
        repo=$(repo_root_quiet)
        if [[ -d "$repo" ]]; then
            info "'$name' task repo defined as $repo (<enter> to confirm):"
            read confirmation
        else
            info "define a repo for '$name' [empty]:"
            read repo
            while [[ -n "$repo" && ! -d "$repo" ]]; do
                err "not a repo: $repo - try again:"
                read repo
            done
        fi

        new_task=$($MYDIR/psql.sh "
            INSERT INTO tasks
            (name, project_id, external_id, repo) 
            SELECT '$name', $project_id, '$external_id', '$repo'
            RETURNING *
        ")

        info "new task created"
        echo "$new_task"
    else
        info "using old task"
        echo "$old_task"
    fi

    if [[ -n "$external_id" ]]; then
        info "updating external id of '$name' to '$external_id'"
        >&2 $MYDIR/psql.sh "
            update tasks set external_id = '$external_id' 
            where name = '$name' and project_id = $project_id
        "
    else
        issue_id=$(echo $name | cut -d'-' -f2)
        if [[ $(nan $issue_id) != true ]]; then
            info "updating external id of '$name' to '$issue_id'"
            >&2 $MYDIR/psql.sh "
                update tasks set external_id = '$issue_id' 
                where name = '$name' and project_id = $project_id
            "
        fi
    fi
}

# finishes unclosed executions
function check_open_executions() {
    chktid=$1
    debug "checking open executions for $chktid ..."
    ex=false

    while read open_execution
    do
        tid=$(echo $open_execution | cut -d'=' -f1)
        tname=$(echo $open_execution | cut -d'=' -f2)

        info "you were previously working on '$tname', ending open executions for task #$tid ..."
        $MYDIR/spend.sh "$tid"
        comment $tid "started work on task #$chktid"

        pause $tid
        ex=true
    done < <($MYDIR/psql-map.sh \
        "executions e join tasks t on t.id=e.task_id" \
        "t.id,t.name" \
        "task_id <> $chktid and e.finish is null group by t.id")

    debug "open executions checked for $chktid"
    if [[ $ex == true ]]; then
        debug "...and found"
    fi
}

# FIXME not pausing when open execution exists
# @return execution if created
function play() {
    pltask_id="$1"

    if [[ -z "$pltask_id" ]]; then
        err "task id cannot be null"
        exit 1
    fi

    info "playing #$pltask_id ..."

    check_open_executions $pltask_id

    debug "creating execution if not exists for $pltask_id ..."
    $MYDIR/psql.sh "WITH open_execution AS (
     select * from executions where task_id = $pltask_id AND finish is null
     ) INSERT INTO executions
     (task_id, start)
     SELECT $pltask_id, now()
     WHERE NOT EXISTS (SELECT * FROM open_execution)
     RETURNING *
    ;"
}

# @return updated task
function pause() {
    ptask_id="$1"

    if [[ ! -n "$ptask_id" ]]; then
        err "task id cannot be null"
        exit 1
    fi

    debug "#$ptask_id - starting pause process..."

    check_open_executions $ptask_id

    $MYDIR/psql.sh "WITH execution AS (
     UPDATE executions 
     SET finish = now(), elapsed = (now() - start)
     WHERE task_id = $ptask_id AND finish is null
     RETURNING *
     ) update tasks set elapsed = elapsed + (select elapsed from execution)
     where id = $ptask_id
     returning *
    ;"

    debug "#$ptask_id - finished pause process"
}

# @return last comments 
function comment() {
    ctask_id="$1"
    content="$2"

    debug "// $content"

    $MYDIR/psql.sh "insert into comments (task_id, content)
     select $ctask_id, '$content' 
     returning *
    ;"
}

# @return tasks that match name 
function find() {
    task_id="$1"
    content="$2"

    $MYDIR/psql.sh "insert into comments (task_id, content)
     select $task_id, '$content' 
     returning *
    ;"
}

name="$1"
if [[ -n "$1" && "$1" != -* ]]; then
    shift
fi

project_id=1
external_id=''
new=false
pausing=false

while test $# -gt 0
do
    case "$1" in
    --list|-l) 
        latest_tasks
        exit 0
    ;;
    --status|-s) 
        $MYDIR/psql.sh "
            select 
                t.name, e.start, e.finish, (coalesce(e.finish, now())-e.start) elapsed 
            from executions e 
            join tasks t on t.id=e.task_id 
            order by e.id desc 
            limit 1
        ;" --full
        exit 0
    ;;
    --remove-last|-r) 
        info "deleting last task..."
        $MYDIR/psql.sh "delete from tasks where id = (select id from tasks order by id desc limit 1) returning *"
        exit 0
    ;;
    --connect|-c) 
        info "connecting to local db..."
        psql -U $DB_USER $DB_NAME
        exit 0
    ;;
    --find|-f)
        shift
        search="$1"
        info "finding last 5 tasks like '$search' ..."
        $MYDIR/psql.sh "select * from tasks where name ilike '%$search%' order by id desc limit 5;" --full
        exit 0
    ;;
    --project|-p)
        shift
        project_id="${1}"
    ;;
    --external-id|--ex)
        shift
        external_id=$1
    ;;
    --pause)
        # defining as null name to go to pause flow
        name=''
        pausing=true
    ;;
    -*) 
      echo "bad option '$1'"
      exit 1
    ;;
    esac
    shift
done

if [[ -n "$name" ]]; then
    # switching to a specific task
    debug "will work with task '$name' on project '$project_id' ..."
    task=$(new_task "$name" $project_id)

    if [[ -n "$task" ]]; then
        task_id=$(echo "$task" | cut -d'|' -f1)
        info "using task #$task_id '$name'"
        new=true
    else
        debug "previously open tasks for '$name' found, looking for latest task execution ..."
        task=$($MYDIR/psql.sh "select 
            t.id,e.finish 
            from tasks t join executions e on e.task_id=t.id 
            where t.name = '$name' 
            order by e.id desc 
            limit 1
        ")
        
        task_id=$(echo $task | cut -d'|' -f1)
        finish=$(echo $task | cut -d'|' -f2)
    fi
else
    # determine current task
    task=$($MYDIR/psql.sh "select t.id,e.finish,t.name from tasks t join executions e on e.task_id=t.id order by e.id desc limit 1")
    task_id=$(echo $task | cut -d'|' -f1)
    finish=$(echo $task | cut -d'|' -f2)
    name=$(echo $task | cut -d'|' -f3)
fi

if [[ -n "$finish" || $new == true ]]; then
    debug "finish: '$finish', new: $new"

    if [[ $pausing == false ]]; then
        execution=$(play $task_id)
        if [[ -n "$execution" ]]; then
            info "playing '$name' locally!!"

            db LAST_TASK_ID "$(db CURR_TASK_ID)"

            db CURR_TASK_ID "${task_id}"
            db CURR_TASK_NAME "${name}"
        else
            err "2 - couldn't play '$name' ... execution:"
            info "$execution"
        fi
    else
        info "already paused locally"
    fi
else
    debug "...none finished"
    
    if [[ ! -n "$task_id" ]]; then
        debug "finding task id by last task with name..."
        task=$($MYDIR/psql.sh "select t.id from tasks t where t.name = '$name' order by t.id desc limit 1")
        task_id=$(echo $task | cut -d'|' -f1)
        debug "found: $task_id"
    fi

    execution=$(pause $task_id)
    if [[ -n "$execution" ]]; then
        info "paused '$name' locally!"
        $MYDIR/spend.sh "$task_id"
    else
        info "couldn't pause '$name' ..."
        
        execution=$(play $task_id)
        if [[ -n "$execution" ]]; then
            info "playing '$name' locally!"

            db LAST_TASK_ID "$(db CURR_TASK_ID)"

            db CURR_TASK_ID "${task_id}"
            db CURR_TASK_NAME "${name}"
        else
            err "1 - couldn't play '$name' ..."
        fi
    fi
fi

info -n "latest executions from '$name' (#$task_id):"
$MYDIR/psql.sh "select * from executions where task_id = $task_id order by id desc limit 5" --full

$MYDIR/elapsed.sh "$task_id"

# TODO 
# - query last executions
# - comment insertions