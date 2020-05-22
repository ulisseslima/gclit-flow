#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

STORE=$CACHE/projects.map

regex="$1"
if [[ ! -n "$regex" ]]; then
    err "arg 1 must the the search string (canse insensitive, regex) or ID"
    exit 1
fi
shift

while test $# -gt 0
do
    case "$1" in
    --refresh|-r)
        rm -f $STORE
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

if [[ ! -f $STORE ]]; then
    $MYDIR/rr-find-all-projects.sh
fi

grep -iP "$regex" $STORE || true