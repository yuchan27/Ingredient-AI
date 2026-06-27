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
4. Spark 免費方案不啟用 Firebase Storage；圖片保存在 App 本機目錄，分析時直接上傳後端。
5. 新增 Android App，package name 為 `com.foodlens.foodlens_ai_app`。
6. 從專案設定取得 API key、App ID、Sender ID 與 Project ID。`FIREBASE_STORAGE_BUCKET` 保留給未來 Blaze 方案使用。

部署安全規則：

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai
firebase login
firebase use --add
firebase deploy --only firestore:rules
```

## 3. Flutter 開發設定

複製 `app/firebase.dev.json.example` 為 `app/firebase.dev.json`，填入 Firebase 用戶端設定。該檔案已被 Git 忽略。

Pixel 9 Emulator 連到電腦的 port 3000 必須使用 `http://10.0.2.2:3000`。食品圖片以 multipart `image` 欄位直接傳給 `/analyzeFoodImage`，不需要 Storage。

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

Android 的 Firestore SDK 預設開啟本機持久快取。已讀取紀錄可在斷網時瀏覽，新增/修改/刪除會先寫入本機佇列，重新連線後自動同步。圖片保存在 App 文件目錄，同一裝置可離線顯示；營養、日期、餐別、金額與備註會同步到 Firestore。圖片 AI 分析需要網路；失敗時仍可手動填寫營養資料。

## 7. 實機或 ngrok

```powershell
ngrok http 3000
flutter run --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://YOUR-NGROK-DOMAIN
```

實機不能使用 `10.0.2.2`。請改為 HTTPS ngrok URL 或 Cloud Run URL。
登入後也可在 App 的「設定 > API 主機」直接更新網址，不需要重新安裝 APK。

## 8. Android release 簽章與 APK

正式 APK 不使用 debug key。先在 `app/android/app` 建立本機簽章檔：

```powershell
keytool -genkeypair -v -keystore foodlens-upload-key.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

建立 `app/android/key.properties`，內容如下；密碼請換成自己保存的值：

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=foodlens-upload-key.jks
```

`key.properties` 與 `*.jks` 已被 Git 忽略，兩者都不可提交。請另外安全備份；Play 商店後續更新必須使用相同簽章。

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\app
flutter build apk --release --dart-define-from-file=firebase.dev.json
```

輸出檔案位於 `app/build/app/outputs/flutter-apk/app-release.apk`。正式測試版也可直接從
[GitHub Release v1.0.0](https://github.com/yuchan27/Ingredient-AI/releases/download/v1.0.0/FoodLens-AI-v1.0.0.apk)
下載；安裝後先完成 Email 驗證，再到「設定 > API 主機」填入 Cloud Run 或 ngrok HTTPS URL。
