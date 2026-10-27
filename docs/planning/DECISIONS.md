# 已核准產品／架構決策摘要

> 2026-10-26 統整。此處記**仍具約束力的決策**，不再保留重複編號、逐日流水帳；精確原始討論與 ADR 文字在整理前 Git commit `425da3ed393e6b9307f3d9961e52e542368c79e5` 的 `docs/DECISIONS.md`。修改約定、release gate 或架構時先更新本檔與測試；不要自行推翻使用者決策。

| 主題 | 核准內容 | 不得誤解 |
| --- | --- | --- |
| 核心橋牌法則 | 純 Bridge Core 擁有叫牌／出牌／計分，PlayerView 決定暗牌權限，固定 52/13 | AI 或 UI 不自行覆寫合法性；三個 Pass 的不完整 Pass Out 記錄不得虛構 |
| 版本管理 | 使用者希望可以直接 push `master`，不建立 PR；不 force-push；修改可 revert | 直接推不等於可省測試或覆蓋他人進度 |
| Learn While Building | 每項可測試新功能附教學說明、源碼位置、測試證據及小練習 | 文檔已從逐功能多份改為 [單一累積工程筆記](../implemented/ENGINEERING_NOTES.md)；不宣稱未經練習已掌握 |
| 主要產品 | 先可用單人牌桌→練習→複盤，再持續改善 UX、安全續局與託管，最後排名／多人 | 早期工程里程碑 M4「多人」不等同制度軌 M4「自訂卡」 |
| 裝置 QA | A3.5 玩家驗收、Android emulator、Android/iOS 真機 E2E **Owner hold** | 只有使用者之後明確同意才可恢復；hold 不是 pass |
| Gateway | 不讓外界直接接到 BEN；一局由伺服器擁有 Game，靠 token、版號、事件與限定重試維護狀態 | localhost scoped success ≠ 正式 TLS identity／跨節點 durability |
| 兩制度 | 2/1 Game Force／SAYC 可分別在 NS/EW 選擇，不可變 profile revision/fingerprint；對應真 BEN 選型 | 並非讓任意 string 註冊成 playable system；正式對局品質仍待專審 |
| Precision | 唯一 V1：`BA-PRECISION-MECKWELL/r1`、BBA Meckwell `1NT 13–15 HCP`、釘選原生卡／binary | 不與外部 Meckwell Lite 13–16 混用；BBA native 研究 ≠ 正式神經網路 AI |
| 自訂 Convention Card | 受限本機草稿、鏈結版本、diff、review，可儲存／匯入；改動後 `ENGINE_UNVERIFIED` | 未有真 provider/opponent reader/Golden，不可開始真 AI 遊戲 |
| Coach | 只信有來源的公開叫牌與已簽核語義，未知 `UNKNOWN`，草稿 `USER_DRAFT` | 不從 AI 文案捏造最佳叫品／內部 reasoning |
| 每日挑戰 | 早期可以有**本機固定牌局、未排名練習** | 比賽／MP/IMP／排行榜須等 server 公平 BoardSet |
| DDS／資料安全 | 只在完局、或明確獨立授權的教學牌例做雙明手分析；含私牌請求與 token 不得記入公開 log | 不偷看進行中玩家或對手未開手牌 |
| 開源與模型權利 | 源碼授權 ≠ 模型 weights ≠ 原生程式庫 ≠ 圖像授權；需逐項保存確切 artifact/provenance | 使用者表示已取得 BBA 使用許可，但仍需逐項文件化可發行範圍與 notices |
| 發行 | Release NO-GO 直到目標 VPS、安全、license、裝置與真人 UX 各關卡簽核 | GitHub Actions PASS 只限其 fixture／環境 |
| 配額與交接（2026-10-26） | 如宿主可提供 `get_usage_limits`，開始／里程碑／完成前核對，任一剩餘 ≤30% **先寫交接**再做重大工作；工具未知要標 UNKNOWN，不能猜；不重複提醒 | 不得讀憑證繞過工具、不保證機器關閉仍監測、不將下列文檔視為可解除政策 |

