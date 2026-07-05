# Android APK Updates

Android APK updates are not automatic like the Web/PWA build. Each native
Android update needs a new APK installed over the old one.

## In-App Update Check

The app checks this public metadata file:

```text
https://zc3307511755.github.io/091.github.io/app_update.json
```

Source file:

```text
web/app_update.json
```

The metadata fields are:

```json
{
  "latest_version": "0.1.0",
  "latest_build_number": 1,
  "minimum_build_number": 1,
  "download_url": "",
  "published_at": "2026-07-05",
  "release_notes": ["Update note"]
}
```

## Release Flow

1. Update `version` in `pubspec.yaml`, for example `0.2.0+2`.
2. Build split APKs for Android:

   ```powershell
   flutter build apk --release --split-per-abi `
     --dart-define=SUPABASE_URL=https://your-project.supabase.co `
     --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key
   ```

3. Copy the generated APKs into `web/downloads/` and update
   `web/downloads/index.html`.
4. Update `web/app_update.json`:
   - `latest_version`: visible version name
   - `latest_build_number`: Android build number
   - `minimum_build_number`: lowest allowed build number
   - `download_url`: use the Pages download page, for example
     `https://zc3307511755.github.io/091.github.io/downloads/`
   - `release_notes`: user-facing changes
5. Push to `main`.
6. Wait for the Web PWA Pages workflow to deploy.
7. Open the Android app and tap `我的 -> 安卓版更新`.

## Important

- Keep the same Android signing key for every APK, or Android cannot install
  the new APK over the old one.
- If `download_url` is empty, the app can still compare versions but cannot
  show a download button.
- Avoid relying on `raw.githubusercontent.com` as the only APK download target.
  It can pass desktop checks but still fail on some mobile networks.
- Prefer a Pages download page with split APKs. Most phones should use
  `arm64-v8a`; older phones may need `armeabi-v7a`.
- Existing account and couple data stays in Supabase. Updating the APK does
  not delete backend data.

See `troubleshooting.md` for APK download and install checks.
