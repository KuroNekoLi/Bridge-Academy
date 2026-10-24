# Bridge Academy — BBA Meckwell Precision V1

> **OFFICIAL SELECTED CONVENTION VARIANT / SPECIFICATION SOURCE OF TRUTH**
>
> 決定日期：2026-10-24（Asia/Taipei）  
> Product system ID：`BA-PRECISION-MECKWELL` · **Revision 1**  
> 對局引擎候選：原生 BBA／EPBot；不是 BEN 的 `ourSystem=PRECISION` 神經模型  
> 規格決定：**已定案**；產品執行啟用：**未核准／未實作**  
> 使用者已表示取得 BBA 使用授權；文件尚未提供本專案核對，範圍：**待驗證**

## 1. 唯一版本決策

Bridge Academy 第三種基礎叫牌制度的唯一 V1 為：

**BBA Meckwell Precision V1（1NT 13–15 HCP）**。

不是「一般 Precision 俱樂部」的模糊名稱，不是 `Meckwell Lite v1.13.0`（其 1NT 為 13–16），也不是任意 `System type = 3` 的約定卡。

本產品所有導覽、Convention Card、AI 叫牌提示、比賽制度、測試報表，未來均須使用完整名稱 `BBA Meckwell Precision V1` 與上述 ID/revision。基礎類型可在分類上顯示 `Precision Club`，但不可取代精確版本名稱。

### 不可變身分清冊

| 欄位 | 唯一固定值 |
| --- | --- |
| `productProfileId` | `BA-PRECISION-MECKWELL` |
| `productRevision` | `1` |
| `sourceBackend` | BBA / EPBot native |
| `upstreamBenCommit` | `ad8608af6e6bfe095863023f344f3cb2cbafec3d` |
| `cardPathInPinnedBen` | `BBA/CC/Meckwell.bbsa` |
| `cardSha256` | `5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc` |
| `nativeSystemType` | `3` |
| `oneNotrumpOpenHcp` | **13–15** |
| `licenseAssertion` | 2026-10-24，專案擁有人表示已取得 BBA 授權 |
| `licenseScopeReviewed` | false；需記錄實際授權對象、版本／元件及用途 |
| `expertSemanticsReviewed` | false |
| `runtimeBackendValidated` | false；8 組原生開叫不代表 Gateway 整局已通過 |
| `selectableInPlayerUI` | false，直到 M3.3/M3.4 釋出門檻通過 |

禁止默默改寫 revision 1 的任一固定欄位：上游 `.bbsa` SHA、引擎參照的 native library 或任何約定內容不同時，須建立 **Revision 2** 與新的明確驗收，不覆寫歷史遊戲的 Revision 1。

## 2. 這份 V1 究竟定義了什麼？

**最高權威是上述固定雜湊的 `Meckwell.bbsa`，它是 EPBot 原生引擎實際讀取的 convention configuration。** 它不等於公開 Meckwell Lite 文獻的每條規則。

已從釘選版 card 直接確認的屬性（狀態 `CARD_DEFINED`，不聲稱 100% 的原生叫牌都已被專家審核）：

| 約定欄位（upstream 原義） | 固定值／說明 | 證據類型 |
| --- | --- | --- |
| `System type` | `3`，EPBot Precision 類型 | SOURCE_PINNED |
| `1NT opening range 13-15` | `1`，唯一選用區間 | SOURCE_PINNED |
| `1NT opening range 12-14` / `14-16` / `15-17` | 全部 `0` | SOURCE_PINNED |
| `Precision 2D` | `1`，具人工制度效果；不擅自推論全部後續叫品 | CARD_DEFINED |
| `1M-3M blocking` | `1`；`1M-3M inviting` 是 `0` | CARD_DEFINED |
| `Jacoby 2NT` | `1` | CARD_DEFINED |
| `Drury` | `1` | CARD_DEFINED |
| `Blackwood 0314` | `1`；`0123` 與 `1430` 為 `0` | CARD_DEFINED |
| `Weak natural 2M` | `1` | CARD_DEFINED |

