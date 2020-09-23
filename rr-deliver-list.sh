#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh

input="$1"
if [[ ! -f "$input" ]]; then
    echo "arg 1 must be an input file containing a list of task ids"
    exit 1
fi

info "delivering all tasks from:"
wc -l $input

while read task
do
    id=$(echo "$task" | cut -d'=' -f1)
    $MYDIR/rr-deliver-task.sh $id
done < $input

info "list delivered"