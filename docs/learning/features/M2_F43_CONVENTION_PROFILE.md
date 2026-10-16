# M2-F43｜版本化叫牌約定解釋器與可信邊界

- Feature ID：M2-F43
- Milestone：M2 / B3.2
- 類型：Flutter UI／叫牌約定 Domain
- 工程狀態：SCOPED VERIFIED（129/129 Flutter、Web、Chrome Demo）
- 學習狀態：DELIVERED
- 原始碼：`apps/bridge_academy_flutter/lib/src/conventions/convention_profile.dart`、`lib/src/widgets/bidding_convention_panel.dart`、`lib/src/bidding_practice.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/b3_2_convention_profile_test.dart`、`test/b3_2_convention_widget_test.dart`；[Flutter branch CI #38909043985](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909043985)（Commit `38d2e96e2d8ce437d90162d1e3c2de1fd8a172fe`） PASS

## 功能目的與實際情境

你與電腦搭檔叫出 1NT–Pass–2♣，這通常可能是 Stayman；但這個意義**不是單靠字串 2♣ 就能判定**：它取決於是否為搭檔的 1NT **開叫**、有沒有敵方插叫、約定是否啟用、版本是否相符。玩家可在叫牌練習中開啟預覽，看到規則來源及「未經專家審核」標示。無法匹配時顯示 UNKNOWN，而不是臆測。

## 真實程式碼導讀

`BidContext.fromView(view)` 只將 dealer／viewer／vulnerability／auction 投影成領域輸入；不包含手牌。核心 `ConventionExplanationEngine.resolve` 會先驗證座位順序與叫品階層，拒絕 Double/Redouble 或競叫，再配對選定 Profile 的 exact `calls`、`relativeSeats`。

```dart
if (nonPass.any((entry) =>
    entry.seat != opener && entry.seat != opener.partner)) {
  return noMatch(ConventionMatchStatus.unknown);
}
```

這條規則保護的是教學約定的**適用前提**：敵方只要積極叫牌，就不能把未受干擾 1NT 回應的意義搬過來。`BiddingConventionPanel` 只切換 `ConventionProfiles.basic` 和 `preview` 的**說明**，沒有更新 BridgeSession、Bot 或 BEN 的策略。

`BiddingPracticeProfile.explain` 現在呼叫新引擎，因此原本 B3.1 的 1NT／2NT／3NT 中文、英文文案 key 和 Demo Bot 均保持相容。

## 為什麼這樣設計

對 Kotlin/Android 而言，`ConventionProfile` 類似版本化的 domain configuration；`BidExplanation` 類似 sealed result DTO，其 status 能區別 MATCHED、UNKNOWN、UNSUPPORTED。Flutter StatefulWidget 的預覽開關只是 Presentation State，**不能等價於切換真正 AI 的訓練權重或配置**。

替代方案是把 `if (call.code == '2C')` 直接寫在 Widget，雖然程式短，卻不易測試開叫者／搭檔關係，也可能透露出錯誤的確定性。常見陷阱是在真實叫牌看到 1NT 就宣稱一定有 15–17 HCP；現在的規則只說明約定，並不檢查別人的暗手。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub --release
```

**實際已於 GitHub Actions 執行通過：** [Flutter branch CI #38909043985](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909043985)（Commit `38d2e96e2d8ce437d90162d1e3c2de1fd8a172fe`），`flutter analyze` 無問題、`flutter test` **129/129 PASS**、Flutter Web release build 成功、Chrome Demo E2E 成功。純 Dart fixtures 涵蓋四家座位、四種局況、開叫、邀請、進局、Stayman、Jacoby、X/XX、插叫、版本失配、非法座位與叫價；Widget 測試覆蓋 zh-TW/en、切換預覽、來源、320px 和文字縮放。這些均不是專家審核或 BEN 策略驗證。

## 練習與自我檢驗

**思考題（1 題）：** 假設 North 開叫 1NT、East 插叫 2♣、South 接著叫 2♦，為何不能直接顯示「2♦ 轉換至紅心」？

**5–15 分鐘小練習（可選）：** 在 `b3_2_convention_profile_test.dart` 加入 1NT–Double–2♦ 的 UNKNOWN 斷言並執行。思考需修改策略演算法嗎？

**完成標準：** 能區分 ①Bridge Core 的合法性 ②約定是否適用 ③Bot/BEN 是否真的依約定叫牌，且能解釋何時回 UNKNOWN。完成教材不等於使用者已 MASTERED。

## 下一步

待專家逐條審查後才可批准真實 SAYC／2/1 規則；另外要先驗證 BEN 實際配置與 CompatibilityReport，才可讓選擇 Profile 影響 AI 的策略或練習評分。
