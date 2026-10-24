# M3.3 — BBA Meckwell Precision V1 獨立叫牌 Provider 與原生隔離服務

> 更新：2026-10-24（Asia/Taipei）  
> 範圍：**M3.3 Engine Adapter／Provider Integration（auction proposal only）**  
> 版本權威：[BBA Meckwell Precision V1](../conventions/PRECISION_BBA_MECKWELL_V1.md) — `BA-PRECISION-MECKWELL/r1`，13–15 HCP，固定 `.bbsa` SHA。  
> 狀態：**IMPLEMENTED／CI 驗收依 GitHub Actions 最新成功結果簽核**；尚未進入 M3.4 可玩混合制度 Gateway 或 Flutter Precision 選單。

## 使用者需求與安全邊界

已收到專案擁有人確認：**BBA 使用權包含商業託管、修改與再散布**。此為 `OWNER_REPORTED_GRANTED`，權利範圍已由擁有人直接說明；授權原文、被授權對象、明確含原生版本與條款須在 release 合規證據中私下歸檔，**不需要公開上傳授權書**。權利確認不代表其他 P0 性能、資安及橋牌規則測試自動通過。

M2.2 對 2/1 與 SAYC 使用的是真正 BEN 神經路由；固定的 BEN `systems.conf` **沒有 Precision 讀取與出價模型**。如果將 `ourSystem=PRECISION` 或 `theirSystem=PRECISION` 強塞給 BEN，會錯誤 fallback、被拒絕或誤解對手出價。因此 M3.3 不直接改 `BenBotPolicy`，也不讓 Flutter 選一個尚不能執行的選項。

M3.3 先分出乾淨、可替換的 **PrecisionBiddingProvider**，其目的只有：從被授權的真實行動者 `PlayerView`（不可看全牌）取得 native Precision `CallAction` 提案；再由 Bridge Core 接管合法性與狀態更新。尚未驗證 BBA 原生防守／出牌或 BEN 的 Precision 對手讀牌模型。

## 真實資料流

```text
Server-authorized actor and filtered PlayerView
  → BbaPrecisionBiddingProvider (NS/EW + opponent model check)
  → Immutable request (V1 profileId/revision/Meckwell .bbsa SHA,
                       own original 13 cards + dealer + vulnerability + ctx)
  → BbaPrecisionLoopbackTransport: 127.0.0.1, HTTP POST body only
  → precision_m33_sidecar.py (bounded single-thread HTTPServer)
     → verify BEN git commit
     → verify full Meckwell.bbsa SHA-256
     → verify native Linux x64 libEPBot.so SHA-256
     → select BBA/CC/BEN-21GF.bbsa or BBA/CC/BEN-SAYC.bbsa
     → native BBABotBid(position, own hand, dealer, NS/EW vulnerability,
                       auction) with our Meckwell/their matching opponent CC
  → Sanitized {bid,provider,profileId,revision,cardSha256}
  → Dart rechecks exact V1 identity + bid syntax
  → CallAction proposal → BridgeGame.apply (auction legality is Core-owned)
```

**零私牌外洩規則**：僅 actor 可見的一手牌 + 已公開 auction；不接受四家完整 Deal、其他家私牌、Dummy、PBN、帳號 Token 或任意 JSON 欄位。側車不記錄 URL、body、native stack trace；向客戶回傳錯誤碼，不將輸入、原始 native error 展露。無 127.0.0.1 外連、無 HTTP proxy、無 redirect、每次 POST 不超過 2048 bytes、回覆不超過 4096 bytes。暫時限制為**非正式單程序 localhost 研究服務**。

## 程式、測試與運行方式

