#!/usr/bin/env -S pipx run
# /// script
# dependencies = [
#   "dykes",
#   "tzlocal",
#   "cron-converter"
# ]
# ///
from dataclasses import dataclass
from pathlib import Path
from typing import Annotated
import dykes
import datetime
import re
from cron_converter import Cron
from tzlocal import get_localzone



@dataclass
class Schedule:
    cron: Cron
    reminderCount: int
    reminderPeriod: int

@dataclass
class Parsed:
    schedules: [Schedule]
    lastEntry: datetime
    taken: bool
    notes: str | None = None


def parseSchedules(f: str) -> Parsed:
    schedules = []
    with open(f) as schedule:
        for line in schedule:
            line = line.rstrip()
            res = re.match(r"^s:\s+((?:(?:\d+(?:,\d+)*|(?:\d+(?:\/|-)\d+)|\*(?:\/\d+)?)\s*){5})\s+(-?\d+)\s+(\d+)$", line)
            if(res):
                cron = res.group(1)
                reminderCount = res.group(2)
                reminderPeriod = res.group(3)
                schedules.append(Schedule(Cron(cron), reminderCount, reminderPeriod))
            elif re.match(r"^={4,}$", line):
                for line in schedule:
                    res = re.match(r"^\[([ x])\] ((?:\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?)(?:Z|[\+-]\d{2}:\d{2})?)(?: (.*))?", line)
                    if(res):
                        taken = res.group(1)
                        date = res.group(2)
                        notes = res.group(3)
                        lastEntry = datetime.datetime.fromisoformat(date)
                return Parsed(schedules, lastEntry, taken, notes)




@dataclass
class DrugReminderArgs:
    drugfile: Annotated[Path, "the drug file"]
    verbosity: dykes.Count

if __name__ == "__main__":
    args = dykes.parse_args(DrugReminderArgs)

    parsed = parseSchedules(args.drugfile)

    reference = datetime.datetime.now(tz=get_localzone())
    nowSchedule = parsed.schedules[0].cron.schedule(reference)
    lastSchedule = parsed.schedules[0].cron.schedule(parsed.lastEntry)

    print(f"last from now: {nowSchedule.prev().isoformat(" ", "seconds")}")
    print(f"next from last: {lastSchedule.next().isoformat(" ", "seconds")}")
