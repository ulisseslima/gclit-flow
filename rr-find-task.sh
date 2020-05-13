#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

regex="$1"
if [[ ! -n "$regex" ]]; then
    err "arg 1 must the the search string (canse insensitive, regex)"
    exit 1
fi

p_id="$2"
if [[ ! -n "$p_id" ]]; then
    err "arg 2 must the project id"
    exit 1
fi

json=$($MYDIR/runrun.sh GET 'tasks?project_id=$p_id')
if [[ -n "$json" ]]; then
    echo "$json" | $MYDIR/jmap.py id title | grep -iP "$regex"
fi