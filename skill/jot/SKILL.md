---
name: jot
description: Record what you need from the user as a TODO in their Jot app (menu bar panel + desktop widget), filed under the current project, and tick it off once they deliver. Use when you are blocked on or ending a turn waiting for something only the user can do (a decision, a manual step, a credential, a UI check, an approval), or when the user says "jot that", "add it to jot", or "/jot".
---

# jot

Jot is the user's local TODO tool. Items filed with a project show in a "Claude · <project>" section. Source: `~/Desktop/projects/claude-jot`.

## Add an ask
```bash
p=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && p=$(dirname "$p") || p=$PWD; ~/.local/bin/jot-cli add -t -p "$(basename "$p")" "<ask>"
```
- The project is the main repo's folder name, so worktrees file under the real project. Outside git it is the current folder's name.
- Write the ask so it stands alone on a desktop widget: imperative, under ~70 characters, specific. Good: `Approve the plan for hook support`. Bad: `Waiting on you`.
- Add `-d "<date>"` only if the user gave a deadline (`fri 3pm`, `nov 20`).

## Resolve an ask
When the user delivers, find the item and complete it:
```bash
~/.local/bin/jot-cli agenda --json   # open asks are under the "claude" key, each with "project" and "id"
~/.local/bin/jot-cli done <id>
```

## Don't
- Don't add things you can do yourself, or progress notes. Only what needs the user.
- Don't add a duplicate: check the `claude` key first if you may have already filed it.
- Don't set `JOT_DB`, and don't `rm` or `done` items you didn't file unless the user asks.
- If `jot-cli` is missing, say so once and carry on; never block on it.
