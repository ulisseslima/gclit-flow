#!/bin/bash -e
# @installable
# creates a local branch pointing to an already existing remote branch and switches to it
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh
source $MYDIR/db.sh
source $(real require.sh)

branch="$1"
require branch

git checkout --track origin/$branch
