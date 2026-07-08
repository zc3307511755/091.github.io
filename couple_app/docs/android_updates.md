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
  "latest_base_build_number": 1,
  "minimum_build_number": 1,
  "download_url": "",
  "download_page_url": "",
  "published_at": "2026-07-05",
  "release_notes": ["Update note"]
}
```

## Release Flow

1. Update `version` in `pubspec.yaml`, for example `0.2.0+2`.
2. Build split APKs for Android:

   ```powershell
   .\scripts\build_android_release.ps1
   ```

3. Copy the generated APKs into `web/downloads/` and update
   `web/downloads/index.html`.
4. Update `web/app_update.json`:
   - `latest_version`: visible version name
   - `latest_build_number`: recommended APK Android versionCode
   - `latest_base_build_number`: pubspec build suffix for split APKs
   - `minimum_build_number`: lowest allowed build number
   - `download_url`: direct link to the recommended arm64 APK.
   - `download_page_url`: Pages download page for alternative ABIs, for example
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
- Release APKs must be built with `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` dart defines. Use
  `scripts/build_android_release.ps1`; building manually without those defines
  creates an APK that cannot connect to the backend.
- Avoid relying on `raw.githubusercontent.com` as the only APK download target.
  It can pass desktop checks but still fail on some mobile networks.
- Prefer a Pages download page with split APKs. Most phones should use
  `arm64-v8a`; older phones may need `armeabi-v7a`.
- Existing account and couple data stays in Supabase. Updating the APK does
  not delete backend data.

See `troubleshooting.md` for APK download and install checks.
