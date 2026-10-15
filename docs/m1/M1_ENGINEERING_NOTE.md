# M1 Engineering Note — 橋牌規則核心架構與學習重點

本文件面向已熟悉 Android、Kotlin、Compose 與單向資料流的工程師。先讀 packages/bridge_core/README.md 與 docs/m1/M1_IMPLEMENTATION_REPORT.md。

## 1. 為什麼把規則引擎獨立於 Flutter？

如果合法叫牌、出牌與計分寫在 Flutter Widget，之後的多人伺服器會需要重寫相同規則，造成雙方判定不一致。我們將其拆成純 Dart Domain Model：GameState + GameAction 經 BridgeGame.apply 變成新 GameState，或拋出 RuleViolation。

這類設計接近 Android 中 immutable UI state + reducer/use case，但遊戲的權威決策在 Core，UI 僅能提交操作請求。

## 2. 為何 Actor 與 Hand Owner 不同？

莊家操作明手時，實際作出選擇的是莊家，但打出的牌屬於明手位置。若只保存 playedBy，13 墩回放就失去了牌張真正的出牌位置。CardAction 因此同時包含 actor、handOwner 與 card，並驗證其關係。

## 3. Pass Out 與事件紀錄

四家輪流 Pass 的完整叫牌，必須有四個實際可追溯的 CallAction。先前 BEN Work 測試中，兩筆 API 判定 PASS、卻只列三個 Pass；Outcome 可接受，但 Transcript 無法視為完整。Bridge Core 不補寫假的第四次 Pass。

## 4. 事件回放與 immutable state

每個合法操作產生有序且帶版本的事件。完整 transcript 包含初始牌局 PBN、dealer、vulnerability、事件；重放時再走相同合法性檢查，不信任儲存內容提供的分數。

我們的 Fingerprint 只用於測試比較，不提供加密完整性或安全認證。

## 5. 計分視角

DuplicateScore 永遠回傳「南北得分」：正數表示 NS 得分，負數表示 EW 得分。例如 East 的 3NT 宕一、無身價：NS +50。如此可以避免 UI、分析報告、API 各自使用不同正負號。

## 6. 測試如何證明架構？

CI 實際在 Dart 3.13.5 上執行 dart analyze 和 dart test，30 個測試案例全部通過，其中一個案例依固定種子測試 100 副完整 52 張牌與 13 墩的狀態轉移，驗證事件回放與出牌合法性。

這些仍是 deterministic test strategy 的牌局，不是 BEN 真人程度 AI；不能用「合法走完」推出「AI 有橋牌實力」。

## 7. 面試延伸追問

**Q：為何不讓 BEN 決定最後計分？**  
A：BEN 是策略提案者，可能傳回非法操作或不完整資料。規則和得分必須由可單元測試的權威引擎獨立產生。

**Q：不可變狀態的成本？**  
A：每張牌會複製最多四組 13 張的集合，記憶體與 CPU 都有成本，但利於回放、重試、錯誤復原以及避免副作用。52 張牌的資料規模非常小。

**Q：Event Sourcing 和一般儲存當前狀態差在哪？**  
A：事件可以完整解釋如何到達目前狀態，也能重播查錯；相對地，需要版本相容、事件遷移、敏感資訊隔離以及重放效能考量。本階段只實作最小可測的事件封存，沒有宣稱具備完整商業級持久化。

**Q：多人模式是否可直接用這個 Package？**  
A：規則核心可重用，但仍必須建立 Server Authoritative Coordinator、身份驗證、seat 權限、冪等、重連與私有資訊投影。尤其完整 GameState 含四家手牌，絕不能直接序列化給玩家。

## 下一步自我練習

設計只能看到自己手牌與公開資訊的 PlayerView。你會如何處理 Dummy 公開前後的資訊變化？如何寫負向測試證明其他位置的 13 張牌從未出現在網路回應？

