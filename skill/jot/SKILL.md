---
name: jot
description: Run by the user as /jot to populate the current project's TODOs in their Jot app (menu bar panel + desktop widget). Files everything this project needs from the user under the project's name.
disable-model-invocation: true
---

# jot

Jot is the user's local TODO tool. Items filed with a project show in a "Claude · <project>" section. The user runs this skill; never file Jot items on your own initiative.

## Steps

1. **Project name.** The main repo's folder name, so worktrees file under the real project; outside git, the current folder's name:
   ```bash
   p=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && p=$(dirname "$p") || p=$PWD; basename "$p"
   ```
2. **Collect what the project needs from the user**, from:
   - `.ai/handoff.md`: unfinished Active-task steps (`[ ]`, `[~]`, `[!]`) owned by the user, and Open threads that are the user's step.
   - This session: anything you are currently waiting on the user for.

   No `.ai/handoff.md`: use the session only, and say so. Leave out anything you can do yourself.
3. **Check what's already there:**
   ```bash
   ~/.local/bin/jot-cli agenda --json   # open items are under "claude", each with "project" and "id"
   ```
   Skip anything already open for this project with the same meaning.
4. **File each new one:**
   ```bash
   ~/.local/bin/jot-cli add -t -p "<project>" "<ask>"
   ```
   Write it to stand alone on a desktop widget: imperative, under ~70 characters, specific. Good: `Add Jot.app to Login Items`. Bad: `Launch at login isn't set up`. Add `-d "<date>"` only if a deadline is written down.
5. **Report** three short lists: added, skipped as duplicates, and open Jot items for this project that match nothing in step 2 (possibly stale).

## Don't
- Don't `done` or `rm` any item unless the user asks; they tick things off in Jot.
- Don't set `JOT_DB`.
- If `jot-cli` is missing, say so and stop.
