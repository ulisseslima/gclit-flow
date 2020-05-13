#!/bin/bash

if [[ $(nan "$1") == true || "$1" -lt 1 ]]; then
	echo "arg 1 has to be index number, 1-based"
	exit 1
fi

if [ ! -n "$2" ]; then
	echo "arg 2 hast to be a list"
	exit 1
fi

echo "$2" | head -$1 | tail -1
