import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/review/review_timeline.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedReplay _terminalReplay(
    List<Call> auction, {Strain strain = Strain.notrump}) {
  var game = GameState.start(
      Deal.suitPerSeat(), Seat.north, Vulnerability.none);
  final frames = <ReplayFrame>[
    ReplayFrame(PlayerView.forSeat(game, Seat.north), null),
  ];
  for (final call in auction) {
    game = BridgeGame.apply(game, CallAction(game.turn!, call));
    frames.add(ReplayFrame(PlayerView.forSeat(game, Seat.north),
        game.events.last.action));
  }
  while (!game.isFinished) {
    final seat = game.turn!;
    final card = game.legalCards(seat).first;
    final action = CardAction(game.actorToPlay!, seat, card);
    game = BridgeGame.apply(game, action);
    frames.add(ReplayFrame(PlayerView.forSeat(game, Seat.north), action));
  }
  return CompletedReplay(frames, game.historyFingerprint);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  const passes = [Pass(), Pass(), Pass(), Pass()];

  test('B5 Pass Out timeline has original versions, score and no private PBN', () {
    final replay = _terminalReplay(passes);
    final timeline = ReviewTimeline.fromReplay(replay);
    expect(timeline.steps.length, replay.frames.length);
    expect(timeline.lastIndex, 4);
    expect(timeline.steps.first.frame.view.dummyCards, isNull);
    expect(timeline.steps.last.insights.map((n) => n.key),
        containsAll(['reviewPassOutRule', 'reviewOfficialScore']));
    expect(timeline.steps.last.frame.view.nsScore, 0);
    expect(timeline.nextKeyAfter(0), 4);
    expect(timeline.previousKeyBefore(4), 0);
    for (final step in timeline.steps) {
      expect(step.frame.view.version, step.index);
      expect(step.frame.view.toJson().containsKey('hands'), false);
    }
    expect(timeline.historyFingerprint, replay.historyFingerprint);
  });

  test('B5 contract explanations include doubled / redoubled without strategy claims', () {
    final doubled = ReviewTimeline.fromReplay(_terminalReplay(const [
      Bid(1, Strain.hearts), DoubleCall(), Pass(), Pass(), Pass(),
    ]));
    expect(doubled.steps[2].insights.map((i) => i.key),
        containsAll(['reviewDoubleRule', 'reviewConventionUnknown']));
    expect(doubled.steps.last.frame.view.contract!.doubling,
        Doubling.doubled);
    expect(doubled.steps.last.insights.map((i) => i.key),
        contains('reviewOfficialScore'));

    final redoubled = ReviewTimeline.fromReplay(_terminalReplay(const [
      Bid(1, Strain.hearts), DoubleCall(), RedoubleCall(),
      Pass(), Pass(), Pass(),
    ]));
    expect(redoubled.steps[3].insights.map((i) => i.key),
        contains('reviewRedoubleRule'));
    expect(redoubled.steps.last.frame.view.contract!.doubling,
        Doubling.redoubled);
  });

  test('B5 NT/trump, opening dummy exposure, dummy actor and follow-suit', () {
    for (final strain in [Strain.notrump, Strain.spades]) {
      final replay = _terminalReplay([
        Bid(1, strain), const Pass(), const Pass(), const Pass(),
      ]);
      final timeline = ReviewTimeline.fromReplay(replay);
      expect(timeline.steps[4].insights.map((i) => i.key),
          contains(strain == Strain.notrump
              ? 'reviewNoTrumpRule' : 'reviewTrumpRule'));
      final leadStep = timeline.steps[5];
      expect(leadStep.insights.map((i) => i.key),
          containsAll(['reviewLeadRule', 'reviewDummyReveal']));
      expect(timeline.steps[4].frame.view.dummyCards, isNull);
      expect(leadStep.frame.view.dummyExposed, true);
      expect(leadStep.frame.view.dummyCards, isNotNull);
      expect(timeline.steps
          .any((step) => step.insights
              .any((note) => note.key == 'reviewDummyControl')), isTrue);
      expect(timeline.steps
          .any((step) => step.insights
              .any((note) => note.key == 'reviewFollowSuit')), isTrue);
      expect(timeline.steps.last.frame.view.completedTricks.length, 13);
      expect(timeline.steps.last.frame.view.nsScore, isNotNull);
    }
  });

  test('B5 timeline rejects unfinished or misordered replay', () {
    final game = GameState.start(
        Deal.suitPerSeat(), Seat.north, Vulnerability.none);
    final initial = ReplayFrame(PlayerView.forSeat(game, Seat.north), null);
    expect(() => ReviewTimeline.fromReplay(
        CompletedReplay([initial], 'not-finished')), throwsFormatException);
    final terminal = _terminalReplay(passes);
    expect(() => ReviewTimeline.fromReplay(CompletedReplay([
        terminal.frames.first, terminal.frames.last,
      ], terminal.historyFingerprint)), throwsFormatException);
  });

  testWidgets('B5 live gameplay has no review, terminal has jump/bookmarks',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('review_timeline_controls')), findsNothing);
    await _tap(tester, 'new_game');
    expect(find.byKey(const Key('review_timeline_controls')), findsNothing);
    await _tap(tester, 'pass');
    expect(find.byKey(const Key('review_timeline_controls')), findsOneWidget);
    expect(find.byKey(const Key('review_strategy_unknown')), findsOneWidget);
    expect(find.byKey(const Key('review_jump')), findsOneWidget);
    await _tap(tester, 'review_bookmark_toggle');
    expect(find.byKey(const Key('review_bookmark_4')), findsOneWidget);
    await _tap(tester, 'review_prev_key');
    expect(find.text('事件步驟: 0 / 4'), findsOneWidget);
    await _tap(tester, 'review_bookmark_4');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await _tap(tester, 'toggle_locale');
    expect(find.textContaining('Strategy quality:'), findsOneWidget);
    await _tap(tester, 'new_game');
    expect(find.byKey(const Key('review_timeline_controls')), findsNothing);
  });

  testWidgets('B5 old history uses the same filtered timeline and no private hands',
      (tester) async {
    final store = MemoryCompletedHistoryStore();
    final session = BridgeSession(historyStore: store);
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await _tap(tester, 'new_game');
    await _tap(tester, 'pass');
    await _tap(tester, 'next_board');
    await _tap(tester, 'history_toggle');
    final id = session.completedHistory.single.id;
    await _tap(tester, 'history_item_$id');
    expect(find.byKey(const Key('review_timeline_controls')), findsOneWidget);
    expect(find.text('事件步驟: 0 / 4'), findsOneWidget);
    expect(session.historyReplay(id)!.frames.first.view.dummyCards, isNull);
    await _tap(tester, 'review_next_key');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
  });

  testWidgets('B5 320px large text does not horizontally overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: BridgeAcademyApp(session: session),
    ));
    await _tap(tester, 'new_game');
    await _tap(tester, 'pass');
    expect(find.byKey(const Key('review_jump')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
