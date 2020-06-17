#!/bin/bash -e
# queries the local database
X=$(dirname `readlink -f ${BASH_SOURCE[0]}`)
source $X/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $X/log.sh
source $X/prop.sh

MYSELF() { readlink -f "${BASH_SOURCE[0]}"; }
MYDIR() { echo "$(dirname $(MYSELF))"; }
MYNAME() { echo "$(basename $(MYSELF))"; }
CALLER=$(basename `readlink -f $0`)

separator="|"

query="$1"; shift
if [[ ! -n "$query" ]]; then
    err "arg 1 must be the query"
    exit 1
fi

if [[ "$query" == --create-db ]]; then
    info "starting db $DB_NAME ..."
    psql -U $DB_USER -c "create database $DB_NAME"
    exit 0
fi

connection="psql -U $DB_USER $DB_NAME"
ops='qAtX'

while test $# -gt 0
do
    case "$1" in
    --separator|-s)
        shift
        separator="$1"
    ;;
    --ops)
        shift
        ops="$1"
    ;;
    --full)
        ops="c1"
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

if [[ -f "$query" ]]; then
    $connection -$ops -F"$separator" < "$query"
else
    $connection -$ops -F"$separator" -c "$query"
fi