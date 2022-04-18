#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

if [[ "$RR_ENABLED" != true ]]; then
    err "run run is not enabled"
    exit 1
fi

while test $# -gt 0
do
    case "$1" in
    --id)
        shift
        id=$1
    ;;
    --comment|-c)
      shift
      comment="$1"
    ;;
    -*) 
      echo "bad option '$1'"
    ;;
    esac
    shift
done

if [[ -z "$id" ]]; then
    id="$(db CURR_TASK_ID)"
fi
name="$(db CURR_TASK_NAME)"

if [[ $(nan "$id") == true ]]; then
    err "--id must be the task id"
fi

if [[ $(nan "$id") == true ]]; then
    info "no tasks were running"
    exit 0
fi

info "pausing task #$id ..."

json=$($MYDIR/runrun.sh POST "tasks/$id/pause")
if [[ "$json" == *'already paused'* ]]; then
    # TODO pesquisar em andamento se não for essa
    info "'$name' was already paused!"
    exit 1
elif [[ "$json" == *'error'* ]]; then
    err "error pausing '$name'!"
    echo "$json"
else
    info "'$name' paused."
    $MYDIR/play.sh --pause
fi

if [[ -n "$comment" ]]; then
    $MYDIR/rr-comment.sh "$comment"
fi
