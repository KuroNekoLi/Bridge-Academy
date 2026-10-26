# M2-F53｜以練習意圖整理入口，切換頁面保留對局

- Feature ID：M2-F53
- Milestone：M2／A3 UI 延伸
- 類型：Flutter UI
- 工程狀態：VERIFIED／ENGINEERING_PASS（本機限定，實際命令與範圍見驗收）
- 學習狀態：DELIVERED；尚無 PRACTICED／MASTERED 證據
- 原始碼：[工作區與 Session composition](../../../apps/bridge_academy_flutter/lib/src/bridge_app.dart)、[練習卡元件](../../../apps/bridge_academy_flutter/lib/src/widgets/bridge_practice_hub.dart)、[雙語文案](../../../apps/bridge_academy_flutter/lib/src/app_copy.dart)
- 驗收與測試：[Workspace 測試](../../../apps/bridge_academy_flutter/test/m2_practice_workspace_test.dart)、[本輪驗收](../../product/UX_WORKSPACE_ACCEPTANCE.md)

## 功能目的與實際情境

玩家原本面對一長列設定／開局／各種練習按鈕，很難看出可做什麼。現在用自由打牌、四副、專心主打、每日、叫牌及歷史等入口說明各自目的；打牌／學院／複盤／我的連到現有可操作功能，Gateway 沒有雲端歷史時不顯示假的複盤入口。牌局開始後，牌桌在其他練習前面。

在「我的」切換語言、開啟自訂卡或教練後回到牌桌，不應意外重發一副牌。按重新發牌時，如果仍在進行，要先讓玩家選擇繼續目前牌局或明確放棄。

## 主要程式碼導讀

`BridgeAcademyApp` 仍在 initState 建立一次本機 `BridgeSession` 或獨立 `GatewayGameSession`；頁籤只改 `_destination`。本機 Play/Review 共用同一個 `BridgeTable` State，而「我的」透過 IndexedStack 切換可見性：

```dart
BridgeTable(
  session: _session!,
  copy: copy,
  historyOnly: _destination == 2,
)
```

`BridgePracticeAction` 是標題、說明、圖示與既有 command button 的呈現資料。按鈕仍呼叫 `session.startFourBoardPractice` 等原本命令，不在卡片元件複製開局／計分／儲存邏輯。

`_startFreePlay` 收到使用者確認後才呼叫 `session.newGame`；取消直接返回。這個 async 方法在 dialog 返回後檢查 mounted 與 busy，避免頁面已離開仍更新 UI。

## 為什麼這樣設計

這和 Android 的 ViewModel 存活時間很相似：頁籤的視覺狀態和牌局的 domain 狀態是不同生命週期。改頁籤只切換目的地，不重新 new 一個 ViewModel／Session，也不在 Widget 產生完整牌局 DTO。

替代方案是每個頁籤 push 一個全新牌桌；比較容易寫，卻容易重建預設座位、叫牌選項和中途對局。IndexedStack 保留本機畫面狀態，代價是未顯示頁也占少量記憶體。本輪頁面數有限；未來有大型 live table 時可改 route-owned controller，仍須維持相同邊界。

常見陷阱：英文放大到 2x 後，花色選單的文字自然寬度可能超過 320px。本輪測試真實抓到這個問題，因此選單採有界寬度＋isExpanded＋ellipsis，完整花色仍有本地化語意。

## 驗證與實際證據

Windows、本機 Flutter 3.47.8／Dart 3.13.7。可重現：

```powershell
flutter test --no-pub test/m2_practice_workspace_test.dart --reporter expanded
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub --release
```

測試斷言：頁籤切換不改 version／手牌；Review 不顯示 active table；學院能返回；未完牌取消重發保留事件及手牌，確認才 reset；活動牌桌在 launcher 前；320/768/1280px、2x 字體與中英切換無 overflow。確切最後執行結果與 CI 狀態記於 [驗收紀錄](../../product/UX_WORKSPACE_ACCEPTANCE.md)，不要把教學檔的存在當作測試通過。

Widget test 使用 Demo／本機 fixture，不能證明真 BEN、正式部署或裝置輔具體驗；Android/iOS QA 仍未執行。

## 練習與自我檢驗

**思考題（1 題）：** 如果把 `BridgeSession()` 放進每次頁籤 build，為什麼「切去設定再回來」可能丟失牌局？

**5–15 分鐘小練習：** 在 workspace test 中，先開局叫 1NT，再依序切 Review → Me → Play，斷言事件 version 和 ownCards 都不變。

**完成標準：** 能分辨畫面目的地、Widget State 與權威對局狀態三者；測試比較實際版本／手牌而不是 PlayerView 的物件 identity，因為 getter 可回傳新的不可變投影。

## 下一步

U3 將改善單屏牌桌與動畫。動畫完成與否不能變成對局是否提交成功的唯一判準；詳見 [全產品交付計畫](../../product/PRODUCT_COMPLETION_PLAN_2026_10.md)。
