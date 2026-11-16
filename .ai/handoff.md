# Handoff — live state snapshot

## Last updated
2026-11-15, session 1

## Current state
The MVP is built, installed, and pushed to github.com/alitahir6001/claude-jot `main` (5 commits; local branch `feat/mvp` tracks it). Jot.app is running on the real DB, and the Übersicht widget is installed and confirmed visible by the user. The folder was renamed from `~/Desktop/projects/jot` to `~/Desktop/projects/claude-jot`, so `.build/` may hold stale absolute paths. If the build fails, run `swift package clean`.

## Active task
**Claude Project TODOs.** Track what each Claude Code session/project needs from the user, grouped by project, in both the panel and the widget. Approved direction, not started.
- [ ] Research the hook payloads (`Notification`, `UserPromptSubmit`: `session_id`, `cwd`, `message`) and whether hooks fire in the Claude desktop app's Code tab. Owner: Claude.
- [ ] Write a plan for approval (it touches 3+ files). Owner: Claude, then user.
- [ ] Schema: add a `project` column (ALTER TABLE migration), possibly `source`/`session_id` for dedupe.
- [ ] `jot-cli add -p <project>`; project = basename of the hook `cwd`'s git root.
- [ ] Hook script: `Notification` adds a "waiting on you" item (one per session); `UserPromptSubmit` marks it done.
- [ ] Instruction in `~/.claude/CLAUDE.md` telling Claude to add specific asks with `jot-cli add -t -p <project>` (needs the user's OK; it's their global file).
- [ ] "Claude" section grouped by project in `PanelView.swift` and `index.jsx`.

## Open threads
- Launch at login isn't set up. The user opens Jot.app manually or adds it under Login Items.
- No scheduled backups; `jot-cli backup` is manual.
- Widget checkboxes need an Übersicht interaction shortcut + Accessibility (user's step, not done).

## Next recommended step
Research the hook payloads, then write the plan.

## Out of scope
Reminders/notifications, sync, accounts, rich text, desktop WidgetKit widget (needs Xcode, which the user declined).
