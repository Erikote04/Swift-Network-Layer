# SwiftNetwork Sample App

This demo app showcases practical usage of the SwiftNetwork library. Each screen maps to a library feature and includes a minimal, realistic workflow so you can copy/paste patterns into your own project.

## Running The App

1. Open `Sample App/SwiftNetworkSampleApp/SwiftNetworkSampleApp.xcodeproj` in Xcode.
2. Select a simulator or device.
3. Build and run.

## Feature Guide (Alphabetical)

### Apple Sign-In

Goal: Demonstrate Sign in with Apple and show the stored token value.

Steps:
1. Ensure the app target has **Sign in with Apple** capability enabled.
2. Open **Apple Sign-In**.
3. Tap **Sign in with Apple** and complete the system flow.

What to look for:
- The status label updates after sign-in.
- The **Keychain** label shows the stored token contents.
- The **Re-authenticate** button appears when a token is already cached.

Notes:
- The Apple identity token is short-lived. In production, you typically exchange it with your backend and store your own session token.

### Auth

Goal: Show token storage with `KeychainTokenStore` and request signing using `AuthInterceptor`.

Steps:
1. Create a GitHub Personal Access Token.
2. Open **Auth**.
3. Paste your token and tap **Save**.
4. Tap **Fetch Profile** to call `GET /user` with the `Authorization` header.

What to look for:
- Token persists in Keychain.
- Requests include the bearer token.

### Caching

Goal: In-memory, disk, and hybrid cache policies.

Steps:
1. Open **Caching**.
2. Execute the requests and observe cache hits.

What to look for:
- Cache metrics and response behavior.

### Interceptors

Goal: Conditional + prioritized interceptors.

Steps:
1. Open **Interceptors**.
2. Execute the requests to see header injection and conditional logic.

### Metrics

Goal: Aggregated request metrics.

Steps:
1. Open **Metrics**.
2. Execute requests and observe aggregate metrics.

### Multipart

Goal: Multipart upload with progress reporting.

Steps:
1. Open **Multipart**.
2. Start the upload and observe the progress bar.

### Performance

Goal: Deduplication + priority demonstrations.

Steps:
1. Open **Performance**.
2. Run deduped requests and inspect the output.

### Progress

Goal: Upload/download progress callbacks.

Steps:
1. Open **Progress**.
2. Start the request and observe progress updates.

### Repository List

Goal: Basic GET + decoding.

Steps:
1. Open **Repository List**.
2. It fetches GitHub repositories and displays them in a list.

What to look for:
- JSON decoding into Swift models.
- Error handling and loading states.

### Request Bodies

Goal: JSON, form-encoded, and raw data bodies.

Steps:
1. Open **Request Bodies**.
2. Switch between body types and submit to `httpbin`.

### Request Builder

Goal: Demonstrate `RequestBuilder` usage for URL composition.

Steps:
1. Open **Request Builder**.
2. Inspect how headers, query params, and timeout are configured.

What to look for:
- Proper URL and header construction.
- Output status + response body.

### Req/Res Interceptors

Goal: Separate request and response interception.

Steps:
1. Open **Req/Res Interceptors**.
2. Run a request and observe response filtering + header capture.

### Retry

Goal: Automatic retry handling + metrics.

Steps:
1. Open **Retry**.
2. Trigger a request designed to fail and watch retry behavior.

### Streaming

Goal: Stream response data incrementally.

Steps:
1. Open **Streaming**.
2. Watch incremental events update in the UI.

### WebSockets

Goal: Connect, send, and receive WebSocket messages.

Steps:
1. Open **WebSockets**.
2. Connect and send a message. Observe received responses.

## Troubleshooting

- If a feature uses an external API, ensure your network allows outbound HTTPS.
- Some flows (Sign in with Apple) work best on a real device.
- If you edit Info.plist or entitlements, do a clean build.

## Notes

This app is intentionally small and readable. The patterns demonstrated here should translate directly to production usage with proper error handling, logging, and security hardening.
