#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "$DIR/common.sh"

# shellcheck disable=SC2120
help () {
    # if arguments, print them
    [ $# == 0 ] || echo "$*"

    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") drugfile
    print out drugs currently needed to be taken
Available options:
  -h, --help       display this help and exit
EOF

    # if args, exit 1 else exit 0
    [ $# == 0 ] || exit 1
    exit 0
}

# getopt short options go together, long options have commas
TEMP=$(getopt -o h --long help -n "$0" -- "$@")
#shellcheck disable=SC2181
if [ $? != 0 ] ; then
    die "something wrong with getopt"
fi
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -h|--help) help ;;
        --) shift ; break ;;
        *) die "issue parsing args, unexpected argument '$0'!" ;;
    esac
done

drug=${1:-}
if [ -f "$drug" ]; then
    help "need to pass in schedule file as arg 1"
fi
shift

schedules=$(awk '/^s:/{ gsub(/^s:[ \t]+/, ""); print}; /^={4,}$/{exit}' "$drug")
lastLog=$(tail -n1 "$drug")
# shellcheck disable=SC2001
lastLogDate=$(rfc33382iso "$(echo "$lastLog" | sed -n 's/^\[[x ]\]\s\+\([^ T]\+[ T]\S\+\).*/\1/p')")


while IFS= read -r schedule; do
    scheduleHour=$(echo "$schedule" | perl -lane 'print "@F[0]"')
    scheduleMinute=$(echo "$schedule" | perl -lane 'print "@F[1]"')
    scheduleDay=$(echo "$schedule" | perl -lane 'print "@F[2]"')
    reminderCount=$(echo "$schedule" | perl -lane 'print "@F[3]"')
    reminderPeriod=$(echo "$schedule" | perl -lane 'print "@F[4]"')
    note=$(echo "$schedule" | perl -lane 'print "@F[5..$#F]"')
    msg "parsing '$schedule' as h=$scheduleHour m=$scheduleMinute d=$scheduleDay r=$reminderPeriod($reminderCount) note=$note"
    now=$(date +%s)
    msg "$drug last taken at $(renderDateAndTimeAgo "$lastLogDate" "$now")"


    if [[ "$scheduleDay" == "*" ]]; then
        lastSchedule=$(date -d "$scheduleHour:$scheduleMinute $(date +%Z)" +%s)
        if (( lastSchedule > now )); then
            # in future, use yesterday
            lastSchedule=$(date -d "$scheduleHour:$scheduleMinute  $(date +%Z) - 1 day" +%s)
        fi
        msg "last scheduled: $(date -d "@$lastSchedule" --rfc-3339=s)"
        msg "$drug last scheduled at $(renderDateAndTimeAgo "$lastSchedule" "$now")"
        if (( lastLogDate > lastSchedule )); then
            msg "we took it after the last schedule"
            continue
        fi

        # the overdue doesn't account for missed doeses
        echo -n "OVERDUE FOR DRUG '$drug' we are $(renderTimeAgo "$now" "$lastSchedule") overdue: "
        minutesSinceLastSchedule=$(( (now - lastSchedule) / 60 ))
        #TODO: reminderCount
        if [[ "$(( minutesSinceLastSchedule % reminderPeriod ))" == "0" ]]; then
            echo "REMINDER NOW"
        else
            echo "reminder in $(( minutesSinceLastSchedule / reminderPeriod )) minutes"
        fi
    else
        die "nonwildcard days not supported yet"
    fi

    # if no log between last drug time and now, scream about drugs
    # if day is valid but time is later, try previous day
done <<< "$schedules"
