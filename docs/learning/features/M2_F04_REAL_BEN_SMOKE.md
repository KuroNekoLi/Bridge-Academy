# M2-F04｜真 BEN API 驗證：為什麼 Contract Test 還不夠

- Feature ID：M2-F04
- Milestone：M2
- 工程狀態：第一副真 BEN 完整牌局已 VERIFIED；第二副 BOT 控制 Dummy 的實機案例待驗收
- 學習狀態：DELIVERED
- 來源：packages/bridge_ben_adapter/bin/live_ben_smoke.dart
- 環境：.github/workflows/ben-real-native-smoke.yml
- 報告：docs/m2/M2_F04_REAL_BEN_ACCEPTANCE.md

## 功能目的與實際情境

M2-F03 的 13 個 MockClient 測試只證明 Adapter 的 HTTP 格式、資訊安全與錯誤處理，不能證明真正的 Python BEN 能完成牌局。M2-F04 使用固定四家合法手牌，讓 North 按固定策略操作，其餘座位由實際 BEN 模型透過 HTTP 決策。第一副真實執行已成功：6NT North、13 墩、NS −250，BEN 實際回覆 /bid 四次、/lead 一次、/play 二十五次（CI #38676215575）。另外新增第二副案例，改由 Human East 防守、BEN 擔任莊家並代出 Dummy；第二副結果仍需獨立驗收。

## 主要程式碼導讀

~~~dart
final coordinator = SinglePlayerCoordinator(
  deal: Deal.fromPbn(fixedPbn),
  dealer: Seat.north,
  vulnerability: Vulnerability.none,
  humanSeat: Seat.north,
  bot: BenBotPolicy(measured),
);
~~~

BenBotPolicy 實際持有 BenHttpTransport，不是 MockClient。每次 AI 請求依 PlayerView 傳本家手牌與公開歷史，BridgeGame.apply 驗證合法性。MeasuredBenTransport 只記錄呼叫次數及耗時，不印完整 URL 與秘密手牌。最後驗證完整牌局與三個端點各至少一筆成功回應。若任何一個失敗，直接回傳非零結束碼，沒有固定出牌替代方案。

對照 Kotlin：MockWebServer/假 Repository 通過，只代表契約符合自己的假設；真正的整合測試則會揭露 Python 服務是否能啟動、TensorFlow 與 DDS 原生庫是否相容，以及真正回應是否合法。

## 為什麼這樣設計

- 不直接用 BEN autoplay：它可以看到四家牌且控制整副牌，不適合驗證 Human 與三位機器人逐回合的隔離流程。
- 固定 Human 先叫 3NT：保證進入合約與出牌階段，讓真實 API 測試可重現；這不是對叫牌策略品質的背書。
- 原生 Ubuntu 24.04 + Python 3.12：BEN 的 DDS 擴充模組要求較新的 glibc 與對應 CPython ABI。
- 此次 PIMC 關閉、抽樣降低：只是驗收設定，不代表 BEN 預設強度、效能或未來 SLA。
- GET query 包含 Bot 自己的牌：測試紀錄不輸出或上傳完整請求及 BEN 原始 log。

## 驗證與實際證據

從可信環境啟動真正 BEN gameapi.py 後：

~~~bash
cd packages/bridge_ben_adapter
dart pub get
BEN_BASE_URL=http://127.0.0.1:8085 dart run bin/live_ben_smoke.dart
~~~

也可以使用 GitHub Actions 工作流程 BEN Real Native Smoke。第一副真實 PASS 證據：https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38676215575 。後續包含第二個執行程式 packages/bridge_ben_adapter/bin/live_ben_dummy_smoke.dart，用於檢查 Robot 莊家以 Actor 身分代打明手 Hand Owner。只有真正的 HTTP 服務、真實模型與 52/13 完成才可以標 PASS。若 workflow 無法安裝或啟動 BEN，應記 BLOCKED/FAIL 而非挪用舊 POC 成果。

## 練習與自我檢驗

**思考題：** 為何 MockClient 可以通過全部契約測試，但在 Ubuntu 22.04 上真 BEN 仍可能因 DDS 的 GLIBC 版本而無法啟動？

**小練習：** 閱讀 live_ben_smoke.dart，找到驗證 /bid、/lead、/play 呼叫次數的條件；思考少了 /lead 為什麼即使出完 13 墩仍未達本次驗收標準。

**成功標準：** 能分辨 Mock 契約測試與真實整合測試分別保證什麼，並能指出哪一層負責保護秘密手牌。

## 下一步

真 BEN 驗收通過後，才將協調器接上 Flutter 牌桌；M2 整體尚未完成。

