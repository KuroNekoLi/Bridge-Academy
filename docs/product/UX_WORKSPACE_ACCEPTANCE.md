# A3 UI 延伸：練習工作區與牌面呈現驗收

- 日期：2026-10-26（使用者 Asia/Taipei 日期）
- 功能：M2-F53、M2-F54、M2-F55；[全產品未完成計畫](PRODUCT_COMPLETION_PLAN_2026_10.md)
- 工程：**SCOPED ENGINEERING_PASS（Windows 本機＋Ubuntu CI Web／Chrome）**；不代表產品／裝置發布
- 教學：**LESSON_DELIVERED**；沒有 PRACTICED／MASTERED 證據
- 部署／全產品／A3.5：**NOT READY／未通過**；Android/iOS UI/E2E 仍 OWNER HOLD

## 範圍與實際改檔

| Feature | Implementation | Deterministic boundary tests | Lesson |
| --- | --- | --- | --- |
| M2-F53 | [bridge_app](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)、[practice hub](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_practice_hub.dart)、[copy](../../apps/bridge_academy_flutter/lib/src/app_copy.dart) | [workspace tests](../../apps/bridge_academy_flutter/test/m2_practice_workspace_test.dart)：切頁保留對局、真正學院／歷史入口、取消重發、各尺寸與中英 | [M2-F53](../learning/features/M2_F53_PRACTICE_WORKSPACE.md) |
| M2-F54 | [card adapter](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_face.dart)、[shared table](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart)、[Gateway](../../apps/bridge_academy_flutter/lib/src/gateway_table.dart)、pubspec／lock | [card tests](../../apps/bridge_academy_flutter/test/m2_card_presentation_test.dart)：52 張映射、排序副本、只顯示 ownCards、keyboard＋semantic tap、disabled/busy；[Gateway](../../apps/bridge_academy_flutter/test/a4_gateway_integration_test.dart) Mock 邊界與既有 dummy owner 回歸 | [M2-F54](../learning/features/M2_F54_CARD_PRESENTATION.md) |

更新產品計畫／README／Roadmap addendum、ADR-038、Architecture、OSS audit 及 learning index。Core、合法性、bot policy、存檔 schema、device workflows 均未變更。既有 A3 元件測試改為驗證叫牌階段確實有自己的手牌；舊叫牌盒測試先捲動到開始按鈕，再繼續檢查 Core 拒絕非法 X，沒有刪除舊規則斷言。

## EXECUTED：環境與命令

本機 Windows PowerShell；Flutter **3.47.8 stable**，framework `737ba8f885`；Dart **3.13.7**。工作目錄 `apps/bridge_academy_flutter`，實際 executable `C:/Users/user05/develop/flutter/bin/flutter.bat`。

```powershell
& C:/Users/user05/develop/flutter/bin/flutter.bat pub get
& C:/Users/user05/develop/flutter/bin/flutter.bat analyze --no-pub
& C:/Users/user05/develop/flutter/bin/flutter.bat test --no-pub --reporter expanded
& C:/Users/user05/develop/flutter/bin/flutter.bat build web --no-pub --release
```

| Check | Result / exact excerpt | 範圍 |
| --- | --- | --- |
| dependency resolve | `Changed 1 dependency!`；playing_cards `0.4.1+11` | 精確 registry archive hash 與 [OSS 紀錄](../OPEN_SOURCE_AUDIT.md) 一致 |
| analyzer | `No issues found!` | Flutter lib／tests 靜態檢查 |
| Flutter suite | `+198: All tests passed!` | 全部本機 test/；Demo／injected Mock，不是真模型 |
| Web release | `Wasm dry run succeeded`；`Built build\web` | Dart2JS release build；沒有聲稱實際 Wasm 運行驗收 |
| git hygiene | `git diff --check` | 無 whitespace error；Windows LF/CRLF 提示不是驗收失敗 |

Build 另出現 `packages/cupertino_icons/CupertinoIcons` font inventory warning；命令 exit 0，Material icons 已成功產生且 Chrome 有顯示本輪圖示。此紀錄不將 warning 隱瞞成無任何 build warning，也不為此引入與功能無關的套件更新。

## EXECUTED：Chrome 實際操作

透過使用者指定的 Chrome，以本機 release 靜態頁 `http://127.0.0.1:8734/` 驗證；不是 Android emulator、不是正式 HTTPS host、不是 BEN。

- 實際開啟練習入口並按開始新牌，叫牌時可見自己的 13 張牌；其他三家只顯示張數。
- Reload 恢復既有加密 checkpoint，UI 顯示「已恢復上次牌局」，不自動重發。
- 公開開叫 `1NT` 後 Demo 對手完成叫牌與首攻，只有此後明手才公開。
- 實際按合法明手／自己手牌，出牌仍由 Session／Core 推進；牌面與輪次／跟牌狀態同步。

Chrome 驗證抓到並修正了 Widget-only 測試原先沒覆蓋的兩個無障礙細節：外層牌面語意必須具有真正的 onTap action；單張手牌也必須有獨立 semantics container，避免與整張手牌區合併導致點擊落在空白處。新增語意 action 及單張牌 label regression，沒有以隱藏欄位或直接呼叫 Session 替代瀏覽器操作。

- 最終 UI 確認 **13/13 墩、56/56 events、1NT、NS +90**，四個座位剩餘牌數皆 0；Review tab 顯示已保存的 1NT/+90 完成牌局，返回 Play 沒有重發。
- 操作 Next Board 後確認 **Board 2／dealer E／NS vulnerable**，叫牌可見 13 張 ownCards、無 dummy 提早公開。
- Chrome viewport 實際 `innerWidth=375`／`innerHeight=812`／DPR=1；重新載入確認窄屏布局，之後已 reset 至原桌面 viewport。這是 Chrome Web，不是手機裝置驗收。
- 本機截圖位於使用者 Codex visualization 目錄 `bridge-table-desktop.jpg`／`bridge-mobile375.jpg`，沒有將私人帳號資料或 unverifiable 截圖提交 Git。

