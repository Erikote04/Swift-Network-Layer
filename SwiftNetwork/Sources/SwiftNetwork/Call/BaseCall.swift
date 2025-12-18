//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

open class BaseCall: Call, @unchecked Sendable {

    public let request: Request

    private let stateLock = NSLock()
    private var state: CallState = .idle

    public init(request: Request) {
        self.request = request
    }

    public final func execute() async throws -> Response {
        try beginExecution()
        
        defer { finishExecution() }

        if isCancelled {
            throw NetworkError.cancelled
        }

        return try await performExecute()
    }

    public func cancel() {
        stateLock.lock()
        state = .cancelled
        stateLock.unlock()
    }

    public var isCancelled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state == .cancelled
    }

    // MARK: - Overridable

    open func performExecute() async throws -> Response {
        fatalError("Subclasses must override performExecute()")
    }

    // MARK: - State

    private func beginExecution() throws {
        stateLock.lock()
        
        defer { stateLock.unlock() }

        guard state == .idle else {
            fatalError("Call can only be executed once")
        }

        state = .running
    }

    private func finishExecution() {
        stateLock.lock()
        
        if state != .cancelled {
            state = .completed
        }
        
        stateLock.unlock()
    }
}
