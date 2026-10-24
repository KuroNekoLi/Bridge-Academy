# M4-F06｜版本差異審查：從「儲存草稿」到「看得見每次改了什麼」

- Feature ID：M4-F06
- Milestone：M4.6
- 工程類型：Immutable revision history／Flutter UX／Auditability
- 工程狀態：**IMPLEMENTED；以最新 M4 CI 結果為準**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomConventionHistory](../../../packages/bridge_conventions/lib/src/custom_convention_history.dart) · [Flutter Editor](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart)
- 測試：[Domain diff tests](../../../packages/bridge_conventions/test/custom_convention_history_test.dart) · [Widget tests](../../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart)
- CI：[M4 Custom Convention Drafts](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/m4-custom-convention-drafts.yml)

## 功能目的與實際情境

玩家第一天把 SAYC 的 1NT 改成 13–15，隔天改為 15–17，又把 1NT–Pass–2♣ 改為自然叫品。過去只能看到草稿最新 SHA，沒辦法知道修改了哪些約定。M4.6 支援從同一份**已驗證版本鏈**挑選舊版與最新版比較：新增、移除、變更的每一項包含叫牌片段、舊設定、新設定。

## 主要程式碼導讀

```dart
final diff = CustomConventionHistory.compare(
  verifiedArchive,
  fromRevision: 2,
  toRevision: verifiedArchive.latest!.revision,
);
for (final change in diff.changes) {
  print('${change.auction}: '
      '${change.beforeChoice} -> ${change.afterChoice}');
}
assert(!diff.isEngineValidated);
```

比較功能只接受同一個 `CustomConventionArchive` 的前後版號，不能拿外部未知身份的任意 JSON 假裝是自己的舊版；Archive 原先已驗證版號、上一版 SHA、base、身份一致。依 `CustomRuleSlot.values` 固定順序列差異，沒有假想的 AI 叫牌行為。

## 為什麼這樣設計

這就像 Git diff，版本 diff 是**人類改動的可追溯性**，不是 GitHub Actions 已替你訓練模型。和 Kotlin 的 immutable `data class` snapshot/Reducer 架構相似：寫入新快照，舊版不動，UI 從兩份狀態計算視圖。

替代方案是只保存最新版，但你無法查明「為什麼這次與搭檔溝通方式不同」，也無法產生可供專家審核的前後證據。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart analyze --fatal-infos
dart test test/custom_convention_history_test.dart
cd ../../apps/bridge_academy_flutter
flutter analyze --no-pub
flutter test test/m4_custom_convention_draft_test.dart
```

測試新增／修改／移除、跨多版本比較、非法版本、不可變變更清單、Widget 切換舊版及不宣稱 AI 已驗證。最終 GitHub Actions 執行狀態以 M4 workflow 的最新 SHA 為準；Android/iOS 真機 QA **NOT RUN**。

## 練習與自我檢驗

**思考題：** 為什麼從 v2 到 v5 的差異，不應直接拿兩個分別貼上的未驗證 JSON 比較？

**5–15 分鐘練習：** 使用 history test 新增 v3 加入 Stayman、v4 移除 Stayman，驗證跨 v2→v4 diff 是空的，即使兩個中間版本不同。

**完成標準：** 能區分使用者設定差異、不可變版本身份和 AI 真正執行結果。

## 下一步

下一步 M4.7 將完整的版本指紋與修改項目送入專家驗證待辦，而不讓任何草稿冒充可玩的 AI 制度。
