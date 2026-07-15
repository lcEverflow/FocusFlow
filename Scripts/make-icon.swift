// FocusFlow 应用图标生成器（纯 AppKit/CoreGraphics，CLT 即可编译运行）。
// 设计：番茄色圆角方（squircle）+ 白色专注计时环 + 计时器顶钮 + 绿叶点缀 + 表针。
// 输出 1024×1024 母图 PNG，供 make-icon.sh 用 sips/iconutil 生成 AppIcon.icns。
//
// 用法：swift Scripts/make-icon.swift <输出PNG路径>
import AppKit
import Foundation

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/AppIcon-1024.png"

let S: CGFloat = 1024
let c = CGPoint(x: S / 2, y: S / 2)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fatalError("cannot create bitmap rep") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.clear(CGRect(x: 0, y: 0, width: S, height: S))

// ---- 圆角方背景（macOS 图标网格：824 居中 / 圆角 ~185）----
let margin: CGFloat = 100
let side = S - margin * 2
let squircle = CGRect(x: margin, y: margin, width: side, height: side)
let bgPath = NSBezierPath(roundedRect: squircle, xRadius: 185, yRadius: 185)

let topColor = NSColor(srgbRed: 1.00, green: 0.55, blue: 0.36, alpha: 1)   // #FF8C5C 暖珊瑚
let botColor = NSColor(srgbRed: 0.89, green: 0.19, blue: 0.16, alpha: 1)   // #E33129 番茄红

ctx.saveGState()
bgPath.addClip()
NSGradient(colors: [topColor, botColor])!.draw(in: squircle, angle: -90) // 上→下
// 顶部柔和高光，制造立体感
if let gloss = NSGradient(colors: [NSColor(white: 1, alpha: 0.20), NSColor(white: 1, alpha: 0.0)]) {
    gloss.draw(fromCenter: CGPoint(x: S / 2, y: 900), radius: 0,
               toCenter: CGPoint(x: S / 2, y: 900), radius: 560, options: [])
}
ctx.restoreGState()

// ---- 专注计时环 ----
let ringR: CGFloat = 232
let lineW: CGFloat = 60

// 轨道（略透明）
let track = NSBezierPath()
track.appendArc(withCenter: c, radius: ringR, startAngle: 0, endAngle: 360)
track.lineWidth = lineW
NSColor(white: 1, alpha: 0.28).setStroke()
track.stroke()

// 进度弧（从顶端顺时针 ~72%，营造「专注进行中」）
let prog = NSBezierPath()
prog.appendArc(withCenter: c, radius: ringR, startAngle: 90, endAngle: 90 - 260, clockwise: true)
prog.lineWidth = lineW
prog.lineCapStyle = .round
NSColor.white.setStroke()
prog.stroke()

// ---- 表针 + 中心轴（点明「计时」）----
NSColor.white.setStroke()
let hand = NSBezierPath()
hand.move(to: c)
let handAngle = 62.0 * .pi / 180.0           // 指向约 1 点方向
hand.line(to: CGPoint(x: c.x + cos(handAngle) * 118, y: c.y + sin(handAngle) * 118))
hand.lineWidth = 30
hand.lineCapStyle = .round
hand.stroke()

NSColor.white.setFill()
NSBezierPath(ovalIn: CGRect(x: c.x - 26, y: c.y - 26, width: 52, height: 52)).fill()

// ---- 顶钮（厨房计时器的旋钮，坐在环的正上方）----
let knob = NSBezierPath(roundedRect: CGRect(x: c.x - 78, y: c.y + ringR + 2, width: 156, height: 66),
                        xRadius: 33, yRadius: 33)
NSColor.white.setFill()
knob.fill()

// ---- 绿叶点缀（番茄叶，斜靠在顶钮左侧）----
func leaf(base: CGPoint, tip: CGPoint, width: CGFloat, color: NSColor) {
    let dx = tip.x - base.x, dy = tip.y - base.y
    let len = max(hypot(dx, dy), 0.001)
    let px = -dy / len * width, py = dx / len * width   // 垂直方向偏移
    let p = NSBezierPath()
    p.move(to: base)
    p.curve(to: tip,
            controlPoint1: CGPoint(x: base.x + px, y: base.y + py),
            controlPoint2: CGPoint(x: tip.x + px, y: tip.y + py))
    p.curve(to: base,
            controlPoint1: CGPoint(x: tip.x - px, y: tip.y - py),
            controlPoint2: CGPoint(x: base.x - px, y: base.y - py))
    color.setFill()
    p.fill()
}
let green = NSColor(srgbRed: 0.36, green: 0.76, blue: 0.36, alpha: 1)  // #5CC25C
leaf(base: CGPoint(x: c.x - 30, y: c.y + ringR + 40),
     tip:  CGPoint(x: c.x - 132, y: c.y + ringR + 120),
     width: 34, color: green)

// ---- 导出 PNG ----
NSGraphicsContext.restoreGraphicsState()
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png encode failed") }
try! data.write(to: URL(fileURLWithPath: outPath))
FileHandle.standardError.write("wrote \(outPath)\n".data(using: .utf8)!)
