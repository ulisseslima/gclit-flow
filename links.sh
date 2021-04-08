#!/bin/bash -e
# @installable
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

branch="$(curr_branch)"
project_url=$(project_url)

if [[ ! -n "$branch" ]]; then
    err "you have to be inside the repository directory"

    branchd="$(db CURR_FEATURE_DIR)"
    if [[ -d "$branchd" ]]; then
        info "maybe you want to go to $branchd?"
    fi
    exit 1
fi

info "project:"
echo "$project_url"
echo ""

if [[ $project_url == *gitlab* ]]; then
    info "branch:"
    echo "$project_url/-/tree/$branch"
    echo ""

    info "merge request:"
    echo "$project_url/-/merge_requests/new?merge_request%5Bsource_branch%5D=$branch"
else
    info "branch:"
    echo "$project_url/tree/$branch"
fi
echo ""

if [[ "$branch" == *fix* ]]; then
    issue_id=$(echo $branch | cut -d'-' -f2)
    if [[ $(nan $issue_id) == true ]]; then
        err "couldn't determine issue id from branch name: $branch"
        exit 1
    fi

    info "issue:"
    if [[ $project_url == *gitlab* ]]; then
        echo "$project_url/-/issues/$issue_id"
    else
        echo "$project_url/issues/$issue_id"
    fi
fi
echo ""