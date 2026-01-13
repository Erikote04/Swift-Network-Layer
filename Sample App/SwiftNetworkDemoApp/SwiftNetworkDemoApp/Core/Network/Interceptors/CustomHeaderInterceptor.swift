//
//  CustomHeaderInterceptor.swift
//  SwiftNetworkDemo
//
//  Custom interceptor that adds app-specific headers to requests
//

import Foundation
import SwiftNetwork

/// Adds custom headers to all requests
struct CustomHeaderInterceptor: Interceptor {
    
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let originalRequest = chain.request
        
        // Add custom headers
        var headers = originalRequest.headers
        headers["X-App-Version"] = "1.0.0"
        headers["X-Platform"] = "iOS"
        headers["X-Request-ID"] = UUID().uuidString
        
        // Create modified request
        let modifiedRequest = Request(
            method: originalRequest.method,
            url: originalRequest.url,
            headers: headers,
            body: originalRequest.body,
            timeout: originalRequest.timeout,
            cachePolicy: originalRequest.cachePolicy
        )
        
        // Proceed with modified request
        return try await chain.proceed(modifiedRequest)
    }
}
