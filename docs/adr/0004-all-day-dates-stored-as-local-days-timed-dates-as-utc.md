---
status: accepted
date: 2026-11-15
---
# All-day dates stored as local days, timed dates as UTC

## Context and Problem Statement
An item's due value is either a whole day ("Nov 20") or a moment ("Nov 20, 3pm"). A whole day stored as a timestamp shifts to the previous or next day when the time zone changes. How should the single `due` column hold both kinds?

## Considered Options
* All-day as `YYYY-MM-DD` text, timed as a UTC ISO 8601 string, told apart by string length
* One timestamp format for both

## Decision Outcome
Chosen option: "All-day as `YYYY-MM-DD` text, timed as a UTC ISO 8601 string, told apart by string length", because an all-day date then names the same calendar day in every time zone.

A 10-character value is a day; anything else must parse as a UTC timestamp (`Sources/JotCore/Item.swift:32`). All-day dates are never converted to timestamps for storage.

### Consequences
* Good, because all-day items never shift across time zones (`DueTests.allDayKeepsItsDateInAnyTimeZone`).
* Good, because an all-day TODO is overdue only once its day has passed, while a timed one is overdue at its moment (`AgendaTests.bucketsAroundMidnight`).
* Bad, because the column holds two formats, so every reader must go through `Due(stored:)` and SQL can't sort or compare the column directly.
* Bad, because the length check is an implicit contract: a third format would need a schema change or a new discriminator.

## More Information
Evidence: commit 97ee885; `Sources/JotCore/Item.swift:5` and `:32`; `DueTests.storageRoundTrip`; `CLAUDE.md` gotcha 6; `README.md`, Notes.
