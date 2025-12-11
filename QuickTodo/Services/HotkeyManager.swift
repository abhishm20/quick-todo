//
//  HotkeyManager.swift
//  QuickTodo
//
//  Manages global keyboard shortcuts
//

import Foundation
import Carbon
import AppKit
import SwiftUI

// MARK: - Hotkey Manager

/// Manages global keyboard shortcuts for quick access to the todo list.
///
/// Default hotkey: `⌘ + Shift + T`
///
/// The hotkey works system-wide, even when the app is in the background.
/// Users can customize the shortcut through the settings.
///
/// ## Important
/// Requires Accessibility permissions to register global hotkeys.
/// The app will prompt for permission on first launch.
final class HotkeyManager: ObservableObject {

    // MARK: - Types

    /// Represents a keyboard shortcut combination
    struct KeyCombo: Codable, Equatable {
        let keyCode: UInt32
        let modifiers: UInt32

        /// Default shortcut: ⌘ + Shift + T
        static let `default` = KeyCombo(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(cmdKey | shiftKey)
        )
    }

    // MARK: - Properties

    /// The action to perform when hotkey is triggered
    private let action: () -> Void

    /// Current keyboard shortcut
    @Published private(set) var keyCombo: KeyCombo

    /// Reference to the event handler
    private var eventHandler: EventHandlerRef?

    /// Reference to the registered hotkey
    private var hotkeyRef: EventHotKeyRef?

    /// UserDefaults key for storing custom shortcut
    private static let shortcutKey = "globalShortcut"

    // MARK: - Initialization

    /// Creates a new HotkeyManager and registers the global shortcut.
    ///
    /// - Parameter action: Closure to execute when hotkey is triggered
    init(action: @escaping () -> Void) {
        self.action = action

        // Load saved shortcut or use default
        if let data = UserDefaults.standard.data(forKey: Self.shortcutKey),
           let saved = try? JSONDecoder().decode(KeyCombo.self, from: data) {
            self.keyCombo = saved
        } else {
            self.keyCombo = .default
        }

        registerHotkey()
    }

    deinit {
        unregisterHotkey()
    }

    // MARK: - Public Methods

    /// Updates the keyboard shortcut.
    ///
    /// - Parameter combo: The new key combination
    func updateShortcut(_ combo: KeyCombo) {
        unregisterHotkey()
        self.keyCombo = combo

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(combo) {
            UserDefaults.standard.set(data, forKey: Self.shortcutKey)
        }

        registerHotkey()
    }

    /// Returns the current keyboard shortcut
    var currentShortcut: KeyCombo {
        keyCombo
    }

    // MARK: - Private Methods

    /// Registers the global hotkey using Carbon APIs
    private func registerHotkey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Install event handler
        let handlerResult = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.action()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard handlerResult == noErr else {
            print("QuickTodo: Failed to install event handler")
            return
        }

        // Register the hotkey
        var hotkeyID = EventHotKeyID(signature: OSType(0x5154444F), id: 1) // "QTDO"

        let registerResult = RegisterEventHotKey(
            keyCombo.keyCode,
            keyCombo.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if registerResult != noErr {
            print("QuickTodo: Failed to register hotkey (code: \(registerResult))")
        }
    }

    /// Unregisters the global hotkey
    private func unregisterHotkey() {
        // Unregister the hotkey first
        if let hotkey = hotkeyRef {
            UnregisterEventHotKey(hotkey)
            hotkeyRef = nil
        }

        // Then remove the event handler
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

// MARK: - Key Code Constants

extension HotkeyManager {
    /// Common key codes for reference
    enum KeyCode {
        static let t = UInt32(kVK_ANSI_T)
        static let space = UInt32(kVK_Space)
        static let returnKey = UInt32(kVK_Return)
    }

    /// Modifier flag constants
    enum Modifier {
        static let command = UInt32(cmdKey)
        static let shift = UInt32(shiftKey)
        static let option = UInt32(optionKey)
        static let control = UInt32(controlKey)
    }
}
