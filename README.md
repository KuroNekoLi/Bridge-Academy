# Bridge Academy

以 Flutter、Dart Bridge Core 和實際 BEN/BBA 橋牌 AI 研究打造的橋牌練習、複盤與學習專案。**已完成功能不等於公開正式上線**，所有「真 BEN」或「原生 Precision」的通過範圍以最新 CI 和固定 SHA 為準。

## 文件（現在只有 7 份）

- [全部 docs 的三類入口](docs/README.md)
- **已實現功能**：[功能、架構與橋牌不變規則](docs/implemented/FEATURES.md) · [對應工程教學](docs/implemented/ENGINEERING_NOTES.md)
- **接下來如何規劃**：[產品路線與發行門檻](docs/planning/ROADMAP.md) · [使用者決策](docs/planning/DECISIONS.md) · [工作交接](docs/planning/CURRENT_HANDOFF.md)
- **研究報告**：[BEN／21GF／SAYC／Precision／自訂約定／教練／容量與授權](docs/research/RESEARCH_REPORTS.md)

## 目前有哪些可用功能

Bridge Core 負責四座位叫牌、Double/Redouble、合法跟牌、定約、13 墩及 Duplicate 計分；Flutter 可玩本機與選擇性 Gateway 牌桌、四局／主打／叫牌／每日非排名練習、雙語學院、加密本機歷史、PBN 匯入匯出、重播與終局 DDS。NS／EW 可配置 2/1 或 SAYC，真 BEN 具固定整局技術驗收；BBA Meckwell Precision 的原生研究可行，但不能等同已批准的正式競賽 AI。可編輯本機自訂約定草稿和公開叫牌教練，但自訂 AI 不具實際可玩引擎證據。

## 下一步與尚未通過的門檻

優先 **U3** 完整桌面／窄屏體驗與演出、**U4** Gateway 續局／經授權雲端歷史、**A4.5** 正式託管（TLS／身份／授權／容量實測），之後補 A7 真人與裝置發行驗收。公平同牌競賽、MP/IMP 排名和真人多人桌尚未實作。4GB VPS 尚未做可核准的正式 BEN 容量／安全驗收，**Production NO-GO**。

**重要限制**：使用者暫緩 A3.5 真人 UX、Android emulator 及 Android/iOS 實機 QA；沒有後續明確批准不要自行啟動。每項新功能應更新同一份功能與工程筆記，附實際測試和 CI，不再新建零散 docs。參考 [AGENTS.md](AGENTS.md)。

## 程式與檢驗入口

| 項目 | 位置 |
| --- | --- |
| Game rules | [`packages/bridge_core/`](packages/bridge_core/) |
| BEN / Precision | [`packages/bridge_ben_adapter/`](packages/bridge_ben_adapter/)、[`packages/bridge_precision_adapter/`](packages/bridge_precision_adapter/) |
| Conventions and coach | [`packages/bridge_conventions/`](packages/bridge_conventions/) |
| Authorized game Gateway | [`services/bridge_gateway/`](services/bridge_gateway/) |
| Flutter Web / mobile app | [`apps/bridge_academy_flutter/`](apps/bridge_academy_flutter/) |
| CI tests | [GitHub Actions](https://github.com/KuroNekoLi/Bridge-Academy/actions) |

原本 190 份 docs 的歷史版本仍可在清理前的 Git commits 查回。此次收斂不刪專案程式碼、測試、Git 歷史，也不啟動產品發行。
