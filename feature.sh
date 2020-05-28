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
    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd?"
    fi

    exit 1
fi

if [[ "$1" != '-'* ]]; then
    # name was passed directlty as first arg with no prefix
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
    --like)
        shift
        lid=$1
        task=$($MYDIR/runrun.sh GET "tasks/$lid")
        if [[ ! -n "$task" ]]; then
            err "task #$lid not found"
            exit 1
        fi
        
        project_id=$(echo "$task" | $MYDIR/jprop.sh "['project_id']")
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

info "will start '$name' on project '$project_name'"
info "project URL: $(project_url)"
echo "<enter> to proceed, CTRL+C to abort"
read anyKey

if [[ "$(curr_branch)" != "$name" ]]; then
    info "creating git branch..."
    git checkout -b "$name"
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$PWD"
else
    info "branch already created..."
fi

if [[ $REMOTE_FEATURES == true ]]; then
    info "pushing local branch to remote..."
    git push -u origin $name
fi

$MYDIR/rr-new-task.sh "$name" -p $project_id

info "additional project info on runrun..."
$MYDIR/rr-comment.sh "started a new feature on $(project_url)"
