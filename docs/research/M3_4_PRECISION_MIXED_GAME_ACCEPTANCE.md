# M3.4 — Precision V1 混合制度牌局：限定範圍驗收

> 2026-10-24 · **EXPERIMENTAL INTEGRATION: SCOPED ENGINEERING PASS** · **NOT COMPETITIVE / NOT PRODUCTION**  
> CI：[M3.4/M3.5 #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596) · [唯一制度 V1](../conventions/PRECISION_BBA_MECKWELL_V1.md)

## 1. 實際完成的功能

- 在 `ConventionCatalog` 建立 **BBA Meckwell Precision V1** 不可變 profile `BA-PRECISION-MECKWELL/r1`，固定上游 `Meckwell.bbsa` SHA-256；**未加入正式 candidateProfiles**。
- `BridgeGatewayService` 增加 `enablePrecisionResearch: false` 預設關閉；須明確設 true 且注入已通過版本、原生 Worker readiness 的 `BbaTableBidTransport`。雙 Precision、未知制度、無 Worker、版本不符都 fail-closed；保留原有 BEN 2/1／SAYC。
- `BbaResearchTablePolicy` 由 Server-owned `GameSystems` 和每個 actor 的 `PlayerView` 產生請求，**整桌四個位置都經 BBA/EPBot 的原生約定卡解讀**，不要求 BEN 對未訓練的 Precision 人工強梅花作假推論：北／南 Meckwell 對東／西 SAYC，以及反方向都跑通。
- 原生側車新增 `/v1/precision/table-bid`：每一請求固定 NS/EW 合作制度、actor、dealer、vulnerability、公開牌叫、僅 actor 的 13 張私牌；用上游 `Meckwell.bbsa`／`BEN-SAYC.bbsa`／`BEN-21GF.bbsa` 對應雙方，禁止任意卡片檔路徑。
- 出牌**刻意使用 `DeterministicTrainingBot` 的第一張合法牌**，Bridge Core 規則仍是出牌與計分的權威。這是在測試全局 pipeline，**不是可競賽的 BEN+Precision 全功能 AI**。
- Flutter `GatewayTable` 以 `--dart-define=BA_M34_RESEARCH_PRECISION=true` 才顯示明確標註「研究、非競賽出牌」的 Precision V1 選項；一般建置保持不可選。Gateway `serve.dart` 也須 `M34_RESEARCH_ENABLED=true` 和 private `M34_RESEARCH_BBA_ORIGIN=http://127.0.0.1:18088/`，只綁本機地址。

## 2. 真實完整牌局

[CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)，Ubuntu 24.04、Dart stable、Python 3.12、BEN pinned `ad8608af6e6bfe095863023f344f3cb2cbafec3d`。

| 測試 | 結果 | 叫牌 | 出牌／規則 |
| --- | --- | --- | --- |
| NS=BA-PRECISION-MECKWELL, EW=BA-SAYC | SCOPED PASS | 原生 BBA 雙方卡 | 52 unique cards、13 墩、NS -100，Bridge Core |
| NS=BA-SAYC, EW=BA-PRECISION-MECKWELL | SCOPED PASS | 原生 BBA 雙方卡 | 52 unique cards、13 墩、NS -100，Bridge Core |

兩局固定公開測試 PBN，auction=6、不同 profile fingerprints；Gateway 只回傳 North 的 filtered PlayerView、不包含全牌或私密手牌，HTTP request_id 重送亦不再套用同一動作。**不要將固定一副牌成功推論為大樣本競技 AI 勝率。**

精確驗收指令：

```bash
cd services/bridge_gateway
dart pub get && dart analyze --fatal-infos && dart test --reporter expanded
# 在 pinned BEN checkout 已啟動 scripts/precision_m33_sidecar.py --research-only 後：
dart run bin/live_precision_research_full_game.dart
```

本次 CI：Convention Domain 10/10、Precision Adapter 10/10、Gateway 47/47、Python 混合制度測試 3/3，所有 Dart analyze 無資訊級以上 issue；Chrome/真實裝置的研究模式完整版 UI E2E **未執行**，M2 的 Flutter 常規 CI 另行維持。

## 3. 重大保留與 NO-GO

1. BEN 現存 bidder/info networks 沒有 Precision opponent reader；**本輪不是「BEN 和 BBA 雙引擎真正各自理解 Precision」**，而是「兩側統一用 BBA 原生卡叫牌」。任何 BEN cardplay 及 bidding-info sampling 若要根據人工 1♣ 進行推論，仍需要獨立 adapter/model/推論語義驗證。
2. **出牌使用合法訓練策略**，不含 PIMC、DDS、BEN 真正防禦策略或安全的 Precision cardplay inference。不能排入正式機器人強度或 ranked MP/IMP。
3. 需要 **100+ 專家簽核的叫牌／Alert Golden Cases**、多種競叫、1NT 13–15 邊界、1♣ 後續完整語義、大樣本不同牌型與雙方公平性測試。
4. Release 仍需 TLS、正式授權文書／通知義務、4GB 實際 VPS 量測、資安、session durability、實機 Android/iOS QA（使用者原先暫緩，不自動執行）。

BBA 商用託管、修改、再散布授權已由專案擁有人明確確認，這**不是**開發阻擋；具體原文／通知義務可保存在非公開 Release 合規紀錄。不要散播個人授權信件。

## 4. 可回滾性

研究模式預設關閉。關閉 `M34_RESEARCH_ENABLED` 與 Flutter 編譯旗標後，正式 BEN 的 2/1／SAYC 路由不變；舊的 LEGACY checkpoint 仍由版本驗證。無需改 Bridge Core。
