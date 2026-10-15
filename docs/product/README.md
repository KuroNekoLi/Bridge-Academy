# Bridge Academy — 產品規劃總覽

**基準日期：2026-10-15**  
**目前狀態：產品方向與開發優先順序已核准；不代表 MVP 已正式發布。**  
**開發原則：參考新睿橋牌、BBO 和 BBO Trainer 的公開產品能力，原創實作，不複製對方的程式碼、素材、牌例或教學內容。**

## 請依此順序閱讀

1. [競品研究：COMPETITOR_BENCHMARK.md](COMPETITOR_BENCHMARK.md)：新睿／BBO／Trainer 各提供什麼、官方依據與查證限制。
2. [正式產品需求：BRIDGE_ACADEMY_PRD_V1.md](BRIDGE_ACADEMY_PRD_V1.md)：定位、使用者故事、15 項功能需求、完整的玩家流程、隱私及產品驗收。
3. [交付 Roadmap：PRODUCT_DELIVERY_ROADMAP.md](PRODUCT_DELIVERY_ROADMAP.md)：分階段交付、依賴關係、測試與發布門檻，以及下一個 Agent 任務。

以上三份是**產品範圍／先後順序的權威依據**。具體橋牌規則仍以 [Bridge Rules Baseline](../BRIDGE_RULES_BASELINE.md) 為準；已核准的架構決策以 [ADRs](../DECISIONS.md) 為準；過往 CI／完成紀錄保留於 [工程 Roadmap](../ROADMAP.md)。若矛盾必須提出討論，不得用 PRD 默默更改遊戲規則。

## 產品定位

讓玩家可以「**打牌 → 複盤 → 學習 → 進步 → 競賽**」：

| 階段 | 交付目標 | 優先重點 |
| --- | --- | --- |
| **A：可玩單人橋牌** | 玩家不需安裝 Python，即可搭配三名真正的 BEN AI，連打多副、保存進度、賽後回放 | **現在最高優先** |
| **B：練習與教學** | 四副牌練習、主打專項、叫牌練習與原創引導課程 | 完成 A 後 |
| **C：複盤與分析** | DDS 賽後分析、有依據的叫牌解說、學習進度 | 需要回放及專家驗證 |
| **D：非同步 Duplicate** | 每日相同牌組、比較 MP／IMP、好友挑戰 | 需要伺服器權威資料和公平性設計 |
| **E：真人線上平台** | 四人同步牌桌、房間、社群、比賽管理與斷線重連 | 長期目標 |

### 為何這次要重排？

先前 Core 47/47、Flutter Web、Android 模擬器及真 BEN 固定牌局 CI 已獲得驗收，但這些「工程 PASS」並不代表玩家能在正式環境持續玩牌。現存關鍵缺口：Board Number／Dealer／Vulnerability 未完整輪替、無持久化保存、真 BEN 尚無正式安全部署、牌桌 UX 尚未完成、未實測物理裝置與正式發布。

## 下一個實作任務：Phase A1 Board Management

從 Bridge Core 開始完成 **標準 16 副 Duplicate 牌號／發牌者／局況循環**，再在 Flutter 顯示牌號與局況，並區分「下一副」與「重新打同一副」。

驗收要求：Board 1–32 規則正確、指定 Dealer 與局況確實進入 Coordinator、正確影響分數與 BEN 參數，並有繁體中文／英文介面及自動化測試。不得破壞已有的固定教學牌、Replay 或真 BEN 回歸測試。

**交接給 Codex/Work Agent 的方式：** 先讀 [AGENTS.md](../../AGENTS.md) → [Orchestrator Skill](../../skills/bridge-orchestrator/SKILL.md) → 三份產品文件 → [既有規則](../BRIDGE_RULES_BASELINE.md) → 相關程式碼。每一步維持使用者已核准的**直接 Push master、不開 PR**，每個行為功能附實際測試與繁體中文工程教學。

## 產品與開發限制

- 初版不強制登入；BEN 網路服務不可偷偷切換成 Demo Bot。
- Bridge Core 才是合法性與計分權威；AI 是不可信任的出牌建議者。
- 玩家在進行中的牌局不得取得另外三家的暗牌；DDS 不得用來作弊。
- 僅有一個 NS signed duplicate score 時，不能直接宣稱已算出 MP 百分比或 IMP。
- 沒有正式牌桌部署、裝置測試及 BEN 授權審查，不可標成可正式發行。
- 效能數值屬**提議驗收門檻**而非已測試成果。

**這回合只完成產品規劃與 Agent 工作規範的文件化；沒有修改遊戲邏輯，也沒有新增通過測試的功能。**
