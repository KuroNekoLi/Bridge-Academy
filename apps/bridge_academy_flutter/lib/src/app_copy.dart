/// All user-visible prose is centralized for zh-TW and en.
class AppCopy {
  const AppCopy(this.isEnglish);
  final bool isEnglish;

  String t(String key) {
    final values = _strings[key];
    if (values == null) {
      throw ArgumentError.value(key, 'key', 'Missing localized string');
    }
    return values[isEnglish ? 1 : 0];
  }

  String seat(String code) => t('seat$code');
  String boardNumber(int number) => '${t('boardNumber')}: $number';
  String dealer(String code) => '${t('dealer')}: ${seat(code)}';
  String vulnerability(String name) =>
      '${t('vulnerability')}: ${t('vul_$name')}';
  String formatTurn(String? code) => code == null
      ? t('noTurn')
      : '${t('turn')}: ${seat(code)}';
  String replayProgress(int index, int total) =>
      '${t('replayStep')}: $index / $total';
  String replayWinner(String seatCode) =>
      '${t('replayTrickWinner')}: ${seat(seatCode)}';
  String remaining(int count) => '${t('remaining')}: $count';
  String trickCount(int count) => '${t('tricks')}: $count / 13';
  String score(int score) => "${t('nsScore')}: ${score > 0 ? '+' : ''}$score";
  String contract(String value) => '${t('contract')}: $value';
  String formatCard(String code, {required bool legal}) =>
      '${legal ? t('legalCard') : t('card')} $code';

  /// Localized speech for already-visible card codes; never reads a private Deal.
  String cardName(String code) {
    final suit = switch (code[0]) {
      'S' => t('suitS'),
      'H' => t('suitH'),
      'D' => t('suitD'),
      'C' => t('suitC'),
      _ => code[0],
    };
    final rank = switch (code.substring(1)) {
      'A' => t('rankA'),
      'K' => t('rankK'),
      'Q' => t('rankQ'),
      'J' => t('rankJ'),
      'T' => t('rankT'),
      final other => other,
    };
    return '$suit $rank';
  }

  String accessibleCard(String code, {required bool playable}) =>
      '${t(playable ? 'playableCard' : 'notPlayableCard')}: ${cardName(code)}';

  String seatSummary(String code,
      {required bool active, required bool viewer,
      required bool dummy, required int remaining}) =>
      [
        seat(code),
        if (viewer) t('yourSeat'),
        if (dummy) t('dummy'),
        if (active) t('activeSeat'),
        this.remaining(remaining),
      ].join(', ');

