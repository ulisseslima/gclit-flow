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

echo "$(date)" > v

$MYDIR/commit.sh "$message"
if [[ $mr == true && $(project_url) == *gitlab* ]]; then
    $MYDIR/merge-request.sh "$message" false
fi
$MYDIR/sync.sh
$MYDIR/push.sh "$message"

if [[ $mr == false || $(project_url) == *github* ]]; then
    info "merging directly to $target ..."
    git checkout $target
    git pull
    git merge --no-ff "$name"
    git add .
    git commit -a -m "$message" && git push

    info "deleting '$name' branch..."
    git branch -d "$name"
fi

info "ending '$name' task..."
$MYDIR/rr-deliver-task.sh

info "'$name' delivered. exit status: $?"
