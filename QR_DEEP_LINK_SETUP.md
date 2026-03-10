# QR Deep Link Setup

## Flutter build

Use your real public domain when building:

```powershell
flutter build web --dart-define=PUBLIC_APP_SCHEME=https --dart-define=PUBLIC_APP_HOST=app.seudominio.com
flutter build apk --dart-define=PUBLIC_APP_SCHEME=https --dart-define=PUBLIC_APP_HOST=app.seudominio.com
flutter build ios --dart-define=PUBLIC_APP_SCHEME=https --dart-define=PUBLIC_APP_HOST=app.seudominio.com
```

## Android App Links

1. Update package name if needed in `android/app/src/main/AndroidManifest.xml`.
2. Replace `REPLACE_WITH_ANDROID_RELEASE_CERT_SHA256` in `web/.well-known/assetlinks.json`.
3. Publish `https://app.seudominio.com/.well-known/assetlinks.json`.

## iOS Universal Links

1. Update `REPLACE_TEAM_ID.com.example.owanyApp` in `web/.well-known/apple-app-site-association`.
2. Keep `ios/Runner/Runner.entitlements` with the domain `applinks:app.seudominio.com`.
3. Publish `https://app.seudominio.com/.well-known/apple-app-site-association` with `Content-Type: application/json`.

## Result

QR payload is now generated as:

- `https://app.seudominio.com/patrimonio/{codigo}`

Flow:

- App installed: deep link opens app and navigates to asset details.
- App not installed: web opens same URL and app parses route on web.
