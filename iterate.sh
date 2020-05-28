#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"

if [[ ! -n "$1" ]]; then
	echo "iterates over lines from a variable."
	echo ""
	echo "available variables:"
	echo "i - line index, 0-based"
	echo "n - line index, 1-based"
	echo "line - line contents"
	echo "total - number of lines"
	echo ""
	echo "e.g.:"
	echo "$0 \"\$var\" '\$line [\$n/\$total]'"
	exit 1
fi

if [ ! -n "$2" ]; then
	echo "arg 2 hast to be iterator expression"
	exit 1
fi

total=$(echo "$1" | $MYDIR/lines.sh)

i=0
n=1
while read line
do
	eval >&2 echo $2
	
	i=$((i+1))
	((n++))
	
	sleep .01
done < <(echo "$1")
