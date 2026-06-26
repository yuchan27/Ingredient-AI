# Food Analysis Cloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the existing Flutter food analyzer into a more complete analysis app with local-first storage, Neon Postgres account/cloud sync, nutrition diary, dashboard summaries, and voice-assisted input.

**Architecture:** Keep SQLite as the source of truth so the app remains usable offline. Add a Neon-backed Node API behind a service that degrades to local-only mode when the API URL is not configured, then sync pending local rows when cloud support and network are available. Keep nutrition analytics in pure Dart services so it is testable without emulator or Neon credentials.

**Tech Stack:** Flutter, Dart 3.9, sqflite, Neon Serverless Postgres, Node.js Express API, connectivity_plus, speech_to_text, local unit tests with flutter_test.

---

## Baseline

- Current project is Flutter under `C:\Users\wuwu6\StudioProjects\App_medium`.
- Existing app already supports image/text food analysis through Gemini and SQLite history.
- `flutter test` currently fails because `test/` does not exist.
- `flutter analyze` timed out after 124 seconds during the baseline check.
- Existing untracked files `C11215139_medium_Flutter.docx` and `Gemini_Generated_Image_v7m05tv7m05tv7m0.png` must not be modified.

## File Structure

- Create `lib/models/food_entry.dart`: daily nutrition diary entry with local/cloud sync metadata.
- Modify `lib/models/health_result.dart`: add optional protein, carbs, fiber, grade helpers, and safer numeric parsing.
- Create `lib/services/nutrition_analytics_service.dart`: pure Dart daily totals, averages, and score trend calculation.
- Modify `lib/services/db_service.dart`: migrate SQLite to version 2 with `history`, `food_entries`, and `user_profile` tables plus pending-sync methods.
- Create `lib/services/cloud_sync_service.dart`: optional Neon API initialization, email/password account methods, and Neon-backed upload of pending rows.
- Create `lib/services/voice_input_service.dart`: thin wrapper over `speech_to_text` for voice food-name input.
- Modify `lib/services/ai_service.dart`: request richer nutrition fields from Gemini JSON.
- Modify `lib/views/analyzer_page.dart`: add voice input button, save analysis to diary, and trigger best-effort sync after save.
- Create `lib/views/dashboard_page.dart`: analysis dashboard for totals, averages, score trend, and sync status.
- Create `lib/views/account_page.dart`: email/password sign-in/up, local-only status, manual sync.
- Modify `lib/views/history_page.dart` and `lib/views/history_detail_page.dart`: show sync status and support saving history items as diary entries.
- Modify `lib/widgets/result_card.dart`: show richer nutrition facts and a diary-save action.
- Modify `lib/main.dart`: add bottom navigation tabs for Analyze, Dashboard, History, Account.
- Create `test/models/health_result_test.dart`: tests for robust model parsing.
- Create `test/models/food_entry_test.dart`: tests for diary serialization and pending sync metadata.
- Create `test/services/nutrition_analytics_service_test.dart`: tests for daily totals and trend output.

---

### Task 1: Add Model Tests

**Files:**
- Create: `test/models/health_result_test.dart`
- Create: `test/models/food_entry_test.dart`
- Create: `test/services/nutrition_analytics_service_test.dart`

- [ ] **Step 1: Write failing tests for richer health result parsing**

Create tests that expect string and numeric JSON values to parse into `HealthResult`, including `protein`, `carbs`, `fiber`, and `nutritionGrade`.

- [ ] **Step 2: Write failing tests for food entry serialization**

Create tests that expect `FoodEntry.fromJson(FoodEntry.toJson())` to preserve nutrition values and mark newly created entries as `pendingSync`.

- [ ] **Step 3: Write failing tests for daily nutrition analytics**

Create tests that expect entries from the same day to sum calories, protein, carbs, fat, sugar, sodium, and fiber.

- [ ] **Step 4: Verify RED**

Run: `flutter test test/models test/services`

Expected: FAIL because `FoodEntry` and `NutritionAnalyticsService` do not exist yet and `HealthResult` lacks the richer fields.

---

### Task 2: Implement Pure Dart Models and Analytics

**Files:**
- Modify: `lib/models/health_result.dart`
- Create: `lib/models/food_entry.dart`
- Create: `lib/services/nutrition_analytics_service.dart`

