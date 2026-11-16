# Handoff — live state snapshot

## Last updated
2026-11-16, session 2

## Current state
Claude Project TODOs is built, installed, and pushed to `main` (local branch `feat/mvp` tracks it). Scope was cut to skill only: items carry a `project`, show in a "Claude · <project>" section in the panel and widget, and are filed by the `jot` skill (`skill/jot/SKILL.md`, copied to `~/.claude/skills/jot/` by `scripts/bundle.sh`). `swift test` passes (18 tests); the real DB migrated to `user_version` 1. Decisions are recorded in `docs/adr/` (6 ADRs, index in `docs/adr/README.md`).

## Active task
**Claude Project TODOs: verify.**
- [x] Schema `project` column, `Agenda.claude` + `byProject`, `jot-cli add -p`, `claude` key in `agenda --json`.
- [x] Panel and widget sections; skill; bundle step; README.
- [x] Visual check of the panel and widget: user confirmed both show the Claude section (2026-11-16).
- [ ] Confirm a fresh Claude Code session triggers the `jot` skill unprompted (skills load at session start). Owner: user + Claude.
- [x] Committed and pushed.

## Open threads
- Automatic "session is waiting" items via hooks were dropped by the user's choice. Research is done: `Notification`/`Stop`/`UserPromptSubmit`/`SessionEnd` all carry `session_id` and `cwd`; `"async": true` keeps a hook from blocking. Unverified: hooks firing in the desktop Code tab, and `idle_prompt` timing (~60 s).
- Launch at login isn't set up.
- No scheduled backups; `jot-cli backup` is manual.
- Widget checkboxes need an Übersicht interaction shortcut + Accessibility (user's step, not done).

## Next recommended step
In a fresh session, see whether Claude files an ask through the `jot` skill unprompted.

## Out of scope
Reminders/notifications, sync, accounts, rich text, desktop WidgetKit widget (needs Xcode, which the user declined).
