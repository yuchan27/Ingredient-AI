# 食伴 AI 本機開發設定

## 1. 必要工具

- Flutter 3.35 以上與 Android Studio
- Node.js 22 以上
- Firebase CLI：`npm install -g firebase-tools`
- Pixel 9 Android Emulator

## 2. Firebase 專案

1. 在 Firebase Console 建立專案。
2. Authentication > Sign-in method 同時啟用 **Email/Password** 與 **Anonymous**。匿名驗證只提供後端可信 token，不會把本機飲食紀錄同步到雲端。
3. 若要啟用 Google 登入，另啟用 **Google** provider，並在 Android App 設定加入 release SHA-1。建立 Web OAuth client 後，保存其 `...apps.googleusercontent.com` client ID。
4. 建立 Cloud Firestore，正式環境不要選測試模式。
5. Spark 免費方案不啟用 Firebase Storage；圖片保存在 App 本機目錄，分析時直接上傳後端。
6. 新增 Android App，package name 為 `com.foodlens.foodlens_ai_app`。
7. 從專案設定取得 API key、App ID、Sender ID 與 Project ID。`FIREBASE_STORAGE_BUCKET` 保留給未來 Blaze 方案使用。

部署安全規則：

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai
firebase login
firebase use --add
firebase deploy --only firestore:rules
```

## 3. Flutter 開發設定

複製 `app/firebase.dev.json.example` 為 `app/firebase.dev.json`，填入 Firebase 用戶端設定。該檔案已被 Git 忽略。

`GOOGLE_SERVER_CLIENT_ID` 是選用欄位。只有 provider、release SHA-1 與 Web OAuth client 都完成後才填入；未設定時 App 不顯示 Google 登入按鈕，避免使用者點到無法完成的流程。

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

App 的註冊使用 Firebase Authentication。建立帳號後會呼叫 `sendEmailVerification()`，未驗證前不會進入食品資料頁。註冊、重寄與更新驗證狀態都有 loading、成功與失敗回饋；重寄成功後會短暫冷卻，避免重複點擊。Firebase Authentication 在 Google 雲端寄送驗證信，開發電腦與本機 Node server 關機後仍可寄送。Gmail SMTP 只供後端開發測試，不參與 App 帳號驗證，也不儲存 App 使用者密碼。

寄送前 App 會呼叫 `FirebaseAuth.instance.setLanguageCode('zh-TW')`，讓 Firebase 使用繁體中文驗證信。若要進一步自訂文字，請在 Firebase Console 的 Authentication → Templates → Email address verification 編輯範本。建議內容：

- 寄件者名稱：`食伴 AI`
- 主旨：`請驗證你的食伴 AI Email`
- 內文：`您好，歡迎使用食伴 AI。請點選 %LINK% 完成 Email 驗證。如果不是你建立此帳號，請忽略這封信。`

信件被分類為垃圾郵件通常是寄件網域信譽或郵件驗證設定造成，並非 App 本機寄信失敗。正式環境應在 Firebase Email Templates 使用已驗證的自訂網域，並依 Firebase 提供的 DNS 資料設定 SPF／CNAME；只有修改內文無法保證通過每一個收件系統的垃圾郵件判斷。

登入頁的「先用本機模式」會執行 Firebase 匿名登入以取得 API token，但飲食紀錄只存放在該裝置的 `LocalFoodRepository`，不寫入 Firestore 且不跨裝置同步。匿名使用者每日可做 5 次 AI 圖片分析；已完成 Email 驗證的帳號每日 50 次，兩者都由後端依 UTC 日期強制執行。

驗證信由 Firebase 雲端寄送，與開發電腦或 Node server 是否開機無關。正式環境不公開 `/sendTestEmail`。

## 6. 離線與自動同步

已驗證帳號使用 Firestore 持久快取。已讀取紀錄可在斷網時瀏覽，新增/修改/刪除會先寫入本機佇列，重新連線後自動同步。匿名本機模式不使用 Firestore，紀錄只保存在該裝置。圖片保存在 App 文件目錄，同一裝置可離線顯示；已驗證帳號的營養、日期、餐別、金額與備註會同步到 Firestore。圖片 AI 分析需要網路；失敗時仍可手動填寫營養資料，Gemini 失敗不會消耗每日額度。

## 7. 實機或 ngrok

```powershell
ngrok http 3000
flutter run --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://YOUR-NGROK-DOMAIN
```

實機不能使用 `10.0.2.2`。目前正式免費 API 為 `https://food-companion-api.vercel.app`；也可使用 ngrok 或未來的 Cloud Run URL。
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
flutter build apk --release --dart-define-from-file=firebase.release.json
```

`firebase.release.json` 必須包含 `FIREBASE_API_KEY`、`FIREBASE_APP_ID`、`FIREBASE_MESSAGING_SENDER_ID`、`FIREBASE_PROJECT_ID`、選用的 `FIREBASE_STORAGE_BUCKET`，以及 `API_BASE_URL=https://food-companion-api.vercel.app`；Google 登入設定完成後再加入 `GOOGLE_SERVER_CLIENT_ID`。不要設定 `DEMO_MODE=true`。目前正式部署與驗證步驟見 `docs/deploy-vercel.md`，Cloud Run 則保留作未來替代方案。

輸出檔案位於 `app/build/app/outputs/flutter-apk/app-release.apk`。正式測試版也可直接從
[GitHub Releases](https://github.com/yuchan27/Ingredient-AI/releases)
下載；安裝後先完成 Email 驗證。正式建置應已內含 Vercel HTTPS URL；「設定 > API 主機」只作診斷覆寫。
