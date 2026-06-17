//
//  NetworkService.swift
//  SandboxPilotKit
//
//  Owns the single loopback TCP connection from a controlled app to the
//  SandboxPilot companion app (the server).
//  - Sends `PilotClientMessage` to the server (JSON, separated by 0x0A).
//  - Receives `PilotServerMessage` and emits them on an `AsyncStream` so the
//    core can handle them without dropping any.
//

import Foundation
import Network

final actor NetworkService {
    // Incoming messages
    private let msgPair = AsyncStream.makeStream(of: PilotServerMessage.self)
    var messages: AsyncStream<PilotServerMessage> { msgPair.stream }

    // Networking
    private var conn: NWConnection?
    private var isReady = false
    private var buffer = Data()
    private var pendingSends: [Data] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: Lifecycle

    func connect(host: String = "127.0.0.1", port: UInt16 = 8085) {
        guard conn == nil else { return }

        let parameters = NWParameters.tcp
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: parameters
        )
        conn = connection

        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { await self.handleState(state) }
        }

        let q = DispatchQueue(label: "sandboxpilot.network")
        connection.start(queue: q)
    }

    func close() {
        conn?.cancel()
        conn = nil
        isReady = false
        buffer.removeAll(keepingCapacity: false)
        pendingSends.removeAll(keepingCapacity: false)
    }

    // MARK: Outgoing

    /// Sends a message from the controlled app to the companion (server).
    /// If the connection is not ready yet (or the companion was restarted) the
    /// message is buffered and flushed once the connection recovers.
    func send(_ message: PilotClientMessage) async {
        do {
            var data = try encoder.encode(message)
            data.append(0x0A)

            if isReady, let conn {
                conn.send(content: data, completion: .contentProcessed { _ in })
            } else {
                pendingSends.append(data)
            }
        } catch {
            // Encoding failures are silently dropped; there is no log channel here.
        }
    }

    // MARK: Internals

    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isReady = true
            flushPending()
            scheduleNextReceive()

        case .failed, .cancelled:
            close()

        case .waiting:
            // The system recovers the connection automatically.
            break

        default:
            break
        }
    }

    private func flushPending() {
        guard !pendingSends.isEmpty, isReady, let conn else { return }
        for data in pendingSends {
            conn.send(content: data, completion: .contentProcessed { _ in })
        }
        pendingSends.removeAll()
    }

    private func scheduleNextReceive() {
        guard let conn else { return }
        conn.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isEOF, error in
            guard let self else { return }
            Task { await self.handleReceive(data: data, isEOF: isEOF, error: error) }
        }
    }

    private func handleReceive(data: Data?, isEOF: Bool, error: Error?) {
        if let data { buffer.append(data) }
        drainBuffer()
        if isEOF || error != nil {
            close()
        } else {
            scheduleNextReceive()
        }
    }

    private func drainBuffer() {
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer[..<nl]
            buffer.removeSubrange(...nl)
            if line.isEmpty { continue }
            if let msg = try? decoder.decode(PilotServerMessage.self, from: line) {
                msgPair.continuation.yield(msg)
            }
        }
    }
}
