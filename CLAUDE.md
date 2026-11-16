<!-- Durable, project-specific knowledge for the agent. Auto-loaded every session.
     Maintenance: permanent facts only (ephemeral state -> .ai/handoff.md); add gotchas as
     you hit them and never delete them (compress instead); edit only when the user asks.
     Cap 12 KB (bytes, not lines), ideally far less.
     At session start get-session-context reads .ai/handoff.md only; .ai/rules.md and
     .ai/backlog.md load on demand. -->

# claude-jot (Jot)

## What this project is
A local macOS productivity tool for one user: jot ideas, dates, and TODOs from a menu bar panel (⌥⌘J), and see the agenda in an Übersicht desktop widget. Read `.ai/handoff.md` first for live state.

## Stack
Swift 6 / SwiftPM, macOS 14+, Command Line Tools only (no Xcode: no XCTest and no WidgetKit; tests use Swift Testing). System SQLite3, no third-party dependencies. The widget is Übersicht JSX.

## Architecture (mental model)
- `JotCore` (store, `DueParser`, `Agenda`) is shared by every front end.
- `Jot` menu bar app and `jot-cli` both read and write `~/Library/Application Support/Jot/jot.db` (WAL mode). `JOT_DB` overrides the path.
- Items with a `project` are asks from Claude Code sessions, filed by the `skill/jot` skill; they go to the agenda's `claude` bucket and nowhere else. Schema changes go through `PRAGMA user_version` in `Store.migrate()`.
- The Übersicht widget only shells out to `~/.local/bin/jot-cli agenda --json` (and `done <id>`).

## Phase / status
MVP on `main`. Claude Project TODOs (project column, "Claude" section, `skill/jot`) built on top; see `.ai/handoff.md` for live state.

## Active gotchas
1. Übersicht ignores symlinked widgets. `scripts/bundle.sh` copies the widget instead.
2. Übersicht widgets can't take keyboard input or be dragged. Position is CSS in `widget/jot.widget/index.jsx`, and desktop icons draw on top. A backdrop blur doesn't work, so use a solid background.
3. Übersicht's widget server (127.0.0.1:41416, `GET /state/` lists the loaded widgets) may not start on first launch. Restart the app.
4. MenuBarExtra can't be opened from a hotkey, which is why the app uses NSStatusItem + NSPopover with a Carbon hotkey.
5. NSDataDetector takes no reference date, so it can't be tested. `DueParser` is hand-written; a weekday name always means the next occurrence.
6. Due storage: all-day = `YYYY-MM-DD`, timed = UTC ISO, told apart by string length. Never convert all-day dates to timestamps.
7. Session screenshots and keystrokes need Screen Recording / Automation, which the user denied. UI checks go through the user.

## Conventions / what NOT to do
- Rebuild and install with `scripts/bundle.sh`, then `pkill -x Jot; open ~/Applications/Jot.app`.
- Test with `swift test`. Use a temp `JOT_DB` for manual CLI runs; never seed the real DB.

<!-- =========================================================
     DELETE EVERYTHING BELOW BEFORE USING — it's usage guidance.
     =========================================================

  Rules of thumb (from Anthropic's best-practices guide):
  - This file loads EVERY message. Every line is re-processed each turn.
    Bloat is a recurring token tax AND makes Claude ignore rules lost in noise.
  - For each line ask: "Would removing this cause Claude to make a mistake?"
    If no -> delete it.
  - INCLUDE: non-guessable commands, style that DIFFERS from defaults,
    test runners, repo etiquette, architecture decisions, env quirks, gotchas.
  - EXCLUDE: anything Claude can read from code, standard conventions,
    long API docs (link instead), file-by-file descriptions, "write clean code".
  - Sometimes-relevant knowledge -> a Skill (.claude/skills/), not here.
  - Deterministic "always do X" -> a Hook (.claude/settings.json), not here.
  - Target: under ~250 lines, ideally far less. If Claude keeps ignoring a
    rule, the file is probably too long. Prune, don't add emphasis.
  - Check it into git so the team shares it. Treat it like code: prune when
    things go wrong.
  - Small/single-purpose projects (POCs, single-integration tools) don't need every
    section above — What this project is / Stack / a "Key behaviors" list / Out of
    scope / Known constraints is often enough. Skip File map and Architecture
    if there's not enough project to say anything non-obvious in them.
  - Session history goes in .ai/history.md, not here.

  Placement:
  - ./CLAUDE.md            project root, shared via git
  - ./CLAUDE.local.md      personal, gitignored
  - ~/.claude/CLAUDE.md    applies to ALL your projects
  - subdir/CLAUDE.md       pulled in on demand when Claude reads that subdir
  - Import others with: @path/to/file.md
============================================================ -->
