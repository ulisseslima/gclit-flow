#!/bin/bash -e
# turns a query into a map. e.g.: ./psql-map.sh tasks "id,name,elapsed" "name='barsd'"
X=$(dirname `readlink -f ${BASH_SOURCE[0]}`)
source $X/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $X/log.sh
source $X/prop.sh

MYSELF() { readlink -f "${BASH_SOURCE[0]}"; }
MYDIR() { echo "$(dirname $(MYSELF))"; }
MYNAME() { echo "$(basename $(MYSELF))"; }
CALLER=$(basename `readlink -f $0`)

table="$1"
if [[ ! -n "$table" ]]; then
    err "arg 1 must be the table"
    exit 1
fi

cols="$2"
if [[ ! -n "$cols" ]]; then
    err "arg 1 must be the cols"
    exit 1
fi

condition="${3:-1=1}"

row=$($X/psql.sh "select $cols from $table where $condition" -s '|')
if [[ -n "$row" ]]; then
    IFS='|' read -r -a array <<< "$row"

    key="${array[0]}"; unset "array[0]"
    echo "$key=${array[@]}"
fi