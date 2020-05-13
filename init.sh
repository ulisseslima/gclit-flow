#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
[[ "$SETUP_DEBUG" == true ]] && debugging on

#git branch develop
#git push -u origin develop
#git checkout develop

echo 'OK!'
