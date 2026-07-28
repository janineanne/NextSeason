import AppKit

private typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat)

/// One rendered appearance (light or dark) of a palette's icon.
private struct IconAppearance {
    let fileName: String
    let background: RGB
    let foreground: RGB
}

/// A single appearance-aware app icon set. iOS swaps `light`/`dark` automatically
/// based on the system appearance, so we no longer generate per-scheme icon sets.
private struct ThemeIconSpec {
    let assetName: String
    let light: IconAppearance
    let dark: IconAppearance
}

private let themeIcons: [ThemeIconSpec] = [
    ThemeIconSpec(
        assetName: "AppIcon",
        light: IconAppearance(
            fileName: "AppIcon.png",
            background: (0.941, 0.949, 0.945),
            foreground: (0.051, 0.420, 0.388)
        ),
        dark: IconAppearance(
            fileName: "AppIcon-Dark.png",
            background: (0.102, 0.114, 0.110),
            foreground: (0.431, 0.792, 0.737)
        )
    ),
]

private enum IconLayout {
    static let pixelSize = 1024
    static let cornerRadius: CGFloat = 224
    static let tvPointSize: CGFloat = 560
    static let calendarPointSize: CGFloat = 500
    static let groupSize = CGSize(width: 817, height: 824)
    static let calendarOffset = CGPoint(x: 317, y: 324)
}

private func nsColor(_ rgb: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> NSColor {
    NSColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
}

private func tintedSymbol(named name: String, pointSize: CGFloat, color: NSColor) -> NSImage? {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
}

private struct SymbolDrawLayout {
    let groupOriginX: CGFloat
    let groupTop: CGFloat
}

private func symbolLayout(groupOriginX: CGFloat, groupTop: CGFloat, canvasHeight: CGFloat) -> (tv: NSRect, calendar: NSRect) {
    let tv = NSRect(
        x: groupOriginX,
        y: groupTop - IconLayout.tvPointSize,
        width: IconLayout.tvPointSize,
        height: IconLayout.tvPointSize
    )
    let calendar = NSRect(
        x: groupOriginX + IconLayout.calendarOffset.x,
        y: groupTop - IconLayout.calendarOffset.y - IconLayout.calendarPointSize,
        width: IconLayout.calendarPointSize,
        height: IconLayout.calendarPointSize
    )
    return (tv, calendar)
}

private func inkBoundsUIKit(
    in rep: NSBitmapImageRep,
    background: (red: CGFloat, green: CGFloat, blue: CGFloat)
) -> CGRect? {
    guard
        let data = rep.bitmapData,
        rep.samplesPerPixel >= 3
    else { return nil }

    let width = rep.pixelsWide
    let height = rep.pixelsHigh
    let bytesPerPixel = rep.bitsPerPixel / 8
    let threshold = 24

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    var found = false

    let bgR = UInt8(background.red * 255)
    let bgG = UInt8(background.green * 255)
    let bgB = UInt8(background.blue * 255)

    for y in 0..<height {
        for x in 0..<width {
            let offset = y * rep.bytesPerRow + x * bytesPerPixel
            let r = data[offset]
            let g = data[offset + 1]
            let b = data[offset + 2]
            let a = bytesPerPixel > 3 ? data[offset + 3] : 255

            guard a > 16 else { continue }
            let dr = abs(Int(r) - Int(bgR))
            let dg = abs(Int(g) - Int(bgG))
            let db = abs(Int(b) - Int(bgB))
            guard dr + dg + db > threshold else { continue }

            found = true
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }

    guard found else { return nil }

    return CGRect(
        x: CGFloat(minX),
        y: CGFloat(minY),
        width: CGFloat(maxX - minX + 1),
        height: CGFloat(maxY - minY + 1)
    )
}

private func makeMeasurementBitmap() -> NSBitmapImageRep? {
    NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: IconLayout.pixelSize,
        pixelsHigh: IconLayout.pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
}

private func measureSymbolInk(
    symbol: NSImage,
    drawRect: NSRect,
    background: (red: CGFloat, green: CGFloat, blue: CGFloat)
) -> CGRect? {
    guard let rep = makeMeasurementBitmap() else { return nil }

    let canvas = CGFloat(IconLayout.pixelSize)
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    nsColor(background).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvas, height: canvas)).fill()
    symbol.draw(in: drawRect)

    return inkBoundsUIKit(in: rep, background: background)
}

