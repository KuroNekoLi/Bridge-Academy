# M5.1–M5.2 — 依來源解釋公開叫牌：限定範圍工程驗收

> 2026-10-25（Asia/Taipei） · **SCOPED ENGINEERING PASS（CI #40154923631）** · 不代表 M5 AI Coach 已全面完成。
>
> 交付判定：公開叫牌 Domain Review／雙語 Flutter 教學沙盒；真實 BEN/BBA 策略解釋、候選叫品評估及賽後專家差異仍 **NO-GO**。

## M5.1～M5.3 具體執行證據（2026-10-25）

**SCOPED ENGINEERING PASS** — [GitHub Actions #40154923631](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923631) `completed/success`，Ubuntu 24.04、Flutter stable（非 Android/iOS 真機或 emulator）。

| 工作 | 實際結果 |
| --- | --- |
| Dart `bridge_conventions` 所有單元測試、含 M2/M3/M4 與 M5.1 source pins/UNKNOWN | **36/36 PASS** |
| Dart analyzer `--fatal-infos` | No issues found |
| Flutter analyzer `--no-pub` | No issues found |
| Flutter M5 Widget（雙語／本機草稿／惡意內容／finished-game snapshot／LEGACY） | **5/5 PASS** |
| Feature Learning Gate | [#40154923670](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40154923670) success |
| 真 BEN／BBA 候選決策、專家級語義 Golden、模型私有推理 | **NOT RUN／尚無憑據** |
| 真 Gateway 完局後手機點擊 E2E、VPS 與裝置 QA | **NOT RUN** |

重點回歸：完成的歷史 Gateway 若使用 `LEGACY_UNVERIFIED`，Coach UI 會保留這個真實 ID 並維持未驗證狀態，**不能**為了下拉選單顯示就冒充 `BA-SAYC`。

## 這一步能做什麼？

首頁新增「叫牌教練」。使用者輸入公開叫牌，例如 `1NT P 2C P`，選擇 Dealer、南北與東西的**固定制度版本**，畫面會顯示每口叫牌的實際座位、公開叫品、制度 ID 與 profile fingerprint。這是**公開資訊整理**，不會讀其他人的隱藏手牌，也不會讓學習用的資料改變正在進行的牌局。

M5.2 能勾選本機已建立的 SAYC／2/1 南北方自訂草稿，顯示指定 auction 上**使用者自己填的約定意義**，並一律標記 `USER_DRAFT`、`engineVerified=false`。同一個局，兩邊可能使用相同 SAYC base，但南北的本機草稿**不能被誤套到東西**。本機草稿不是 Gateway 的被授權制度。

任何不符合已實作、經查核的規則的叫牌都會回報 `UNKNOWN`；有限約定位置若未被專家核可，則回報 `baseNotReviewed`。目前全部 `verifiedCandidateCalls=[]`、`expertApproved=false`、`explainsBenPrivateReasoning=false`。這是誠實保留，不是未完成的推薦被偷偷填入固定值。

## 權限／信任架構

```text
App 中明確選擇的 trusted ConventionCatalog profiles
   + dealer seat + public auction calls (≤64)
   + OPTIONAL reviewed-local-archive: NS intent only
→ PublicAuctionCoach.review(...) (pure Dart; NO Deal/GameState)
→ chronological N/E/S/W source identity & current GameSystems fingerprint
→ UNKNOWN / baseNotReviewed / USER_DRAFT
→ bilingual Coach page (no best bid, no private AI chain of thought)
```

安全條件：未經使用者勾選不讀本機自訂卡，格式和長度不合格拒絕；禁止其他欄位、未經驗證的自訂 AI 模型、假裝 `SUPPORTED` 的結論。這個頁面**沒有**將單純 token 格式驗證宣稱為完整叫牌合法性判定：是否可 Double/Redouble、何時 auction 結束，仍屬 Bridge Core／未來安全 snapshot integration。

## 實際交付

| Feature | 原始碼與驗證 | 功能 |
| --- | --- | --- |
| M5-F01 | [Domain coach](../../packages/bridge_conventions/lib/src/auction_coach.dart) · [tests](../../packages/bridge_conventions/test/auction_coach_test.dart) | dealer/seat 歸屬、NS/EW immutable profile provenance、UNKNOWN-by-default、無未經證實的候選叫品 |
| M5-F02 | [Flutter Coach](../../apps/bridge_academy_flutter/lib/src/conventions/auction_coach_page.dart) · [Widget tests](../../apps/bridge_academy_flutter/test/m5_auction_coach_test.dart) | 雙語教學頁、本機南北草稿可選對照、拒絕壞資料，不會干擾 Gateway |
| CI | [M5 專用流程](../../.github/workflows/m5-coach.yml) | Dart analyzer + Domain 全回歸 + Flutter analyzer + Coach Widget tests；不執行裝置 QA |

重現指令：

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
cd ../../apps/bridge_academy_flutter
flutter pub get && flutter analyze --no-pub
flutter test test/m5_auction_coach_test.dart --reporter expanded
```

## M4 決策與 M5 釋出 Gate

M4.1–M4.7 本機草稿／專家待審清單已完成，證據見 [M4 Acceptance](M4_CUSTOM_CONVENTION_DELIVERY_ACCEPTANCE.md)／[CI #40139553945](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40139553945)。但**可執行的自訂 AI 制度仍 NO-GO**：未提供實際 BEN/BBA 版本專屬 capability mapping、已批准 rule card、100+ 專家 Golden 與真實模型配合。這些不是 M5 教學介面能自行解除的 gate。

M5 接下來需要：來源分層的**實際** BEN/BBA 候選叫品，明確可重現的 server-side play-test data，雙語 reviewed meaning、反例，與賽後客觀 IMP/MP／策略對照。不能用 LLM 自行生成未觀測的「AI 當下為什麼這樣想」。

**Release 狀態：M5.1／M5.2 工程範圍與 M4 草稿工程可獨立核可；M4 executable custom AI 與 M5 完整智慧教練仍 NO-GO。** Android/iOS 模擬器／實機 QA 依既有使用者暫緩，不啟動。
