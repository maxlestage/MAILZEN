import SwiftUI

/// The radar of MailZen, drawn in 2D: rings, a sweep that fades behind its edge, and
/// blips that light up when the sweep passes over them (red ones ring twice).
struct RadarView: View {
    private struct Blip {
        let angle: Double
        let radius: Double
        let color: Color
        let threat: Bool
    }

    private static let blips: [Blip] = {
        var seed: UInt64 = 0x6d61_696c_7a65
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(seed >> 33) / Double(UInt32.max >> 1)
        }
        return (0..<14).map { i in
            let kind = i % 5
            let color = kind == 0 ? Theme.danger : (kind == 1 || kind == 3 ? Theme.suspicious : Theme.safe)
            return Blip(angle: next() * 2 * .pi, radius: 0.3 + next() * 0.62, color: color, threat: kind == 0)
        }
    }()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            Canvas { ctx, size in
                draw(ctx: ctx, size: size, time: context.date.timeIntervalSinceReferenceDate)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(ctx: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let r = min(size.width, size.height) / 2 - 2
        for i in 1...4 {
            let rr = r * Double(i) / 4
            ctx.stroke(Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)),
                       with: .color(Theme.cyan.opacity(0.08 + 0.04 * Double(i))), lineWidth: 1)
        }
        var cross = Path()
        cross.move(to: CGPoint(x: center.x - r, y: center.y))
        cross.addLine(to: CGPoint(x: center.x + r, y: center.y))
        cross.move(to: CGPoint(x: center.x, y: center.y - r))
        cross.addLine(to: CGPoint(x: center.x, y: center.y + r))
        ctx.stroke(cross, with: .color(Theme.cyan.opacity(0.1)), lineWidth: 1)

        // The sweep.
        let angle = (time * 1.15).truncatingRemainder(dividingBy: 2 * .pi)
        let trail = Double.pi * 0.55
        let slices = 24
        for i in 0..<slices {
            let f = Double(i) / Double(slices)
            var wedge = Path()
            wedge.move(to: center)
            wedge.addArc(center: center, radius: r,
                         startAngle: .radians(angle - trail * (1 - f)),
                         endAngle: .radians(angle - trail * (1 - f - 1 / Double(slices)) + 0.004),
                         clockwise: false)
            wedge.closeSubpath()
            ctx.fill(wedge, with: .color(Theme.cyan.opacity(pow(f, 3) * 0.3)))
        }
        var edge = Path()
        edge.move(to: center)
        edge.addLine(to: CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r))
        ctx.stroke(edge, with: .color(Theme.cyanLight.opacity(0.9)), lineWidth: 1.6)

        // Blips: lit when the sweep has just passed.
        for blip in Self.blips {
            var behind = angle - blip.angle
            if behind < 0 { behind += 2 * .pi }
            let age = behind / 1.15
            let glow = max(0, 1 - age / 4)
            guard glow > 0 else { continue }
            let p = CGPoint(x: center.x + cos(blip.angle) * blip.radius * r, y: center.y + sin(blip.angle) * blip.radius * r)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16)), with: .color(blip.color.opacity(glow * 0.25)))
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 3.2, y: p.y - 3.2, width: 6.4, height: 6.4)), with: .color(blip.color.opacity(glow)))
            if blip.threat {
                for k in 0..<2 {
                    let q = min(max((age - Double(k) * 0.35) / 1.4, 0), 1)
                    if q > 0 && q < 1 {
                        let rr = 4 + q * 22
                        ctx.stroke(Path(ellipseIn: CGRect(x: p.x - rr, y: p.y - rr, width: rr * 2, height: rr * 2)),
                                   with: .color(blip.color.opacity((1 - q) * 0.8)), lineWidth: 1.4)
                    }
                }
            }
        }
    }
}
