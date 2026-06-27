# FoodLens AI MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a local-first Flutter Firebase food analysis MVP with a secure Express Gemini API and Cloud Run deployment path.

**Architecture:** Flutter owns authentication, direct Storage uploads, Firestore records, and editable UI state. Express verifies Firebase tokens, enforces Storage ownership, downloads images, calls Gemini, and exposes only normalized nutrition data.

**Tech Stack:** Flutter, Material 3, Firebase Auth, Cloud Firestore, Firebase Storage, Express 5, Firebase Admin, Google Gen AI SDK, Nodemailer, Helmet, CORS, Node test runner, Docker, Cloud Run.

---

### Task 1: Scaffold And Configuration

**Files:**
- Create: `foodlens_ai/app/`
- Create: `foodlens_ai/server/package.json`
- Create: `foodlens_ai/server/.env.example`
- Create: `foodlens_ai/server/.gitignore`
- Create: `foodlens_ai/app/.gitignore`

- [ ] Generate the Flutter Android project under `app/`.
- [ ] Add Firebase, image picker, and HTTP dependencies.
- [ ] Add server dependencies and deterministic npm scripts.
- [ ] Verify `.env`, service-account values, and generated files are ignored.

### Task 2: Server Tests First

**Files:**
- Create: `foodlens_ai/server/test/app.test.js`
- Create: `foodlens_ai/server/test/food-analysis.test.js`
- Create: `foodlens_ai/server/test/config.test.js`

- [ ] Write failing tests for `GET /health` returning `{ "ok": true }`.
- [ ] Write failing tests proving `/sendTestEmail` is denied outside development.
- [ ] Write failing tests for missing/invalid bearer tokens.
- [ ] Write failing tests for cross-user Storage paths.
- [ ] Write failing tests for fixed nutrition JSON normalization.
- [ ] Run `npm test` and confirm failures are caused by missing implementation.

### Task 3: Secure Express Implementation

**Files:**
- Create: `foodlens_ai/server/src/app.js`
- Create: `foodlens_ai/server/src/config.js`
- Create: `foodlens_ai/server/src/firebase.js`
- Create: `foodlens_ai/server/src/gemini.js`
- Create: `foodlens_ai/server/src/mailer.js`
- Create: `foodlens_ai/server/src/index.js`

- [ ] Build an injectable Express app with Helmet, explicit CORS, JSON limits,
  custom 404 handling, and redacted production errors.
- [ ] Initialize Firebase Admin from local service-account environment values or
  Application Default Credentials on Cloud Run.
- [ ] Verify Firebase ID tokens and attach the decoded `uid` to requests.
- [ ] Restrict image paths to `users/{uid}/` and download via Firebase Storage.
- [ ] Call Gemini with image bytes and normalize every response field to the
  required fixed JSON schema.
- [ ] Implement the development-only Nodemailer endpoint without logging secrets.
- [ ] Run `npm test` until all server tests pass.

### Task 4: Firebase Rules

**Files:**
- Create: `foodlens_ai/firestore.rules`
- Create: `foodlens_ai/storage.rules`
- Create: `foodlens_ai/firebase.json`

- [ ] Deny unauthenticated access.
- [ ] Allow each authenticated user to access only `users/{uid}` and its own
  `food_records` and `feedback` subcollections.
- [ ] Restrict Storage writes to each user's `food_images` path and image MIME
  types under 10 MB.

### Task 5: Flutter Domain And Service Tests First

**Files:**
- Create: `foodlens_ai/app/test/models/food_record_test.dart`
- Create: `foodlens_ai/app/test/services/api_config_test.dart`
- Create: `foodlens_ai/app/test/widget_test.dart`

- [ ] Write failing JSON round-trip tests for editable food records.
- [ ] Write failing API URL tests for Android Emulator and explicit dart-define
  overrides.
- [ ] Write a failing signed-out shell widget test.
- [ ] Run `flutter test` and confirm expected failures.

### Task 6: Flutter Services And Models

**Files:**
- Create: `foodlens_ai/app/lib/models/food_record.dart`
- Create: `foodlens_ai/app/lib/services/api_config.dart`
- Create: `foodlens_ai/app/lib/services/api_service.dart`
- Create: `foodlens_ai/app/lib/services/auth_service.dart`
- Create: `foodlens_ai/app/lib/services/food_repository.dart`
- Create: `foodlens_ai/app/lib/firebase_options.dart`

- [ ] Implement platform-aware API base URL defaults with `API_BASE_URL`
  dart-define override.
- [ ] Implement bearer-token API calls and fixed response parsing.
- [ ] Implement Firebase registration, verification email, login, refresh, and
  sign-out operations.
- [ ] Implement Storage upload/delete and Firestore CRUD under the authenticated
  user's path.
- [ ] Run Flutter tests until green.

### Task 7: Flutter Feature UI

**Files:**
- Create: `foodlens_ai/app/lib/main.dart`
- Create: `foodlens_ai/app/lib/theme/app_theme.dart`
- Create: `foodlens_ai/app/lib/screens/auth_screen.dart`
- Create: `foodlens_ai/app/lib/screens/email_verification_screen.dart`
- Create: `foodlens_ai/app/lib/screens/home_screen.dart`
- Create: `foodlens_ai/app/lib/screens/add_food_screen.dart`
- Create: `foodlens_ai/app/lib/screens/food_detail_screen.dart`
- Create: `foodlens_ai/app/lib/screens/settings_screen.dart`
- Create: `foodlens_ai/app/lib/screens/feedback_screen.dart`
- Create: `foodlens_ai/app/lib/widgets/nutrition_field.dart`

- [ ] Build authentication and email-verification states.
- [ ] Build the record list, add-food image flow, upload/analyze state, editable
  nutrition form, and save action.
- [ ] Build detail edit/delete, settings, sign-out, and feedback submission.
- [ ] Confirm controls are responsive and do not overlap at Pixel 9 dimensions.

### Task 8: Container And Documentation

**Files:**
- Create: `foodlens_ai/server/Dockerfile`
- Create: `foodlens_ai/server/.dockerignore`
- Create: `foodlens_ai/docs/setup.md`
- Create: `foodlens_ai/docs/deploy-cloud-run.md`
- Create: `foodlens_ai/README.md`

- [ ] Document local environment setup without secret values.
- [ ] Document Firebase Console and FlutterFire configuration.
- [ ] Document Emulator, desktop/web, ngrok, and physical-device API URLs.
- [ ] Document Artifact Registry, Docker build, Secret Manager, Cloud Run deploy,
  Flutter API override, and `/health` verification commands.

### Task 9: End-To-End Verification And Report

**Files:**
- Modify: `C11215139_medium_Flutter.docx` only by copying it to a new extended
  report file before adding FoodLens AI implementation evidence.

- [ ] Run Node tests, syntax checks, npm audit triage, Flutter tests, analyze,
  and Android release build.
- [ ] Start the local API and verify `/health` from Windows and the Emulator.
- [ ] Use Android Emulator QA for authentication/configuration and app screens
  when Firebase credentials permit the flow.
- [ ] Create an extended Word report from the original medium document, preserve
  its original content, and append architecture, security, setup, test evidence,
  screenshots, and limitations.
- [ ] Commit only intended files and push the `codex/foodlens-ai-mvp` branch.

