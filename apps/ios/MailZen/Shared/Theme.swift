import SwiftUI
import MailZenKit

/// The colors of MailZen: night blue, cyan, turquoise; green, amber, orange and red for
/// the verdicts.
enum Theme {
    static let background = Color(red: 0.024, green: 0.043, blue: 0.102)
    static let background2 = Color(red: 0.039, green: 0.075, blue: 0.157)
    static let surface = Color(red: 0.58, green: 0.77, blue: 1).opacity(0.06)
    static let line = Color(red: 0.58, green: 0.77, blue: 1).opacity(0.16)
    static let text = Color(red: 0.91, green: 0.95, blue: 1)
    static let muted = Color(red: 0.58, green: 0.65, blue: 0.78)
    static let cyan = Color(red: 0.133, green: 0.827, blue: 0.933)
    static let cyanLight = Color(red: 0.404, green: 0.91, blue: 0.976)
    static let teal = Color(red: 0.176, green: 0.831, blue: 0.749)
    static let safe = Color(red: 0.204, green: 0.827, blue: 0.6)
    static let caution = Color(red: 0.984, green: 0.749, blue: 0.141)
    static let suspicious = Color(red: 0.984, green: 0.573, blue: 0.235)
    static let danger = Color(red: 0.973, green: 0.443, blue: 0.443)

    static let gradient = LinearGradient(
        colors: [cyanLight, cyan, teal, safe],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Verdict {
    var color: Color {
        switch self {
        case .safe: Theme.safe
        case .caution: Theme.caution
        case .suspicious: Theme.suspicious
        case .danger: Theme.danger
        }
    }

    var symbol: String {
        switch self {
        case .safe: "checkmark.shield.fill"
        case .caution: "exclamationmark.shield.fill"
        case .suspicious: "exclamationmark.triangle.fill"
        case .danger: "xmark.octagon.fill"
        }
    }
}

extension Family {
    var symbol: String {
        switch self {
        case .sender: "person.crop.circle.badge.questionmark"
        case .link: "link"
        case .file: "doc.badge.ellipsis"
        case .behavior: "brain.head.profile"
        case .identity: "theatermasks"
        case .technical: "server.rack"
        case .model: "cpu"
        }
    }
}

/// The SF Symbol of an icon name of the website's content.
func symbol(_ icon: String) -> String {
    switch icon {
    case "mail": "envelope.fill"
    case "link": "link"
    case "file": "doc.text"
    case "camera": "camera.viewfinder"
    case "qr": "qrcode"
    case "spark": "sparkles"
    case "lifebuoy": "lifepreserver"
    case "cursor": "cursorarrow.click"
    case "download": "arrow.down.circle"
    case "key": "key.fill"
    case "card": "creditcard"
    case "coin": "eurosign.circle"
    case "message": "message"
    case "app": "app.badge"
    case "reply": "arrowshape.turn.up.left"
    case "help": "questionmark.circle"
    case "clock": "clock"
    case "alert": "exclamationmark.triangle"
    case "crown": "crown"
    case "bolt": "bolt.fill"
    case "lock": "lock.fill"
    case "gift": "gift"
    case "eye": "eye"
    case "ban": "nosign"
    case "heart": "heart"
    case "mask": "theatermasks"
    case "maze": "questionmark.diamond"
    case "bank": "building.columns"
    case "parcel": "shippingbox"
    case "gov": "flag"
    case "briefcase": "briefcase"
    case "chart": "chart.line.uptrend.xyaxis"
    default: "shield"
    }
}

/// The night background, with slow blurred lights.
struct AppBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                Theme.background
                Circle()
                    .fill(Theme.cyan.opacity(0.22))
                    .frame(width: 420, height: 420)
                    .blur(radius: 90)
                    .offset(x: -140 + 40 * sin(t / 7), y: -260 + 50 * cos(t / 9))
                Circle()
                    .fill(Theme.teal.opacity(0.18))
                    .frame(width: 380, height: 380)
                    .blur(radius: 90)
                    .offset(x: 160 + 50 * cos(t / 8), y: 120 + 40 * sin(t / 6))
                Circle()
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: 30 * sin(t / 5), y: 420 + 30 * cos(t / 7))
            }
            .ignoresSafeArea()
        }
    }
}
