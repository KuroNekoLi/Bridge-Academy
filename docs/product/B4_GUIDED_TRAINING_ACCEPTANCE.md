# B4.1 橋牌學院：課程、原創題庫與可互動答題

日期：2026-10-16  
分支：feature/b4-bridge-academy  
狀態：SCOPED VERIFIED（Flutter analyse、128/128 tests、Web release）／LESSON_DELIVERED。

## 玩家實際可用的功能
- 主應用右上角學院按鈕可以開啟獨立課程頁，與既有正在進行的牌局平行存在；返回後不變更叫牌或出牌狀態。
- 三堂繁中／英文課程，共九道可提交的原創選擇題：
  1. 52 張牌、13 張手牌、北南／東西搭檔；
  2. HCP A=4、K=3、Q=2、J=1，含加總；
  3. 跟牌義務、完整四 Pass 的 Pass Out、4♠ 合約十墩目標。
- 玩家選題→選項→提交→正誤與原因／規則依據→答錯重試或下一題→課堂完成→返回課程列表；正解才增加本次完成數，重複提交不重複計數。
- 課程列表顯示本頁 session 內每堂課已答對題數；**關閉頁面後進度會消失**，C3 再實作加密與跨重啟統計。
- 以 AppBar 進入獨立 Scaffold，對 Gateway／BEN／牌桌無侵入，支援 320／375 邏輯寬度以及 2× 字體縮放。

## 工程邊界
- 無外部題庫或第三方圖片；所有問題由 B4 原創，沒有牌局私人四手牌。
- 依 docs/BRIDGE_RULES_BASELINE.md 檢查基本橋牌規則。HCP 是**明確的教學估算法**，不是 Bridge Core 計分權威、專家核准之競叫建議或完整 SAYC。
- Schema version 1、唯一 lessonId/questionId、skillTag、選項 ID、規則依據、雙語完整性均由 AcademyValidator.validate 檢查；不合法題庫拒絕使用。
- 依 docs/handoff/B4_LEARNING_PROGRESS_CONTRACT.md 將穩定模型留給未來 C3；本輪不搶學習進度持久化。
- Android emulator、真機 iOS/Android、真 BEN 與競賽排名不在本次驗收範圍。

## 程式與測試
- Domain：apps/bridge_academy_flutter/lib/src/academy/academy_models.dart
- 原創教材：apps/bridge_academy_flutter/lib/src/academy/academy_catalog.dart
- UI：apps/bridge_academy_flutter/lib/src/academy/academy_page.dart
- 入口：apps/bridge_academy_flutter/lib/src/bridge_app.dart
- unit：apps/bridge_academy_flutter/test/b4_academy_domain_test.dart
- widget：apps/bridge_academy_flutter/test/b4_academy_widget_test.dart

可重現命令：
    cd apps/bridge_academy_flutter
    flutter analyze
    flutter test test/b4_academy_domain_test.dart
    flutter test test/b4_academy_widget_test.dart
    flutter test
    flutter build web

**GitHub Actions 實測已通過：** [B4 Branch Flutter CI #38909904915](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909904915)，程式碼 SHA `eea21bf293ba6e6c3eb7f3b89b92d2b718456044`。
- `flutter analyze --no-pub`：**No issues found**。
- `flutter test --no-pub --reporter expanded`：**128/128 tests passed**，含全套既有 Flutter 及新 B4 Domain／Widget／320／375px 2× 字體測試。
- `flutter build web --no-pub --release`：**Built build/web**。
- 實際 runner：GitHub Actions ubuntu-latest、subosito/flutter-action@v2 stable。非本地／非手機實機。
- 本輪沒有新增真 Chrome／真 BEN E2E；本測試結果不代表部署合規與真人學習效果。

## 已知限制／未完成
- 不儲存長期進度，不包含錯題歷史／弱點分析／難度自動調整；C3 處理。
- 固定入門教材不是即時真牌局分析，沒有 BEN AI 叫牌評估與高級約定、專家審核。
- 沒有已部署正式服務、帳號、跨裝置、行動裝置實機驗收。

## 回退
如需要可只回退 B4 專屬 academy/、B4 測試、AppBar 的獨立入口與 academyOpen 文案；原 BridgeSession／Bridge Core／BEN 完全未修改。
