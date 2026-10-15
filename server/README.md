# MyRSU API

This service keeps Firebase Auth as the identity provider and uses Supabase PostgreSQL for application data. The API verifies the Firebase ID token on every protected request, then uses the Firebase UID as `user_id`.

## Local setup

```bash
cd server
cp .env.example .env
npm install
npm start
```

Apply `sql/schema.sql` in the Supabase SQL Editor before using the data routes.

## Railway setup

Create a Railway service from the GitHub repository. Railway will use the repository-level `railway.toml` and run:

```bash
npm --prefix server start
```

Add these variables in Railway:

- `SUPABASE_URL` = `https://rtkyuwaqhnhxcnlitjge.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` = the Supabase server-side service-role key
- `FIREBASE_SERVICE_ACCOUNT_JSON` = the complete Firebase Admin service-account JSON on one line
- `CORS_ORIGIN` = the deployed Flutter web origin, or a comma-separated list of allowed origins
- `NODE_ENV` = `production`

Never put either server-side key in Flutter or commit them to GitHub.

## Endpoints

- `GET /health` — public health check
- `GET /api/me` — current user profile
- `PUT /api/me` — update current user profile
- `GET /api/majors` — list majors
- `GET /api/timetable` — current user timetable
- `POST /api/timetable` — create a timetable entry
- `PUT /api/timetable/:id` — update an owned timetable entry
- `DELETE /api/timetable/:id` — delete an owned timetable entry
- `GET /api/events` — current user personal events
- `POST /api/events` — create a personal event
- `PUT /api/events/:id` — update an owned event
- `DELETE /api/events/:id` — delete an owned event

Protected endpoints require:

```http
Authorization: Bearer <Firebase ID token>
```
