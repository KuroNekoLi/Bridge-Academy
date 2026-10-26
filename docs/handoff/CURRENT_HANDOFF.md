# Bridge Academy 目前交接

更新時間：**2026-10-26 09:49:18 Asia/Taipei（01:49:18 UTC）**。**已觸發 30% 先交接規範**：帳號工具本次回報 5 小時視窗 used 76%／remaining **24%**，每週 used 12%／remaining **88%**。已先更新本文件，之後只做必要驗證／保存／提交收尾，不開始新功能。這是帳號共用用量，不代表本專案獨占消耗；之後必須重新讀取。

## 觸發後最短接續路徑

1. F53/F54 的 master `5b72c13` 已有六項自動 CI success（Flutter 198/198＋Web/Chrome、Learning、M4、M5、Precision、真 BEN Chrome）。
2. F55 窄屏單排牌列 source/test/lesson 已完成，本機 analyzer、scoped 10/10、完整 **200/200**、Web release PASS；目前 14 個檔案待同批 commit。先保留它們，不回退／丟棄。
3. 尚未提交：`apps/bridge_academy_flutter/lib/src/{app_copy.dart,widgets/bridge_table_components.dart,widgets/bridge_card_strip.dart}`、`test/m2_card_strip_test.dart`；docs 的 Architecture、handoff、learning INDEX／F53／F54 evidence／F55 lesson、A3 spec、product plan／roadmap／acceptance。完整清單以 `git status --short` 為準。
4. Chrome 375px 已實際看見水平提示、捲軸，向右捲到末端 C6 仍保持完整牌面。人工 Browser 用 locator 遇到 Flutter 捲動／彈出選單焦點不同步，期間曾點出非法叫牌／規則拒絕；不將這次人工操作稱為完整新局 F55 E2E，既有 domain／200 tests 正常。
5. **Chrome 臨時 viewport 已 reset，並 reload 清除彈出選單／暫時錯誤狀態**；保留本機預覽分頁，不再開始另一副完整驗收。原桌面 screenshot 與 mobile375 screenshot 已存在 Codex visualization 目錄。
6. 接著只跑必要 git hygiene／lesson gate，將 F55 source＋test＋lesson 與這批 evidence 同一 commit 直接 push master；記錄新 SHA／新 CI。若額度不足以等 CI，保留 PENDING 與 URL，不聲稱 PASS，也不再跑重複昂貴測試。
7. 配額恢復並重新檢查後，再從 U3 尚未完成的整張單屏牌桌／可中止動畫繼續；A4 production、server history、安全 bearer 續局、公平比賽與多人仍未完成。Android/iOS device hold 不變。

**最後觸發狀態：** `TRIGGERED_PRIMARY_LE_30`；已在先保存本文件後向使用者回報 24%／88%。除有新行動／恢復／重要交接變更，監看不要重複提醒同一狀態。不要把本段的 24% 長期當即時值。

## 使用者目標與最新要求

1. 依 DOCS 盤點全產品未完成規劃後實作；UI/UX 改善到 BBO／新睿類型的可玩體驗，評估 Dart 牌面／互動套件。
2. 繼續開發並監看帳號用量；任一可用視窗剩餘 <=30% 時先交接。此規範已寫入根目錄 AGENTS.md 與 [用量政策](../USAGE_AND_HANDOFF_POLICY.md)，並建立每 15 分鐘的目前 chat heartbeat `bridge-academy`。

## 分支、工作樹與本輪檢查點

- Repository：`C:/Users/user05/StudioProjects/Bridge-Academy`。
- 工作目錄：`apps/bridge_academy_flutter`；分支 **master**。
- 本輪開始時 HEAD／origin/master：`d835c90`，當時 fetch 後 left/right `0/0`；未改寫 Git 歷史。
- 本次功能／測試／兩篇教學／用量政策已以 **`5b72c13241a6f75dafed66b4a20ebe87677098f3`** 直接 push master；提交後工作樹乾淨。後續 evidence-only 文件更新可能另有 commit，接手先讀 `git status --short`、`git log -3 --oneline`。
- 本輪沒有別人的既有未提交檔案。新增檔為 practice hub/card face、兩個 M2 測試、產品計畫／驗收、兩篇 feature lesson／index、用量政策與本交接；修改集中於 Flutter app/copy/shared table/bidding/Gateway/pubspec、既有回歸、browser integration test 及 docs／AGENTS。

