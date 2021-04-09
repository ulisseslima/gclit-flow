#!/bin/bash -e
# depends on: xmlstarlet
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $(real log.sh)

NAMESPACE='http://maven.apache.org/POM/4.0.0'

function do_select() {
    local file="$1"
    local query="$2"

    require.sh -f "$file" "arg 1 should be the pom file location"
    require.sh "$query" "arg 2 should be the xpath query, maven pom namespace prefix is 'x:'"

    xmlstarlet sel -N x=$NAMESPACE -t -v "$query" $file
}

function do_edit() {
    local file="${1}"
    local query="$2"
    local value="$3"

    currval=$(do_select "$file" "$query")
    require.sh "$value" "arg 3 should be the replacement value"

    debug "editing $file $query from $currval to $value..."
    xmlstarlet ed -L -N x=$NAMESPACE \
        -u "$query" -v "$value" \
        $file
    debug "value changed."
}

# selects project version, or parent version, if undefined.
function select_version() {
    local v=$(do_select "$1" 'x:project/x:version' || true)
    if [[ ! -n "$v" ]]; then
        debug "falling back to parent/version..."
        v=$(do_select "$1" 'x:project/x:parent/x:version')
    fi

    echo "$v"
}

function set_version() {
    local file="$1"
    local new_v="$2"

    local v=$(do_select "$file" 'x:project/x:version' || true)
    if [[ ! -n "$v" ]]; then
        debug "falling back to parent/version..."
        do_edit "$file" "x:project/x:parent/x:version" "$new_v"
    else
        do_edit "$file" "x:project/x:version" "$new_v"
    fi
}

##
# increments build version.
# if SNAPSHOT, just closes it without incrementing.
function bump_build() {
    local file="$1"
    local v=$(select_version "$file")

    if [[ "$v" == *SNAPSHOT* ]]; then
        debug "only closing snapshot..."
        new_v=${v/-SNAPSHOT/}
    else
        new_v=$(echo $v | awk -F. '{$NF+=1; OFS="."; print $0}' | sed 's/ /./g')
        debug "new version calculated as: $new_v"
    fi
    
    do_edit "$file" "x:project/x:version" "$new_v"
    echo $new_v
}

function reopen_version() {
    local file="$1"
    local v=$(select_version "$file")

    if [[ "$v" == *SNAPSHOT* ]]; then
        debug "project is already in snapshot"
    else
        new_v="$(bump_build "$file")-SNAPSHOT"
    fi

    do_edit "$file" "x:project/x:version" "$new_v"
    echo "$new_v"
}

while test $# -gt 0
do
    case "$1" in
        --verbose|-v) 
            debugging on
        ;;
        --select|-s)
            shift; f="$1"
            shift; q="$1"

            do_select "$f" "$q"
        ;;
        --edit|-e)
            shift; file="$1"
            shift; query="$1"
            shift; value="$1"

            do_edit "$file" "$query" "$value"
        ;;
        --project-version|--version)
            shift; file="$1"
            select_version "$file"
        ;;
        --set)
            shift; file="$1"
            shift; version="$1"
            set_version "$file" "$version"
        ;;
        --bump-build|-b)
            shift; f="$1"
            bump_build "$f"
        ;;
        --snap|--open|-o)
            shift; f="$1"
            reopen_version "$f"
        ;;
        -*)
            echo "bad option '$1'"
        ;;
    esac
    shift
done