# Troubleshooting Notes

These notes collect the concrete issues already hit in this project and the
working fixes. Keep them updated when a non-obvious problem is solved.

## Flutter Analyze Fails in Chinese Path

Symptom:

```text
FormatException: Unterminated string
analysis server exited with code 255
```

Cause:

- The project path contains Chinese characters:
  `C:\Users\朱超\Documents\软件开发.情侣版\couple_app`
- Dart analysis server can fail before reporting normal diagnostics.

Fix:

1. Sync `couple_app` to `C:\src\couple_app_build`.
2. Use ASCII cache paths:
   `PUB_CACHE=C:\src\pub-cache`,
   `GRADLE_USER_HOME=C:\src\gradle-home`.
3. Run Flutter commands from `C:\src\couple_app_build`.

## Android Build Stalls on CMake

Symptom:

```text
Preparing "Install CMake 3.22.1 v.3.22.1".
```

The SDK folder only contains `.installer`, or SDK `.temp` contains an
incomplete CMake zip.

Fix:

1. Download `https://dl.google.com/android/repository/cmake-3.22.1-windows.zip`.
2. Extract it to:
   `%LOCALAPPDATA%\Android\Sdk\cmake\3.22.1`
3. Rebuild from the ASCII build copy.

## Android Update Detects New Version but Cannot Download

Checklist:

1. Open:
   `https://zc3307511755.github.io/091.github.io/app_update.json`
2. Confirm `download_url` is not empty.
3. Open the `download_url` on the same phone network. It should normally point
   directly to the recommended `arm64-v8a` APK.
4. Check each APK with HTTP HEAD/GET.
5. Confirm `latest_build_number` equals the APK's Android `versionCode`.

Lessons learned:

- A GitHub raw APK URL can pass desktop checks but still be unreliable on
  mobile networks.
- A single large universal APK can be unnecessarily fragile.
- The current stable approach is a GitHub Pages download page at:
  `couple_app/web/downloads/index.html`
- Keep `download_page_url` as the human-facing page for alternative ABIs, while
  `download_url` can point directly to the recommended APK for the in-app
  update button.
- Flutter/Android can transform a pubspec version such as `0.2.2+4` into
  Android `versionCode='2004'`. The in-app updater compares against Android's
  installed `versionCode`, so `app_update.json` must use `2004`, not `4`.
- Split APKs have ABI-specific Android `versionCode` offsets, such as
  `1005` for armeabi-v7a, `2005` for arm64-v8a, and `4005` for x86_64. Keep
  `latest_build_number` as the recommended arm64 code for old clients, and set
  `latest_base_build_number` to the pubspec build suffix so new clients do not
  repeatedly prompt after installing a non-arm64 APK.
- Release APKs must be built with Supabase dart defines. A plain
  `flutter build apk --release --split-per-abi` can produce an APK that opens
  without backend configuration. Use `scripts/build_android_release.ps1`.
- The page links split APKs:
  - `womenlia-*-arm64-v8a.apk`
  - `womenlia-*-armeabi-v7a.apk`
  - `womenlia-*-x86_64.apk`

Verification commands:

```powershell
$json = Invoke-RestMethod `
  -Uri "https://zc3307511755.github.io/091.github.io/app_update.json?check=$(Get-Date -UFormat %s)"
$json.latest_version
$json.latest_build_number
$json.download_url

& "$env:LOCALAPPDATA\Android\Sdk\build-tools\37.0.0\aapt.exe" `
  dump badging "C:\src\couple_app_build\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" |
  Select-String "package:"

Invoke-WebRequest `
  -Uri "https://zc3307511755.github.io/091.github.io/downloads/" `
  -UseBasicParsing `
  -TimeoutSec 20

Invoke-WebRequest `
  -Uri "https://zc3307511755.github.io/091.github.io/downloads/womenlia-0.2.1-build3-arm64-v8a.apk" `
  -Method Head `
  -UseBasicParsing `
  -TimeoutSec 30
```

## Android Install Fails After Download

Check these first:

- Package name must remain `com.couple.couple_app`.
- New versionCode must be higher than the installed APK.
- Signing certificate must match the installed APK.
- Most real phones should use `arm64-v8a`; older phones may need
  `armeabi-v7a`.

Helpful commands:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\37.0.0\aapt.exe" `
  dump badging "path\to\app.apk"

