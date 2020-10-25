#!/bin/bash
# @installable
# screen lock/unlock monitor based on gnome screen saver
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

function install() {
    log "installing lock screen monitor..."
}

function monitor() {
    debug "monitoring lock screen..."
    dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" | \
    ( while true
    do read X
        debug "received screen saver signal: $X"

        if echo $X | grep "boolean true" &> /dev/null; then
            debug "screen locked"
            $MYDIR/rr-pause.sh || $MYDIR/local-play.sh pause
        elif echo $X | grep "boolean false" &> /dev/null; then
            debug "unlocked screen..."
            $MYDIR/rr-play.sh || $MYDIR/local-play.sh || true
            $MYDIR/notify.sh "task was automatically resumed!"
        fi
    done )
}

function disabled() {
    debug "script disabled"
}
trap 'disabled' EXIT

monitor