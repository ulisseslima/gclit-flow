#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

# e.g. get column definition
$MYDIR/psql.sh "
SELECT  
    f.attname::text AS col
FROM pg_attribute f  
JOIN pg_class c ON c.oid = f.attrelid  
WHERE c.relname = 'tasks'
;"