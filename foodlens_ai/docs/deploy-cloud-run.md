# FoodLens AI 部署到 Google Cloud Run

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
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com secretmanager.googleapis.com

# 在命令列互動輸入值，不要把秘密寫進腳本或 Git
gcloud secrets create foodlens-gemini-api-key --replication-policy=automatic
gcloud secrets versions add foodlens-gemini-api-key --data-file=-
gcloud secrets create foodlens-smtp-pass --replication-policy=automatic
gcloud secrets versions add foodlens-smtp-pass --data-file=-
```

Cloud Run runtime service account 至少需要：

- Secret Manager Secret Accessor（對上述 secrets）
- Storage Object Viewer（對 Firebase Storage bucket）

Cloud Run 上使用 Application Default Credentials，不需要設 `FIREBASE_CLIENT_EMAIL` 或 `FIREBASE_PRIVATE_KEY`。

## 3. 部署

```powershell
cd C:\Users\wuwu6\StudioProjects\App_medium\foodlens_ai\server
gcloud run deploy foodlens-ai-api `
  --source . `
  --region asia-east1 `
  --allow-unauthenticated `
  --set-env-vars NODE_ENV=production,FIREBASE_PROJECT_ID=YOUR_PROJECT_ID,FIREBASE_STORAGE_BUCKET=YOUR_BUCKET,SMTP_HOST=smtp.gmail.com,SMTP_PORT=587,SMTP_SECURE=false,SMTP_USER=YOUR_GMAIL,SMTP_FROM_NAME="FoodLens AI",SMTP_FROM_EMAIL=YOUR_GMAIL `
  --set-secrets GEMINI_API_KEY=foodlens-gemini-api-key:latest,SMTP_PASS=foodlens-smtp-pass:latest
```

`--allow-unauthenticated` 讓 `/health` 與 App 可到達 Cloud Run；`/analyzeFoodImage` 仍必須通過 Firebase ID Token 驗證。正式環境不會註冊 `/sendTestEmail` route。

## 4. 測試 Cloud Run

```powershell
$url = gcloud run services describe foodlens-ai-api --region asia-east1 --format="value(status.url)"
Invoke-RestMethod "$url/health"
```

預期：

```json
{ "ok": true }
```

## 5. Flutter 改用 Cloud Run URL

在 `app/firebase.dev.json` 將 `API_BASE_URL` 改為 Cloud Run HTTPS URL，或執行：

```powershell
flutter run --dart-define-from-file=firebase.dev.json --dart-define=API_BASE_URL=https://YOUR-SERVICE-URL
```

發布 APK/App Bundle 時也要帶入相同的 Firebase 設定與 Cloud Run URL。
