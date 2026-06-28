# Food Companion Guest, Cloud, and Quota Design

## Goal

Food Companion must remain useful without an Email account, keep registered-user data synchronized, and keep AI analysis available when the developer computer is turned off.

## Identity Modes

- Guest mode uses Firebase Anonymous Authentication only to obtain a trusted backend token. It does not ask for Email or password.
- Guest food records use the existing local repository and never write to a cross-device Firestore collection.
- Registered mode requires a verified Email account and uses Firestore offline persistence plus cloud synchronization.
- The authentication screen exposes three explicit actions: sign in, register, and continue locally.

## AI Quotas

- The backend, not the Flutter client, enforces daily limits.
- Anonymous users receive 5 AI analyses per UTC calendar day.
- verified Email users receive 50 AI analyses per UTC calendar day.
- Firestore transactions store one counter per Firebase uid and UTC date so Cloud Run instances share the same quota state.
- A successful response includes remaining quota metadata. Exhaustion returns HTTP 429 with a user-facing message and quota fields.
- Failed authentication and invalid uploads do not consume quota. A Gemini failure refunds the reserved quota unit.

## Email Verification UX

- Firebase Authentication remains the sender, so verification delivery does not depend on the local Node server.
- Register, resend, and refresh actions have visible loading states and disable duplicate taps.
- Success and failure messages are shown inline and through a SnackBar where appropriate.
- Resend applies a short client cooldown while Firebase remains the authoritative anti-abuse layer.

## Cloud Runtime

- The Express server runs on Google Cloud Run with minimum instances set to zero to stay within free usage where possible.
- Firebase Admin uses the Cloud Run service account and Application Default Credentials.
- Gemini secrets remain in Secret Manager or Cloud Run secret environment variables and are never bundled into the APK.
- Release builds use the Cloud Run HTTPS URL as `API_BASE_URL`; local development keeps `10.0.2.2:3000` available.

## Testing And Release

- Flutter widget/unit tests cover guest entry, visible busy/status states, and quota error rendering.
- Node tests cover anonymous and verified limits, daily keying, 429 responses, and quota refund behavior.
- Cloud `/health`, authenticated AI analysis, Firebase verification delivery, APK signature, package label, and launcher icon are verified before Release replacement.
- `v1.0.0` is updated only after public asset download and hash verification.

