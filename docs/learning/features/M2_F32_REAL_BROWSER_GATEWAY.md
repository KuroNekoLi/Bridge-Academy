# M2-F32｜A4.4 真實 Chrome → Gateway → BEN 全場驗收與開發配額

- Feature ID：M2-F32
- Milestone：A4.4 Browser real-network acceptance
- 類型：Flutter Web／API Gateway／真正 BEN／Rate Limiting
- 工程狀態：IMPLEMENTED（首次真 Chrome 測試發現 429，修正後 CI 待驗）
- 學習狀態：DELIVERED，尚未 PRACTICED 或 MASTERED
- 測試：`apps/bridge_academy_flutter/integration_test/browser_gateway_real_test.dart`
- CI：`.github/workflows/ben-flutter-browser.yml`
- 設定：`services/bridge_gateway/bin/serve.dart`

## 功能目的與實際情境

先前的 Flutter MockClient 可以證明 Request ID 安全重送，真正 BEN Gateway 的 Dart 測試也能證明 13 墩成立；但這兩個結果加起來仍無法證明**瀏覽器上的真玩家可以透過 CORS，連到真 Gateway 與真 BEN 打完一副牌**。M2-F32 把三層真正串起來：Chrome → Flutter Widget → localhost Gateway → 可信 Python BEN，再由 Bridge Core 檢查全部操作。

## 主要程式碼導讀

- `browser_gateway_real_test.dart` 不是 MockClient。它透過 `BRIDGE_GATEWAY_ORIGIN=http://127.0.0.1:8086` 進入真正 Gateway 模式，檢查沒有 Demo Selector，取得伺服器發行的 Session。從人類 North 的 UI 叫 3NT，之後依伺服器 `PlayerView.legalCards` 點選合法手牌或公開 Dummy 的牌，直到完成 13 墩。
- `ben-flutter-browser.yml` 另外啟動 pinned `lorserker/ben` Python API 和 Dart Gateway；ChromeDriver 使用固定 `--web-port=8000`，Gate­way 明確允許對應 Origin。沒有啟動 Android 模擬器或 iOS/Android 實機。
- `GatewayConfig.decisionLimit` 原本是每個 Token 每分鐘 30 次。完整 52 張牌需要許多 `/v1/games/action` 和 `/v1/games/advance`，所以**第一次真實瀏覽器測試 #38848501397 在 429 `gatewayRateLimited` 失敗**。這是合理且重要的失敗：單一 API 的保護限制不代表完整用戶旅程可用。
- `bin/serve.dart` 新增明確的本機開發設定 `GATEWAY_DEV_DECISION_LIMIT`，只接受 1–240，沒有設定時維持原本的 **30**。獨立 CI 上使用 180 驗證一整副牌，不改變對外 API，也不聲稱正式部署應採用此值。

## 為什麼這樣設計

對 Android/Kotlin 工程師來說，就像 Espresso／UI Automator 以外再多一層真正連測試後端的 End-to-End Test。MockWebServer 用於精準驗證錯誤；真正 HTTP + 完整 AI 對局則能發現兩者之間的 CORS、Session TTL、Quota、JSON schema、網路逾時與 UX 問題。

正式產品不能只把 429 關掉：必須按照每次 Bot 呼叫的實際 CPU、記憶體、p95 與費用建立分層配額和併發控制。這次只將**可信 localhost 開發執行檔**配額明確參數化；公網未部署、跨程序公平計數未完成，API Raw Hand Endpoint 仍必須在正式環境關閉。

## 驗證與實際證據

```bash
# 可信的本機 BEN Python 應先在 127.0.0.1:8085 執行
cd services/bridge_gateway
GATEWAY_BROWSER_ORIGINS=http://localhost:8000 \
GATEWAY_DEV_DECISION_LIMIT=180 \
BEN_INTERNAL_ORIGIN=http://127.0.0.1:8085 dart run bin/serve.dart

# 另一終端啟動 ChromeDriver 4444；再從 Flutter App 專案執行：
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/browser_gateway_real_test.dart \
  -d web-server --browser-name=chrome --web-port=8000 \
  --dart-define=BRIDGE_GATEWAY_ORIGIN=http://127.0.0.1:8086
```

既有 [Flutter CI #38848030915](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848030915) 為 **86/86 Widget/Unit、Web Build、Chrome Demo PASS**。[真 Chrome Gateway 首輪 #38848501397](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38848501397) 為 **FAIL（429 Rate Limit）**；這次參數修正尚需新的 CI，不能先宣稱通過。原有真 BEN CLI/Gateway 完整牌局有獨立 CI 證據，不能代替本次 Chrome 驗收。

## 練習與自我檢驗

**思考題：** 當完整 52 張牌的端到端測試遭遇 HTTP 429，為何不應直接刪掉 Rate Limiter？開發測試把上限設為 180，能不能代表正式產品的配額設計已經完成？

**5–15 分鐘小練習：** 比較 `GatewayConfig.decisionLimit` 的預設值和 `GATEWAY_DEV_DECISION_LIMIT` 明確設定，列出每次玩家出牌可能產生幾次 Gateway HTTP 呼叫，以及執行一副 13 墩牌局的最低 Token 配額需求。

**完成標準：** 能分清楚 API 單次安全、真正完整牌局 UX、Server Rate Limit、模型運算配額，以及產品部署前尚未通過的負載測試。

## 下一步

通過真 Chrome 牌局後進 A4.5 staging 安全、授權、部署及模型成本驗收；A3.5 和 Android／iOS 裝置 UI/E2E 仍由使用者決定何時恢復。
