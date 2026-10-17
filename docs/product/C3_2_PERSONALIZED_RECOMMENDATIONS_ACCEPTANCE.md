# C3.2 — 本機個人化學習推薦

**State:** SCOPED VERIFIED (Flutter/Web Demo)

## 可操作玩家功能
- C3 明確同意後，B4 課程列表顯示可點擊的推薦卡片，可直接跳進既有課程的建議題目。
- 依本機 skillTag 對應原創課程；至少 3 次作答且正確率低於 70% 優先；其次為近 14 天仍未改正的錯題、未開始、未完成及複習。顯示雙語原因與正確／總作答。
- 預設 opt-out 不使用紀錄；停用保存但仍保留歷史時清楚揭露使用舊紀錄；刪除後不再顯示。無額外網路、AI 模型或持久儲存。

## 統計可信度與隱私
- 紀錄的 lessonId/questionId/schemaVersion/skillTag/選項 ID／實際正誤皆需符合最新 B4 題庫，否則忽略；不能以舊題的錯誤推導新題弱點。
- 14 天判斷使用可注入 UTC 時鐘，僅最後仍錯才顯示未改正；相同時間戳用唯一 ID tie-break。
- 不包含橋牌 live Deal、對手手牌、分析結果或其它敏感資料；原 C3 已加密資料不改 schema。

## 驗收命令與未完成限制
`cd apps/bridge_academy_flutter && flutter analyze && flutter test && flutter build web --release`

**實際執行證據：** [Flutter CI #38980805539](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38980805539)，程式碼 SHA `988b1028`，靜態分析無問題、**165/165 測試通過**、Web Release 編譯與 ChromeDriver Demo E2E 均成功。[Learning Gate #38980805532](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38980805532) PASS。最終提交僅更新驗收文件並移除分支暫時性的 CI trigger，未改動已通過測試的程式碼。
使用現有三堂九題，純規則推薦不是專家或 BEN AI 評估；不涉及正式上線、帳號同步、Android/iOS 裝置測試。需要時可以單一 Git commit revert 回退，不需搬遷 C3 存檔。
