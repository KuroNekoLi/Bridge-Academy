# Bridge Academy 目前交接

更新日期：2026-10-26（Asia/Taipei）。**主動保存的工作檢查點，非 30% 用量觸發。** 帳號工具最新回報 5 小時視窗剩 **82%**、每週視窗剩 **97%**；後續 agent 必須重新檢查，不沿用此數字。首次回報曾為 100%／100%，與最新讀值分開。

## 使用者目標與最新要求

1. 依 DOCS 盤點全產品未完成規劃後實作；UI/UX 改善到 BBO／新睿類型的可玩體驗，評估 Dart 牌面／互動套件。
2. 繼續開發並監看帳號用量；任一可用視窗剩餘 <=30% 時先交接。此規範已寫入根目錄 AGENTS.md 與 [用量政策](../USAGE_AND_HANDOFF_POLICY.md)，並建立每 15 分鐘的目前 chat heartbeat `bridge-academy`。

## 分支、工作樹與本輪檢查點

- Repository：`C:/Users/user05/StudioProjects/Bridge-Academy`。
- 工作目錄：`apps/bridge_academy_flutter`；分支 **master**。
- 本輪開始時 HEAD／origin/master：`d835c90`，當時 fetch 後 left/right `0/0`；未改寫 Git 歷史。
- 本次功能及文件仍待最終 commit/push；接手先執行 `git status --short`、`git log -3 --oneline`，不可假設已提交。實際提交與 CI 狀態在後續更新記錄。
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
- **IMPLEMENTED / CI PENDING**：`integration_test/browser_table_test.dart` 新增一副全新 Demo 26 個玩家／明手選擇、52 unique cards、13 墩、version、Review→Play 不改局的 browser regression；沿用既有允許的 `flutter-single-player.yml` ChromeDriver job。
- **BLOCKED（非產品程式失敗）**：曾嘗試 `flutter test --no-pub integration_test/browser_table_test.dart -d windows --reporter expanded`，因 **No Windows desktop project configured** 未能載入；不宣稱 Windows native integration 通過，不另生成未要求的 Windows 專案。
- **NOT RUN**：本輪 genuine BEN、BBA、native DDS、正式部署／容量／成本、Android/iOS emulator/device UI/E2E；device workflow 仍 owner hold，沒有 dispatch 或解除 guard。

完整 evidence／範圍見 [UX_WORKSPACE_ACCEPTANCE.md](../product/UX_WORKSPACE_ACCEPTANCE.md)。新 browser test 在加入後 analyzer 已通過；全 test/ 的 198 測試不包含 integration_test，兩者分開說明。

## 尚待完成的安全收尾

1. 已確認 Review 顯示完成的 1NT/+90，返回 Play 並 Next Board 到 Board 2／E／NS 有局；375px Chrome 與 screenshot 已驗證並 reset 臨時 viewport。不要將 Chrome viewport 當 Android/iOS device 驗收。
2. 更新驗收最後 browser 觀察，檢查新 browser integration test 分析／本機可執行範圍。
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
