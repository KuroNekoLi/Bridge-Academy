# Bridge Academy — M1.3：真 BEN 2/1 Game Force／SAYC 叫牌 A/B 驗收

> 2026-10-24 · **SCOPED VERIFIED** — 真 BEN 16 組 × 2 制度共 32 次 /bid 全部成功、0 個已檢查 forcing 違規；未達完整專家簽核／全套制度驗收。  
> 範圍：固定 BEN `ad8608af6e6bfe095863023f344f3cb2cbafec3d`；`ourSystem=21GF` 與 `ourSystem=SAYC`。  
> 文件權威：[三制度主計畫](../product/THREE_SYSTEM_BIDDING_AI_MASTER_PLAN.md) · [M1.2 原生執行驗收](BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md)。

## 1. M1.3 真正要驗證什麼

M1.2 的 `GET /` 只驗證服務宣告。M1.3 會在**實際 BEN `gameapi.py`** 中，針對相同 `hand / seat / dealer / vul / ctx` 分別傳 `ourSystem=21GF` 和 `ourSystem=SAYC`，確認：
1. 真模型各自有回應，沒有查不到模型、超時或 HTTP error；兩模型名稱合法且已載入。
2. 輸出的叫品符合最低限度的叫牌合法性檢查（正確等級、花色升序、X/XX 上下文）；真正 Domain 權威仍為 Bridge Core，後續須完成 adapter-to-Core end-to-end。
3. `ourSystem` 不存在的字串必須被 BEN 拒絕（400），**不允許默默回到預設 21GF-GIB**。
4. 高信心 2/1 forcing pattern：`1S–P–2H–P` 的開叫者、`1S–P–2H–P–2S–P` 的答叫者與 `1H–P–1NT–P` 的開叫者不得以 `PASS` 終止一輪／進局迫叫；若有就標語義異常並且 CI gate FAIL，不自動改寫模型結果。
5. 保留每次單獨合法出價和對照結果；**兩制度回應剛好一樣不視為錯誤**，不同也不自動視為證明模型準確。

本輪是**16 個人工選取、未經專家簽核的微型測試情境**，不是 100 個已審核制度案例，不是完整對局 13 墩，也不是正式 Precision 支援。絕不拿這些案例推論 AI 整體品質或與 BBO 的牌力差距。

## 2. 真實執行方法與固定版本

- CI：[BEN M1.3 Real A/B + M1.4 Isolated Capacity](../../.github/workflows/ben-m13-m14.yml)
- 程式：[scripts/ben_multisystem_benchmark.py](../../scripts/ben_multisystem_benchmark.py)
- 牌例：[16 個 single-seat 固定情境](../../scripts/fixtures/ben_multisystem_m13.json)
- 契約測試：[scripts/test_ben_multisystem_benchmark.py](../../scripts/test_ben_multisystem_benchmark.py)
- 與 M1.2 相同 pinned commit、Python 3.12／TensorFlow 2.21.0／Keras 3.15.1；此輪 BEN 設定為**NN-biased 快速研究模式**（BBA、PIMC、SuitC 停用，`eval_opening_bid=False`、`no_search_threshold=0.01`）。這不是 BEN 原廠完整比賽配置，品質數字不能對外宣稱等於完整版 BEN。第一輪 [CI #40076117313](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076117313) 亦已成功；報告以後續修正 RSS 採樣的 [#40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888) 為正式性能參考。

執行（以已啟動在 loopback 8085 的同版 BEN 為前提）：

```bash
python -m unittest discover -s scripts -p 'test_ben_multisystem_benchmark.py' -v
python scripts/ben_multisystem_benchmark.py \
    --mode m13 --url http://127.0.0.1:8085/ \
    --fixtures scripts/fixtures/ben_multisystem_m13.json \
    --output m13-results.json
```

`m13-results.json` 記 fixture ID、兩制度各自 `bid`、延遲／合法性、對照差異、forcing 違規及是否為專家審核；不包含整副牌、未公開另外三家手牌、含私人手牌的 HTTP URL、BEN 的原始錯誤物件。

## 3. CI evidence 和判定

**EXECUTED / REAL BEN PASS**：最終版本 GitHub Actions [#40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888) job `multi-system` completed/success。Pinned `ad8608af` 真正 `gameapi.py` 啟動，32/32 次真 `/bid` 成功，最低合法叫品預檢全部通過；BEN 對未知 `ourSystem` 回應 400（fail-closed）；3 個 2/1 forcing 規則沒有出現 PASS 違規。
- 16 組情境中有 **1 組不同**：`2over1_opener` 的 `1S–P–2H–P`，`21GF→4H`，`SAYC→3H`。此為觀察值，不是任一叫品已被專家證明最優。
- 21GF 16 次：p50 **26.3 ms**、p95 **532.6 ms**、最大 **774.4 ms**。
- SAYC 16 次：p50 **27.7 ms**、p95 **514.1 ms**、最大 **730.8 ms**。
- 基礎測試是 Python 獨立語法／叫牌升序預檢，**未透過 Dart Bridge Core 執行每一個提案**。Fixture 有既定先前叫牌，但未建立配對的完整四手隱藏分配，也非專家審核 golden set。
- 第三方模型/原生授權仍未核准；NN-biased 輕量設定不代表完整 BEN Production 模式。

| 項目 | 要求 | 狀態 |
|---|---|---|
| 固定版本真實 BEN | PASS（[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)） | PASS（[CI #40076200888](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40076200888)） |
| 32 次 `/bid` | PASS（32/32，16 × 2，無非法回應） | PASS（32/32，16 × 2，無非法回應） |
| 錯誤制度拒絕 | PASS（未知 ourSystem 400） | PASS（未知 ourSystem 400） |
| 2/1 迫叫限制 | PASS（3 個指定情境零 PASS 違反） | PASS（3 個指定情境零 PASS 違反） |
| 完整叫牌制度專家簽核 | 100+ curated golden fixtures | NOT RUN／後續 |
| Bridge Core 逐動作 end-to-end | 真制度決策由 server Core 依法驗證 | NOT RUN／後續 M2 |

## 4. 原始技術限制與下一階段

即使本文件得到 `SCOPED VERIFIED`，仍只能聲稱 **「真 BEN 在 16 組未專審情境中能依要求呼叫兩套模型並回傳合法叫牌」**。尚不能宣稱每個後續叫牌都遵守 2/1/SAYC 或可正式為使用者切換；Gateway/Flutter 制度綁定是 M2，Precision 是 M3。

如 CI 發現 forcing 違規：固定輸入、保留模型權重 SHA 及原始回應到**不含私人牌的**受控測試報告，對照專家規格與引擎後再決定是 BEN 上游差異還是我們的制度假設有誤；禁止程式默默改成指定叫品。
