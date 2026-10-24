# M3-F09｜M2.5：真 BEN 混合制度整局驗證

- Feature ID：M3-F09
- Milestone：Multi-System M2.5
- 類型：真實 AI E2E
- 工程狀態：IMPLEMENTED；詳細執行證據見驗收紀錄（真模型結果須單獨核對）
- 學習狀態：DELIVERED
- 原始碼：[實作](../../../services/bridge_gateway/bin/live_gateway_multisystem_full_game.dart)
- 驗收與測試：[測試或 CI](../../../.github/workflows/ben-m2-multisystem-real.yml)

## 功能目的與實際情境
獨立 CI 使用固定 BEN upstream commit，將同一 PBN 交給 server-owned Gateway。各跑 NS 2/1 + EW SAYC 和反向配置，驗證 52 張唯一牌、13 墩、叫牌及計分，並確認舊 request ID 重送不會重複套用。

## 主要程式碼導讀
主要入口是 services/bridge_gateway/bin/live_gateway_multisystem_full_game.dart。資料流：在開局／輪到機器人時先核對安全版本 → 檢查配置與被允許的玩家視角 → 產生對應參數或狀態 → 由安全的 Gateway/Bridge Core 邊界處理。實際程式請以連結為準；不宣稱未執行的測試成功。

## 為什麼這樣設計
Mock 只能證明介面可運行，不足以證明真實模型、牌局規則與服務全程整合。完整一局 PASS 也不能代替專家對所有叫牌約定的評核。
替代方式是直接相信 UI 選單或記住某一個全域預設模型；這會造成多局並行、重啟或切換座位後制度漂移，因此本輪不採用。錯誤處理選擇 Fail Closed，拒絕假裝模型已切換。

## 驗證與實際證據
實作：services/bridge_gateway/bin/live_gateway_multisystem_full_game.dart；測試：.github/workflows/ben-m2-multisystem-real.yml。執行環境是 GitHub Actions 的 Dart/Flutter 與隔離 BEN，和正式部署不同。真實 CI 連結及通過/失敗狀態記錄於 [M2.2–M2.5 驗收](../../research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md)。真實 BEN 完整對局不得由 mock 測試推論，未成功以前維持 NOT VERIFIED。

## 練習與自我檢驗
**思考題（1 題）：** 為何真 BEN /bid 回 200，不等於整場橋牌已通過驗收？
**5–15 分鐘小練習（可選）：** 閱讀上述測試，補一個拒絕非法制度版本的測試，或確認目前資料流不會傳遞未公開的另外三家手牌。
**完成標準：** 能區分前端選擇、伺服器權威、模型真實行為及 Bridge Core 合法性。未實際練習前維持 DELIVERED。

## 下一步
依照 M2.2→M2.5 完成測試追蹤；後續 Precision、自訂約定和正式 VPS 部署需獨立授權與 Release Gate。
