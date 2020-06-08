#!/bin/bash

f="${1:-/dev/stdin}"
if [[ ! -f "$f" ]]; then
	tmp=/tmp/lines.f
	echo "$f" > $tmp
	f=$tmp
fi

wc -l "$f" | cut -d' ' -f1
rm -f "$tmp"