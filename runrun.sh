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

	curl_opts="--progress-bar"
	if [[ $(debugging) == on ]]; then
		curl_opts='-v'
    fi

	debug "$curl_opts -X $method $RR_API/$endpoint"
	debug "$(rr_header_app_key)"
	debug "$(rr_header_usr_token)"
	debug "body: $body"

	request_cache="$CACHE/$1-$2.request.json"
	if [[ -f "$body" ]]; then
		cp "$body" $request_cache

		curl $curl_opts -X $method "$RR_API/$endpoint"\
			-d "@$body"\
			-H "Content-Type: application/json"\
			-H "$(rr_header_app_key)"\
			-H "$(rr_header_usr_token)"
	elif [[ -n "$body" ]]; then
		echo "$body" > $request_cache

		curl $curl_opts -X $method "$RR_API/$endpoint"\
			-d "$body"\
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

out="$CACHE/$1-$2.response.json"
mkdir -p $(dirname "$out")

echo "$response" > "$out"
debug "response cached to $out"

if [[ "$response" == *html* ]]; then
	err "$response"
fi

echo "$response"