& "$env:LOCALAPPDATA\Android\Sdk\build-tools\37.0.0\apksigner.bat" `
  verify --print-certs "path\to\app.apk"
```

On Windows, `aapt dump badging` can fail with `Illegal byte sequence` when the
APK path contains Chinese characters. Run it against the ASCII build output
under `C:\src\couple_app_build`, then compare file hashes after copying the APK
to `couple_app\web\downloads`.

## Coupon Features Fail

Symptoms:

- Cannot send coupon.
- Cannot request coupon.
- Cannot use coupon.
- Coupon page shows schema/RPC/PostgREST errors.

Root cause already seen:

- The remote Supabase schema was still old.
- Missing items:
  - `coupons.expires_at`
  - `coupons.source_request_id`
  - `coupon_requests`
  - `respond_coupon_request`

Diagnosis:

```powershell
$envFile = "couple_app\.env"
$vars = @{}
foreach ($line in Get-Content -LiteralPath $envFile) {
  if ($line -match "^\s*#" -or $line -notmatch "=") { continue }
  $name, $value = $line.Split("=", 2)
  $vars[$name] = $value.Trim()
}

$url = $vars["SUPABASE_URL"]
$key = $vars["SUPABASE_PUBLISHABLE_KEY"]
$headers = @{
  apikey = $key
  Authorization = "Bearer $key"
  "Accept-Profile" = "public"
  "Content-Profile" = "public"
}

Invoke-WebRequest `
  -Uri "${url}/rest/v1/coupons?select=id,expires_at,source_request_id&limit=1" `
  -Headers $headers `
  -UseBasicParsing

Invoke-WebRequest `
  -Uri "${url}/rest/v1/coupon_requests?select=id,status&limit=1" `
  -Headers $headers `
  -UseBasicParsing
```

Fix:

1. Open Supabase SQL Editor.
2. Run `couple_app/supabase_schema.sql` completely.
3. Confirm Realtime includes `coupon_requests`.
4. Retest with two paired accounts.

Current client fallback:

- If the old schema is still present, long-lived basic coupon issue/use should
  keep working.
- Request coupons and coupon expiry still require the upgraded schema.

## Invite Pairing Cannot Connect

Symptom:

- One account generates an invite code, but the other account cannot bind it.
- The app may show an English backend error such as:
  `user already has an active or pending couple`

Cause already seen:

- Both test accounts already had the same `active` row in `couples`.
- The pairing RPC intentionally blocks new invites or bindings when a user
  already has a `pending` or `active` relationship.

Diagnosis:

```powershell
$envFile = "couple_app\.env"
$vars = @{}
foreach ($line in Get-Content -LiteralPath $envFile) {
  if ($line -match "^\s*#" -or $line -notmatch "=") { continue }
  $name, $value = $line.Split("=", 2)
  $vars[$name] = $value.Trim()
}

$url = $vars["SUPABASE_URL"]
$key = $vars["SUPABASE_PUBLISHABLE_KEY"]

# Login as the affected account, then query with that user's access token:
Invoke-RestMethod `
  -Uri "${url}/rest/v1/couples?select=id,status,invite_code,paired_at,created_at&status=in.(pending,active)" `
  -Headers @{
    apikey = $key
    Authorization = "Bearer <USER_ACCESS_TOKEN>"
    "Accept-Profile" = "public"
    "Content-Profile" = "public"
  }
```

Fix:

1. Run the latest `couple_app/supabase_schema.sql` in Supabase SQL Editor.
2. Use the app's new cancel invite or解除配对 action, which calls
   `leave_current_couple`.
3. Generate a fresh invite code and bind with the other account.

## PowerShell Command Pitfalls

Avoid piping directly after a multiline block:

```powershell
# Fragile
foreach ($x in $items) {
  $x
} | Format-Table

# Safer
$rows = foreach ($x in $items) {
  $x
}
$rows | Format-Table
```

Use `${variable}` in URLs when text follows the variable:

```powershell
"${SupabaseUrl}/rest/v1/${table}?select=*&limit=1"
```

Prefer `Invoke-RestMethod` plus `ConvertTo-Json` for JSON request bodies.

## GitHub Actions API Rate Limit

Symptom:

```text
API rate limit exceeded
```

Fix:

- Prefer direct deployed URL checks for Pages.
- Use cache-busting query strings:
  `?check=<timestamp>`.
- Only use the GitHub Actions API when authenticated or when workflow details
  are essential.
