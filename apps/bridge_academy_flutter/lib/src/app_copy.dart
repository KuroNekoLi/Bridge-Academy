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
  String historyPage(int current, int total) =>
      '${t('historyPage')}: $current / $total';
  String contract(String value) => '${t('contract')}: $value';
  String justDeclareProgress(int tricks, int target) =>
      '${t('justDeclareWonTricks')}: $tricks / $target';
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
    'academyOpen': ['開啟橋牌學院', 'Open bridge lessons'],
    'uxWelcome': ['今天想怎麼練習橋牌？', 'How would you like to practice?'],
    'uxGuestHint': ['不需登入，可以直接練習。', 'No account needed to start.'],
    'uxHome': ['首頁', 'Home'],
    'uxPlay': ['打牌', 'Play'],
    'uxReview': ['複盤', 'Review'],
    'uxMe': ['我的', 'Me'],
    'uxQuickStart': ['快速開始示範牌局', 'Start a Demo deal'],
    'uxQuickHint': ['北家・固定教學牌例・規則 Bot（不是 BEN）', 'North · teaching deal · rules bot (NOT BEN)'],
    'uxResume': ['繼續目前牌局', 'Continue current deal'],
    'uxResumeHint': ['保留已確認的叫牌與出牌，不會重新發牌。', 'Keep committed actions; no new deal is generated.'],
    'uxCustomPlay': ['自訂牌桌', 'Customize table'],
    'uxCustomHint': ['選擇座位、牌源與可用電腦模式。', 'Choose your seat, deal source and available opponents.'],
    'uxLearn': ['學習橋牌', 'Learn bridge'],
    'uxLearnHint': ['六堂雙語互動課程。', 'Six bilingual interactive lessons.'],
    'uxShortPractice': ['短時間練習', 'Short practice'],
    'uxShortHint': ['到牌桌選擇叫牌練習或 Just Declare。', 'Choose bidding or Just Declare on the table.'],
    'uxDailyPractice': ['每日練習', 'Daily practice'],
    'uxDailyHint': ['本機四副固定練習牌，非排名賽事。', 'Four local fixed deals, not a ranked contest.'],
    'uxReviewHint': ['重看已完成牌局與教學式複盤。', 'Open saved deals and guided review.'],
    'uxNoCompetition': ['尚未提供正式比賽、排行或好友對戰。', 'Rankings and friend matches are not available yet.'],
    'uxDemoStatus': ['規則示範 Bot 可本機練習；真正 BEN 需要明確設定可信任服務。', 'Rules-demo Bot works locally; real BEN requires a configured trusted service.'],
    'uxGatewayStatus': ['已設定 Gateway；尚未驗證連線，不會自動切換 Demo。', 'Gateway configured; connectivity not checked. No Demo fallback.'],
    'uxGatewayOpen': ['開啟伺服器牌桌', 'Open server table'],
    'uxNoAccount': ['目前只有本機設定，尚不支援帳號同步。', 'Local settings only; no account sync.'],
    'uxRecoveryWarning': ['系統從先前有效存檔恢復。請到牌桌確認恢復後再操作。', 'Recovered an older valid checkpoint. Confirm it at the table before acting.'],
    'uxSaveWarning': ['儲存尚未成功，請進入牌桌修復，切勿覆蓋原牌局。', 'Saving is blocked. Open the table to recover; do not replace the deal.'],
    'uxReplaceTitle': ['放棄進行中的牌局？', 'Abandon this deal?'],
    'uxReplaceWarning': ['開始新牌局會取代尚未完成的叫牌及出牌進度。', 'A new deal replaces the unfinished auction and play.'],
    'uxCancel': ['取消', 'Cancel'],
    'uxReplace': ['放棄並開始', 'Abandon and start'],

    'mode': ['電腦對手', 'Computer opponents'],
    'demo': ['規則示範 Bot（不是 BEN）', 'Rules demo bot (NOT BEN)'],
    'live': ['真正 BEN API', 'Live BEN API'],
    'humanSeat': ['玩家座位', 'Your seat'],
    'newGame': ['開始新牌局', 'Start new deal'],
    'biddingStart': ['開始叫牌練習', 'Start bidding practice'],
    'biddingTitle': ['B3 叫牌練習', 'B3 Bidding practice'],
    'biddingScope': [
      '只練叫牌，不出牌、不計分；目前使用本機規則 Bot（非 BEN），提示不代表最佳叫品。',
      'Auction-only: no cards or scores. Local rules bot (NOT BEN); hints are not optimal strategy.',
    ],
    'biddingProfile': [
      '教學約定 BA-NATURAL-NT v1（尚未經外部專家審核）',
      'Teaching agreement BA-NATURAL-NT v1 (not expert-reviewed)',
    ],
    'biddingHint': ['本手牌的示範建議', 'Sample call for your hand'],
    'biddingFinished': [
      '叫牌已完成。可以開始下一副練習。',
      'Auction complete. You may start another drill.',
    ],
    'biddingOpening1NT': [
      '教學約定：前面僅 Pass 的 1NT 開叫，表示 15–17 HCP 均型；無法驗證其他人的真實牌力。',
      'Teaching agreement: 1NT opening after passes shows 15–17 HCP balanced; does not verify hidden hand strength.',
    ],
    'biddingInvite2NT': [
      '教學約定：搭檔 1NT 開叫後，以 2NT 邀請進局，表示 8–9 HCP（無敵方插叫）。',
      'Teaching agreement: 2NT invites game with 8–9 HCP after uncontested partner 1NT.',
    ],
    'biddingGame3NT': [
      '教學約定：搭檔 1NT 開叫後的 3NT 進局，表示 10+ HCP（無敵方插叫）。',
      'Teaching agreement: 3NT game response shows 10+ HCP after uncontested partner 1NT.',
    ],
    'biddingAccept3NT': [
      '教學約定：1NT 開叫者接受搭檔 2NT 邀請，以 3NT 進局。',
      'Teaching agreement: 1NT opener accepts partner’s 2NT invitation with 3NT.',
    ],
    'b3ProfileLabel': ['叫牌約定版本', 'Convention profile'],
    'b3PreviewToggle': ['預覽新約定', 'Preview proposed agreements'],
    'b3Unreviewed': [
      '教學草稿・未經專家審核',
      'Educational draft · not expert-reviewed',
    ],
    'b3PreviewDisclaimer': [
      '預覽僅提供約定語義，不影響示範 Bot 或 BEN 的叫牌，亦不保證牌力。',
      'Preview only: no changes to the demo bot or BEN, and no guarantee of hand strength.',
    ],
    'b3AssumptionNatural': [
      '僅適用於本教學約定下，雙方沒有競叫的開叫與回應；不代表實際持牌。',
      'Only for this teaching agreement, an uncontested opening and response; does not prove the actual hand.',
    ],
    'b3AssumptionPreview': [
      '預設雙方已約定採用此慣例、1NT 為開叫而非插叫，且敵方沒有叫牌干擾。',
      'Assumes partnership agreement, an opening (not overcall) 1NT and no competitive interference.',
    ],
    'b3Stayman': [
      'Stayman 2♣：詢問 1NT 開叫者有無四張高花。僅為預覽約定。',
      'Stayman 2C: asks whether the 1NT opener holds a four-card major; preview only.',
    ],
    'b3JacobyHearts': [
      'Jacoby Transfer 2♦：請 1NT 開叫者以 2♥ 回應。僅為預覽約定。',
      'Jacoby Transfer 2D: asks 1NT opener to rebid 2H; preview only.',
    ],
    'b3JacobySpades': [
      'Jacoby Transfer 2♥：請 1NT 開叫者以 2♠ 回應。僅為預覽約定。',
      'Jacoby Transfer 2H: asks 1NT opener to rebid 2S; preview only.',
    ],
    'b3RuleId': ['規則 ID', 'Rule ID'],
    'b3Source': ['教學依據', 'Teaching reference'],
    'b3PreviewOnly': [
      '本約定尚未由專家驗證，也沒有接入 AI 建議或評分。',
      'This agreement is not expert-verified and is not used for AI suggestions or grading.',
    ],
    'b3NoRule': [
      '無匹配規則（UNKNOWN）；可能存在插叫、加倍或未支援的搭檔約定。',
      'No matching rule (UNKNOWN); interference, doubles or unsupported agreements may apply.',
    ],
    'biddingUnknown': [
      '此叫品無法在本版約定下確定解釋，不應推測其他人的真實牌力。',
      'No supported explanation for this call; do not infer hidden hands.',
    ],
    'justDeclareStart': ['只練莊家（Just Declare）', 'Just Declare practice'],
    'justDeclareLevel': ['選擇定約線位', 'Choose contract level'],
    'justDeclareStrain': ['選擇定約花色', 'Choose contract strain'],
    'justDeclareActive': [
      '莊家練習：定約直接設定，沒有模擬叫牌。首攻後可操作搭檔的明手；目前使用規則示範 Bot，非 BEN。',
      'Declarer practice: contract set without an auction. You control partner dummy after the opening lead. Rules-demo Bot only, not BEN.',
    ],
    'justDeclareSeatHint': [
      '莊家座位使用上方的「玩家座位」選擇；四個座位均可練習。',
      'Your declarer seat comes from Your seat above; all four seats are supported.',
    ],
    'justDeclareDeclarer': ['莊家', 'Declarer'],
    'justDeclareDummy': ['明手座位', 'Dummy seat'],
    'justDeclareWonTricks': ['莊家方已贏墩數／定約目標', 'Declarer tricks / contract target'],
    'justDeclareMade': ['練習成功：完成定約', 'Practice success: contract made'],
    'justDeclareDown': ['練習未達標：定約宕掉', 'Practice result: contract defeated'],
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
    'dailyStart': ['開始每日挑戰', 'Start daily challenge'],
    'dailyTitle': ['B6 每日固定四副牌', 'B6 Daily four-board challenge'],
    'dailyScope': [
      'UTC 每天固定四副原創牌；只顯示個人原始 Duplicate 分數，非 MP、IMP 或排名。使用本機示範 Bot。',
      'Four original deterministic deals each UTC day. Personal raw duplicate points only: no MP, IMP or ranking. Local Demo bot.',
    ],
    'dailyDateUtc': ['挑戰日期（UTC）', 'Challenge date (UTC)'],
    'dailyCompleted': ['已完成副數', 'Deals completed'],
    'dailyScore': ['累積原始分數（你的方向）', 'Raw score total (your side)'],
    'dailyNext': ['進入下一副每日牌', 'Next daily board'],
    'dailyCurrent': [
      '這副正在進行；結束後再進下一副。',
      'Finish the current board to advance.',
    ],
    'dailyFinished': [
      '今日四副牌已完成！這是個人練習結果，不是競賽排名。',
      'All four daily boards complete! Personal practice, not a competition ranking.',
    ],
    'dailyHistory': ['最近的每日練習紀錄（UTC）', 'Recent daily practice (UTC)'],
    'dailyRestart': ['重新練習今天四副牌', 'Retry today’s four deals'],
    'dailyRestartTitle': ['重設今天的個人練習？', 'Reset today’s practice?'],
    'dailyRestartWarning': [
      '這會重設今天四副牌的進度與累積分數，重新使用同一組牌；既有完整牌局歷史仍會保留。確定要繼續？',
      'This resets today’s progress and score using the same deals. Completed history entries remain. Continue?',
    ],
    'dailyRestartCancel': ['取消', 'Cancel'],
    'dailyRestartConfirm': ['重設練習', 'Reset practice'],
    'dailyLoadError': [
      '無法讀取每日練習紀錄；為避免覆蓋既有紀錄，暫時不會建立新的每日挑戰。',
      'Daily practice history cannot be read. New daily challenges are blocked to avoid overwriting records.',
    ],
    'dailySaveError': [
      '每日練習儲存失敗；修復儲存前不能進入下一副。',
      'Daily progress could not be saved. Retry before advancing.',
    ],
    'dailyRetrySave': ['重試儲存每日進度', 'Retry saving daily progress'],
    'practiceFourStart': ['開始四副牌練習賽', 'Start 4-board practice'],
    'practiceFourTitle': ['四副牌練習賽', 'Four-board practice'],
    'practiceFourCompleted': ['已完成副數', 'Deals completed'],
    'practiceFourHumanScore': ['練習累積分（玩家視角）', 'Practice net score (your side)'],
    'practiceFourNext': ['進入下一副練習牌', 'Next practice board'],
    'practiceFourFinished': ['四副牌練習完成！可從歷史牌局逐副複盤。', 'Four boards finished! Review each deal in History.'],
    'practiceFourCurrent': ['正在練習中；完成本副後可進入下一副。', 'Playing this board; finish it to continue.'],
    'practiceFourScope': [
      '四副不同隨機發牌，顯示原始 Duplicate 得分加總；不是 MP、IMP 或賽事排名。',
      'Four fresh deals, sum of raw duplicate scores only; not MP, IMP or a ranking.',
    ],
    'reviewNotesTitle': ['B5 教學式複盤', 'B5 Guided review'],
    'reviewStrategyUnknown': [
      '策略品質：未分析（UNKNOWN）。此頁不代表 DDS 最佳打法或 BEN 真正意圖。',
      'Strategy quality: NOT ANALYZED (UNKNOWN). No DDS best-play or BEN intent is inferred.',
    ],
    'reviewRuleTag': ['規則', 'Rule'],
    'reviewConventionTag': ['約定前提・未經專家審核', 'Teaching agreement · unreviewed'],
    'reviewUnknownTag': ['未知', 'Unknown'],
    'reviewStartRule': [
      '此為已完成牌局的初始公開狀態。回放不會修改原始牌局。',
      'This is the initial state of a completed deal; replay does not mutate it.',
    ],
    'reviewBidRule': [
      '叫品必須符合 Bridge Core 的合法性規則，叫品本身不證明叫牌者的實際牌力。',
      'A bid must satisfy Bridge Core legality; it does not verify the bidder’s actual hand strength.',
    ],
    'reviewConventionUnknown': [
      '目前沒有符合公開叫牌上下文的教學約定，不應推測暗手。',
      'No teaching agreement matches this public auction context. Hidden hands cannot be inferred.',
    ],
    'reviewPassRule': [
      'Pass 由 Bridge Core 計入叫牌進度；不是對牌力或策略品質的驗證。',
      'Bridge Core records PASS in the auction; it is not proof of strength or strategy quality.',
    ],
    'reviewPassOutRule': [
      '四家依序 Pass，牌局直接結束、沒有定約，原始南北得分為 0。',
      'Four consecutive passes end the deal with no contract and N/S score 0.',
    ],
    'reviewDoubleRule': [
      '合法加倍（X）會影響最終計分；不表示此時的叫牌有最佳策略。',
      'A legal Double (X) changes final scoring; this says nothing about strategic optimality.',
    ],
    'reviewRedoubleRule': [
      '合法再加倍（XX）會改變最終計分，不代表教學約定已匹配。',
      'A legal Redouble (XX) changes final scoring; it does not imply a matched teaching agreement.',
    ],
    'reviewContractRule': [
      '叫牌完成後由 Bridge Core 決定莊家、王牌與定約目標（6 + 線位）。',
      'After the auction Bridge Core determines declarer, strain and required tricks (6 + level).',
    ],
    'reviewNoTrumpRule': [
      '無王（NT）沒有王牌花色；牌墩勝負由正式跟牌與牌力規則決定。',
      'No Trump (NT) has no trump suit; Bridge Core determines trick winners.',
    ],
    'reviewTrumpRule': [
      '有王定約具有指定王牌花色；仍須先遵守跟牌義務。',
      'Suit contracts have a trump suit; players must still follow suit when able.',
    ],
    'reviewLeadRule': [
      '每墩第一張牌決定本墩領出花色；其後有該花色必須跟牌。',
      'The first card sets the led suit for that trick; players must follow suit when able.',
    ],
    'reviewFollowSuit': [
      '此牌與本墩領出花色相同，屬於跟牌的可見例子。',
      'This card matches the led suit and visibly follows suit.',
    ],
    'reviewOffSuitUnknown': [
      '此張不是領出花色；從公開回放不能證明當時所有未公開手牌的持牌情況。',
      'This card is off-suit; public replay cannot prove the contents of any still-hidden hand.',
    ],
    'reviewDummyReveal': [
      '開出首攻後明手正式公開；在此之前不會顯示明手牌面。',
      'Dummy becomes public after the opening lead, never before.',
    ],
    'reviewDummyControl': [
      '本次由莊家代明手選牌，出牌所有權仍屬於明手座位。',
      'Declarer selects for dummy; the card still belongs to the dummy seat.',
    ],
    'reviewTrickComplete': [
      '一墩四張牌均已完成；勝方由 Bridge Core 判定（見上方上一墩勝者）。',
      'All four cards complete a trick; Bridge Core determines its winner (shown above).',
    ],
    'reviewOfficialScore': [
      '此南北得分由 Bridge Core 在終局產生，不是複盤自行計算。',
      'This N/S score is produced by Bridge Core at the terminal result, not recalculated by review.',
    ],
    'reviewTargetTricks': ['定約至少需要的墩數', 'Tricks needed to make contract'],
    'reviewJumpTitle': ['直接跳到事件', 'Jump to event'],
    'reviewStartEvent': ['開始', 'Start'],
    'reviewAuctionEvent': ['叫牌', 'Auction'],
    'reviewPlayEvent': ['出牌', 'Play'],
    'reviewPreviousKey': ['上一個重點', 'Previous key event'],
    'reviewNextKey': ['下一個重點', 'Next key event'],
    'reviewMark': ['標記學習重點', 'Mark learning point'],
    'reviewUnmark': ['取消重點標記', 'Unmark learning point'],
    'reviewMarkedTitle': ['本頁標記的事件', 'Marked events this session'],
    'reviewBookmarksTemporary': [
      '標記只保留在目前開啟的複盤頁面，不會寫入牌局歷史。',
      'Bookmarks last only while this review panel is open; no history is changed.',
    ],
    'ddsTitle': ['雙明手分析（DDS）', 'Double-dummy analysis (DDS)'],
    'ddsRequest': ['分析完成牌局', 'Analyze completed board'],
    'ddsUnavailable': ['此環境沒有可用 DDS 引擎。', 'DDS unavailable on this runtime.'],
    'ddsLoading': ['分析中…', 'Analyzing…'],
    'ddsError': ['分析失敗，沒有產生推測資料。', 'Analysis failed; no fabricated results.'],
    'ddsNotFinished': ['必須先完成 13 墩牌局；Pass Out 不支援。', 'A full 13-trick board is required; Pass Out is unsupported.'],
    'ddsResult': ['起始 52 張之雙明手可取得墩數', 'Double-dummy tricks at initial deal'],
    'ddsCaveat': ['假設看見全部四家手牌；不是當時資訊條件下的最佳打法或逐張建議。', 'Assumes all four hands are known, not information-limited optimal play or card-by-card advice.'],
    'ddsDeclarer': ['莊家', 'Declarer'],
    'ddsSolverVersion': ['DDS 版本', 'DDS version'],
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
    'historyOpen': ['歷史牌局', 'Deal history'],
    'historyClose': ['收起歷史', 'Close history'],
    'historySearch': ["搜尋牌號、定約、分數或座位","Search board, contract, score or seat"],
    'historyFilter': ["篩選牌局","Filter deals"],
    'historyFilterAll': ["全部牌局","All deals"],
    'historyFilterContracts': ["有定約","Contract deals"],
    'historyFilterPassOut': ["四家不叫","Pass Out"],
    'historyFilterPractice': ["練習牌局","Practice deals"],
    'historyNoResults': ["沒有符合條件的牌局。","No matching deals."],
    'historyPage': ["頁數","Page"],
    'historyPagePrevious': ["上一頁","Previous page"],
    'historyPageNext': ["下一頁","Next page"],
    'historyExportTitle': ['匯出已完成牌局 PBN', 'Export completed deal PBN'],
    'historyExportWarning': [
      'PBN 含這副已完成牌局的四家完整手牌、叫牌與結果。確認後會複製到系統剪貼簿，其他應用程式可能讀取，請只分享給信任的人。',
      'PBN contains ALL FOUR HANDS, the auction and result. Confirming copies it to your system clipboard, which other apps may read. Share only with people you trust.',
    ],
    'historyExportCancel': ['取消', 'Cancel'],
    'historyExportConfirm': ['了解，複製 PBN', 'Copy PBN'],
    'historyExportSuccess': ['已複製完整牌局 PBN 到剪貼簿', 'Completed deal PBN copied to clipboard'],
    'historyExportFailure': ['無法匯出 PBN，請稍後重試。', 'Could not export PBN. Please retry.'],
    'historyImportTitle': ['匯入已完成牌局 PBN', 'Import completed PBN'],
    'historyImportWarning': [
      '僅支援已完成的一副牌局，需包含 Deal、完整 Auction 與 13 墩 Play（或四家 Pass）。匯入資料含四家手牌，只儲存於本機加密歷史，不會傳送給 BEN。',
      'Only one completed deal with Deal, full Auction and 13 tricks of Play (or four Passes) is supported. The four hands stay in encrypted local history and are never sent to BEN.',
    ],
    'historyImportHint': ['貼上完整 PBN', 'Paste complete PBN'],
    'historyImportCancel': ['取消匯入', 'Cancel import'],
    'historyImportConfirm': ['檢查並匯入', 'Validate and import'],
    'historyImportSuccess': ['牌局已匯入，可從歷史列表開啟複盤。',
      'Deal imported. Open it from history to review.'],
    'historyImportFailure': ['PBN 無效、重複，或本機儲存失敗；未新增牌局。',
      'PBN is invalid, duplicated, or could not be stored. No deal was added.'],
    'errorHistoryImport': ['PBN 無法通過橋牌規則及計分驗證，或加密歷史儲存失敗。',
      'PBN failed bridge-rule/score validation or encrypted history storage.'],
    'errorHistoryDuplicate': ['這副已完成牌局已有相同的歷史紀錄。',
      'This completed deal already exists in history.'],
    'historyDeleteTitle': ["刪除這副牌局？","Delete this deal?"],
    'historyDeleteWarning': ["此動作將永久刪除此副歷史紀錄及複盤資料，不會中斷目前的牌局，也無法復原。","This permanently deletes this saved deal and its replay. Your current game is unaffected. This cannot be undone."],
    'historyDeleteCancel': ["取消","Cancel"],
    'historyDeleteConfirm': ["確認刪除","Delete deal"],
    'errorHistoryDelete': ["無法刪除歷史牌局，請稍後重試。","Could not delete the saved deal. Please retry."],
    'historyTitle': ['已完成的牌局', 'Completed deals'],
    'historyStatsTitle': ['近期牌局統計', 'Recent deal statistics'],
    'historyStatsScope': [
      '依目前搜尋與篩選計算；僅包含本機最多 12 副已完成牌局（含練習與匯入）。不是 MP／IMP 或玩家排名。',
      'Calculated from current search and filter: up to 12 local finished deals (including practice/imports). Not MP, IMP or player ranking.',
    ],
    'historyStatsBoards': ['完成副數', 'Deals'],
    'historyStatsContracts': ['有定約', 'Contracts'],
    'historyStatsMade': ['定約成功率', 'Contracts made'],
    'historyStatsUnknown': ['尚無資料', 'No data'],
    'historyStatsPassOut': ['四家不叫', 'Pass Outs'],
    'historyStatsPractice': ['固定練習', 'Practice'],
    'historyStatsHumanScore': ['玩家視角累積分', 'Your net duplicate score'],
    'historyEmpty': ['還沒有完成的牌局，先打一副牌吧。',
      'No finished boards yet. Play a deal to start your history.'],
    'historyReplayTitle': ['歷史牌局複盤', 'Replay saved deal'],
    'historyPractice': ['固定練習', 'Practice deal'],
    'historyPassOut': ['四家不叫', 'Pass out'],
    'historyRetry': ['重新儲存歷史', 'Retry saving history'],
    'errorHistorySave': ['已完成牌局，但歷史封存失敗。可重新儲存，切勿清除本機資料。',
      'Board finished, but saving history failed. Retry without clearing local data.'],
    'errorHistoryLoad': ['無法讀取歷史牌局，先檢查本機儲存設定。',
      'Could not read deal history. Check local storage settings.'],
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
    'ux02_justDeclare': [
      '莊家單項練習（無競叫紀錄）',
      'Declarer-only practice (no auction)',
    ],
    'ux02_declarer': ['莊家', 'Declarer'],
    'ux02_tricks': ['莊家方墩數／達標墩數', 'Declarer tricks / contract target'],
    'ux02_made': ['完成定約（超額墩數）', 'Contract made (overtricks)'],
    'ux02_down': ['定約宕掉（差距墩數）', 'Contract down (trick difference)'],
    'ux02_yourScore': ['你的方向原始分數', 'Raw duplicate score for your side'],
    'ux02_rawScoreDisclaimer': [
      '由 Bridge Core 結算；非 MP、IMP 或排名。',
      'Adjudicated by Bridge Core; not MP, IMP or a ranking.',
    ],
    'ux02_noNext': ['本系列已完成', 'Series completed'],
    'ux02_review': ['複盤這副牌', 'Review this deal'],
    'ux02_history': ['查看歷史', 'View history'],
    'ux02_backToResult': ['返回本局結果', 'Back to deal result'],
    'ux02_saveBlocked': [
      '儲存、恢復或背景作業尚未完成；請先處理提示再繼續。',
      'Saving, recovery or background work is pending; resolve it before continuing.',
    ],
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

