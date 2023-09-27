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
    # name was passed directly as first arg with no prefix
    name="$1"; shift
fi

project_id="$(db CURR_PROJECT_ID)"
literal_name=false
# sync with target branch before creating the new one
sync=true

while test $# -gt 0
do
    case "$1" in
    --name|-n)
        shift
        name="$1"
    ;;
    --literal)
        literal_name=true
    ;;
    --sync-later|--no-sync)
        sync=false
    ;;
    --project|-p)
        shift
        
        # name_or_id="$1"
        # project_id=$(prompt_project_id "$name_or_id")
        project_id="$1"
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

if [[ -z "$project_id" ]]; then
    project_id=1
fi

if [[ $literal_name != true ]]; then
    name="$FEATURE_PREFIX/$(safe_name "$name")"
fi

if [[ "$RR_ENABLED" == true ]]; then
    project_name="$($MYDIR/rr-find-project.sh $project_id)"
    if [[ -z "$project_name" ]]; then
        err "problem finding project"
        exit 1
    fi
else
    project_name=$($MYDIR/psql.sh "select name from projects where id = $project_id")
fi

# TODO
#if [[ -z "$estimate" ]]; then
#    info "no time estimate found, enter one [8h]"
#    read estimate
#fi

TARGET_BRANCH=$(curr_branch)
if [[ "$sync" == true ]]; then
	info "switching to $TARGET_BRANCH and syncing..."
	git checkout $TARGET_BRANCH
	git pull
fi

if [[ $(git branch | grep -c $name) -eq 1 ]]; then
    info "feature already exists. switching to it..."
    db CURR_FEATURE "$name"
    db CURR_FEATURE_DIR "$(repo_root)"

    git checkout $name
    git merge $TARGET_BRANCH
    git branch

    $MYDIR/play.sh "$name"
    exit 0
fi

info "will start '$name' on project '$project_name', with target branch '$TARGET_BRANCH'"
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

project_url="$(project_url)"

if [[ "$RR_ENABLED" == true ]]; then
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
else
    $MYDIR/play.sh "$name"
fi
