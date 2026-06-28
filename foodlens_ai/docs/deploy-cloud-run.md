# 食伴 AI 部署到 Google Cloud Run

> Cloud Run 必須連結 Google Cloud 計費帳戶，即使使用免費額度也一樣。本機 Android Emulator 開發不需要啟用計費。

正式 App 需要一個公開 HTTPS API，才可在開發電腦關機後繼續使用 AI 分析。Firebase 驗證信由 Firebase Authentication 寄送，不經過這個 Express server，也不依賴開發電腦或 Cloud Run SMTP 設定。

## 0. 部署前唯讀檢查

先安裝並登入 Google Cloud CLI，再確認目前專案與計費狀態；下列命令不會啟用 API 或建立資源：

```powershell
gcloud auth login
gcloud config set project foodlens-ai-fd67f
gcloud billing projects describe foodlens-ai-fd67f --format="value(billingEnabled)"
gcloud services list --enabled --filter="name:(run.googleapis.com OR cloudbuild.googleapis.com OR secretmanager.googleapis.com)" --format="value(name)"
gcloud run services describe foodlens-ai-api --region asia-east1 --format="value(status.url)"
```

- `billingEnabled` 必須是 `True`，否則 Cloud Run 部署會被 Google Cloud 計費前置條件阻擋。
- 若服務尚未存在，最後一個命令會回報找不到資源；這代表尚未部署，不代表 App 可使用雲端 API。
- 保存實際命令、exit code 與 Google 回傳錯誤即可作為阻塞證據；不要把憑證、access token 或 API key 寫入紀錄。

## 1. Dockerfile

`server/Dockerfile` 使用 Node 22 Alpine、`npm ci --omit=dev`、非 root `node` 使用者，並由 Cloud Run 的 `PORT` 環境變數決定監聽 port。

本機建置與測試：

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\server
docker build -t foodlens-ai-api .
docker run --rm -p 3000:8080 --env-file .env -e PORT=8080 foodlens-ai-api
```

## 2. 建立 Secret Manager secrets

```powershell
gcloud config set project foodlens-ai-fd67f
gcloud services enable run.googleapis.com cloudbuild.googleapis.com secretmanager.googleapis.com

# 在命令列互動輸入值，不要把秘密寫進腳本或 Git
gcloud secrets create foodlens-gemini-api-key --replication-policy=automatic
gcloud secrets versions add foodlens-gemini-api-key --data-file=-
```

Cloud Run runtime service account 至少需要：

- Secret Manager Secret Accessor（只對 Gemini secret）
- Cloud Datastore User（讀寫 Firestore 的 `ai_usage` 額度計數）
- 免費 Spark 版本使用 multipart 直接分析圖片，不需要 Storage Object Viewer。

Cloud Run 上使用 Application Default Credentials，不需要設 `FIREBASE_CLIENT_EMAIL` 或 `FIREBASE_PRIVATE_KEY`。

## 3. 部署

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\server
gcloud run deploy foodlens-ai-api `
  --source . `
  --project foodlens-ai-fd67f `
  --region asia-east1 `
  --allow-unauthenticated `
  --min 0 `
  --set-env-vars NODE_ENV=production,FIREBASE_PROJECT_ID=foodlens-ai-fd67f `
  --set-secrets GEMINI_API_KEY=foodlens-gemini-api-key:latest
```

`--allow-unauthenticated` 只讓網路可到達服務；`/analyzeFoodImage` 仍必須通過 Firebase ID Token 驗證。`--min 0` 允許沒有流量時縮到零個 instance。正式環境不會註冊 `/sendTestEmail` route，也不需要 SMTP secret。

## 4. 測試 Cloud Run

```powershell
$url = gcloud run services describe foodlens-ai-api --project foodlens-ai-fd67f --region asia-east1 --format="value(status.url)"
Invoke-RestMethod "$url/health"
```

預期：

```json
{ "ok": true }
```

## 5. Flutter 改用 Cloud Run URL

建立被 Git 忽略的 `app/firebase.release.json`，完整欄位如下：

```json
{
  "FIREBASE_API_KEY": "YOUR_FIREBASE_WEB_API_KEY",
  "FIREBASE_APP_ID": "YOUR_ANDROID_APP_ID",
  "FIREBASE_MESSAGING_SENDER_ID": "YOUR_SENDER_ID",
  "FIREBASE_PROJECT_ID": "foodlens-ai-fd67f",
  "FIREBASE_STORAGE_BUCKET": "",
  "API_BASE_URL": "https://YOUR-SERVICE-URL"
}
```

正式建置必須同時載入 Firebase 設定與 Cloud Run HTTPS URL，且不要設定 `DEMO_MODE=true`：

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\app
flutter build apk --release --dart-define-from-file=firebase.release.json
```

也可逐一傳入以下 dart-defines：`FIREBASE_API_KEY`、`FIREBASE_APP_ID`、`FIREBASE_MESSAGING_SENDER_ID`、`FIREBASE_PROJECT_ID`、選用的 `FIREBASE_STORAGE_BUCKET`，以及必要的 `API_BASE_URL=https://...run.app`。

登入後仍可在「設定 > API 主機」覆寫 URL 供診斷，但正式 APK 應在建置時就帶入 Cloud Run URL，不能把 `10.0.2.2` 當作正式預設值。

完成後必須關閉本機 Node server，再從另一個網路重新驗證 `$url/health` 與一筆帶 Firebase ID token 的圖片分析；成功回應應含 `quota.limit`、`quota.used`、`quota.remaining`。
