//
//  RequestResponseInterceptorTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Request and Response Interceptor Tests")
struct RequestResponseInterceptorTests {
    
    // MARK: - Fake Interceptors
    
    struct FakeRequestInterceptor: RequestInterceptor {
        let headerName: String
        let headerValue: String
        
        func interceptRequest(_ request: Request) async throws -> Request {
            var headers = request.headers
            headers[headerName] = headerValue
            
            return Request(
                method: request.method,
                url: request.url,
                headers: headers,
                body: request.body,
                timeout: request.timeout,
                cachePolicy: request.cachePolicy
            )
        }
    }
    
    struct FakeResponseInterceptor: ResponseInterceptor {
        let recorder: Recorder
        
        func interceptResponse(_ response: Response, for request: Request) async throws -> Response {
            await recorder.record("Response: \(response.statusCode)")
            return response
        }
    }
    
    // MARK: - Tests
    
    @Test("Request interceptor modifies outgoing request")
    func testRequestInterceptor() async throws {
        let transport = FakeTransportFactory.success()
        let requestInterceptor = FakeRequestInterceptor(
            headerName: "X-Custom",
            headerValue: "TestValue"
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            requestInterceptors: [requestInterceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let executedRequest = await transport.requests.first?.request
        #expect(executedRequest?.headers["X-Custom"] == "TestValue")
    }
    
    @Test("Response interceptor processes incoming response")
    func testResponseInterceptor() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success(statusCode: 201)
        let responseInterceptor = FakeResponseInterceptor(recorder: recorder)
        
        let client = TestClientFactory.make(
            transport: transport,
            responseInterceptors: [responseInterceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "Response: 201")
    }
    
    @Test("Request and response interceptors work together")
    func testCombinedInterceptors() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success(statusCode: 200)
        
        let requestInterceptor = FakeRequestInterceptor(
            headerName: "X-Request",
            headerValue: "Modified"
        )
        let responseInterceptor = FakeResponseInterceptor(recorder: recorder)
        
        let client = TestClientFactory.make(
            transport: transport,
            requestInterceptors: [requestInterceptor],
            responseInterceptors: [responseInterceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let executedRequest = await transport.requests.first?.request
        #expect(executedRequest?.headers["X-Request"] == "Modified")
        
        let events = await recorder.events
        #expect(events[0] == "Response: 200")
    }
    
    @Test("Multiple request interceptors execute in order")
    func testMultipleRequestInterceptors() async throws {
        let transport = FakeTransportFactory.success()
        
        let first = FakeRequestInterceptor(headerName: "X-First", headerValue: "1")
        let second = FakeRequestInterceptor(headerName: "X-Second", headerValue: "2")
        
        let client = TestClientFactory.make(
            transport: transport,
            requestInterceptors: [first, second]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let executedRequest = await transport.requests.first?.request
        #expect(executedRequest?.headers["X-First"] == "1")
        #expect(executedRequest?.headers["X-Second"] == "2")
    }
    
    @Test("Execution order: prioritized → request → regular → response")
    func testExecutionOrder() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let regularInterceptor = RecordingInterceptor(id: "Regular", recorder: recorder)
        let prioritizedInterceptor = RecordingInterceptor(id: "Prioritized", recorder: recorder)
        
        struct RequestRecorder: RequestInterceptor {
            let recorder: Recorder
            func interceptRequest(_ request: Request) async throws -> Request {
                await recorder.record("Request")
                return request
            }
        }
        
        struct ResponseRecorder: ResponseInterceptor {
            let recorder: Recorder
            func interceptResponse(_ response: Response, for request: Request) async throws -> Response {
                await recorder.record("Response")
                return response
            }
        }
        
        let requestInterceptor = RequestRecorder(recorder: recorder)
        let responseInterceptor = ResponseRecorder(recorder: recorder)
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [regularInterceptor],
            prioritizedInterceptors: [
                PrioritizedInterceptor(interceptor: prioritizedInterceptor, priority: 10)
            ],
            requestInterceptors: [requestInterceptor],
            responseInterceptors: [responseInterceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let events = await recorder.events
        #expect(events[0] == "Prioritized")
        #expect(events[1] == "Request")
        #expect(events[2] == "Regular")
        #expect(events[3] == "Response")
    }
}
