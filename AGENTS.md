# Project Memory for Agents

This repository contains the Flutter app `couple_app`, branded as `我们俩`.
Read this file before making changes.

## Stable Project Facts

- Main app path: `couple_app/`.
- GitHub remote: `zc3307511755/091.github.io`.
- GitHub Pages URL: `https://zc3307511755.github.io/091.github.io/`.
- Pages workflow: `.github/workflows/web-pwa-pages.yml`.
- Pages source is `couple_app/build/web`, built by GitHub Actions from `couple_app/web`.
- Do not commit `.env` or credentials.
- Local troubleshooting notes under `.learnings/` are ignored by git. Permanent lessons belong here or under `couple_app/docs/`.

## Build and Validation

- The Windows workspace path contains Chinese characters. `flutter analyze` can fail before code analysis with an LSP parse error from this path.
- Use the ASCII build copy for reliable Flutter validation:
  - Source copy: `C:\src\couple_app_build`
  - Flutter: `C:\src\flutter\bin\flutter.bat`
  - `PUB_CACHE`: `C:\src\pub-cache`
  - `GRADLE_USER_HOME`: `C:\src\gradle-home`
- Sync source to the ASCII copy before validation. Exclude generated folders such as `.dart_tool`, `build`, `.gradle`, `.kotlin`, `Pods`, and `ephemeral`.
- Run:
  - `flutter analyze`
  - `flutter test`
  - `.\scripts\build_web.ps1 -BaseHref '/091.github.io/'`
  - Android builds from `C:\src\couple_app_build`

## Android Update Lessons

- The Android in-app updater reads:
  `https://zc3307511755.github.io/091.github.io/app_update.json`.
- `download_url` must not be empty.
- Avoid using `raw.githubusercontent.com` as the only Android download target. It can pass desktop checks but still fail for users on mobile networks.
- Prefer a GitHub Pages download page under:
  `couple_app/web/downloads/`
- Publish split APKs rather than one large universal APK:
  - `arm64-v8a`: most modern phones
  - `armeabi-v7a`: older phones
  - `x86_64`: emulators/special devices
- Verify online after deployment:
  - `app_update.json` reports the expected version/build.
  - `/downloads/` returns HTTP 200.
  - each APK returns HTTP 200 and `application/vnd.android.package-archive`.
- `latest_build_number` must match the Android APK `versionCode` reported by `aapt dump badging`, not the small pubspec build suffix. For example, `version: 0.2.2+4` built as Android `versionCode='2004'`, so update metadata must use `2004`.
- Keep the Android signing key stable. Current release builds intentionally use the debug signing config, matching earlier debug APK installs.

## Supabase Schema Lessons

- New client features can require database schema changes. Always rerun `couple_app/supabase_schema.sql` in Supabase SQL Editor after schema-related changes.
- Invite pairing rejects any account that already has a `pending` or `active` row in `couples`. Check current rows before blaming the UI.
- The recovery path for stale invite/relationship state is `leave_current_couple`, which archives the current `pending`/`active` row and frees both users to pair again.
- The coupon request/expiry update requires:
  - `coupons.expires_at`
  - `coupons.source_request_id`
  - `coupon_requests` table
  - `respond_coupon_request` RPC
- If those are missing, request coupons and expiry features will not work. The client has fallback logic so basic long-lived coupon issue/use can still work on the old schema.
- Use REST checks to confirm schema before blaming UI code:
  - `coupons?select=id,expires_at,source_request_id&limit=1`
  - `coupon_requests?select=id,status&limit=1`
  - `rpc/respond_coupon_request`

## Windows PowerShell Gotchas

- Do not pipe directly after a multiline `foreach` block in PowerShell. Assign output first:
  `$rows = foreach (...) { ... }`
  then:
  `$rows | Format-Table`
- When interpolating variables before `?`, `/`, or other adjacent URL text, use `${name}`.
- Prefer `Invoke-RestMethod` with `ConvertTo-Json` for JSON bodies instead of hand-quoted `curl.exe -d` strings.

## Deployment Verification

- Public GitHub Actions API requests may be rate-limited from shared IPs. Prefer direct Pages URL verification unless workflow details are required.
- For Pages, verify deployed static assets directly with cache-busting query strings.
- A push to `main` triggers Pages when files under `couple_app/**` or the workflow change.
