# Sample App - SwiftNetwork Demo

This sample application demonstrates the capabilities of the **SwiftNetwork** framework through two interactive tabs showcasing real-world use cases.

---

## 📱 App Tabs

### 1️⃣ **Characters**
Tab that consumes the Rick and Morty public API to display a list of characters with:
- ✅ Initial character loading
- 🔍 Real-time search
- 📄 Infinite pagination
- 🔄 State management (loading, error, empty)

### 2️⃣ **Token Demo**
Educational tab that visualizes the framework's token refresh system through:
- 🔐 Token authentication simulation
- 🔄 Automatic and coordinated token refresh
- 🚀 Multiple concurrent requests
- 📊 Real-time event logging
- 📈 Visual request state tracking

---

## 🎯 Complete Flow: Characters API Request

### Step 1: Request Initiation

**File:** `Sample App/Features/Characters/View/CharactersView.swift`

Everything starts when the user opens the **Characters** tab. The `CharactersView` executes its initial task:

```swift
.task {
    if viewModel.characters.isEmpty {
        await viewModel.fetchCharacters()
    }
}
```

### Step 2: ViewModel Prepares the Request

**File:** `Sample App/Features/Characters/ViewModel/CharactersViewModel.swift`

The `CharactersViewModel` initiates the loading process:

```swift
@MainActor
func fetchCharacters() async {
    guard !isLoading else { return }
    
    isLoading = true
    errorMessage = nil
    
    do {
        // Call NetworkManager
        let response = try await networkManager.fetchCharacters(page: 1)
        characters = response.results
        currentPage = 1
        hasMorePages = response.info.next != nil
    } catch let error as NetworkError {
        handleError(error)
    }
    
    isLoading = false
}
```

### Step 3: NetworkManager Builds the Request

**File:** `Sample App/Core/Network/NetworkManager.swift`

The `NetworkManager` creates the request and sends it through the configured client:

```swift
func fetchCharacters(page: Int = 1) async throws -> CharactersResponse {
    let request = Request(
        method: .get,
        url: URL(string: "/character?page=\(page)")!
    )
    
    return try await clientWithInterceptors
        .newCall(request)
        .execute()
}
```

**What happens here?**
- A `Request` is built with GET method and relative URL `/character?page=1`
- Uses `clientWithInterceptors` which has several configured interceptors
- The `execute<T>()` method is generic - it will automatically decode the response to `CharactersResponse`

### Step 4: Interceptor Chain

**File:** `Sample App/Core/Network/NetworkManager.swift`

The request passes through the interceptor chain **in sequential order**:

```swift
interceptors: [
    CustomHeaderInterceptor(),     // 1. Adds custom headers
    LoggingInterceptor(level: .headers),  // 2. Logs the request
    RetryInterceptor(maxRetries: 2),      // 3. Handles retries
    TimeoutInterceptor(timeout: 30.0)     // 4. Controls timeout
]
```

#### 🔸 **CustomHeaderInterceptor**

**File:** `Sample App/Core/Network/Interceptors/CustomHeaderInterceptor.swift`

```swift
func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    var request = chain.request
    
    // Add app-specific headers
    request.headers["X-App-Version"] = "1.0"
    request.headers["X-Platform"] = "iOS"
    
    // Continue to next interceptor
    return try await chain.proceed(request)
}
```

#### 🔸 **LoggingInterceptor**

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/LoggingInterceptor.swift`

Prints request information to console:
```
📤 REQUEST
GET https://rickandmortyapi.com/api/character?page=1
Headers:
  Accept: application/json
  X-App-Version: 1.0
  X-Platform: iOS
```

#### 🔸 **RetryInterceptor**

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/RetryInterceptor.swift`

