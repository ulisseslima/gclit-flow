#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
[[ "$SETUP_DEBUG" == true ]] && debugging on
source $MYDIR/db.sh

##
# called on error
function failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

##
# assert a web address is up
function assert_is_up() {
    address="$1"
    debug "checking if $address is up..."
    curl -sSf "$address" > /dev/null
}

##
# prompt the user for an internal variable value
function prompt() {
    keyname="$1"
    message="$2"
    currval="${!keyname}"
    set=false

    while [[ ! -n "$currval" ]]
	do
		err "'$keyname' not set. what's your $message?"
		read currval
        set=true
	done

	if [[ $set == true ]]; then
        prop $LOCAL_ENV $keyname $currval
        source $LOCAL_ENV
    fi
}

##
# default task type that will be used when creating new tasks
function prompt_task_type() {
    debug "checking default task type..."
    
    if [[ ! -n "$RR_DEFAULT_TASK_TYPE" ]]; then
        info "what will be the default task type?"

        type=$($MYDIR/runrun.sh GET task_types | $MYDIR/jmap.py id name)
        n=$(echo "$type" | $MYDIR/lines.sh)
        if [[ $n -gt 1 ]]; then
            $MYDIR/iterate.sh "$type" '$line [$n]'
            info "choose one:"
            read one

            type=$($MYDIR/get.sh $one "$type")
        fi

        RR_DEFAULT_TASK_TYPE=$(echo "$type" | cut -d'=' -f1)
    fi
    
    debug "task type checked."
}

##
# selects a task from a project to start working on
function prompt_project_task() {
    info "initializing project environment..."
    if [[ -n "$(db CURR_TASK_ID)" ]]; then
        debug "resuming '$(db CURR_TASK_NAME)' ..."
        $MYDIR/rr-play.sh
    else
        info "defining current project..."
        project="$($MYDIR/rr-curr-project.sh)"
        new_project=false

        while [[ ! -n "$project" ]]
        do
            new_project=true
            info "you're not working on any project, choose one (enter name or ID):"
            read name_or_id

            info "searching..."
            project=$($MYDIR/rr-find-project.sh "$name_or_id")
            n=$(echo "$project" | $MYDIR/lines.sh)
            if [[ $n -gt 1 ]]; then
                info "found $n results that match '$name_or_id':"
                $MYDIR/iterate.sh "$project" '$line [$n]'
                info "choose one [1]:"
                read one

                [[ ! -n "$one" ]] && one=1
                project=$($MYDIR/get.sh $one "$project")
                [[ ! -n "$project" ]] && project=$($MYDIR/get.sh 1 "$project")
            fi

            info "project defined as: $project"
        done

        if [[ $new_project == true ]]; then
            while [[ ! -n "$(db CURR_TASK_ID)" ]]
            do
                info "choose a task to start working on (enter name or ID):"
                read name_or_id

                info "searching..."
                task=$($MYDIR/rr-find-task.sh "$name_or_id" "$(echo $project | cut -d'=' -f1)")
                n=$(echo "$task" | $MYDIR/lines.sh)
                if [[ $n -gt 1 ]]; then
                    info "found $n results that match '$name_or_id':"
                    $MYDIR/iterate.sh "$task" '$line [$n]'
                    info "choose one [1]:"
                    read one

                    [[ ! -n "$one" ]] && one=1
                    task=$($MYDIR/get.sh $one "$task")
                    [[ ! -n "$task" ]] && task=$($MYDIR/get.sh 1 "$task")
                fi

                info "starting work on $task ..."
                $MYDIR/rr-play.sh "$(echo $task | cut -d'=' -f1)"
            done
        fi
    fi

    if [[ ! -n "$(db CURR_TASK_ID)" ]]; then
        err "could not initialize environment"
        exit 1
    fi
    
    info "you're working on '$(db CURR_TASK_NAME)':"
    info "task: https://runrun.it/en-US/tasks/$(db CURR_TASK_ID)"
    info "project: https://runrun.it/en-US/company/projects/$(db CURR_PROJECT_ID)"
}

##
# put stuff on PATH
function install() {
    debug "updating installation..."
    uninstall

    while read script
    do
        name=$(basename $script)

        iname="$INSTALL_PREFIX-${name/.sh/}"
        iname="${iname/-rr-/-}"
        fname="/usr/local/bin/$iname"

        sudo ln -s $script $fname
        info "installed $fname ..."
    done < <(grep -l '@installable' $CLIT/* | grep -v setup)

    debug "installation finished."
}

##
# remove stuff from PATH
function uninstall() {
    # unsafe
    sudo rm /usr/local/bin/${INSTALL_PREFIX}-*
}

##
# build initial config.
function wizard() {
	debug "checking configuration..."
    
    install

    prompt USR_EMAIL "runrun email"
    prompt RR_APP_KEY "runrun API app key"
	prompt RR_U_TOKEN "runrun API user token"

    assert_is_up "$RR_URL"
    debug "$RR_URL is up"

    rr_id=$($MYDIR/runrun.sh GET "users/$(rr_user_id)" | $MYDIR/jprop.sh "['id']")
    debug "runrun id: $rr_id"

    $MYDIR/rr-find-all-projects.sh
    prompt_project_task

	debug "local settings saved to $LOCAL_ENV"
}

wizard