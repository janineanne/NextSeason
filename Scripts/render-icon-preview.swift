import AppKit

private struct ThemeIconSpec {
    let assetName: String
    let fileName: String
    let background: (red: CGFloat, green: CGFloat, blue: CGFloat)
    let foreground: (red: CGFloat, green: CGFloat, blue: CGFloat)
}

private let themeIcons: [ThemeIconSpec] = [
    ThemeIconSpec(
        assetName: "AppIcon",
        fileName: "AppIcon.png",
        background: (0.902, 0.886, 0.933),
        foreground: (0.365, 0.306, 0.443)
    ),
    ThemeIconSpec(
        assetName: "AppIcon-LavenderDark",
        fileName: "AppIcon-LavenderDark.png",
        background: (0.149, 0.129, 0.196),
        foreground: (0.659, 0.596, 0.769)
    ),
    ThemeIconSpec(
        assetName: "AppIcon-TealUtilityLight",
        fileName: "AppIcon-TealUtilityLight.png",
        background: (0.941, 0.949, 0.945),
        foreground: (0.051, 0.420, 0.388)
    ),
    ThemeIconSpec(
        assetName: "AppIcon-TealUtilityDark",
        fileName: "AppIcon-TealUtilityDark.png",
        background: (0.102, 0.114, 0.110),
        foreground: (0.431, 0.792, 0.737)
    ),
    ThemeIconSpec(
        assetName: "AppIcon-WarmSlateLight",
        fileName: "AppIcon-WarmSlateLight.png",
        background: (0.969, 0.961, 0.949),
        foreground: (0.200, 0.255, 0.333)
    ),
    ThemeIconSpec(
        assetName: "AppIcon-WarmSlateDark",
        fileName: "AppIcon-WarmSlateDark.png",
        background: (0.110, 0.098, 0.090),
        foreground: (0.796, 0.835, 0.882)
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

private func drawIcon(spec: ThemeIconSpec) throws -> CGImage {
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
    ctx.setFillColor(nsColor(spec.background).cgColor)
    ctx.addPath(
        CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: canvas, height: canvas),
            cornerWidth: IconLayout.cornerRadius,
            cornerHeight: IconLayout.cornerRadius,
            transform: nil
        )
    )
    ctx.fillPath()

    let accent = nsColor(spec.foreground)
    guard
        let tvSymbol = tintedSymbol(named: "sparkles.tv", pointSize: IconLayout.tvPointSize, color: accent),
        let calendarSymbol = tintedSymbol(named: "calendar", pointSize: IconLayout.calendarPointSize, color: accent)
    else {
        throw NSError(domain: "IconPreview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load SF Symbols"])
    }

    let layout = equalMarginLayout(
        tvSymbol: tvSymbol,
        calendarSymbol: calendarSymbol,
        background: spec.background
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

private func resizedPNG(from image: CGImage, pixelSize: Int) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
    guard let ctx = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw NSError(domain: "IconPreview", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create resize context"])
    }

    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    guard let resized = ctx.makeImage() else {
        throw NSError(domain: "IconPreview", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to resize icon"])
    }

    return try pngData(from: resized)
}

private func writeAppIconSet(spec: ThemeIconSpec, assetsRoot: URL) throws {
    let iconSetURL = assetsRoot.appendingPathComponent("\(spec.assetName).appiconset", isDirectory: true)
    try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

    let sourceImage = try drawIcon(spec: spec)
    try pngData(from: sourceImage).write(to: iconSetURL.appendingPathComponent(spec.fileName))

    let isAlternateIcon = spec.assetName != "AppIcon"
    if isAlternateIcon {
        try resizedPNG(from: sourceImage, pixelSize: 120).write(to: iconSetURL.appendingPathComponent("\(spec.assetName)-120.png"))
        try resizedPNG(from: sourceImage, pixelSize: 152).write(to: iconSetURL.appendingPathComponent("\(spec.assetName)-152.png"))
    }

    let baseName = spec.assetName
    let legacyEntries = isAlternateIcon
        ? """
        {
          "filename" : "\(baseName)-120.png",
          "idiom" : "iphone",
          "scale" : "2x",
          "size" : "60x60"
        },
        {
          "filename" : "\(baseName)-152.png",
          "idiom" : "ipad",
          "scale" : "2x",
          "size" : "76x76"
        },
        """
        : ""
    let contents = """
    {
      "images" : [
        \(legacyEntries){
          "filename" : "\(spec.fileName)",
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
    try contents.write(to: iconSetURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

let assetsRoot = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
for spec in themeIcons {
    try writeAppIconSet(spec: spec, assetsRoot: assetsRoot)
    print("Wrote \(spec.assetName)")
}
