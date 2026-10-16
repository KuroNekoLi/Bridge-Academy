# B5 — 教學式牌局複盤驗收

**日期：2026-10-16；工程狀態：B5.1–B5.4 SCOPED VERIFIED（Flutter／Web／Chrome Demo）。**

## 玩家可操作的交付
- A5 歷史牌局與剛完成的單人牌局，都可在原有 Replay 中查看 B5 教學規則卡與下一個／上一個重點事件。
- 可以利用事件下拉選單直接定位到任一叫牌或出牌事件，保留原有第一／前一／下一／最後一步控制。
- 每一步的規則解釋來自 Bridge Core 驗證後的 filtered PlayerView 和公開 Event，不重新計分，也不擷取私有四手 Deal。狀態與得分未結束前不顯示事後複盤。
- 不將叫牌語義當成實際牌力：B3.2 命中的約定註明未經專家審核，其他一律 UNKNOWN。無 DDS／專家驗證的行動策略品質顯示 NOT ANALYZED。
- 學習重點標記只存在當前複盤 Widget 的生命週期；從歷史列表切換紀錄會重設，不落盤、不涉及明文隱私資料。

## 驗收邊界
- `ReviewTimeline.fromReplay` 接受已完成 `CompletedReplay`，檢查每幀 version/index/authorized viewer 與 terminal phase，不修改原始 action 或 fingerprint。
- Pass Out 四 Pass、Double/Redouble、NT/王牌、明手首攻後公開、由莊家控制明手、跟牌例子、Core 終局計分有 deterministic tests。
- 策略品質 UNKNOWN 不是最佳打法預測；DDS 的 `AnalysisResult` 由未來 C1.5 額外串接，B5 不會預先讀取四手。
- `apps/bridge_academy_flutter/test/b5_teaching_review_test.dart`、原 A5/M2-F11 測試仍需完整回歸；手機真機／模擬器依使用者要求保持暫停。
- Windows/macOS/Android/iOS 原生裝置未實測，不能聲稱正式產品發行驗收。

## 執行證據
- [Flutter Single Player CI #38919162697](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162697) 對應真實程式碼 SHA `7c5d62942a599032ad5610cb4a49d964531d5bfb`：`flutter analyze --no-pub` **No issues found**；`flutter test --no-pub --reporter expanded` **152/152 PASS**；`flutter build web --no-pub --release` **PASS**；**ChromeDriver Demo E2E PASS**。
- [Feature Learning Gate #38919162925](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38919162925) **PASS**。
- 此次僅 Demo/本機已完成歷史牌局；**未執行真 BEN 模型 B5 策略驗收、Android/iOS 實機測試或正式上線驗收**。本地環境無 Dart/Flutter，執行證據來自 GitHub Actions。

## rollback／合併
可 Revert B5 commit；原本 CompletedReplay、HistoryStore、Bridge Core 與 Gateway／BEN API 都沒有變動。常見整合衝突僅 `app_copy.dart`、`bridge_history_panel.dart`、`bridge_replay_panel.dart` 與 `docs/learning/INDEX.md`；C1 不能覆蓋 Replay Widget。
