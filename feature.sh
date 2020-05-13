#!/bin/bash
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

# push options for automatically creating a merge request
# https://docs.gitlab.com/ee/user/project/push_options.html

# use gitlab api to assign a merge request to someone
# https://github.com/gitlabhq/gitlabhq/blob/master/doc/api/merge_requests.md#create-mr

# use codes in the commit message to close issues:
# closes #123
# https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue

# https://www.reddit.com/r/git/comments/3rrzf6/should_i_ever_have_longterm_feature_branches_in/
# merge develop branch back into your feature often to avoid conflicts

# start
#git checkout develop
#git checkout -b $1

# finish
# work locally, commit but don't push unless more than one people need to work on the feature
# if you need other people to work on the feature:
# git push -u origin $1
#git checkout develop

##
# to get changes from specifica files from other branches:
# git checkout otherbranch file1 [file2 file3 ...]

##
# to keep your branch up to date with a target final branch for merging (NOTA: ainda tem que testar):
# git merge --no-ff develop

# The --no-ff flag causes the merge to always create a new commit object,
# even if the merge could be performed with a fast-forward.
# This avoids losing information about the historical existence of a feature branch
# and groups together all commits that together added the feature
#git merge --no-ff feature_branch

#git push origin develop
#git branch -d feature_branch

function find_project() {
    name_or_id="$1"

    project=$($MYDIR/rr-find-project.sh "$name_or_id")
    n=$(echo "$project" | $MYDIR/lines.sh)
    if [[ $n -gt 1 ]]; then
        $MYDIR/iterate.sh "$project" '$line [$n]'
        info "choose one [1]:"
        read one

        [[ ! -n "$one" ]] && one=1
        project=$($MYDIR/get.sh $one "$project")
        [[ ! -n "$project" ]] && project=$($MYDIR/get.sh 1 "$project")
    fi

    if [[ ! -n "$project" ]]; then
        err "could not find project '$project', try again"
        exit 1
    fi

    # return project id:
    echo $project | cut -d'=' -f1
}

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

        project_id=$(find_project "$name_or_id")
    ;;
    -*)
        echo "bad option '$1'"
        exit 1
    ;;
    esac
    shift
done

name=$(safe_name "$name")

if [[ ! -n "$project_id" ]]; then
    info "no project selected. choose one:"
    read name_or_id

    project_id=$(find_project "$name_or_id")
fi

