# BEN M1.2 — Pinned model SHA-256 與原生相依項

> 來源：2026-10-24 GitHub Actions [#40075126810](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075126810) 的 `ben-m12-inventory.json`（只存檔名與 checksum，未含權重內容）。  
> BEN upstream commit：`ad8608af6e6bfe095863023f344f3cb2cbafec3d`。  
> **來源可稽核 ≠ 已允許商業使用、託管服務或再分發**。  
> 本文件紀錄釘選 checksum；有關 Runtime 真正啟動及記憶體，見 [M1.2 Acceptance](BEN_MULTI_SYSTEM_M1_2_ACCEPTANCE.md)。

## 1. 正式目標制度

### 2/1 Game Force — BEN `21GF`

| 來源 repo 內相對路徑 | SHA-256 |
|---|---|
| `models/TF2models/BEN-21GF-8742_2026-10-22-E30.keras` | `33ff95fe85ed29c9b1c1cd5ac8d6f9516f7d3d4547b17384fbdfadba56f69efd` |
| `models/TF2models/BEN-21GF-8742-Info_2026-10-22-E30.keras` | `486a692d9e517fc9dd96728f55040044af5fb787c3807605665f17fff3473cec` |
| `BBA/CC/BEN-21GF.bbsa` | `28e2d15f5f2761355b5d01c47b5c738e155533d212dd2953895c82da6584717a` |

### SAYC — BEN `SAYC`

| 來源 repo 內相對路徑 | SHA-256 |
|---|---|
| `models/TF2models/BEN-Sayc-8730_2025-04-20-E30.keras` | `6824fb96264d6536709b3c4d3fa989f321f5886662cfcb3a0e5c1e3c5cb67c32` |
| `models/TF2models/BEN-Sayc-Info-8730_2025-04-20-E30.keras` | `b87513a3f40fbdee65bc53977f6746c3c9cd4816de276bf3adcbbd2d44113abc` |
| `BBA/CC/BEN-SAYC.bbsa` | `496f4ac0c537c73a1c3f86306d08c047d2905edb81ae6dbd0cb1bc0dc3456c14` |

## 2. Native binary 與原始碼授權資訊

| 依賴 | SHA-256 |
|---|---|
| `bin/dds3-linux/dds3/_dds3.so` | `188bdf7d2efc4c9f82f57574f4a463c46edce9e2937dcb42bfdc96f18edd2f6f` |
| `bin/BBA/linux/x64/libEPBot.so` | `c35d00b7aacdb5fe7bd4a5aeb1f5cdacef9856f9fc7b4ff4048368b6827777b4` |
| `bin/BGA/linux/x64/BGADLL.so` | `0d3c7b12b8fc57cb1205dc7c448a11af6b6ad56b012a5f056c7cc41b94ca5d2f` |
| `bin/BGA/linux/x64/libdds.so` | `f849ce43164edab3e238e3dacfd65f7dab08fffde185c6726fb933975c8dc9f5` |
| `LICENSE` | `3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986` |

Native BBA/PIMC 在 M1.2 的隔離 Runtime Smoke **不啟用**，但保留來源與 checksum 紀錄。模型權重與這些 native binaries 的實際商用、服務與再分發許可仍須個別審查。

## 3. 完整載入集合

實際 inventory 共計 **35 個檔案**，約 **133,786,660 bytes**（含 registered opponent models、配置、卡片、模型、部分 native libs 與 LICENSE）。清冊原始 JSON 另存在 [Workflow #40075126810](https://github.com/KuroNekoLi/Bridge-Academy/actions/runs/40075126810) 的 artifact，短期保留；該 JSON 的 SHA-256 是：

`94df9dbbf383a5e774f95ad6f556bc9cf7cfe8d7bcfdb4681699778542da1cce`

這是 **清冊檔案**的 hash，不是所有模型權重的單一打包 hash；需要更高保證時必須再次對 pinned SHA 全部檔案重新計算並比對。

## 4. 安全與契約

- 絕不把外部模型、原生 binaries、四家手牌或內部服務日誌 commit 到本 repo。
- 真實模型品質的 `/bid` 與不同制度一致性屬 M1.3，不因檔案 checksum 通過而宣稱完成。
- 正式部署到 OVHcloud 及確認 4GB RAM 是否足夠，屬 M1.4／後續 Release Gate。
