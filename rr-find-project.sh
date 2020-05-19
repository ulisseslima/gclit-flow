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

STORE=$CACHE/projects.map
if [[ ! -f $STORE ]]; then
    $MYDIR/rr-find-all-projects.sh
fi

grep -iP "$regex" $STORE || true