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

| M2-F17 | A2.5：跨重啟保存回退警告與確認，Fail Closed（[Flutter 50/50 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38738604483)） | [M2-F17 教學](features/M2_F17_DURABLE_RECOVERY_CONSENT.md) | [session_persistence.dart](../../apps/bridge_academy_flutter/lib/src/session_persistence.dart) · [Recovery 測試](../../apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart) · [驗收](../product/P1_A2_5_DURABLE_RECOVERY_CONSENT_ACCEPTANCE.md) | DELIVERED |

| M2-F18 | A2.6：真 Android 兩次 force-stop 後，回退警告與玩家確認必須持續 | [M2-F18 教學](features/M2_F18_ANDROID_ROLLBACK_CONSENT.md) | [三程序測試](../../apps/bridge_academy_flutter/scripts/android_rollback_consent_e2e.sh) · [專項 CI](../../.github/workflows/android-rollback-consent.yml) · [驗收](../product/P1_A2_6_ANDROID_ROLLBACK_CONSENT_ACCEPTANCE.md) | DELIVERED |

| M2-F19 | A2.7 AES-GCM 密文、交易式 SQLite 與舊檔遷移（[Flutter 60/60 PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38744797200)，裝置驗收延後） | [M2-F19 教學](features/M2_F19_SECURE_TRANSACTIONAL_STORAGE.md) | [Secure Store](../../apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart) · [故障注入測試](../../apps/bridge_academy_flutter/test/secure_checkpoint_test.dart) · [驗收](../product/P1_A2_7_SECURE_TRANSACTIONAL_STORAGE_ACCEPTANCE.md) | DELIVERED |

| M2-F21 | A3.1 Bridge Table UI V2（Flutter 67/67 + Chrome、true BEN CI 驗證）：座位、明手、牌號與手牌的 Presentation Widget 分層 | [M2-F21 教學](features/M2_F21_BRIDGE_TABLE_COMPONENTS.md) | [UI 元件](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart) · [Widget tests](../../apps/bridge_academy_flutter/test/a3_table_components_test.dart) · [A3 規格](../product/A3_BRIDGE_TABLE_V2_SPEC.md) | DELIVERED |

| M2-F22 | A3.2 叫牌盒 State Hoisting（Flutter 69/69、Chrome Demo／真 BEN 驗證）、Session Callback、合法性權威 | [M2-F22 教學](features/M2_F22_BIDDING_BOX.md) | [BiddingBox](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_bidding_box.dart) · [Widget tests](../../apps/bridge_academy_flutter/test/a3_bidding_box_test.dart) · [A3 規格](../product/A3_BRIDGE_TABLE_V2_SPEC.md) | DELIVERED |

| M2-F23 | A3.3 響應式四方牌桌、公開歷史工具列、immutable Replay（Flutter 74/74 + Demo／真 BEN Chrome PASS） | [M2-F23 教學](features/M2_F23_TABLE_TOOLBAR_REPLAY.md) | [UI](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_toolbar.dart) · [測試](../../apps/bridge_academy_flutter/test/a3_table_toolbar_test.dart) · [規格](../product/A3_BRIDGE_TABLE_V2_SPEC.md) | DELIVERED |

| M2-F24 | A3.4 卡牌語意、48×48 點擊區域、焦點順序、文字放大／雙語（80/80 Flutter、Chrome Demo／真 BEN PASS） | [M2-F24 教學](features/M2_F24_ACCESSIBILITY.md) | [元件](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_table_components.dart) · [測試](../../apps/bridge_academy_flutter/test/a3_accessibility_test.dart) · [規格](../product/A3_BRIDGE_TABLE_V2_SPEC.md) | DELIVERED |

