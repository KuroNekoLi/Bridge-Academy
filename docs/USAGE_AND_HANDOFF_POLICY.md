# 用量監看與 30% 交接硬性規範

核准：使用者於 2026-10-26 要求「繼續，監看用量；額度剩下 30% 先整理交接文件；寫入專案硬性需求」。本文件和根目錄 AGENTS.md 一起適用於本專案所有後續 agent 工作，屬開發流程規範，不是 App 玩家功能。

## 檢查方式

只使用目前宿主提供的 `get_usage_limits` 帳號工具。優先讀 `rateLimitsByLimitId`；不存在才讀 legacy `rateLimits`，避免重複計算同一帳號視窗。對每個可取得的 primary／secondary：

```text
remainingPercent = max(0, min(100, 100 - usedPercent))
trigger = 任一 numeric window 的 remainingPercent <= 30
```

usedPercent 是已使用比例；不要把 70% used 當成 70% remaining。0% used → 100% remaining。null／缺欄位／讀取失敗是 UNKNOWN；餘額 credits、對話 context 剩餘 token 和帳號使用視窗是不同概念，不能互換。

檢查時機：工作開始、大型新功能前、主要驗證後、commit/push 與交接前；持續工作至少每 15 分鐘一次。只在工具回報之後描述目前數字，保留「工具回報」用語，不承諾計量沒有延遲。

## 30% 觸發順序

1. 先保存本機現況，讀 `git status --short`、目前 branch／HEAD，查核已完成的命令和 CI；不刪除或暫存別人的未提交工作。
2. **先更新 `docs/handoff/CURRENT_HANDOFF.md`，再做另一項大型工作**。即使目前有測試失敗／CI 等待，也要寫真實狀態，不能為了漂亮交接省略失敗。
3. 交接內容包含目標、原始要求／新 steering、完成與未完成、實際檔案、重現／接續命令、每項測試 EXECUTED/PASS/FAILED/BLOCKED/NOT RUN、CI URL／SHA、未提交項目、風險、回退、必要決策、使用量視窗與百分比及檢查時間。
4. 通知使用者已觸發、哪個視窗剩多少、交接文件位置。優先安全收尾／必要修復／有限驗證，不開始新的大型功能；恢復後重新檢查再接續。
5. 同一次狀態不重複提醒；數字下降到需採取新行動、恢復、交接有重要更新或需要使用者處理時才回報。不把交接規範解讀為自動購買額度、變更模型／權限、部署或解除 device hold 的授權。

## 本機自動監看

已透過 Codex app 工具建立目前 chat 的 heartbeat：

- 名稱：**Bridge Academy 額度與交接監看**
- automation ID：`bridge-academy`
- 週期：每 15 分鐘
- 首次檢查：帳號工具回報 5 小時視窗及每週視窗 used 0%，各剩 100%；尚未觸發 30%。這不是永久數字，之後要重新讀取。
- 行為：可讀用量時檢查門檻，觸發時更新 current handoff；大於門檻且無 actionable 變化時保持安靜，不重跑昂貴測試、不修改功能 source。

本地排程依賴宿主可執行狀態；電腦／app 關閉、未登入、工具或網路不可用時不能保證即時監看。以失敗／UNKNOWN 明確記錄，不以讀取認證檔或其他未支援路徑補救。帳號用量為各 chat／專案共用，不能宣稱只計算 Bridge Academy。

管理既有監看時先查同 ID 的排程，不建立第二份。此文件不包含登入帳號 ID、Token、私牌或秘密；也不把帳號資料加入 App telemetry。

## 目前交接

[CURRENT_HANDOFF.md](handoff/CURRENT_HANDOFF.md) 是可接續的現況文件；即使尚未達門檻，也可在里程碑留下檢查點，但必須明確註明「非額度觸發」，不能虛構 30% 事件。
