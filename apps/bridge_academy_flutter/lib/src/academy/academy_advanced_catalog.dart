import 'academy_models.dart';

/// B4.2 copyright-clean intermediate content. Fixed hypothetical examples only.
/// No live Deal/PlayerView or AI strategy is accessed; conventions are UNREVIEWED.
abstract final class AcademyAdvancedCatalog {
  static AcademyQuestion _question({
    required String id,
    required String tag,
    required AcademyText prompt,
    required List<String> zhOptions,
    required List<String> enOptions,
    required int correctIndex,
    required AcademyText correct,
    required AcademyText incorrect,
    required String reference,
  }) {
    if (zhOptions.length != 3 || enOptions.length != 3 ||
        correctIndex < 0 || correctIndex >= 3) {
      throw const FormatException('Expected three localized options');
    }
    const ids = ['a', 'b', 'c'];
    return AcademyQuestion(
      questionId: id, skillTag: tag, prompt: prompt,
      options: List.unmodifiable([
        for (var i = 0; i < 3; i++)
          AcademyOption(optionId: ids[i],
            label: AcademyText(zhOptions[i], enOptions[i])),
      ]),
      correctOptionId: ids[correctIndex],
      explanation: AcademyExplanation(
        correct: correct, incorrect: incorrect, ruleReference: reference),
    );
  }

