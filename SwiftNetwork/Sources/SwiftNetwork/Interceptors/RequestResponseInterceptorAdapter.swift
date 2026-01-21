//
//  RequestResponseInterceptorAdapter.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation

/// Adapts request-only and response-only interceptors to the full `Interceptor` protocol.
///
/// This adapter enables the use of specialized interceptors in the standard
/// interceptor chain without requiring them to implement the full protocol.
struct RequestResponseInterceptorAdapter: Interceptor {
    
    private let requestInterceptor: RequestInterceptor?
    private let responseInterceptor: ResponseInterceptor?
    
    /// Creates an adapter for a request interceptor.
    ///
    /// - Parameter requestInterceptor: The request interceptor to wrap.
    init(requestInterceptor: RequestInterceptor) {
        self.requestInterceptor = requestInterceptor
        self.responseInterceptor = nil
    }
    
    /// Creates an adapter for a response interceptor.
    ///
    /// - Parameter responseInterceptor: The response interceptor to wrap.
    init(responseInterceptor: ResponseInterceptor) {
        self.requestInterceptor = nil
        self.responseInterceptor = responseInterceptor
    }
    
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var request = chain.request
        
        if let requestInterceptor = requestInterceptor {
            request = try await requestInterceptor.interceptRequest(request)
        }
        
        var response = try await chain.proceed(request)
        
        if let responseInterceptor = responseInterceptor {
            response = try await responseInterceptor.interceptResponse(response, for: request)
        }
        
        return response
    }
}
