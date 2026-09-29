import AppKit

// Generates Resources/AppIcon.png (1024px) — deep-green rounded square + 99-point star mark.
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon.png"
let px = 1024

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: px,
    pixelsHigh: px,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { fatalError("could not create bitmap") }

rep.size = NSSize(width: px, height: px)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let rect = NSRect(x: 0, y: 0, width: px, height: px)
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 10, dy: 10), xRadius: 210, yRadius: 210)

let top = NSColor(red: 0.07, green: 0.45, blue: 0.33, alpha: 1)
let bottom = NSColor(red: 0.02, green: 0.24, blue: 0.20, alpha: 1)
NSGradient(colors: [top, bottom])?.draw(in: path, angle: -90)

// eight-pointed star (khatim) outline
let center = CGPoint(x: CGFloat(px) / 2, y: CGFloat(px) / 2)
let outer: CGFloat = 300
let inner: CGFloat = 130
let star = NSBezierPath()
for i in 0..<16 {
    let r = i % 2 == 0 ? outer : inner
    let a = Double(i) * Double.pi / 8 - Double.pi / 2
    let p = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
    if i == 0 { star.move(to: p) } else { star.line(to: p) }
}
star.close()
NSColor.white.withAlphaComponent(0.95).setStroke()
star.lineWidth = 26
star.stroke()

// ring inside the star
let ring = NSBezierPath(ovalIn: NSRect(x: center.x - 96, y: center.y - 96, width: 192, height: 192))
NSColor.white.withAlphaComponent(0.95).setStroke()
ring.lineWidth = 22
ring.stroke()

// a small dot above the ring
let dot = NSBezierPath(ovalIn: NSRect(x: center.x - 26, y: center.y + 108, width: 52, height: 52))
NSColor.white.setFill()
dot.fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode png")
}

let url = URL(fileURLWithPath: outPath)
try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
try png.write(to: url)
print("wrote \(outPath)")
