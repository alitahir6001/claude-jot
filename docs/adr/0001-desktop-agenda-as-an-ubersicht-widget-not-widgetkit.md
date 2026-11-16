---
status: accepted
date: 2026-11-15
---
# Desktop agenda as an Übersicht widget, not WidgetKit

## Context and Problem Statement
Jot needs an always-visible agenda on the desktop. The project builds with the Command Line Tools only, and WidgetKit requires Xcode, which the user declined to install (`CLAUDE.md`, Stack; `.ai/handoff.md`, Out of scope). How should the desktop agenda be rendered?

## Considered Options
* Übersicht widget written in JSX
* WidgetKit desktop widget

## Decision Outcome
Chosen option: "Übersicht widget written in JSX", because it needs no Xcode: the widget is one JSX file that shells out to `jot-cli agenda --json` and renders the result.

### Consequences
* Good, because the whole project builds and installs with `swift build` and a file copy (`scripts/bundle.sh`).
* Good, because the widget holds no data logic; it shows whatever the CLI prints.
* Bad, because Übersicht is a third-party app the user must install and keep running.
* Bad, because widgets can't take keyboard input or be dragged, so capture lives in the menu bar panel and position is CSS in the widget file (`CLAUDE.md`, gotcha 2).
* Bad, because Übersicht ignores symlinked widgets, so the install step copies the folder (`CLAUDE.md`, gotcha 1), and its widget server may need an app restart on first launch (gotcha 3).
* Bad, because clicking a checkbox needs an Übersicht interaction shortcut plus Accessibility access (`README.md`, Notes).

## More Information
Evidence: commit 81df516; `widget/jot.widget/index.jsx`; `CLAUDE.md` Stack and gotchas 1 to 3. Related: [ADR-0005](0005-one-sqlite-file-shared-through-jotcore.md) (the CLI as the widget's only interface).
