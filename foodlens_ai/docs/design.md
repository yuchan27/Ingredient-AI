# FoodLens AI MVP Design

## Objective

Build a production-shaped Flutter and Node.js MVP that runs locally, supports
Android Emulator networking, and can later deploy the API to Google Cloud Run.

## Architecture

- `app/`: Flutter Material 3 application using Firebase Authentication,
  Cloud Firestore, app-private local image storage, and a token-authenticated
  API client.
- `server/`: Express API using Firebase Admin to verify ID tokens and enforce
  image limits before calling Gemini 2.5 Flash with Gemma fallback.
- `docs/`: local setup, Firebase setup, emulator testing, and Cloud Run deploy
  instructions.

The client sends the selected JPEG/PNG/WebP as an authenticated multipart
request. The API derives `uid` from the verified token, enforces a 10 MB limit,
and returns normalized nutrition JSON. The user can edit the result before the
record metadata is saved to `users/{uid}/food_records/{recordId}`. The image is
stored in the app's private documents directory, so Spark-plan users do not
depend on paid Firebase Storage. A legacy owned Storage-path adapter remains
available for a future Blaze/Cloud Run deployment.

## Authentication And Email

Firebase Email/Password Authentication owns registration, sign-in, sign-out,
and verification-email delivery. Newly registered users are held on a
verification screen until `emailVerified` is true. The Gmail SMTP settings are
used only by the development-only `/sendTestEmail` endpoint and are never sent
to the Flutter client.

## Security Boundaries

- Firebase ID tokens are accepted only through `Authorization: Bearer`.
- Multipart images are MIME allowlisted and limited to 10 MB.
- Firestore rules deny unauthenticated access and cross-user paths.
- Request bodies have explicit limits and schema validation.
- Production errors do not return stack traces or environment values.
- Cloud Run secrets belong in Secret Manager; service-account private keys are
  used only for local development when Application Default Credentials are not
  available.

## User Experience

FoodLens AI uses a restrained dark-on-light health-tool interface with clear
nutrition metrics and direct actions. The first screen is authentication when
signed out and the food record list when signed in. Adding a food record is a
linear flow: choose image, analyze, review editable values, then save locally
and synchronize Firestore metadata.

## Verification

- Node unit and route tests cover health, development email gating, token
  enforcement, path ownership, Gemini normalization, and error responses.
- Flutter unit/widget tests cover API URL selection, multipart analysis,
  local-image persistence, record models, insights, and signed-out UI behavior.
- Local smoke tests exercise `/health`; live Firebase Auth, Firestore, and
  authenticated Gemini analysis have been verified with the configured project.
