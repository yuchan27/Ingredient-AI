# FoodLens AI

FoodLens AI is a local-first Flutter nutrition analysis app with Firebase
Authentication, Cloud Firestore synchronization, an Express API, and Gemini
image analysis with Gemma fallback.

## Android APK

Download the signed `v1.0.0` APK from the
[GitHub Release](https://github.com/yuchan27/Ingredient-AI/releases/download/v1.0.0/FoodLens-AI-v1.0.0.apk).
After signing in on a physical phone, set the deployed HTTPS API URL under
`Settings > API host` before using image analysis.

## Features

- Email/password registration, verification, login, and logout
- Food-label image analysis with editable calories and macronutrients
- Local private image storage with offline Firestore record access
- Daily calories, nutrition trends, meal suggestions, cost tracking, and notes
- Record create, edit, delete, voice input, and feedback submission
- Token-authenticated API with MIME validation, size limits, and rate limiting

## Local Run

Start the API:

```powershell
cd foodlens_ai\server
npm install
npm start
```

Run the Android app on an Emulator:

```powershell
cd foodlens_ai\app
flutter pub get
flutter run --dart-define-from-file=firebase.dev.json
```

The Android Emulator connects to the local API through
`http://10.0.2.2:3000`. Physical devices must use an HTTPS Cloud Run or ngrok
URL through `API_BASE_URL`.

## Verification

```powershell
cd foodlens_ai\server
npm test
npm run check

cd ..\app
flutter analyze
flutter test --no-pub
```

See [setup.md](docs/setup.md) for Firebase and release-signing setup, and
[deploy-cloud-run.md](docs/deploy-cloud-run.md) for deployment details.
