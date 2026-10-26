# 開源授權、容量與營運研究

截至 2026-10-26，**研究通過 ≠ 正式商業發布授權**。

| 元件 | 目前用途／版號 | 未通過的發行條件 |
| --- | --- | --- |
| [BEN](https://github.com/lorserker/ben) | NN，候選 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`，source GPL-3.0 | 模型 weights／native binaries 權利逐項審核 |
| BBA／EPBot | Meckwell Precision V1 本機 native 研究 | 使用者說明已取得許可；仍需留存原文、再散布/託管許可及 notice |
| DDS | 完局雙明手分析 | 終局視角、元件來源與發布 license |
| `playing_cards 0.4.1+11` | Flutter 牌面 render-only，registry SHA256 `392d5e42317ec657f6814a282e6bb70942c6599d22dac89cdc741a8b2b095d09`，package Apache-2.0 | bundled Wikimedia 圖像可能被打包；需逐張查授權或排除 |
| `card_game 2.0.0` | 動畫套件候選 | **未安裝／未核准** |

## 模型身份與核驗

[SHA inventory](../../scripts/ben_m12_inventory.py) 對模型與 native 依賴逐項計算 SHA256；[真 BEN CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) 已成功開機與宣告 systems。21GF bidder `33ff95fe85ed29c9b1c1cd5ac8d6f9516f7d3d4547b17384fbdfadba56f69efd`；SAYC bidder `6824fb96264d6536709b3c4d3fa989f321f5886662cfcb3a0e5c1e3c5cb67c32`。**Hash 只能證明檔案身份，不能當作商用授權**。完整 info/native 清單在整理前 Git 歷史的 `BEN_M12_PINNED_ASSETS.md`。

## 真 4GB VPS 尚未驗證

[CI benchmark](BEN_SYSTEMS.md) 是 Ubuntu Runner、短時 NN-biased、BBA/PIMC/SuitC disabled。單 Worker 觀測約 1.01 GiB RSS、雙 Worker 約 1.95 GiB，**不能推定**目標 2vCPU/4GB VPS 可行或不可行。

發布前在目標主機逐組測 concurrency 1/2/4/8、整局 bid/lead/play、冷啟與長時 CPU/RSS/p50/p95/p99/429/5xx、重啟與備援。成本還需 DAU、每局 requests、供應商實際報價（日期／幣別）、TLS、儲存、備份與監控。不假設免費。

**Production NO-GO**：TLS、identity、模型權利、隱私、VPS 真測、A3.5/Android/iOS hold 均未解除。發行準則：[RELEASE_CHECKLIST](../planning/RELEASE_CHECKLIST.md)。