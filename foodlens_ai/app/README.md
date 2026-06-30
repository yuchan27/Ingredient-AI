# 食伴 AI Flutter App

這是食伴 AI 的正式 Flutter Android 用戶端。正式版使用 Firebase Authentication、
Cloud Firestore 與 `https://food-companion-api.vercel.app`，不需要開發電腦或本機伺服器開機。

## Email 驗證流程

註冊時只會對輸入地址執行 `trim()`，不會加入 `+foodlenscloud...` 等別名。Firebase
Authentication 建立帳號後由 Google 雲端寄送驗證信。點選「我已完成驗證」會重新載入
Firebase 使用者並檢查 `emailVerified`，畫面分別顯示已完成、尚未完成／請稍候，或連線失敗。

## 正式建置

```powershell
flutter build apk --release --dart-define-from-file=firebase.release.json
```

`firebase.release.json` 與簽章設定只存在本機且已被 Git 忽略。正式版 API 位址不可由使用者
變更；開發 debug build 才能設定本機測試 API。

## 驗證

```powershell
flutter analyze --no-pub
flutter test --no-pub
```
