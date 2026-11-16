---
status: accepted
date: 2026-11-15
---
# Menu bar panel on NSStatusItem with a Carbon hotkey, not MenuBarExtra

## Context and Problem Statement
The capture panel must open from a global hotkey (⌥⌘J) as well as from a click on the menu bar icon. SwiftUI's `MenuBarExtra` can't be opened from a hotkey (`CLAUDE.md`, gotcha 4). Which menu bar mechanism should the app use?

## Considered Options
* NSStatusItem + NSPopover with a Carbon hotkey
* SwiftUI MenuBarExtra

## Decision Outcome
Chosen option: "NSStatusItem + NSPopover with a Carbon hotkey", because the app controls when the popover shows, so the hotkey and the icon click can open the same panel.

### Consequences
* Good, because ⌥⌘J opens the panel from any app.
* Good, because a Carbon hotkey needs no Accessibility permission, unlike an NSEvent global monitor (`Sources/Jot/AppDelegate.swift:42`).
* Good, because the panel content is still SwiftUI (`Sources/Jot/PanelView.swift`), hosted in the popover.
* Bad, because the app carries AppKit lifecycle code and a Carbon hotkey registration that `MenuBarExtra` would have hidden (`Sources/Jot/AppDelegate.swift`).
* Bad, because Carbon hotkey APIs are legacy (inferred from the API family, not from a source in this repo).

## More Information
Evidence: commit d3bae9d; `Sources/Jot/AppDelegate.swift:5` and `:42`; `CLAUDE.md` gotcha 4.
