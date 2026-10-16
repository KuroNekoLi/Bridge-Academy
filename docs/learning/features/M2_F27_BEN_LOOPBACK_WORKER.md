# M2-F27｜A4.3.1：真正的 BEN 私有 Worker（Loopback Transport）

- Feature ID：M2-F27
- Milestone：A4.3.1
- 類型：Dart 後端／AI 整合／隱私信任邊界
- 工程狀態：SCOPED ENGINEERING VERIFIED（20/20 HTTP 與真正 BEN bid/lead/play CI PASS；非正式部署）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 實作：[BEN Loopback backend](../../services/bridge_gateway/lib/src/ben_loopback_backend.dart)
- 測試：[Worker HTTP tests](../../services/bridge_gateway/test/ben_loopback_backend_test.dart)

## 功能目的與實際情境

玩家的牌局請求經過 Gateway HTTPS POST 送達服務端，但真正 BEN Python API 仍使用包含手牌的 GET query。把這個 GET 暴露給網際網路，可能使私人牌張被 Proxy、APM 或日誌記錄。本切片只允許 Gateway 在**同一台電腦的 127.0.0.1／::1** 連接 BEN，對外永遠只回傳一個經格式檢查的 bid/card 建議，不能回傳 BEN 的除錯字串，也不能在 BEN 不可用時改用 Demo Bot。

## 主要程式碼導讀

`BenLoopbackBackend` 實作 `GatewayDecisionBackend`，先檢查 `bid / lead / play` 與允許欄位，再以 `Uri.replace(queryParameters: allowedFields)` 建立只供本機使用的 BEN URL。它明確拒絕非 literal loopback、HTTP redirects、非 200、過大／非法 JSON，並只投影 `bid` 或 `card` 字串。

```dart
if (origin.scheme != 'http' ||
    !const {'127.0.0.1', '::1'}.contains(origin.host) ||
    origin.userInfo.isNotEmpty || origin.hasQuery ||
    origin.hasFragment) {
  throw ArgumentError('BEN upstream must be a literal loopback HTTP origin');
}
```

`bin/serve.dart` 僅在設有 `BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085` 時啟用這個 Worker；沒有 BEN 或未設環境變數的 Gateway 保持 503。這是開發環境 opt-in，不會更動 Flutter 對外傳輸。

## 為什麼這樣設計

此層相當於 Kotlin/Ktor 的 Infrastructure Adapter：`GatewayDecisionBackend` 是 Port，`BenLoopbackBackend` 是 Adapter。不能單靠把 BEN URL 改成 `localhost` 的 DNS 名稱，或任意傳入 `BEN_BASE_URL` 讓 Gateway 向私人網段／外部網段發請求，否則可能產生 SSRF。禁止 Redirect 與 Proxy 並限定 literal loopback，才能將含私人牌張的 GET 限制在本機。

另一種方案是直接讓 Flutter 連 BEN GET。雖然少一層 Gateway，卻失去權限、速率限制與未來伺服器稽核，也可能洩露私人牌張。

## 驗證與實際證據

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

本切片測試會啟動**真的 Dart HttpServer** 充當 BEN API，並透過真的 Gateway HTTP 請求驗證 POST→BEN GET 的流程、只回傳 action、拒絕 `deal`、禁止外部 hostname、錯誤與 Redirect Fail Closed。這是「真 HTTP + Stub BEN」，**不是「真 BEN 神經網路模型」**。[Gateway CI #38837641317](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641317)：Dart analyze 無問題，**20/20 localhost HTTP 測試 PASS**；[真 BEN Gateway CI #38837641285](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837641285) 採 `lorserker/ben@72653ec1b5c17116faea229e9b975ea5622aa1f7`、Python 3.12，真正模型叫牌／首攻／明手出牌 **bid、lead、play 全部 PASS**。[Learning Gate #38837642035](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38837642035) PASS。這不代表 Gateway 完整 13 墩或雲端部署與實機驗收。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼限制只能呼叫 `http://127.0.0.1`，仍不能保證正式網路產品的玩家無法取得其他人的手牌？

**5–15 分鐘小練習：** 為 `BenLoopbackBackend` 的拒絕清單加上 `http://192.168.1.1:8085`，再讀 `origin.host` 白名單如何使測試在任何網路請求前就失敗。

**完成標準：** 能區分「Gateway 身分及流量控管」、「Worker 網路出口安全」、「實際牌局／座位授權」與「Bridge Core 合法性」。

## 下一步

A4.3.2 將匿名 Session 綁定權威牌局／座位，加入穩定 Request ID、預期事件版本與去重；沒有完成這些之前，不允許外網公開。A4.3.3 再針對 pinned BEN 做足夠的代表性真模型回歸、資源／逾時與授權檢查。Android/iOS 裝置 QA 與 A3.5 持續依使用者指示暫停。
