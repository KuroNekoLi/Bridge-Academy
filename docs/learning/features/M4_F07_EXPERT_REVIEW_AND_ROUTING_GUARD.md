# M4-F07｜專家驗證清單與 Gateway 准入防線

- Feature ID：M4-F07
- Milestone：M4.7
- 工程類型：Evidence provenance／Server-side authorization／Safe clipboard
- 工程狀態：**IMPLEMENTED；需依最新 CI 驗證**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomConventionReviewPlan](../../../packages/bridge_conventions/lib/src/custom_convention_review_plan.dart) · [編輯頁面](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart)
- 測試：[審查計畫](../../../packages/bridge_conventions/test/custom_convention_review_plan_test.dart) · [Gateway session rejection](../../../services/bridge_gateway/test/m47_custom_draft_routing_guard_test.dart) · [Flutter export](../../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart)
- CI：[M4 workflow](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m4-custom-convention-drafts.yml) · [Gateway regression](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/game-systems-m21.yml)

## 功能目的與實際情境

使用者可以定義「1NT–Pass–2♣ 是自然叫品」，也能複製自己的草稿，但真正可玩的 BEN/SAYC AI 需要更嚴格的相容性證據。因此 M4.7 不會幫 AI 硬改出價，而是讓玩家一鍵產出**專家待審清單**；每個已變更叫牌位置產生六種待測：一般、競叫、Pass 後、迫叫/邀請、Alert/揭露、對手制度理解。每個項目都是 `NOT_REVIEWED`、`NOT_RUN`，**沒有產生任何假想的 AI 輸出或專家簽名**。

## 主要程式碼導讀

```dart
final plan = CustomConventionReviewPlan.forDraft(draft);
assert(plan.targetExpertGoldenCases == 100);
assert(plan.observedEngineGoldenCases == 0);
assert(!plan.eligibleForProduction);
final packet = plan.toJson(); // public metadata only, no private Deal
```

Packet 鎖定 `baseFingerprint`、`draftFingerprint`、revision、編輯規則與待審 scenario，供未來具備實際 BEN/BBA runner 和專家金標的程式建置。100 是**目標數，不是通過數**。Flutter 複製的是待辦 JSON，沒有牌局手牌。

另一側在真實 Gateway HTTP 測試直接提交 `local_sayc`／`local_21gf`／偽造 `SUPPORTED`／偽造草稿 SHA 或 private `customDraft` payload，確認服務端拒絕建立 Session、沒有發出 access token。前端沒有可繞過的秘密開關；服務端繼續只認受信任 ConventionCatalog。

## 為什麼這樣設計

可類比 Android 客戶端 Feature Flag vs 後端權限：**client flag 不等於 server authority**。即使自訂卡 JSON 擁有合法 SHA-256，也只能證明版本資料一致，不能證明 BEN 神經網路理解新約定，更不等於已取得有授權且版本釘選的 BBA artifact。

替代方案是直接把草稿 `modelId` 塞進 `GameSystems`。這會讓 BEN 運行完全不一致的制度，破壞公平性，因此維持 fail closed。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart test test/custom_convention_review_plan_test.dart
cd ../../services/bridge_gateway
dart test test/m47_custom_draft_routing_guard_test.dart
cd ../../apps/bridge_academy_flutter
flutter test test/m4_custom_convention_draft_test.dart
```

本輪實際測試涵蓋全部待審清單的固定 slot/scene、唯一 SHA 參照、沒有私牌、0 verified、Gateway 真 HTTP 400/無 token，以及 Flutter Clipboard round-trip。還沒有專家簽核 100+ Golden、真 BEN/BBA 自訂出價跑分、模型重訓或正式裝置測試。**產品版自訂 AI Release = NO-GO**。

## 練習與自我檢驗

**思考題：** 一個本機 JSON 裡寫 `engineCertified: true`，為什麼 Gateway 仍應拒絕它？

**5–15 分鐘練習：** 在 Gateway 測試多加入一個偽造 `customDraft` 欄位，觀察服務仍為 HTTP 400 且沒有發給 access token。

**完成標準：** 能解釋待審測試案例、真實 engine observation、expert review，以及 server allowlist 分別是什麼責任。

## 下一步

M4 產品級最後的門檻仍是有來源的真正 BEN／BBA 約定映射、經審核專家標準案例、對手 reader、持續負載與正式版本部署，不會因為產生 review packet 自動通過。
