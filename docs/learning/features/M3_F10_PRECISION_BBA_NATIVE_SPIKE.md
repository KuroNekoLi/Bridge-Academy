# M3-F10｜從 2/1、SAYC 延伸到 Precision：BBA 原生實驗

- Feature ID：M3-F10
- Milestone：M3 Precision Club 原型研究
- 類型：AI 整合、原生函式庫與測試可追溯性
- 工程狀態：SCOPED VERIFIED / RESEARCH ONLY（原生 EPBot 已跑、不得當正式 AI）
- 學習狀態：DELIVERED
- 原始碼：[Precision Probe](../../../scripts/precision_m3_probe.py)、[Fixtures](../../../scripts/fixtures/precision_m3_cases.json)
- 驗收與測試：[單元測試](../../../scripts/test_precision_m3_probe.py) · [原生 CI #40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757) · [完整研究報告](../../research/M3_PRECISION_SPIKE_ACCEPTANCE.md)

## 功能目的與實際情境

玩家若選擇 Precision Club，常見的人工強 1♣ 與 SAYC 的天然 1♣ 不可混淆。M2 已經能讓 BEN 在 2/1/SAYC 模型之間切換，但最新版固定 BEN 的 systems.conf 裡沒有 Precision 的可玩 neural bidder，所以不能只在 Flutter 加一個選項。這一輪先向上游 BEN 的既有 BBA/EPBot 原生技術做隔離可行性試驗。

在固定 BEN commit ad8608af6e6bfe095863023f344f3cb2cbafec3d，BBA/CC/Meckwell.bbsa 使用 System type = 3，也就是 BBA 的 Precision 候選。不過，上游 BBA/CC 不是開源自由改用的保證：BBA 官方 README 沒有明確授權，因此我們只在暫時性 CI 裡執行，絕不直接封裝進產品。

## 主要程式碼導讀

來源 scripts/precision_m3_probe.py：read_cc() 讀取外部版本化約定卡，檢查 System type = 3、唯一的 1NT 區間及來源檔案的 SHA-256。check_ben_source() 再檢查 BEN 真正的 Git commit，防止浮動 master。probe_native() 只有在明確 --live 時才 import 上游 bba.BBA 並執行 BBABotBid；不將 BBA 的 native binary 複製進 Bridge Academy。

資料流：固定公開 fixture → 13 張牌格式、HCP 合法性檢查 → pinned BEN + Meckwell 卡 hash → 真 EPBot bid([]) → bid 合法格式與候選強 1♣ 比對 → 只輸出已允許的 ID、HCP、叫品和差異。任何服務側 hidden Deal、客戶帳號或部署密鑰都不是這個研究的輸入。

注意 .bbsa 格式有許多「Not defined = 0」空白占位行，允許這些重複不等於允許真正的約定項重複；程式只放行占位行，重複 1NT 範圍等有意義規則仍會 fail closed。

## 為什麼這樣設計

這是 Adapter + Reproducible Build（可重現建置）思路：像 Android 使用 Gradle 鎖版及 checksum 一樣，先證明你呼叫的原生模組是哪一個版本，再討論功能對不對。可替代方案是把 BBA 原生庫直接放入 Gateway，卻會導致未解授權、平台 ABI、記憶體與所有使用者資料流一起承擔風險，故暫不採用。

另一個常見誤判是「呼叫 BBA 成功」就說 AI 符合 Precision。這次 8 組開叫研究包含四個高牌點候選，原生實驗中四個都叫出 1♣，代表一個很小的語義切片觀察成功，並不代表受干擾後的一整套約定、最佳定約及勝率合格。

## 驗證與實際證據

執行：python -m unittest discover -s scripts -p 'test_precision_m3_probe.py' -v；原生研究使用 GitHub Actions precision-m3-research.yml，在 Ubuntu 24.04 + Python 3.12 暫時 checkout BEN 到 third_party_ben_m3。

實際成功 [#40092096757](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40092096757)：8 次真 EPBot 開叫實驗，強 1♣ 候選差異 0/4；來源 Meckwell.bbsa SHA-256 為 5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc。資料沒有證明可商用、對局強度或所有 Precision 規則。

**NOT RUN**：正式 Gateway Precision /bid/lead/play、Flutter Precision 開局、完整真 BBA 52 張牌、目標 VPS、Android/iOS 裝置、專家 100+ golden cases。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼 8 組 BBA 原生模型的合法叫品，不足以證明玩家選的「Precision」制度與 AI 的理解完全一致？

**5–15 分鐘小練習（可選）：** 在 test_precision_m3_probe.py 增加不允許兩個互斥 1NT 區間同時為 1 的測試，並確保只有文字檢查、沒有在單元測試時載入原生 DLL。

**完成標準：** 能清楚說明 upstream commit、.bbsa digest、原生引擎行為、專家語義及授權是五個分離的證據。

## 下一步

先取得 BBA 使用許可與正式 Meckwell 版本，然後建立人工強 1♣ 回應、1NT 區間、競叫與 alert 的 golden cases。這些完成後才能評估獨立 BBA Precision Worker，必要時以規則器或自訓神經網路取代。
