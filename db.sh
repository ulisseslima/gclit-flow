#!/bin/bash -e
X=$(dirname `readlink -f ${BASH_SOURCE[0]}`)
source $X/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $X/log.sh
source $X/prop.sh

MYSELF() { readlink -f "${BASH_SOURCE[0]}"; }
MYDIR() { echo "$(dirname $(MYSELF))"; }
MYNAME() { echo "$(basename $(MYSELF))"; }
CALLER=$(basename `readlink -f $0`)

if [[ ! -f $LOCAL_DB ]]; then
    mkdir -p $(dirname $LOCAL_DB)
    touch $LOCAL_DB
fi

function db() {
    if [[ ! -n "$1" ]]; then
        err "no key specified"
        exit 1
    fi

    prop "$LOCAL_DB" "$@"
    if [[ -n "$2" ]]; then
        debug "saved to $LOCAL_DB"
    fi
}

function db_dump() {
    cat $LOCAL_DB
}

if [[ -n "$1" && $(MYNAME) == $CALLER ]]; then
    if [[ "$1" == -r ]]; then
        less $LOCAL_DB
        exit 0
    elif [[ "$1" == -e ]]; then
        nano $LOCAL_DB
        exit 0
    elif [[ "$1" == -x ]]; then
        shift
        db "$@"
    fi
fi