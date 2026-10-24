# M3.6 — Precision V1：依原生約定解讀選擇合法出牌（研究版）

> 2026-10-24 · BBA Meckwell Precision V1 · **研發功能；競賽 AI 仍未驗收**  
> 原始證據：[固定上游 BBA.py](https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/src/bba/BBA.py) `BBABotBid.find_info(auction)` · [整合 CI workflow](../../.github/workflows/precision-m34-m35-research.yml)

## 目標與查核結果

上一階段雖通過四種 `Precision v1 × SAYC / 21GF` 的 Gateway/Bridge Core 完整技術對局，但原生 EPBot 僅執行 Bid；出牌仍使用 `DeterministicTrainingBot`，不能理解人工強 1♣ 所代表的牌型。

已查核 pinned upstream `src/bba/BBA.py`：`BBABotBid` 僅實作原生叫牌、叫牌解釋 `find_info`，其 `EPBotNative` interface **沒有對等 `choose_card`／出牌 API**。同時 pinned BEN `systems.conf` 沒有 Precision `theirSystem` reader；因此**不可假稱既有 BEN 的 `/play` 可正確解讀 Precision**。

本次 M3.6 採**真實原生叫牌解讀 → 有界啟發式合法出牌**的研究增量，而不是移植不存在的原生神經出牌模型。

## 真正的資料流與邊界

```text
已結束叫牌之 Gateway PlayerView（只有自己手牌 + 可見明手 + 公開記錄）
    ↓ BbaResearchTablePolicy（僅當前可出牌 actor）
private POST /v1/precision/auction-inference
    ↓ pinned sidecar：BEN Git SHA + Meckwell .bbsa SHA + libEPBot.so SHA
BBA BBABotBid.find_info(completed public auction)
    ↓ 每個 N/E/S/W 位置的 C/D/H/S「推估花色長度」（非實際私牌）
strict DTO validation + provider/profile/revision/card SHA pin
    ↓ 對 Bridge Core 提供的 legalCards 排序
    ↓ CardAction proposal
BridgeGame.apply（唯一驗證跟牌、所有權、回合、計分）
```

Native `find_info` 以當前 actor 的**原始 13 張自己的手牌**、dealer、vulnerability、完成的公開 auction 及兩邊已鎖定的 `.bbsa` 運作。只將四座位的四花色長度估值（0..13）輸出，**不傳** hidden full Deal、其他三家真牌、不暴露 native 的完整 `info`／HCP／hand。這是「BBA 對約定的推論」，不是對隱藏牌張的已知事實。

在 Dart `BbaResearchTablePolicy` 出牌策略中，評分時僅參考自己／已公開明手真正可打的牌與解讀所得之各座位**預測**長度，計算最基本的搭檔花色支持與敵方推測長度差；同分時偏向較低點數牌。**這是顯式啟發式、不含 DDS 作弊或雙明手搜索，也非強度驗收。**

## 對局安全與失敗行為

1. 對出牌推論採單獨 `/v1/precision/auction-inference`，不能重用只支援 bidding turn 的 `table-bid` 座位驗證；只允許有效合約以三 Pass 完成後請求，拒絕中途 auction、Pass Out、無明確來源版本。
2. Strict schema：NS/EW 必須**恰有一方**為固定 BBA Meckwell V1；其餘只接受 `BA-SAYC` 或 `BA-21GF`；actor 只能傳自己的手牌；傳隱藏牌、未知制度、卡雜湊錯誤一律拒絕。
3. Sidecar 只在 127.0.0.1 服務、POST body、有限 bytes，無代理或重新導向。Native 原始例外、手牌和 stack trace 不輸出到回覆。
4. Dart 對所有 16 項推測長度驗證為 0..13 整數；無法推論、服務超時、回覆版本不符則不做「第一張合法牌」的靜默降級，Gate 回 503/不可用，**目前研究版 fail-closed**。
5. 即使啟發式給出不佳的 card，Core 仍必須檢查牌是 legalCards 中的一張，不能藉 AI 直接修改 authoritative State。

## 驗證矩陣

| 項目 | 驗證方式 | 結果定義 |
| --- | --- | --- |
| native 叫牌解讀遵循兩邊卡 | Python mock 原生方法、同時在隔離 CI 呼叫真 `find_info` | 區分 MOCK vs REAL |
| BBA 信號會改變出牌，而非固定第一張 | Dart unit，用同一副牌提供兩組不同「推估搭檔長度」 | 所提 CardAction 花色不同且都合法 |
| 未授權私牌／不完整 auction／篡改數值 | Python/HTTP + Dart contract tests | Fail-closed，不洩露私牌 |
| NS/EW × SAYC/21GF 真 BBA 叫牌與受推論引導出牌 | 真 native Gateway 固定 fixture 共四局 | 52 unique cards／13 tricks／Bridge Core score |
| 競賽品質、真正 Precision-aware 神經模型、防守訊號、100+ expert goldens | 外部專家／後續可用模型 | **NOT VALIDATED** |
| 2 vCPU／4GB 正式 VPS + Redis/MySQL + concurrent load | 目標部署實測 | **NOT RUN** |

## 工作範圍與正式發行

- 原生側車：[scripts/precision_m33_sidecar.py](../../scripts/precision_m33_sidecar.py)
- Bridge policy：[bba_research_table_policy.dart](../../packages/bridge_precision_adapter/lib/src/bba_research_table_policy.dart)
- 私有 transport：[bba_precision_loopback_transport.dart](../../packages/bridge_precision_adapter/lib/src/bba_precision_loopback_transport.dart)
- Dart 策略測試：[bba_research_table_policy_test.dart](../../packages/bridge_precision_adapter/test/bba_research_table_policy_test.dart)
- Python 邊界：[test_precision_m34_table.py](../../scripts/test_precision_m34_table.py)
- 真 native schema smoke：[precision_m36_native_inference_smoke.py](../../scripts/precision_m36_native_inference_smoke.py)
- 真實 Gateway：[live_precision_research_full_game.dart](../../services/bridge_gateway/bin/live_precision_research_full_game.dart)

本研究功能不更改原有 2/1／SAYC 正式 BEN 路由，不開放預設 Flutter Precision 選擇，不啟動 Android/iOS emulator/device QA。**若目標是可與強力機器人公平競技的 AI，仍需真正針對 Precision 的 single-dummy cardplay model／資訊抽樣、專家 Golden tests、1000 場完整雙方向對局以及同種子 IMP/MP 比較；本研究策略不能取代它。**
