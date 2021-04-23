#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

message="$1"

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd ?"
    fi
    exit 1
fi

name="$(db CURR_FEATURE)"
target=$TARGET_BRANCH
if [[ ! -n "$name" ]]; then
    err "you're not working on any features, make sure to start one with gclit-feature"
    exit 1
fi

git checkout $name

info "${name}'s conclusion message:"
if [[ -n "$message" ]]; then
    echo "$message"
else
    read message
fi

info "pushing changes..."
git add .
git commit -a -m "$message" || true
git push

$MYDIR/rr-comment.sh "pushed to $name: $message"
