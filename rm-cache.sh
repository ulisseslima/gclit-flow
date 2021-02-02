#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh
source $(real require.sh)

resource="$1"
require resource

if [[ ! -f "$resource" ]]; then
    if [[ ! -d "$resource" ]]; then
        err "'$resource' is not a file or directory"
        exit 1
    fi
fi

info "checking exclusion rules for $resource ..."
r=$(git check-ignore -v -- $resource)
if [[ -n "$r" ]]; then
    err "$resource is already checked"
    echo "$r"
    exit 1
fi

info "removing $resource from cache ..."
git rm -r --cached $resource

info "re-checking exclusion rules for $resource ..."
git check-ignore -v -- $resource
