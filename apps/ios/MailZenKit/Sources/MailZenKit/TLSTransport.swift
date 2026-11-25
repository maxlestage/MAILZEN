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
#endif
