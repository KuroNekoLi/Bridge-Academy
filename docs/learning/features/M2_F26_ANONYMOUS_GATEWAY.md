# M2-F26｜A4.2：匿名短效 Session、API 授權與 Rate Limiting

- Feature ID：M2-F26
- Milestone：A4.2 Local Gateway
- 類型：Dart Backend／安全 API／無狀態客戶端
- 工程狀態：IMPLEMENTED（第一輪 CI lint 修正後，第二輪 #38836007368 localhost 測試的 HttpClient Headers 設定順序錯誤；已修復，待再次 CI）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 原始碼：`services/bridge_gateway/lib/src/gateway_service.dart`
- 驗收與測試：`services/bridge_gateway/test/gateway_service_test.dart`、`docs/product/A4_GATEWAY_A4_2_ACCEPTANCE.md`

## 功能目的與實際情境

不強制使用者註冊的橋牌 App 仍需要防止任何人無限制消耗 BEN 運算。新的 Gateway 可以先發一張效期有限的匿名憑證，再對每次 AI 建議請求檢查 bearer token，拒絕超量／未知欄位，必要時清楚回傳錯誤。開發版只允許 127.0.0.1，預設沒有真 BEN，因此請求結果應是 503 而不是假的牌。

## 主要程式碼導讀

最小流程：`BridgeGatewayService.start` 綁定 loopback → `_handle` 控制合法路由、Origin、Content-Type、JSON 大小 → `_issueSession` 隨機發短效 token，只存 SHA-256 → `_requestDecision` 驗證 token／expiry／quota，再檢查公開 BEN 欄位、呼叫注入的 GatewayDecisionBackend。回應只包含 `version + decision.bid/card`：

```dart
if (session == null || !session.expiresAt.isAfter(now)) {
  throw const GatewayFailure(401, 'unauthorized');
}
if (++session.used > _config.decisionLimit || session.inFlight) {
  throw const GatewayFailure(429, 'rate_limited');
}
session.inFlight = true;
try {
  // Future A4.3 backend, current default returns 503.
} finally {
  session.inFlight = false;
}
```

**HTTP Token 發行** 與 **玩家實際有權操作哪一張牌** 是兩種不同權限：此階段的憑證只允許消耗受限額度，還無法證明某人的 Seat/Deal。Bridge Core 必須繼續驗證合法行動；正式多人競賽更需要服務端權威。

## 為什麼這樣設計

對 Android/Kotlin 工程師而言，這類似 Ktor 的 Routing + authentication middleware + rate-limiting interceptor；但目前用 Dart `HttpServer` 保持部署獨立與低依賴，暫不引入資料庫或第三方雲。選擇 `Random.secure` 的高熵 Token，狀態僅存雜湊可降低意外記憶體 dump 暴露明文的範圍，但不代表已經做完整的身份驗證。

替代方案是直接給每個 Flutter App 一把共用長期 API Key：容易被逆向取得，也無法控制不同使用者的額度。另一個常見錯誤是相信 `X-Forwarded-For` 來判斷 IP，卻沒有先驗證可信反向代理；原型只使用實際 TCP Peer IP，等未來部署時才設計代理可信來源。

## 驗證與實際證據

```bash
cd services/bridge_gateway
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
dart run bin/serve.dart
```

新增 localhost HTTP 整合測試含：兩次 token 不同、過期／偽造 token、匿名發行與決策請求速率限制、偽造 XFF、未知欄位 `deal`、未公開 Dummy 提早輸入、CORS、8KiB body cap、並發請求、BEN 未連接 503、上游帶敏感字串的錯誤遮蔽。**目前使用 FakeBackend，非真 BEN，也沒有正式公開服務。[CI #38835869874](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38835869874) 首次 analyze FAIL（測試建構子 lint）已修正；[CI #38836007368](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38836007368) analyze PASS、HTTP Test FAIL（測試 `req.write` 後才設定 Authorization Header，HTTP Headers 已鎖定；修正 Headers-first）。**下次 CI 未完成前不得宣稱 PASS****。裝置 UI/實機測試不在本階段。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼匿名短效 Bearer Token 已通過驗證，仍然不能直接代表「玩家 North 有權得知 East 的手牌」？

**5–15 分鐘小練習：** 在 `gateway_service_test.dart` 中找 `X-Forwarded-For` 測試，解釋為什麼兩次使用不同的 XFF 卻仍應受到同一個 Rate Limiter 約束。

**完成標準：** 能分清楚 Session 能力、資料層授權、Bridge Core 合法性，以及 Rate Limiting 的職責。

## 下一步

A4.3 在非公開網路環境下加入真 BEN Worker、穩定請求 ID 與版本去重／超時控制；高成本正式部署需在容量、授權與主機預算確認後再做。