  static const Map<String, List<String>> _strings = {
    'title': ['Bridge Academy｜橋牌學院', 'Bridge Academy'],
    'language': ['切換英文', 'Switch to Chinese'],
    'mode': ['電腦對手', 'Computer opponents'],
    'demo': ['規則示範 Bot（不是 BEN）', 'Rules demo bot (NOT BEN)'],
    'live': ['真正 BEN API', 'Live BEN API'],
    'humanSeat': ['玩家座位', 'Your seat'],
    'newGame': ['開始新牌局', 'Start new deal'],
    'webCheckpointCaution': [
      '瀏覽器存檔使用加密，仍無法防範同網站惡意程式。請使用受信任的 HTTPS 網站；清除瀏覽器資料將無法恢復牌局。',
      'Browser saves are encrypted, but do not protect against malicious same-site scripts. Use trusted HTTPS sites; clearing browser data prevents recovery.',
    ],
    'boardNumber': ['牌號', 'Board'],
    'dealer': ['發牌者', 'Dealer'],
    'vulnerability': ['局況', 'Vulnerability'],
    'vul_none': ['雙方無局', 'Neither vulnerable'],
    'vul_ns': ['南北有局', 'N/S vulnerable'],
    'vul_ew': ['東西有局', 'E/W vulnerable'],
    'vul_both': ['雙方有局', 'Both vulnerable'],
    'nextBoard': ['下一副牌', 'Next board'],
    'replaySameBoard': ['重打同一副牌', 'Replay same board'],
    'boardMode': ['發牌方式', 'Deal source'],
    'trainingBoard': ['固定教學牌例', 'Fixed training deal'],
    'freshBoard': ['新隨機牌局', 'Fresh shuffled deal'],
    'restart': ['重新發牌', 'Restart deal'],
    'seatN': ['北（N）', 'North (N)'],
    'seatE': ['東（E）', 'East (E)'],
    'seatS': ['南（S）', 'South (S)'],
    'seatW': ['西（W）', 'West (W)'],
    'yourSeat': ['你', 'You'],
    'activeSeat': ['目前輪到此座位', 'Seat to act'],
    'playableCard': ['可出牌', 'Playable card'],
    'notPlayableCard': ['目前不能出牌', 'Card not currently playable'],
    'suitS': ['黑桃', 'Spades'],
    'suitH': ['紅心', 'Hearts'],
    'suitD': ['方塊', 'Diamonds'],
    'suitC': ['梅花', 'Clubs'],
    'rankA': ['A', 'Ace'],
    'rankK': ['K', 'King'],
    'rankQ': ['Q', 'Queen'],
    'rankJ': ['J', 'Jack'],
    'rankT': ['10', 'Ten'],
    'turn': ['輪到', 'Turn'],
    'noTurn': ['牌局結束', 'Deal finished'],
    'waitingBot': ['電腦思考中…', 'Computer is thinking…'],
    'contract': ['定約', 'Contract'],
    'notYet': ['未定', 'Pending'],
    'auction': ['叫牌紀錄', 'Auction history'],
    'lastTrick': ['上一墩', 'Last trick'],
    'close': ['關閉', 'Close'],
    'call': ['叫牌', 'Make bid'],
    'pass': ['不叫（Pass）', 'Pass'],
    'double': ['賭倍（X）', 'Double (X)'],
    'redouble': ['再加倍（XX）', 'Redouble (XX)'],
    'level': ['線位', 'Level'],
    'strain': ['花色', 'Strain'],
    'strainC': ['梅花 ♣', 'Clubs ♣'],
    'strainD': ['方塊 ♦', 'Diamonds ♦'],
    'strainH': ['紅心 ♥', 'Hearts ♥'],
    'strainS': ['黑桃 ♠', 'Spades ♠'],
    'strainNT': ['無王 NT', 'No Trump NT'],
    'cards': ['你的手牌', 'Your hand'],
    'dummy': ['公開明手', 'Exposed dummy'],
    'hidden': ['尚未公開', 'Not exposed yet'],
    'legalCard': ['可出', 'Playable'],
    'card': ['牌', 'Card'],
    'remaining': ['剩餘張數', 'Cards remaining'],
    'tricks': ['已完成墩數', 'Completed tricks'],
    'currentTrick': ['本墩出牌', 'Current trick'],
    'replayTitle': ['牌局歷史回放', 'Deal replay'],
    'replayStep': ['事件步驟', 'Event step'],
    'replayStart': ['牌局開始（尚未叫牌）', 'Deal started (before auction)'],
    'replayBy': ['操作者', 'Actor'],
    'replayTrickWinner': ['上一墩贏家', 'Last trick winner'],
    'replayFirst': ['第一步', 'First'],
    'replayPrevious': ['上一步', 'Previous'],
    'replayNext': ['下一步', 'Next'],
    'replayLast': ['最後一步', 'Last'],
    'nsScore': ['南北方分數', 'North–South score'],
    'end': ['牌局結算', 'Deal result'],
    'passOut': ['四家 Pass Out，0 分', 'Four passes: Pass Out, 0 points'],
    'errorInvalid': ['操作未被橋牌規則接受，請重新選擇。',
      'The bridge rules rejected that action. Choose again.'],
    'restoringGame': ['正在恢復上次牌局…', 'Restoring saved game…'],
    'restoredGame': ['已恢復上次牌局', 'Saved board restored'],
    'retrySave': ['重試儲存', 'Retry saving'],
    'recoveredOlderCheckpoint': [
      '最新存檔已損壞，系統改用較早的合法備份。最近的叫牌或出牌可能遺失；請先確認牌局狀態再繼續。',
      'The latest save was damaged. An older valid backup was restored. Recent bids or plays may be missing. Review the board before continuing.',
    ],
    'ackRecoveredCheckpoint': ['了解風險，繼續牌局', 'I understand, continue'],
    'errorSave': ['牌局尚未成功儲存，請重試後繼續。',
      'Board could not be saved. Retry before continuing.'],
    'errorStorage': ['無法讀取本機牌局。可選擇開始新牌局。',
      'Could not read local save. You can start a new board.'],
    'errorCorruptSave': ['舊牌局格式不支援或資料有誤，可開始新牌局。',
      'Saved board is unsupported or invalid. Start a new board.'],
    'errorBot': ['無法完成電腦回合。檢查 BEN 服務或重試。',
      'Could not complete the computer turn. Check BEN or retry.'],
    'retry': ['重試電腦回合', 'Retry computer turn'],
    'demoNotice': ['示範模式使用測試 Bot（不是 BEN），可選固定或隨機發牌。',
      'Demo uses a test bot (NOT BEN), with fixed or shuffled deals.'],
    'liveNotice': ['真 BEN 模式需要可連線的 BEN API，手牌只送往受信任服務。',
      'Live BEN mode requires a reachable, trusted BEN API.'],
    'gatewayNotice': [
      '伺服器牌桌模式：牌局與 AI 決策由可信任的 Gateway 管理，不會使用本機示範 Bot。此模式目前僅供明確設定的開發環境。',
      'Server-owned Gateway table: the server controls the deal and AI. No Demo fallback. Only for explicitly configured development environments.',
    ],
    'gatewayNewSession': ['開始新的伺服器牌局', 'Start server-owned deal'],
    'gatewayRefresh': ['查詢伺服器牌局', 'Refresh server view'],
    'gatewayRetry': ['重試原請求', 'Retry same request'],
    'gatewayWaiting': ['等待伺服器回應…', 'Waiting for server…'],
    'gatewayNotStarted': [
      '伺服器模式已啟用，按「開始新的伺服器牌局」取得短效 Session。',
      'Gateway mode is enabled. Start a server-owned deal to obtain a short-lived session.',
    ],
    'gatewayInvalidConfig': [
      'Gateway 網址設定無效。正式服務僅允許 HTTPS；本機開發只允許 localhost。請檢查設定，系統不會自動切回 Demo。',
      'Invalid Gateway origin. Use HTTPS, or localhost for development. The app will not fall back to Demo.',
    ],
    'gatewayExpired': [
      '此伺服器 Session 已到期或權杖失效。請建立新牌局；舊請求不會以新身分自動重送。',
      'This server session expired. Start a new deal. The old action will not be retried with a new token.',
    ],
    'gatewayConflict': [
      '伺服器牌局版本或請求識別衝突。請先查詢伺服器最新牌局，不要另送同一張牌。',
      'Server event version or request ID conflict. Refresh server view before attempting any new action.',
    ],
    'gatewayRateLimited': [
      '伺服器呼叫過於頻繁。請稍後使用原請求重試。',
      'Too many server requests. Wait, then retry the same request.',
    ],
    'gatewayUnavailable': [
      'Gateway／BEN 暫時無法提供服務。請查詢牌局後用原請求重試，系統不會使用 Demo Bot。',
      'Gateway/BEN is unavailable. Refresh and retry the original request; there is no Demo fallback.',
    ],
    'gatewayOffline': [
      '網路中斷，尚未確認先前行動是否成功。請查詢伺服器牌局，再重試相同請求。',
      'Connection lost; the previous action may have committed. Refresh server view, then retry the same request.',
    ],
    'gatewayInvalidResponse': [
      '伺服器回應格式無效，操作已暫停。請檢查 Gateway 服務。',
      'Invalid server response. Actions are paused; check the Gateway service.',
    ],
    'gatewayRetryPending': [
      '已重新取得伺服器狀態，仍有未確認的請求。按「重試原請求」使用相同的 Request ID，不會建立新行動。',
      'Server view refreshed, but the previous action is still unconfirmed. Retry with the same request ID.',
    ],
    'notStarted': ['選擇座位及對手，開始練習。', 'Choose your seat and opponents.'],
  };
}