| M2-F25 | A4.1 HTTPS POST Gateway Client、短效 Token 注入、安全 API 契約（Dart 23/23 Mock Adapter CI PASS） | [M2-F25 教學](features/M2_F25_BEN_GATEWAY.md) | [Gateway](../../packages/bridge_ben_adapter/lib/src/ben_gateway_transport.dart) · [Tests](../../packages/bridge_ben_adapter/test/ben_gateway_transport_test.dart) · [Contract](../product/A4_GATEWAY_CONTRACT_V1.md) | DELIVERED |

| M2-F26 | A4.2 匿名 Bearer Session、Rate Limiting、HTTP API 信任邊界（localhost HTTP 14/14 CI PASS） | [M2-F26 教學](features/M2_F26_ANONYMOUS_GATEWAY.md) | [Loopback Gateway](../../services/bridge_gateway/lib/src/gateway_service.dart) · [HTTP tests](../../services/bridge_gateway/test/gateway_service_test.dart) · [A4.2 acceptance](../product/A4_GATEWAY_A4_2_ACCEPTANCE.md) | DELIVERED |

| M2-F27 | A4.3.1 BEN Loopback Worker（HTTP 20/20 PASS；真 BEN bid/lead/play PASS） | [M2-F27 教學](features/M2_F27_BEN_LOOPBACK_WORKER.md) | [Loopback Backend](../../services/bridge_gateway/lib/src/ben_loopback_backend.dart) · [HTTP tests](../../services/bridge_gateway/test/ben_loopback_backend_test.dart) · [驗收](../product/A4_GATEWAY_A4_3_1_ACCEPTANCE.md) | DELIVERED |

| M2-F28 | A4.3.2 Server-owned Bridge Core 牌局、expected_version、request_id 去重（Gateway 27/27 CI PASS） | [M2-F28 教學](features/M2_F28_SERVER_GAME_AUTHORITY.md) | [Game Authority](../../services/bridge_gateway/lib/src/authoritative_game.dart) · [HTTP tests](../../services/bridge_gateway/test/authoritative_game_http_test.dart) · [驗收](../product/A4_GATEWAY_A4_3_2_ACCEPTANCE.md) | DELIVERED |

| M2-F29 | A4.3.2b AES-GCM 加密 Checkpoint、實際 Dart SIGKILL 重啟（32/32 PASS）、Bot 逐步恢復與去重 | [M2-F29 教學](features/M2_F29_ENCRYPTED_GATEWAY_RESTART.md) | [Encrypted store](../../services/bridge_gateway/lib/src/encrypted_session_store.dart) · [Tests](../../services/bridge_gateway/test/encrypted_restart_test.dart) · [驗收](../product/A4_GATEWAY_A4_3_2B_ACCEPTANCE.md) | DELIVERED |

| M2-F30 | A4.3.3 真 BEN Gateway 完整 52 張牌／13 墩／計分／版本驗收（Full-game CI PASS） | [M2-F30 教學](features/M2_F30_REAL_BEN_GATEWAY_FULL_GAME.md) | [Full-game runner](../../services/bridge_gateway/bin/live_gateway_ben_full_game.dart) · [真 BEN CI](../../.github/workflows/ben-gateway-real.yml) · [驗收](../product/A4_GATEWAY_A4_3_3_ACCEPTANCE.md) | DELIVERED |

| M2-F31 | A4.4 Flutter 伺服器權威 Gateway Session、斷線安全重送、隱私回應拒絕及 zh-TW/en（Flutter 86/86 + Web Build + Chrome Demo CI PASS） | [M2-F31](features/M2_F31_FLUTTER_GATEWAY_SESSION.md) | [Gateway API](../../apps/bridge_academy_flutter/lib/src/gateway_http_api.dart) · [Session](../../apps/bridge_academy_flutter/lib/src/gateway_game_session.dart) · [Flutter tests](../../apps/bridge_academy_flutter/test/a4_gateway_integration_test.dart) · [驗收](../product/A4_GATEWAY_A4_4_ACCEPTANCE.md) | DELIVERED |

