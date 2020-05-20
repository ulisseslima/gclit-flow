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

p_id="${2:-$(db CURR_PROJECT_ID)}"
if [[ ! -n "$p_id" ]]; then
    err "no current project, arg 2 must be the project id"
    exit 1
fi

debug "searching for task like '$regex' on project $p_id ..."
json=$($MYDIR/runrun.sh GET "tasks?project_id=$p_id")
if [[ -n "$json" ]]; then
    echo "$json" | $MYDIR/jmap.py id title | grep -iP "$regex" || true
fi