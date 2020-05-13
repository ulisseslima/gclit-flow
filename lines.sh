#!/bin/bash

f="${1:-/dev/stdin}"
wc -l "$f" | cut -d' ' -f1