| 檔案 | 內容 |
|---|---|
| [Dart Provider](../../packages/bridge_precision_adapter/lib/src/precision_bidding_provider.dart) | 不可變設定 `precisionSideIsNS`、對手 `21GF` 或 `SAYC`，從過濾 PlayerView 組合資料、解碼 `CallAction` |
| [Private transport](../../packages/bridge_precision_adapter/lib/src/bba_precision_loopback_transport.dart) | 僅 127.0.0.1/::1、非代理 POST、固定 schema、timeout、只回錯誤代碼 |
| [Native EPBot sidecar](../../scripts/precision_m33_sidecar.py) | 固定 BEN commit、Meckwell CC SHA、EPBot 原生 SHA；BBA NS/EW 兩組約定、auction 記錄；不提供任何 cardplay 接口 |
| [Dart tests](../../packages/bridge_precision_adapter/test/precision_bidding_provider_test.dart) | N/E seat、private hand、原生 identity、缺少授權/篡改回覆拒絕、HTTP POST 無 URL 手牌 |
| [Python tests](../../scripts/test_precision_m33_sidecar.py) | Schema/turn/auction/privacy／原生 CC 選型／真 HTTP 400 fail-closed、假 native 引擎，不需下載二進位 |
| [真 EPBot HTTP smoke](../../scripts/precision_m33_http_smoke.py) | 8 固定開叫牌 × 21GF/SAYC 對手卡 = **16 真 Native HTTP requests**，預期強 1♣ 成功（有正反牌例） |
| [Dart→真 EPBot→Bridge Core](../../packages/bridge_precision_adapter/test/native_precision_live_test.dart) | 以公開測試 Deal 建 `PlayerView`，實際 POST 請 native EPBot，將回覆由 Core 套用一次合法叫牌 |
| [CI](../../.github/workflows/precision-m33-provider.yml) | Pinned BEN checkout、Dart analyze/test、Python unittest、Linux native BBA live sidecar、整合/拒絕測試；**不啟動正式 Gateway、Flutter 或 VPS** |

本地若已有經授權及明確固定版本的 BEN checkout：

```bash
cd packages/bridge_precision_adapter && dart pub get && dart analyze --fatal-infos && dart test
cd ../..
python -m unittest discover -s scripts -p 'test_precision_m33_sidecar.py' -v
python scripts/precision_m33_sidecar.py --ben-root third_party_ben_m33 --port 18088 --research-only
# 另一個 shell 執行：
python scripts/precision_m33_http_smoke.py --port 18088
cd packages/bridge_precision_adapter && PRECISION_NATIVE_ORIGIN=http://127.0.0.1:18088/ dart test test/native_precision_live_test.dart
```

## M3.3 完成條件

1. Domain/Catalog：單一 V1 `BA-PRECISION-MECKWELL/r1`、13–15、來源 SHA 不變；BBA 商用／託管／修改／散布權由 owner 報告已取得。
2. Native Provider：需要讀取 `precision_m33_sidecar.py`，不能再冒用 BEN `ourSystem=PRECISION`；只執行 auction proposals。
3. Privacy + seat：驗證 NS/EW 判斷、dealer/auction 長度與輪值、只傳當下 actor hand，對手 CC 匹配；偽造任何欄位 fail-closed。
4. 真實模型證據：不能以 HttpStub 取代 native；須有 pinned EPBot 實際出價及 Dart 到 Core 的可重現 CI。
5. 規則驗證：Core 能拒絕非法出價；**完整 100+ expert golden fixtures、1♣ 應叫、1NT 上下界、競叫及 full-game 尚未簽核**。
6. Release：M3.4 真 Server-owned mixed-party provider routing、M3.5 正式負載仍需要獨立驗收。

## 重要局限與下一階段

- BBA 會以固定 `BEN-21GF.bbsa`／`BEN-SAYC.bbsa` 去解讀**敵方出價**，但這不代表另一方實際的 BEN 神經 bidder 學會了解讀 Precision。若 M3.4 希望同桌一組真 BEN、一組真 BBA，必須取得/訓練 Precision 對手 reader 模型或明確指定整桌的 BBA/native 相容模式，並向玩家揭露差異；**不能假稱 mixed engine 已完整通過**。
- Native provider 沒有 cardplay；出牌階段的搭檔默契、採樣與 Dummy 仍需獨立設計及實測。此階段不更動 Gateway production/Flutter 以保留 M2 的 2/1、SAYC。
- 暫不提交 native shared libraries 與特定授權原文；雖然 owner 已取得許可，工件歸屬、權利範圍與散布方式可單獨在受控部署紀錄驗證。
