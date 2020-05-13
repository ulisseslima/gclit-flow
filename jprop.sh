#!/bin/bash

cat /dev/stdin | python -c "import sys, json; print json.load(sys.stdin)$1"