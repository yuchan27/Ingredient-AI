# 食伴 AI（FoodLens AI）

食伴 AI 是 Flutter 本地優先飲食分析 App，使用 Firebase Authentication、
Cloud Firestore、Vercel Express API 與 Gemini 圖片分析。

## Android APK

最新簽章 APK：[Food-Companion-v1.0.4.apk](https://github.com/yuchan27/Ingredient-AI/releases/download/v1.0.4/Food-Companion-v1.0.4.apk)。
大小 `53,211,862 bytes`，SHA-256
`E8FD6268B627ED79A394AA39935EBDFD19B4D4F9DB52B36D9BCB4B23420D9C99`，
APK Signature Scheme v2 驗證通過。
正式 API 已內建 `https://food-companion-api.vercel.app`，不依賴開發電腦。

## Features

- 分離的登入／建立帳號介面與確認密碼驗證
- Firebase 繁體中文 Email 驗證信、重寄，以及已完成／尚未完成／連線失敗狀態回饋
- Email 只移除前後空白，不加入別名；輸入 `C112151139@nkust.edu.tw` 就提交同一地址
- 條件式 Google 登入（需 Firebase provider、SHA-1 與 Web OAuth client）
- 訪客本機模式每日 5 次、已驗證帳號每日 50 次 AI 分析
- 食品標示辨識、營養趨勢、餐點建議、餐費與離線同步
- Firebase token 驗證、MIME/大小限制與 Vercel 速率限制
- 正式版固定受信任的 Vercel API 位址，API 自訂功能僅在 debug build 開放

## Local Run

啟動本機 API：

```powershell
cd foodlens_ai\server
npm install
npm start
```

啟動 Android App：

```powershell
cd foodlens_ai\app
flutter pub get
flutter run --dart-define-from-file=firebase.dev.json
```

Android Emulator 可使用 `http://10.0.2.2:3000`。正式裝置使用
`https://food-companion-api.vercel.app`。Firebase 驗證信由 Google 雲端寄出，
不使用本機 API 或 Gmail SMTP。

## Verification

```powershell
cd foodlens_ai\server
npm test
npm run check

cd ..\app
flutter analyze
flutter test --no-pub
```

詳見 [setup.md](docs/setup.md) 與 [deploy-vercel.md](docs/deploy-vercel.md)。
