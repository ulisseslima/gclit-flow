#!/usr/bin/python -tt
###
# gets a single property from a json array
##

import sys, json
j = json.load(sys.stdin)
prop = sys.argv[1]

for item in j:
    print(item[prop])