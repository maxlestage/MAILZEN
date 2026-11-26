#if canImport(Network)
import Foundation
import Network

/// Runs a closure once, whichever callback comes first.
final class Once: @unchecked Sendable {
    private var done = false
    private let lock = NSLock()

    func run(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !done else { return }
        done = true
        body()
    }
}

/// An encrypted connection (TLS) to an IMAP server, with Network.framework.
public final class TLSTransport: IMAPTransport, @unchecked Sendable {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "app.mailzen.imap")

    public init(host: String, port: UInt16 = 993) {
        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port) ?? .imaps,
            using: .tls
        )
    }

    /// Opens the connection, or fails after `timeout` seconds.
    public func start(timeout: TimeInterval = 15) async throws {
        let once = Once()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    once.run { continuation.resume() }
                case .failed(let error), .waiting(let error):
                    once.run { continuation.resume(throwing: error) }
                case .cancelled:
                    once.run { continuation.resume(throwing: IMAPError.closed) }
                default:
                    break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                once.run { continuation.resume(throwing: IMAPError.timeout) }
            }
        }
    }

    public func send(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    public func receive() async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, !data.isEmpty {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: Data())
                }
                _ = isComplete
            }
        }
    }

    public func close() async {
        connection.cancel()
    }
}

extension MailboxWatcher {
    /// Connects to `host` over TLS and checks the inbox.
    public static func check(
        host: String, port: UInt16 = 993, user: String, password: String,
        lastUID: UInt32?, uidValidity: UInt32?
    ) async throws -> MailboxCheck {
        let transport = TLSTransport(host: host, port: port)
        try await transport.start()
        return try await check(
            transport: transport, user: user, password: password,
            lastUID: lastUID, uidValidity: uidValidity
        )
    }
}
extension MailBrowser {
    static func open(_ host: String, _ port: UInt16) async throws -> TLSTransport {
        let transport = TLSTransport(host: host, port: port)
        try await transport.start()
        return transport
    }

    public static func folders(host: String, port: UInt16 = 993, user: String, password: String) async throws -> [IMAPFolder] {
        try await folders(transport: open(host, port), user: user, password: password)
    }

    public static func page(host: String, port: UInt16 = 993, user: String, password: String, folder: String,
                            knownUIDs: [UInt32]? = nil, uidValidity: UInt32? = nil,
                            before: UInt32? = nil, size: Int = 30) async throws -> MailPage {
        try await page(transport: open(host, port), user: user, password: password, folder: folder,
                       knownUIDs: knownUIDs, uidValidity: uidValidity, before: before, size: size)
    }

    public static func newer(host: String, port: UInt16 = 993, user: String, password: String, folder: String,
                             after: UInt32, limit: Int = 50) async throws -> (uidValidity: UInt32, items: [MailSummary]) {
        try await newer(transport: open(host, port), user: user, password: password, folder: folder, after: after, limit: limit)
    }

    public static func message(host: String, port: UInt16 = 993, user: String, password: String, folder: String, uid: UInt32) async throws -> EmailMessage? {
        try await message(transport: open(host, port), user: user, password: password, folder: folder, uid: uid)
    }
}
#endif
