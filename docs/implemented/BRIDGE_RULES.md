# Bridge Rules Baseline v0.1 — normative engineering invariants

Intended game: four-player contract bridge, initially Duplicate scoring. Consult current WBF Laws of Duplicate Bridge before claiming sanctioned-tournament compliance; this document is an implementation checklist, not a replacement for the Laws.

## Auction
- Each seat has 13 unique cards; dealer acts first, then clockwise N→E→S→W→N (with correct seat ordering).
- Legal contract strain ranking: clubs < diamonds < hearts < spades < notrump; higher contract must increase level or, at same level, strain.
- Pass always permitted before termination. Double permitted only against opponents' currently highest undoubled contract while auction live; Redouble only by side whose contract was doubled.
- If no contract has been bid, the auction ends after **four actual consecutive passes**. If a contract has been bid, auction ends after **three consecutive passes** following the last bid/double/redouble; those calls reset the pass count.
- Final contract is highest legal bid plus X/XX status; declarer is first player on the winning partnership who named the final strain; dummy = partner of declarer; opening lead = declarer's left-hand opponent.
- A raw AI "PASS OUT" outcome with only three displayed PASS calls is not a complete auction event history. Treat contract result as provisionally valid with a warning; do not invent missing decision.

## Play
- Opening leader leads first. Dummy is exposed after opening lead per rules.
- Each trick contains four turns following winner-led clockwise order.
- Following the lead suit is mandatory if a player holds that suit, otherwise may play any card.
- Winner: highest trump played; if none, highest of led suit. All cards played exactly once; 13 complete tricks must equal 52 played cards.
- Only controlling legal player/actor can choose a dummy card as allowed; log physical hand owner separately from selecting actor.

## Duplicate scoring, signed NS perspective
- Contract target = level + 6; made/down logic uses declarer's tricks.
- Undoubled contract trick values: minor 20, major 30, NT 40 first then 30. Doubled x2, redoubled x4.
- Overtricks undoubled per strain trick rate; doubled overtrick 100 nonvul / 200 vul; redoubled twice doubled bonus.
- Partscore bonus 50 or game bonus 300 nonvul / 500 vul, based on contract trick score ≥100; insult 50 X /100 XX; small slam 500/750; grand slam 1000/1500 nonvul/vul.
- Undertricks undoubled 50 nonvul /100 vul each. Doubled nonvul: first 100, second/third 200 each, fourth+ 300 each. Doubled vul: first 200, subsequent 300 each. Redoubled penalties doubled.
- PASS OUT score 0 with no play.
- Explicit test fixtures for E/W declarer scored with reversed NS sign and 3NT one down nonvul = NS +50.

## Replay and edge cases
- Immutable state; reject invalid actions without mutation or appending a valid-action event.
- Regression fixtures: 4-Pass, 3-Pass incomplete transcript warning, contract-after-3-Pass, X/XX, all 5 strains, vulnerability, trick follow suit, void, trump, all-seats and score symmetry.
- Claim/concession and tournament irregularities are OUT OF SCOPE for M1 until separately specified.

