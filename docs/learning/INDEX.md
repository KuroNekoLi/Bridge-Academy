# Feature Learning Index — Bridge Academy

本索引是「每功能一份可追溯教學」的入口；規範及格式見 [README](README.md) 與 [Template](FEATURE_LESSON_TEMPLATE.md)。

- DELIVERED：文件已提供，未暗示使用者理解。
- PRACTICED：使用者實際作答或完成練習。
- MASTERED：使用者在回答或實作展示理解，且有可引用的明確證據。

| Feature | 概念 | 教學 | 真實實作／測試 | 學習狀態 |
| --- | --- | --- | --- | --- |
| M1-F01 | 四家 Pass Out、Reducer 與事件完整性 | [M1-F01 — Pass Out](features/M1_F01_PASS_OUT.md) | [game.dart](../../packages/bridge_core/lib/src/game.dart) · [auction_test.dart](../../packages/bridge_core/test/auction_test.dart) · [M1 CI](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38672191891) | DELIVERED |
| M2-F01 | PlayerView、私有手牌的信任邊界 | [M2-F01 — PlayerView](features/M2_F01_PLAYER_VIEW.md) | [player_view.dart](../../packages/bridge_core/lib/src/player_view.dart) · [測試](../../packages/bridge_core/test/player_view_test.dart) · [驗收](../m2/M2_FOUNDATION_REPORT.md) | DELIVERED |
| M2-F02 | 本地 Game Coordinator、樂觀並行控制 | [M2-F02 — Coordinator](features/M2_F02_LOCAL_COORDINATOR.md) | [coordinator](../../packages/bridge_core/lib/src/single_player_coordinator.dart) · [測試](../../packages/bridge_core/test/single_player_coordinator_test.dart) · [驗收](../m2/M2_FOUNDATION_REPORT.md) | DELIVERED |

| M2-F03 | BEN Adapter，最低權限的 HTTP 參數、合法提案、timeout | [M2-F03 — BEN Adapter](features/M2_F03_BEN_ADAPTER.md) | [BenBotPolicy](../../packages/bridge_ben_adapter/lib/src/ben_bot_policy.dart) · [契約測試](../../packages/bridge_ben_adapter/test/ben_bot_policy_test.dart) · [驗收報告](../m2/M2_BEN_ADAPTER_REPORT.md) | DELIVERED |

| M2-F04 | 真 BEN HTTP 完整牌局測試 | [M2-F04 教學](features/M2_F04_REAL_BEN_SMOKE.md) | [實測程式](../../packages/bridge_ben_adapter/bin/live_ben_smoke.dart) · [驗收紀錄](../m2/M2_F04_REAL_BEN_ACCEPTANCE.md) | DELIVERED |

| M2-F05 | Flutter UI 單向資料流、Dummy 控制、zh-TW/en | [M2-F05 — Flutter 牌桌](features/M2_F05_FLUTTER_TABLE.md) | [Flutter App](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart) · [Widget tests](../../apps/bridge_academy_flutter/test/bridge_app_test.dart) · [驗收](../m2/M2_F05_FLUTTER_TABLE_REPORT.md) | DELIVERED |

| M2-F06 | 真 ChromeDriver 整合測試／小螢幕 Responsive | [M2-F06 Chrome 測試](features/M2_F06_CHROME_RESPONSIVE.md) | [browser test](../../apps/bridge_academy_flutter/integration_test/browser_table_test.dart) · [responsive tests](../../apps/bridge_academy_flutter/test/responsive_layout_test.dart) · [驗收](../m2/M2_F06_BROWSER_QA_REPORT.md) | DELIVERED |

| M2-F07 | Chrome 真 BEN、async I/O 與 Demo 防降級驗收（[最新版真 BEN CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38682472896)） | [M2-F07 真 BEN UI 教學](features/M2_F07_REAL_BEN_CHROME.md) | [browser BEN test](../../apps/bridge_academy_flutter/integration_test/browser_ben_test.dart) · [真實 CI 規則](../../.github/workflows/ben-flutter-browser.yml) · [驗收](../m2/M2_F07_REAL_BEN_BROWSER_ACCEPTANCE.md) | DELIVERED |

| M2-F08 | Android Emulator 原生 UI 與跨平台驗收 | [M2-F08 教學](features/M2_F08_ANDROID_EMULATOR.md) | [Android UI Test](../../apps/bridge_academy_flutter/integration_test/android_table_test.dart) · [Android CI](../../.github/workflows/flutter-android-emulator.yml) · [驗收](../m2/M2_F08_ANDROID_EMULATOR_ACCEPTANCE.md) | DELIVERED |
| M2-F09 | 真 BEN 莊家與 Dummy Actor/HandOwner | [M2-F09 教學](features/M2_F09_BEN_DECLARER_UI.md) | [BEN Declarer Test](../../apps/bridge_academy_flutter/integration_test/browser_ben_declarer_test.dart) · [BEN CI](../../.github/workflows/ben-flutter-browser.yml) · [驗收](../m2/M2_F09_BEN_DECLARER_UI_ACCEPTANCE.md) | DELIVERED |

| M2-F10 | 固定教學牌與新隨機練習牌；測試 Seed 與 PBN | [M2-F10 隨機發牌教學](features/M2_F10_SHUFFLED_DEALS.md) | [Bridge Core](../../packages/bridge_core/lib/src/model.dart) · [Flutter Session](../../apps/bridge_academy_flutter/lib/src/bridge_session.dart) · [驗收](../m2/M2_F10_SHUFFLED_DEALS_ACCEPTANCE.md) | DELIVERED |

| M2-F11 | Event Sourcing、規則回放與 PlayerView 隱私（[Core/Flutter/真 Chrome 回放 PASS](../m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md)；[Android 回放已通過](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38693616421)，[Domain 47/47 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38714671479)） | [M2-F11 終局歷史教學](features/M2_F11_FINISHED_REPLAY.md) | [Core Replay Test](../../packages/bridge_core/test/completed_replay_test.dart) · [Domain hardening](../../packages/bridge_core/test/replay_domain_hardening_test.dart) · [Flutter UI Test](../../apps/bridge_academy_flutter/test/completed_replay_test.dart) · [驗收](../m2/M2_F11_FINISHED_REPLAY_ACCEPTANCE.md) | DELIVERED |

## 新功能加入方式
1. 直接推送 master 時，仍給每個獨立功能唯一 ID：Mx-Fxx。
2. 建立 docs/learning/features/Mx_Fxx_TOPIC.md，填入實作路徑和實測證據。
3. 更新索引本表，Commit 或工程驗收文件附功能、實作、測試與教材對應。
4. 推送後審查教學是否準確，完成時在 Chat 用一個問題引導學習。
5. 不因 Agent 自己生成教材就將進度提升為 PRACTICED 或 MASTERED。

## M1 其他功能的教學回補候選
合約／莊家判定、Double／Redouble、Actor 與 Hand Owner、Follow Suit、Duplicate Scoring、事件回放與完整手牌隱私。此處只是**尚未交付的回補清單**，不代表已有教材或已驗收學習。
| M2-F12 | Phase A1：標準牌號、發牌者／局況、同副重打與下一副 | [M2-F12 教學](features/M2_F12_BOARD_MANAGEMENT.md) | [BoardDefinition](../../packages/bridge_core/lib/src/board_definition.dart) · [Session/UI 測試](../../apps/bridge_academy_flutter/test/board_management_test.dart) · [驗收](../product/P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md) | DELIVERED |