```swift
func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    var lastError: Error?
    
    for attempt in 0...maxRetries {
        do {
            let response = try await chain.proceed(chain.request)
            
            // If response is successful, return it
            if response.isSuccessful {
                return response
            }
            
            // If it's 5xx, retry
            if response.statusCode >= 500 {
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(delay))
                    continue
                }
            }
            
            return response
            
        } catch {
            lastError = error
            if attempt < maxRetries {
                try await Task.sleep(for: .seconds(delay))
                continue
            }
        }
    }
    
    throw lastError ?? NetworkError.unknown
}
```

#### 🔸 **TimeoutInterceptor**

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/TimeoutInterceptor.swift`

```swift
func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    try await withThrowingTaskGroup(of: Response.self) { group in
        // Main task: execute the request
        group.addTask {
            try await chain.proceed(chain.request)
        }
        
        // Timeout task: wait and cancel
        group.addTask {
            try await Task.sleep(for: .seconds(timeout))
            throw NetworkError.timeout
        }
        
        // Return the first task to complete
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

### Step 5: Transport Executes the Real HTTP Request

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Transport/URLSessionTransport.swift`

After all interceptors, it reaches the `Transport` which performs the actual HTTP request:

```swift
func execute(_ request: Request) async throws -> Response {
    // Build URLRequest
    var urlRequest = URLRequest(url: baseURL.appendingPathComponent(request.url.path))
    urlRequest.httpMethod = request.method.rawValue
    
    // Add headers
    for (key, value) in request.headers {
        urlRequest.setValue(value, forHTTPHeaderField: key)
    }
    
    // Add body if exists
    urlRequest.httpBody = request.body
    
    // Execute with URLSession
    let (data, urlResponse) = try await session.data(for: urlRequest)
    
    guard let httpResponse = urlResponse as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }
    
    // Build Response
    return Response(
        request: request,
        statusCode: httpResponse.statusCode,
        headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
        body: data
    )
}
```

**🌐 The actual HTTP request:**
```
GET https://rickandmortyapi.com/api/character?page=1 HTTP/1.1
Host: rickandmortyapi.com
Accept: application/json
Content-Type: application/json
X-App-Version: 1.0
X-Platform: iOS
```

### Step 6: Response Travels Back

The HTTP response travels back through the **same interceptor chain in reverse order**:

```
API → Transport → TimeoutInterceptor → RetryInterceptor → LoggingInterceptor → CustomHeaderInterceptor → NetworkClient
```

The `LoggingInterceptor` prints the response:
```
📥 RESPONSE
200 OK
Headers:
  Content-Type: application/json
Body: { "info": {...}, "results": [...] }
```

### Step 7: Automatic Decoding

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Call/Call+Decodable.swift`

The `NetworkClient` automatically decodes the response because we use `execute<T>()`:

```swift
public func execute<T: Decodable>() async throws -> T {
    let response = try await execute()
    
    // Validate that response is successful
    guard response.isSuccessful else {
        throw NetworkError.httpError(
            statusCode: response.statusCode,
            body: response.body
        )
    }
    
    // Get the body
    guard let data = response.body else {
        throw NetworkError.noData
    }
    
    // Decode with JSONDecoder
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw NetworkError.decodingError(error)
    }
}
```

**The JSON response:**
```json
{
  "info": {
    "count": 826,
    "pages": 42,
    "next": "https://rickandmortyapi.com/api/character?page=2",
    "prev": null
  },
  "results": [
    {
      "id": 1,
      "name": "Rick Sanchez",
      "status": "Alive",
      "species": "Human",
      "type": "",
      "gender": "Male",
      "image": "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
      ...
    },
    ...
  ]
}
```

It's automatically decoded to:

**File:** `Sample App/Features/Characters/Model/CharactersResponse.swift`

```swift
struct CharactersResponse: Codable {
    let info: PageInfo
    let results: [Character]
}
```

### Step 8: ViewModel Updates the UI

**File:** `Sample App/Features/Characters/ViewModel/CharactersViewModel.swift`

The ViewModel receives the decoded data and updates the state:

