# Bridge Academy — M2.2～M2.5 三制度產品線整合驗收

> 日期：2026-10-24。狀態：SCOPED ENGINEERING PASS；Production/Competition Release NO-GO。
> 基線：Bridge Academy master；BEN 上游 SHA ad8608af6e6bfe095863023f344f3cb2cbafec3d。

## 交付範圍與四個里程碑

| 子階段 | 實際完成 | 驗收 |
| --- | --- | --- |
| M2.2 | BenBotPolicy 依 PlayerView.viewer.isNS 將固定的南北／東西模型填入 request-scoped ourSystem/theirSystem；支援 bid/lead/play，legacy 不變 | BEN Adapter CI 29/29 PASS |
| M2.3 | Gateway 建局時把用戶提交的 NS/EW profile ID 映射到伺服器 allowlist，版本不可由用戶指定；BEN loopback GET / capability + operator pinned commit 驗證；斷線／重啟後每個 action 再驗，無聲降級為 503 | Gateway CI 44/44 PASS |
| M2.4 | Flutter GatewayTable 開局前 NS/EW 可獨立選 Legacy、2/1、SAYC；混用 Legacy 和新制度禁止啟動；進行中的局不可改選；Session 只送 ID 並驗證 Gateway 回傳的 GameSystems fingerprint；zh-TW/en | Flutter Unit/Widget、Web build 與 Chrome demo CI PASS |
| M2.5 | 同一 PBN 反向輪流採用 NS 2/1/EW SAYC、NS SAYC/EW 2/1；兩局分別使用真 BEN、授權 Gateway、Bridge Core 完成 52 張牌 | REAL BEN 兩局 PASS |

## CI 具體證據（不以 Mock 冒充真實模型）

- M2.2：[BEN Adapter Contract CI #40087679336](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087679336) — Dart analyze No issues、29 tests PASS。新測試涵蓋 N/E/S 座位、首攻、legacy、未驗證混合系統拒絕與 PlayerView 隱私。
- M2.3：[Gateway CI #40087906654](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087906654) — analyze No issues、44 tests PASS；[Conventions & Gateway CI #40087906622](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087906622) 另有 Domain 5/5 與 Gateway 44/44 PASS。測試中的 BEN 是本機 HttpServer stub，不是 TensorFlow。
- M2.4：[Flutter M2 CI #40087781811](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087781811) — analyze、Widget/Session、Web Release Build、headless Chrome demo E2E 全部 completed/success。新增 m2_system_choice_test.dart 覆蓋選單、系統 payload、版本相符/不相符、鎖定與隱私。**沒有執行 Android emulator 或 Android/iOS 真機**。
- M2.5：[Genuine BEN Real Model CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) — 兩個完整真模型子步驟 completed/success。模型與 DDS/BBA 配置是 pinned 研究設定，非正式預設高強度配置；沒有對外部署。

## 實際產品與安全契約

1. 只有 Gateway opt-in 介面可選擇模型，HTTP body 只提交 game_systems: {northSouth: BA-21GF, eastWest: BA-SAYC} 等合法 profile ID。無效或未登錄的 profile ID/revision/混合 legacy 回 400；不接受客戶端自己填 BEN weights 或引擎修訂版。
2. Session bootstrap 回傳伺服器建立的完整 GameSystems fingerprint；Flutter 重新計算驗證，若不符不會顯示新局。Gateway 每局 checkpoint 使用 AES-GCM；已開始的制度不可漂移。
3. BEN Loopback Backend 僅接受 127.0.0.1/::1；真正系統能力需 GET / 允許且 operator 指定的 pinned commit 相同。不支援或服務中斷就回 503，不會偷偷沿用 21GF-GIB。
4. BEN 僅接受 Bot 的 own hand、公開 auction、公開 dummy（曝光後）。Bridge Core 仍負責 bidding/card legality、52 張原始牌、13 墩與計分。
5. 現有 Legacy 模式繼續使用舊 Gateway 行為，不被冒稱是 2/1/SAYC；原 Android/iOS QA Hold 不變。M2.1 metadata 支援舊 checkpoint 遷移。

## 限制／安全與發行門檻

- 2/1/SAYC 模型 capabilities 與 pinned Git commit 不等於實體 model weights 檔案 SHA 的 runtime cryptographic attestation；商業模型／第三方 DLL 許可仍須審核。
- 固定牌局兩種配置都 PASS，**不能證明所有 SAYC/2/1 約定、競叫、強制進局序列都正確**。需 expert-reviewed 100+ golden fixtures 與大樣本牌力評估。
- M2.5 此次是真 BEN → Gateway → Core 的完整牌局；Flutter 只在 Mock Gateway Widget / Chrome Demo E2E 驗證，未在真 BEN 情境下另做完整 Chrome UI E2E。
- 生產環境 IPv4 loopback、TLS、模型權重、Docker/cgroup、長時間併行與你 4GB VPS 真實負載測試仍在 release gate；本次不能宣稱 production READY。
- Precision Club、自訂 Convention Card、正式 MP/IMP 排名賽不在 M2 交付範圍。Precision 預定 M3。

## 測試檔案與下一步

- packages/bridge_ben_adapter/test/ben_bot_policy_test.dart
- services/bridge_gateway/test/m2_system_routing_http_test.dart
- apps/bridge_academy_flutter/test/m2_system_choice_test.dart
- services/bridge_gateway/bin/live_gateway_multisystem_full_game.dart
- .github/workflows/ben-m2-multisystem-real.yml

開發後續：完善 expert-reviewed convention fixtures、真正權重 SHA runtime驗證、Gateway HTTPS 部署及 VPS 量測。再依 M3 研究 Precision、BBA 授權與制度語義。
