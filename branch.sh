#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

if [[ -z "$(curr_branch)" ]]; then
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
    # name was passed directly as first arg with no prefix
    name="$1"; shift
fi

# sync with target branch before creating the new one
sync=true

while test $# -gt 0
do
    case "$1" in
    --name|-n)
        shift
        name="$1"
    ;;
    --sync-later|--no-sync)
        sync=false
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

name=$(safe_name "$name")

TARGET_BRANCH=$(curr_branch)
if [[ "$sync" == true ]]; then
	info "switching to $TARGET_BRANCH and syncing..."
	git checkout $TARGET_BRANCH
	git pull
fi

if [[ $(git branch | grep -c $name) -eq 1 ]]; then
    info "branch already exists. switching to it..."
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$(repo_root)"

    git checkout $name
    git merge $TARGET_BRANCH
    git branch

    exit 0
fi

info "will start '$name' branch, with target branch '$TARGET_BRANCH'"
info "project URL: $(project_url)"
echo "<enter> to proceed, CTRL+C to abort"
read anyKey

if [[ "$(curr_branch)" != "$name" ]]; then
    info "creating git branch..."
    git checkout -b "$name"
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$(repo_root)"
    db CURR_FEATURE_TARGET_BRANCH "$TARGET_BRANCH"
else
    info "branch already created..."
fi

if [[ $REMOTE_FEATURES == true ]]; then
    info "pushing local branch to remote..."
    git push -u origin $name
    git branch --set-upstream-to=origin/$name $name
fi
