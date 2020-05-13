#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

info "caching all projects..."

PROJECTS=$CACHE/projects.map
cat /dev/null > "$PROJECTS"

page=1
max_results=100
count=$max_results
total=0
while [[ $count -ge $max_results ]]
do
	debug "page: $page"
    
    query="projects?sort=name&page=$page"
    tmp="$PROJECTS.$page.tmp"

    projects=$($MYDIR/runrun.sh GET "$query")
    if [[ -n "$projects" ]]; then
        echo "$projects" | $MYDIR/jmap.py id name > "$tmp"
        cat "$tmp" >> "$PROJECTS"
        debug "$tmp"
    fi 
	
	count=$(cat "$tmp" | wc -l)
	debug "results: $count"
	
    ((total+=count))
	((page++))
done

info "$total projects cached (status: $?)"