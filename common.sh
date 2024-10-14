#!/usr/bin/env bash
if [[ "$(basename -- "$0")" == "common.sh" ]]; then
    >&2 echo "Don't run $0, scripts source it"
    exit 1
fi

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}