**範圍限制**：本輪人工 Chrome Demo 牌局跨開發 reload／修復，最後版本從還原的第 12 墩繼續完成；不把它說成同一 final build 從新局不中斷的自動 E2E。新增 `integration_test/browser_table_test.dart` 的完整新局回歸另檢查 26 次玩家／明手選擇、52 unique cards、13 墩與 Review→Play，已由下方對應 ChromeDriver CI 實際執行通過。

曾嘗試 `flutter test --no-pub integration_test/browser_table_test.dart -d windows --reporter expanded`，**BLOCKED：No Windows desktop project configured**，測試未能載入；沒有宣稱 Windows native integration 通過，也未新增未要求的 desktop scaffolding。analyzer 已通過 browser test；本機 198 項 test/ 不包含 integration_test。

## NOT RUN／限制

- 本機未啟動 genuine BEN／Precision native BBA／native DDS。提交後既有真 BEN／Precision workflows 自動執行，狀態見本檔末；未執行正式 VPS／TLS、多人／MP/IMP 或成本壓測，不挪用舊 CI 當本輪證據。
- Android/iOS 模擬器與實機 UI/E2E：**OWNER HOLD，沒有 dispatch、schedule 或解除 workflow guard**。
- 真人新手／熟手 usability、TalkBack／VoiceOver、A3.5 最終玩家驗收尚未執行。Widget／Chrome 不可代替裝置驗收。
- package 未使用的 bundled Wikimedia 圖像可能仍進 build；公開 binary 之前必須完成來源或排除，見 OSS audit。
- 單屏布局、選牌／拖放、發牌／飛牌／收墩動畫與 reduced motion 屬 U3，沒有宣稱套件安裝就代表動畫已實作。
- Gateway 雲歷史、跨重啟 bearer 安全續局、正式可玩自訂 AI／Precision 品質、ranked／live multiplayer 繼續列在交付計畫。

## 回退與後續

無 schema migration。回退使用本輪 source/docs commit 的 `git revert <commit>` 並依 lock 重新取依賴，不 force-push、不改已保存牌局、不刪除歷史。後續以 U3 的單屏牌桌與可中止呈現動畫為下一包；公開部署與裝置 release gate 維持獨立決策。

## U3.1／M2-F55：窄屏手牌與明手單排捲動

使用者要求繼續後，在用量仍高於 30% 時完成下一個可獨立驗收的 UI 範圍。

- [BridgeCardStrip](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_card_strip.dart) 只接收原有授權牌面 Widgets；68px 外框＋6px 間距超出實際內容寬度才顯示水平捲動／可拖曳捲軸／雙語提示，放得下時直接展開。
- 自己與公開明手共用，不縮小 touch target，不變更 legal/busy/owner/callback/key，不新增 package／Core／schema 變動。
- [測試](../../apps/bridge_academy_flutter/test/m2_card_strip_test.dart)：320px 最後一張 CA 初始在畫面外，捲到後能正確點選；牌列高度 <180、點擊區 >=48；中英提示；13→2→0 安全切換；1280px 同列且無捲動提示。
- **EXECUTED/PASS**：`flutter analyze --no-pub` 無問題；scoped strip＋A3 accessibility＋components **10/10**；`flutter test --no-pub --reporter expanded` **200/200**；`flutter build web --no-pub --release` 成功，保留前述非致命 font warning。
- [M2-F55 lesson](../learning/features/M2_F55_RESPONSIVE_CARD_STRIP.md) 與 INDEX 同批。前段 `5b72c13` 的 CI 屬 F53/F54，不挪用為本次新布局 CI；新提交後另記新 run/SHA。
- Chrome release 375px 已觀察單排提示／可見捲軸，實際向右捲到最末 C6，牌面未縮小；已 reset viewport。人工 locator 曾有捲動／popup 焦點不同步及非法叫牌拒絕，沒有把此操作當作完整新局 F55 E2E。
- 尚未完成 U3 整張牌桌單屏、飛牌／收墩動畫或裝置 QA；不以這個小範圍解除原 gates。
- 2026-10-26 09:49 Asia/Taipei 帳號工具回報 5 小時剩 24%／週剩 88%，已先更新交接，停止新增功能，只保存已驗證工作。

## 已提交與自動 CI

功能、測試、兩篇教學與用量硬性規範已一起直接 push master：`5b72c13241a6f75dafed66b4a20ebe87677098f3`。

[Flutter／Web／Chrome Demo CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094253) 已成功結束，analyzer 成功；**198/198 Flutter＋Web Release＋ChromeDriver Demo 新局完整 52 張／13 墩與 browser encrypted checkpoint 全部成功**。Chrome／ChromeDriver `155.0.8059.39`，Flutter `3.47.8`；jobs `121355118469`、`121355118337` 步驟與日誌已查核。兩個 `flutter drive` target 皆回報 `All tests passed.`。 [Learning Gate](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094204)、[M4](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094234)、[M5](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094228)、[Precision 研究](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094239) 均已 success；既有 [真 BEN Chrome](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40255094235) 同次 push 自動觸發，已 **success**，job `121355118328` 的三個 Flutter drive targets 皆 `All tests passed.`；此為該 SHA 的固定 fixture 真模型回歸，非公開部署或任意牌力保證。
