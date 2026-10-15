# M2-F09｜真 BEN 當莊家：Actor 與 Hand Owner

- Feature：M2-F09
- 工程狀態：IMPLEMENTED（真 BEN Chrome Declarer 尚未驗收）
- 學習狀態：DELIVERED
- 程式：apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart
- CI：.github/workflows/ben-flutter-browser.yml
- 驗收：docs/m2/M2_F09_BEN_DECLARER_UI_ACCEPTANCE.md

## 需求與程式導讀
先前 M2-F07 是人類 North 當莊家，BEN 只防守。現在人類 East 防守，BEN 自行叫牌，由 North 擔任莊家並替 South 明手決策。

核心判斷：Robot 收到的 PlayerView.viewer 應是 Declarer North、PlayerView.turn 應是 Dummy South。真 BenBotPolicy 提案後，AuditedBot 驗證 CardAction.actor 是 North，handOwner 是 South，且牌存在於合法可出集合；要求總共 13 次。

## 設計原因與替代方案
Actor（做出決定的人）不等於 Hand Owner（牌的持有者）。把兩者混成同一個座位，就會錯誤地讓明手取得自主出牌權。AuditedBot 不修改 AI 決策，僅觀測，因此不會把假的測試策略冒稱 BEN。

本次 Opening Lead 由人類 East 完成，所以 BEN 的 /lead=0 可以完全正常；只要求真 /bid 和 /play。類比 Android：使用者身分與被代理操作的資源擁有人，需要獨立授權。

## 驗證
固定真 BEN 在 localhost 8085，從 Flutter App 目錄執行：

    flutter drive --driver=test_driver/integration_test.dart --target=integration_test/browser_ben_declarer_test.dart -d web-server --browser-name=chrome --dart-define=BEN_BASE_URL=http://127.0.0.1:8085

初稿 CI NOT RUN，CI 證據與明手次數後續寫入驗收報告。不代表正式策略效能。

## 練習
**問題：** North 是莊家、South 是明手，BEN 建議 South 出方塊 2；為什麼 actor 應是 North 而 handOwner 是 South？

**小練習：** 說明如果改成 Actor South，為何應在 Bridge Core 被拒絕。

**完成標準：** 能清楚分辨決策者、持牌者及真實 AI 觀測層的三種責任。

