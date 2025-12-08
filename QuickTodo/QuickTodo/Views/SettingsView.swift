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
    @State private var eventMonitor: Any?

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
                }
                .padding(16)
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 360, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            dataPath = todoStore.currentFileURL.path
            shortcutText = formatKeyCombo(hotkeyManager.keyCombo)
        }
        .onDisappear {
            stopRecording()
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

        if panel.runModal() == .OK, let url = panel.url {
            todoStore.updateStoragePath(url)
            dataPath = url.path
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
        shortcutText = formatKeyCombo(newCombo)
        stopRecording()
    }

    /// Formats a KeyCombo as a human-readable string
    private func formatKeyCombo(_ combo: HotkeyManager.KeyCombo) -> String {
        var result = ""

        // Modifiers
        if combo.modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if combo.modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if combo.modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if combo.modifiers & UInt32(cmdKey) != 0 { result += "⌘" }

        // Key
        result += keyCodeToString(combo.keyCode)

        return result
    }

    /// Converts a key code to its string representation
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        // Common key codes
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "↩", 48: "⇥", 51: "⌫", 53: "⎋",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
            103: "F11", 111: "F12",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        return keyMap[keyCode] ?? "?"
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(TodoStore())
}
