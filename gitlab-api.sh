#!/bin/bash -e
MYSELF="$(readlink -f "$0")"
MYDIR="${MYSELF%/*}"
ME=$(basename $MYSELF)

source $MYDIR/env
[[ -f $LOCAL_ENV ]] && source $LOCAL_ENV 
source $MYDIR/log.sh

function gitlab() {
	method="$1"; shift
	endpoint="$1"; shift
	body="$1"; shift

	curl_opts="--progress-bar"
	if [[ $(debugging) == on ]]; then
		curl_opts='-v'
    fi

	debug "$curl_opts -X $method $GITLAB_API/$endpoint"
	debug "$(gitlab_header_token)"
	debug "body: $body"

	request_cache="$CACHE/$1-$2.request.json"
	if [[ -f "$body" ]]; then
		cp "$body" $request_cache

		curl $curl_opts -X $method "$GITLAB_API/$endpoint"\
			-d "@$body"\
			-H "Content-Type: application/json"\
			-H "$(gitlab_header_token)"
	elif [[ -n "$body" ]]; then
		echo "$body" > $request_cache

		curl $curl_opts -X $method "$GITLAB_API/$endpoint"\
			-d "$body"\
			-H "Content-Type: application/json"\
			-H "$(gitlab_header_token)"
	else
		curl $curl_opts -X $method "$GITLAB_API/$endpoint"\
			-H "$(gitlab_header_token)"
	fi

	# TODO incluir content type
	request_debug="curl $curl_opts -X $method '$GITLAB_API/$endpoint' -H '$(gitlab_header_token)'"
	debug "request: $request_debug"
}

# cache responses
response=$(gitlab "$@")
error=true
if [[ -z "${response}" ]]; then
	err "no response from gitlab for request: $request_debug"
elif [[ "${response,,}" == *'401 unauthorized'* ]]; then
	err "$response"
	err "request: $request_debug"
elif [[ "$response" == *html* ]]; then
	err "$response"
else
	error=false
fi

if [[ $error != true ]]; then
	out="$CACHE/$1-$2.response.json"
	mkdir -p $(dirname "$out")

	echo "$response" > "$out"
	debug "response cached to $out"
fi

echo "$response"