**人工強 1♣：** 本 V1 屬 Precision 強梅花類型，且此前 8 組原生測試中，4 組高牌點預期 1♣ 的測試手牌均得到 1♣；但點力例外、平衡／非平衡條件、1♣–1♦ 應叫以及競叫後強迫性，必須按本 native engine 的實測和專家金標 fixture 建立，不可以直接套用 Meckwell Lite 的 17+ balanced / 16+ unbalanced 或 1NT 13–16 說明。

## 3. 不能混用的 Meckwell Lite 參照

外部參考：[Meckwell Lite Precision System v1.13.0（2026-01-05）](https://zaremba.ch/files/precision-meckwell_lite.pdf) 的 1NT 開叫範圍為 **13–16 HCP**，而本產品原生 BBA 約定卡為 **13–15 HCP**。該文獻可以作為問題清單，**不能作為本 V1 的替代規則**。其他 Precision Club（包含 Classic Precision、Standard Modern Precision、Meckwell Lite）即使同為強梅花，也都必須按其獨立 profile/version 管理。

為避免誤導玩家，除非某條描述已經由原生 EPBot + 規格專家 + 正反牌例證明與本張 `.bbsa` 相符，不可在 UI 當成確定的叫牌含義、Alert 或教材。尚未審核的內容應顯示「約定意義待核對」而不是猜測。

## 4. 權威、實作與授權彼此獨立

- **產品規格選擇：DONE**；選定唯一 V1，不再在 13–15／13–16 之間搖擺。
- **引擎候選可運作：SCOPED PASS**；[M3 原生 CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) 8 組真原生 EPBot 開叫、四組強梅花候選皆回 1♣。
- **專家規則驗收：PENDING**；需解決完整叫牌分支與協議披露，特別是 artificial 1♣、1♦ 應叫、開叫區間上下界和敵方干擾。
- **授權狀態：OWNER_REPORTED_GRANTED / SCOPE_UNVERIFIED**；使用者已告知取得 BBA 授權，但授權文書、涵蓋 `libEPBot.so`、`.bbsa`、托管 API、非商用／商用、修改、再散布、模型訓練之範圍未核對。不得把口頭確認變成未核准的正式部署許可。
- **Bridge Academy 可玩的 Precision：NOT ENABLED**。此規格是 source of truth，不是 BEN 系統能力宣告；`ConventionCatalog`、Gateway、Flutter 仍不可選 `BA-PRECISION-MECKWELL`。

## 5. 版本驗證與接受條件

若要從研究版本升級到可對局：

1. 取得並歸檔授權的非敏感摘要與權限矩陣；完整原文可留私有儲存，不應無意上傳公開 Repo。
2. 啟動 M3.3 `PrecisionBiddingProvider`（獨立 BBA runtime）並以 Bridge Core `PlayerView` 最小資訊建立請求；不得將 `PRECISION` 冒充 BEN 可玩神經模型。
3. 對原生 `Meckwell.bbsa` 生成至少 100 組具明確 auction／expected meaning／Alert 的 golden fixture，接受專家審核。必含 1♣ 開叫與續叫、1NT 13／15／16 邊界、1♦、強迫叫、Double/Redouble／敵方競叫及誤判反例。
4. 驗證南北 Precision 對東西 21GF、SAYC，以及制度方向對調；一次完整出牌 52 張、13 墩且 Bridge Core 計分合法。
5. 經過 checkpoint/restart、失敗不中途改用 BEN 預設、負載與 4GB 目標主機測試，才能單獨考慮打開 Flutter Precision 選單。

## 6. 程式與交付來源

- 選定單一規格常數：[PrecisionResearchCatalog](../../packages/bridge_conventions/lib/src/precision_research.dart)
- 防止未核准模型進入現有可玩白名單：[Dart tests](../../packages/bridge_conventions/test/precision_research_test.dart)
- 真原生開叫資料：[M3 研究報告](../research/M3_PRECISION_SPIKE_ACCEPTANCE.md) · [Python probe](../../scripts/precision_m3_probe.py)
- 系統設計與決策：[ADR-031](../DECISIONS.md) · [授權稽核](../OPEN_SOURCE_AUDIT.md)

**產品決定不代表橋牌專家對 BBA 所有語義的簽核。** 本文件版本 1 只在 source pin、1NT 及已證實的 flag 層級給出不可變權威；更深的強梅花回應規則以後續實際 native output 建立 goldens，並由專家審定。
