# M3-F17｜讓 Precision AI 根據真正的叫牌約定推論來出牌

- Feature ID：M3-F17
- Milestone：M3.6（M3.4/3.5 後續研究）
- 類型：BBA Native `find_info`、有限資訊推論、合法 CardAction 策略、Mock/Real 分層驗收
- 工程狀態：**SCOPED VERIFIED（研究啟發式）**；非競賽級神經網路 AI
- 學習狀態：**DELIVERED**
- 原始碼：[Dart 策略](../../../packages/bridge_precision_adapter/lib/src/bba_research_table_policy.dart) · [private transport](../../../packages/bridge_precision_adapter/lib/src/bba_precision_loopback_transport.dart) · [Native inference](../../../scripts/precision_m33_sidecar.py)
- 驗收與測試：[策略測試](../../../packages/bridge_precision_adapter/test/bba_research_table_policy_test.dart) · [Python Mock](../../../scripts/test_precision_m34_table.py) · [Real EPBot Smoke](../../../scripts/precision_m36_native_inference_smoke.py) · [完整牌局](../../../services/bridge_gateway/bin/live_precision_research_full_game.dart)
- 技術說明：[M3.6 研究驗收](../../research/M3_6_PRECISION_CONVENTION_AWARE_CARDPLAY.md)

## 功能目的與實際情境

之前 BBA Meckwell 確實會按照 Precision 1♣ 叫牌，但它叫完之後，Bridge Academy 仍用 `DeterministicTrainingBot` 出牌——有可能永遠先打一張排序最前面的牌，**完全不理會搭檔有沒有暗示長紅心**。

這一步先不冒充 BEN 的完整防禦神經網路，而是利用 pinned 上游 BBA 的 `BBABotBid.find_info(auction)`：在**不偷看對手底牌**的前提下，依照正式 `.bbsa` 約定卡與公開叫牌，取得對四家 C/D/H/S 花色長度的「推估」，再用它調整合法出牌的花色選擇。

## 主要程式碼導讀

```text
BridgeGatewayService 仍驗證並固定 NS/EW GameSystems
 → SinglePlayerCoordinator 僅給 BotPolicy 輪到的 PlayerView
 → BbaResearchTablePolicy._chooseInformedCard(view)
 → POST /v1/precision/auction-inference
 → Python NativePrecisionEngine.auction_inference()
 → BBA BBABotBid.find_info(public auction)
 → {N/E/S/W: {C: expected length, D: ..., H: ..., S: ...}}
 → Dart strict validates V1 card hash / source / 16 estimates
 → rank(view.legalCards): ownLength*2 + partnerEst*3 - opponentEsts
 → one proposed CardAction → BridgeGame.apply(...)
```

這段公式是**明確標示的探索用啟發式**，不代表橋牌專家建議的防禦最佳解，也不代表已學會訊號、擠牌、飛牌或雙明手分析。在 Dart 裡用 `PlayerView.legalCards` 當候選集合，並且檢查所有候選都屬於自己或已公開明手，不讓 BBA 模型直接更新 GameState。

完成叫牌後，現在可能由任何一座位出牌；因此 native API 與叫牌中的「目前輪到哪個 bidder」驗證**分開設計**。`auction_inference` 只允許合法合約以三張 Pass 結束，而不是在競叫中途盲目推斷全套牌局。原生 payload 只有一手牌與公開資訊，輸出的預估數值必須落在 0 到 13，且 **不能當成別人的真實私牌**。

## 為什麼這樣設計

與 Kotlin/Android 的 **Strategy + typed DTO + domain validation** 相同：外部原生服務負責提出推論，應用層負責看是否可信，Domain/Core 決定是否合法。即便 EPBot 說「打 C2」，如果自己根本沒有 C2 或違反跟牌規則，Bridge Core 仍拒絕。

考慮過直接將 `theirSystem=PRECISION` 傳給 BEN `/play`，但固定 BEN 版沒有這個 opponent reader；等於「讓 AI 用錯的系統理解叫牌」，不採用。也考慮過把 DDS 四家牌塞給出牌 AI，但那是雙明手作弊，與公平玩家的單明手對局根本不同。