## 用量規則細節

## 2026-10-26：Reuse First UI 與 Nickel Bridge 授權

Owner 明確要求：新增 UI 前優先調查現成套件／開源橋牌專案及授權；牌面用 playing_cards，手牌排列先評估其 FlatCardFan，拖放／移動／翻牌優先評估 card_game，四人桌／明手／叫牌流程優先完整研究 Nickel Bridge，可參考 bridgegui 與 Flutter 官方 Card Template。只有不適配時才自製，並在 RESEARCH_REPORTS 說明。Owner 已表示取得 Nickel Bridge 完整授權、可自由修改；這是 owner 授權聲明，不偽造已閱合約或傳遞其他第三方資產權利。

保留 Bridge Academy 的 Core、BEN、2/1／SAYC／Precision 身分與計分。外部元件只接授權 PlayerView、公開事件與 action intent；不引進第二個規則權威。下一次低額度恢復後，先做重用適配 PoC／替換比較，再擴寫現有手製互動。四家 13 張展示只限獨立公開 fixture；真人／AI 一般對局不把暗牌傳給 UI。Web／桌面工程可測，Android／A3.5 仍 HOLD。現有 F57–F59 實作保留為可回退技術基線，不宣稱已採用 card_game 或移植 Nickel。

`remainingPercent = clamp(100 - usedPercent, 0, 100)`，所有 primary/secondary 限額都要看，優先 `rateLimitsByLimitId`；缺失是 UNKNOWN。持續工作至少每 15 分鐘核對（宿主工具可用時）。任一剩餘 ≤30%：**優先**更新 [CURRENT_HANDOFF](CURRENT_HANDOFF.md)（branch/SHA、工作樹、已完成/待辦、可重現命令、實測狀態、風險與回退），通知使用者，改做安全收尾；不可藉此執行未授權部署、額度購買、重置資料或解除 QA hold。若宿主沒有用量工具，要明確標 UNKNOWN 並備妥交接，不能捏造數字。

## 決策更新機制

新增一項會影響產品功能、橋牌語義、資安、模型版本或正式發行標準的決策時：在本文件追加「日期／決策／替代方案／原因／影響範圍／使用者核可」；標準不因同一命名的歷史計畫而降低。

## 2026-10-26：docs 總量不得超過十份

**使用者明確決策**：`docs/` 只保留「已實現的功能、接下來的產品規劃、研究報告」，總數最多 10，越精簡越好。將 190 份整併為 7 份；重複的逐功能驗收、逐次交接與規劃流水帳從當前 `master` 刪除，但原始版本保留在 Git 歷史，沒有執行 `git filter-branch`、`push --force` 或刪除 repo 的原始程式／測試／CI。保留安全不變條件、啟用限制、權利證據與原始 CI URL。後續**不要再為每個 Feature 產生新 docs 檔**；只增補既有功能清單、工程導讀、路線或研究整合報告。

**重要提醒**：額度檢查與必要交接記錄放同類的 `planning/CURRENT_HANDOFF.md`；不把它當新第四種文件分類。 


## 2026-10-27：手機完整扇形手牌優先

Owner 再次提供 BBO 手機介面，明確要求全13張可見、上下明手／自己，以及可把非Flutter開源UI移植成Flutter。專注桌的手機預設因此改為壓縮扇形：不足48px可見區時先選牌抬起、第二點或確認鈕才提交；另保留寬牌列切換與大字體捲動退路。這修訂 F60 的「手機一律48px寬牌列」呈現選擇；授權投影／Core驗證、Reuse First、裝置QA HOLD不變。參考 pinned Nickel HandFan 的 selected／second-tap interaction，以既有 FlatCardFan／PlayingCardView 整合，未複製 React runtime 或第三方素材。