/// Positions the TV/calendar pair so ink from the TV top-left to the calendar bottom-right
/// has equal padding on all four sides of the icon canvas.
private func equalMarginLayout(
    tvSymbol: NSImage,
    calendarSymbol: NSImage,
    background: (red: CGFloat, green: CGFloat, blue: CGFloat)
) -> SymbolDrawLayout {
    let canvas = CGFloat(IconLayout.pixelSize)
    let referenceTop = IconLayout.groupSize.height
    let reference = symbolLayout(groupOriginX: 0, groupTop: referenceTop, canvasHeight: canvas)

    guard
        let tvInk = measureSymbolInk(symbol: tvSymbol, drawRect: reference.tv, background: background),
        let calendarInk = measureSymbolInk(symbol: calendarSymbol, drawRect: reference.calendar, background: background)
    else {
        return SymbolDrawLayout(
            groupOriginX: (canvas - IconLayout.groupSize.width) / 2,
            groupTop: (canvas + IconLayout.groupSize.height) / 2
        )
    }

    let footprintWidth = calendarInk.maxX - tvInk.minX
    let footprintHeight = calendarInk.maxY - tvInk.minY
    let marginX = (canvas - footprintWidth) / 2
    let marginY = (canvas - footprintHeight) / 2

    // UIKit coordinates: shift content so TV ink anchors the top-left margin.
    let shiftX = marginX - tvInk.minX
    let shiftY = marginY - tvInk.minY

    return SymbolDrawLayout(
        groupOriginX: shiftX,
        groupTop: referenceTop - shiftY
    )
}

private func drawIcon(appearance: IconAppearance) throws -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
    guard let ctx = CGContext(
        data: nil,
        width: IconLayout.pixelSize,
        height: IconLayout.pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw NSError(domain: "IconPreview", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap"])
    }

    let canvas = CGFloat(IconLayout.pixelSize)
    ctx.setFillColor(nsColor(appearance.background).cgColor)
    ctx.addPath(
        CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: canvas, height: canvas),
            cornerWidth: IconLayout.cornerRadius,
            cornerHeight: IconLayout.cornerRadius,
            transform: nil
        )
    )
    ctx.fillPath()

    let accent = nsColor(appearance.foreground)
    guard
        let tvSymbol = tintedSymbol(named: "sparkles.tv", pointSize: IconLayout.tvPointSize, color: accent),
        let calendarSymbol = tintedSymbol(named: "calendar", pointSize: IconLayout.calendarPointSize, color: accent)
    else {
        throw NSError(domain: "IconPreview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load SF Symbols"])
    }

    let layout = equalMarginLayout(
        tvSymbol: tvSymbol,
        calendarSymbol: calendarSymbol,
        background: appearance.background
    )
    let rects = symbolLayout(groupOriginX: layout.groupOriginX, groupTop: layout.groupTop, canvasHeight: canvas)
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    tvSymbol.draw(in: rects.tv)
    calendarSymbol.draw(in: rects.calendar)

    guard let image = ctx.makeImage() else {
        throw NSError(domain: "IconPreview", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create output image"])
    }

    return image
}

private func pngData(from image: CGImage) throws -> Data {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconPreview", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }
    return png
}

private func writeAppIconSet(spec: ThemeIconSpec, assetsRoot: URL) throws {
    let iconSetURL = assetsRoot.appendingPathComponent("\(spec.assetName).appiconset", isDirectory: true)
    try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

    let lightImage = try drawIcon(appearance: spec.light)
    try pngData(from: lightImage).write(to: iconSetURL.appendingPathComponent(spec.light.fileName))

    let darkImage = try drawIcon(appearance: spec.dark)
    try pngData(from: darkImage).write(to: iconSetURL.appendingPathComponent(spec.dark.fileName))

    // Single 1024 image per appearance; iOS renders all sizes and swaps the
    // dark variant automatically (no `setAlternateIconName` for light/dark).
    let contents = """
    {
      "images" : [
        {
          "filename" : "\(spec.light.fileName)",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "filename" : "\(spec.dark.fileName)",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try (contents + "\n").write(to: iconSetURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

let assetsRoot = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
for spec in themeIcons {
    try writeAppIconSet(spec: spec, assetsRoot: assetsRoot)
    print("Wrote \(spec.assetName)")
}
