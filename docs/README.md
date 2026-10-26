# Bridge Academy 文件總覽

> 更新：2026-10-26。這是本專案文件的**唯一入口**。所有功能狀態以**實作與測試證據**為準；規劃、研究、原型和正式發行不能混為一談。

文件只分三類：

| 類別 | 看什麼 | 入口 |
| --- | --- | --- |
| **一、已實作功能** | 玩家可使用的內容、技術架構、橋牌規則、工程教學摘要 | [功能清單](implemented/FEATURES.md) · [架構](implemented/ARCHITECTURE.md) · [規則](implemented/BRIDGE_RULES.md) · [工程筆記](implemented/ENGINEERING_NOTES.md) |
| **二、接下來的產品規劃** | 產品目標、未完成任務的優先順序、正式發行門檻與決策／交接 | [產品需求](planning/PRODUCT_REQUIREMENTS.md) · [下一步路線](planning/ROADMAP.md) · [發行關卡](planning/RELEASE_CHECKLIST.md) · [決策](planning/DECISIONS.md) · [目前交接](planning/CURRENT_HANDOFF.md) |
| **三、相關研究報告** | BEN、2/1/SAYC、Precision、橋牌 AI、效能、UX、授權與競品研究 | [BEN 制度實測](research/BEN_SYSTEMS.md) · [Precision](research/PRECISION.md) · [自訂約定／教練](research/CUSTOM_AND_COACH.md) · [UI／產品驗收](research/UX_AND_PLATFORM.md) · [授權與容量](research/OPERATIONS_AND_LICENSES.md) · [Precision 約定規格](research/PRECISION_CONVENTION_SPEC.md) |

## 文件使用原則

1. **問「現在能玩什麼」：**讀 `implemented/FEATURES.md`，再以其中連結到的程式與 CI 驗證。
2. **問「下一步做什麼」：**讀 `planning/ROADMAP.md`，尚有阻斷須同時看 `RELEASE_CHECKLIST.md`。
3. **問「為什麼選這個 AI／有沒有真實測試」：**讀 `research/` 的對應報告。
4. **改橋牌玩法：**`implemented/BRIDGE_RULES.md` 是工程法則權威，先補測試再改規則。
5. **架構、AI 或安全決策：**先核對 `planning/DECISIONS.md`，不得將 scoped CI pass 說成公開部署許可。
6. **開始程式工作：**由根目錄 [AGENTS.md](../AGENTS.md) 與 [skills/README.md](../skills/README.md) 確認開發規範。

## 已清理的舊文件

2026-10-26 將散落的里程碑報告、逐版本交接、重複規格、分散式教學整理為上述主題文件。先前精確技術內容並非消失，可由整理前的 Git commit `425da3ed393e6b9307f3d9961e52e542368c79e5` 查閱。**歷史報告的 PASS 只適用其當時 SHA、fixture 與環境；本版不把歷史證據提升為新的產品核准。**