```swift
let response = try await networkManager.fetchCharacters(page: 1)

// ✅ We have a typed CharactersResponse
characters = response.results
currentPage = 1
hasMorePages = response.info.next != nil

print("✅ Loaded \(characters.count) characters")
```

### Step 9: SwiftUI Re-renders the View

**File:** `Sample App/Features/Characters/View/CharactersView.swift`

Since `CharactersViewModel` is `@Observable`, SwiftUI automatically detects changes:

```swift
@State private var viewModel = CharactersViewModel()

var body: some View {
    List {
        ForEach(viewModel.characters) { character in
            CharacterRow(character: character)
        }
    }
}
```

**🎨 The UI instantly updates showing:**
- List of characters with their avatars
- Names and details
- Loading indicator disappears

---

## 🔐 Complete Flow: Token Refresh

The token refresh system is **one of the most sophisticated aspects** of the framework. It solves a critical problem: what happens when multiple requests simultaneously detect that the token has expired?

### 🎯 The Problem It Solves

Without coordination:
```
Request 1: 401 → Refresh token → Success
Request 2: 401 → Refresh token → Success  ❌ Wastes resources
Request 3: 401 → Refresh token → Success  ❌ Wastes resources
Request 4: 401 → Refresh token → Success  ❌ Wastes resources
Request 5: 401 → Refresh token → Success  ❌ Wastes resources

Result: 5 calls to auth server (unnecessary)
```

With coordination:
```
Request 1: 401 → Refresh token → Success  ✅ Does the refresh
Request 2: 401 → ⏳ Waits for Request 1
Request 3: 401 → ⏳ Waits for Request 1
Request 4: 401 → ⏳ Waits for Request 1
Request 5: 401 → ⏳ Waits for Request 1

Once refresh completes:
Requests 2-5: Use the new token → Success ✅

Result: Only 1 call to auth server
```

### 📋 Initial Setup

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift`

In the demo, the `TokenDemoViewModel` configures the client with authentication:

```swift
private func setupNetworkClient() {
    // 1. Create the authenticator
    let authenticator = FakeAuthenticator(
        tokenStore: tokenStore,
        authService: authService,
        onAuthEvent: { event in
            Task { @MainActor in
                self.addLog(event)
            }
        },
        onRefreshStart: {
            Task { @MainActor in
                // Visually mark which request is doing the refresh
                // This is only for the demo - not needed in production
            }
        }
    )
    
    // 2. Configure client with interceptors
    let config = NetworkClientConfiguration(
        baseURL: URL(string: "https://rickandmortyapi.com/api")!,
        interceptors: [
            // AuthInterceptor FIRST - adds the token
            AuthInterceptor(
                tokenStore: tokenStore,
                authenticator: authenticator
            ),
            
            // Fake401Interceptor - simulates 401 responses for demo
            Fake401Interceptor()
        ]
    )
    
    networkClient = NetworkClient(configuration: config)
}
```

### Step 1: User Starts the Demo

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift`

The user presses "Run Demo" with 5 concurrent requests:

```swift
@MainActor
func runDemo(requestCount: Int = 5) async {
    // 1. Prepare state
    reset()
    
    // 2. Put an INVALID token intentionally
    await tokenStore.updateToken("invalid_token")
    addLog("❌ Token is currently INVALID")
    
    // 3. Create states to visualize each request
    requests = (1...requestCount).map { RequestState(requestNumber: $0) }
    
    // 4. Launch ALL requests in parallel
    await withTaskGroup(of: Void.self) { group in
        for i in 0..<requestCount {
            group.addTask {
                await self.executeRequest(index: i)
            }
        }
    }
    
    addLog("✅ All requests completed!")
}
```

