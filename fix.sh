#!/bin/bash -e
# @installable
# TODO criar no padrão fix/issueId-issueName, receber apenas issue id
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

$MYDIR/feature.sh --name "fix #${issue_id}"
