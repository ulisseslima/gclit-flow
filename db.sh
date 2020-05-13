#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/prop.sh

if [[ ! -f $LOCAL_DB ]]; then
    mkdir -p $(dirname $LOCAL_DB)
    touch $LOCAL_DB
fi

function db() {
    prop "$LOCAL_DB" "$@"
    if [[ -n "$2" ]]; then
        debug "saved to $LOCAL_DB"
    fi
}