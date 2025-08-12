# UAE PASS Integration (Custom OAuth 2.0 + PKCE)

This document explains the custom UAE PASS integration in the ADCDA Inspector app. It replaces any external package with a fully in-house OAuth 2.0 Authorization Code flow that uses PKCE, state verification, app detection with browser fallback, secure storage, and platform deep-linking.


## Overview

- OAuth 2.0 Authorization Code + PKCE
- Random CSRF `state` per login, verified on callback
- UAE PASS app detection and fallback to browser
- Token exchange and userinfo retrieval via UAE PASS endpoints
- Secure storage of tokens and user profile
- Native deep-linking on Android/iOS using `adcdainspector://uaepass/callback`
- Environment-aware configuration (staging vs production)


## Key Files

- `lib/services/uae_pass_service.dart`
  - App-facing service that orchestrates login, token exchange, backend auth, and storage.
- `lib/uaepass/uae_pass_api.dart`
  - Core OAuth client: builds authorize URL (with PKCE & state), exchanges code for access token, fetches user profile, and handles logout.
- `lib/uaepass/uaepass_view.dart`
  - In-app WebView for the authorization UI and custom-scheme handoff. Verifies `state` on the callback before accepting `code`.
- `lib/uaepass/memory_service.dart`
  - Ephemeral storage for `state`, `codeVerifier`, and the resulting authorization `code`.
- `lib/uaepass/uaepass_user_profile_model.dart`
  - Dart model for the UAE PASS user profile response.
- `lib/uaepass/constant.dart`
  - ACR values, base URLs, and scheme helpers for staging/production.
- `lib/utils/api_config.dart`
  - App configuration for API endpoints and UAE PASS client details.


## Dependencies

Added/Used:
- `http`
- `dio`
- `url_launcher`
- `webview_flutter`
- `flutter_fgbg` (>= 0.6.0)
- `get_storage`
- `crypto` (for PKCE S256)

Install with:
```
flutter pub get
```


## Configuration

All UAE PASS configuration values must be consistent across:
- UAE PASS Console (your registered app)
- Mobile app deep links (AndroidManifest/Info.plist)
- Mobile runtime configuration (`ApiConfig` / env)

Important values:
- Client ID
- Client Secret (if required by your tenant)
- Redirect URI (must be the deep link):
  - `adcdainspector://uaepass/callback`
- Environment base URL:
  - Staging: `https://stg-id.uaepass.ae`
  - Production: `https://id.uaepass.ae`

In code, the base URLs and ACR are sourced from `lib/uaepass/constant.dart` and the environment is driven from `ApiConfig` and/or your build flavors.


## OAuth Flow (with PKCE & State)

1. The app builds an authorize URL (`UaePassAPI._getURL()`):
   - Generates random `state` (CSRF) and `code_verifier` (PKCE)
   - Computes `code_challenge` = `BASE64URL-ENCODE(SHA256(code_verifier))`
   - Persists `state` and `codeVerifier` in `MemoryService`
   - Detects if UAE PASS app is installed (custom scheme); if not, sets web ACR
   - Adds parameters: `response_type=code`, `client_id`, `redirect_uri`, `ui_locales`, `acr_values`, `code_challenge`, `code_challenge_method=S256`, `state`

2. `CustomWebView` (`uaepass_view.dart`) loads the authorize URL. If the web page tries to open `uaepass://...`, it hands off to the app.

3. After login/consent, UAE PASS redirects back to `adcdainspector://uaepass/callback?code=...&state=...`.

4. `CustomWebView` verifies:
   - The URL starts with the configured `callbackUrl`
   - The returned `state` matches the stored `state`
   - If valid, it stores the `code` in `MemoryService` and closes the WebView

5. `UaePassAPI.getAccessToken(code)` exchanges the code for an access token, including `code_verifier`.

6. The app stores tokens securely and can optionally call `userinfo` to enrich the profile.

7. Finally, ephemeral `MemoryService` values are cleared.


## App Detection & Browser Fallback

- App detection uses `url_launcher` with UAE PASS schemes:
  - Prod: `uaepass://`
  - Staging: `uaepassstg://`
- If unavailable, the flow stays in WebView with the web ACR (`Const.uaePassWebACR`).


## Native Platform Setup

### Android

1) Deep link intent filter (already updated):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="adcdainspector"
        android:host="uaepass"
        android:path="/callback" />
