---
status: accepted
date: 2026-11-15
---
# Hand-written date parser, not NSDataDetector

## Context and Problem Statement
Users type dates like `fri 3pm`, `nov 20`, or `in 2 weeks`. `NSDataDetector` can read such text but takes no reference date, so its output depends on the real clock and can't be tested (`CLAUDE.md`, gotcha 5). How should date text be parsed?

## Considered Options
* Hand-written `DueParser` that takes `now` and a calendar
* NSDataDetector

## Decision Outcome
Chosen option: "Hand-written `DueParser` that takes `now` and a calendar", because every rule can be pinned by a test with a fixed date and time zone.

One rule users rely on: a weekday name always means the next occurrence, so `sun` typed on a Sunday is next week, not today.

### Consequences
* Good, because parsing is deterministic and covered by tests, including a DST boundary (`Tests/JotCoreTests/JotCoreTests.swift`, `ParserTests`).
* Good, because unreadable input returns nil, which the panel shows as "can't read date" before saving.
* Bad, because only the listed forms are understood; phrases outside them (for example `next week`) are rejected.
* Bad, because the parser is English-only and is code the project must maintain.

## More Information
Evidence: commit 97ee885; `Sources/JotCore/DueParser.swift`; `ParserTests` (`weekdaysAreAlwaysAhead`, `rejectsJunk`, `dstUsesLocalWallClock`); `CLAUDE.md` gotcha 5.
