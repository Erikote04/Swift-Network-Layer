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
    var isRefreshingToken: Bool  // NEW: Indicates if this request is the one refreshing
    
    enum Status {
        case waiting
        case executing
        case refreshingToken  // This request is refreshing the token
        case waitingForToken  // This request is waiting for another to refresh
        case success
        case failed
    }
    
    init(requestNumber: Int) {
        self.id = UUID()
        self.requestNumber = requestNumber
        self.status = .waiting
        self.message = "Request #\(requestNumber) waiting..."
        self.timestamp = Date()
        self.isRefreshingToken = false
    }
    
    mutating func updateStatus(_ status: Status, message: String, isRefreshingToken: Bool = false) {
        self.status = status
        self.message = message
        self.timestamp = Date()
        self.isRefreshingToken = isRefreshingToken
    }
}
