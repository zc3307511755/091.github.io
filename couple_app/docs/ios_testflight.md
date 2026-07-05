# iOS TestFlight Cloud Build

This project uses GitHub Actions to build an iOS IPA on a macOS runner and upload it to TestFlight. It does not publish the app publicly on the App Store.

## Required Accounts

- Apple Developer Program membership.
- App Store Connect access.
- A GitHub repository containing this workspace.

## Apple Setup

1. In Apple Developer, create an App ID for the iOS bundle identifier.
2. In App Store Connect, create an app record with the same bundle identifier.
3. Create an Apple Distribution certificate and export it as a `.p12`.
4. Create an App Store provisioning profile for the bundle identifier.
5. Create an App Store Connect API key with permission to upload builds.

## GitHub Secrets

Add these repository secrets in GitHub:

| Secret | Meaning |
| --- | --- |
| `SUPABASE_URL` | Supabase project URL. |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase publishable/anon key. |
| `APPLE_TEAM_ID` | Apple Developer Team ID. |
| `IOS_BUNDLE_ID` | App bundle identifier, for example `com.yourname.coupleapp`. |
| `IOS_CERTIFICATE_P12_BASE64` | Base64 encoded Apple Distribution `.p12`. |
| `IOS_CERTIFICATE_PASSWORD` | Password for the `.p12` file. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 encoded App Store `.mobileprovision` file. |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key ID. |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect issuer ID. |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | Base64 encoded App Store Connect `.p8` key. |

On macOS or Linux, encode files with:

```bash
base64 -i certificate.p12 | pbcopy
base64 -i profile.mobileprovision | pbcopy
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

On Windows PowerShell, encode files with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8"))
```

## Run the Workflow

1. Push the repository to GitHub.
2. Open GitHub Actions.
3. Run `iOS TestFlight`.
4. Optionally set `build_name` and `build_number`.
5. After the workflow completes, open App Store Connect and add the processed build to TestFlight testing.

## Notes

- The workflow builds from the `couple_app` subdirectory.
- The IPA artifact is also uploaded to the workflow run.
- TestFlight builds are private until you invite testers.
- The workflow patches the Bundle Identifier in CI using `IOS_BUNDLE_ID`; keep the GitHub secret aligned with the App Store Connect app record.
