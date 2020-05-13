#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

function runrun() {
	method="$1"; shift
	endpoint="$1"; shift
	body="$1"; shift
	#[[ -n "$body" ]] && body=" -d '${body//\"/\\\"}'"

	curl_opts="-s"
	if [[ $(debugging) == on ]]; then
		curl_opts='-v'
    fi

	debug "$curl_opts -X $method $RR_API/$endpoint"
	debug "$(rr_header_app_key)"
	debug "$(rr_header_usr_token)"
	debug "body: $body"

	if [[ -f "$body" ]]; then
		curl $curl_opts -X $method "$RR_API/$endpoint" -d "@$body"\
			-H "Content-Type: application/json"\
			-H "$(rr_header_app_key)"\
			-H "$(rr_header_usr_token)"
	elif [[ -n "$body" ]]; then
		curl $curl_opts -X $method "$RR_API/$endpoint" -d "$body"\
			-H "Content-Type: application/json"\
			-H "$(rr_header_app_key)"\
			-H "$(rr_header_usr_token)"
	else
		curl $curl_opts -X $method "$RR_API/$endpoint"\
			-H "$(rr_header_app_key)"\
			-H "$(rr_header_usr_token)"
	fi
}

## TODO
# cache responses
response=$(runrun "$@")

out="$CACHE/$1-$2.json"
mkdir -p $(dirname "$out")

echo "$response" > "$out"
debug "response cached to $out"

if [[ "$response" == *html* ]]; then
	err "$response"
fi

echo "$response"