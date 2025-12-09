//
//  QuickTodoApp.swift
//  QuickTodo
//
//  A lightweight menubar todo app for macOS
//

import SwiftUI
import AppKit

// MARK: - App Entry Point

/// Main application entry point for QuickTodo.
///
/// This app runs as a menubar-only application (no dock icon).
/// It displays a popover with the todo list when the menubar icon is clicked
/// or when the global hotkey is triggered.
@main
struct QuickTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

/// Manages the menubar icon and popover lifecycle.
///
/// Responsibilities:
/// - Creates and manages the NSStatusItem (menubar icon)
/// - Shows/hides the popover containing the todo list
/// - Registers and handles the global hotkey
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// The menubar status item
    private var statusItem: NSStatusItem?

    /// The popover containing the todo list
    private var popover: NSPopover?

    /// Shared todo store for data persistence
    private let todoStore = TodoStore()

    /// Manages global keyboard shortcuts
    private var hotkeyManager: HotkeyManager!

    /// Monitor for clicks outside the popover
    private var eventMonitor: Any?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkey()
        setupPopover()
        setupEventMonitor()
    }

    // MARK: - Setup

    /// Creates the menubar status item with icon
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "QuickTodo")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    /// Configures the popover with the todo list view
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(todoStore)
                .environmentObject(hotkeyManager!)
        )
    }

    /// Registers the global hotkey for quick access
    private func setupHotkey() {
        hotkeyManager = HotkeyManager { [weak self] in
            self?.togglePopover()
        }
    }

    /// Sets up event monitor to close popover when clicking outside
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    // MARK: - Actions

    /// Toggles the popover visibility
    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Activate the app to ensure keyboard focus
            NSApp.activate(ignoringOtherApps: true)

            // Post notification to focus the input field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .focusNewTodoField, object: nil)
            }
        }
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the new todo text field should receive focus
    static let focusNewTodoField = Notification.Name("focusNewTodoField")
}
