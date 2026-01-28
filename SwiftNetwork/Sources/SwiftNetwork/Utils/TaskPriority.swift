//
//  TaskPriority.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Foundation

/// Executes a task with a specific priority.
///
/// - Parameters:
///   - priority: The task priority to use.
///   - operation: The operation to execute.
/// - Returns: The result of the operation.
/// - Throws: Any error thrown by the operation.
func withTaskPriority<T: Sendable>(
    _ priority: TaskPriority,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await Task(priority: priority) {
        try await operation()
    }.value
}
