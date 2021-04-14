#!/bin/bash

function llog() {
    >&2 echo "$@"
}

require() {
    switch='-s'
    if [[ "$1" == *'-'* ]]; then
        switch=$1
        shift
    fi

	keyname="$1"
	value="${!keyname}"
	info="$2"

    case $switch in
        --string|-s)
            if [ ! -n "$value" ]; then
                llog "required variable has no value: $keyname = '$info'"
                exit 1
            fi
        ;;
        --file|-f)
                if [ ! -f "$value" ]; then
                    llog "an expected file was not found: '$value' (varname: $keyname) - $info"
                    exit 2
            fi
        ;;
        --dir|-d)
            if [ ! -d "$value" ]; then
                llog "an expected dir was not found: '$value' (varname: $keyname) - $info"
                exit 3
            fi
        ;;
    esac
}

#test $# -gt 0 && require "$@"
