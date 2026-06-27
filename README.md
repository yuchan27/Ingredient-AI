# FoodLens AI

FoodLens AI 是以 Flutter、Firebase Authentication、Cloud Firestore、Node.js
與 Gemini 建立的本地優先飲食分析 App。

最新程式碼位於 [`foodlens_ai/`](foodlens_ai/)：

- `foodlens_ai/app`：Flutter Android App
- `foodlens_ai/server`：Express API、Firebase Token 驗證與 Gemini 圖片分析
- `foodlens_ai/firestore.rules`：Firestore 使用者資料隔離規則
- `foodlens_ai/storage.rules`：Firebase Storage 使用者路徑規則
- `foodlens_ai/docs`：本機設定與 Cloud Run 部署說明

## 主要功能

- Email/Password 註冊、驗證信、登入與登出
- 食品標示圖片分析，結果可手動修改
- 熱量、蛋白質、脂肪、碳水、餐別、日期、備註與餐費紀錄
- 今日總覽、七日分析與下一餐建議
- Firestore 離線快取，恢復連線後自動同步
- 實機可在 App 設定中切換 Cloud Run 或 ngrok API URL

## 下載 APK

請到 [GitHub Releases](https://github.com/yuchan27/Ingredient-AI/releases)
下載最新簽章 APK。

## 開發與測試

```powershell
cd foodlens_ai\server
npm install
npm test
npm start

cd ..\app
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=firebase.dev.json
```

Android Emulator 會使用 `http://10.0.2.2:3000` 連到本機 API。完整設定請參考
[`foodlens_ai/docs/setup.md`](foodlens_ai/docs/setup.md)。
