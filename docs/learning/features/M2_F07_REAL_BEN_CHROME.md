# M2-F07｜Flutter Chrome 真正呼叫 BEN 的整副牌驗收

- Feature ID：M2-F07
- Milestone：M2
- 類型：Flutter 瀏覽器 E2E／Python BEN／HTTP
- 工程狀態：ENGINEERING_VERIFIED（最新版 [真 BEN Chrome #38682472896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472896) PASS、[Flutter 14/14 #38682472692](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472692) PASS；固定牌局，實機與正式效能未驗收）
- 學習狀態：DELIVERED（尚未練習或答題）
- 原始碼：apps/bridge_academy_flutter/integration_test/browser_ben_test.dart
- CI：.github/workflows/ben-flutter-browser.yml
- 驗收：docs/m2/M2_F07_REAL_BEN_BROWSER_ACCEPTANCE.md

## 功能目的與實際情境

M2-F04 證明 Dart 呼叫真正 BEN 可以完成一副牌；M2-F06 證明 Chrome 可操作 Flutter Demo 牌桌。然而這兩個結果不能直接推論「Flutter Chrome 畫面真的能連到 BEN」，因為瀏覽器還多了 CORS、Host 檢查、真實網路非同步、渲染生命週期等獨立故障點。

這次固定 North 為人類玩家：畫面選真正 BEN、先叫 3NT；AI 透過真正 HTTP 操控其餘座位；玩家持續點擊可出的自己手牌或已公開明手，直到 52 張／13 墩完成。

## 主要程式碼導讀

在 browser_ben_test.dart：

    final realHttp = BenHttpTransport(
      baseUri: Uri.parse(origin),
      timeout: const Duration(seconds: 120),
    );
    final counter = _RouteCounter(realHttp);
    final session = BridgeSession(
      botFactory: (mode) {
        if (mode != OpponentMode.ben) {
          throw StateError('M2-F07 requires BEN mode, not Demo');
        }
        return BenBotPolicy(counter);
      },
    );

這裡的 counter **不是 Mock**，只是包裝真實 BenHttpTransport 並計數成功回應；還要求 BEN 參數只能包含公開資訊／該 Bot 自己的手牌。如果 BEN 無法連線，它會報錯，絕不偷偷換成示範 Bot。

另一個重要的函式是 _awaitBen：Flutter 的 pumpAndSettle 只能讓排隊的 Widget frames 穩定，不能保證網路上的 Python 模型已完成運算。因此必須在真正非同步環境等待 BridgeSession.busy 解除，接著重新繪製，才檢查狀態。

## 為什麼這樣設計

- Android 對照：MockWebServer/假 Repository 只驗證本機預期資料格式；Chrome 操作 + 真 Python BEN 更接近 UIAutomator/Espresso + 真後端，速度較慢但能偵測真實部署相容性。
- 替代方案：直接拿以前 M2-F04 的 Dart CLI 成功結果當成 Flutter UI 成功。這會忽略 Chrome 的 HTTP/CORS 和畫面互動問題，因此不採用。
- 避坑：單靠 session.finished 可能在 Demo Bot 也打完時錯判。必須另外確認真正 /bid、/lead、/play 至少各一次成功回應。
- 隱私：BEN 的 GET URL 可能攜帶私人手牌。CI 不可輸出原始 URL／body／四家牌資訊，僅記錄端點成功次數、牌墩和分數。
- 測試公平性：固定 3NT 只是讓測試進入出牌階段，不是對此叫牌品質的背書。PIMC 和抽樣皆使用縮減驗收設定。

## 驗證與實際證據

    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

實際最新 [GitHub Actions #38682472896](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472896) SUCCESS（SHA ca200fa，且 [Flutter CI #38682472692](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472692)／[教學 Gate #38682472760](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472760) 亦 PASS）。首輪真 BEN Chrome 證據 [#38681913862](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38681913862) 同樣 SUCCESS：真正 BEN Readiness PASS、Chrome/ChromeDriver 154 版本相符、Flutter UI 點擊真 BEN 完整牌局（52/13）、真實 /bid、/lead、/play 各至少 1 次成功回應，所有 browser assertions PASS。CI 沒有印出精確 API 次數或數字分數，因此文件不捏造。最早版本的 Flutter analyze 曾因一個多餘 import 的 lint 失敗；移除後已在最新版 #38682472692 真正重新通過。

## 練習與自我檢驗

**思考題：** 假設 Chrome 的畫面顯示打完 13 墩，但 /lead 真實成功次數為 0。為什麼這不能算 M2-F07 GO？

**5–15 分鐘練習：** 找到 _awaitBen，說明當瀏覽器網路 Future 尚未完成時，單純呼叫 pumpAndSettle 為何可能提早讀取 BridgeSession 狀態。

**完成標準：** 能分辨 Widget frame 與真正 I/O 等待，指出「真 BEN 整合」的可觀測驗收證據，以及從 PlayerView 到 Bridge Core 的責任邊界。

## 下一步

Chrome 真 BEN 完整對局通過後，依序擴充 BEN 當莊家的畫面測試，以及 Android 模擬器／iOS Android 實機的 UI、網路與 UX 驗收。Chrome PASS 不能替代手機裝置 PASS。
