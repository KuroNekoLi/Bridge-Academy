# BEN、2/1／SAYC 真實研究

更新：2026-10-26。固定 BEN 上游 `ad8608af6e6bfe095863023f344f3cb2cbafec3d`，Python 3.12.15／TensorFlow 2.21.0／Keras 3.15.1。BEN `playsSystems` 有 21GF-GIB、21GF、SAYC；`BEN:` 對手設定為 read-only，Precision 不屬於其 Neural 可玩制度。

| 階段 | 實測與證據 | 判斷 |
| --- | --- | --- |
| M1.1 | systems.conf／模型／Mock 靜態驗證 | 靜態通過，不是 API |
| M1.2 | 真 BEN `GET /`、模型 SHA；[CI #40075250217](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075250217) | 開機 9.03 秒、RSS 輪詢約 879MiB；當時尚未跑 /bid |
| M1.3 | [真 BEN CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012)，16 組情境 × 21GF／SAYC | **32/32 /bid**、基本合法性與未知制度 400 檢查通過、3 個抽樣 forcing 未出現 PASS、1 組差異 |
| M1.4 | 同版本單 Worker 並行 1／2／4、雙 Worker 監測 | GitHub Runner 限定小樣本，非 VPS |
| M2.1～M2.5 | 不可變 NS/EW `GameSystems`、Gateway/Adapter/Flutter 選型、[真雙局 CI #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) | 兩種相反配對各完整 52 張／13 墩，有效計分；不是專家制度品質認證 |

## M1.4 效能觀察

[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)，單 Worker 每組 16 requests：c1/c2/c4 p50 = 26.0／35.3／78.7 ms，p95 = 89.2／98.2／126.1 ms，throughput = 28.6／38.3／42.3 req/s。兩個 Python Worker 合計輪詢 RSS 約 **1.95 GiB**，單 Worker 約 **1.01 GiB**。較新 [CI #40076846012](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076846012) 也 success，c1/c2/c4 p95 約 110.3／130.5／161.0ms；顯示短時測量會波動，不能拿來推定穩態 SLO。CPU 時間主／次約 2.25／1.71 CPU-seconds（不是實機 CPU %）。

測試使用降低模擬負擔的 NN-biased BEN 配置，BBA/PIMC/SuitC 停用；不是 2vCPU／4GB VPS 實測，亦不是完整版 BEN。研究初步傾向**單 Worker 多模型＋有界 queue**；公開服務仍 **NO-GO**。

## 限制與重現

16 組情境未經橋牌專家逐一審核，兩制度只有 `1S–P–2H–P` 情境回應不同（曾觀察 21GF `4H`，SAYC `3H`）。**不同不等於更好或正確**。100+ expert golden、完整服務成本、長時真 bid/lead/play、模型權重與 native binaries 的商用再散布權利仍是 release gate。

工具：[benchmark](../../scripts/ben_multisystem_benchmark.py)、[fixtures](../../scripts/fixtures/ben_multisystem_m13.json)、[CI](../../.github/workflows/ben-m13-m14.yml)。原始詳表可查前一版 Git 歷史／Actions artifact。