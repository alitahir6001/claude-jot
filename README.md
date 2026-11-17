# Jot

A small local productivity tool for macOS: jot down ideas, dates, and TODOs from the menu bar, and see your agenda on the desktop.

- **Menu bar app**: press ⌥⌘J (or click the icon) to capture a note or TODO, optionally with a date like `fri 3pm`, `tomorrow`, `nov 20`, `in 2 weeks`. Check items off, edit, delete, search.
- **Desktop widget** (via [Übersicht](https://tracesof.net/uebersicht/)): a read-only agenda of overdue, today, upcoming, and undated TODOs, refreshed every 30 seconds.
- **`jot-cli`**: the same data from the terminal, with `--json` output for scripts and agents.

Everything lives in one SQLite file at `~/Library/Application Support/Jot/jot.db`. No accounts, no sync, no network.

## Requirements

- macOS 14+
- Swift 6 (Xcode Command Line Tools is enough; full Xcode not needed)
- Optional: Übersicht for the desktop widget (`brew install --cask ubersicht`)

## Install

```bash
scripts/bundle.sh
```

This builds a release, installs `~/Applications/Jot.app` (ad-hoc signed, menu bar only) and `~/.local/bin/jot-cli`, and copies the widget into Übersicht's widgets folder if it exists. Then open `~/Applications/Jot.app`.

## CLI

```
jot-cli add [-t] [-d <date>] [-p <project>] <text>
                                      add a note (-t: TODO, -d: "fri 3pm", "nov 20", ...,
                                      -p: file it under a Claude Code project)
jot-cli agenda [--json]
jot-cli find <text> [--json]
jot-cli done <id> | undo <id> | rm <id>
jot-cli backup [dir]                  snapshot the DB (default ~/Documents/Jot Backups)
```

Set `JOT_DB=/path/to/file.db` to use a different database.

## Claude Code asks

`scripts/bundle.sh` also installs a `jot` skill into `~/.claude/skills/jot/`. Type `/jot` in a Claude Code session and it files what that project needs from you as TODOs under the project's name (`jot-cli add -t -p <project>`), reading the project's `.ai/handoff.md` and the session. The panel and widget show them in a "Claude · <project>" section. Only you can run it; Claude never files items on its own.

## Layout

```
Sources/JotCore/      item model, SQLite store, date parser, agenda (shared)
Sources/Jot/          menu bar app (NSStatusItem + NSPopover, Carbon hotkey)
Sources/jot-cli/      command-line interface
Tests/JotCoreTests/   Swift Testing suite
widget/jot.widget/    Übersicht widget
skill/jot/            Claude Code skill (copied to ~/.claude/skills/jot)
scripts/bundle.sh     build + install
docs/adr/             decision records (start at docs/adr/README.md)
```

## Tests

```bash
swift test
```

## Notes

- All-day dates are stored as local `YYYY-MM-DD` and timed dates as UTC, so all-day items never shift across time zones.
- Übersicht widgets can't take keyboard input or be dragged; capture happens in the menu bar panel, and the widget position is set in `widget/jot.widget/index.jsx`.
- Clicking checkboxes on the widget requires an interaction shortcut in Übersicht's preferences plus Accessibility access.
