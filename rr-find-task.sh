#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

regex="$1"
if [[ ! -n "$regex" ]]; then
    err "arg 1 must the the search string (canse insensitive, regex)"
    exit 1
fi
shift

p_id="$(db CURR_PROJECT_ID)"
u_id=$(rr_user_id)

while test $# -gt 0
do
    case "$1" in
    --like)
        shift
        lid=$1
        task=$($MYDIR/runrun.sh GET "tasks/$lid")
        if [[ ! -n "$task" ]]; then
            err "task #$lid not found"
            exit 1
        fi
        p_id=$(echo "$task" | ./jprop.sh "['project_id']")
    ;;
    --everyone)
        u_id=''
    ;;
    --project|-p)
        shift
        name_or_id="$1"

        p_id=$(prompt_project_id "$name_or_id")
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

if [[ ! -n "$p_id" ]]; then
    err "no project selected, arg --project must be the project name or ID"
    exit 1
fi

debug "searching for task like '$regex' on project $p_id - u_id=$u_id ..."
if [[ -n "$u_id" ]]; then
    debug "filtering by tasks created by $u_id"
fi

json=$($MYDIR/runrun.sh GET "tasks?project_id=$p_id&user_id=$u_id")
if [[ -n "$json" ]]; then
    echo "$json" | $MYDIR/jmap.py id title | grep -iP "$regex" || true
fi