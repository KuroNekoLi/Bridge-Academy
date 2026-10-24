# M4-F04｜公開叫牌片段預覽：知道使用者設定，不假裝知道 AI 真正推論

- Feature ID：M4-F04
- Milestone：M4.4
- 類型：安全輸入、白名單解析、Flutter 預覽、雙語說明
- 工程狀態：**IMPLEMENTED；CI 以最新版成功 run 為準**
- 學習狀態：**DELIVERED**
- 原始碼：[CustomConventionReviewer.preview](../../../packages/bridge_conventions/lib/src/custom_convention_review.dart) · [Flutter Editor](../../../apps/bridge_academy_flutter/lib/src/conventions/custom_draft_page.dart)
- 驗收與測試：[Domain](../../../packages/bridge_conventions/test/custom_convention_review_test.dart) · [Widget](../../../apps/bridge_academy_flutter/test/m4_custom_convention_draft_test.dart)

## 功能目的與實際情境

在自訂叫牌編輯器選 1NT–Pass–2♣、設定 Stayman 後，玩家希望看到自己寫的意義。但如果這項卡尚未與真 BEN／BBA 對齊，應顯示「玩家草稿：Stayman」、「模型理解未知」，而不是顯示虛構的 AI 叫牌解釋。

## 主要程式碼導讀

```dart
final preview = CustomConventionReviewer.preview(
  draft, '1NT-PASS-2C');
assert(preview.auction == '1NT-P-2C');
assert(preview.userSelectedMeaning == 'STAYMAN');
assert(!preview.engineVerified);
```

`preview` 只讀草稿與公開叫牌序列，不讀 `GameState` 的未公開資訊，也不使用 DDS。它把大寫、PASS 簡寫以及 1N/1NT 做正規化，僅接受有限 token 和長度。遇到未定義的片段則回傳 `baseUnverified` 或 `noRule`，**不能猜測**。Flutter 以固定 rule slot 的公開 auction 顯示預覽，另顯示「僅使用者編輯，非 AI 引擎證據」。

## 為什麼這樣設計

這類預覽是一個 **pure function**：同樣的草稿版本與公開 auction，永遠得到同樣的描述。相對於叫 LLM 自己猜測，這樣不會因模型不同而胡亂聲稱 2♣ 是 Stayman。未來可在有權限的伺服器端回傳真正的 engine explanation，並附獨立來源與 artifact version。

常見錯誤：把沒有設定的叫牌直接寫成「標準 SAYC」含義。任何系統都存在競叫、passed hand 與 exceptions，不可以因為選了 base 就跳過驗證。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart test test/custom_convention_review_test.dart
cd ../../apps/bridge_academy_flutter
flutter test test/m4_custom_convention_draft_test.dart
```

驗證已編輯 Stayman 有明確 author source；未覆蓋片段回 `UNKNOWN`；不接受注入奇怪 call 或超長輸入；Flutter 顯示 engine-unverified 提示。真 AI 訓練/約定對手 reader：**NOT RUN**。

## 練習與自我檢驗

**思考題（1 題）：** 如果玩家沒有設定 1NT–Pass–2♦，介面可以直接宣稱 BEN 必然按「轉移紅心」理解嗎？為什麼？

**5–15 分鐘小練習：** 在 `custom_convention_review_test.dart` 對 `1NT-P-2H` 未設定時增加 `no verified meaning` 斷言。

**完成標準：** 能說明 UI 顯示的 user intention、actual engine meaning、public- vs private-view 資訊邊界。

## 下一步

M4.5 支援草稿備份與匯入，但不能以從剪貼簿貼上資料就取得引擎權限。
