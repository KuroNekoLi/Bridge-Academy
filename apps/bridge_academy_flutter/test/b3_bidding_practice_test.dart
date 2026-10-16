import 'package:bridge_academy_flutter/src/bidding_practice.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements SessionArchiveStore {
  String? content;
  @override
  Future<String?> read() async => content;
  @override
  Future<void> write(String archive) async { content = archive; }
  @override
  Future<void> clear() async { content = null; }
}

void main() {
  test('B3: own-hand 17 HCP balanced 1NT teaching hint', () {
    final deal = Deal.fromPbn(
      'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
      'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8');
    final view = PlayerView.forSeat(
        GameState.start(deal, Seat.north, Vulnerability.none), Seat.north);
    expect(view.toJson().containsKey('hands'), false);
    expect(BiddingPracticeProfile.hcp(view.ownCards), 17);
    expect(BiddingPracticeProfile.balanced(view.ownCards), true);
    expect(BiddingPracticeProfile.suggest(view).code, '1NT');
  });

  test('B3: unknown when opponent interferes', () {
    expect(BiddingPracticeProfile.explain([
      const AuctionEntry(Seat.north, Bid(1, Strain.notrump)),
      const AuctionEntry(Seat.east, Pass()),
      const AuctionEntry(Seat.south, Bid(2, Strain.notrump)),
    ]), 'biddingInvite2NT');
    expect(BiddingPracticeProfile.explain([
      const AuctionEntry(Seat.north, Bid(1, Strain.notrump)),
      const AuctionEntry(Seat.east, Bid(2, Strain.clubs)),
      const AuctionEntry(Seat.south, Bid(2, Strain.notrump)),
    ]), 'biddingUnknown');
  });

  test('B3: stops without lead and persists across restart', () async {
    final store = _MemoryStore();
    final session = BridgeSession(
        archiveStore: store, freshDealFactory: Deal.suitPerSeat);
    await session.startBiddingPractice();
    expect(session.mode, OpponentMode.demo);
    await session.submitCall(const Bid(1, Strain.notrump));
    // Partner may respond 3NT instead of PASS, so the human must close it.
    for (var i = 0; i < 4 && !session.biddingPracticeComplete; i++) {
      expect(session.view!.canAct, true);
      await session.submitCall(const Pass());
    }
    expect(session.biddingPracticeComplete, true);
    expect(session.view!.phase, Phase.play);
    expect(session.view!.completedTricks, isEmpty);
    final version = session.view!.version;
    if (session.view!.legalCards.isNotEmpty) {
      await session.submitCard(session.view!.legalCards.first);
    }
    expect(session.view!.version, version);
    session.dispose();

    final resumed = BridgeSession(
        archiveStore: store, freshDealFactory: Deal.suitPerSeat);
    addTearDown(resumed.dispose);
    expect(await resumed.restoreSavedGame(), true);
    expect(resumed.isBiddingPractice, true);
    expect(resumed.biddingPracticeComplete, true);
    await resumed.startBiddingPractice();
    expect(resumed.view!.phase, Phase.auction);
  });

  testWidgets('B3: player can launch and see both localizations', (tester) async {
    final session = BridgeSession(freshDealFactory: Deal.suitPerSeat);
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    final button = find.byKey(const Key('start_bidding_practice'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bidding_practice_panel')), findsOneWidget);
    await session.submitCall(const Bid(1, Strain.notrump));
    for (var i = 0; i < 4 && !session.biddingPracticeComplete; i++) {
      await session.submitCall(const Pass());
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bidding_finished')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Auction complete.'), findsOneWidget);
  });
}