</intent-filter>
```

2) Queries for UAE PASS apps and browsers (in `<queries>`):
```xml
<!-- UAE PASS variants -->
<package android:name="ae.uaepass.mainapp" />
<package android:name="ae.uaepass.mainapp.qa" />
<package android:name="ae.uaepass.mainapp.stg" />

<!-- Common browsers -->
<intent>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="http" />
</intent>
<intent>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" />
</intent>
```

3) Ensure the callback URI in app code matches the manifest: `adcdainspector://uaepass/callback`.

### iOS

1) LSApplicationQueriesSchemes (Info.plist):
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>uaepass</string>
  <string>uaepassqa</string>
  <string>uaepassstg</string>
  <string>http</string>
  <string>https</string>
</array>
```

2) URL Types (Info.plist) for deep link:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>adcdainspector</string>
    </array>
  </dict>
</array>
```


## Backend Integration

After obtaining the UAE PASS access token, the app authenticates with the backend using a simplified request:

- Endpoint: `ApiConfig.uaePassLoginEndpoint`
- Body: `{ "uaePassToken": "<access_token>" }`

Backend responsibilities:
- Validate the UAE PASS token signature and claims
- Map/construct app user identity and roles
- Issue app JWTs (access/refresh) returned to the mobile app

The app then stores these tokens and updates user profile information. The `unique_name` claim is extracted and stored to display the signed-in user.


## Storage & Security

- Ephemeral: `MemoryService` (GetStorage namespace `uae-pass-app`)
  - `state`, `codeVerifier`, `accessCode` (cleared after token exchange)
- Persistent (Secure Storage in `UAEPassService`):
  - `uae_pass_access_token`, `auth_method`, plus app tokens returned from backend
  - Select profile fields (e.g., `firstNameEN`, `lastNameEN`, `idn`, `email`, etc.)

Security features:
- PKCE (S256)
- CSRF `state` verification
- Callback URL restriction and validation
- Request timeouts to avoid hangs


## Localization

- The authorization UI locale is set via `ui_locales` (e.g., `en`, `ar`).
- `CustomWebView` shows localized snackbars for common error cases and logout.


## Error Handling

In `uaepass_view.dart`:
- Recognized callback errors: `invalid_request`, `login_required`, `access_denied`, `cancelledOnApp`.
- If callback contains `error`/`error_description`, shows a user-friendly message and exits the flow.
- State mismatch triggers a security error and aborts.

Network requests in `uae_pass_api.dart` use a 20-second timeout for token and userinfo calls.


## Testing Checklist

- Login with UAE PASS app installed (handoff path)
- Login with UAE PASS app not installed (web ACR path)
- Invalid credentials / cancel on app
- State mismatch (simulate if possible)
- Slow/unstable network (timeouts)
- Backend rejects token (verify error surfaced)
- Logout callback returns to app and shows confirmation


## Troubleshooting

- Deep link not triggered:
  - Confirm Android intent filter and iOS URL Types match `adcdainspector://uaepass/callback`.
  - Ensure UAE PASS console redirect URI matches exactly, including scheme/host/path.

- App handoff not working:
  - Verify LSApplicationQueriesSchemes (iOS) and `<queries>` (Android) include UAE PASS schemes/packages.
  - Ensure the staging vs production scheme is correct (`uaepassstg://` vs `uaepass://`).

- State mismatch:
  - Ensure you’re not reusing a prior `CustomWebView` session. The app clears `state` and `codeVerifier` at start and after token exchange.

- Backend 4xx/5xx:
  - Check that backend expects `{ uaePassToken: "..." }` and that CORS/headers are correct.


## Going to Production

- Switch environment to production base URL and client credentials
- Update app icon/name/signing as needed
- Confirm production deep-link and redirect URI are registered in UAE PASS console
- Validate all user types and ACR policies with UAE PASS
- Run full QA on fresh installs and upgrade paths


## Reference

- `lib/uaepass/uae_pass_api.dart` – PKCE & state generation, token exchange, userinfo, logout
- `lib/uaepass/uaepass_view.dart` – WebView, callback handling, state verification
- `lib/uaepass/memory_service.dart` – Ephemeral storage for state & codeVerifier
- `lib/uaepass/constant.dart` – Base URLs, ACR, schemes
- `lib/services/uae_pass_service.dart` – Integration with app auth & backend
- `lib/utils/api_config.dart` – Environment configuration
