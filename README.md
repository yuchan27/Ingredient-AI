# 食伴 AI（FoodLens AI）

食伴 AI 是以 Flutter、Firebase Authentication、Cloud Firestore、Vercel 與
Gemini 建立的本地優先飲食分析 Android App。正式 AI API 部署於
[`https://food-companion-api.vercel.app`](https://food-companion-api.vercel.app)，
開發電腦關機後仍可使用。

## 帳號與 Email 驗證

- 登入與建立帳號使用不同標題、說明與操作狀態，避免使用者混淆。
- 建立帳號要求再次輸入確認密碼；兩次密碼不同時不會送出註冊。
- 註冊後由 Firebase Authentication 雲端直接寄出驗證信，不經本機 Node、SMTP 或 Vercel API。
- 註冊與重寄前固定設定 Firebase 語系為 `zh-TW`，使用繁體中文驗證信。
- App 只會移除 Email 前後空白，不會加入 `+foodlenscloud...` 或改寫地址；例如輸入
  `C112151139@nkust.edu.tw` 就會把同一個完整地址交給 Firebase。
- 寄信前會強制更新 Firebase ID token；token 無效時不會顯示成功訊息。
- 點選「我已完成驗證」時，App 會向 Firebase 重新載入帳號並讀取最新
  `emailVerified`；畫面會明確顯示「已完成」、「尚未完成，請稍候並檢查垃圾郵件」
  或連線失敗，不再把單純更新狀態誤報為驗證成功。
- Google 登入程式已整合；只有在 Firebase 啟用 `google.com` provider 並於建置設定
  `GOOGLE_SERVER_CLIENT_ID` 時才顯示按鈕，避免未設定完成卻提供必定失敗的入口。

## 主要功能

- 訪客本機模式：飲食資料只留在裝置，每日 5 次 AI 圖片分析。
- 已驗證帳號：Firestore 雲端同步與離線快取，每日 50 次 AI 圖片分析。
- 食品標示辨識、熱量與三大營養素、成分重點及可編輯結果。
- 今日總覽、七日趨勢、下一餐建議、餐費、備註與意見回饋。
- Vercel 後端驗證 Firebase token 並強制執行每日額度。
- 正式 APK 固定使用受信任的 Vercel API；只有 debug build 可修改 API 位址，避免
  Firebase Token 被送往不受信任的主機。

## 下載 APK

下載 [食伴 AI v1.0.4 APK](https://github.com/yuchan27/Ingredient-AI/releases/download/v1.0.4/Food-Companion-v1.0.4.apk)。
本次版本為 `versionName 1.0.4`／`versionCode 5`，檔案大小 `53,211,862 bytes`，
SHA-256：`E8FD6268B627ED79A394AA39935EBDFD19B4D4F9DB52B36D9BCB4B23420D9C99`。
APK Signature Scheme v2 驗證通過，package 為 `com.foodlens.foodlens_ai_app`。
既有 Release 檔案與 SHA-256 保持不變。

## 專案結構

- `foodlens_ai/app`：Flutter Android App
- `foodlens_ai/server`：Express/Vercel API、Firebase token 驗證與 Gemini 圖片分析
- `foodlens_ai/firestore.rules`：Firestore 使用者資料隔離規則
- `foodlens_ai/docs`：Firebase、Vercel 與 release 設定

## 開發與測試

```powershell
cd foodlens_ai\server
npm ci
npm test
npm run check

cd ..\app
flutter pub get
flutter analyze
flutter test --no-pub
flutter run --dart-define-from-file=firebase.dev.json
```

正式或實機建置必須設定 `API_BASE_URL=https://food-companion-api.vercel.app`。
若要啟用 Google 登入，另需在 Firebase Console 啟用 Google provider、加入 release
SHA-1，建立 Web OAuth client，並在 JSON 建置設定加入
`"GOOGLE_SERVER_CLIENT_ID": "...apps.googleusercontent.com"`。完整說明見
[`foodlens_ai/docs/setup.md`](foodlens_ai/docs/setup.md)。
