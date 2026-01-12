//
//  TokenDemoState.swift
//  SwiftNetworkDemo
//
//  State model for tracking individual request states in token demo
//

import Foundation

/// Represents the state of a single API request
struct RequestState: Identifiable {
    let id: UUID
    let requestNumber: Int
    var status: Status
    var message: String
    var timestamp: Date
    
    enum Status {
        case waiting
        case executing
        case refreshingToken
        case success
        case failed
    }
    
    init(requestNumber: Int) {
        self.id = UUID()
        self.requestNumber = requestNumber
        self.status = .waiting
        self.message = "Request #\(requestNumber) waiting..."
        self.timestamp = Date()
    }
    
    mutating func updateStatus(_ status: Status, message: String) {
        self.status = status
        self.message = message
        self.timestamp = Date()
    }
}
