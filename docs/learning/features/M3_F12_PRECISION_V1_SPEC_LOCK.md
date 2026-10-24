# M3-F12｜Precision 如何決定唯一、可重現的制度版本

- Feature ID：M3-F12
- Milestone：M3 Precision agreement version selection
- 類型：領域建模、橋牌叫牌約定、軟體版本／授權邊界
- 工程狀態：**SCOPED VERIFIED**（規格與不可變性檢查；不是完整 BBA runtime）
- 學習狀態：**DELIVERED**
- 原始碼：[Dart selected V1](../../../packages/bridge_conventions/lib/src/precision_research.dart) · [Spec SoT](../../conventions/PRECISION_BBA_MECKWELL_V1.md) · [ADR-031](../../DECISIONS.md)
- 驗收與測試：[Dart tests](../../../packages/bridge_conventions/test/precision_research_test.dart) · [CI #40093845902](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40093845902)

## 功能目的與實際情境

玩家希望在 2/1、SAYC 之外能跟一名精準制 AI 搭檔打牌。如果我們只把 profile 命名成 `Precision`，兩位搭檔可能各自理解不同的 1NT 區間和強梅花回應，造成每一步叫牌雖然合法卻互相誤解。

因此正式決定 Bridge Academy 的第一套精準制是 **BBA Meckwell Precision V1**，1NT **13–15**，以已在隔離 CI 執行的 `BBA/CC/Meckwell.bbsa` 固定 SHA 為約定來源。另一份 2026-01-05 公開 Meckwell Lite 1NT 13–16 是不同的參考規格，不能混稱同一版本。

## 主要程式碼導讀

真正的來源是 `packages/bridge_conventions/lib/src/precision_research.dart`：

```dart
static const String selectedProductProfileId = 'BA-PRECISION-MECKWELL';
static const int selectedProductRevision = 1;
static const String selectedProductName = 'BBA Meckwell Precision V1';
static const String selectedCardSha256 =
    '5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc';

static const bool bbaPermissionReportedByOwner = true;
static const bool bbaPermissionScopeVerified = false;

static const selectedV1 = upstreamBbaMeckwell;
static const bool variantSelected = true;
```

第一部分固定系統身分、版本和來源卡。第二部分區分「使用者已表示有權使用」與「我們已核對正式授權範圍」，以免誤判可散布 native binaries。最後明確只有 `upstreamBbaMeckwell` 是 V1，其他候選只供比較。

資料流：商品規格決定 → revision + SHA pin → unit tests → 後續先完成權限／expert／backend gate → 才能由 Gateway 建立正式 Session。這輪**未將 Precision 加進 `ConventionCatalog` 讓玩家選擇**。

## 為什麼這樣設計

可以類比 Kotlin 的 immutable `data class` + Gradle Dependency Locking：不是只要求版本名字，還必須把真正會影響行為的 **artifact fingerprint** 固定。

另一種方案是採公開 Meckwell Lite 13–16 然後改寫 BBA `.bbsa`；但只改 card 值並不會證明整套 native backend、回應及對手理解都跟著改對，因此這輪選擇更貼近已實測的上游 13–15。

**常見錯誤**：把 `licenseApproved = true` 當成「我有對方某種許可」，而未記錄究竟是研究、伺服器商用、修改或散布。好的 release gate 需要權利明細，不是單一模糊 bool。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

實際 [GitHub Actions #40093845902](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40093845902)：Domain **10/10 PASS**、Gateway 回歸 **44/44 PASS**、雙 Package Dart analyze No issues。測試確認唯一 V1 ID/revision、固定 SHA、已報告／未審核授權、不得誤註冊進玩家選單。

與本次規格決定不同的原生證據：[M3 EPBot CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) 真原生 8 組開叫、4 個強 1♣ 候選零差異；**這不是**完整精準制 Goldens 或混合搭檔的真 Gateway 對局驗收。

## 練習與自我檢驗

**思考題（1 題）：** 某天 BBA 將 Meckwell 1NT 從 13–15 改為 13–16，卻仍叫做 Meckwell。為什麼舊遊戲不可以默默沿用 profile revision 1？

**5–15 分鐘小練習（可選）：** 在 `precision_research_test.dart` 增加一個斷言：`selectedV1` 與 `meckwellLiteReference` 的 1NT 區間不同，且 `ConventionCatalog.resolve('BA-PRECISION-MECKWELL', 1)` 仍是 null。

**完成標準：** 能解釋制度名字、revision、來源雜湊、實際 AI 模型行為與使用權範圍五者不同，且能指出哪個證據還沒有。

## 下一步

M3.3 應以這份固定 V1 規格建立可替換 BBA Provider，並完成專家規則、合作競叫、正式授權權限矩陣及真實整局 E2E。沒有這些就不把 Precision 放入 Flutter 正式選單。
