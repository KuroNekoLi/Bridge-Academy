# UI、平台及產品工程驗收研究

更新：2026-10-26。將零散 Flutter／Chrome、A1～A6、B1～B6、C1～C3 驗收濃縮為玩家體驗與平台研究。完整功能清單在 [FEATURES](../implemented/FEATURES.md)。

## 已觀察到的進展

| 面向 | 受控證據與解讀 |
| --- | --- |
| Bridge Core | [CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/bridge-core.yml) 覆蓋 Auction、合法出牌、終局及計分；歷史 Pass Out 三次紀錄缺口不可自動補造 |
| 真 AI 完整牌局 | [Chrome → localhost Gateway → 真 BEN #38849429500](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38849429500) 有一副固定 52 張、13 墩端到端成功；不是公開主機多使用者 |
| 牌桌與工作區 | [Flutter Web／Chrome #40255094253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)：198 個測試、Web build／Chrome scoped PASS，新增打牌/學院/複盤/我的工作區、牌面 renderer 和叫牌手牌 |
| 窄屏牌列 | [後續 #40256171652](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40256171652)：200 個測試、Web／Chrome scoped PASS，手牌可橫向捲動、保留點擊大小；不是全桌動畫 UX 完成 |
| 本機持久化／歷史 | 有加密 checkpoint、replay、PBN 輸入輸出、搜尋統計及練習；不能當成 remote durable history |
| 練習與教學 | 四局、Just Declare、叫牌練習、非排名每日練習、學院、DDS 事後複盤已逐步有 scoped 工程驗收 | 

## 重要限制

Flutter Web 受控測試、Android 模擬器、Android/iOS 實機各是不同驗收層級；**使用者目前要求暫緩 A3.5 與裝置 QA**，不可在未明確批准前啟動，也不能稱為發行已通過。

`playing_cards 0.4.1+11` 已用於可見牌渲染，來源與 Apache-2.0 package license 已初審；未使用的內建 Wikimedia 圖像仍可能被打包，公開二進位檔發行前須逐項排除／查核。Flutter Widget 不接管發牌、Bridge Core 法則、完整暗牌或網路認證。

## 後續 UX 研究題目

U3：單屏佈局、可中止出牌/收墩動畫、合法目標與錯誤重試、320/375/768/1280px、2×字體及輔助科技。U4：持久 Gateway session/雲端 history，不能冒用本機 checkpoint 的測試成果。正式準入規格見 [產品路線](../planning/ROADMAP.md)。