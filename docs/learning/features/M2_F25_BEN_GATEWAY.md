# M2-F25｜A4.1：安全的 BEN Gateway Transport

- Feature ID：M2-F25
- Milestone：A4.1 Production BEN Client Contract
- 類型：Dart／HTTP 安全、依賴注入
- 工程狀態：ENGINEERING_VERIFIED（僅 Adapter MockClient，非真 Gateway／正式產品）
- 學習狀態：DELIVERED（非 PRACTICED／MASTERED）
- 原始碼：`packages/bridge_ben_adapter/lib/src/ben_gateway_transport.dart`
- 測試：`packages/bridge_ben_adapter/test/ben_gateway_transport_test.dart`

## 功能目的與實際情境

本機 BEN 的 GET 把 AI 玩家自己的手牌放到 Query URL；公開服務的 Proxy、APM 可能記錄 URL。A4.1 為正式產品預留 HTTPS POST 的 Gateway Client，不再把手牌或 Token 放在 URL。**實際 Gateway 尚未部署，Flutter App 也還沒切換。**

## 主要程式碼導讀

```dart
final gateway = BenGatewayTransport(
  baseUri: Uri.parse('https://approved.example'),
  accessTokenProvider: () async => trustedSessionToken,
);
final response = await gateway.get('/bid', allowedFields);
```

名稱 `get` 是繼承現有 `BenTransport` 相容性介面，網路操作仍是 POST。流程是：檢查 route/欄位 → 讀取未來後端發行的短效 Session Token → POST JSON → 拒絕錯誤／超時／非 v1 回應 → 交給 BenBotPolicy 與 Bridge Core 驗證。UI 只顯示通用錯誤，避免印出私人牌或 Token。

## 為什麼這樣設計

類似 Android Kotlin 的 Repository 搭配 OkHttp 認證 Interceptor／Retrofit API，依賴注入容易 Fake Client 測試；不同點是 Dart `BenTransport` 先保留既有 interface，不在 Flutter 重寫 BEN 規則。替代方案將遠端網址直接塞給舊 GET：HTTP Query 洩漏且沒有 Gateway 保護；另一錯誤是把長期 API Token 寫進 `--dart-define`，前端編譯常數不是安全秘密儲存空間。

## 驗證與實際證據

```bash
cd packages/bridge_ben_adapter
dart pub get
dart analyze --fatal-infos
dart test --reporter expanded
```

MockClient 測試範圍：POST 而非 GET、URL 無敏感資訊、失效授權、route/field allowlist、無明手先傳入測試、401/403/429/503、Redirect、Timeout、過大／無效 JSON。初次 [Adapter CI #38832931786](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38832931786) 在 analyze 時發現 Mock 測試 headers 需傳非 null Map，已修正。修正後 [Adapter CI #38833132162](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38833132162) **Dart Analyze 無問題、23/23 套件測試 PASS**（包含新 Gateway MockClient 測試）。正式 Gateway、Token 發行與遠端 BEN 仍 NOT IMPLEMENTED。，不可將 MockClient 說成真正 BEN 或公開 Gateway。裝置測試依決策持續暫停。

## 練習與自我檢驗

**思考題（1 題）：** 將 BEN 改成 HTTPS POST，是否已經讓應用完全不會洩漏手牌，且可以免登入任意開放 AI API？為什麼？

**5–15 分鐘小練習：** 為 `/bid` 加入一個 `deal` 欄位，閱讀 Mock Test 如何在拿到 token 與送出請求之前阻擋它。

**完成標準：** 可以分清楚 Client Payload 限制、Gateway 身分／權限／流量控管，以及 Bridge Core 的合法性權威。

## 下一步

A4.2 匿名 Session Gateway（仍要使用者批准部署／方案／成本），而不是直接宣稱 A4 正式上線。
