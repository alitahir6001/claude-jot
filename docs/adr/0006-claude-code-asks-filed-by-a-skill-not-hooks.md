---
status: accepted
date: 2026-11-16
---
# Claude Code asks filed by a skill, not hooks

## Context and Problem Statement
Jot should show what each Claude Code project needs from the user, grouped by project. The first design used Claude Code hooks to add a "waiting on you" item per session automatically, plus an instruction in the user's global instructions file for specific asks (`.ai/handoff.md` at commit 5d8a5ea). Research confirmed the hook payloads carry `session_id` and `cwd`, but left two things unverified: that hooks fire in the desktop app, and when the idle notification fires (`.ai/handoff.md`, Open threads). What should put Claude's asks into Jot?

## Considered Options
* A skill only
* A skill plus hooks
* Hooks plus an instruction in the global instructions file

## Decision Outcome
Chosen option: "A skill only", because it is the smallest build: no hook configuration, no session tracking in the schema, and no always-loaded instruction. The user chose it knowing its limit.

The `jot` skill (`skill/jot/SKILL.md`) tells Claude to file an ask with `jot-cli add -t -p <project>` and to complete it once the user delivers. The project is the main repository's folder name, so worktrees file under the real project. Items with a `project` go to the agenda's `claude` bucket and nowhere else, and both front ends show one "Claude · <project>" section per project.

### Consequences
* Good, because the data model gained one nullable column (`project`) and nothing per session.
* Good, because asks are specific sentences Claude wrote, not a generic "waiting on you" line per finished turn.
* Good, because a skill costs a one-line description in context until it is used.
* Good, because the skill is versioned in the repo and installed by `scripts/bundle.sh`, like the widget.
* Bad, because nothing is automatic: an ask appears only when Claude runs the skill or the user invokes it. An idle session doesn't list itself.
* Bad, because completion also depends on Claude noticing the user delivered; otherwise the user checks the item off by hand.
* Bad, because schema changes now need a migration path, handled by `PRAGMA user_version` in `Store.migrate()`.

## More Information
Evidence: commits 2735574, 987bbac, 2f6530c, 7dc40e9, dcdc1ed; `skill/jot/SKILL.md`; `Sources/JotCore/Agenda.swift`; `AgendaTests.projectItemsGoToClaudeOnly`; `StoreTests.migratesOldSchemaKeepingRows`. Hook findings, should the automatic part be revisited: `.ai/handoff.md`, Open threads. Related: [ADR-0005](0005-one-sqlite-file-shared-through-jotcore.md).
