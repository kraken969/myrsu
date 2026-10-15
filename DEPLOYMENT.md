# MyRSU combined Railway deployment

This repository is configured as one Railway service. The Docker build compiles the Flutter web interface and packages it with the Node.js API. Railway serves both from one public domain:

- Flutter interface: `/`
- API health: `/health`
- API routes: `/api/...`

## Railway settings

Connect Railway to the `main` branch of `https://github.com/kraken969/myrsu`.

Set the service builder to **Dockerfile** and use the repository-root `Dockerfile`. If Railway has an old manual start command, clear it so the Dockerfile command is used, or set it to:

```text
npm --prefix server start
```

The service must have these variables:

```text
SUPABASE_URL=https://rtkyuwaqhnhxcnlitjge.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<private Supabase service-role key>
FIREBASE_SERVICE_ACCOUNT_JSON=<complete Firebase Admin service-account JSON>
NODE_ENV=production
CORS_ORIGIN=*
```

Never commit the service-role key or Firebase service-account JSON.

## Deploy and verify

After pushing this repository, trigger a Railway redeploy. The build log should contain both Flutter and Node steps. Open:

```text
https://<railway-domain>/
https://<railway-domain>/health
```

The root URL should show the Flutter app. The health URL should return JSON.

After opening the Flutter site in Chrome, use the browser menu and choose **Install MyRSU** to install it as a desktop-style Progressive Web App. The app icon and install behavior come from `web/manifest.json` and the existing web icons.

## Current data architecture

The Flutter app currently uses Firebase Auth, Firestore, and Firebase Storage directly. The Railway API and Supabase schema are deployed alongside it, but changing the Flutter data layer to use the API is a separate migration step.
