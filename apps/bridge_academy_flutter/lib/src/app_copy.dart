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

  static const Map<String, List<String>> _strings = {
    'title': ['Bridge Academy｜橋牌學院', 'Bridge Academy'],
    'language': ['切換英文', 'Switch to Chinese'],
    'mode': ['電腦對手', 'Computer opponents'],
    'demo': ['規則示範 Bot（不是 BEN）', 'Rules demo bot (NOT BEN)'],
    'live': ['真正 BEN API', 'Live BEN API'],
    'humanSeat': ['玩家座位', 'Your seat'],
    'newGame': ['開始新牌局', 'Start new deal'],
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
    'turn': ['輪到', 'Turn'],
    'noTurn': ['牌局結束', 'Deal finished'],
    'waitingBot': ['電腦思考中…', 'Computer is thinking…'],
    'contract': ['定約', 'Contract'],
    'notYet': ['未定', 'Pending'],
    'auction': ['叫牌紀錄', 'Auction history'],
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
    'errorBot': ['無法完成電腦回合。檢查 BEN 服務或重試。',
      'Could not complete the computer turn. Check BEN or retry.'],
    'retry': ['重試電腦回合', 'Retry computer turn'],
    'demoNotice': ['示範模式使用測試 Bot（不是 BEN），可選固定或隨機發牌。',
      'Demo uses a test bot (NOT BEN), with fixed or shuffled deals.'],
    'liveNotice': ['真 BEN 模式需要可連線的 BEN API，手牌只送往受信任服務。',
      'Live BEN mode requires a reachable, trusted BEN API.'],
    'notStarted': ['選擇座位及對手，開始練習。', 'Choose your seat and opponents.'],
  };
}

