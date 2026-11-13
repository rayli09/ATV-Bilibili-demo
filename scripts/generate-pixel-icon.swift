import AppKit
import CoreGraphics
import CoreText
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("BilibiliLive/Supporting Files/Assets.xcassets/App Icon & Top Shelf Image.brandassets")
guard let artwork = NSImage(contentsOf: root.appendingPathComponent("Artwork/pixel-icon.png"))?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fatalError("Missing pixel artwork") }

func wordmark() -> CGImage {
    guard let bitmap = CGContext(data: nil, width: 176, height: 48, bitsPerComponent: 8, bytesPerRow: 176 * 4,
                                 space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("Cannot allocate wordmark") }
    bitmap.setAllowsAntialiasing(false)
    let font = CTFontCreateWithName("Menlo-Bold" as CFString, 36, nil)
    let attributes = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: NSColor.white.cgColor] as CFDictionary
    let text = CFAttributedStringCreate(nil, "bilibili" as CFString, attributes)!
    let line = CTLineCreateWithAttributedString(text)
    bitmap.textPosition = CGPoint(x: (176 - CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))) / 2, y: 8)
    CTLineDraw(line, bitmap)
    guard let image = bitmap.makeImage() else { fatalError("Cannot render wordmark") }
    return image
}

func render(_ layer: String, width: Int, height: Int, to output: URL) throws {
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError("Cannot allocate icon") }
    context.scaleBy(x: CGFloat(width) / 800, y: CGFloat(height) / 480)
    context.interpolationQuality = .none
    if layer == "Back" {
        let scale = max(800 / CGFloat(artwork.width), 480 / CGFloat(artwork.height))
        let size = CGSize(width: CGFloat(artwork.width) * scale, height: CGFloat(artwork.height) * scale)
        context.draw(artwork, in: CGRect(x: (800 - size.width) / 2, y: (480 - size.height) / 2, width: size.width, height: size.height))
    } else if layer == "Middle" {
        context.setFillColor(NSColor(srgbRed: 1, green: 0.62, blue: 0.78, alpha: 1).cgColor)
        for rect in [CGRect(x: 100, y: 306, width: 14, height: 14), CGRect(x: 236, y: 153, width: 12, height: 12), CGRect(x: 277, y: 323, width: 9, height: 9)] {
            context.fill(rect)
        }
    } else {
        context.draw(wordmark(), in: CGRect(x: 18, y: 190, width: 320, height: 87))
    }
    guard let image = context.makeImage(), let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
    try data.write(to: output)
}

for (stack, width, height) in [("App Icon", 400, 240), ("App Icon - App Store", 1280, 768)] {
    for layer in ["Back", "Middle", "Front"] {
        let directory = assets.appendingPathComponent("\(stack).imagestack/\(layer).imagestacklayer/Content.imageset")
        var images: [[String: String]] = []
        if stack == "App Icon" {
            for scale in 1...2 {
                let filename = "\(layer)\(scale == 2 ? "@2x" : "").png"
                try render(layer, width: width * scale, height: height * scale, to: directory.appendingPathComponent(filename))
                images.append(["idiom": "tv", "scale": "\(scale)x", "filename": filename])
            }
        } else {
            let filename = "\(layer).png"
            try render(layer, width: width, height: height, to: directory.appendingPathComponent(filename))
            images.append(["idiom": "tv", "filename": filename])
        }
        let manifest: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
        let json = try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: directory.appendingPathComponent("Contents.json"))
    }
}
