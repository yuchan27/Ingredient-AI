# AI 飲食分析 App

這是一個 Flutter 製作的 AI 飲食分析 App。使用者可以輸入食物名稱、拍攝餐點、上傳營養標示照片，讓 Gemini 分析熱量、營養成分、風險成分與建議。App 採本地優先設計，沒有網路時會先存入 SQLite；登入帳號且連上 Neon API 後，可將分析紀錄與飲食紀錄同步到 Neon Postgres。

## 主要功能

- AI 圖片/文字飲食分析：支援餐點照片與包裝營養標示。
- 飲食紀錄：保存餐別、日期、熱量、蛋白質、碳水、脂肪、糖、鈉、纖維。
- 記帳功能：每筆飲食紀錄可記錄餐費，總覽會顯示每日花費。
- 今日總分析：顯示每日熱量進度、剩餘熱量、營養素總量與近 7 日趨勢。
- 飲食規劃系統：依今日熱量、鈉、纖維與蛋白質狀態，產生下一餐建議。
- 語音輸入：可用語音輸入食物名稱。
- 帳號與同步：Node API 連接 Neon Postgres，提供註冊、登入與資料同步。

## Flutter App 設定

在專案根目錄建立 `.env`：

```text
GEMINI_API_KEY=your_gemini_api_key
NEON_API_BASE_URL=http://10.0.2.2:8787
```

`NEON_API_BASE_URL` 可不填；不填時 App 會以本地模式運作。Android emulator 要連到電腦本機 API 時，請使用 `http://10.0.2.2:<PORT>`。

執行：

```powershell
flutter pub get
flutter run
```

建立 APK：

```powershell
flutter build apk --debug
flutter build apk --release
```

## Neon Postgres API

API 位於 `server/`，用來避免 Flutter App 直接暴露 Neon connection string。

```powershell
npm install --prefix server
```

建立 `server/.env`：

```text
DATABASE_URL=postgresql://USER:PASSWORD@HOST.neon.tech/DB?sslmode=require
JWT_SECRET=replace-with-a-long-random-secret
PORT=8787
```

在 Neon SQL Editor 或 CLI 套用：

```text
neon/schema.sql
```

啟動 API：

```powershell
npm --prefix server run dev
```

本專案實測 Neon project ID：`falling-brook-09062115`。

## 驗證命令

```powershell
flutter test test/models test/services
flutter analyze
node --check server/src/index.js
flutter build apk --release
```

## 繳交素材

- Word 報告：`C11215139_medium_Flutter_final_report.docx`
- App 截圖：`artifacts/screenshots/`
- 示範影片：`artifacts/videos/ingredient_ai_demo.mp4`
