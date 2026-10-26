# 已實作的技術架構

更新：2026-10-26。本文件只記目前程式中存在的組件與邊界。橋牌權威規則另見 [BRIDGE_RULES](BRIDGE_RULES.md)。

```text
Flutter (BridgeAcademyApp)
 ├─ local BridgeSession ─ SinglePlayerCoordinator ─┐
 ├─ opt-in GatewayGameSession → server-owned Game ─┼─→ Bridge Core
 │                              ├─ BEN AI adapter ─┤    叫牌／出牌是否合法、
 │                              └─ Precision 研究 ─┘    墩數與計分唯一裁判
 ├─ local encrypted checkpoint / completed history
 ├─ learning, DDS completed-game review, public auction coach
 └─ filtered PlayerView → BridgeTable / visible playing_cards renderer
```

## 主要模組

| 來源 | 職責 | 不可跨越的邊界 |
| --- | --- | --- |
| [bridge_core](../../packages/bridge_core/) | Auction、play、contract、duplicate scoring、replay | AI／UI 只能提議 Action，Core 才能裁決 |
| [bridge_conventions](../../packages/bridge_conventions/) | 南北／東西 GameSystems、revision/fingerprint、草稿與公開叫牌 | 使用者草稿 `ENGINE_UNVERIFIED` 絕不改真 AI |
| [bridge_ben_adapter](../../packages/bridge_ben_adapter/) | BEN 21GF／SAYC 真模型每回合請求 | 只傳合法座位可見資料，不能默默 fallback |
| [bridge_precision_adapter](../../packages/bridge_precision_adapter/) | BBA/EPBot Meckwell 研究 | 不是 BEN neural Precision reader，正式版仍關閉 |
| [bridge_dds_adapter](../../packages/bridge_dds_adapter/) | 終局 DDS 分析 | 真牌局進行中不得泄漏雙明手牌 |
| [bridge_gateway](../../services/bridge_gateway/) | 本機 server-owned Game／Bearer／版本、重試與復原 | 非公開託管與跨節點一致性 |
| [bridge_academy_flutter](../../apps/bridge_academy_flutter/) | 桌面 UI、練習、歷史與可見手牌 | Widget 不拿私有 Deal、不判合法 |
| [scripts 與 CI](../../scripts/) | 正版固定測試、負載研究與 safe preflight | CI runner success ≠ Production GO |

## 資料流與安全

1. Core 以 `PlayerView` 限定每座位所見牌；明手只在法則允許時出現。原生 DDS、BEN 與 Flutter 不得繞過視角權限。
2. 玩家點叫牌／牌張 → 送出有版本的 Action → Core／Gateway 驗證 → 更新事件與投影。UI 切換、捲動、動畫不應改權威 GameState。
3. Gateway 會鎖定每局 NS/EW profile（21GF／SAYC）；BEN request 的 `ourSystem`／`theirSystem` 必須隨座位正確轉換。Unknown system fail closed。
4. Gateway 研究版 Precision 由獨立 BBA/EPBot sidecar 叫牌；其研究出牌提案只可從 `legalCards` 選取，不能當正式強牌力證明。
5. PBN 匯入必須驗證；本機 checkpoint 必須經 schema、版本、完整性／rollback 核對。未實作跨節點原子交易、正式 TLS 身分與雲端 history。
6. `playing_cards 0.4.1+11` 是 render-only adapter；窄屏橫向捲動保持手牌順序、授權與可點擊大小，不能把未曝光牌丟入 Widget。

詳細 release blocker 見 [產品規劃](../planning/ROADMAP.md) 和 [發行門檻](../planning/RELEASE_CHECKLIST.md)。