# Food Companion Guest, Cloud, and Quota Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a no-Email local mode, server-enforced daily AI quotas, reliable verification feedback, and a Cloud Run-backed release.

**Architecture:** Firebase Anonymous Authentication secures guest API requests while guest records stay in the local repository. Cloud Run verifies every token and uses transactional Firestore counters before Gemini analysis; verified Email users receive a larger allowance. Firebase Authentication sends verification messages independently of the developer computer.

**Tech Stack:** Flutter, Firebase Authentication, Cloud Firestore, Express.js, firebase-admin, Gemini, Google Cloud Run, Secret Manager.

## Global Constraints

- Work directly on `main`; do not create a branch or pull request.
- Never commit `.env`, Firebase runtime config, signing credentials, local account files, APKs, videos, or reports.
- Do not bulk-delete files or directories.
- Anonymous quota is 5 per UTC day; verified Email quota is 50 per UTC day.
- Do not expose the Gemini API key in Flutter or GitHub.

---

### Task 1: Server Quota Service

**Files:**
- Create: `foodlens_ai/server/src/quota.js`
- Modify: `foodlens_ai/server/src/firebase.js`
- Modify: `foodlens_ai/server/src/index.js`
- Modify: `foodlens_ai/server/src/app.js`
- Test: `foodlens_ai/server/test/quota.test.js`
- Test: `foodlens_ai/server/test/app.test.js`

**Interfaces:**
- Produces: `createDailyQuotaService({ firestore, now })` with `reserve(identity)` and `refund(reservation)`.
- Consumes: decoded Firebase token fields `uid`, `email_verified`, and `firebase.sign_in_provider`.

- [ ] **Step 1: Write failing quota tests** for anonymous limit 5, verified limit 50, UTC date partitioning, and refund.
- [ ] **Step 2: Run `npm test -- quota.test.js`** and confirm missing module/behavior failures.
- [ ] **Step 3: Implement transactional quota reservations** under `ai_usage/{uid_date}` without logging tokens or secrets.
- [ ] **Step 4: Add middleware integration tests** that expect HTTP 429 and quota metadata.
- [ ] **Step 5: Run `npm test`** and confirm all server tests pass.

### Task 2: Guest Mode And Verification Feedback

**Files:**
- Create: `foodlens_ai/app/lib/auth/auth_action_state.dart`
- Modify: `foodlens_ai/app/lib/app.dart`
- Modify: `foodlens_ai/app/lib/services/food_analysis_api.dart`
- Modify: `foodlens_ai/app/lib/screens/settings_screen.dart`
- Test: `foodlens_ai/app/test/auth/auth_action_state_test.dart`
- Test: `foodlens_ai/app/test/services/food_analysis_api_test.dart`
- Test: `foodlens_ai/app/test/widget_test.dart`

**Interfaces:**
- Produces: explicit idle/loading/success/error state for registration, resend, and refresh actions.
- Consumes: Firebase anonymous sign-in and the existing local `MemoryFoodRepository`.

- [ ] **Step 1: Write failing tests** for status transitions, 429 quota parsing, and the local-mode entry button.
- [ ] **Step 2: Run targeted Flutter tests** and confirm expected failures.
- [ ] **Step 3: Add guest sign-in and local dashboard routing** while preserving registered Firestore behavior.
- [ ] **Step 4: Add visible registration/resend/refresh feedback** and prevent duplicate taps.
- [ ] **Step 5: Display remaining quota and quota-exhausted guidance** without exposing backend secrets.
- [ ] **Step 6: Run `flutter analyze` and `flutter test --no-pub`**.

### Task 3: Cloud Deployment

**Files:**
- Modify: `foodlens_ai/server/.env.example`
- Modify: `foodlens_ai/docs/deploy-cloud-run.md`
- Modify: `foodlens_ai/docs/setup.md`

**Interfaces:**
- Produces: a public HTTPS Cloud Run base URL with protected AI endpoints.
- Consumes: Firebase project `foodlens-ai-fd67f`, runtime service account, and Secret Manager values.

- [ ] **Step 1: Verify project billing/API readiness** without enabling paid resources silently.
- [ ] **Step 2: Deploy the existing Dockerfile** with minimum instances zero and unauthenticated network access.
- [ ] **Step 3: Verify `/health`** returns `{ "ok": true }` after the local computer is no longer involved.
- [ ] **Step 4: Run one authenticated AI request** and verify Firestore quota state and response metadata.
- [ ] **Step 5: Record the Cloud Run URL** in ignored release configuration and deployment documentation.

### Task 4: Release, Evidence, And Report

**Files:**
- Modify: `foodlens_ai/docs/build_final_report.py`
- Generate locally: `FoodLens_AI_Final_Report.docx`
- Generate locally: `FoodLens_AI_demo.mp4`
- Generate locally: signed release APK

**Interfaces:**
- Produces: verified `v1.0.0` GitHub asset, final video, and Word report.

- [ ] **Step 1: Build and sign the release APK** with Cloud Run URL and Firebase config.
- [ ] **Step 2: Verify signature, package label `食伴 AI`, launcher icon resources, and emulator flow**.
- [ ] **Step 3: Run secret scan and confirm ignored artifacts are untracked**.
- [ ] **Step 4: Update only the existing `v1.0.0` asset** and download it publicly to compare hash and package metadata.
- [ ] **Step 5: Verify the complete video with `ffprobe` and sampled frames**.
- [ ] **Step 6: Update the midterm-based report with cloud, guest, quota, Gmail, and final release evidence**.
- [ ] **Step 7: Visually inspect the changed Word pages** and confirm links and images render correctly.
- [ ] **Step 8: Commit and push source-only changes to `main`**.

