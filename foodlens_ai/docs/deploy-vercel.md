# 食伴 AI 免費雲端 API（Vercel）

## 正式服務

- API base URL：`https://food-companion-api.vercel.app`
- 健康檢查：`https://food-companion-api.vercel.app/health`
- Vercel 專案：`food-companion-api`
- Runtime：Node.js 22 LTS，單一 Express Function，最長執行 60 秒

本專案在 2026-06-28 檢查到 Google Cloud 專案 `foodlens-ai-fd67f` 尚未綁定計費帳戶，無法部署 Cloud Run。Vercel Hobby 可供非商業課程專案免費使用，因此目前以 Vercel Production 提供關機後仍可使用的 AI API。

## 雲端環境變數

Production 必須設定下列變數，值不得提交到 Git：

```text
NODE_ENV=production
GEMINI_API_KEY
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
FIREBASE_STORAGE_BUCKET
```

`GEMINI_API_KEY`、`FIREBASE_CLIENT_EMAIL` 與 `FIREBASE_PRIVATE_KEY` 應標記為 Vercel sensitive environment variables。正式環境不需要 Gmail SMTP；使用者註冊驗證信由 Firebase Authentication 的 `sendEmailVerification()` 寄送。

專用 service account 為 `food-companion-api@foodlens-ai-fd67f.iam.gserviceaccount.com`，只需要：

- Cloud Datastore User：寫入每日 AI 額度交易。
- Storage Object Viewer：支援舊版 Storage 圖片路徑。

## 部署

```powershell
cd foodlens_ai\server
npm ci
npm test
npx vercel --prod --yes
```

Vercel CLI 會使用 `vercel.json` 將所有路徑轉給 `api/index.js`。`src/index.js` 在 Vercel 匯出 Express app，在本機與 Cloud Run 則繼續監聽 `PORT`。

## 驗證

```powershell
Invoke-RestMethod https://food-companion-api.vercel.app/health
```

預期結果：

```json
{ "ok": true }
```

`/analyzeFoodImage` 仍要求 Firebase ID Token。匿名 Firebase 使用者每日 5 次，Email 已驗證使用者每日 50 次；計數由 Firestore transaction 在後端強制執行。

## Flutter 正式建置

Android Emulator 開發仍可使用 `http://10.0.2.2:3000`。正式 APK 或實機測試必須指定：

```powershell
flutter run --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://food-companion-api.vercel.app

flutter build apk --release --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://food-companion-api.vercel.app
```

已安裝的舊 APK 可先到「設定 > API 主機」填入同一網址，不必等待重新安裝。
