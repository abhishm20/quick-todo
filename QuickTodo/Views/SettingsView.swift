//
//  SettingsView.swift
//  QuickTodo
//
//  Settings panel for configuring shortcuts and data location
//

import SwiftUI
import AppKit
import Carbon

// MARK: - Settings View

/// Settings panel for configuring app preferences.
///
/// Allows users to:
/// - Change the global keyboard shortcut
/// - Change the JSON data file location
struct SettingsView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var todoStore: TodoStore
    @EnvironmentObject private var hotkeyManager: HotkeyManager

    /// Current shortcut display text
    @State private var shortcutText = "⌘⇧T"

    /// Whether recording a new shortcut
    @State private var isRecordingShortcut = false

    /// Current data path
    @State private var dataPath: String = ""

    /// Event monitor for capturing keyboard shortcut
    @State private var eventMonitor: EventMonitorRef?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    shortcutSection
                    dataLocationSection
                    keyboardShortcutsSection
                }
                .padding(16)
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 360, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            dataPath = todoStore.currentFileURL.path
            shortcutText = formatKeyCombo(keyCode: hotkeyManager.keyCombo.keyCode, modifiers: hotkeyManager.keyCombo.modifiers)
        }
        .onDisappear {
            stopRecording()
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    // MARK: - Subviews

    /// Header with title and close button
    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.headline)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    /// Global shortcut configuration section
    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Global Shortcut")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text(isRecordingShortcut ? "Press keys..." : shortcutText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(isRecordingShortcut ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                    .animation(.easeInOut(duration: 0.2), value: isRecordingShortcut)

                Button(isRecordingShortcut ? "Cancel" : "Record") {
                    if isRecordingShortcut {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .buttonStyle(.bordered)
            }

            Text("Press the shortcut to open QuickTodo from anywhere")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Data location configuration section
    private var dataLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Location")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text(dataPath)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)

                Button("Browse...") {
                    selectDataLocation()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button("Open in Finder") {
                    NSWorkspace.shared.selectFile(dataPath, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Button("Reset to Default") {
                    resetDataLocation()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.orange)
            }

            Text("Your todos are stored in this JSON file")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Keyboard shortcuts info section
    private var keyboardShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keyboard Shortcuts")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 4) {
                shortcutRow("↑/↓", "Navigate items")
                shortcutRow("⇧↑/⇧↓", "Multi-select")
                shortcutRow("↩/Space", "Toggle complete")
                shortcutRow("⌘I", "Edit item")
                shortcutRow("⌫", "Delete item(s)")
                shortcutRow("⌘C", "Copy item(s)")
                shortcutRow("⌘V", "Paste in input")
                shortcutRow("⌘,", "Open settings")
                shortcutRow("⎋", "Close window")
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
    }

    /// Helper to create a shortcut row
    private func shortcutRow(_ shortcut: String, _ description: String) -> some View {
        HStack {
            Text(shortcut)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 70, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Footer with action buttons
    private var footerView: some View {
        HStack {
            Button("Quit QuickTodo") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.terminate(nil)
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }

    // MARK: - Actions

    /// Opens file picker to select new data location
    private func selectDataLocation() {
        let panel = NSSavePanel()
        panel.title = "Choose data location"
        panel.nameFieldStringValue = "todos.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        if let url = URL(string: dataPath) {
            panel.directoryURL = url.deletingLastPathComponent()
        }

        // Dismiss settings first to avoid state corruption
        dismiss()

        // Show file picker after settings is dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [todoStore] in
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                todoStore.updateStoragePath(url)
            }
        }
    }

    /// Resets data location to default
    private func resetDataLocation() {
        todoStore.resetToDefaultPath()
        dataPath = todoStore.currentFileURL.path
    }

    // MARK: - Shortcut Recording

    /// Starts listening for keyboard shortcut
    private func startRecording() {
        isRecordingShortcut = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            captureShortcut(event)
            return nil // Consume the event
        }
    }

    /// Stops listening for keyboard shortcut
    private func stopRecording() {
        isRecordingShortcut = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Captures a keyboard shortcut from an event
    private func captureShortcut(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Require at least Cmd or Ctrl modifier for a valid shortcut
        guard modifiers.contains(.command) || modifiers.contains(.control) else {
            return
        }

        // Convert NSEvent modifiers to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }

        let newCombo = HotkeyManager.KeyCombo(
            keyCode: UInt32(event.keyCode),
            modifiers: carbonModifiers
        )

        hotkeyManager.updateShortcut(newCombo)
        shortcutText = formatKeyCombo(keyCode: newCombo.keyCode, modifiers: newCombo.modifiers)
        stopRecording()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(TodoStore())
}
