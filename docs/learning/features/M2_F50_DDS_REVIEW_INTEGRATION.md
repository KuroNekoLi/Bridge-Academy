# M2-F50｜C1.5 DDS 與 B5 複盤：資料信任邊界

- Feature ID：M2-F50

- 功能：在 B5 終局複盤新增玩家主動觸發 DDS3 的 5×4 分析表。
- 學習狀態：DELIVERED；驗收：Flutter 161/161 + Web + Chrome Demo PASS；真 DDS Worker NOT RUN。
- 核心檔案：`lib/src/bridge_session.dart`、`widgets/dds_review_section.dart`、`packages/bridge_dds_adapter/lib/src/double_dummy_analysis.dart`

## 功能目的與實際情境
玩家可在已完成牌局與歷史紀錄中，主動查看 DDS 雙明手墩數；未設定原生 Worker 的 Web 環境不顯示偽造結果。

## 主要程式碼導讀
`BridgeSession.analyzeCompletedDds()` 在 Core 完成牌局後，才從私有 `snapshotForTrustedStorage()` 取得可信 transcript，呼叫 `TrustedCompletedBoard.fromTrustedTranscript()`。`DdsReviewSection` 的按鈕透過 Future callback 取得 `DoubleDummyTable`，只顯示解牌後的 20 個整數與 solver 版本。

## 為什麼這樣設計
這和 Android Clean Architecture 的 Domain→Application→UI 邊界一致。錯誤作法是把原始 52 張牌傳進 Widget、Web API 或讓未完成的牌局呼叫 DDS，導致遊戲變相作弊。雙明手分析知道所有人的牌，只能做**事後全知分析**，不代表資訊受限的真人當下必須找得到同一張牌。

## CI 修正紀錄
Flutter 3.47.7 的 analyze 會因為單行 if 缺少大括號而回傳 info 並阻擋 pipeline；UI 的例外分支改為完整 block，避免風格與失敗處理在未來維護時出錯。

## 驗證與實際證據
`flutter test test/c1_5_dds_review_test.dart`、`flutter analyze`、`flutter build web` 都需跑。本地環境無 SDK，但 [GitHub Actions #38984253536](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38984253536) 執行了 161/161 tests、Analyze、Web Build 與 Chrome Demo E2E，皆 PASS；原生 DDS Worker 的真引擎端對端尚未執行，不可稱為已驗收。真正 DDS Worker 安裝與授權依 C1 審查文件。

## 練習與自我檢驗

**思考題：**
在 Web 環境沒有 native DDS worker 時，為什麼應顯示 unavailable，而不是顯示預存的模擬 20 格墩數？