- [ ] **Step 1: Extend `HealthResult`**

Add safe parsing helpers and fields for `protein`, `carbs`, `fiber`, and a computed `nutritionGrade` based on `healthScore`.

- [ ] **Step 2: Add `FoodEntry`**

Implement immutable diary entry serialization with sync metadata: `id`, `cloudId`, `isPendingSync`, `createdAt`, `updatedAt`, and `deletedAt`.

- [ ] **Step 3: Add `NutritionAnalyticsService`**

Implement daily grouping and totals using `FoodEntry.consumedAt`.

- [ ] **Step 4: Verify GREEN**

Run: `flutter test test/models test/services`

Expected: PASS for model and analytics tests.

---

### Task 3: Add Local-First SQLite Storage

**Files:**
- Modify: `lib/services/db_service.dart`

- [ ] **Step 1: Add SQLite migration to version 2**

Create `food_entries` and `user_profile` tables and add `cloudId`, `syncStatus`, `updatedAt`, and `deletedAt` columns to history for future upload.

- [ ] **Step 2: Add repository methods**

Add methods to insert history, list history, insert food entries, list food entries, read pending history, read pending food entries, and mark rows synced.

- [ ] **Step 3: Run local tests**

Run: `flutter test test/models test/services`

Expected: PASS. SQLite plugin behavior is not tested here; this task keeps pure logic covered and compile checks happen in analyze/build.

---

### Task 4: Add Neon Cloud Account and Sync

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/cloud_sync_service.dart`

- [ ] **Step 1: Add dependencies**

Run: `flutter pub add http connectivity_plus uuid speech_to_text intl`

- [ ] **Step 2: Implement Neon API optional initialization**

Create `CloudSyncService.initialize()` that checks `NEON_API_BASE_URL` and returns a local-only state instead of crashing the app when cloud sync is not configured.

- [ ] **Step 3: Implement account methods**

Add email/password sign-in, sign-up, sign-out, and current user email through the Neon-backed Node API.

- [ ] **Step 4: Implement upload sync**

Upload pending history and diary entries into per-user Neon Postgres tables through the Node API and mark local rows synced after successful writes.

- [ ] **Step 5: Verify package resolution**

Run: `flutter pub get`

Expected: dependencies resolve successfully.

---

### Task 5: Add Voice, Dashboard, and Account UI

**Files:**
- Create: `lib/services/voice_input_service.dart`
- Modify: `lib/views/analyzer_page.dart`
- Create: `lib/views/dashboard_page.dart`
- Create: `lib/views/account_page.dart`
- Modify: `lib/views/history_page.dart`
- Modify: `lib/views/history_detail_page.dart`
- Modify: `lib/widgets/result_card.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add voice input wrapper**

Implement speech recognition availability, start listening, stop listening, and error-safe text result handling.

- [ ] **Step 2: Add analyzer voice button and diary save**

Add a microphone icon in the product-name field and save successful analyses into both history and diary entry storage.

- [ ] **Step 3: Add dashboard tab**

Show today's calories, macro totals, average health score, recent score trend, and cloud sync state.

- [ ] **Step 4: Add account tab**

Provide email/password sign-in and sign-up, show local-only/cloud-enabled state, and expose a manual sync button.

- [ ] **Step 5: Add sync status in history**

Display pending/synced state on history rows when the local row exposes sync metadata.

---

### Task 6: Verification

**Files:**
- All modified app files

- [ ] **Step 1: Run model and service tests**

Run: `flutter test test/models test/services`

Expected: PASS.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: exit code 0. If it times out again, report the timeout and run a narrower check if available.

- [ ] **Step 3: Run Android debug build**

Run: `flutter build apk --debug`

Expected: exit code 0. Neon sync remains in local-only mode until `NEON_API_BASE_URL` points to a deployed API backed by a Neon `DATABASE_URL`.

## Self-Review

- Spec coverage: Account, cloud DB, offline-first local storage, auto/best-effort sync, more storage methods through history and diary tables, richer nutrition analysis, dashboard analysis, and voice input are covered.
- Placeholder scan: No implementation step depends on an undefined future task.
- Type consistency: `FoodEntry`, `HealthResult`, `NutritionAnalyticsService`, `DBService`, `CloudSyncService`, and `VoiceInputService` are named consistently across tasks.
