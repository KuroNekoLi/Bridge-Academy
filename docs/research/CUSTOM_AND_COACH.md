# M4 自訂約定與 M5 叫牌教練研究

更新：2026-10-26。**工程功能已實作，完整可玩自訂 AI／最佳叫品教練未完成。**

## M4：安全的本機草稿

已實作 SAYC／2/1 有限 Convention Card 編輯、碰撞／Schema 驗證、不可變 SHA 鏈結 revision、版本 diff、fast-forward-only 備份匯入、公開 auction 上的使用者規則意義預覽、專家審查待辦。Gateway 對 `customDraft`、偽造 `SUPPORTED`、不符合法定 allowlist 的 profile 明確拒絕；已編輯卡標 `ENGINE_UNVERIFIED`，**不能改 BEN/BBA 的真實模型決策**。

實測：[M4 Domain 30/30 + Flutter 6/6 #40139400430](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139400430)；[Gateway 49/49 #40139293120](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139293120)。專家審查包的所有情境 **NOT REVIEWED／NOT RUN**，不是 100 個 expert Goldens。

## M5：來源可核對的公開叫牌教練

已實作 `PublicAuctionCoach`、雙語 Flutter 頁面、Gateway 完局公開 auction review。根據 dealer、公開叫品、NS/EW 固定 profile 與 fingerprint 顯示來源；無已驗證規則回 `UNKNOWN`，本機草稿標 `USER_DRAFT`。不讀別人的隱藏手牌，不宣稱解釋 BEN 內部推理。

[真 M5 CI #40154923631](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923631)：Conventions 36/36、Flutter Widget 5/5、analyzer PASS。真 AI 候選比較、來源專家核准、使用者手機完整 E2E 尚 **NOT RUN**。

## 仍未解決

需要可信的自訂約定引擎能力白名單、雙向 opponent-reader、artifact hash、迫叫／競叫／Alert 100+ 專家 Golden，才能准入可玩自訂制度。AI Coach 若要提供最佳叫品，須有可重現 BEN/BBA 及專家評分，不能虛構。

下一步與發行障礙見 [Roadmap](../planning/ROADMAP.md)／[Release](../planning/RELEASE_CHECKLIST.md)。