### Step 2: The 5 Requests Launch Simultaneously

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift`

Each request begins execution:

```swift
@MainActor
private func executeRequest(index: Int) async {
    let requestNumber = requests[index].requestNumber
    
    requests[index].updateStatus(.executing, message: "Request #\(requestNumber) executing...")
    
    // Create the request (without token - let AuthInterceptor add it)
    let request = Request(
        method: .get,
        url: URL(string: "/character/1")!
    )
    
    // Execute
    let response = try await networkClient!.newCall(request).execute()
    
    // ... handle response
}
```

**State at this moment:**
```
Request #1: ▶️ Executing...
Request #2: ▶️ Executing...
Request #3: ▶️ Executing...
Request #4: ▶️ Executing...
Request #5: ▶️ Executing...
```

### Step 3: AuthInterceptor Adds the (Invalid) Token

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/AuthInterceptor.swift`

Each request passes through the `AuthInterceptor`:

```swift
public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    let originalRequest = chain.request
    
    // 1. Get token from store
    guard let usedToken = await tokenStore.currentToken() else {
        return try await chain.proceed(originalRequest)
    }
    
    // 2. Add Authorization header
    var headers = originalRequest.headers
    headers["Authorization"] = "Bearer \(usedToken)"
    
    // 3. Create authenticated request
    let authenticatedRequest = Request(
        method: originalRequest.method,
        url: originalRequest.url,
        headers: headers,  // <-- Now has "Authorization: Bearer invalid_token"
        body: originalRequest.body
    )
    
    // 4. Continue to next interceptor
    let response = try await chain.proceed(authenticatedRequest)
    
    // ... (we haven't processed the response yet)
}
```

**Each request now has:**
```
GET /character/1 HTTP/1.1
Authorization: Bearer invalid_token
```

### Step 4: Fake401Interceptor Detects Invalid Token

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift` (Fake401Interceptor private struct)

This interceptor is demo-specific to simulate a real server:

```swift
func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    let request = chain.request
    
    // Extract token from header
    guard let authHeader = request.headers["Authorization"] else {
        return Response(statusCode: 401, ...)  // No header → 401
    }
    
    let token = authHeader.replacingOccurrences(of: "Bearer ", with: "")
    
    // Verify if valid (must start with "token_")
    if !token.hasPrefix("token_") {
        print("🚫 Invalid token '\(token)', returning 401")
        return Response(
            statusCode: 401,
            headers: ["WWW-Authenticate": "Bearer realm=\"demo\""],
            body: Data("{\"error\": \"Unauthorized\"}".utf8)
        )
    }
    
    // Valid token → continue to real API
    return try await chain.proceed(request)
}
```

**🚨 All requests receive 401:**
```
Request #1: Received → 401 Unauthorized
Request #2: Received → 401 Unauthorized
Request #3: Received → 401 Unauthorized
Request #4: Received → 401 Unauthorized
Request #5: Received → 401 Unauthorized
```

### Step 5: AuthInterceptor Detects the 401s

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/AuthInterceptor.swift`

The 401s travel back through the interceptor chain. The `AuthInterceptor` processes each response:

```swift
public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    // ... (previous code adding token)
    
    let response = try await chain.proceed(authenticatedRequest)
    
    // ⚠️ Detect 401
    guard response.statusCode == 401 else {
        return response  // Not 401, return normally
    }
    
    // 🔍 Check if token changed while we were waiting
    if let currentToken = await tokenStore.currentToken(),
       currentToken != usedToken {
        // ✅ Token was already updated by another request
        // Retry with the new token immediately
        var retryHeaders = originalRequest.headers
        retryHeaders["Authorization"] = "Bearer \(currentToken)"
        
        let retryRequest = Request(
            method: originalRequest.method,
            url: originalRequest.url,
            headers: retryHeaders
        )
        
        return try await chain.proceed(retryRequest)
    }
    
    // 🔄 We need to refresh the token
    // HERE ENTERS THE COORDINATOR MAGIC
    let refreshedToken = try await coordinator.refreshIfNeeded(
        tokenStore: tokenStore
    ) {
        // This closure executes ONLY ONCE for all requests
        if let newRequest = try await authenticator.authenticate(
            request: authenticatedRequest,
            response: response
        ),
        let authHeader = newRequest.headers["Authorization"] {
            return authHeader.replacingOccurrences(of: "Bearer ", with: "")
        }
        
        return nil
    }
    
    // ... (retry with new token)
}
```

