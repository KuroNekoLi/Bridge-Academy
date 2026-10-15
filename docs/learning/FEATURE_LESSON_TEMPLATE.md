# Feature Lesson Template — 複製後填寫真實內容

文件位置：docs/learning/features/Mx_Fxx_TOPIC.md。不要保留「待填」的 placeholder；尚未實作的內容要明確標註 PROPOSED，不得冒稱通過。

# Mx-Fxx｜功能名稱

- Feature ID：Mx-Fxx
- Milestone：Mx
- 類型：規則／AI 整合／Flutter UI／後端／其他
- 工程狀態：IMPLEMENTED / VERIFIED / BLOCKED
- 學習狀態：DELIVERED（預設）；PRACTICED / MASTERED 需有使用者學習證據
- 原始碼：GitHub 檔案路徑（盡可能含版本）
- 驗收與測試：測試檔案、CI URL、版本或 NOT RUN

## 功能目的與實際情境
先描繪玩家或系統遇到的具體情境。清楚區分預期行為和實際驗收結果。

## 主要程式碼導讀
指出真正的入口、重要類別／函式、資料流（輸入 → 驗證 → 狀態改變 → 輸出）。挑 5–20 行最有教學價值的實際程式碼，解釋關鍵判斷及錯誤處理。若尚未實作，請標示為設計範例。

## 為什麼這樣設計
說明一個設計原則、一個合理替代方案及取捨、一個常見錯誤或邊界情境。使用者為 Android/Kotlin 工程師，可在有幫助時比較 Kotlin、Compose、Flow、Clean Architecture。

## 驗證與實際證據
提供可重現的測試命令、具體測試斷言、實際執行版本、CI URL/Commit 和已知未覆蓋情況。不可把假資料／Mock 與 BEN 真實模型回應混為一談；沒跑要寫 NOT RUN。

## 練習與自我檢驗
**思考題（1 題）：** 將重要原理應用到稍微改變的情境。

**5–15 分鐘小練習（可選）：** 指出可修改的小測試或讀碼任務。

**完成標準：** 明確說明答題時應能指出什麼；使用者答題後才更新學習進度。不要一開始將教學視為已掌握。

## 下一步
下一個功能需要的相關觀念或銜接知識；不必擴展成毫無關聯的課程。
