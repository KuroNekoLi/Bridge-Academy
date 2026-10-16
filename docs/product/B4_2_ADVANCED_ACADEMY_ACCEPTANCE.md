# B4.2 — 進階橋牌課程（2026-10-17）

**狀態：SCOPED VERIFIED（Flutter／Web／Demo Chrome）；不是外部橋牌專家審核完成。**

## 玩家可操作交付
- 保留 B4.1 的 3 堂／9 題，新增防守跟牌、莊家定約及計分、教學叫牌約定 3 堂／12 題，合計 **6 堂／21 題**，全部繁中／英文。
- 沿用學院頁的選課、答題、錯誤解釋、重新作答、完成進度；C3 明確 opt-in 時紀錄新題 `questionId`，進度畫面自動重新計算總題數。
- 原版 B4 題目不改 ID 或正解；新題前綴 `b4.2.`，schemaVersion=1，skillTag 為 `defense_rules`、`contract_planning`、`convention_literacy`。
- 防守規則與計分以 `docs/BRIDGE_RULES_BASELINE.md` 和 Core `Contract`／`DuplicateScore` 交叉驗證；Stayman/Jacoby 為 v2 `ConventionProfiles.preview` 預覽且 `UNREVIEWED`，不能推測 BEN 真正的叫牌策略或對手暗手。

## 驗收門檻
- `flutter analyze`、`flutter test`、`flutter build web --release`。
- B4.2 unit：六堂廿一題唯一 ID／schema／雙語、12 題正解與錯誤處理；N/S/E/W Score 正負、定約墩數；Stayman/Jacoby public auction 匹配與競叫 UNKNOWN。
- B4.2 widget：新課程可操作、答錯重試、opt-in C3 紀錄、320px／2× 字體與英文切換。
- 既有 B4.1 與 C3 回歸通過；不變更 Gateway、DDS、牌局規則、正式多玩家模式。

**CI 實際 PASS**：[Flutter CI #38981030736](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38981030736)，來源 Commit `ebcad9a1a04e552f25202475adcc3e03786f368e`。
- Flutter Analyze：`No issues found`
- Flutter tests：**164/164 All tests passed**（含 B4.1、B4.2、C3 與全套 Flutter 回歸）
- Flutter Web Release Build：`Built build/web`
- ChromeDriver 真瀏覽器 Demo E2E：**PASS**（不等於真 BEN 或正式部署）
- [Feature Learning Gate #38981032251](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38981032251)：**PASS**。
- 驗證過程發現 C3 既有 Widget 測試依賴未捲動的 ListView，新增課程使保存開關延後建立；改用 `scrollUntilVisible` 操作真實 UI，保留 C3 保護條件與確認刪除斷言。Android/iOS 實機及模擬器 QA 依既定決策暫停。

## 檔案與回退
- `lib/src/academy/academy_advanced_catalog.dart`：原創進階課程
- `lib/src/academy/academy_catalog.dart`：單一題庫入口
- `lib/src/academy/academy_page.dart`：雙語學院標題
- `test/b4_2_advanced_domain_test.dart`、`test/b4_2_advanced_widget_test.dart` 與 B4.1／C3 回歸 fixture
- 回退時只回退 B4.2 新題庫與題目掛載、改動測試／標題即可；不清除使用者過往 C3 加密紀錄，陌生新題 ID 若已存在歷史仍可安全顯示。
