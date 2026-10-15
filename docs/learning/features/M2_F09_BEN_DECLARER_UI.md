# M2-F09｜真 BEN 當莊家：Actor 與 Hand Owner

- Feature ID：M2-F09
- 工程狀態：ENGINEERING_VERIFIED（[真 BEN Chrome CI #38685977544](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685977544) PASS；固定牌例）
- 學習狀態：DELIVERED
- 程式：apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart
- CI：.github/workflows/ben-flutter-browser.yml
- 驗收：docs/m2/M2_F09_BEN_DECLARER_UI_ACCEPTANCE.md

## 功能目的與實際情境

本功能以真實執行結果確認 AI 行為。

## 主要程式碼導讀
先前 M2-F07 是人類 North 當莊家，BEN 只防守。現在人類 East 防守，BEN 自行叫牌，由 North 擔任莊家並替 South 明手決策。

核心判斷：Robot 收到的 PlayerView.viewer 應是 Declarer North、PlayerView.turn 應是 Dummy South。真 BenBotPolicy 提案後，AuditedBot 驗證 CardAction.actor 是 North，handOwner 是 South，且牌存在於合法可出集合；要求總共 13 次。

## 為什麼這樣設計
Actor（做出決定的人）不等於 Hand Owner（牌的持有者）。把兩者混成同一個座位，就會錯誤地讓明手取得自主出牌權。AuditedBot 不修改 AI 決策，僅觀測，因此不會把假的測試策略冒稱 BEN。

本次 Opening Lead 由人類 East 完成，所以 BEN 的 /lead=0 可以完全正常；只要求真 /bid 和 /play。類比 Android：使用者身分與被代理操作的資源擁有人，需要獨立授權。

## 驗證與實際證據
固定真 BEN 在 localhost 8085，從 Flutter App 目錄執行：

    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_declarer_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

[第一次真 BEN CI #38685813924](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685813924) SUCCESS；修改 lint 後最新版 [#38685977544](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38685977544) 亦 SUCCESS。實際斷言：13 次 BEN 代打 South 明手、13 次人類 East 防守操作、52 張牌／13 墩、合法結算，且真 /bid /play 都有成功回應。不代表正式策略效能。

## 練習與自我檢驗
**問題：** North 是莊家、South 是明手，BEN 建議 South 出方塊 2；為什麼 actor 應是 North 而 handOwner 是 South？

**小練習：** 說明如果改成 Actor South，為何應在 Bridge Core 被拒絕。

**完成標準：** 能清楚分辨決策者、持牌者及真實 AI 觀測層的三種責任。
