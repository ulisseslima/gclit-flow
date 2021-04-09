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
        info "maybe you want to go to $branchd ?"
    fi

    exit 1
fi

if [[ -z "$(project_url)" ]]; then
    err "coudn't determine project url, check if you are inside a git project"
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
    --estimate)
        shift
        estimate="$1"
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

name="$FEATURE_PREFIX/$(safe_name "$name")"

if [[ -z "$project_id" ]]; then
    info "no project selected. choose one:"
    read name_or_id

    project_id=$(prompt_project_id "$name_or_id")
fi

project_name="$($MYDIR/rr-find-project.sh $project_id)"
if [[ -z "$project_name" ]]; then
    err "problem finding project"
    exit 1
fi

# TODO
#if [[ -z "$estimate" ]]; then
#    info "no time estimate found, enter one [8h]"
#    read estimate
#fi

info "switching to $TARGET_BRANCH and syncing..."
git checkout $TARGET_BRANCH
git pull

if [[ $(git branch | grep -c $name) -eq 1 ]]; then
    info "feature already exists. switching to it..."
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$(repo_root)"

    git checkout $name
    git merge $TARGET_BRANCH
    git branch

    $MYDIR/rr-play.sh "$name"
    exit 0
fi

info "will start '$name' on project '$project_name'"
info "project URL: $(project_url)"
echo "<enter> to proceed, CTRL+C to abort"
read anyKey

if [[ "$(curr_branch)" != "$name" ]]; then
    info "creating git branch..."
    git checkout -b "$name"
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$(repo_root)"
else
    info "branch already created..."
fi

if [[ $REMOTE_FEATURES == true ]]; then
    info "pushing local branch to remote..."
    git push -u origin $name
fi

project_url="$(project_url)"

description="$project_url/-/tree/$name"
if [[ "$name" == *fix* ]]; then
    issue_id=$(echo $name | cut -d'-' -f2)
    if [[ $(nan $issue_id) == true ]]; then
        err "couldn't determine issue id from feature name: $name"
    fi

    description="* $description * $project_url/-/issues/$issue_id"
fi

$MYDIR/rr-new-task.sh "$name" -p $project_id --description "$description"

info "additional project info on runrun..."
$MYDIR/rr-comment.sh "started a new feature on $(project_url)"
