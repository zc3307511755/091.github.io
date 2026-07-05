# Flutter Web + PWA

The Web/PWA build lets the app run from a browser and be added to the iPhone home screen without App Store, TestFlight, or an Apple Developer account.

## Build

```powershell
.\scripts\build_web.ps1
```

The build output is:

```text
build\web
```

For a subpath deployment, pass a base href:

```powershell
.\scripts\build_web.ps1 -BaseHref "/couple-app/"
```

## Local Preview

```powershell
.\scripts\serve_web.ps1 -Port 8080
```

Then open:

```text
http://localhost:8080
```

## iPhone Usage

1. Deploy `build\web` to an HTTPS static host.
2. Open the URL in Safari on iPhone.
3. Tap Share.
4. Tap Add to Home Screen.
5. Open the app from the new home screen icon.

## Hosting Options

- GitHub Pages
- Netlify
- Vercel
- Cloudflare Pages
- Supabase Storage static hosting with a CDN in front

## GitHub Pages Deployment

This repository includes `.github/workflows/web-pwa-pages.yml`.

1. Push the repository to GitHub.
2. Add repository secrets:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
3. In GitHub, open Settings -> Pages.
4. Set Source to GitHub Actions.
5. Run the `Web PWA Pages` workflow manually, or push to `main`.
6. Open the Pages URL on iPhone Safari and add it to the home screen.

For a normal project Pages URL, the workflow uses:

```text
/<repository-name>/
```

as the Flutter `base-href`. If the repository name ends with `.github.io`, the
workflow automatically uses `/` because that repository is served from the
domain root. If you deploy to a custom domain root, run the workflow manually
and set `base_href` to `/`.

## Notes

- Camera/photo upload support depends on the mobile browser.
- Push notifications are not included in this version.
- The app still uses the same Supabase backend and RLS policies.
