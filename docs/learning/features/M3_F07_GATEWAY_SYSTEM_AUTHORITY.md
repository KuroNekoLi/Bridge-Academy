# M3-F07｜M2.3：Gateway 版本綁定與真能力檢查

- Feature ID：M3-F07
- Milestone：Multi-System M2.3
- 類型：安全後端
- 工程狀態：IMPLEMENTED；詳細執行證據見驗收紀錄（真模型結果須單獨核對）
- 學習狀態：DELIVERED
- 原始碼：[實作](../../../services/bridge_gateway/lib/src/gateway_service.dart)
- 驗收與測試：[測試或 CI](../../../services/bridge_gateway/test/m2_system_routing_http_test.dart)

## 功能目的與實際情境
Gateway 開局只接受已登錄的 northSouth/eastWest profile ID；revision 與 engine 一律伺服器決定。BenLoopbackBackend 需要 operator pin commit 且本機 BEN GET / 宣告兩模型可玩。AuthoritativeGame 在每次 action 前重驗，不符合回 503，不會偷回預設 GIB。

## 主要程式碼導讀
主要入口是 services/bridge_gateway/lib/src/gateway_service.dart。資料流：在開局／輪到機器人時先核對安全版本 → 檢查配置與被允許的玩家視角 → 產生對應參數或狀態 → 由安全的 Gateway/Bridge Core 邊界處理。實際程式請以連結為準；不宣稱未執行的測試成功。

## 為什麼這樣設計
信任邊界要區分 UI 的請求與伺服器授權；資料 fingerprint 也不能證明某台 BEN Worker 現在能執行。像 Android 的遠端 feature availability 必須獨立查詢。
替代方式是直接相信 UI 選單或記住某一個全域預設模型；這會造成多局並行、重啟或切換座位後制度漂移，因此本輪不採用。錯誤處理選擇 Fail Closed，拒絕假裝模型已切換。

## 驗證與實際證據
實作：services/bridge_gateway/lib/src/gateway_service.dart；測試：services/bridge_gateway/test/m2_system_routing_http_test.dart。執行環境是 GitHub Actions 的 Dart/Flutter 與隔離 BEN，和正式部署不同。真實 CI 連結及通過/失敗狀態記錄於 [M2.2–M2.5 驗收](../../research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md)。真實 BEN 完整對局不得由 mock 測試推論，未成功以前維持 NOT VERIFIED。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼 encrypted checkpoint 的版本沒有改，仍需要在重啟後再次驗證 BEN？
**5–15 分鐘小練習（可選）：** 閱讀上述測試，補一個拒絕非法制度版本的測試，或確認目前資料流不會傳遞未公開的另外三家手牌。
**完成標準：** 能區分前端選擇、伺服器權威、模型真實行為及 Bridge Core 合法性。未實際練習前維持 DELIVERED。

## 下一步
依照 M2.2→M2.5 完成測試追蹤；後續 Precision、自訂約定和正式 VPS 部署需獨立授權與 Release Gate。
