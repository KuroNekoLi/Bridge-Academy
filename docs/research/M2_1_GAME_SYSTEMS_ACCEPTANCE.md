# Bridge Academy — M2.1 GameSystems 不可變版本驗收

> 日期：2026-10-24。功能：Multi-System M2.1 / M3-F05 教學。
> 工程狀態：IMPLEMENTED；最終驗收以包含 fail-closed guard 的 CI 為準。
> 範圍只涵蓋純 Dart 制度版本、Server-owned metadata、加密 checkpoint 與既有回歸；**不包含** BEN 真正依新制度叫牌、Precision、Flutter 選單、Production 上線。

## 需求與正式邊界

一局橋牌有南北與東西兩組搭檔；兩組制度可以不同，而且在建局後不受 UI 偏好改變、應用重新啟動或 Session 恢復影響。Bridge Core 仍只負責合法叫牌、出牌、定約及計分；不引入任何 SAYC/2/1 語義。伺服器仍只讓 BEN 接收合法 PlayerView 所允許的資訊。

本功能新增 package： [bridge_conventions](../../packages/bridge_conventions/lib/src/game_systems.dart)，其中：
- `PartnershipSystem` 封裝 `profileId`、`revision`、`engineId`、`modelId`、`modelRevision`、`profileFingerprint`。
- `GameSystems` 以不可變 northSouth/eastWest 分組搭配，並產生 canonical SHA-256 game fingerprint。
- `ConventionCatalog` 僅登錄三個 profile：`LEGACY_UNVERIFIED/r1`、`BA-21GF/r1` 和 `BA-SAYC/r1`。PRECISION 尚未可用。
- 21GF/SAYC 的 `modelRevision` 為已研究 BEN git commit `ad8608af6e6bfe095863023f344f3cb2cbafec3d`；**不是實際權重的 SHA-256**。模型權重清冊仍見 [M1.2 pinned assets](BEN_M12_PINNED_ASSETS.md)。

## 整合和保證

1. [BridgeGatewayService](../../services/bridge_gateway/lib/src/gateway_service.dart) 只接受**可信任的 Server 建構參數** `GameSystems`，不由 HTTP session/action body 決定。新建遊戲固定 metadata，原有 Session id、版本、去重與 Hidden Deal 規則維持。
2. [AuthoritativeGame](../../services/bridge_gateway/lib/src/authoritative_game.dart) 保存 `final _gameSystems`。由 `trustedCheckpoint()` 寫入 `gameSystems`，走既有 AES-GCM `EncryptedSessionStore`。
3. 加密 archive 舊格式**沒有** `gameSystems` 時，復原為 `LEGACY_UNVERIFIED`，不冒稱舊局使用 SAYC 或 2/1。
4. archive **含有** `gameSystems` 但 profile/version/model、schema 或 fingerprint 被破壞、資料被增減、版本未登錄，`GameSystems.fromTrustedJson()` 拒絕恢復，不退回「新版預設」。
5. 新版已固定 21GF/SAYC metadata 的遊戲，在 M2.2 真實模型 routing 尚未證明以前，`action`、`advance` 一律拒絕並回報 `503 system_router_unavailable`。既有 LEGACY_UNVERIFIED 遊戲仍可沿用既有 BEN。這避免 metadata 說 SAYC、實際 AI 卻用預設 GIB 的錯誤。
6. PlayerView 與外部 `/v1/games/view` 回傳 schema 不變。SHA-256 fingerprint 是 deterministic metadata 檢查，**不取代 AES-GCM 認證、可信任後端授權與 Worker 權重核對**。

## 可重現測試

[Domain tests](../../packages/bridge_conventions/test/game_systems_test.dart) 包含 catalog pin、不同 NS/EW、serialization/map copy、篡改／未註冊版本拒絕、legacy。  
[Gateway tests](../../services/bridge_gateway/test/game_systems_checkpoint_test.dart) 包含 trusted checkpoint、JSON roundtrip、錯誤版本拒絕、legacy migration、候選模型 routing fail-closed。  
CI：[M2.1 Scoped CI](../../.github/workflows/game-systems-m21.yml) + [Bridge Gateway 完整回歸](../../.github/workflows/bridge-gateway.yml)。

執行指令：

    cd packages/bridge_conventions
    dart pub get && dart analyze --fatal-infos && dart test --reporter expanded

    cd ../../services/bridge_gateway
    dart pub get && dart analyze --fatal-infos && dart test --reporter expanded

首次在 CI [#40077396984](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40077396984) 看到**5/5 Domain、39/39 Gateway** 加上雙 package analyze 零 issues；這是加入最後一道 routing fail-closed 防線**以前**的結果，最終結果須另外核對最新 CI。

**NOT RUN / 尚未核准**：M2.2 `ourSystem/theirSystem`、M2.3 Session 制度選擇、M2.4 Flutter UI、M2.5 真 BEN 完整對局、Precision／任意自訂制度、機器人排名賽、Production 4GB VPS、第三方模型權利及 Android/iOS device QA（使用者目前明令暫緩）。

## 回滾與交接

新增 package 沒有更改 Bridge Core 及 BEN 的既有推論；在未解除 M2.2 routing gate 時可回滾程式，但新增含 profile metadata 的 encrypted checkpoint 不可交給不識別其 schema 的舊服務直接覆蓋。M2.2 首要工作是從 server-owned NS/EW pin 與真正的 actor seat 推導 BEN 兩側制度，核對該 worker 的能力、模型 commit／weights、fail closed，完成後才解除暫停檢查。
