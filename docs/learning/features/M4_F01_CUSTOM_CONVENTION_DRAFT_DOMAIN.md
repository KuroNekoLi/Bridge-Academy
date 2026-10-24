# M4-F01｜自訂叫牌約定草稿：有限選項、衝突偵測與不可變版本

- Feature ID：M4-F01
- Milestone：M4.1 自訂約定領域模型
- 類型：純 Dart domain、型別安全、版本雜湊與引擎支援 Gate
- 工程狀態：**IMPLEMENTED；以最新 M2.1 Domain CI 為驗收依據**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomConventionDraft](../../../packages/bridge_conventions/lib/src/custom_convention_draft.dart) · [Immutable GameSystems](../../../packages/bridge_conventions/lib/src/game_systems.dart)
- 驗收與測試：[custom_convention_draft_test.dart](../../../packages/bridge_conventions/test/custom_convention_draft_test.dart) · [Convention CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/game-systems-m21.yml)

## 功能目的與實際情境

玩家希望從 SAYC 或 2/1 複製自己的搭檔約定，將 1NT 開叫點力改成 13–15，或將 1NT–Pass–2♣ 改成不同的意義。但目前 BEN 的 21GF/SAYC 不是可以即時任意改寫的神經網路。**使用者設定「這叫品是 Stayman」不等於 BEN 就理解且照做。**

M4.1 讓玩家可以以受限、明確的欄位建立草稿：1NT 範圍 12–14／13–15／15–17、1NT–Pass–2♣ Stayman／Natural、2♦ Hearts transfer／Natural、2♥ Spades transfer／Natural。沒有任意程式碼、任意 .bbsa 或未知約定名稱。

## 主要程式碼導讀

```dart
final draft = CustomConventionDraft.create(
  id: 'my_card', label: 'My SAYC', base: ConventionCatalog.sayc);
final edited = draft.withRule(CustomConventionRule(
  CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
assert(edited.revision == 2);
assert(edited.previousFingerprint == draft.fingerprint);
assert(edited.runtimeSupport == 'ENGINE_UNVERIFIED');
assert(!edited.isPlayableCustomSystem);
```

每次 edit/remove 都建立新 revision；SHA-256 以卡片 ID、名稱、固定 base system fingerprint、版本、上一版本 hash、排序後的受限 rule slot/choice 共同生成。不會回寫既有 `PartnershipSystem`、`GameSystems` 或 BEN 的權重。匯入 JSON 時只准許精確欄位且檢查雜湊、base allowlist、範圍、衝突；同一個 auction slot 不能同時代表 Stayman 與自然叫品。

## 為什麼這樣設計

可類比 Kotlin 的 `data class.copy()` 與 sealed enum：新版本是新物件，不因 UI 編輯而改變開局前就被鎖定的約定歷史。避免自由輸入一段「讓 1♣ 後一定答叫 1♦」就假裝神經模型能接受任意命令。

替代方案是直接修改 BBA `.bbsa` 或自由 DSL；它可以表達更多約定，但需要針對每一種完整競叫／延遲／解讀與實際 native 可執行性驗收。這階段拒絕無證據標為 `SUPPORTED`。

常見錯誤：**SHA-256 確保資料序列化的完整性，不能證明你真的擁有授權或 AI 引擎能理解這份卡。**

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart pub get
dart analyze --fatal-infos
dart test test/custom_convention_draft_test.dart --reporter expanded
```

測試包含：序列化還原／篡改拒絕、revision link、不同 rule choice、無支援的卡不能進入 `ConventionCatalog`、衝突匯入拒絕、list 不可修改。真 AI 模型支援：**NOT IMPLEMENTED**；沒有用 Mock 宣稱可用。

### 已執行的 CI

**[CI #40108357113](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40108357113) PASS**，Ubuntu 24.04，`dart analyze --fatal-infos` No issues，所有 Convention Domain 回歸加新草稿／archive 測試 **20/20**。這只能證實資料模型與拒絕偽裝引擎支援，不證明 BEN/BBA 會遵照改動出價。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼將 1NT 點力從 15–17 改成 13–15 後，原本 BEN 的 `modelId=SAYC` 不能因此就宣稱已支援新草稿？

**5–15 分鐘小練習（可選）：** 修改 `custom_convention_draft_test.dart`，對同一個 1NT–Pass–2♣ 同時導入 Stayman 與 Natural，確認匯入失敗且既有卡片版本不變。

**完成標準：** 能說明為何約定編輯、immutable revision 與 AI 引擎驗收必須分開。

## 下一步

M4.2 為草稿提供 Flutter 編輯和本機保存；日後引擎可證實支援約定才可加入 Gateway，可執行的 engine capability 不能由使用者自行宣告。
