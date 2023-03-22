#!/bin/bash -e
# @installable
# creates a "fix" type feature for working on issues
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

issue_id="$1"
if [[ $(nan "$issue_id") == true ]]; then
    err "arg 1 must be only the issue number"
    exit 1
fi

issue_tag="$2"
$MYDIR/feature.sh --name "fix #${issue_id} $issue_tag"
