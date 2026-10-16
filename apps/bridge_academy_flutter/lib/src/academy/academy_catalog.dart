import 'academy_models.dart';
import 'academy_advanced_catalog.dart';

/// Original, copyright-clean beginner questions. No active game hand, online
/// convention claim, external question bank or player data is accessed.
abstract final class AcademyCatalog {
  static final List<AcademyLesson> lessons = [
    AcademyLesson(
      lessonId: 'b4.cards-and-seats',
      schemaVersion: 1,
      skillTag: 'table_basics',
      title: AcademyText('認識牌桌與四個座位', 'Cards and the four seats'),
      summary: AcademyText('一副牌有幾張？誰是你的搭檔？',
          'How many cards are dealt, and who is your partner?'),
      introduction: AcademyText(
        '標準橋牌用 52 張牌，平均發給北、東、南、西四位玩家。'
        '每人 13 張；北南是一隊，東西是另一隊。',
        'Duplicate bridge deals 52 distinct cards to North, East, South '
        'and West. Each gets 13 cards; N–S and E–W are partnerships.',
      ),
      questions: [
        AcademyQuestion(
          questionId: 'b4.cards.count',
          skillTag: 'table_basics',
          prompt: AcademyText('一副標準橋牌共有幾張牌？',
              'How many cards are in a standard bridge deck?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('48 張', '48')),
            AcademyOption(optionId: 'b', label: AcademyText('52 張', '52')),
            AcademyOption(optionId: 'c', label: AcademyText('54 張', '54')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('正確！四種花色各 13 張，總共 52 張。',
                'Correct! Four suits with 13 cards each makes 52.'),
            incorrect: AcademyText('橋牌不使用鬼牌；每個花色 A 到 2 共 13 張，四個花色共 52 張。',
                'Bridge uses no jokers: 13 ranks in each of four suits = 52.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Deal',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.cards.hand-size',
          skillTag: 'table_basics',
          prompt: AcademyText('發完 52 張牌後，每位玩家手上有幾張？',
              'How many cards does each player start with?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('12 張', '12')),
            AcademyOption(optionId: 'b', label: AcademyText('13 張', '13')),
            AcademyOption(optionId: 'c', label: AcademyText('14 張', '14')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('答對了！52 ÷ 4 = 13。',
                'Exactly! 52 ÷ 4 = 13.'),
            incorrect: AcademyText('牌要平均發給四家，所以每個座位應持有 13 張不重複的牌。',
                'Each of the four seats receives exactly 13 unique cards.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Deal',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.cards.north-partner',
          skillTag: 'table_basics',
          prompt: AcademyText('你坐在北家（North），哪一家是你的搭檔？',
              'You sit North. Who is your partner?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('東家', 'East')),
            AcademyOption(optionId: 'b', label: AcademyText('西家', 'West')),
            AcademyOption(optionId: 'c', label: AcademyText('南家', 'South')),
          ],
          correctOptionId: 'c',
          explanation: AcademyExplanation(
            correct: AcademyText('沒錯，南北是同一個搭檔組合。',
                'Yes! North and South form one partnership.'),
            incorrect: AcademyText('對家才是搭檔：北對南、東對西。',
                'Your partner is opposite you: North–South or East–West.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Deal / Seat',
          ),
        ),
      ],
    ),
    AcademyLesson(
      lessonId: 'b4.hcp-intro',
      schemaVersion: 1,
      skillTag: 'high_card_points',
      title: AcademyText('HCP 牌力入門', 'High-card points (HCP)'),
      summary: AcademyText('用 A、K、Q、J 估算大牌點數。',
          'Count the strength of aces, kings, queens and jacks.'),
      introduction: AcademyText(
        'HCP 是常見的教學估算：A=4、K=3、Q=2、J=1，其他牌為 0。'
        '這是一種牌力估算，並非完整的叫牌策略。',
        'The common teaching shorthand is Ace=4, King=3, Queen=2 '
        'and Jack=1; all other cards count 0. HCP alone is not a bidding system.',
      ),
      questions: [
        AcademyQuestion(
          questionId: 'b4.hcp.ace',
          skillTag: 'high_card_points',
          prompt: AcademyText('在 HCP 算法中，一張 A 值幾點？',
              'How many high-card points is an ace worth?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('3 點', '3 points')),
            AcademyOption(optionId: 'b', label: AcademyText('4 點', '4 points')),
            AcademyOption(optionId: 'c', label: AcademyText('5 點', '5 points')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('正確！一張 A 是 4 HCP。',
                'Correct! One ace is 4 HCP.'),
            incorrect: AcademyText('依本課 HCP 教學定義：A=4、K=3、Q=2、J=1。',
                'In this teaching model A=4, K=3, Q=2, J=1.'),
            ruleReference: 'B4 lesson definition — standard HCP teaching model',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.hcp.king-queen',
          skillTag: 'high_card_points',
          prompt: AcademyText('手上有一張 K 與一張 Q，合計幾 HCP？',
              'A king plus a queen: how many HCP?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('4 點', '4 points')),
            AcademyOption(optionId: 'b', label: AcademyText('5 點', '5 points')),
            AcademyOption(optionId: 'c', label: AcademyText('6 點', '6 points')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('答對了！K 3 點 + Q 2 點 = 5 點。',
                'Right! King 3 + queen 2 = 5 HCP.'),
            incorrect: AcademyText('分別計算：K=3、Q=2，相加等於 5。',
                'Count them separately: king 3 plus queen 2 is 5.'),
            ruleReference: 'B4 lesson definition — standard HCP teaching model',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.hcp.all-honors',
          skillTag: 'high_card_points',
          prompt: AcademyText('A、K、Q、J 各一張，總共有幾 HCP？',
              'One each of A, K, Q and J totals how many HCP?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('9 點', '9 points')),
            AcademyOption(optionId: 'b', label: AcademyText('10 點', '10 points')),
            AcademyOption(optionId: 'c', label: AcademyText('11 點', '11 points')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('正確！4 + 3 + 2 + 1 = 10。',
                'Correct! 4 + 3 + 2 + 1 = 10.'),
            incorrect: AcademyText('依序把 A、K、Q、J 的 4、3、2、1 點加起來。',
                'Add the values of A, K, Q and J: 4, 3, 2 and 1.'),
            ruleReference: 'B4 lesson definition — standard HCP teaching model',
          ),
        ),
      ],
    ),
    AcademyLesson(
      lessonId: 'b4.play-and-contract',
      schemaVersion: 1,
      skillTag: 'play_rules',
      title: AcademyText('跟牌、Pass Out 與定約', 'Following suit and contracts'),
      summary: AcademyText('認識打牌義務、四家 Pass 與贏墩目標。',
          'Learn follow-suit, passed-out auctions and trick targets.'),
      introduction: AcademyText(
        '有人領牌時，如果手上有相同花色，必須跟出該花色。'
        '四家都在初始叫牌中 Pass 就是 Pass Out。'
        '定約需要的總墩數等於線位加 6。',
        'You must follow the led suit if you have that suit. Four initial '
        'passes produce a passed-out board. Contract target = level + 6 tricks.',
      ),
      questions: [
        AcademyQuestion(
          questionId: 'b4.play.follow-suit',
          skillTag: 'play_rules',
          prompt: AcademyText('東家領出 ♥，你手上有 ♥。你應該怎麼做？',
              'East leads a heart. You hold a heart. What must you do?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('跟出一張紅心 ♥',
                'Play a heart')),
            AcademyOption(optionId: 'b', label: AcademyText('任選一張黑桃 ♠',
                'Play any spade')),
            AcademyOption(optionId: 'c', label: AcademyText('先打王牌就可以',
                'Play a trump instead')),
          ],
          correctOptionId: 'a',
          explanation: AcademyExplanation(
            correct: AcademyText('正確！有領出花色就必須跟牌。',
                'Correct! If you can follow suit, you must.'),
            incorrect: AcademyText('除非沒有紅心，否則不能改出其他花色，甚至王牌。',
                'You may play another suit or trump only when void in hearts.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Play',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.play.pass-out',
          skillTag: 'play_rules',
          prompt: AcademyText('沒有任何開叫、四家依序都 Pass，結果為何？',
              'With no bid, all four players pass. What is the result?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('Pass Out，沒有出牌',
                'Pass Out; no play')),
            AcademyOption(optionId: 'b', label: AcademyText('直接 1NT 定約',
                'Automatic 1NT contract')),
            AcademyOption(optionId: 'c', label: AcademyText('由發牌者選王牌',
                'Dealer chooses trumps')),
          ],
          correctOptionId: 'a',
          explanation: AcademyExplanation(
            correct: AcademyText('正確！完整四次 Pass 才能證明 Pass Out。',
                'Correct! Four actual initial passes establish Pass Out.'),
            incorrect: AcademyText('四家初始都 Pass 則無定約、不打牌且得分為 0。'
                '如果只記錄三次 Pass，不可以捏造第四次。',
                'Four initial passes mean no contract, no card play and a '
                'zero score. Never fabricate a missing fourth call.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Auction / Scoring',
          ),
        ),
        AcademyQuestion(
          questionId: 'b4.play.four-spades',
          skillTag: 'play_rules',
          prompt: AcademyText('4♠ 定約至少需要贏幾墩才能完成？',
              'How many tricks must declarer win to make 4 spades?'),
          options: [
            AcademyOption(optionId: 'a', label: AcademyText('9 墩', '9 tricks')),
            AcademyOption(optionId: 'b', label: AcademyText('10 墩', '10 tricks')),
            AcademyOption(optionId: 'c', label: AcademyText('11 墩', '11 tricks')),
          ],
          correctOptionId: 'b',
          explanation: AcademyExplanation(
            correct: AcademyText('沒錯，4 線位 + 6 = 10 墩。',
                'Yes! Level 4 + 6 = 10 tricks.'),
            incorrect: AcademyText('橋牌定約線位以 6 墩為基數，4♠ 至少要贏 10 墩。',
                'The contract target is six plus the level: 4 + 6 = 10.'),
            ruleReference: 'docs/BRIDGE_RULES_BASELINE.md — Scoring',
          ),
        ),
      ],
    ),
    ...AcademyAdvancedCatalog.lessons,
  ];

  static List<AcademyLesson> validated() {
    AcademyValidator.validate(lessons);
    return lessons;
  }
}