### Step 6: 🎯 The AuthRefreshCoordinator Does Its Magic

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Auth/AuthRefreshCoordinator.swift`

Here's the **heart of the system**. When the 5 requests call `refreshIfNeeded()`, the coordinator ensures only one executes the refresh:

```swift
actor AuthRefreshCoordinator {
    private var refreshTask: Task<String?, Error>? = nil
    
    func refreshIfNeeded(
        tokenStore: TokenStore,
        authenticate: @escaping @Sendable () async throws -> String?
    ) async throws -> String? {
        
        // 🔍 Is there already a refresh in progress?
        if let task = refreshTask {
            print("⏳ Another request is already refreshing. Waiting...")
            return try await task.value  // ✅ Wait for the existing one
        }
        
        // 🚀 No refresh in progress - THIS request will initiate it
        print("🔑 Starting token refresh...")
        
        let task = Task<String?, Error> {
            defer { refreshTask = nil }  // Clean up when done
            
            // Execute authentication closure
            guard let token = try await authenticate() else {
                return nil
            }
            
            // Update token store
            await tokenStore.updateToken(token)
            return token
        }
        
        // Save the task for others to use
        refreshTask = task
        return try await task.value
    }
}
```

**🎬 What happens:**

**Request #1** (first to arrive):
```swift
coordinator.refreshIfNeeded(...) {
    // refreshTask is nil
    // → Creates a new Task
    // → refreshTask = task
    // → Executes authenticate()
}
```

**Requests #2, #3, #4, #5** (arrive while #1 is executing):
```swift
coordinator.refreshIfNeeded(...) {
    // refreshTask already exists
    // → return try await task.value
    // → ⏳ They wait for #1's result
}
```

### Step 7: The Authenticator Refreshes the Token

**File:** `Sample App/Features/Tokens/Services/FakeAuthenticator.swift`

Only Request #1 executes this function:

```swift
func authenticate(request: Request, response: Response) async throws -> Request? {
    guard response.statusCode == 401 else {
        return nil
    }
    
    onAuthEvent("🔒 401 detected - attempting token refresh...")
    onRefreshStart()  // UI: Mark request #1 as "refreshing"
    
    // ⏰ Simulate auth server call (2 seconds)
    let newToken = try await authService.refreshToken()
    
    // 💾 Store the new token
    await tokenStore.updateToken(newToken)
    
    onAuthEvent("✅ Token refreshed successfully")
    
    // 📝 Create new request with fresh token
    var headers = request.headers
    headers["Authorization"] = "Bearer \(newToken)"
    
    return Request(
        method: request.method,
        url: request.url,
        headers: headers,
        body: request.body
    )
}
```

**File:** `Sample App/Features/Tokens/Services/FakeAuthService.swift`

**The FakeAuthService executes:**
```swift
func refreshToken() async throws -> String {
    print("🔄 Starting token refresh...")
    
    // Simulate network latency
    try await Task.sleep(for: .seconds(2))
    
    refreshCount += 1
    let newToken = "token_\(refreshCount)_\(UUID().uuidString.prefix(8))"
    
    print("✅ Token refreshed: \(newToken)")
    
    return newToken
}
```

**Real timeline:**
```
t=0.00s: Request #1 calls authenticate()
t=0.00s: Requests #2,#3,#4,#5 wait in coordinator
t=0.00s: [LOG] 🔄 Starting token refresh...
t=2.00s: Refresh completes
t=2.00s: [LOG] ✅ Token refreshed: token_1_a1b2c3d4
t=2.00s: tokenStore.updateToken("token_1_a1b2c3d4")
t=2.00s: coordinator.refreshTask completes
t=2.01s: Requests #2,#3,#4,#5 unblock with the new token
```

### Step 8: All Requests Get the New Token

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/AuthInterceptor.swift`

