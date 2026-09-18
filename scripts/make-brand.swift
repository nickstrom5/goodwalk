// Generates the app icon, the sample dog used in screenshots, and the social images from code,
// so the brand is reproducible.
// Run: swift scripts/make-brand.swift   (from the repo root; needs macOS, no dependencies)
import AppKit
import CoreGraphics

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: a) }

let cream = rgb(0.980, 0.961, 0.925)
let oat = rgb(0.949, 0.918, 0.867)
let terracotta = rgb(0.929, 0.455, 0.200)
let terracottaDeep = rgb(0.788, 0.333, 0.106)
let brown = rgb(0.180, 0.133, 0.098)
let leaf = rgb(0.298, 0.624, 0.439)
let white = rgb(1, 1, 1)

func context(_ w: Int, _ h: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    return ctx
}

func save(_ ctx: CGContext, _ path: String) {
    let image = ctx.makeImage()!
    let rep = NSBitmapImageRep(cgImage: image)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

func gradient(_ ctx: CGContext, _ rect: CGRect, top: CGColor, bottom: CGColor) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.clip(to: rect)
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
    ctx.restoreGState()
}

func ellipse(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, rotation: CGFloat = 0, _ color: CGColor) {
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: rotation * .pi / 180)
    ctx.setFillColor(color)
    ctx.fillEllipse(in: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
    ctx.restoreGState()
}

/// A paw: one big pad and four toes. `size` is the overall height.
func drawPaw(_ ctx: CGContext, center: CGPoint, size s: CGFloat, color: CGColor) {
    ellipse(ctx, cx: center.x, cy: center.y - s * 0.17, rx: s * 0.30, ry: s * 0.24, color)
    ellipse(ctx, cx: center.x - s * 0.36, cy: center.y + s * 0.08, rx: s * 0.105, ry: s * 0.14, rotation: 24, color)
    ellipse(ctx, cx: center.x - s * 0.14, cy: center.y + s * 0.30, rx: s * 0.11, ry: s * 0.155, rotation: 8, color)
    ellipse(ctx, cx: center.x + s * 0.14, cy: center.y + s * 0.30, rx: s * 0.11, ry: s * 0.155, rotation: -8, color)
    ellipse(ctx, cx: center.x + s * 0.36, cy: center.y + s * 0.08, rx: s * 0.105, ry: s * 0.14, rotation: -24, color)
}

/// Today's ring, three quarters full, with the paw inside. The mark is the product: a dog in a ring.
func drawMark(_ ctx: CGContext, center: CGPoint, diameter d: CGFloat, track: CGColor, arc: CGColor, paw: CGColor) {
    let width = d * 0.085
    let radius = d / 2 - width / 2
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(track)
    ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()
    ctx.setStrokeColor(arc)
    // From 12 o'clock, clockwise, 78% of the way round.
    ctx.addArc(center: center, radius: radius, startAngle: .pi / 2, endAngle: .pi / 2 - .pi * 2 * 0.78, clockwise: true)
    ctx.strokePath()
    drawPaw(ctx, center: CGPoint(x: center.x, y: center.y - d * 0.02), size: d * 0.52, color: paw)
}

func roundedRect(_ ctx: CGContext, _ rect: CGRect, _ radius: CGFloat, _ color: CGColor) {
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(color)
    ctx.fillPath()
}

func drawText(_ ctx: CGContext, _ text: String, at point: CGPoint, size: CGFloat, color: CGColor, weight: NSFont.Weight = .bold) {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    let font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: size) } ?? base
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(cgColor: color)!]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    ctx.saveGState()
    ctx.textPosition = point
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

