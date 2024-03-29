#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

message=''
mr=true

while test $# -gt 0
do
    case "$1" in
    --message|-m)
        shift
        message="$1"
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

name="$(db CURR_FEATURE)"
target=$(db CURR_FEATURE_TARGET_BRANCH)
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
            #exit 1
        else
            message="closes #$issue_id"
        fi
    fi
fi

info "delivery message: '$message'"

# TODO work with github origin/main
info "will deliver feature '$name' into target branch '$target'"
info "## closes"
git log HEAD...origin/$target | grep -i closes | sort -fu
info "confirm?"
read confirmation

# FIXME in case there is nothing to push
#echo "$(date)" > v
#git add v
#git commit -m 'gclit merge request f'

#$MYDIR/commit.sh "$message"
if [[ $mr == true && $(project_url) == *gitlab* ]]; then
    $MYDIR/merge-request.sh --message "$message" --target "$target"
fi
$MYDIR/sync.sh --target "$target"
#$MYDIR/push.sh "$message"

if [[ $mr == false || $(project_url) == *github* ]]; then
    info "merging directly to $target ..."
    git checkout $target
    git pull
    git merge --no-ff "$name"
    git add .
    git commit -a -m "$message" || true
    git push
fi

info "ending '$name' task..."
$MYDIR/rr-deliver-task.sh

if [[ $FEATURE_DELETE_WHEN_DELIVERED == true ]]; then
    info "backing up '$name' ..."
    tmp=/tmp/git/$(repo_root)
    mkdir -p $tmp
    cp -r $(repo_root)/* $tmp

    info "deleting '$name' branch..."
    git checkout $target
    git branch -d "$name"
    git pull
else
    info "delete local branch with: git checkout $target; git branch -d $name"
fi

info "'$name' delivered. exit status: $?"
