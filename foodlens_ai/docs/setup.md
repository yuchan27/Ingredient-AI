# FoodLens AI 本機開發設定

## 1. 必要工具

- Flutter 3.35 以上與 Android Studio
- Node.js 22 以上
- Firebase CLI：`npm install -g firebase-tools`
- Pixel 9 Android Emulator

## 2. Firebase 專案

1. 在 Firebase Console 建立專案。
2. Authentication > Sign-in method 啟用 **Email/Password**。
3. 建立 Cloud Firestore，正式環境不要選測試模式。
4. 建立 Firebase Storage。
5. 新增 Android App，package name 為 `com.foodlens.foodlens_ai_app`。
6. 從專案設定取得 API key、App ID、Sender ID、Project ID 與 Storage bucket。

部署安全規則：

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai
firebase login
firebase use --add
firebase deploy --only firestore:rules,storage
```

## 3. Flutter 開發設定

複製 `app/firebase.dev.json.example` 為 `app/firebase.dev.json`，填入 Firebase 用戶端設定。該檔案已被 Git 忽略。

Pixel 9 Emulator 連到電腦的 port 3000 必須使用 `http://10.0.2.2:3000`。

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\app
flutter pub get
flutter run --dart-define-from-file=firebase.dev.json
```

若尚未建立 Firebase，可先執行可操作展示模式：

```powershell
flutter run --dart-define=DEMO_MODE=true
```

DEMO 只用於介面與報告展示，不代表雲端同步成功。

## 4. Server 本機執行

`server/.env` 應包含 `.env.example` 列出的鍵。不要將 `.env`、Gmail 應用程式密碼、Gemini key 或 Firebase private key 提交到 Git。

本機可用 Firebase service account 環境變數；若已使用 `gcloud auth application-default login`，可留空 client email/private key。

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\server
npm install
npm test
npm start
```

另開 PowerShell 測試：

```powershell
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod -Method Post http://localhost:3000/sendTestEmail -ContentType application/json -Body '{}'
```

`/sendTestEmail` 只在 `NODE_ENV=development` 存在，而且只會寄到 `SMTP_USER`，不接受外部指定收件人。

## 5. 註冊與 Email 驗證

App 的註冊使用 Firebase Authentication。建立帳號後會呼叫 `sendEmailVerification()`，未驗證前不會進入食品資料頁。Gmail SMTP 只是後端開發測試，不儲存 App 使用者密碼。

## 6. 離線與自動同步

Android 的 Firestore SDK 預設開啟本機持久快取。已讀取紀錄可在斷網時瀏覽，新增/修改/刪除會先寫入本機佇列，重新連線後自動同步。圖片 AI 分析需要網路；失敗時仍可手動填寫營養資料。

## 7. 實機或 ngrok

```powershell
ngrok http 3000
flutter run --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://YOUR-NGROK-DOMAIN
```

實機不能使用 `10.0.2.2`。請改為 HTTPS ngrok URL 或 Cloud Run URL。
