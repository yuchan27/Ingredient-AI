# Ingredient AI Neon API

This small API keeps the Flutter app from exposing the Neon Postgres connection
string on mobile devices.

## Setup

1. Create a Neon project and copy the pooled connection string.
2. Run `neon/schema.sql` in the Neon SQL editor or with `neonctl`.
3. Copy `server/.env.example` to `server/.env`.
4. Fill `DATABASE_URL` and `JWT_SECRET`.
5. Run:

```powershell
npm install
npm run dev
```

For Android emulator testing, set Flutter `.env`:

```text
NEON_API_BASE_URL=http://10.0.2.2:8787
```

For real phones or final submission, deploy this API to a public host and set
`NEON_API_BASE_URL` to that deployed HTTPS URL.
