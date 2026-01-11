# Codex Runbook: NewsCatcher API Test App

## Purpose
This repository contains a Flutter proof-of-concept app that exercises the NewsCatcher API (news + local news) using a simple UI shell and multiple screens for different endpoints. The app supports two modes:

- **Proxy mode (recommended):** Requests go through a Cloudflare Worker proxy so API tokens are not bundled in the client.
- **Direct mode:** Requests go straight to NewsCatcher endpoints and include API tokens in headers.

The runtime entry point is `lib/main.dart` and state is coordinated by `AppState` and the screen widgets in `lib/ui/`.

## Quick Start

### Prerequisites
- Flutter SDK installed (stable channel preferred).
- Xcode (for iOS) or Android Studio / Android SDK (for Android).
- A NewsCatcher API account and tokens if you plan to run in direct mode.
- (Optional) A Cloudflare Worker configured as a proxy if you use proxy mode.

### Install dependencies
```bash
flutter pub get
```

### Run the app
```bash
flutter run
```

If you want to launch a specific device/emulator:
```bash
flutter devices
flutter run -d <device_id>
```

## Configuration
All runtime configuration lives in `lib/config.dart`:

- `useProxy`: When `true`, requests go to the `proxyBaseUrl` and do **not** include API tokens.
- `proxyBaseUrl`: Base URL for your Cloudflare Worker proxy.
- `newsBaseUrl` / `localBaseUrl`: Direct API endpoints for NewsCatcher.
- `newsApiToken` / `localApiToken`: Direct API tokens (client-side).
- `proxyNewsPrefix` / `proxyLocalPrefix`: Paths prepended when using the proxy.

**Recommended:** Use proxy mode for production to avoid shipping API tokens in a client app.

### Proxy mode
Set:
```dart
static const bool useProxy = true;
static const String proxyBaseUrl = "https://<your-worker-domain>";
```
Ensure the worker is routing `/news/*` and `/local/*` to the corresponding NewsCatcher API endpoints.

### Direct mode
Set:
```dart
static const bool useProxy = false;
```
and provide valid values for `newsApiToken` and `localApiToken`.

## Project Layout
```
lib/
  main.dart                App entry + Provider setup
  app_state.dart           Location and app-level state
  config.dart              API configuration (proxy/direct)
  services/
    api_client.dart        HTTP client wrapper + JSON parsing
    news_service.dart      News API endpoints (v3)
    local_news_service.dart Local news endpoints
  ui/
    app_shell.dart         Navigation shell
    screens/               Individual endpoint screens
    widgets/               Reusable UI pieces
```

## Execution Flow
1. `main.dart` creates `AppState` and kicks off `initLocation()`.
2. `AppShell` hosts a set of screens that call service methods.
3. Each screen constructs a request body, calls `NewsService` or `LocalNewsService`, and renders response JSON.
4. `ApiClient` builds the request URL (proxy or direct), sets headers, performs HTTP request, and parses JSON.

## API Usage Summary
- **News API** endpoints are in `lib/services/news_service.dart`.
- **Local news** endpoints are in `lib/services/local_news_service.dart`.
- Endpoint methods call `_client.post()` for most operations, `_client.get()` for subscription.

## Code Review Notes (Known Issues / Risks)
These are areas to keep in mind when working with this codebase:

1. **Proxy URL missing scheme**
   - `proxyBaseUrl` is currently missing `https://`. `Uri.parse` will treat the base as a relative URL and can break requests.
   - Fix: ensure `proxyBaseUrl` includes scheme, e.g. `https://example.workers.dev`.

2. **Hard-coded API tokens in source**
   - `newsApiToken` and `localApiToken` are checked into `lib/config.dart`.
   - This is unsafe for production and can cause token leakage. Use environment or CI secrets and a proxy.

3. **No HTTP client disposal**
   - `ApiClient` creates an `http.Client` but never closes it.
   - In long-lived apps, this can lead to socket exhaustion. Consider wiring a dispose method.

4. **Location permissions may be denied**
   - `AppState.initLocation()` requests location and sets a status string, but the UI should handle denied states gracefully.
   - The UI should avoid calling local endpoints when `locationPermissionGranted == false`.

5. **Error handling in UI is minimal**
   - The UI mostly shows raw JSON responses. HTTP errors are not surfaced in a structured way.
   - Consider surfacing `statusCode`, or a standardized error view.

6. **Proxy path and API path coupling**
   - `_buildUri()` concatenates `proxyBaseUrl + prefix + path`. If any part misses slashes, endpoints can break.
   - Ensure `proxyBaseUrl` does not end with a slash, and prefixes include a leading slash.

## Local Development Tips

### Run with location support
On iOS simulators, you can set a simulated location via **Features > Location**. On Android emulators, use the **Location** panel.

### Verify API connectivity
- Temporarily add logging to `ApiClient.get`/`post` to inspect full URLs and responses.
- Use a REST client (curl/Postman) to validate that the proxy is routing correctly.

### Debugging HTTP errors
- Inspect `ApiResponse.status` in the UI to correlate with response bodies.
- Common issues:
  - 401/403 → missing/invalid token or proxy not forwarding headers.
  - 404 → incorrect API path or proxy routing mismatch.
  - 429 → rate limit reached.

## Runbook: Common Tasks

### Update API tokens
1. Open `lib/config.dart`.
2. Replace `newsApiToken` and `localApiToken` with new values.
3. Ensure `useProxy` is `false` if you want the client to send tokens directly.

### Switch to proxy mode
1. Set `useProxy` to `true` in `lib/config.dart`.
2. Set `proxyBaseUrl` to your Cloudflare Worker URL (include `https://`).
3. Ensure your worker forwards requests to the correct NewsCatcher endpoints.

### Add a new News API endpoint
1. Add a new method in `lib/services/news_service.dart` that calls `_client.post()` or `_client.get()`.
2. Create a new screen in `lib/ui/screens/` with a form and response viewer.
3. Add the screen to `AppShell` navigation.

### Add a new Local News endpoint
1. Add a method in `lib/services/local_news_service.dart`.
2. Create a screen in `lib/ui/screens/`.
3. Wire the screen into `AppShell`.

## Troubleshooting

### App shows “Location services disabled”
- Enable location services on the emulator/device.
- Reopen the app so `initLocation()` is called again.

### App shows empty or null JSON
- The API may be returning a non-JSON response. Check `ApiResponse.rawBody`.
- Validate the endpoint path and parameters.

### Proxy returns 404
- Verify your Cloudflare Worker routes `/news/*` and `/local/*` to the expected NewsCatcher API endpoints.
- Ensure the proxy strips/retains the path correctly.

## Maintenance Checklist
- [ ] Rotate tokens and remove any hard-coded secrets.
- [ ] Add environment-based configuration (build-time or runtime).
- [ ] Implement HTTP client disposal.
- [ ] Add structured error handling UI.
- [ ] Add basic smoke tests (e.g., one endpoint per API group).

## Reference Files
- `lib/main.dart`: App entry and Provider setup.
- `lib/app_state.dart`: Location and app-level state.
- `lib/config.dart`: Configuration (proxy/direct tokens).
- `lib/services/`: API client and service wrappers.
- `lib/ui/`: UI screens and widgets.
