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

require TARGET_BRANCH
target=$TARGET_BRANCH
info "syncing with $target ..."

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd?"
    fi
    exit 1
fi

current=$(db CURR_FEATURE)

git checkout $target
git pull
git checkout $current
git merge $target

$MYDIR/rr-comment.sh "synced to $target"
