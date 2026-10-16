# M2-F43｜B4 橋牌學院：版本化教材、狀態去重與 Flutter 答題流程

- Feature ID：M2-F43
- Milestone：M2／B4.1 (P2)
- 類型：Flutter UI、資料模型、原創教學
- 工程狀態：SCOPED VERIFIED（Flutter Analyze + 128/128 + Web Build）
- 學習狀態：DELIVERED
- 原始碼：apps/bridge_academy_flutter/lib/src/academy/academy_models.dart、academy_catalog.dart、academy_page.dart、bridge_app.dart
- 驗收與測試：apps/bridge_academy_flutter/test/b4_academy_domain_test.dart、b4_academy_widget_test.dart；[CI 128/128 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909904915)

## 功能目的與實際情境
剛開始學橋牌的玩家可以從牌桌進入學院，先了解基本規則，再做九道原創題。答錯會看到原因且能重試；只在正確回答時累積「本次已完成」。玩家離開學院時原牌局不被影響。這與 B3.2 的叫牌約定不是同一個功能，不依賴 BEN。

## 主要程式碼導讀
- bridge_app.dart AppBar 的 academy_open 使用 Navigator.push(MaterialPageRoute) 將 AcademyPage 加在獨立 Route；Flutter 原牌桌留在下層，避免另建遊戲 Session。
- AcademyCatalog.lessons 儲存三堂、九道雙語固定題；AcademyValidator.validate 在顯示前檢查 schemaVersion、ID、選項、正解和雙語完整性。
- AcademyPage._submit 將已選 option 變成 AcademyAnswer（包含 version/IDs），交給 AcademyPractice.submit 判定正誤，回傳 AcademyFeedback。
- AcademyPage._advance 僅在正確後前往下一題；_retry 僅在錯誤回饋後清掉選項和回饋。作答後提交按鈕從 widget tree 消失，避免 UI 重複提交。
- AcademyPractice 的核心邏輯如下（摘自實際程式）：

    final correct = question.isCorrect(answer.selectedOptionId);
    return AcademyFeedback(
      correct: correct,
      newlyCompleted: correct && _completed.add(question.questionId),
    );

Dart 的 Set.add() 在元素已存在時回傳 false，和 Kotlin MutableSet.add() 很接近。透過短路運算子，答錯絕不寫入已完成集合；同一題答對第二次也不會增加已完成題數。

## 為什麼這樣設計
這是 Clean Architecture 的最小練習示例：資料模型和 Catalog 不依賴 Flutter；單頁的 AcademyPractice 不碰 GameState、PBN、BridgeSession；Widget 管理由選項、正誤、下一題組成的畫面狀態。相較將學習結果直接寫 SharedPreferences，本輪選擇「明確 session-only」，避免繞過 A2 的加密要求，也不與 C3 後續持久化任務衝突。

常見陷阱：用問題清單 index 當持久化 ID，教材排序後答題紀錄會配錯；或將「按下提交」當成完成，錯誤答案會讓進度虛增。現在 stable questionId 與 correct-only Set 各自處理。

## 驗證與實際證據
驗證目標：三課九題 ID 唯一、原創雙語必填、每題正解、答錯不增加完成、重複提交去重、舊版本拒絕、Json roundtrip、登入主 App 進入／離開、繁英切換、320/375px 2× 字體縮放。

命令：
    cd apps/bridge_academy_flutter
    flutter analyze
    flutter test test/b4_academy_domain_test.dart
    flutter test test/b4_academy_widget_test.dart
    flutter test
    flutter build web

**GitHub Actions EXECUTED / PASS**：[B4 Branch CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909904915)，程式碼 SHA `eea21bf293ba6e6c3eb7f3b89b92d2b718456044`，`flutter analyze` 0 問題、`flutter test` **128/128 通過**，`flutter build web --release` 成功。包含 320/375px、2× 字體排版的可重現 Widget 測試。**NOT RUN**：Android/iOS 實機、獨立 Chrome E2E、BEN 與真人教學效果；不得以此 CI 超額宣稱。

## 練習與自我檢驗
**思考題（1 題）：** 為什麼 C3 的長期學習進度應該保存 stable questionId，而不能保存「第 3 堂的第 2 題」？

**5–15 分鐘小練習（可選）：** 將第三堂最後一題重排到第一題，再重新運行 b4_academy_domain_test.dart，確認已有 questionId 的語義與正解不變。

**完成標準：** 能解釋 ID、版本遷移、去重與錯題不得算完成，以及單頁與持久化的分工。尚未實際作答，不標記 PRACTICED／MASTERED。

## 下一步
C3 使用 docs/handoff/B4_LEARNING_PROGRESS_CONTRACT.md 的四個穩定欄位設計加密持久化；後續若增加更進階的叫牌教材，需有明確約定版本與外部專家審核，不可拿教材描述冒充 BEN 策略。
