# Ingredient AI Neon API

This API sits between the Flutter app and Neon Postgres. It keeps the database
connection string off mobile devices and provides account-based sync.

## Setup

1. Create a Neon project.
2. Apply `../neon/schema.sql`.
3. Copy `server/.env.example` to `server/.env`.
4. Fill `DATABASE_URL` and `JWT_SECRET`.
5. Run:

```powershell
npm install
npm run dev
```

## Endpoints

- `GET /health`
- `POST /auth/signup`
- `POST /auth/login`
- `POST /sync/history`
- `POST /sync/food-entries`

`/sync/food-entries` stores nutrition fields plus `cost` and `currency`, so the
Flutter app can sync both diet records and meal expense data.

## Android Emulator

When the API runs on the Windows host, set the Flutter `.env` value to:

```text
NEON_API_BASE_URL=http://10.0.2.2:8787
```

For a real phone or final deployment, deploy this API to a public HTTPS host and
use that URL instead.
