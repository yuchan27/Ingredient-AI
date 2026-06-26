# AI 食品成分與營養分析 App

Flutter 期末專案：使用 Gemini 分析食品名稱或照片，產生健康分數、營養素、成分風險與飲食建議。專案已加入本地 SQLite 離線儲存、飲食日記、營養 Dashboard、語音輸入，以及 Neon Postgres 雲端同步架構。

## 功能

- AI 食品分析：輸入食品名稱或拍照，取得健康評分與營養分析。
- 營養紀錄：自動把分析結果保存為飲食日記。
- Dashboard：統計今日熱量、蛋白質、碳水、脂肪、糖、鈉、纖維與平均分數。
- 掃描歷史：保存每次 AI 分析結果，並顯示待同步/已同步狀態。
- 語音輸入：可用麥克風輸入產品名稱。
- 離線可用：沒有網路時資料仍會寫入本地 SQLite。
- Neon 雲端同步：透過 `server/` Node API 連接 Neon Postgres，避免在 App 中暴露資料庫密碼。

## Flutter App 執行

1. 建立 `.env`：

```text
GEMINI_API_KEY=your_gemini_api_key
NEON_API_BASE_URL=http://10.0.2.2:8787
```

`NEON_API_BASE_URL` 未設定時，App 會自動進入本地模式。

2. 安裝套件並執行：

```powershell
flutter pub get
flutter run
```

3. 建置 APK：

```powershell
flutter build apk --debug
flutter build apk --release
```

## Neon Postgres API

Flutter App 不直接連 Postgres；雲端同步走 `server/`：

```powershell
npm install --prefix server
```

複製 `server/.env.example` 成 `server/.env`：

```text
DATABASE_URL=postgresql://USER:PASSWORD@HOST.neon.tech/DB?sslmode=require
JWT_SECRET=replace-with-a-long-random-secret
PORT=8787
```

先在 Neon SQL Editor 執行：

```text
neon/schema.sql
```

啟動 API：

```powershell
npm --prefix server run dev
```

Android 模擬器連本機 API 時，`NEON_API_BASE_URL` 使用：

```text
http://10.0.2.2:8787
```

## 驗證命令

```powershell
flutter test test/models test/services
flutter analyze
node --check server/src/index.js
flutter build apk --release
```

## 期末報告與素材

- Word 報告：`C11215139_medium_Flutter_final_report.docx`
- App 截圖：`artifacts/screenshots/`
- 操作影片：`artifacts/videos/ingredient_ai_demo.mp4`
