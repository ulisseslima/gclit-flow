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
    err "you're not working on a feature, make sure to start one with gclit-feature"
    exit 1
fi

if [[ "$PWD" != $(db CURR_FEATURE_DIR) ]]; then
    err "feature '$name' was started on another repo:"
    db CURR_FEATURE_DIR
    exit 1
fi

git checkout $name

if [[ -z "$message" ]]; then
    if [[ "$name" == *fix* ]]; then
        issue_id=$(echo $name | cut -d'-' -f2)
        if [[ $(nan $issue_id) == true ]]; then
            err "couldn't determine issue id from branch name: $name"
            exit 1
        fi
        message="closes #$issue_id"
    else
        err "arg 1 must be ${name}'s conclusion message"
        exit 1
    fi
fi
debug "delivery message: '$message'"

echo "$(date)" > v

$MYDIR/commit.sh "$message"
if [[ $mr == true && $(project_url) == *gitlab* ]]; then
    $MYDIR/merge-request.sh "$@"
fi
$MYDIR/sync.sh
$MYDIR/push.sh "$message"

if [[ $mr == false || $(project_url) == *github* ]]; then
    info "merging directly to $target ..."
    git checkout $target
    git pull
    git merge --no-ff "$name"
    git add .
    git commit -a -m "$message" || true
    git push
fi

if [[ $FEATURE_DELETE_WHEN_DELIVERED == true ]]; then
    info "backing up '$name' ..."
    cp -r $(repo_root) /tmp

    info "deleting '$name' branch..."
    git checkout $target
    git branch -d "$name"
else
    info "delete local branch with: git checkout $target; git branch -d $name"
fi

info "ending '$name' task..."
$MYDIR/rr-deliver-task.sh

info "'$name' delivered. exit status: $?"
