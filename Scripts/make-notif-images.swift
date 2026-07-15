// 通知配图生成器（纯 AppKit，CLT 即可）。与 App 图标同一视觉语言：
// 主题渐变圆角卡 + 居中白色圆底 + emoji。专注完成用番茄红，休息用青色。
// 输出 notif-focus.png / notif-break.png 到指定目录，供 UNNotificationAttachment 使用。
//
// 用法：swift Scripts/make-notif-images.swift <输出目录>
import AppKit
import Foundation

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"

func render(to path: String, top: NSColor, bottom: NSColor, emoji: String) {
    let S: CGFloat = 512
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("rep") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.clear(CGRect(x: 0, y: 0, width: S, height: S))

    // 渐变圆角卡（占满，圆角柔和）
    let card = CGRect(x: 24, y: 24, width: S - 48, height: S - 48)
    let bg = NSBezierPath(roundedRect: card, xRadius: 96, yRadius: 96)
    ctx.saveGState()
    bg.addClip()
    NSGradient(colors: [top, bottom])!.draw(in: card, angle: -90)
    if let gloss = NSGradient(colors: [NSColor(white: 1, alpha: 0.18), NSColor(white: 1, alpha: 0)]) {
        gloss.draw(fromCenter: CGPoint(x: S / 2, y: S - 60), radius: 0,
                   toCenter: CGPoint(x: S / 2, y: S - 60), radius: 300, options: [])
    }
    ctx.restoreGState()

    // 居中白色圆底
    let r: CGFloat = 150
    let circle = NSBezierPath(ovalIn: CGRect(x: S / 2 - r, y: S / 2 - r, width: 2 * r, height: 2 * r))
    NSColor(white: 1, alpha: 0.96).setFill()
    circle.fill()

    // 居中 emoji
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 170),
        .paragraphStyle: para,
    ]
    let str = emoji as NSString
    let sz = str.size(withAttributes: attrs)
    str.draw(in: CGRect(x: 0, y: S / 2 - sz.height / 2, width: S, height: sz.height), withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
    try! data.write(to: URL(fileURLWithPath: path))
    FileHandle.standardError.write("wrote \(path)\n".data(using: .utf8)!)
}

// 专注完成：番茄红（与 App 图标同色）+ 🍅
render(to: "\(outDir)/notif-focus.png",
       top: NSColor(srgbRed: 1.00, green: 0.55, blue: 0.36, alpha: 1),
       bottom: NSColor(srgbRed: 0.89, green: 0.19, blue: 0.16, alpha: 1),
       emoji: "🍅")

// 休息：青色（与 App 内 break 主题一致）+ ☕
render(to: "\(outDir)/notif-break.png",
       top: NSColor(srgbRed: 0.28, green: 0.78, blue: 0.80, alpha: 1),
       bottom: NSColor(srgbRed: 0.10, green: 0.60, blue: 0.62, alpha: 1),
       emoji: "☕")
