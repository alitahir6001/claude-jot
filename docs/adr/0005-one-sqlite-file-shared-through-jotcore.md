---
status: accepted
date: 2026-11-15
---
# One SQLite file shared through JotCore, with jot-cli as the widget's only interface

## Context and Problem Statement
Three front ends show and change the same items: the menu bar app, the command line, and the desktop widget. The tool is local and single-user, with no accounts, sync, or network (`README.md`). Where does the data live, and how does each front end reach it?

## Considered Options
* One SQLite file in WAL mode, accessed only through the `JotCore` library, using the system SQLite3
* (alternatives not recorded)

## Decision Outcome
Chosen option: "One SQLite file in WAL mode, accessed only through the `JotCore` library, using the system SQLite3", because one library owns the schema and rules while several processes read and write the same file safely.

The app and `jot-cli` link `JotCore` and open `~/Library/Application Support/Jot/jot.db`; `JOT_DB` overrides the path. The widget never opens the file: it shells out to `jot-cli agenda --json` and `jot-cli done <id>`. The project takes no third-party dependencies.

### Consequences
* Good, because WAL lets the widget's CLI call read while the app writes (`Sources/JotCore/Store.swift:35`).
* Good, because the agenda rules exist once, in `JotCore`, and every front end shows the same buckets.
* Good, because `--json` output makes the CLI usable by scripts and agents, and `JOT_DB` gives tests and manual runs a scratch database.
* Good, because there is nothing to resolve or update: SwiftPM builds with no package downloads.
* Bad, because the store hand-writes SQLite C API calls (prepare, bind, step) that a wrapper library would hide.
* Bad, because the widget's JSON shape is a contract: changing a key in `jot-cli agenda --json` can break the widget.
* Bad, because the app doesn't see changes made by the CLI or widget until it reloads from disk.

## More Information
Evidence: commits 97ee885, 0d9fd4a, 81df516; `Sources/JotCore/Store.swift`; `Sources/jot-cli/main.swift`; `CLAUDE.md`, Stack and Architecture. Related: [ADR-0001](0001-desktop-agenda-as-an-ubersicht-widget-not-widgetkit.md).