When the coordinator completes, **all requests receive the same token**:

```swift
// In AuthInterceptor, after coordinator.refreshIfNeeded()

guard let token = refreshedToken else {
    return response  // Refresh failed
}

// 🎯 Retry the original request with the new token
var retryHeaders = originalRequest.headers
retryHeaders["Authorization"] = "Bearer \(token)"

let retryRequest = Request(
    method: originalRequest.method,
    url: originalRequest.url,
    headers: retryHeaders
)

// 🚀 Execute again
return try await chain.proceed(retryRequest)
```

**All 5 requests retry simultaneously:**
```
Request #1: GET /character/1 (Authorization: Bearer token_1_a1b2c3d4)
Request #2: GET /character/1 (Authorization: Bearer token_1_a1b2c3d4)
Request #3: GET /character/1 (Authorization: Bearer token_1_a1b2c3d4)
Request #4: GET /character/1 (Authorization: Bearer token_1_a1b2c3d4)
Request #5: GET /character/1 (Authorization: Bearer token_1_a1b2c3d4)
```

### Step 9: Fake401Interceptor Validates the New Token

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift` (Fake401Interceptor)

```swift
func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
    let token = /* extract from header */
    
    // Verify it starts with "token_"
    if !token.hasPrefix("token_") {
        return Response(statusCode: 401, ...)
    }
    
    // ✅ Valid token, continue to API
    print("✅ Valid token, proceeding to API")
    return try await chain.proceed(request)
}
```

### Step 10: Real API Responds

The requests reach the Rick and Morty API:

```
GET https://rickandmortyapi.com/api/character/1
Authorization: Bearer token_1_a1b2c3d4
```

The API responds with 200 OK:
```json
{
  "id": 1,
  "name": "Rick Sanchez",
  "status": "Alive",
  ...
}
```

### Step 11: UI Updates

**File:** `Sample App/Features/Tokens/ViewModel/TokenDemoViewModel.swift`

The `TokenDemoViewModel` updates each request's state:

```swift
// In executeRequest()
let response = try await networkClient!.newCall(request).execute()

if response.statusCode == 200 {
    requests[index].updateStatus(
        .success,
        message: "Request #\(requestNumber) succeeded! ✓"
    )
}
```

**The UI displays:**
```
✅ Request #1 succeeded! ✓
✅ Request #2 succeeded! ✓
✅ Request #3 succeeded! ✓
✅ Request #4 succeeded! ✓
✅ Request #5 succeeded! ✓

📊 Total token refreshes: 1
```

---

## 📊 Token Refresh Sequence Diagram

```
Request 1                    Request 2-5                    Coordinator                    Auth Service
   |                            |                               |                                |
   |---- GET /character/1 ----->|                               |                                |
   |<--- 401 Unauthorized ------                                |                                |
   |                            |                               |                                |
   |--- refreshIfNeeded() ----->|                               |                                |
   |                            |--- refreshIfNeeded() -------->|                                |
   |                            |                               |<--- No task exists             |
   |                            |                               |--- Create Task                 |
   |                            |                               |--- authenticate() ------------>|
   |                            |     ⏳ WAITING ⏳             |                                |
   |                            |                               |                                |--- Refresh Token
   |                            |                               |                                |    (2 seconds)
   |                            |                               |                                |
   |                            |                               |<--- "token_1_a1b2c3d4" --------
   |<--- "token_1_a1b2c3d4" ----|                               |                                |
   |                            |<--- "token_1_a1b2c3d4" -------|                                |
   |                            |                               |--- Clear Task                  |
   |                            |                               |                                |
   |---- Retry with new token -->                               |                                |
   |                            |---- Retry with new token ---->                                 |
   |<--- 200 OK ----------------                                                                 |
   |                            |<--- 200 OK -------------------                                 |
