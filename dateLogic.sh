#!/usr/bin/env bash
if [[ "$(basename -- "$0")" == "dateLogic.sh" ]]; then
    >&2 echo "Don't run $0, scripts source it"
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "$DIR/common.sh"

rfc33382iso() {
    date -d "$1" +%s
}

nowOptional() {
    now=${1:-}
    if [ -z "$now" ]; then
        now=$(date +%s)
    fi
    echo "$now"
}
renderTimeAgo () {
    date=${1:-}
    now=$(nowOptional "$2")
    timeAgo=$(( "$now" - "$date" ))
    secondsInHour=$((60 * 60))
    secondsInDay=$((secondsInHour * 24))
    if [[ "$timeAgo" -gt "$secondsInDay" ]]; then
        echo -n "$(( timeAgo / secondsInDay )) days "
    fi
    if [[ "$timeAgo" -gt "$secondsInHour" ]]; then
        echo -n "$(( timeAgo / secondsInHour % 24)) hours "
    fi
    echo "$(( timeAgo / 60 % 60)) minutes ago"
}

renderDateAndTimeAgo () {
    date=${1:-}
    now=$(nowOptional "$2")
    echo "$(date -d "@$date" --rfc-3339=s) or $(renderTimeAgo "$now" "$date")"
}


# hours
# minutes
# day of week
# now (optional) unix
calculateMostRecentSchedule() {
    h=$1
    m=$2
    d=$3
    now=$(nowOptional "$4")
    msg "getting most recent dose for $h $m $d at $now"
    #if [[ "$d" =~ ^[0-9]+-[0-9]+$ ]]; then
    #    low=${BASH_REMATCH[1]}
    #    high=${BASH_REMATCH[1]}
    #    dayOfWeek=$(date +%u)
    #    #if ((number >= 2 && number <= 5)); then
    #fi
    if [[ "$d" == "*" ]]; then
        lastSchedule=$(date -d "TZ=\"$(date +%z)\" $(date -d @"$now" +%F) $h:$m" +%s)
        if (( lastSchedule > now )); then
            # in future, use yesterday
            lastSchedule=$(date -d "$(date -d "@$lastSchedule") - 1 day" +%s)
        fi
    fi
    echo "$lastSchedule"
}
