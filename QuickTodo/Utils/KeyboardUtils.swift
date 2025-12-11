//
//  KeyboardUtils.swift
//  QuickTodo
//
//  Shared keyboard utilities and key code constants
//

import Foundation
import Carbon

// MARK: - Key Code Constants

/// macOS virtual key codes for keyboard handling.
///
/// These correspond to the physical key positions on a US keyboard layout.
/// Use `rawValue` to compare with `NSEvent.keyCode`.
enum KeyCode: UInt16 {
    // Letters (QWERTY layout)
    case a = 0
    case s = 1
    case d = 2
    case f = 3
    case h = 4
    case g = 5
    case z = 6
    case x = 7
    case c = 8
    case v = 9
    case b = 11
    case q = 12
    case w = 13
    case e = 14
    case r = 15
    case y = 16
    case t = 17
    case o = 31
    case u = 32
    case i = 34
    case p = 35
    case l = 37
    case j = 38
    case k = 40
    case n = 45
    case m = 46

    // Numbers
    case one = 18
    case two = 19
    case three = 20
    case four = 21
    case five = 23
    case six = 22
    case seven = 26
    case eight = 28
    case nine = 25
    case zero = 29

    // Punctuation & Symbols
    case equals = 24
    case minus = 27
    case rightBracket = 30
    case leftBracket = 33
    case quote = 39
    case semicolon = 41
    case backslash = 42
    case comma = 43
    case slash = 44
    case period = 47
    case grave = 50

    // Special keys
    case `return` = 36
    case tab = 48
    case space = 49
    case delete = 51
    case escape = 53
    case forwardDelete = 117

    // Arrow keys
    case leftArrow = 123
    case rightArrow = 124
    case downArrow = 125
    case upArrow = 126

    // Function keys
    case f1 = 122
    case f2 = 120
    case f3 = 99
    case f4 = 118
    case f5 = 96
    case f6 = 97
    case f7 = 98
    case f8 = 100
    case f9 = 101
    case f10 = 109
    case f11 = 103
    case f12 = 111
}

// MARK: - Key Combo Formatting

/// Formats a key combination as a human-readable string with modifier symbols.
///
/// - Parameters:
///   - keyCode: The virtual key code
///   - modifiers: Carbon modifier flags (cmdKey, shiftKey, etc.)
/// - Returns: A formatted string like "⌘⇧T"
func formatKeyCombo(keyCode: UInt32, modifiers: UInt32) -> String {
    var result = ""

    // Modifiers in standard macOS order: ⌃⌥⇧⌘
    if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
    if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
    if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
    if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }

    // Key
    result += keyCodeToString(keyCode)

    return result
}

/// Converts a virtual key code to its string representation.
///
/// - Parameter keyCode: The virtual key code
/// - Returns: A string representing the key (e.g., "A", "↩", "F1")
func keyCodeToString(_ keyCode: UInt32) -> String {
    let keyMap: [UInt32: String] = [
        // Letters
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
        38: "J", 40: "K", 45: "N", 46: "M",

        // Numbers
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 25: "9", 26: "7", 28: "8", 29: "0",

        // Punctuation
        24: "=", 27: "-", 30: "]", 33: "[", 39: "'",
        41: ";", 42: "\\", 43: ",", 44: "/", 47: ".", 50: "`",

        // Special keys
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦",

        // Arrow keys
        123: "←", 124: "→", 125: "↓", 126: "↑",

        // Function keys
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
        97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10",
        103: "F11", 111: "F12"
    ]

    return keyMap[keyCode] ?? "?"
}

// MARK: - Event Monitor Type Alias

/// Type alias for NSEvent monitor references.
///
/// NSEvent's `addLocalMonitorForEvents` and `addGlobalMonitorForEvents`
/// return an opaque `Any?` type. This alias provides semantic clarity.
typealias EventMonitorRef = Any
