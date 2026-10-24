# M4 — 自訂叫牌約定：草稿與引擎相容性的分離驗收

> 2026-10-24 · source: [三制度產品路線](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md)  
> **M3 research/engineering = SCOPED PASS, M3 production/AI strength = NO-GO.**  
> **M4.1–M4.2 editable draft = IMPLEMENTED / scoped CI evidence；M4 complete playable custom-system = NO-GO.**

## M4 在本分支到底是什麼？

產品三制度路線 M1→M6 定義的 M4 是 **Custom Convention Card**；不是歷史 `docs/ROADMAP.md` 中另一套「M4 Multiplayer」里程碑。這一階段可與 M3 競賽牌力驗證並行，但不可把研究成功當成已核准的 AI 模型，或修改正式 Gateway 的 `GameSystems`。

## 已實作

| 子階段 | 程式及使用者效果 | 證據／限制 |
| --- | --- | --- |
| M4.1 限定規則與版本 | [Draft](../../packages/bridge_conventions/lib/src/custom_convention_draft.dart) 從固定 SAYC 或 21GF clone，編輯 1NT HCP、Stayman、Jacoby transfer；slot choice 白名單，JSON schema、SHA-256、revision/previousFingerprint、collision check；規格不許任意 DSL/.bbsa | [Dart domain tests](../../packages/bridge_conventions/test/custom_convention_draft_test.dart)，無任何 AI「支援」標籤 |
| M4.2 歷史與 UI | [Archive](../../packages/bridge_conventions/lib/src/custom_convention_archive.dart) 逐版 append／驗證 hash chain、同 ID/base；[本機 store](../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_store.dart) 使用 SharedPreferences；[雙語 Flutter page](../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) 有 editor／remove／revision／fingerprint／明確研究提示，主 AppBar 可以開啟 | [archive tests](../../packages/bridge_conventions/test/custom_convention_archive_test.dart) · [Flutter widget tests](../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart) |
| M4.3 engine capability | 每筆**已編輯**規則都標 `ENGINE_UNVERIFIED`，`isPlayableCustomSystem=false`，不在 `ConventionCatalog` 註冊，也無法送給 `BenBotPolicy`／正式 `Gateway`；只有未更動 base 具有 `UNCHANGED_BASE_ONLY` | 這是安全保護，**不是完成引擎支援** |
| M4.4 專家／AI 功能驗收 | 逐個約定的真 BEN/BBA behavior、對手 reader、forcing/competition/alerts/expert goldens | **NOT IMPLEMENTED、NOT RUN** |
| M4.5 正式部署與同步 | 多卡管理、匯入/匯出、可編輯自訂名稱、跨裝置帳號、專家審核程序與已簽核 AI routing | **NOT IMPLEMENTED、RELEASE NO-GO** |

**保存≠支援。** 修改 `1NT=13–15` 或 `2♣=NATURAL` 沒有重訓 BEN，也沒把 BBA `.bbsa` 改成正式可辨識的 engine artifact。即使以 SHA 計算出同一份檔案完整性，也沒有給它 runtime execution 權限。哪天要開放可玩自訂卡，必須新增**server-owned allowlisted engine evidence**，每組已授權卡的 model/commit/CC digest、正式叫牌測試及適當恢復與隔離測試，才能從 `ENGINE_UNVERIFIED` 升級。使用者／JSON 不可以自行宣告 `SUPPORTED`。

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
