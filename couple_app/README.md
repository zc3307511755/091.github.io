# 我们俩

两个人的日常、纪念、互动和小约定。

## Setup

1. Create a Supabase project.
2. Run `supabase_schema.sql` in the Supabase SQL Editor.
3. Copy the project URL and publishable/anon key from Supabase.
4. Install Flutter, then run:

```bash
flutter create . --org com.couple
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key
```

Or use the helper script:

```powershell
.\scripts\run_app.ps1 `
  -SupabaseUrl "https://your-project.supabase.co" `
  -SupabasePublishableKey "your-publishable-or-anon-key"
```

You can also copy `.env.example` to `.env`, fill in the values, and run:

```powershell
.\scripts\run_app.ps1
```

For Android builds on this Windows machine, use the ASCII build copy:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PUB_CACHE = 'C:\src\pub-cache'
$env:GRADLE_USER_HOME = 'C:\src\gradle-home'
Set-Location -LiteralPath 'C:\src\couple_app_build'
C:\src\flutter\bin\flutter.bat build apk --debug `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key
```

Or use:

```powershell
.\scripts\build_android_debug.ps1 `
  -SupabaseUrl "https://your-project.supabase.co" `
  -SupabasePublishableKey "your-publishable-or-anon-key"
```

If `.env` is filled in, the Android build script can also run without
arguments:

```powershell
.\scripts\build_android_debug.ps1
```

The app includes a basic Android update check under `我的 -> 安卓版更新`.
It reads `web/app_update.json` after that file is deployed to GitHub Pages.
See `docs/android_updates.md` before publishing a new APK.

## iOS build

iOS cannot be built on Windows directly. Use one of these paths:

- Local Mac: install Xcode, CocoaPods, and Flutter, then open/build the `ios`
  project from macOS.
- Cloud build: use the GitHub Actions TestFlight workflow in
  `.github/workflows/ios-testflight.yml`.

From macOS:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ios \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-or-anon-key
```

For App Store or TestFlight distribution, configure the Bundle Identifier,
Apple Developer team, signing certificate, provisioning profile, app icon, and
display name in Xcode.

See `docs/ios_testflight.md` for the cloud build and TestFlight setup.

## Web/PWA build

Build the browser version:

```powershell
.\scripts\build_web.ps1
```

Preview it locally:

```powershell
.\scripts\serve_web.ps1 -Port 8080
```

Deploy `build\web` to an HTTPS static host, then open it in iPhone Safari and
use Share -> Add to Home Screen. See `docs/pwa.md`.

The repository also includes a GitHub Pages workflow:

```text
.github/workflows/web-pwa-pages.yml
```

See `docs/github_pages_release.md` for the release checklist.
See `docs/troubleshooting.md` for known build, deployment, Android update, and
Supabase schema troubleshooting notes.

After native platform folders are generated, check image permissions before
testing meal photo upload:

- iOS: add camera/photo usage descriptions in `ios/Runner/Info.plist`.
- Android: confirm camera/gallery access works on the target SDK and device.

The current source covers:

- Auth and profile loading
- Invite-code pairing
- Shared todos
- Couple coupons
- Shared journals
- Anniversaries
- Meal photos and meal plans
- Realtime subscriptions for shared modules

## Supabase checklist

1. Create a new Supabase project.
2. Open SQL Editor and run `supabase_schema.sql` completely.
   For existing projects, rerun `supabase_schema.sql` before using coupon
   expiry or coupon requests. The update adds `coupon_requests`, coupon expiry
   fields, and the `respond_coupon_request` RPC.
3. In Authentication settings, enable email/password signups.
4. In Storage, confirm the `meals` bucket exists after the SQL script runs.
5. In Realtime, confirm these tables are enabled:
   `todos`, `coupons`, `coupon_requests`, `journals`, `anniversaries`,
   `meal_entries`, `meal_plans`.
6. Start the app with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
7. Register two test accounts.
8. Use one account to create an invite code and the other to join it.
9. Test each shared module from both accounts:
   todos, coupons, journals, anniversaries, meal entries, and meal plans.
10. Confirm data isolation by signing in with an unpaired third account.

Run a backend smoke check:

```powershell
.\scripts\check_supabase.ps1
```

Run a two-account backend smoke test after creating confirmed users:

```powershell
.\scripts\smoke_supabase.ps1 `
  -EmailA "first-user@example.com" `
  -PasswordA "first-password" `
  -EmailB "second-user@example.com" `
  -PasswordB "second-password"
```

Coupon issue/use is optional because the current client policy does not delete
coupons. Add `-IncludeCoupon` when you intentionally want to create one used
test coupon.

For local testing, either disable email confirmation temporarily in Supabase
Auth settings or manually create confirmed test users in the dashboard. With
email confirmation enabled, signup returns no active session until the email is
confirmed, and automated two-account testing cannot continue.
