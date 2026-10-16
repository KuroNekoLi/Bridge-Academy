# M2-F31｜A4.4：Flutter 接入伺服器權威牌局及斷線重送

- Feature ID：M2-F31
- Milestone：A4.4
- 類型：Flutter／HTTP Client／狀態恢復／安全 API
- 工程狀態：ENGINEERING_VERIFIED（Flutter CI 86/86 + Web/Chrome Demo PASS；真 Chrome→Gateway→BEN 全場新測試待 CI）
- 學習狀態：DELIVERED（尚非 PRACTICED 或 MASTERED）
- 原始碼：`apps/bridge_academy_flutter/lib/src/gateway_http_api.dart`、`gateway_game_session.dart`、`gateway_table.dart`、`packages/bridge_core/lib/src/player_view.dart`
- 驗收與測試：`apps/bridge_academy_flutter/test/a4_gateway_integration_test.dart`、`docs/product/A4_GATEWAY_A4_4_ACCEPTANCE.md`

## 功能目的與實際情境

玩家按「1NT」時，伺服器可能已經記錄這個叫牌，但 HTTP 網路突然斷線。假設 Flutter 直接新增 Request ID 再送，就可能出現「重複提交」或被事件版本衝突拒絕。這個階段改用真正的 Gateway Session：手機／瀏覽器從伺服器拿短效匿名 Token，畫面只顯示對 North 合法公開的 PlayerView；任何 Bot 回合都由伺服器自己選出 BEN 對應座位。**Gateway 失敗不會偷偷變成 Demo Bot**。

## 主要程式碼導讀

`GatewayHttpApi` 只允許四條白名單 JSON POST 路由，Bearer 放 `Authorization` Header，防止 Token／Hand 進 URL。`GatewayGameSession` 將同一個 Action（端點、Request ID、Expected Version）保存在記憶體中；如果網路失敗，UI 提供「查詢伺服器牌局」和「重試原請求」，絕不產生新的 ID 偷偷重出牌：

```dart
final pending = _Pending(route, Map.unmodifiable(payload));
_pending = pending;
await _sendPending(pending); // If network fails, _pending stays.
```

重試時原樣送出 pending，伺服器必須用它的幂等紀錄回傳之前成功的結果。`PlayerView.fromJson` 只解析公開投影，不允許額外 `deal/hands/transcript` 欄位；`GatewayTable` 重用原來的牌桌／叫牌控制元件，Bot 和完整 GameState 仍然不在 Flutter 裡。

## 為什麼這樣設計

這與 Android/Kotlin 的 MVVM + Retrofit/OkHttp 類似：Repository 封裝 HTTP 認證和 DTO 檢查；`ChangeNotifier` 對應 ViewModel 的 StateFlow，Widget 只繪製合法視角。要小心的不是網路錯誤本身，而是**發生在伺服器提交之後、客戶端接收回應之前**的錯誤；此時唯一安全的下一步是查詢權威版本、並以原 Request ID 做有明確去重保證的重送。

把 Bearer 保存到 SharedPreferences 可實現瀏覽器關閉再開時續局，但會新增 XSS、權杖保存與失效同步風險；此切片刻意只採記憶體，頁面重整後需開始新牌局。這不是永久 Session 功能。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter build web --release
```

新增 MockClient + Widget 測試：安全 Origin 驗證、Gateway 啟動與 view、伺服器提交成功但 HTTP 回應遺失時用同 Request ID 恢復、401 Token 過期、惡意回應包含 `hands` 的隱私拒絕，以及雙語 UI。其他 Demo/Chrome 與真正 BEN Gateway 全場測試分開驗證。[首次 Bridge Core CI #38847385042](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38847385042) FAIL：新增解析器時的文字置換將原本的 PlayerView 類別展開在正規表示式當中，使 300+ 筆 analyzer 警告／錯誤；這是編輯錯誤，不是原始 Bridge Core 失效。已從 Git commit `49772b6` 的 canonical 原檔重建並正確加入解碼 factory，Core 修正後 [Bridge Core CI #38847678253](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38847678253) 已 PASS；[Flutter CI #38847830454](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38847830454) 嚴格分析剩三項單行 if 大括號與一項測試 Map lint，已修正待新一輪 CI；**修正後 Flutter CI [#38848030915](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915) 通過：`flutter analyze` 乾淨、86/86 Unit/Widget 測試、Web Release Build、真 Chrome Demo／加密存檔回歸全部 PASS；[Learning Gate #38848030896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030896) PASS**。這仍未證明真 Flutter Gateway full-game 或公開部署。另新增 `integration_test/browser_gateway_real_test.dart` + pinned BEN Chrome 工作流程，使用 Chrome Web-Server 固定 8000、Gateway 127.0.0.1:8086，檢查玩家從按開始、3NT 叫牌直到 52 張牌打完。這項新真模型 E2E **待 CI**。不可將 MockClient 等同真 BEN，也不會恢復 Android／iOS 實機／模擬器測試。

## 練習與自我檢驗

**思考題（1 題）：** 如果玩家的叫牌已經寫入伺服器，但 Flutter 因為 timeout 沒收到回應，為什麼按「重試」時必須使用原來的 `request_id`，而不是產生新的 ID？

**5–15 分鐘小練習：** 打開 `a4_gateway_integration_test.dart`，找出在伺服器提交完叫牌後刻意丟出網路錯誤的測試。說明 `refreshServerView` 和 `retry` 分別做什麼。

**完成標準：** 能區分伺服器權威 GameState、僅可見 PlayerView、事件版本、Request ID 去重、Token 生命週期與 Widget 狀態；且知道目前尚無持久 Token 和公開正式 Gateway。

## 下一步

A4.4 完成 CI 後，要補真實 Flutter Chrome→localhost Gateway→真 BEN 的端到端驗收，並進行 A4.5 HTTPS、流量/容量/模型授權/成本及部署。A3.5、Android／iOS 裝置 UI/E2E 仍待使用者另外授權。
