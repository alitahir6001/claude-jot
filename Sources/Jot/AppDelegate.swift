import AppKit
import Carbon.HIToolbox
import SwiftUI

/// NSStatusItem + NSPopover instead of MenuBarExtra: MenuBarExtra can't be opened from a hotkey.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private let model = Model()

    func applicationDidFinishLaunching(_ note: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Jot")
        statusItem.button?.action = #selector(toggle)
        statusItem.button?.target = self

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PanelView(model: model))
        model.close = { [weak self] in self?.popover.performClose(nil) }

        // ⌥⌘J
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_J), modifiers: UInt32(cmdKey | optionKey)) { [weak self] in
            self?.toggle()
        }
    }

    @objc func toggle() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem.button else { return }
        model.reload()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        model.opened += 1
    }
}

/// Carbon hotkeys need no Accessibility permission, unlike NSEvent global monitors.
final class HotKey {
    private var ref: EventHotKeyRef?
    private static var action: (() -> Void)?

    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        HotKey.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { HotKey.action?() }
            return noErr
        }, 1, &spec, nil, nil)
        let id = EventHotKeyID(signature: OSType(0x4A4F_5421), id: 1)   // 'JOT!'
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &ref)
    }
}
