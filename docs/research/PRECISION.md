# Precision Club（Meckwell V1）研究報告

更新：2026-10-26。**ENGINEERING RESEARCH PASS／COMPETITIVE PRODUCT NO-GO**。

## 已確認的制度與引擎

產品唯一釘選變體 `BA-PRECISION-MECKWELL/r1`，原生 BBA／EPBot `Meckwell.bbsa`，**1NT＝13–15 HCP**。這與外部 Meckwell Lite 13–16 不相容，不得混版。BEN Neural `playsSystems` 不含可玩 Precision，也沒有經證明的 Precision neural opponent reader；本研究透過獨立 [bridge_precision_adapter](../../packages/bridge_precision_adapter/) 與 [原生 sidecar](../../scripts/precision_m33_sidecar.py) 提出叫牌，再交 Bridge Core 判合法。

## 真實測試

| 測試 | 實際證據 | 限制 |
| --- | --- | --- |
| 原生 Precision spike | [CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)：8 次開叫、4 個強 1♣ 候選 | 非整局，不是正式最優叫牌 |
| 原生 Provider | [precision-m33-provider](https://github.com/KuroNekoLi/Bridge-Academy/actions/workflows/precision-m33-provider.yml) | 只在固定真 BBA artifacts 且白名單下執行 |
| mixed partnership | [CI #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733)：SAYC／Precision 及 21GF／Precision 配對研究，固定整局 52/13 | 出牌是合法訓練策略，不代表高牌力 |
| 原生開叫效能 | [CI #40102968596](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40102968596)：1000/1000 次原生 **開叫 API**，p50 9.46ms、p95 12.96ms、約 77MiB RSS；[重測 #40103865733](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40103865733) p50 7.05ms、p95 10.03ms | **不是 1000 副完整牌局**，也不是 BEN 全模型記憶體 |
| 出牌推論研究 | [CI #40105701070](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40105701070)：使用真 BBA `find_info` 推估各座位花色長度，再只在 `PlayerView.legalCards` 選牌 | 研究啟發式，非訓練好的 Precision-aware neural cardplayer |

## 證據不足之處

尚無專家審核的充分 forcing／競叫／Alert Golden corpus、同牌同種子 MP/IMP 對照、1000 副完整隨機牌局、目標 VPS 長時負載、Android/iOS QA 或完整發布授權檔。使用者已表示 BBA 許可涵蓋必要使用，**仍須逐一保存原始許可條款、版本、SHA 和 notices**；不以口頭授權自動推定所有其他原生 binary 與模型 weights 可再散布。

相關 [固定 Precision 規格](PRECISION_CONVENTION_SPEC.md)、[產品下一階段](../planning/ROADMAP.md)、[發布門檻](../planning/RELEASE_CHECKLIST.md)。