## 已完成的實作

- **M2-F53**：練習卡片入口、打牌／學院／本機複盤／我的導覽、活動牌桌優先、最大寬度 1240、頁籤保留 Session／版本、未完牌重發確認。Gateway 不顯示不存在的雲歷史。
- **M2-F54**：`playing_cards 0.4.1+11` 精確依賴，單向 Card renderer adapter、字形牌面、可讀中央點數、叫牌顯示自己的牌且不可出牌、公開明手／本墩共用牌面、合法／鎖定提示與獨立 semantic tap。無 Core／bot／存檔 schema 變更。
- 全產品計畫：[PRODUCT_COMPLETION_PLAN_2026_10.md](../product/PRODUCT_COMPLETION_PLAN_2026_10.md)；分清既有本機能力、U3 操作／動畫、U4 server history／續局、部署、AI 品質、比賽與多人。
- [M2-F53 lesson](../learning/features/M2_F53_PRACTICE_WORKSPACE.md)、[M2-F54 lesson](../learning/features/M2_F54_CARD_PRESENTATION.md) 與 INDEX 同批提供；只可說 LESSON_DELIVERED，不可說已熟練／掌握。
- 根 AGENTS 用量硬性規範、[政策](../USAGE_AND_HANDOFF_POLICY.md)、本機每 15 分鐘 heartbeat 已設定。

## 測試與證據（不可混用）

環境 Windows／PowerShell，Flutter `C:/Users/user05/develop/flutter/bin/flutter.bat` **3.47.8**，Dart **3.13.7**。

- **EXECUTED/PASS**：`flutter pub get`；新增一個 playing_cards 精確依賴，archive SHA 見 OSS audit。
- **EXECUTED/PASS**：`flutter analyze --no-pub`，`No issues found!`。
- **EXECUTED/PASS**：`flutter test --no-pub --reporter expanded`，**198/198**。最後一輪包含 52 張映射、只顯示 ownCards、keyboard／semantic tap、單張牌 label、Gateway Mock、放大字體／各寬度與全部既有 test/ 回歸。
- **EXECUTED/PASS**：`flutter build web --no-pub --release`，`Built build\web`；CupertinoIcons font inventory 有非致命 warning，沒有隱瞞成零 warning。
- **EXECUTED/PASS**：lesson gate，當時 25 changed files；新增用量文件後 commit 前重查。新文件 46 個 local links 當時全部存在。
- **EXECUTED/Chrome Demo**：release localhost `127.0.0.1:8734` 實際按牌、checkpoint reload 恢復、1NT 最終 **13/13、56/56 events、NS +90**。期間發現並修正 semantic tap／單張牌合併問題；最後版本由已恢復的第 12 墩繼續到終局，不能把跨 reload 的操作說成單一全新 build 未中斷的 E2E。
- **EXECUTED / CI PASS**：`integration_test/browser_table_test.dart` 新增一副全新 Demo 26 個玩家／明手選擇、52 unique cards、13 墩、version、Review→Play 不改局的 browser regression；已由既有允許的 `flutter-single-player.yml` ChromeDriver job 真實執行成功。
- **BLOCKED（非產品程式失敗）**：曾嘗試 `flutter test --no-pub integration_test/browser_table_test.dart -d windows --reporter expanded`，因 **No Windows desktop project configured** 未能載入；不宣稱 Windows native integration 通過，不另生成未要求的 Windows 專案。
- **NOT RUN（本機）**：genuine BEN、BBA、native DDS、正式部署／容量／成本、Android/iOS emulator/device UI/E2E；提交後自動 CI 狀態另見下節。device workflow 仍 owner hold，沒有 dispatch 或解除 guard。

完整 evidence／範圍見 [UX_WORKSPACE_ACCEPTANCE.md](../product/UX_WORKSPACE_ACCEPTANCE.md)。新 browser test 在加入後 analyzer 已通過；全 test/ 的 198 測試不包含 integration_test，兩者分開說明。

