#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

wip=false
description="auto generated by gclit"

if [[ "$1" != '-'* ]]; then
    # message was passed directlty as first arg with no prefix
    message="$1"; shift
fi

while test $# -gt 0
do
    case "$1" in
    --message|-m)
        shift
        message="$1"
    ;;
    --wip)
        wip=true
    ;;
    --label)
        shift
        label="$1"
    ;;
    --description|-d)
        shift
        description="$1"
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

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

while [[ ! -n "$label" ]]; do
    info "choose a label:"
    read label
done

info "#$label - creating request to merge back to $target ..."
git checkout $name

while [[ ! -n "$message" ]]; do
    info "${name}'s MR message:"
    read message
done
debug "MR message: '$message'"

if [[ $wip == true ]]; then
    message="[WIP] $message"
    info "WIP prefix added"
fi

# https://docs.gitlab.com/ee/user/project/push_options.html
git push \
    -o merge_request.create \
    -o merge_request.target=$target \
    -o merge_request.remove_source_branch \
    -o merge_request.title="$message" \
    -o merge_request.description="$description" \
    -o merge_request.label="$label"

$MYDIR/rr-comment.sh "opened MR to $target"
