# M4 — 自訂叫牌約定：草稿與引擎相容性的分離驗收

> 2026-10-24 · source: [三制度產品路線](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md)  
> **M3 research/engineering = SCOPED PASS, M3 production/AI strength = NO-GO.**  
> **M4.1–M4.2 editable draft = IMPLEMENTED / scoped CI evidence；M4 complete playable custom-system = NO-GO.**

## M4 在本分支到底是什麼？

產品三制度路線 M1→M6 定義的 M4 是 **Custom Convention Card**；不是歷史 `docs/ROADMAP.md` 中另一套「M4 Multiplayer」里程碑。這一階段可與 M3 競賽牌力驗證並行，但不可把研究成功當成已核准的 AI 模型，或修改正式 Gateway 的 `GameSystems`。

## M4.3～M4.5 工程擴充（2026-10-25）

**工程碼已提交；最新 CI 必須另依已完成的 GitHub Actions 簽核。** 此階段重點是讓玩家知道自訂約定代表的意思、確認它是否真的受到 AI 引擎支援，以及安全地轉移自己的草稿歷史。**沒有訓練 BEN 模型，沒有提供受支援的任意自訂 BBA 卡，也沒有解除正式對局封鎖。**

| 階段 | 交付內容 | 不可混淆的限制 |
| --- | --- | --- |
| M4.3：能力審核 | [CustomConventionReviewer](../../packages/bridge_conventions/lib/src/custom_convention_review.dart)；對每項規則顯示 `USER_DRAFT:<slot>`、公開叫牌、`engineEvidenceRequired`；未更動 base 為 `unchangedBase` | `canUseAsAiSystem=false`，沒有正向憑證就不可說「BEN 支援」；不能讓玩家輸入 `SUPPORTED` 繞過 |
| M4.4：語義預覽 | `preview(draft, publicAuction)` 正規化有限 call；回傳 user-draft meaning／base-unverified／no-rule；[Flutter](../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) 顯示雙語語義和證據不足提醒 | 不推測未知叫品、不查看隱藏手牌、不代表真 AI 在叫牌當下的理解 |
| M4.5：本機安全搬移 | [CustomArchiveImport](../../packages/bridge_conventions/lib/src/custom_convention_archive.dart) 支援驗證歷史後 `identical/fastForward/divergent`；Flutter Clipboard 明確匯出、受限 128 KiB 匯入、人類按確認才寫入 | 不能倒退覆蓋本機版本、不能跨 base/分岔匯入；沒有帳號同步、雲端歷史或惡意本機攻擊防護 |

