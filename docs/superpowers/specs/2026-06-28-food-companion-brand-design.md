# 食伴 AI 品牌設計規格

## 目標

將 `foodlens_ai/app` 從 Flutter 預設圖示與工程名稱，更新為可辨識、親切且適合日常使用的飲食分析品牌。品牌調性採「親切生活」，不改動套件識別、Firebase 專案、資料格式或功能流程。

## 品牌名稱

- 正式顯示名稱：`食伴 AI`
- 英文／內部沿用名稱：`FoodLens AI`
- 品牌副標：`懂你每一餐`
- Android launcher、iOS display name、Web manifest 與 Flutter application title 統一顯示 `食伴 AI`。
- App 登入頁與首頁主標題顯示 `食伴 AI`，登入頁副標改為 `懂你每一餐`。

`FoodLens` 已有多個同類飲食辨識產品使用；新顯示名稱以中文區隔，同時保留既有程式套件與後端識別，避免不必要的遷移風險。

## Icon 定案

採用「圓盤鏡頭」方案：

- 主體是一個圓形餐盤，同時可讀成相機鏡頭。
- 右下短柄暗示放大鏡，對應拍照辨識與分析。
- 盤中簡化微笑，傳達友善陪伴，不塑造成醫療診斷工具。
- 右上小亮點代表 AI 協助，但不使用機器人頭、腦部或電路紋理。
- 圖標不放文字、不使用細線、不使用醫療十字、體重秤或寫實食物照片。
- Android adaptive icon 的關鍵圖形位於中央安全區；maskable Web icon 同樣保留安全邊距。

## 色彩

- 深葉綠 `#1F7658`：主背景與品牌識別，延續現有 App 綠色主題。
- 暖杏 `#F3B562`：餐盤／鏡頭內圈，增加日常與食物溫度。
- 米白 `#FFF8E9`：圖形與高光，避免純白過硬。
- 深墨綠 `#174E3E`：需要陰影或小尺寸輪廓時使用。

圖標在亮色與暗色桌布上都應保持清楚；最小 48 px 尺寸仍需辨認出圓盤、短柄和亮點。

## 實裝範圍

- 建立單一 1024×1024 品牌母圖。
- 產生 Android legacy mipmap 尺寸與 adaptive icon foreground/background 資源。
- 更新 iOS `AppIcon.appiconset` 全部既有尺寸。
- 更新 Web favicon、192/512 與 maskable icon。
- 更新 Windows `app_icon.ico`，避免桌面建置仍顯示 Flutter 預設圖示。
- 更新 Android、iOS、Web 與 Flutter 內部顯示名稱。
- 不更改 `applicationId`、bundle identifier、Firebase project id 或 API 路徑。

## 驗證

- 以像素與尺寸檢查確認所有 icon 檔存在、尺寸正確且不是 Flutter 預設圖示。
- `flutter analyze` 與 `flutter test` 必須通過。
- 建置 Android debug APK，確認資源編譯與 manifest label 正確。
- 在 Pixel 9 模擬器安裝並檢查 launcher 圖示、App 標題、登入頁與首頁標題。
- 檢查 Git diff 只包含品牌規格、icon 資源與顯示名稱，不納入另一對話窗留下的 Windows 產生檔變更。

## 非目標

- 不重構功能頁面或導航。
- 不修改雲端服務、驗證、資料庫或 AI 分析行為。
- 不建立新分支、Pull Request 或發布新版 Release；發佈需由使用者另行授權。
