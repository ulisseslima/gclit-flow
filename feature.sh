#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

if [[ ! -n "$(curr_branch)" ]]; then
    err "you have to be inside the repository directory"
    exit 1
fi

if [[ "$1" != '-'* ]]; then
    name="$1"; shift
fi

project_id="$(db CURR_PROJECT_ID)"

while test $# -gt 0
do
    case "$1" in
    --name|-n)
        shift
        name="$1"
    ;;
    --project|-p)
        shift
        name_or_id="$1"

        project_id=$(prompt_project_id "$name_or_id")
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

name="$FEATURE_PREFIX/$(safe_name "$name")"

if [[ ! -n "$project_id" ]]; then
    info "no project selected. choose one:"
    read name_or_id

    project_id=$(prompt_project_id "$name_or_id")
fi

project_name="$($MYDIR/rr-find-project.sh $project_id)"
if [[ ! -n "$project_name" ]]; then
    err "problem finding project"
    exit 1
fi

info "will start '$name' on project '$project_name', proceed?"
read anyKey

git checkout -b "$name"
db CURR_BRANCH "$name"
db CURR_BRANCH_DIR "$PWD"

if [[ $REMOTE_FEATURES == true ]]; then
    git push -u origin $name
fi

$MYDIR/rr-new-task.sh "$name"