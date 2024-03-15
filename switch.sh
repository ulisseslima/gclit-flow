#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV
source $MYDIR/log.sh
source $MYDIR/db.sh

project_id=1
similar="$1"

while test $# -gt 0
do
    case "$1" in
    --list|-l) 
        latest_tasks
        exit 0
    ;;
    -*) 
      echo "bad option '$1'"
      exit 1
    ;;
    esac
    shift
done

if [[ -n "$similar" ]]; then
  $MYDIR/play.sh "$(similar_task "$similar" | cut -d'|' -f2)"
else
  $MYDIR/play.sh "$(latest_task | cut -d'|' -f2)"
fi