# M4-F02｜Flutter 自訂約定編輯器：本機版本歷史與執行保護

- Feature ID：M4-F02
- Milestone：M4.2 本機自訂約定編輯器
- 類型：Flutter UI、SharedPreferences Local-only persistence、Immutable archive、雙語
- 工程狀態：**IMPLEMENTED；Flutter CI 實測以最新工作流程為準**
- 學習狀態：**DELIVERED**
- 原始碼：[編輯頁面](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart) · [Local store](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_store.dart) · [CustomConventionArchive](../../../packages/bridge_conventions/lib/src/custom_convention_archive.dart)
- 驗收與測試：[Flutter widget test](../../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart) · [Domain archive test](../../../packages/bridge_conventions/test/custom_convention_archive_test.dart) · [Flutter CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/flutter-single-player.yml)

## 功能目的與實際情境

使用者按 Bridge Academy 上方的「自訂約定」筆記圖示，先選 SAYC／2/1 基礎制度，再選 1NT 點力、Stayman 或 Jacoby 轉移約定，按「儲存新版本」。頁面明確警告**它只是一張本機私人草稿，AI 並沒有依此訓練，不能在真正 Gateway 對局中套用**。

修改之後舊 revision 不會被覆蓋；移除某個設定也會新增修訂，避免因目前編輯結果覆蓋過去的意思。

## 主要程式碼導讀

```dart
var archive = _archive;
if (archive.latest == null) {
  archive = archive.append(_newDraft());
}
final edited = archive.latest!.withRule(
  CustomConventionRule(_slot, _choice),
);
archive = archive.append(edited);
await _storage.save(_base.profileId, archive);
```

在 `SharedPrefsCustomDraftStorage` 中，從 SharedPreferences 讀出的 JSON 不會直接賦予信任；由 `CustomConventionArchive.fromJson` 檢查每個 revision 的正確 base／上一版 hash／唯一欄位和身份。壞資料會顯示錯誤，絕不默默重置後覆寫。這個儲存**只有本裝置／瀏覽器**，不是加密正式帳號同步，也不是伺服器上的合法 GameSystems。

## 為什麼這樣設計

相當於 Android ViewModel + Repository 概念：Widget 操作 UI state，Domain 草稿負責不可變資料與驗證，Storage 處理保存。沒有把 App 的全局 BEN 配置暴露成任意 UI 可更改的 SharedPreferences。

替代方案是立即讓使用者套用到正在玩的 Gateway 牌局，但那會破壞 session 的 immutable `GameSystems` 與服務端引擎相容性；因此先提供教育／準備用的私人草稿。

常見錯誤：`SharedPreferences` 不提供跨裝置同步、交易式歷史或惡意本機攻擊防護；SHA fingerprint 不是簽章。不能拿本機草稿當正式競賽制度。

## 驗證與實際證據

```bash
cd apps/bridge_academy_flutter
flutter pub get
flutter analyze --no-pub
flutter test test/m4_custom_convention_draft_test.dart
```

Widget tests 使用注入式 memory store，測試 save/reopen、zh-TW/en 文字與 `ENGINE_UNVERIFIED`，測試再編輯／移除的版本連結。正式 SharedPreferences 在 Android/iOS 實機重啟下的 fsync/rollback **NOT RUN**，原先的裝置 QA 暫緩政策維持。

### 已執行的 CI

**[CI #40108357113](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40108357113) PASS**：`flutter analyze --no-pub` No issues，指定兩個 Flutter Widget tests **2/2 PASS**（儲存重開、中文/英文、revision chain、移除以及 `ENGINE_UNVERIFIED`）；同一 CI 的 Dart Domain 20/20。真 SharedPreferences 物理裝置 process restart 與 UI 裝置 QA 維持 NOT RUN。

## 練習與自我檢驗

**思考題（1 題）：** 當你重新開啟 App 看到本機草稿 `revision=3`，為什麼這不能直接出現在遊戲的「可玩搭檔制度」清單？

**5–15 分鐘小練習（可選）：** 在 Widget Test 先存 1NT 12–14，再移除規則，確認 revision 遞增且原始版本可由 archive 重現。

**完成標準：** 能區分本機 draft repository、Gateway server-owned game authority、模型 engine capability 三者的責任。

## 下一步

M4 的「真正可玩自訂卡」需要另外建立可證明某組 rule 改動已由 BEN／BBA 路由支援的 allowlisted capability、專家 review／golden fixtures 與相容性證據。不得透過 UI 將未驗證的草稿強制發送到正式引擎。
