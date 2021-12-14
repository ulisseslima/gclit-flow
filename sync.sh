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

while test $# -gt 0
do
    case "$1" in
    --target)
        shift
        target="$1"
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

[[ -z "$target" ]] && target=$(db CURR_FEATURE_TARGET_BRANCH)
require target
info "syncing with $target ..."

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd ?"
    fi
    exit 1
fi

current=$(db CURR_FEATURE)
info "... from $current"

git checkout $target
git pull
git checkout $current
git merge $target
if [[ $(git status | grep -ci 'Your branch is ahead' || true) -gt 0 ]]; then
    info "detected $current ahead of $target, pushing changes"
    git push
fi

info "$current is synced with $target"

$MYDIR/rr-comment.sh "synced to $target"
