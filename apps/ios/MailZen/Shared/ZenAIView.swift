import SwiftUI
import MailZenKit

/// ZenAI: a conversation about a report. The answers come from the analysis only.
struct ZenAIView: View {
    let report: Report
    let message: EmailMessage?

    private struct Bubble: Identifiable {
        let id = UUID()
        let fromUser: Bool
        let lines: [String]
        /// The answer rewritten by Apple's on-device model, above the facts.
        var phrased: String? = nil
    }

    @State private var bubbles: [Bubble] = []
    @State private var question = ""
    @State private var typing = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bubbles) { bubble in
                            bubbleView(bubble).id(bubble.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        if typing {
                            HStack(spacing: 5) {
                                ForEach(0..<3) { i in
                                    Circle().fill(Theme.muted).frame(width: 7, height: 7)
                                        .opacity(0.4)
                                        .scaleEffect(typing ? 1.2 : 0.8)
                                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: typing)
                                }
                            }
                            .padding(14)
                            .background(Color(red: 0.08, green: 0.13, blue: 0.25), in: RoundedRectangle(cornerRadius: 18))
                            .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: bubbles.count) { _, _ in
                    if let id = bubbles.last?.id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
                }
            }
            suggestions
            inputBar
        }
        .background(AppBackground())
        .navigationTitle("ZenAI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if bubbles.isEmpty {
                bubbles.append(Bubble(fromUser: false, lines: ZenAI.answer(.summary, report: report, message: message)))
            }
        }
    }

    private func bubbleView(_ bubble: Bubble) -> some View {
        HStack {
            if bubble.fromUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                if !bubble.fromUser {
                    Label(bubble.phrased == nil ? "ZenAI" : "ZenAI · Apple Intelligence", systemImage: "sparkles")
                        .font(.caption.weight(.bold)).foregroundStyle(Theme.cyanLight)
                }
                if let phrased = bubble.phrased {
                    Text(phrased).font(.subheadline).foregroundStyle(Theme.text).textSelection(.enabled)
                    Text(tr("D’après l’analyse :", "From the analysis:", "Según el análisis:"))
                        .font(.caption2.weight(.bold)).foregroundStyle(Theme.muted).padding(.top, 4)
                }
                ForEach(Array(bubble.lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(bubble.phrased == nil ? .subheadline : .caption)
                        .foregroundStyle(bubble.phrased == nil ? Theme.text : Theme.muted)
                        .textSelection(.enabled)
                }
            }
            .padding(14)
            .background(
                bubble.fromUser
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.05, green: 0.45, blue: 0.56), Color(red: 0.06, green: 0.46, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color(red: 0.08, green: 0.13, blue: 0.25)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            if !bubble.fromUser { Spacer(minLength: 24) }
        }
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(ZenAI.suggestions.enumerated()), id: \.offset) { _, item in
                    Button { ask(item.1.localized, intent: item.0) } label: {
                        Chip(text: item.1.localized)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(tr("Posez votre question…", "Ask your question…", "Haz tu pregunta…"), text: $question)
                .padding(12)
                .background(Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.line))
                .submitLabel(.send)
                .onSubmit { send() }
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)).foregroundStyle(Theme.gradient)
            }
            .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    private func send() {
        let text = question.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        question = ""
        ask(text, intent: ZenAI.intent(of: text))
    }

    private func ask(_ text: String, intent: ZenAI.Intent) {
        withAnimation(.spring) { bubbles.append(Bubble(fromUser: true, lines: [text])) }
        typing = true
        Task {
            let lines = ZenAI.answer(intent, report: report, message: message)
            var phrased: String?
            if OnDeviceModel.isAvailable {
                phrased = await OnDeviceModel.phrase(question: text, facts: lines)
            } else {
                try? await Task.sleep(for: .milliseconds(650))
            }
            typing = false
            withAnimation(.spring) {
                bubbles.append(Bubble(fromUser: false, lines: lines, phrased: phrased))
            }
        }
    }
}