| M2-F32 | 真 Chrome→Gateway→BEN 13 墩 E2E PASS；429 配額與開發上限 | [M2-F32 教學](features/M2_F32_REAL_BROWSER_GATEWAY.md) | [Live browser test](../../apps/bridge_academy_flutter/integration_test/browser_gateway_real_test.dart) · [BEN Chrome CI](../../.github/workflows/ben-flutter-browser.yml) · [驗收](../product/A4_GATEWAY_A4_4_ACCEPTANCE.md) | DELIVERED |

| M2-F33 | A5.1 玩家可用歷史牌局、加密終局封存與跨局複盤（Flutter 91/91 + Web + Chrome Demo PASS） | [M2-F33 教學](features/M2_F33_COMPLETED_HISTORY.md) | [歷史畫面](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [加密 Store](../../apps/bridge_academy_flutter/lib/src/completed_history_store.dart) · [Flutter tests](../../apps/bridge_academy_flutter/test/a5_history_test.dart) · [A5.1 驗收](../product/A5_1_HISTORY_ACCEPTANCE.md) | DELIVERED |

| M2-F34 | A5.2 歷史搜尋／篩選／5 筆分頁／刪除確認及加密 tombstone（Flutter 94/94 PASS、lint 修復教學已同步） | [M2-F34 教學](features/M2_F34_HISTORY_MANAGEMENT.md) | [History UI](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [Encrypted Store](../../apps/bridge_academy_flutter/lib/src/completed_history_store.dart) · [Tests](../../apps/bridge_academy_flutter/test/a5_history_management_test.dart) · [驗收](../product/A5_2_HISTORY_MANAGEMENT_ACCEPTANCE.md) | DELIVERED |

| M2-F35 | A5.3.1 歷史終局 PBN 匯出：雙語確認、52 張原始牌張、完整叫牌、隱私警告（Flutter 97／97 + Web Build + Chrome Demo PASS） | [M2-F35 教學](features/M2_F35_COMPLETED_PBN_EXPORT.md) | [PBN 產生器](../../apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart) · [可操作畫面](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [Flutter 測試](../../apps/bridge_academy_flutter/test/a5_pbn_export_test.dart) · [驗收](../product/A5_3_1_PBN_EXPORT_ACCEPTANCE.md) | DELIVERED |

| M2-F36 | A5.3.2 完整 PBN 十三墩 [Play] 匯出（Flutter 97/97 + Web CI PASS） | [M2-F36 教學](features/M2_F36_PBN_PLAY_EXPORT.md) | [PBN serializer](../../apps/bridge_academy_flutter/lib/src/completed_pbn_export.dart) · [Tests](../../apps/bridge_academy_flutter/test/a5_pbn_export_test.dart) · [驗收](../product/A5_3_2_PBN_PLAY_ACCEPTANCE.md) | DELIVERED |

| M2-F37 | A5.3.3 本機 PBN 匯入：貼上完整牌局、Bridge Core 逐事件驗證、加密複盤（Flutter 101/101 CI PASS） | [M2-F37 教學](features/M2_F37_COMPLETED_PBN_IMPORT.md) | [Parser](../../apps/bridge_academy_flutter/lib/src/completed_pbn_import.dart) · [匯入畫面](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [測試](../../apps/bridge_academy_flutter/test/a5_pbn_import_test.dart) · [驗收](../product/A5_3_3_PBN_IMPORT_ACCEPTANCE.md) | DELIVERED |

| M2-F38 | A5.4 近期歷史統計：成約率、Pass Out、玩家得分與搜尋篩選（Flutter 105/105 PASS） | [M2-F38](features/M2_F38_HISTORY_STATISTICS.md) | [History statistics](../../apps/bridge_academy_flutter/lib/src/history_statistics.dart) · [Player UI](../../apps/bridge_academy_flutter/lib/src/widgets/bridge_history_panel.dart) · [Tests](../../apps/bridge_academy_flutter/test/a5_history_statistics_test.dart) · [驗收](../product/A5_4_HISTORY_STATISTICS_ACCEPTANCE.md) | DELIVERED |

| M2-F39 | B1 四副牌練習賽：四副新牌、進度、分數結算、跨重啟接續（Flutter 109/109 PASS） | [M2-F39 教學](features/M2_F39_FOUR_BOARD_PRACTICE.md) | [單人場次模型](../../apps/bridge_academy_flutter/lib/src/four_board_practice.dart) · [牌桌](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart) · [Flutter tests](../../apps/bridge_academy_flutter/test/b1_four_board_practice_test.dart) · [B1 驗收](../product/B1_FOUR_BOARD_PRACTICE_ACCEPTANCE.md) | DELIVERED |

| M2-F40 | B2.1 Just Declare：指定定約練莊家、明手、13 墩；不捏造叫牌（CI Runner 啟動阻擋） | [M2-F40 教學](features/M2_F40_JUST_DECLARE.md) | [Bridge Core](../../packages/bridge_core/lib/src/game.dart) · [Flutter](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart) · [Core tests](../../packages/bridge_core/test/just_declare_test.dart) · [UI tests](../../apps/bridge_academy_flutter/test/b2_just_declare_test.dart) · [驗收](../product/B2_JUST_DECLARE_ACCEPTANCE.md) | DELIVERED |

| M2-F41 | B2.2 四座位莊家練習、定約目標進度、完成／宕約結果、修復 Session 實際缺失（CI PENDING） | [M2-F41 教學](features/M2_F41_JUST_DECLARE_FOUR_SEATS.md) | [BridgeSession](../../apps/bridge_academy_flutter/lib/src/bridge_session.dart) · [牌桌](../../apps/bridge_academy_flutter/lib/src/bridge_app.dart) · [測試](../../apps/bridge_academy_flutter/test/b2_2_declarer_seats_test.dart) · [B2 驗收](../product/B2_JUST_DECLARE_ACCEPTANCE.md) | DELIVERED |

| M2-F42 | B3.1 叫牌練習、自然 NT 示範約定、Just Declare 回歸修正、PlayerView 隱私（[Flutter 118/118 + Web + Chrome PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38905811936)） | [M2-F42 教學](features/M2_F42_BIDDING_PRACTICE.md) | [實作](../../apps/bridge_academy_flutter/lib/src/bidding_practice.dart) · [測試](../../apps/bridge_academy_flutter/test/b3_bidding_practice_test.dart) · [B3.1 驗收](../product/B3_BIDDING_PRACTICE_ACCEPTANCE.md) | DELIVERED |

| M2-F43 | B6 每日固定四副牌、UTC manifest、AES-GCM 進度、Flutter UI（[124/124 tests + Web/Chrome Demo PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38910655183)） | [M2-F43 教學](features/M2_F43_DAILY_PRACTICE.md) | [模型](../../apps/bridge_academy_flutter/lib/src/daily_practice.dart) · [測試](../../apps/bridge_academy_flutter/test/b6_daily_practice_test.dart) · [驗收](../product/B6_DAILY_PRACTICE_ACCEPTANCE.md) | DELIVERED |

## 新功能加入方式
1. 直接推送 master 時，仍給每個獨立功能唯一 ID：Mx-Fxx。
2. 建立 docs/learning/features/Mx_Fxx_TOPIC.md，填入實作路徑和實測證據。
3. 更新索引本表，Commit 或工程驗收文件附功能、實作、測試與教材對應。
4. 推送後審查教學是否準確，完成時在 Chat 用一個問題引導學習。
5. 不因 Agent 自己生成教材就將進度提升為 PRACTICED 或 MASTERED。

## M1 其他功能的教學回補候選
合約／莊家判定、Double／Redouble、Actor 與 Hand Owner、Follow Suit、Duplicate Scoring、事件回放與完整手牌隱私。此處只是**尚未交付的回補清單**，不代表已有教材或已驗收學習。
| M2-F12 | Phase A1：標準牌號、發牌者／局況、同副重打與下一副 | [M2-F12 教學](features/M2_F12_BOARD_MANAGEMENT.md) | [BoardDefinition](../../packages/bridge_core/lib/src/board_definition.dart) · [Session/UI 測試](../../apps/bridge_academy_flutter/test/board_management_test.dart) · [驗收](../product/P1_A1_BOARD_MANAGEMENT_ACCEPTANCE.md) | DELIVERED |
| M2-F13 | Phase A2：事件保存、恢復、失敗重試、DI 儲存庫 | [M2-F13 本機恢復教學](features/M2_F13_PERSISTENCE.md) | [Coordinator](../../packages/bridge_core/lib/src/single_player_coordinator.dart) · [Store](../../apps/bridge_academy_flutter/lib/src/session_persistence.dart) · [測試](../../apps/bridge_academy_flutter/test/persistence_test.dart) · [驗收](../product/P1_A2_PERSISTENCE_ACCEPTANCE.md) | DELIVERED |
| M2-F14 | A2.2 雙槽 Checkpoint、提交代數、舊版遷移與 14 筆故障注入測試 | [M2-F14 教學](features/M2_F14_CHECKPOINT_HARDENING.md) | [雙槽 Store](../../apps/bridge_academy_flutter/lib/src/session_persistence.dart) · [13 個故障注入測試](../../apps/bridge_academy_flutter/test/checkpoint_store_test.dart) · [驗收](../product/P1_A2_2_CHECKPOINT_HARDENING_ACCEPTANCE.md) | DELIVERED |
| M2-F15 | A2.3 Android 強制關閉／新行程的本機牌局恢復驗收 | [M2-F15 教學](features/M2_F15_ANDROID_PROCESS_RESTART.md) | [跨行程 Android 測試](../../apps/bridge_academy_flutter/integration_test/android_persist_restore_test.dart) · [腳本](../../apps/bridge_academy_flutter/scripts/android_process_restart_e2e.sh) · [驗收](../product/P1_A2_3_ANDROID_PROCESS_RESTART_ACCEPTANCE.md) | DELIVERED |
| M2-F16 | A2.4 存檔回退警告與明確確認，防止玩家／Bot 自動續玩舊版 | [M2-F16 教學](features/M2_F16_CHECKPOINT_ROLLBACK_NOTICE.md) | [回退與 UI 測試](../../apps/bridge_academy_flutter/test/checkpoint_recovery_notice_test.dart) · [驗收](../product/P1_A2_4_ROLLBACK_NOTICE_ACCEPTANCE.md) | DELIVERED |
| M2-F20 | A2.8 Web 加密存檔／明文遷移／瀏覽器重新啟動恢復 | [A2.8 繁體中文教學](features/M2_F20_WEB_ENCRYPTED_CHECKPOINT.md) | [Web 加密存檔](../../apps/bridge_academy_flutter/lib/src/secure_session_persistence.dart) · [Unit tests](../../apps/bridge_academy_flutter/test/browser_encrypted_archive_test.dart) · [Chrome test](../../apps/bridge_academy_flutter/integration_test/browser_table_test.dart) · [驗收](../product/P1_A2_8_BROWSER_ENCRYPTED_CHECKPOINT_ACCEPTANCE.md) | DELIVERED |
| M2-F44 | B4 橋牌學院三堂九題、雙語規則練習、答錯重試、去重與 C3 ID 契約（[Flutter 128/128 + Web CI PASS](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/38909904915)） | [M2-F44 教學](features/M2_F44_BEGINNER_ACADEMY.md) | [課程](../../apps/bridge_academy_flutter/lib/src/academy/academy_catalog.dart) · [Domain 測試](../../apps/bridge_academy_flutter/test/b4_academy_domain_test.dart) · [Widget 測試](../../apps/bridge_academy_flutter/test/b4_academy_widget_test.dart) · [驗收](../product/B4_GUIDED_TRAINING_ACCEPTANCE.md) | DELIVERED |
