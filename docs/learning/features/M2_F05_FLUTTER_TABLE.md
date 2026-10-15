# M2-F05｜Flutter 橋牌桌：單向資料流與明手控制

- Feature ID：M2-F05
- Milestone：M2 單機橋牌
- 類型：Flutter UI、狀態協調、i18n
- 工程狀態：ENGINEERING_VERIFIED（Flutter Web、11/11 Widget／Session tests；裝置 QA 待驗）
- 學習狀態：DELIVERED（使用者尚未作答）
- 實作：apps/bridge_academy_flutter/lib/src/bridge_app.dart、bridge_session.dart、app_copy.dart
- 測試：apps/bridge_academy_flutter/test/bridge_app_test.dart、bridge_session_test.dart
- 實際證據：[Flutter CI #38678356482](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38678356482)、docs/m2/M2_F05_FLUTTER_TABLE_REPORT.md

## 功能目的與實際情境

玩家選擇座位及 Bot 模式，開始單機橋牌。畫面只提供自己的牌及其他座位的張數；首攻後公開 Dummy。玩家可叫牌、Pass、Double／Redouble、點擊合法卡片，最後顯示 13 墩和 NS 總分；四次 Pass Out 顯示 0 分。繁體中文是預設語系，可切換英文。

Demo 是固定牌例與規則測試 Bot，明確標成 NOT BEN；Live 模式才透過 BEN HTTP，失敗會顯示錯誤與重試，不會偷偷改用 Demo。

## 主要程式碼導讀

UI 按鈕 → BridgeSession → SinglePlayerCoordinator → BridgeGame.apply → PlayerView → Flutter Widget。

在 bridge_session.dart 出牌邏輯中：

~~~dart
final view = this.view;
if (_busy || view == null || view.phase != Phase.play ||
    !view.canAct || view.turn == null ||
    !view.legalCards.contains(card)) {
  return;
}
await _submit(CardAction(view.viewer, view.turn!, card), view.version);
~~~

重點：Actor 是出牌的決策人（view.viewer），Hand Owner 才是卡片實際持有座位（view.turn）。當 North 是莊家、South 是 Dummy，決策權屬於 North，但出的牌屬於 South。Bridge Core 判斷是否合法，Flutter 只畫出最新 PlayerView。合法選項另外有 ✓ 標記，不只是靠顏色辨識。

所有畫面文案集中在 AppCopy 管理 zh-TW/en；牌面代碼 SA、D2 是橋牌協定符號，不作語言翻譯。

對應 Android/Kotlin：BridgeSession 類似簡化的 ViewModel，使用 ChangeNotifier + AnimatedBuilder 而不是 StateFlow + Compose；Bridge Core 如同 Domain UseCase 的規則層。UI 不可以直接修改 Domain 狀態。

## 為什麼這樣設計

- 替代方案：Flutter 的 onPressed 自行判斷叫牌或跟牌合法性。這會形成第二套可能與 BEN/CLI 不一致的規則。
- 採用方案：遊戲核心只存在一套規則權威；Controller 管理 loading、重試和版本，Widget 只處理輸入與投影畫面。
- 替代狀態管理：Riverpod/BLoC 適合大型產品，第一版 ChangeNotifier 足以低耦合、可注入測試，以後仍可替換。
- 安全陷阱：只在 Widget 蓋住其他玩家牌並不等於保護秘密，資料應該先經 PlayerView 過濾。
- 策略陷阱：Demo Bot 合法不代表 BEN 策略；真正 BEN 模式必須有真實服務，不能無聲降級。

## 驗證與實際證據

~~~bash
cd apps/bridge_academy_flutter
flutter create --platforms=web --project-name=bridge_academy_flutter .
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
~~~

測試涵蓋中英切換、初始資訊隱私、Pass Out、1NT 後首攻公開明手、莊家點擊明手的合法卡，以及非法 Double 不修改版本。實際 GitHub Actions CI #38678356482：flutter analyze 無問題、11/11 Widget／Session 測試 PASS、Flutter Web Release Build PASS。測試使用 Demo/Fake，與 M2-F04 真 BEN HTTP 驗證不同；Web CI 通過不等於裝置 UX 或瀏覽器真 BEN 點擊驗收。

## 練習與自我檢驗

**情境題：** 輪到 South（Dummy）出牌，但 North 是莊家，為何 CardAction.actor 應填 North、handOwner 填 South？

**5–15 分鐘練習：** 修改 bridge_session_test.dart，在成功點擊一張 Dummy 的合法牌後確認遊戲版本增加、沒有修改其他家的秘密手牌，並解釋為何要傳 expectedVersion。

**完成標準：** 能說明 GameState、PlayerView、BridgeSession、Flutter Widget 各自的職責，並能以 Actor/Hand Owner 解釋明手控制。

## 下一步

CI 通過後，做 Chrome 與 Android/iOS 實機 QA，再擴展真正 BEN 模式的 UI 互動測試、更多固定牌例及手機尺寸 UX。
