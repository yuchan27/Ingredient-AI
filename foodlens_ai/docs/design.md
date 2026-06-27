# FoodLens AI MVP Design

## Objective

Build a production-shaped Flutter and Node.js MVP that runs locally, supports
Android Emulator networking, and can later deploy the API to Google Cloud Run.

## Architecture

- `app/`: Flutter Material 3 application using Firebase Authentication,
  Cloud Firestore, Firebase Storage, and a token-authenticated API client.
- `server/`: Express API using Firebase Admin to verify ID tokens and enforce
  image ownership before downloading images from Storage and calling Gemini.
- `docs/`: local setup, Firebase setup, emulator testing, and Cloud Run deploy
  instructions.

The client uploads an image to
`users/{uid}/food_images/{recordId}.jpg`, obtains a Firebase ID token, and sends
only the Storage object path to the API. The API derives `uid` from the verified
token, rejects paths outside `users/{uid}/`, downloads the object, and returns a
normalized nutrition JSON object. The user can edit the result before saving it
to `users/{uid}/food_records/{recordId}`.

## Authentication And Email

Firebase Email/Password Authentication owns registration, sign-in, sign-out,
and verification-email delivery. Newly registered users are held on a
verification screen until `emailVerified` is true. The Gmail SMTP settings are
used only by the development-only `/sendTestEmail` endpoint and are never sent
to the Flutter client.

## Security Boundaries

- Firebase ID tokens are accepted only through `Authorization: Bearer`.
- Storage paths are allowlisted to the authenticated user's prefix.
- Firestore and Storage rules deny unauthenticated access and cross-user paths.
- Request bodies have explicit limits and schema validation.
- Production errors do not return stack traces or environment values.
- Cloud Run secrets belong in Secret Manager; service-account private keys are
  used only for local development when Application Default Credentials are not
  available.

## User Experience

FoodLens AI uses a restrained dark-on-light health-tool interface with clear
nutrition metrics and direct actions. The first screen is authentication when
signed out and the food record list when signed in. Adding a food record is a
linear flow: choose image, upload/analyze, review editable values, then save.

## Verification

- Node unit and route tests cover health, development email gating, token
  enforcement, path ownership, Gemini normalization, and error responses.
- Flutter unit/widget tests cover API URL selection, JSON parsing, and core
  signed-out UI behavior.
- Local smoke tests exercise `/health`; Firebase-backed flows are exercised when
  valid Firebase project configuration is available.

