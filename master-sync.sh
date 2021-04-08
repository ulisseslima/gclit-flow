#!/bin/bash -e
# @installable
# sync current branch with master
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

target=master
currbranch=$(curr_branch)
if [[ ! -n "$currbranch" ]]; then
    err "you have to be inside the repository directory"
    exit 1
fi

info "syncing '$currbranch' with $target ..."

git checkout "$target"
git pull
git checkout "$currbranch"
git merge "$target"

$MYDIR/rr-comment.sh "synced '$currbranch' with $target"
