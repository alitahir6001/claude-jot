---
status: accepted
date: 2026-11-16
---
# The jot skill is user-invoked and populates the current project's TODOs

## Context and Problem Statement
[ADR-0006](0006-claude-code-asks-filed-by-a-skill-not-hooks.md) chose a skill over hooks for getting Claude Code project asks into Jot, and described a skill that Claude runs on its own whenever it is blocked on the user (`skill/jot/SKILL.md` at commit dcdc1ed). The user corrected this the same day: they run the skill themselves, when they want a project's TODOs populated (`.ai/handoff.md`, Current state). Who invokes the skill, and what does one run cover?

## Considered Options
* Claude invokes it when blocked on the user, one ask at a time
* The user invokes it; it populates the current project
* The user invokes it; it sweeps every project
* The user invokes it; an argument picks the current project or every project

## Decision Outcome
Chosen option: "The user invokes it; it populates the current project", because the user wants to decide when Jot is filled, and one project per run keeps a run small and its result easy to check.

Still a skill and not hooks, as in ADR-0006. The skill sets `disable-model-invocation: true`, so only `/jot` runs it. A run reads the project's `.ai/handoff.md` for unfinished steps owned by the user and open threads that are the user's step, adds anything the session is waiting on the user for, skips what is already open in Jot for that project, and files the rest with `jot-cli add -t -p <project>`. It never completes or deletes items; the user ticks them off in Jot.

### Consequences
* Good, because nothing lands in Jot unless the user asked for it.
* Good, because the skill's description no longer competes for Claude's attention in every session.
* Good, because the handoff file is the source, so a run gives the same answer whichever session it happens in.
* Bad, because Jot only reflects a project as of its last `/jot` run; it goes stale in between.
* Bad, because covering several projects means running `/jot` once in each.
* Bad, because a project without `.ai/handoff.md` yields only what the current session knows.
* Bad, because duplicate detection is Claude's judgement of "same meaning", not a key in the database.

## More Information
Evidence: `skill/jot/SKILL.md`; commit dcdc1ed (the Claude-invoked version); `.ai/handoff.md`. Supersedes [ADR-0006](0006-claude-code-asks-filed-by-a-skill-not-hooks.md), whose data model (the `project` column and the agenda's `claude` bucket) is unchanged.
