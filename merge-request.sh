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

info "merge request..."
debug "options: $@"

if [[ $# -gt 0 && "$1" != '-'* ]]; then
    # message was passed directly as first arg with no prefix
    message="$1"
    shift
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

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd ?"
    fi
    exit 1
fi

[[ -z "$target" ]] && target=$TARGET_BRANCH
info "target branch: $target"

name="$(db CURR_FEATURE)"
if [[ ! -n "$name" ]]; then
    err "you're not working on any features, make sure to start one with gclit-feature"
    exit 1
fi

while [[ -z "$label" ]]; do
    if [[ -n "$DEFAULT_MR_LABEL" ]]; then
        label="$DEFAULT_MR_LABEL"
    else
        info "choose merge request label:"
        read label
    fi
done

info "#$label - creating request to merge back to $target ..."
git checkout $name

while [[ ! -n "$message" ]]; do
    info "${name}'s MR message (new line then ctrl+d to finish):"
    readarray -t msg
    message=$(printf '%s\n' "${msg[@]}")
done

debug "MR message: '$message'"

if [[ $wip == true ]]; then
    message="[WIP] $message"
    info "WIP prefix added"
fi

# TODO merge request is not opened if all changes are already pushed

# https://docs.gitlab.com/ee/user/project/push_options.html
# TODO redirecionar todo output e grep 'remote: View merge request for' e já abrir o link localmente
git push \
    -o merge_request.create \
    -o merge_request.target=$target \
    -o merge_request.remove_source_branch \
    -o merge_request.title="$message" \
    -o merge_request.description="$description" \
    -o merge_request.label="$label"

debug "mr comment"
$MYDIR/rr-comment.sh "opened MR to $target" || true
