#!/bin/bash
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

logf="$LOGF"
if [[ -z "$logf" ]]; then
    >&2 echo "env var LOGF must be defined"
    exit 1
fi

logd="$(dirname $logf)"
if [ ! -d $logd ]; then
    mkdir -p "$logd"
fi

function debugging() {
    verbose=${1}

    confd="/tmp/log-$(basename $logf).conf.d"

    debugf="$confd/debug"
    if [ ! -f $debugf ]; then
        mkdir -p "$(dirname $debugf)"
        echo off > $debugf
        debug "all logs are saved to $LOGF"
    fi


    if [[ -n "$verbose" ]]; then
        echo $verbose > $debugf
    else
        cat $debugf
    fi
}

function log() {
    level="$1"
    shift

    indicator="$1"
    shift

	if [[ "$1" == '-n' ]]; then
		echo ""
		shift
	fi

    if [[ $level == DEBUG && $(debugging) == on || $level != DEBUG ]]; then
        echo -e "$indicator $(now.sh -t) - ${FUNCNAME[2]}@${BASH_LINENO[1]}/$level: $@"
    fi
    echo -e "$MYSELF - $indicator $(now.sh -dt) - ${FUNCNAME[2]}@${BASH_LINENO[1]}/$level: $@" >> $logf
}

function info() {
    >&2 log INFO '###' "$@"
}

function err() {
    >&2 log ERROR '!!!' "$@"
}

function debug() {
    >&2 log DEBUG '>>>' "$@"
}

for var in "$@"
do
    case "$var" in
        --verbose|--debug|-v)
            shift
            echo "debug is on"
            debugging on
        ;;
        --quiet|-q)
            shift
            debugging off
        ;;
    esac
done
