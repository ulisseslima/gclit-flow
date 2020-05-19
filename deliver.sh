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
mr=${2:-true}

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd?"
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

$MYDIR/commit.sh "$message"
if [[ $mr == true ]]; then
    $MYDIR/merge-request.sh "$message" false
fi
$MYDIR/sync.sh
$MYDIR/push.sh "$message"