**常見錯誤**：模型預估某人紅心 5 張，不代表此人真的持有 5 張！這是依已公布約定與上下文推論的機率性訊息，不可以寫成已知其他座位手牌、對使用者洩漏，或用來報出不合法 CardAction。

## 驗證與實際證據

```bash
cd packages/bridge_precision_adapter
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded

cd ../..
python -m unittest discover -s scripts -p 'test_precision_m34_table.py' -v

# 啟動固定上游真正的 BBA worker，再做真 native：
python scripts/precision_m36_native_inference_smoke.py
cd services/bridge_gateway
dart run bin/live_precision_research_full_game.dart
```

證據標記必須分開：
- **Mock unit**：給同一副測試牌兩組不同的「搭檔最長花色」估值，確認 Dart 出牌花色會跟著改變；改成超出 0..13 的錯誤數值則拒絕。
- **Real native**：只有 GitHub Actions 完整通過 pinned EPBot `find_info` + private API + 固定 Bridge Core 對局，才可以標示 SCOPED REAL-PASS。
- **NOT RUN**：重新訓練神經網路、100+ 專家 Golden、1000 場真正亂數全局、對手防守訊號評分及 4GB 目標 VPS。

上次原生研究驗證成功的先例：[M3.4/M3.5 #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733)，但那輪仍是**舊的 deterministic 出牌策略**，不可將它作為新 inference 的執行證據。以後續 [M3.6 工作流程](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m34-m35-research.yml) 的實際跑完狀態為準。

### 真實執行結果補充（2026-10-24）

**M3.6 native [CI #40105927916](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105927916) completed SUCCESS**：Dart Domain **10/10**、Adapter **12/12**、Gateway **47/47**、Python schema **5/5**；真 BBA `find_info` 單獨 4/4 成功、無效呼叫 2/2 拒絕。四種 Precision/SAYC/21GF NS/EW 配置，各完整 52 張／13 墩，每局真 native `auctionInference` **52 次**，總計 **208 次 BBA 原生推論往返**，不是 Mock。Native 開叫另有 1,000/1,000 種子呼叫成功（與 208 次出牌推論屬**不同的測試**）。

這份驗證**只有真正的制度解讀＋確定合法的 heuristic**。沒有證明神經牌力、實際 Precision 弱點克制、MP/IMP 大樣本勝率，亦尚未部署 VPS。

### 延伸查證：真實強梅花的關鍵侷限

[CI #40106500046](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40106500046) 新增 `1C-P-1D-P-1N-P-3N-P-P-P` 完成叫牌測試，6/6 Native `find_info` 請求成功。但在固定例中，交換哪一方使用 Precision 後 **16 個花色 `probable_length` 預測全部不變**。因此能證實 API 連動與合法牌策略受估值影響，**不能**只憑這個結果說「BBA 已在這副牌上展示人工強 1♣ 的語義區辨」。這也說明需要看 HCP/meaning/alert 或多組 expert golden，而不是以 Mock 和接口成功率代替制度正確性。

## 練習與自我檢驗

**思考題（1 題）：** 如果原生 BBA 說「搭檔可能有 6 張紅心」，但 Bridge Core 只允許你跟黑桃，你的 AI 可以出紅心嗎？為什麼？

**5–15 分鐘練習（可選）：** 修改 `bba_research_table_policy_test.dart` 的假資料，分別令 West 的 H 或 C 預估為 13。確認 East 在相同 3NT 開局合法牌中選擇了不同花色；然後嘗試把估值改成 -10，驗證 fail-closed。

**完成標準：** 能說清楚「約定解讀的花色預測」與「看得到的真牌」、「候選策略」與「Bridge Core 合法性」是兩層不同的資訊。

## 下一步

建置真正 single-dummy Precision-aware cardplayer（含可能牌張分布與防守訊號），用 expert reviewer 與相同種子大量對局評估牌力，不能以此 heuristic 取代完整 AI/商用釋出驗收。