可重現驗證：

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
cd ../../apps/bridge_academy_flutter
flutter pub get && flutter analyze --no-pub
flutter test test/m4_custom_convention_draft_test.dart --reporter expanded
```

測試含未支援約定不得進入 `ConventionCatalog`、公開叫牌只顯示作者明訂語義、未覆寫為 `UNKNOWN`、異常 JSON/hash/conflict 失敗、剪貼簿匯入明確確認及拒絕分岔、離線匯出回讀。固定 `GameSystems` 及既有 BEN／BBA 正式路由完全不變；Android/iOS 裝置 QA 未經使用者授權不啟動。

**剩餘 M4 Product NO-GO：** 任意可執行自訂規則需要已簽核的 native BBA/自有 rule engine 能力 manifest、引擎 hash、完整兩家搭檔的 forcing/competitive/alert Golden、版本恢復與相容性測試；多張自訂卡管理、可信雲同步和正式發行審查仍未完成。

## 最新 M4.3～M4.5 CI 證據（2026-10-25）

[GitHub Actions #40137806806](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40137806806) **completed/success**（Ubuntu 24.04，Dart／Flutter stable，未使用 Android/iOS 模擬器或實機）。該 workflow 執行：

| 範圍 | 實際結果 |
| --- | --- |
| `packages/bridge_conventions` analyzer | **No issues found** |
| 所有 Domain tests（包含 immutable GameSystems、M3 compatibility、M4 rule/revision/review/import） | **25/25 PASS** |
| `apps/bridge_academy_flutter` analyzer | **No issues found** |
| M4 Flutter Editor tests（含語義預覽、Clipboard fast-forward/衝突、安全確認） | **4/4 PASS** |
| 修改過的約定真 BEN/BBA 叫牌執行 | **NOT RUN／UNSUPPORTED** |
| 100+ 專家 Golden、正式多卡雲同步、主機與裝置 QA | **NOT RUN** |

**工程結論：** M4.1／4.2 本機草稿與 M4.3／4.4／4.5 的 evidence guard／預覽／可攜版本備份 **SCOPED ENGINEERING PASS**。M4 任意可玩自訂系統**仍 NO-GO**，不可將草稿變成 `GameSystems`／`ConventionCatalog` 的新模型。

## 已實作

| 子階段 | 程式及使用者效果 | 證據／限制 |
| --- | --- | --- |
| M4.1 限定規則與版本 | [Draft](../../packages/bridge_conventions/lib/src/custom_convention_draft.dart) 從固定 SAYC 或 21GF clone，編輯 1NT HCP、Stayman、Jacoby transfer；slot choice 白名單，JSON schema、SHA-256、revision/previousFingerprint、collision check；規格不許任意 DSL/.bbsa | [Dart domain tests](../../packages/bridge_conventions/test/custom_convention_draft_test.dart)，無任何 AI「支援」標籤 |
| M4.2 歷史與 UI | [Archive](../../packages/bridge_conventions/lib/src/custom_convention_archive.dart) 逐版 append／驗證 hash chain、同 ID/base；[本機 store](../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_store.dart) 使用 SharedPreferences；[雙語 Flutter page](../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) 有 editor／remove／revision／fingerprint／明確研究提示，主 AppBar 可以開啟 | [archive tests](../../packages/bridge_conventions/test/custom_convention_archive_test.dart) · [Flutter widget tests](../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart) |
| M4.3 engine capability | 每筆**已編輯**規則都標 `ENGINE_UNVERIFIED`，`isPlayableCustomSystem=false`，不在 `ConventionCatalog` 註冊，也無法送給 `BenBotPolicy`／正式 `Gateway`；只有未更動 base 具有 `UNCHANGED_BASE_ONLY` | 這是安全保護，**不是完成引擎支援** |
| M4.4 專家／AI 功能驗收 | 逐個約定的真 BEN/BBA behavior、對手 reader、forcing/competition/alerts/expert goldens | **NOT IMPLEMENTED、NOT RUN** |
| M4.5 正式部署與同步 | 多卡管理、匯入/匯出、可編輯自訂名稱、跨裝置帳號、專家審核程序與已簽核 AI routing | **NOT IMPLEMENTED、RELEASE NO-GO** |

**保存≠支援。** 修改 `1NT=13–15` 或 `2♣=NATURAL` 沒有重訓 BEN，也沒把 BBA `.bbsa` 改成正式可辨識的 engine artifact。即使以 SHA 計算出同一份檔案完整性，也沒有給它 runtime execution 權限。哪天要開放可玩自訂卡，必須新增**server-owned allowlisted engine evidence**，每組已授權卡的 model/commit/CC digest、正式叫牌測試及適當恢復與隔離測試，才能從 `ENGINE_UNVERIFIED` 升級。使用者／JSON 不可以自行宣告 `SUPPORTED`。

## 已執行的 M4.1–M4.2 驗收（GitHub Actions）

**2026-10-24 [CI #40108357113](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40108357113) `completed/success`：**

| 項目 | 結果 |
| --- | --- |
| `packages/bridge_conventions` `dart analyze --fatal-infos` | No issues found |
| Dart Domain all: M2/M3 regression + M4 custom drafts／archive | **20/20 PASS** |
| Flutter `flutter analyze --no-pub` | No issues found |
| Flutter editor `flutter test test/m4_custom_convention_draft_test.dart` | **2/2 PASS** |
| M4 UI save, reload, locale, remove, engine-unverified warning | PASS（memory storage injected into Widget；真 SharedPreferences on device NOT RUN） |
| 修改後的約定在 BEN/BBA 中實際執行 | **NOT SUPPORTED / NO-GO** |
| 新約定 100+ expert golden、正式 VPS、裝置 QA | **NOT RUN** |

**判決：M4.1／M4.2 的本機功能 ENGINEERING_PASS；M4 整體尚未全部完成。**

## 已知保留與安全

- SharedPreferences 是一般本機偏好，不是 encrypted ACID database、跨裝置雲同步或防惡意使用者竄改的簽章。發現 hash mismatch 會**拒絕自動覆蓋**，舊資料不被靜默丟棄。
- 有限 rule choices 對應公開 auction slot；同 slot 不同意義或任意攻擊 payload 不允許匯入。若 UI 把同 slot 改成另一個 choice，舊 revision 保留，新 revision 替代那個 slot。
- 不允許拿自己的草稿直接更換場上 GameSystems；已開始的牌局之 NS/EW 系統版本仍由 server pin。
- Android emulator、Android/iOS 實機 E2E 遵守既有 owner 暫緩。Flutter widget/Dart/Chrome 能跑的範圍不等同 release。
- 本次並**沒有**得到任何「M3 牌力已完成」的新證據：100+ Precision 專家 goldens、1000 完整局比較、VPS 2vCPU/4GB 負載仍未實際通過。

## 驗證指令與證據歸類

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded

cd ../../apps/bridge_academy_flutter
flutter pub get && flutter analyze --no-pub
flutter test test/m4_custom_convention_draft_test.dart
```

CI 建議：[Domain+Gateway](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/game-systems-m21.yml)、[Flutter Web/Widget](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/flutter-single-player.yml)。每個 run 的 true conclusion 在成功前仍須標 **PENDING**，不得用過期版本通過冒充。

## 下一步

M4 可執行產品完成所需：與真 BEN/BBA 可用卡版本或自有規則引擎做**封閉式 capability mapping**；精確 Golden 叫牌與對手理解測試；本機多草稿 UX、匯出與必要帳號同步；釋出前雙語用戶驗收。**現階段不解除 Precision／自訂卡正式發行門檻。**
