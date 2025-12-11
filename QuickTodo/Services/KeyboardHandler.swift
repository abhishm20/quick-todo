//
//  KeyboardHandler.swift
//  QuickTodo
//
//  Handles keyboard events for navigation
//

import AppKit
import SwiftUI

// MARK: - Keyboard Handler

/// Handles keyboard events for todo list navigation.
///
/// Uses NSEvent monitoring to reliably capture keyboard events
/// even when text fields are focused.
@MainActor
final class KeyboardHandler: ObservableObject {

    // MARK: - Published State

    /// Currently focused todo index (-1 for input field)
    @Published var focusedIndex: Int = -1

    /// Selected indices for multi-select
    @Published var selectedIndices: Set<Int> = []

    /// Index of item that should enter edit mode (set by Cmd+I, observed by ContentView)
    @Published var editingRequestedForIndex: Int? = nil

    // MARK: - Properties

    /// Event monitor reference
    private var eventMonitor: Any?

    /// Callback for actions
    var onToggle: ((Int) -> Void)?
    var onDelete: ((Set<Int>) -> Void)?
    var onClose: (() -> Void)?
    var onCopy: ((Set<Int>) -> Void)?
    var onOpenSettings: (() -> Void)?
    var getTodosCount: (() -> Int)?

    // MARK: - Lifecycle

    deinit {
        // Remove monitor directly since deinit is nonisolated
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Public Methods

    /// Starts monitoring keyboard events
    func startMonitoring() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if self.handleKeyEvent(event) {
                return nil // Consume event
            }
            return event // Pass through
        }
    }

    /// Stops monitoring keyboard events
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Resets focus to input field
    func resetFocus() {
        focusedIndex = -1
        selectedIndices.removeAll()
    }

    // MARK: - Private Methods

    /// Handles a keyboard event
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let hasShift = event.modifierFlags.contains(.shift)
        let hasCommand = event.modifierFlags.contains(.command)
        let todosCount = getTodosCount?() ?? 0
        let keyCode = event.keyCode

        // Handle Cmd+I for edit mode
        if hasCommand && keyCode == KeyCode.i.rawValue {
            if focusedIndex >= 0 && focusedIndex < todosCount {
                editingRequestedForIndex = focusedIndex
                return true
            }
            return false
        }

        // Handle Cmd+C for copy
        if hasCommand && keyCode == KeyCode.c.rawValue {
            if focusedIndex >= 0 || !selectedIndices.isEmpty {
                let indicesToCopy: Set<Int>
                if selectedIndices.isEmpty {
                    indicesToCopy = [focusedIndex]
                } else {
                    indicesToCopy = selectedIndices
                }
                onCopy?(indicesToCopy)
                return true
            }
            return false
        }

        // Handle Cmd+, for settings
        if hasCommand && keyCode == KeyCode.comma.rawValue {
            onOpenSettings?()
            return true
        }

        switch keyCode {
        case KeyCode.downArrow.rawValue:
            if hasShift {
                extendSelectionDown(todosCount: todosCount)
            } else {
                moveDown(todosCount: todosCount)
                selectedIndices.removeAll()
            }
            return true

        case KeyCode.upArrow.rawValue:
            if hasShift {
                extendSelectionUp(todosCount: todosCount)
            } else {
                moveUp()
                selectedIndices.removeAll()
            }
            return true

        case KeyCode.escape.rawValue:
            onClose?()
            return true

        case KeyCode.return.rawValue:
            if focusedIndex == -1 {
                return false // Let input field handle it
            } else if focusedIndex >= 0 && focusedIndex < todosCount {
                onToggle?(focusedIndex)
                return true
            }
            return false

        case KeyCode.space.rawValue:
            if focusedIndex >= 0 && focusedIndex < todosCount {
                onToggle?(focusedIndex)
                return true
            }
            return false

        case KeyCode.delete.rawValue, KeyCode.forwardDelete.rawValue:
            if focusedIndex >= 0 || !selectedIndices.isEmpty {
                deleteSelected(todosCount: todosCount)
                return true
            }
            return false

        default:
            return false
        }
    }

    /// Moves focus down
    private func moveDown(todosCount: Int) {
        guard todosCount > 0 else { return }
        if focusedIndex < todosCount - 1 {
            focusedIndex += 1
        }
    }

    /// Moves focus up
    private func moveUp() {
        if focusedIndex > -1 {
            focusedIndex -= 1
        }
    }

    /// Extends selection downward
    private func extendSelectionDown(todosCount: Int) {
        guard focusedIndex < todosCount - 1 else { return }

        if selectedIndices.isEmpty && focusedIndex >= 0 {
            selectedIndices.insert(focusedIndex)
        }

        focusedIndex += 1

        if selectedIndices.contains(focusedIndex) {
            selectedIndices.remove(focusedIndex - 1)
        } else {
            selectedIndices.insert(focusedIndex)
        }
    }

    /// Extends selection upward
    private func extendSelectionUp(todosCount: Int) {
        guard focusedIndex > 0 else { return }

        if selectedIndices.isEmpty && focusedIndex >= 0 {
            selectedIndices.insert(focusedIndex)
        }

        focusedIndex -= 1

        if selectedIndices.contains(focusedIndex) {
            selectedIndices.remove(focusedIndex + 1)
        } else {
            selectedIndices.insert(focusedIndex)
        }
    }

    /// Deletes selected items
    private func deleteSelected(todosCount: Int) {
        let indicesToDelete: Set<Int>
        if selectedIndices.isEmpty {
            if focusedIndex >= 0 && focusedIndex < todosCount {
                indicesToDelete = [focusedIndex]
            } else {
                return
            }
        } else {
            // Filter to only valid indices
            let validIndices = selectedIndices.filter { $0 >= 0 && $0 < todosCount }
            guard !validIndices.isEmpty else { return }
            indicesToDelete = validIndices
        }

        onDelete?(indicesToDelete)

        // Adjust focus after deletion
        selectedIndices.removeAll()
        let newCount = todosCount - indicesToDelete.count
        if focusedIndex >= newCount {
            focusedIndex = max(-1, newCount - 1)
        }
    }
}
