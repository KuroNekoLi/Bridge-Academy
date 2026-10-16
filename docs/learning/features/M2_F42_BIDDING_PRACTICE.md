# M2-F42｜只練叫牌、約定與 AI 資訊邊界

- Feature ID：M2-F42
- Milestone：M2／B3.1
- 類型：Flutter UI／AI 整合
- 工程狀態：SCOPED VERIFIED（Flutter analyze／118 測試／Web Release／Chrome Demo）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/bidding_practice.dart`、`bridge_session.dart`、`bridge_app.dart`、`packages/bridge_core/lib/src/single_player_coordinator.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b3_bidding_practice_test.dart`；[CI 118/118 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38905811936)

## 功能目的與實際情境
玩家想練與 AI 搭檔叫牌，卻不想為每一副牌再打 13 墩。B3.1 可以建立新的叫牌練習，只進行叫牌，結束後提供已知教學約定的解釋。練習不應記入虛假的終局成績。

## 主要程式碼導讀
`BridgeSession.startBiddingPractice` 建立獨立 `BoardMode.bidding` 並寫入既有 Snapshot。叫牌透過 `submitCall` 執行 Bridge Core 的原有規則；`BiddingPracticeBot` 只能從 `PlayerView` 取自身 13 張牌與公開資訊提出建議。

```dart
if (!view.canAct || view.phase != Phase.auction) {
  throw const RuleViolation('Bidding practice is auction-only');
}
return CallAction(view.viewer, BiddingPracticeProfile.suggest(view));
```

`SinglePlayerCoordinator.runBots(stopAfterAuction: true)` 是唯一新增的 Core 功能旗標；保留一般牌局預設行為，練習則停止於 Phase.play，不進行任何首攻。

`BiddingPracticeProfile.explain` 依公開叫牌歷史判斷受支援的 1NT／2NT／3NT 路徑，其他回傳 `biddingUnknown`。這只是在說明約定條件，絕不是對對手暗手或 AI 內部決策的證明。

## 為什麼這樣設計
可對照 Android/Kotlin 的 Clean Architecture：Bridge Core 是 Domain、BridgeSession 是 Application State Holder、Flutter Widget 是 UI。直接新建另一個叫牌引擎會複製合法性檢查與事件語義，增加不一致風險。

常見陷阱是把約定推測當成真實手牌（例如看見 1NT 就認為 AI *一定* 有 15–17 點），或讓 AI 在叫牌訓練後自動出牌。此示範 Bot 未經專家審查，不能把教學模式說成 BEN 真實模型。

## 驗證與實際證據
```bash
cd apps/bridge_academy_flutter
flutter test test/b3_bidding_practice_test.dart
flutter analyze
```

**EXECUTED on GitHub Actions**：程式碼 Commit `76232aa8`，Flutter analyze 無問題，118/118 Widget／Session tests 通過，Web release build 與 ChromeDriver Demo E2E 皆成功；[CI 證據](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38905811936)。包含 HCP、未知競叫、停止出牌、保存恢復、雙語；未涵蓋 B3 專家評鑑、實際 BEN 約定能力與 Android/iOS 裝置驗收。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼一個 1NT 叫品符合「15–17 HCP」約定，仍不能當作 AI 或真人真的持有 15–17 點的證據？

**5–15 分鐘小練習（可選）：** 加入敵方插叫 2♣ 後，2NT 約定提示必須為「未知」的回歸測試。

**完成標準：** 可以分辨規則合法性、約定語義、AI 策略、隱藏資訊四者的責任與資料來源。尚未實際練習，不能標成 MASTERED。

## 本輪回歸修正
GitHub Actions 的 Flutter 測試揭露兩個既有功能回歸：Just Declare 完成後的歷史摘要原先僅將固定牌局標為練習（未辨識 Just Declare）；已在 `BridgeSession._summarize` 改以 `state.isJustDeclare` 判定。320px／2.0 倍文字下的 Just Declare 下拉選單及長按鈕改用有界寬度與省略處理，避免英文文字橫向溢位。恢復警告 Widget 測試改為先 scroll into view 再點擊，避免畫面上新增入口影響原有可點擊區。已經透過相同程式碼 SHA 的 [Flutter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38905811936) 驗證 118/118 通過。

## 下一步
做 B3.2 ConventionProfile 版本管理、叫牌約定的專家覆核及教學回饋，並補上可驗證的自動化 QA。