  static List<AcademyLesson> get lessons => _lessons;
  static final List<AcademyLesson> _lessons = List.unmodifiable([
    AcademyLesson(
      lessonId: "b4.advanced-defense", schemaVersion: 1,
      skillTag: "defense_rules",
      title: AcademyText("防守：跟牌、王牌與明手", "Defense: following suit, trumps and dummy"),
      summary: AcademyText("辨認合法防守動作，避免以牌點大小代替跟牌規則。", "Apply the follow-suit rule and understand how trumps win tricks."),
      introduction: AcademyText("本單元以明確指定的領出花色與王牌為前提。跟牌義務是規則，王牌打法依情境而定；以下都是獨立教學牌例，不來自正在進行的私有牌局。", "Every example explicitly states the led suit and trump suit. Following suit is mandatory; choosing to ruff when void is optional. These are independent teaching examples, not live hidden hands."),
      questions: List.unmodifiable([
        _question(
          id: "b4.2.follow-led-suit", tag: "defense_rules",
          prompt: AcademyText("有人領出 ♣，定約是 ♥ 王牌。你手中還有 ♣K 和 ♥A，這一墩依法必須怎麼打？", "Clubs are led, hearts are trumps. You hold ♣K and ♥A. What must you play?"),
          zhOptions: ["打出 ♣K，遵守跟牌", "打出 ♥A，因為是王牌", "任選一張，不須跟牌"],
          enOptions: ["Play ♣K to follow suit", "Play ♥A because it is trump", "Play either card; no need to follow"],
          correctIndex: 0,
          correct: AcademyText("有領出花色就必須跟牌，無論手上有多大的王牌。", "You must follow the led suit when able, even if you hold the ace of trumps."),
          incorrect: AcademyText("持有 ♣ 時不能改打 ♥A。", "Holding a club makes playing ♥A illegal on this trick."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Play",
        ),
        _question(
          id: "b4.2.void-in-led-suit", tag: "defense_rules",
          prompt: AcademyText("♠ 被領出，你手上沒有 ♠，而定約以 ♥ 為王牌。以下哪項符合跟牌規則？", "Spades are led. You have no spades and hearts are trumps. Which action is legal?"),
          zhOptions: ["一定要出 ♥ 王牌", "可以出 ♥ 王牌，也可以墊其他花色", "一定要出最大的牌"],
          enOptions: ["You must ruff with a heart", "You may ruff with a heart or discard another suit", "You must play your highest card"],
          correctIndex: 1,
          correct: AcademyText("缺門時可以出任一合法持有的牌；是否王牌取決於打法選擇。", "When void in the led suit, you may choose any card you hold, including a trump."),
          incorrect: AcademyText("缺門並不強迫你用王牌，也沒有必須打最大牌的規定。", "Being void does not force a ruff or your highest card."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Play",
        ),
        _question(
          id: "b4.2.trump-beats-ace", tag: "defense_rules",
          prompt: AcademyText("♥ 是王牌，這一墩領出 ♠A，另外三張是 ♥2、♠3、♠5。誰贏這墩？", "Hearts are trumps. The trick contains ♠A (led), ♥2, ♠3 and ♠5. Which card wins?"),
          zhOptions: ["♠A，因為 A 最大", "♥2，因為有王牌就勝過非王牌", "♠5，因為最後打"],
          enOptions: ["♠A because aces are highest", "♥2 because any trump beats non-trumps", "♠5 because it is played last"],
          correctIndex: 1,
          correct: AcademyText("只要該墩出現王牌，最高王牌贏墩；此例唯一王牌是 ♥2。", "The highest trump wins whenever a trump is played; ♥2 is the only trump here."),
          incorrect: AcademyText("王牌規則優先於領出花色的大牌比較。", "Trump precedence outweighs the ace of the led suit."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Play",
        ),
        _question(
          id: "b4.2.dummy-timing", tag: "defense_rules",
          prompt: AcademyText("一般合約橋牌在什麼時候攤開明手（Dummy）？", "In standard contract bridge, when does dummy's hand become exposed?"),
          zhOptions: ["第一張首攻已領出後", "四家還沒開始叫牌前", "打完第 13 墩後"],
          enOptions: ["After the opening lead is made", "Before anyone starts bidding", "After the thirteenth trick"],
          correctIndex: 0,
          correct: AcademyText("防家首攻領出後，明手才攤開；不是事先公開所有手牌。", "Dummy is exposed after the opening lead, not before the auction."),
          incorrect: AcademyText("若提前攤開，會破壞正常牌局的資訊界線。", "Showing dummy beforehand violates normal play's information boundary."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Play",
        ),
      ]),
    ),
    AcademyLesson(
      lessonId: "b4.advanced-declarer", schemaVersion: 1,
      skillTag: "contract_planning",
      title: AcademyText("莊家：定約目標與計分規劃", "Declarer: contract targets and scoring"),
      summary: AcademyText("以固定、完整的情境判斷要拿幾墩與可能得分。", "Calculate contract targets and outcomes from complete scenarios."),
      introduction: AcademyText("這裡的「規劃」是以合約線位與已確定的贏墩數推算目標；不聲稱知道尚未打出的最佳路線。計分採 Duplicate Score，視角依 NS 正負號。", "Here planning means calculating contract targets from explicit facts—not predicting a best line of play. Duplicate scores are signed from the N–S perspective."),
      questions: List.unmodifiable([
        _question(
          id: "b4.2.nt-target", tag: "contract_planning",
          prompt: AcademyText("北家主打 3NT，至少要拿幾墩才算完成定約？", "North declares 3NT. How many tricks must declarer win to make the contract?"),
          zhOptions: ["8 墩", "9 墩", "10 墩"],
          enOptions: ["8 tricks", "9 tricks", "10 tricks"],
          correctIndex: 1,
          correct: AcademyText("線位 3 + 6 = 9 墩，與是否無王無關。", "A level-three contract requires 3 + 6 = 9 tricks."),
          incorrect: AcademyText("完成任何定約的基本墩數都是線位加 6。", "All contract trick targets equal their level plus six."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Duplicate scoring",
        ),
        _question(
          id: "b4.2.four-hearts-one-down", tag: "contract_planning",
          prompt: AcademyText("南家主打 4♥，實際拿到 9 墩。結果如何？", "South declares 4♥ and wins exactly nine tricks. What is the outcome?"),
          zhOptions: ["剛好完成", "宕一（down one）", "超一（overtrick）"],
          enOptions: ["Contract made exactly", "Down one", "One overtrick"],
          correctIndex: 1,
          correct: AcademyText("4 線位需要 10 墩，只有 9 墩就宕一。", "A four-level contract needs ten tricks; nine means one undertrick."),
          incorrect: AcademyText("9 墩不足以完成 4♥ 的 10 墩目標。", "Nine tricks are one short of 4♥'s ten-trick target."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Duplicate scoring",
        ),
        _question(
          id: "b4.2.nt-nonvul-game-score", tag: "contract_planning",
          prompt: AcademyText("北家主打無局、未加倍 3NT，剛好完成 9 墩。NS 合約總得分是多少？", "North declares non-vulnerable undoubled 3NT and makes exactly nine tricks. What is the N–S score?"),
          zhOptions: ["+150", "+400", "+600"],
          enOptions: ["+150", "+400", "+600"],
          correctIndex: 1,
          correct: AcademyText("3NT 定約墩分為 40+30+30=100，再加無局成局獎勵 300，NS 得 +400。", "3NT contract points are 40+30+30=100; add the non-vulnerable game bonus of 300: N–S +400."),
          incorrect: AcademyText("不能只算 100 墩分而忽略成局獎勵。", "Do not omit the game bonus when contract points reach 100."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Duplicate scoring",
        ),
        _question(
          id: "b4.2.ew-score-sign", tag: "contract_planning",
          prompt: AcademyText("東家主打無局、未加倍 3NT，剛好拿 9 墩。以 NS 視角記分是多少？", "East declares non-vulnerable undoubled 3NT and makes nine tricks. What is the score from N–S perspective?"),
          zhOptions: ["-400", "+400", "0"],
          enOptions: ["-400", "+400", "0"],
          correctIndex: 0,
          correct: AcademyText("同樣是東西方 +400，從南北視角是 -400。", "E–W earns 400, which is recorded as N–S −400."),
          incorrect: AcademyText("DuplicateScore.score() 固定使用 NS 正負號。", "DuplicateScore.score() is always signed from the N–S viewpoint."),
          reference: "docs/BRIDGE_RULES_BASELINE.md — Duplicate scoring",
        ),
      ]),
    ),
    AcademyLesson(
      lessonId: "b4.advanced-agreements", schemaVersion: 1,
      skillTag: "convention_literacy",
      title: AcademyText("叫牌約定：看懂上下文與限制", "Bidding agreements: context and limitations"),
      summary: AcademyText("學習 1NT 約定、Stayman/Jacoby 預覽及不明序列的界線。", "Interpret natural-NT and preview conventions without overstating certainty."),
      introduction: AcademyText("以下僅描述 BA-NATURAL-NT v1/v2 教學約定。Stayman 與 Jacoby 為「未經外部專家審核」的 v2 預覽，並非 BEN 或任意搭檔必定遵循的系統。前提是無對手干擾。", "These questions describe only the BA-NATURAL-NT v1/v2 teaching profile. Stayman and Jacoby are unreviewed v2 previews, not proof of BEN or any partnership's system. Examples assume no interference unless stated."),
      questions: List.unmodifiable([
        _question(
          id: "b4.2.nt-not-verified", tag: "convention_literacy",
          prompt: AcademyText("在 BA-NATURAL-NT v1 中，看到 1NT 開叫，就能證明叫牌者真的有 15–17 HCP 嗎？", "In BA-NATURAL-NT v1, does a 1NT opening prove the bidder actually holds 15–17 HCP?"),
          zhOptions: ["可以，約定等同於手牌證據", "不行，約定意義不等於實際手牌已驗證", "只要是 BEN 就一定正確"],
          enOptions: ["Yes, an agreement proves the cards", "No, agreed meaning is not verified card evidence", "Yes, BEN guarantees it"],
          correctIndex: 1,
          correct: AcademyText("1NT 的 15–17 HCP 是此教學檔案中的約定，不是暗手的實際驗證。", "The 15–17 HCP meaning is an agreement, not evidence of unseen cards."),
          incorrect: AcademyText("不可由公開叫品反推出真正牌力或 AI 內部決策。", "Never treat public calls as verification of hidden strength or private model reasoning."),
          reference: "apps/bridge_academy_flutter/lib/src/conventions/convention_profile.dart — NAT-1NT-OPEN",
        ),
        _question(
          id: "b4.2.stayman-context", tag: "convention_literacy",
          prompt: AcademyText("BA-NATURAL-NT v2 預覽中，北家 1NT、東家 Pass、南家 2♣，該約定通常稱為什麼？", "In BA-NATURAL-NT v2 preview, North bids 1NT, East passes, South bids 2♣. What is this agreement called?"),
          zhOptions: ["Stayman（詢問四張高花）", "Jacoby Transfer（轉向紅心）", "Double（加倍）"],
          enOptions: ["Stayman (asks about four-card majors)", "Jacoby transfer to hearts", "Double"],
          correctIndex: 0,
          correct: AcademyText("此特定無競叫路徑在 v2 預覽中標記為 Stayman，且狀態仍是 UNREVIEWED。", "This uncontested sequence is marked as Stayman in the v2 preview and remains UNREVIEWED."),
          incorrect: AcademyText("如果換成受干擾的競叫，不能套用此無競叫規則。", "Interference invalidates this simple uncontested rule."),
          reference: "apps/bridge_academy_flutter/lib/src/conventions/convention_profile.dart — PREVIEW-STAYMAN-2C (UNREVIEWED)",
        ),
        _question(
          id: "b4.2.jacoby-hearts", tag: "convention_literacy",
          prompt: AcademyText("BA-NATURAL-NT v2 預覽中，北家 1NT、東家 Pass、南家 2♦ 是哪個轉換約定？", "In BA-NATURAL-NT v2 preview, North bids 1NT, East passes, South bids 2♦. Which transfer does this represent?"),
          zhOptions: ["Jacoby：轉向黑桃 ♠", "Jacoby：轉向紅心 ♥", "自然 2♦ 競叫"],
          enOptions: ["Jacoby transfer to spades", "Jacoby transfer to hearts", "Natural competitive 2♦"],
          correctIndex: 1,
          correct: AcademyText("v2 預覽的 2♦ 轉換到 ♥；不能推斷實際搭檔或 BEN 一定使用。", "The v2 preview maps 2♦ to a heart transfer; it does not bind BEN or actual partners."),
          incorrect: AcademyText("此處只描述未核准的約定語義，非最佳叫品。", "This is an unapproved convention meaning, not optimal bidding advice."),
          reference: "apps/bridge_academy_flutter/lib/src/conventions/convention_profile.dart — PREVIEW-JACOBY-2D (UNREVIEWED)",
        ),
        _question(
          id: "b4.2.opponent-interference", tag: "convention_literacy",
          prompt: AcademyText("北家 1NT，東家插叫 2♦，南家再叫 3♣。依現有簡化的約定解釋器，應顯示什麼？", "North opens 1NT, East overcalls 2♦, South bids 3♣. What should the current teaching matcher display?"),
          zhOptions: ["確定是 Stayman", "確定是 Jacoby Transfer", "UNKNOWN：不把競叫當作無競叫約定"],
          enOptions: ["Certainly Stayman", "Certainly Jacoby transfer", "UNKNOWN: do not apply uncontested agreements"],
          correctIndex: 2,
          correct: AcademyText("現有匹配器遇到敵方插叫時保守回 UNKNOWN，而非任意推測。", "The existing matcher fails closed on opponent interference: UNKNOWN."),
          incorrect: AcademyText("即使 3♣ 合法，也不表示其約定意義已知。", "A legal 3♣ bid does not imply a known convention meaning."),
          reference: "apps/bridge_academy_flutter/lib/src/conventions/convention_profile.dart — ConventionExplanationEngine.resolve",
        ),
      ]),
    ),
  ]);
}