## 本輪 CI（5b72c13，由 push 自動觸發）

- [Flutter＋Web＋Chrome Demo](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253)：**success**：198/198 Widget、analyze、Web release、ChromeDriver 155 真正的新局 52 張／13 墩與加密 checkpoint targets 全 PASS，jobs 日誌已查核。
- [Feature Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094204)、[M4](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094234)、[M5](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094228)：均已 success。
- [Precision 研究](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094239)：已 success；[真 BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094235)：已 success，job 三個 Flutter drive targets 全部通過。兩者由既有 path triggers 自動啟動，不是手動新增測試或 device QA。

## U3.1／M2-F55 新進度（與前批 CI 分開）

- 新增 `bridge_card_strip.dart`／`m2_card_strip_test.dart`：窄屏 own/dummy 水平牌列＋捲軸，中英提示，保持目標大小及原 command；寬屏展開。
- 已執行 analyzer PASS、scoped 10/10、完整 **200/200**、Web release PASS（同 font warning）。
- 教學 `M2_F55_RESPONSIVE_CARD_STRIP.md`／INDEX 已寫，新的 source＋test＋lesson 尚待同一 commit/push；不能用 `5b72c13` 的 CI 證明 F55。
- 尚待 Chrome 實際新牌列驗證、新提交 CI、最後用量／handoff 更新。這是 U3 第一小範圍，整張單屏牌桌／動畫未完成。

## 尚待完成的安全收尾

1. 已確認 Review 顯示完成的 1NT/+90，返回 Play 並 Next Board 到 Board 2／E／NS 有局；375px Chrome 與 screenshot 已驗證並 reset 臨時 viewport。不要將 Chrome viewport 當 Android/iOS device 驗收。
2. 前批最後 browser 觀察／CI 證據已更新；F55 實際 375px 提示／右捲到 C6 已觀察，沒有宣稱全新 F55 人工完整牌局。
3. 再查用量、git diff --check、lesson gate、文件連結；commit/push verified source＋tests＋lessons＋政策到 master（不開 PR、不 force-push）。
4. 查 push 對應的 Flutter／Learning CI，記下 run URL／SHA 與 executed/pending/failed 真實狀態；若失敗先修復。不額外 dispatch held device workflows。
5. 更新本交接的實際功能 SHA／CI 後，下一功能為 U3：單屏牌桌與可中止的選牌／發牌／出牌／收墩動畫。公開部署、U4 server history／安全 bearer 續局、AI quality 和 D/E 不可冒稱已實作。

## 接續命令

```powershell
Set-Location C:/Users/user05/StudioProjects/Bridge-Academy/apps/bridge_academy_flutter
git status --short
git log -3 --oneline
& C:/Users/user05/develop/flutter/bin/flutter.bat analyze --no-pub
& C:/Users/user05/develop/flutter/bin/flutter.bat test --no-pub --reporter expanded
& C:/Users/user05/develop/flutter/bin/flutter.bat build web --no-pub --release
```

依新改動／失敗需要才重跑，不為交接重複昂貴檢查。ChromeDriver CI 使用既有 workflow 的標準命令；本機預覽是 `build/web` 的 Python loopback server，沒有公開部署。

## 風險、回退與決策

- `playing_cards` 的 source 為 Apache-2.0，全部 rank/suit 用字形 style；package 未使用的內附 Wikimedia 圖像仍可能被 Flutter 打包，公開 binary 前須排除或完成逐圖來源審核。不能將 package reference 的准入視為整體商業發行核准。
- 30% 規範是 account-shared quota，排程依賴 app／機器可執行，不保證關機時即時。工具缺欄位是 UNKNOWN，不存帳號 ID／Token。
- 無 schema migration；可用單一 feature commit 的 `git revert` 回退 source/pubspec/docs，保留已有加密牌局。不 delete 未提交工作、不 reset/force-push。
- owner-held A3.5／Android/iOS device QA 只有後續明確批准才恢復；本次「繼續」沒有解除 hold。
