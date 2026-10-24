# M3-F14｜M3.3：把原生 EPBot 包裝成隔離的本機 HTTP 叫牌服務

- Feature ID：M3-F14
- Milestone：M3.3 Native BBA Service
- 類型：Python native ctypes、服務隔離、安全 POST、固定來源再現
- 工程狀態：**SCOPED VERIFIED**（isolated GitHub Actions，非正式 VPS）
- 學習狀態：**DELIVERED**
- 原始碼：[Native sidecar](../../../scripts/precision_m33_sidecar.py) · [Real HTTP smoke](../../../scripts/precision_m33_http_smoke.py)
- 驗收與測試：[Privacy/schema tests](../../../scripts/test_precision_m33_sidecar.py) · [CI #40095274359](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095274359)

## 功能目的與實際情境

EPBot 是 BBA 的原生函式庫，不是 Dart 程式庫。若把原生程式直接嵌進 Gateway，一旦 native exception 或 ABI 崩潰，就可能拖垮整個遊戲服務。

本輪用 **sidecar pattern**：隔離 Python 程序使用 upstream BEN 的 `bba.BBA.BBABotBid` 呼叫 EPBot，透過僅在 `127.0.0.1` 開放的 HTTP POST 將**叫牌結果**回給 Dart。未通過 M3.4 正式部署驗收前只能用 `--research-only` 啟動，不能將它當成正式可公開的 API。

## 主要程式碼導讀

啟動流程：

```text
--ben-root pinned checkout
 → Git commit == ad8608af...
 → Meckwell.bbsa sha256 == selected V1 card digest
 → Linux x64 libEPBot.so sha256 == pinned native hash
 → load bba.BBA.BBABotBid from verified checkout
 → bind 127.0.0.1:18088 (no public address)
```

資料請求只接收 `version/profileId/revision/cardSha256/opponentModel/seat/dealer/vul/ctx/hand`。側車由 `opponentModel` 自己選擇 BEN-21GF 或 BEN-SAYC `.bbsa`，將 Meckwell 卡設定成 `our_system_file`，並依座位 parity 交給 native EPBot。它可以解讀對手 2/1/SAYC 的 *BBA 約定卡配置*，不能由此宣稱 BEN 神經模型已具備對 Precision 的反向理解。

`handler_factory` 的錯誤永不回傳完整 request 或 native traceback；BaseHTTPRequestHandler 的預設 `log_message` 被關閉，以免私人 hand 被記錄；Dart 不允許 proxy、非本機或 GET hand query。私牌僅存在必要的 request body 裡。

## 為什麼這樣設計

這是 Android 常見的 **Process Isolation** 在 Server 的對應做法：原生元件的死鎖、ABI 和記憶體風險與 Dart Gateway 隔離。替代方案是直接呼叫 FFI，延遲可能較小，但一旦 native crash 就需要與 Gateway 綁定重啟；目前不值得承擔此耦合。

本研究服務採單程序處理並用有限 request queue，避免未測過的 EPBot concurrency 產生狀態競爭；正式部署還須增加認證、監控、重啟、CPU/RSS budget，以及 p95/持續負載。

## 驗證與實際證據

```bash
python -m unittest discover -s scripts -p 'test_precision_m33_sidecar.py' -v
python scripts/precision_m33_sidecar.py --ben-root third_party_ben_m33 \
  --port 18088 --research-only
# another shell
python scripts/precision_m33_http_smoke.py --port 18088
```

[CI #40095274359](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40095274359)：**Python 5/5 tests**，真原生 service 啟動、16/16（8 fixtures × 2 opponent model）HTTP 出價，8/8 強 1♣ 候選皆符合，3 個明確無效 schema 被 400 拒絕。該工作流程還驗證 Dart 到 native 再到 Core 的一次完整 CallAction。

此結果是**真 EPBot 開叫**，但不是 52 張牌／13 墩完整局，也不是對專家級強梅花續叫、敵方競叫或 BBA 授權原文的檢驗。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼同樣是 local HTTP，透過 GET URL 傳 `hand=...` 的風險通常比以 private POST body 傳送更高？

**5–15 分鐘小練習（可選）：** 在 `test_precision_m33_sidecar.py` 加一個含 `deal` 欄位的 payload，斷言服務回 400 且 response 只含標準化 error，不出現任何牌面。

**完成標準：** 能解釋固定來源 hash、程序隔離、最小授權 DTO 和 fail-closed 四種不同保護。

## 下一步

M3.4 需驗證同桌 Precision 與真 BEN 神經模型的雙向約定理解，並在完整 server-owned Gateway 和 Android/iOS QA release gate 合格之後才允許正式用戶選擇。
