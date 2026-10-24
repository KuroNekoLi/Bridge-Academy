# M2.5 真實 BEN 2/1／SAYC 混合制度全局驗收

> 2026-10-24 · SCOPED VERIFIED / TRUE BEN MODEL (NOT MOCK) · production not approved。

## 執行環境

- GitHub Actions：[M2.5 Genuine BEN #40087851963](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40087851963) — completed/success。
- BEN commit：ad8608af6e6bfe095863023f344f3cb2cbafec3d（不是浮動 main）。Python 3.12 + 上游 TensorFlow 依賴；在 Ubuntu 24.04 臨時 runner 上的私有 127.0.0.1 BEN。
- Gateway 是真實 Dart HTTP Server，Bridge Core 實際套用每個 CallAction / CardAction；BEN 真正回應 /bid、/lead、/play。BBA、PIMC、SuitC 關閉，部分 sampling 參數縮小，僅用于 CI。
- 同一固定測試 Deal：N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8。這是公開合成 PBN，不是私人或尚未公開的玩家牌。

## 實測數字

| 配置 | 結果 | 定約／分數 | 叫牌 | BEN Requests | 成功對局時長 | BEN p95 |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| NS=21GF / EW=SAYC | PASS：13 墩、52 張唯一牌 | 南家 4♣；NS +130 | 6 | 56（bid 4、lead 1、play 51） | 26.657s | 2409ms |
| NS=SAYC / EW=21GF | PASS：13 墩、52 張唯一牌 | 南家 4♣；NS +130 | 6 | 56（bid 4、lead 1、play 51） | 30.476s | 2203ms |

兩局 final version=58（6 次叫牌 + 52 張牌），使用不同 GameSystems fingerprint，沒有重複牌與漏墩。Server 會核對首次 action request_id 的重送不會再次改變牌局版本。具體資料來自該 GitHub Actions job 的兩筆 REAL BEN JSON 成功紀錄。

## 能證明／不能證明

**能證明：** Server-owned partnership IDs 在真 BEN worker 的 two-system 路由、授權 Gateway、Bridge Core 出牌與終局計分可以完整連通；兩組 NS/EW 對調配置都通過。

**不能證明：** Flutter 的實際 Chrome UI 在這個真 BEN 任務中完成完整對局（Flutter 只在別的 Mock/Demo 工作流程驗證）；大量複雜競叫、約定解釋或 AI 牌力達標；商業權重許可、4GB VPS、多人正式競賽 release gate。

## 重現與資料保護

在 GitHub Actions 頁面執行 ben-m2-multisystem-real.yml 的手動工作流程；本工作流程也對測試 script／CI 變更由 master push 觸發。所有帶手牌的 BEN GET URL 和 BEN 原始 log 都只保留在 runner 本機，不會上傳 artifact 或顯示給用戶。工具輸出限於公開 fixture 的摘要與比數。

參考：[M2.2～M2.5 綜合驗收](M2_2_TO_M2_5_IMPLEMENTATION_ACCEPTANCE.md)。
