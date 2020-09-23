#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

f=$(find $CACHE -type f -printf '%T@ %p\n' | sort -n | grep response | tail -1 | cut -f2- -d" ")
echo "$f"
cat $f | json_pp -json_opt pretty,utf8 | less