#!/usr/bin/env swift

import Cocoa

// MARK: - Icon Generator

/// Generates a todo-list style app icon at the specified size
func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let scale = s / 512.0

    // Background - rounded rectangle with gradient
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: s * 0.02, dy: s * 0.02),
                               xRadius: s * 0.18,
                               yRadius: s * 0.18)

    // Gradient background (light blue to white)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0),
        NSColor.white
    ])
    gradient?.draw(in: bgPath, angle: -90)

    // Subtle border
    NSColor(red: 0.85, green: 0.87, blue: 0.9, alpha: 1.0).setStroke()
    bgPath.lineWidth = 2 * scale
    bgPath.stroke()

    // Content area
    let padding = s * 0.15
    let contentRect = rect.insetBy(dx: padding, dy: padding)

    // Draw 3 todo items
    let lineHeight = contentRect.height / 4
    let circleSize = lineHeight * 0.5
    let lineStartX = contentRect.minX + circleSize + 20 * scale
    let lineEndX = contentRect.maxX - 10 * scale

    // Colors
    let accentColor = NSColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0) // #007AFF
    let checkColor = NSColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0) // Green
    let lineColor = NSColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0)
    let completedLineColor = NSColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0)

    for i in 0..<3 {
        let y = contentRect.maxY - lineHeight * CGFloat(i + 1) + lineHeight * 0.25
        let circleX = contentRect.minX + 5 * scale
        let circleY = y - circleSize * 0.5

        let circleRect = NSRect(x: circleX, y: circleY, width: circleSize, height: circleSize)
        let circlePath = NSBezierPath(ovalIn: circleRect)

        if i == 0 {
            // First item - completed (green checkmark)
            checkColor.setFill()
            circlePath.fill()

            // Draw checkmark
            let checkPath = NSBezierPath()
            let cx = circleRect.midX
            let cy = circleRect.midY
            let cs = circleSize * 0.25

            checkPath.move(to: NSPoint(x: cx - cs, y: cy))
            checkPath.line(to: NSPoint(x: cx - cs * 0.3, y: cy - cs * 0.7))
            checkPath.line(to: NSPoint(x: cx + cs, y: cy + cs * 0.5))

            NSColor.white.setStroke()
            checkPath.lineWidth = 3 * scale
            checkPath.lineCapStyle = .round
            checkPath.lineJoinStyle = .round
            checkPath.stroke()

            // Completed line (strikethrough style, lighter)
            completedLineColor.setStroke()
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: lineStartX, y: y))
            linePath.line(to: NSPoint(x: lineEndX * 0.7, y: y))
            linePath.lineWidth = 4 * scale
            linePath.lineCapStyle = .round
            linePath.stroke()

        } else {
            // Uncompleted items - blue circle outline
            accentColor.setStroke()
            circlePath.lineWidth = 2.5 * scale
            circlePath.stroke()

            // Todo line
            lineColor.setStroke()
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: lineStartX, y: y))

            // Vary line lengths
            let lineLength = i == 1 ? 0.85 : 0.6
            linePath.line(to: NSPoint(x: lineStartX + (lineEndX - lineStartX) * lineLength, y: y))
            linePath.lineWidth = 4 * scale
            linePath.lineCapStyle = .round
            linePath.stroke()
        }
    }

    image.unlockFocus()
    return image
}

/// Saves an NSImage as PNG to the specified path at exact pixel dimensions
func saveAsPNG(_ image: NSImage, to path: String, pixelSize: Int) {
    // Create a bitmap at exact pixel dimensions
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        print("✗ Failed to create bitmap for \(path)")
        return
    }

    bitmap.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy,
               fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("✗ Failed to create PNG data for \(path)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("✓ Created \(path) (\(pixelSize)x\(pixelSize))")
    } catch {
        print("✗ Failed to write \(path): \(error)")
    }
}

// MARK: - Main

// Get the directory where the script is located
let fileManager = FileManager.default
let currentDir = fileManager.currentDirectoryPath
let iconsetPath = "\(currentDir)/QuickTodo/Resources/Assets.xcassets/AppIcon.appiconset"

print("Generating QuickTodo app icons...")
print("Output directory: \(iconsetPath)")
print("")

// Icon sizes for macOS app icon (actual pixel dimensions needed)
let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let icon = generateIcon(size: size)
    let path = "\(iconsetPath)/\(name)"
    saveAsPNG(icon, to: path, pixelSize: size)
}

print("")
print("Done! Don't forget to update Contents.json with the new filenames.")