/// Rex: the illustrated sample dog used by `-screenshot` launches. A friendly tan mutt in a park.
/// Real App Store screenshots should use a real dog; this keeps the repo free of stock photos.
func drawSampleDog(_ ctx: CGContext, side s: CGFloat) {
    let u = s / 1024
    gradient(ctx, CGRect(x: 0, y: 0, width: s, height: s), top: rgb(0.74, 0.87, 0.94), bottom: rgb(0.93, 0.95, 0.90))
    // Sun haze, hills, grass.
    ellipse(ctx, cx: 800 * u, cy: 860 * u, rx: 150 * u, ry: 150 * u, rgb(1.0, 0.93, 0.70, 0.9))
    ellipse(ctx, cx: 200 * u, cy: 250 * u, rx: 620 * u, ry: 300 * u, rgb(0.56, 0.76, 0.52))
    ellipse(ctx, cx: 880 * u, cy: 200 * u, rx: 600 * u, ry: 300 * u, rgb(0.46, 0.70, 0.47))
    ctx.setFillColor(rgb(0.40, 0.65, 0.43))
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: 210 * u))

    let fur = rgb(0.82, 0.60, 0.36)
    let furDark = rgb(0.47, 0.30, 0.17)
    let furLight = rgb(0.97, 0.90, 0.78)
    // Chest and collar.
    ellipse(ctx, cx: 512 * u, cy: 60 * u, rx: 300 * u, ry: 330 * u, fur)
    ellipse(ctx, cx: 512 * u, cy: 40 * u, rx: 150 * u, ry: 250 * u, furLight)
    roundedRect(ctx, CGRect(x: 322 * u, y: 268 * u, width: 380 * u, height: 58 * u), 29 * u, terracotta)
    ellipse(ctx, cx: 512 * u, cy: 248 * u, rx: 30 * u, ry: 30 * u, rgb(0.98, 0.80, 0.30))
    // Ears behind the head.
    ellipse(ctx, cx: 250 * u, cy: 560 * u, rx: 105 * u, ry: 215 * u, rotation: -16, furDark)
    ellipse(ctx, cx: 774 * u, cy: 560 * u, rx: 105 * u, ry: 215 * u, rotation: 16, furDark)
    // Head, eye patch, muzzle.
    ellipse(ctx, cx: 512 * u, cy: 560 * u, rx: 270 * u, ry: 262 * u, fur)
    ellipse(ctx, cx: 630 * u, cy: 640 * u, rx: 105 * u, ry: 120 * u, rotation: -12, rgb(0.66, 0.44, 0.24))
    ellipse(ctx, cx: 512 * u, cy: 690 * u, rx: 48 * u, ry: 130 * u, furLight)
    ellipse(ctx, cx: 512 * u, cy: 450 * u, rx: 170 * u, ry: 135 * u, furLight)
    // Eyes.
    for x in [400.0, 624.0] {
        ellipse(ctx, cx: x * u, cy: 630 * u, rx: 36 * u, ry: 40 * u, rgb(0.13, 0.09, 0.07))
        ellipse(ctx, cx: (x + 12) * u, cy: 645 * u, rx: 11 * u, ry: 11 * u, white)
    }
    // Tongue, mouth, nose.
    roundedRect(ctx, CGRect(x: 470 * u, y: 318 * u, width: 84 * u, height: 120 * u), 42 * u, rgb(0.95, 0.52, 0.55))
    ctx.setStrokeColor(rgb(0.13, 0.09, 0.07))
    ctx.setLineWidth(12 * u)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: 512 * u, y: 490 * u))
    ctx.addLine(to: CGPoint(x: 512 * u, y: 440 * u))
    ctx.strokePath()
    ctx.addArc(center: CGPoint(x: 462 * u, y: 446 * u), radius: 50 * u, startAngle: 0, endAngle: -.pi * 0.8, clockwise: true)
    ctx.strokePath()
    ctx.addArc(center: CGPoint(x: 562 * u, y: 446 * u), radius: 50 * u, startAngle: .pi, endAngle: -.pi * 0.2, clockwise: false)
    ctx.strokePath()
    ellipse(ctx, cx: 512 * u, cy: 515 * u, rx: 56 * u, ry: 40 * u, rgb(0.13, 0.09, 0.07))
    ellipse(ctx, cx: 496 * u, cy: 528 * u, rx: 16 * u, ry: 9 * u, rgb(1, 1, 1, 0.35))
}

let root = FileManager.default.currentDirectoryPath

// App icon: 1024, no rounded corners (iOS masks it).
do {
    let ctx = context(1024, 1024)
    gradient(ctx, CGRect(x: 0, y: 0, width: 1024, height: 1024), top: rgb(0.965, 0.545, 0.270), bottom: terracottaDeep)
    drawMark(ctx, center: CGPoint(x: 512, y: 512), diameter: 700, track: rgb(1, 1, 1, 0.25), arc: white, paw: white)
    save(ctx, "\(root)/GoodWalk/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
}

// Sample dog for screenshots.
do {
    let ctx = context(1024, 1024)
    drawSampleDog(ctx, side: 1024)
    save(ctx, "\(root)/GoodWalk/Resources/Assets.xcassets/SampleDog.imageset/SampleDog.png")
}

// Profile pictures (rounded, padded for circular crops).
for size in [1024, 400] {
    let s = CGFloat(size)
    let ctx = context(size, size)
    roundedRect(ctx, CGRect(x: 0, y: 0, width: s, height: s), s * 0.22, terracotta)
    drawMark(ctx, center: CGPoint(x: s / 2, y: s / 2), diameter: s * 0.56, track: rgb(1, 1, 1, 0.25), arc: white, paw: white)
    save(ctx, "\(root)/docs/brand/profile-\(size).png")
}

// Banner 1500x500 for X / YouTube.
do {
    let ctx = context(1500, 500)
    ctx.setFillColor(cream)
    ctx.fill(CGRect(x: 0, y: 0, width: 1500, height: 500))
    drawMark(ctx, center: CGPoint(x: 270, y: 250), diameter: 300, track: oat, arc: terracotta, paw: terracotta)
    drawText(ctx, "Good Walk", at: CGPoint(x: 480, y: 250), size: 120, color: brown)
    drawText(ctx, "Every dog deserves a good walk.", at: CGPoint(x: 486, y: 165), size: 46, color: rgb(0.180, 0.133, 0.098, 0.66), weight: .semibold)
    save(ctx, "\(root)/docs/brand/banner-1500x500.png")
}

// First post image: the reveal number, square.
do {
    let ctx = context(1080, 1080)
    ctx.setFillColor(cream)
    ctx.fill(CGRect(x: 0, y: 0, width: 1080, height: 1080))
    roundedRect(ctx, CGRect(x: 90, y: 90, width: 900, height: 900), 80, white)
    drawMark(ctx, center: CGPoint(x: 190, y: 890), diameter: 90, track: oat, arc: terracotta, paw: terracotta)
    drawText(ctx, "Good Walk", at: CGPoint(x: 256, y: 872), size: 54, color: rgb(0.180, 0.133, 0.098, 0.66), weight: .semibold)
    drawText(ctx, "A dog like Rex needs about", at: CGPoint(x: 150, y: 690), size: 56, color: brown, weight: .semibold)
    drawText(ctx, "60 min", at: CGPoint(x: 150, y: 510), size: 190, color: terracotta)
    drawText(ctx, "a day. The typical", at: CGPoint(x: 150, y: 400), size: 56, color: brown, weight: .semibold)
    drawText(ctx, "dog gets about", at: CGPoint(x: 150, y: 330), size: 56, color: brown, weight: .semibold)
    drawText(ctx, "23.", at: CGPoint(x: 150, y: 170), size: 150, color: rgb(0.870, 0.600, 0.130))
    save(ctx, "\(root)/docs/brand/post-reveal.png")
}