```

---

## 🎓 Key Token Refresh Concepts

### 1. **Actor for Synchronization**

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Auth/AuthRefreshCoordinator.swift`

```swift
actor AuthRefreshCoordinator {
    private var refreshTask: Task<String?, Error>? = nil
    // ...
}
```
- The `actor` guarantees only one thread accesses `refreshTask` at a time
- This prevents race conditions when multiple requests try to refresh simultaneously

### 2. **Task Reuse**

```swift
if let task = refreshTask {
    return try await task.value  // Reuse existing task
}
```
- If a refresh is already in progress, we simply wait for its result
- This avoids multiple calls to the authentication server

### 3. **Optimistic Verification**

```swift
if let currentToken = await tokenStore.currentToken(),
   currentToken != usedToken {
    // Token already updated, use it directly
    return try await chain.proceed(retryRequest)
}
```
- Before starting a refresh, we check if another request already did it
- This is an optimization to reduce latency

### 4. **Automatic Cleanup**

```swift
let task = Task<String?, Error> {
    defer { refreshTask = nil }  // Clean up when done
    // ...
}
```
- The `defer` ensures we clean up `refreshTask` even if errors occur
- This allows future refreshes to work correctly

---

## 💡 System Advantages

### ✅ **Efficiency**
- **Only 1 call** to auth server, regardless of how many requests fail
- Reduces load on authentication server
- Saves bandwidth

### ✅ **Transparency**
- Individual requests don't need to know about the coordinator
- The `AuthInterceptor` handles everything automatically
- Business code stays clean

### ✅ **Thread-Safe**
- The `actor` prevents race conditions
- Guarantees consistency even with high concurrency

### ✅ **Resilient**
- Handles refresh failures correctly
- Automatic cleanup prevents inconsistent states

---

## 🔧 Technical Components

### TokenStore

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Auth/TokenStore.swift`

Interface for persisting and retrieving tokens:
```swift
public protocol TokenStore: Actor {
    func currentToken() async -> String?
    func updateToken(_ token: String) async
}
```

### Authenticator

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Auth/Authenticator.swift`

Defines how to refresh a token:
```swift
public protocol Authenticator: Sendable {
    func authenticate(
        request: Request,
        response: Response
    ) async throws -> Request?
}
```

### AuthInterceptor

**File (SwiftNetwork Library):** `SwiftNetwork/Sources/SwiftNetwork/Interceptors/AuthInterceptor.swift`

Adds tokens and coordinates refreshes:
```swift
public struct AuthInterceptor: Interceptor {
    let tokenStore: TokenStore
    let authenticator: Authenticator
    private let coordinator: AuthRefreshCoordinator
    
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response
}
```

---

## 🎯 Production Use Cases

### Case 1: App with Multiple Screens
```
Dashboard Screen → 5 widgets → 5 API calls
If token expires while loading:
✅ Only 1 refresh
✅ 5 widgets load correctly
❌ No 5 redundant calls to auth server
```

### Case 2: Background Sync
```
App in background → Sync 100 items
Token expires during sync:
✅ Only 1 refresh
✅ 100 items continue syncing
❌ No wasted resources
```

### Case 3: Optimistic UI Updates
```
User performs 3 quick actions:
1. Like post
2. Comment
3. Share
Token expires:
✅ Only 1 refresh
✅ All 3 actions complete
✅ UI updates correctly
```

---

## 📝 Summary

This Sample App demonstrates:

1. **REST API consumption** with professional state management
2. **Robust authentication system** with coordinated token refresh
3. **MVVM architecture** with Observation framework
4. **Interceptors** for cross-cutting concerns
5. **Structured concurrency** with Swift Concurrency
6. **Typed error handling** with descriptive messages

The **SwiftNetwork** framework provides all these capabilities in an elegant and easy-to-use manner, allowing developers to focus on business logic instead of networking infrastructure.