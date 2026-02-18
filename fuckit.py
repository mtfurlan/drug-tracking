#!/usr/bin/env -S pipx run
# /// script
# dependencies = [
#   "dykes"
# ]
# ///
from dataclasses import dataclass
from pathlib import Path
from typing import Annotated
import dykes
import datetime
import re

@dataclass
class Schedule:
    h
    m
    d
    reminderCount: int
    reminderPeriod: int
    notes: str | None = None

    def __post_init__(self):
        self.h = "foobar"
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
            if re.match(r"^s:", line):
                _, h, m, d, reminderCount, reminderPeriod, *note = re.split(r"\s+", line)
                schedules.append(Schedule(h, m, d, reminderCount, reminderPeriod, notes=" ".join(note)))
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
    print(parsed)
