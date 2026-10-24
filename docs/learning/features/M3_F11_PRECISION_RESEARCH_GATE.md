# M3-F11｜如何避免未完成的 Precision 被意外放到玩家選單

- Feature ID：M3-F11
- Milestone：M3 Precision Club Candidate Gate
- 類型：Dart Domain、規格版本與 Fail Closed
- 工程狀態：SCOPED VERIFIED（資料模型與不可選保護測試，真 Precision Gateway 尚未實作）
- 學習狀態：DELIVERED
- 原始碼：[PrecisionResearchCatalog](../../../packages/bridge_conventions/lib/src/precision_research.dart) · [正式 ConventionCatalog](../../../packages/bridge_conventions/lib/src/game_systems.dart)
- 驗收與測試：[Dart tests](../../../packages/bridge_conventions/test/precision_research_test.dart) · [Dart CI](../../../.github/workflows/game-systems-m21.yml)

## 功能目的與實際情境

與 2/1/SAYC 不同，Precision 在這階段只有兩個不同來源的候選：Meckwell Lite 2026-01-05 公開參考規格、以及 BEN 固定 commit 內的 BBA Meckwell 約定卡。如果它們規則不同，玩家看到相同的「精準制」標籤，就可能誤以為搭檔懂得同一套約定。

研究發現 1NT 區間不一致：Meckwell Lite 參考文件 13–16，原生 BBA Meckwell 卡 13–15。不能在不說明差異的情況下將兩份規格併成同一個 revision。

## 主要程式碼導讀

PrecisionResearchCandidate 是 immutable value object，分開記 researchId、來源 URL、1NT 區間、人工強 1♣ 說明、runtime backend、system type，以及 backendValidated／expertApproved／licenseApproved／supportedByPlayableBenNeuralModel 四個互不等價的狀態。readyForCatalog 只有在 backend、expert 和 license 三者都核准才可成立；因為 BBA 是可行的非神經網路選項，不能錯把「沒有 BEN NN」當成未來絕不可能使用。

PrecisionResearchCatalog 目前含兩個候選，compatibleAsSameVersion = false；canOfferPrecisionToPlayers = false。此類型故意不被 ConventionCatalog.resolve() 註冊，也不導出 Gateway 任何對玩家的選擇。即使有人向 Gateway POST BA-PRECISION，仍會被現有 allowlist 回絕。

## 為什麼這樣設計

這相當於 Android 的 staged feature rollout：把研究資料、產品契約和 runtime availability 分開，不能因 UI 的選單出現就推斷後端已支援。另一種做法是先在 ConventionCatalog 加 BA-PRECISION，再用 TODO 或 false flag 擋住；這容易造成歷史 checkpoint 版本漂移、意外解除 guard 或前端誤用，所以這一輪不採用。

未來需要正式引擎時，先建立獨立 provider contract，再以完整 Gateway capability + immutable profile/version 將研究候選升級成真實可玩的選擇。不能僅修改 Meckwell.bbsa 的 1NT 設定就假裝 BEN 神經網路已學會新的叫牌語義。

## 驗證與實際證據

執行：cd packages/bridge_conventions && dart pub get && dart analyze --fatal-infos && dart test --reporter expanded。測試確認兩個 1NT 範圍不同，候選資料顯示未核准、原生 type 3 不被視為 BEN 模型、正式 ConventionCatalog 只有 21GF 與 SAYC。

CI 請以最新 [M2.1 GameSystems Workflow](../../../.github/workflows/game-systems-m21.yml) 通過結果為準；早期實作曾因錯誤 import / 缺少 backendValidated named arg 觸發 Dart analyzer，均應修正後再計入完成。真 BBA 隔離執行見 [M3 報告](../../research/M3_PRECISION_SPIKE_ACCEPTANCE.md)，與這個純 Dart 保護測試是不同證據。

**NOT RUN**：Precision 在真 BEN Gateway 牌局中切換、完整 52 張牌對局、商業授權、裝置 QA。這一功能只保護現有 M2，不宣稱 Precision 已對外開放。

## 練習與自我檢驗

**思考題（1 題）：** 假設下一版 BBA Meckwell .bbsa 將 1NT 改成 13–16，但仍未取得商業使用許可，是否可以直接新增 BA-PRECISION 到 ConventionCatalog？為什麼？

**5–15 分鐘小練習（可選）：** 在 precision_research_test.dart 驗證 candidate.readyForCatalog 為 false，並確認 ConventionCatalog.resolve('BA-PRECISION',1) 仍為 null。

**完成標準：** 能區分候選參考規格、實際引擎設定與被允許的 Product Feature。

## 下一步

先形成唯一的 Precision 約定卡修訂版，且拿到作者授權，完成 expert-approved 流程與同桌兩側模型路由後才允許將候選設為 playable。
