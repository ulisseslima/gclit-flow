#!/bin/bash
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

message="$1"
debug "notify: $message"
notifier=$(which notify-send)

if [[ -f "$notifier" ]]; then
    $notifier "gclit-fow - $message"
else
    err "notify-send not available"
fi
