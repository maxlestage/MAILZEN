import SwiftUI
import MailZenKit

// MARK: - Cards and buttons

struct CardModifier: ViewModifier {
    var tint: Color = Theme.line
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(tint, lineWidth: 1))
    }
}

extension View {
    func card(tint: Color = Theme.line, padding: CGFloat = 16) -> some View {
        modifier(CardModifier(tint: tint, padding: padding))
    }

    /// Rises and fades in, `delay` seconds after appearing.
    func appear(delay: Double = 0) -> some View {
        modifier(AppearModifier(delay: delay))
    }
}

struct AppearModifier: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) { shown = true }
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.016, green: 0.063, blue: 0.094))
            .padding(.horizontal, 22)
            .frame(minHeight: 52)
            .frame(maxWidth: .infinity)
            .background(Theme.gradient, in: Capsule())
            .shadow(color: Theme.cyan.opacity(0.45), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var tint: Color = Theme.text

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .padding(.horizontal, 20)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Small pieces

struct Chip: View {
    let text: String
    var tint: Color = Theme.cyan

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
    }
}

struct VerdictBadge: View {
    let verdict: Verdict

    var body: some View {
        Label(verdict.title.localized.uppercased(), systemImage: verdict.symbol)
            .font(.caption.weight(.heavy))
            .foregroundStyle(verdict.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(verdict.color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(verdict.color.opacity(0.45), lineWidth: 1))
    }
}

struct IconBox: View {
    let systemName: String
    var tint: Color = Theme.cyanLight
    var size: CGFloat = 46

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint.opacity(0.25), tint.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).stroke(tint.opacity(0.35), lineWidth: 1))
    }
}

struct SectionTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(Theme.cyanLight)
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The score of a report, drawn as a ring that fills up.
struct GaugeView: View {
    let score: Int
    let color: Color
    var size: CGFloat = 130
    @State private var shown = 0.0

    var body: some View {
        ZStack {
            Circle().stroke(Theme.line, lineWidth: size * 0.09)
            Circle()
                .trim(from: 0, to: shown / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 10)
            VStack(spacing: 0) {
                Text("\(Int(shown))")
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText(value: shown))
                Text("/100")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) { shown = Double(score) }
        }
        .accessibilityElement()
        .accessibilityLabel("\(score)/100")
    }
}

/// Rings that pulse around an icon.
struct PulseIcon: View {
    let systemName: String
    var tint: Color = Theme.cyan
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<2) { i in
                Circle()
                    .stroke(tint.opacity(0.6), lineWidth: 1.5)
                    .scaleEffect(pulse ? 2.1 : 0.9)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(Double(i) * 1.1), value: pulse)
            }
            Image(systemName: systemName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 74, height: 74)
                .background(tint.opacity(0.14), in: Circle())
        }
        .frame(width: 120, height: 120)
        .onAppear { pulse = true }
    }
}

// MARK: - Flow layout

/// Lays its children out in rows that wrap, like chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += row + spacing
                row = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            row = max(row, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + row)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += row + spacing
                row = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            row = max(row, size.height)
        }
    }
}

/// Chips that appear one after the other.
struct ChipCloud: View {
    let items: [String]
    var tint: Color = Theme.cyan

    var body: some View {
        FlowLayout {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Chip(text: item, tint: tint)
                    .appear(delay: Double(index) * 0.03)
            }
        }
    }
}
