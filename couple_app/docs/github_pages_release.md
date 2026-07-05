# GitHub Pages Release Checklist

Use this checklist to publish the Flutter Web/PWA build without Apple App Store or TestFlight.

## 1. Create GitHub Repository

1. Create a new GitHub repository.
2. Keep it private or public as you prefer.
3. Push this workspace to the repository.

Recommended commands from the repository root:

```powershell
git add .github couple_app .learnings
git commit -m "Prepare Flutter Web PWA release"
git branch -M main
git remote add origin https://github.com/<your-user>/<your-repo>.git
git push -u origin main
```

## 2. Add GitHub Secrets

Open the repository on GitHub:

```text
Settings -> Secrets and variables -> Actions -> New repository secret
```

Add:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Use the same Supabase project values that the local `.env` file uses.

## 3. Enable GitHub Pages

Open:

```text
Settings -> Pages
```

Set:

```text
Source: GitHub Actions
```

## 4. Run Workflow

Open:

```text
Actions -> Web PWA Pages -> Run workflow
```

Leave `base_href` empty. The workflow detects the correct path:

```text
https://<your-user>.github.io/<your-repo>/
```

For a repository named exactly `<your-user>.github.io` under the same account,
the site is served from the root:

```text
https://<your-user>.github.io/
```

and the workflow automatically uses `/`. A repository can still contain
`.github.io` in its name and be a project Pages site. For example,
`zc3307511755/091.github.io` is served at:

```text
https://zc3307511755.github.io/091.github.io/
```

Set `base_href` manually only for a custom deployment path.

## 5. Install on iPhone

1. Open the GitHub Pages HTTPS URL in iPhone Safari.
2. Tap Share.
3. Tap Add to Home Screen.
4. Open the app from the home screen icon.

## Notes

- Do not commit `.env`.
- The PWA uses the same Supabase backend as Android.
- If the page opens but the app stays blank, check that `base_href` matches the deployed path.
- Pushing changes under `couple_app/` triggers the `Web PWA Pages` workflow.
