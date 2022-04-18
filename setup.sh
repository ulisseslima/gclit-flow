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
        $MYDIR/rr-play.sh || true
    else
        info "defining current project..."
        project="$($MYDIR/rr-sync-project.sh)"
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
                task=$($MYDIR/rr-find-task.sh "$name_or_id" --project "$(echo $project | cut -d'=' -f1)")
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
                $MYDIR/rr-play.sh "$(echo $task | cut -d'=' -f1)" || true
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
        fname="/usr/local/bin/$iname"

        sudo ln -s $script $fname
        info "installed $fname ..."
    done < <(grep -l '@installable' $CLIT/* | grep -v setup)

    info "installation finished."
}

##
# remove stuff from PATH
function uninstall() {
    # unsafe
    sudo rm -f /usr/local/bin/${INSTALL_PREFIX}-*
}

function local_db() {
    info "checking if dpkg is available..."
    [[ ! -n "$(which dpkg)" ]] && return 0
    
    info "checking if postgresql client is available..."
    [[ "$(dpkg -l | grep -c postgresql-client)" -lt 1 ]] && return 0

    info "checking if postgresql server is available..."
    [[ "$(dpkg -l | grep postgresql | grep -c server)" -lt 1 ]] && return 0

    info "checking if db already created..."
    if [[ -n "$($MYDIR/psql.sh 'select id from tasks limit 1')" ]]; then
        info "database already created."
    else
        info "we detected you have a postgresql server. do you want to enable a local timesheet? (Y/n)"
        read answer

        # defaults to yes
        [[ ! -n "$answer" ]] && answer=y

        # if answer (to lower case) starts with "y", continue installation
        [[ ${answer,} != y* ]] && return 0

        info "creating database..."
        $MYDIR/psql.sh --create-db
        $MYDIR/psql.sh $MYDIR/db/timesheet.sql

        info "creating default project..."
        $MYDIR/psql.sh "insert into projects (name) select 'default'"

        info "mapping default project..."
        row=$($MYDIR/psql-map.sh projects 'id,name' "name='default'")
        echo $row

        if [[ ! -n "$row" ]]; then
            err "could not complete local db installation"
            exit 1
        fi

        db DB_ENABLED yes
        info "local task creation enabled"
    fi
}

##
# check pre requisites
function check_requirements() {
    check_installed python --version
    check_installed xmlstarlet --version
}

##
# build initial config.
function wizard() {
	info "checking configuration..."

    check_requirements
    install

    prompt RR_ENABLED "enable RunRun integration? [true|false]"
    if [[ true == "$RR_ENABLED" ]]; then
        prompt RR_EMAIL "runrun email"
        prompt RR_APP_KEY "runrun API app key"
        prompt RR_U_TOKEN "runrun API user token"

        assert_is_up "$RR_URL"
        info "$RR_URL is up"

        rr_id=$($MYDIR/runrun.sh GET "users/$(rr_user_id)" | $MYDIR/jprop.sh "['id']")
        info "runrun id: $rr_id"

        $MYDIR/rr-find-all-projects.sh
        prompt_project_task
    fi
    
    prompt GITLAB_TOKEN "gitlab API personal access token"
    prompt GITLAB_API "gitlab API base URL"

    local_db

	info "local settings saved to $LOCAL_ENV"
}

wizard