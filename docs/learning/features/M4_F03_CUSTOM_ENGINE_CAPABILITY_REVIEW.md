# M4-F03｜自訂 Convention Card 的引擎能力與證據判定

- Feature ID：M4-F03
- Milestone：M4.3
- 類型：Dart Domain、Capability Gating、安全工程、AI 系統誠信
- 工程狀態：**IMPLEMENTED；CI 以最新版成功 run 為準**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomConventionReviewer](../../../packages/bridge_conventions/lib/src/custom_convention_review.dart)
- 測試：[custom_convention_review_test.dart](../../../packages/bridge_conventions/test/custom_convention_review_test.dart)；[M4 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m4-custom-convention-drafts.yml)

## 功能目的與實際情境

當玩家把 1NT 開叫點力從 15–17 改成 12–14，再勾選 2♣ 是自然叫品，編輯器必須能清楚說明「這是你寫的約定」，**絕對不能**說「BEN 已經會依照這份草稿叫牌」。固定 BEN 21GF/SAYC 的神經網路沒有接受任意新的 Convention Card 的訓練證據。

## 主要程式碼導讀

```dart
final card = CustomConventionDraft.create(
  id: 'my_card', label: 'My SAYC',
  base: ConventionCatalog.sayc,
).withRule(CustomConventionRule(
  CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL',
));
final report = CustomConventionReviewer.assess(card);
assert(report.executionStatus ==
    CustomExecutionStatus.engineEvidenceRequired);
assert(!report.canUseAsAiSystem);
```

`assess` 對每個修改過的 slot 產生 `USER_DRAFT:<slot>`、對應公開 auction、玩家選擇、`no_pinned_engine_rule_evidence`，不是模型推理報告。沒有修改的 base 顯示 `unchangedBase`，**但依然不能把本機草稿註冊成新的 playable profile**。`canUseAsAiSystem` 在本階段始終 false；需要未來獨立的 server-owned artifact manifest、實際行為金標測試與 revision 對照才有資格討論支援。

## 為什麼這樣設計

在 Android/Kotlin 可以類比 Feature Flag 與 Domain Policy 分離。UI 上的 `enabled=true` 不等於後端已獲授權。同理，JSON `"runtimeSupport":"SUPPORTED"` 即使是玩家自己填的，也不可以被信任或成為正式 BEN model selector。Bridge Core 仍是合法性唯一權威。

替代方案是讓使用者上傳任何 BBA `.bbsa`，但那涉及任意檔案載入、沙箱、授權、版本固定以及雙方 interpreter 的一致性；目前明確禁止。

常見錯誤：把一個 SHA-256 hash 當成 capability proof。它只能檢查資料是否一致，不能證明 BEN／BBA 真會執行使用者寫的約定。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos
dart test test/custom_convention_review_test.dart --reporter expanded
```

測試涵蓋未修改 vs 已修改、四種已列舉規則、無法註冊 ConventionCatalog、回傳不可用引擎狀態。AI 引擎實際套用修改過的約定：**NOT RUN / UNSUPPORTED**；不使用 Mock 充當真 BEN 支援。

## 練習與自我檢驗

**思考題（1 題）：** 既然草稿有 SHA256，為什麼不能把 `modelId=SAYC` 不變就宣稱已支援新的 1NT 12–14 約定？

**5–15 分鐘小練習：** 在 `custom_convention_review_test.dart` 為 2♦ 轉移叫品新增斷言，確認任何修改後的卡仍不可作為 AI 對局制度。

**完成標準：** 能分辨使用者設定、模型實際能力、引擎認證證據的不同來源。

## 下一步

M4.4 將上述清楚的驗證狀態顯示在 UI，並只允許公開叫牌片段的意義預覽。
