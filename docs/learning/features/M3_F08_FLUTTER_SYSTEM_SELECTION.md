# M3-F08｜M2.4：Flutter 開局制度選擇

- Feature ID：M3-F08
- Milestone：Multi-System M2.4
- 類型：Flutter UI
- 工程狀態：IMPLEMENTED；詳細執行證據見驗收紀錄（真模型結果須單獨核對）
- 學習狀態：DELIVERED
- 原始碼：[實作](../../../apps/bridge_academy_flutter/lib/src/gateway_table.dart)
- 驗收與測試：[測試或 CI](../../../apps/bridge_academy_flutter/test/m2_system_choice_test.dart)

## 功能目的與實際情境
GatewayTable 提供南北／東西兩個下拉選單，含舊 BEN、2/1 和 SAYC。開局前以 ID 提交，GatewayGameSession 以 GameSystems.fromTrustedJson 驗證伺服器的指紋；進行中的遊戲選單停用。AppCopy 提供繁體中文及英文。

## 主要程式碼導讀
主要入口是 apps/bridge_academy_flutter/lib/src/gateway_table.dart。資料流：在開局／輪到機器人時先核對安全版本 → 檢查配置與被允許的玩家視角 → 產生對應參數或狀態 → 由安全的 Gateway/Bridge Core 邊界處理。實際程式請以連結為準；不宣稱未執行的測試成功。

## 為什麼這樣設計
UI 的選擇是預先偏好，不是正在對局的權威狀態；和 Compose 的 State Hoisting 一樣，後端已接受的不可變 GameSystems 才是正式來源。
替代方式是直接相信 UI 選單或記住某一個全域預設模型；這會造成多局並行、重啟或切換座位後制度漂移，因此本輪不採用。錯誤處理選擇 Fail Closed，拒絕假裝模型已切換。

## 驗證與實際證據
實作：apps/bridge_academy_flutter/lib/src/gateway_table.dart；測試：apps/bridge_academy_flutter/test/m2_system_choice_test.dart。執行環境是 GitHub Actions 的 Dart/Flutter 與隔離 BEN，和正式部署不同。真實 CI 連結及通過/失敗狀態記錄於 [M2.2–M2.5 驗收](../../research/M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md)。真實 BEN 完整對局不得由 mock 測試推論，未成功以前維持 NOT VERIFIED。

## 練習與自我檢驗
**思考題（1 題）：** 玩家中途改選 SAYC，為何不能直接修改同一局的 GameSystems？
**5–15 分鐘小練習（可選）：** 閱讀上述測試，補一個拒絕非法制度版本的測試，或確認目前資料流不會傳遞未公開的另外三家手牌。
**完成標準：** 能區分前端選擇、伺服器權威、模型真實行為及 Bridge Core 合法性。未實際練習前維持 DELIVERED。

## 下一步
依照 M2.2→M2.5 完成測試追蹤；後續 Precision、自訂約定和正式 VPS 部署需獨立授權與 Release Gate。
