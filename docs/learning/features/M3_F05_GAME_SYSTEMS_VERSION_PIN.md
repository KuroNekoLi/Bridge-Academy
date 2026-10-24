# M3-F05｜M2.1：讓 GameSystems 與制度版本跟著牌局固定

- Feature ID：**M3-F05**（三制度產品線的 M2.1；舊 M2-F01～F52 編號不重新使用）
- Milestone：**Multi-System M2.1**
- 類型：純 Dart Domain／可信任 Gateway／加密恢復相容性
- 工程狀態：**IMPLEMENTED；CI 結果以 GitHub Actions 為準**
- 學習狀態：**DELIVERED**（尚無使用者練習／精熟證據）
- 原始碼：[GameSystems](../../../packages/bridge_conventions/lib/src/game_systems.dart)、[AuthoritativeGame](../../../services/bridge_gateway/lib/src/authoritative_game.dart)、[BridgeGatewayService](../../../services/bridge_gateway/lib/src/gateway_service.dart)
- 驗收與測試：[Domain tests](../../../packages/bridge_conventions/test/game_systems_test.dart)、[Checkpoint tests](../../../services/bridge_gateway/test/game_systems_checkpoint_test.dart)、[CI](../../../.github/workflows/game-systems-m21.yml)、[M2.1 接受條件](../../research/M2_1_GAME_SYSTEMS_ACCEPTANCE.md)

## 功能目的與實際情境

你想讓 Bridge Academy 的南北搭檔使用 **2/1 Game Force**，東西搭檔使用 **SAYC**。假如中途修改了使用者設定，或 Gateway 重新啟動、從加密檔案恢復，**已開始的那一局不可被修改成新制度**。

本功能建立一個不含手牌與叫牌規則的 `bridge_conventions` Domain package；`PartnershipSystem` 表示單組搭檔固定版本，`GameSystems` 將兩組搭檔綁在一副牌上。這個 metadata 可被可信任的 Gateway 保存和還原，但 **M2.1 不會修改 BEN /bid 決策**；玩家在 Flutter 選制度、真正 routing 由 M2.2–M2.4 完成。

## 主要程式碼導讀

實際程式碼中的關鍵：

```dart
final class GameSystems {
  factory GameSystems({
    required PartnershipSystem northSouth,
    required PartnershipSystem eastWest,
  }) => GameSystems._(northSouth: northSouth, eastWest: eastWest);

  GameSystems._({
    required this.northSouth,
    required this.eastWest,
  }) : fingerprint = _fingerprint(northSouth, eastWest);

  static const schemaVersion = 1;
  final PartnershipSystem northSouth;
  final PartnershipSystem eastWest;
  final String fingerprint;
}
```

`final class`＋`final` 欄位讓一局的選定制度成為不可變的 value object。這和你熟悉的 Kotlin `data class GameSystems(val northSouth: ...)` 很像；另外以 SHA-256 對固定欄位序列算出 fingerprint，讓還原時能偵測 checkpoint 中被錯誤更動的 metadata。

資料流：

```text
Server-trusted ConventionCatalog
  → GameSystems(NS, EW) / legacyUnverified
  → BridgeGatewayService 發行新遊戲 Session
  → AuthoritativeGame._gameSystems（server-only，唯讀）
  → trustedCheckpoint()['gameSystems']（外層 AES-GCM 加密）
  → AuthoritativeGame.restore() → GameSystems.fromTrustedJson()
```

`ConventionCatalog` 只允許 `BA-21GF/r1`、`BA-SAYC/r1` 及 `LEGACY_UNVERIFIED/r1`，且 `modelRevision` 綁定已研究 BEN commit `ad8608af...`；這是候選映射與版本身分，**不是目前服務已裝好該模型的證明**。

## 為什麼這樣設計

採用 **Immutable Value Object + Allowlisted Registry + Fail-Closed Restore**。

**替代方案**：只儲存一個 `selectedSystem = 'SAYC'` 或每回合從 UI Settings 讀取。缺點是已開始的局可能因 UI 設定改變而被重新解釋，甚至在重啟後換成不同的 AI 模型版本。

**目前折衷**：還沒有完整支援自訂制度，所以只放入 allowlisted profiles；Precision 此時不能被憑空標為可執行，且 `GameSystems` 不改變 Bridge Core 法規判定。

**容易忽略的舊資料問題**：原本的 encrypted checkpoint 沒有 `gameSystems`。我們不能假定舊局是 2/1 或 SAYC，因此缺少這個欄位的舊局一律還原成 `LEGACY_UNVERIFIED`；反過來，**新格式裡已出現 gameSystems 但被破壞／夾帶不存在的版本，就拒絕恢復，而不是悄悄退回 LEGACY**。

**安全限制**：SHA-256 fingerprint 用來檢查結構一致性，不是密碼學身分認證的完整替代品；外層 AES-GCM 認證、可信任伺服器設定、存取權限依然不可少。且 M2.1 不信任 HTTP 的 profile 指定，遊戲的 public `view()` 格式維持不變。

## 驗證與實際證據

```bash
cd packages/bridge_conventions
dart pub get && dart analyze --fatal-infos && dart test

cd ../../services/bridge_gateway
dart pub get && dart analyze --fatal-infos && dart test
```

GitHub Actions：[M2.1 GameSystems CI](../../../.github/workflows/game-systems-m21.yml)，會跑 Domain 單元測試和全部 Gateway regression；實際通過與否請以工作流程記錄為準，未完成前不能宣稱 PASS。

重要斷言：
- NS/EW 互換會造成不同 fingerprint，序列化前後完全一致。
- 修改 `toJson()` 回傳的普通 Map 不會更動原本 GameSystems。
- 不受允許的 profile/revision、錯誤 modelId、錯誤 fingerprint、未知欄位均 fail-closed。
- AuthoritativeGame 的 trusted checkpoint 保存每局固定版本、還原後不變。
- 舊格式可恢復但明確標示 `LEGACY_UNVERIFIED`。
- Public API v1 不會多顯示任何牌手可操控的 gameSystems 欄位。
- 真 BEN 模型路由 / production / Precision / Android&iOS 裝置 QA **NOT RUN**。

## 練習與自我檢驗

**思考題（1 題）：** 為什麼 `GameSystems.fromTrustedJson()` 遇到 `profileId=BA-SAYC, revision=999` 應該拒絕，而不是「試著用最新 SAYC」？

**5–15 分鐘小練習（可選）：** 打開 `game_systems_test.dart`，建立 `GameSystems(NS=BA-21GF, EW=BA-SAYC)` 再對調兩者，確認 fingerprint 改變；試著更改輸出的 `toJson()`，看看原本物件是否不受影響。

**完成標準：** 你能解釋「資料不變」、「版本釘選」、「伺服器權威」和「快照完整性」分別解決什麼問題。沒有實際練習證據前學習狀態維持 DELIVERED。

## 下一步

M2.2：BenBotPolicy / Gateway 依照當前行動者座位從 GameSystems 推導 `ourSystem/theirSystem`，先驗證當前 worker 的 capabilities，禁止默默 fallback。M2.3 再從 server-owned Session 建立配置；M2.4 Flutter 選擇 UI 不能直接修改正在進行的遊戲。
