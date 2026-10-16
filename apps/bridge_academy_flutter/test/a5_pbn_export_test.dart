import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _passOut(BridgeSession session) async {
  await session.newGame();
  await session.submitCall(const Pass());
  expect(session.finished, isTrue);
}

void main() {
  test('A5.3 PBN exports only completed stored deal, round-trips four hands',
      () async {
    final store = MemoryCompletedHistoryStore();
    final session = BridgeSession(historyStore: store);
    addTearDown(session.dispose);
    expect(session.exportHistoryPbn('missing_id'), isNull);
    await session.newGame();
    expect(session.exportHistoryPbn('missing_id'), isNull);
    await session.submitCall(const Pass());
    final id = session.completedHistory.single.id;
    final pbn = session.exportHistoryPbn(id)!;
    expect(pbn, contains('[Board "1"]'));
    expect(pbn, contains('[Dealer "N"]'));
    expect(pbn, contains('[Vulnerable "None"]'));
    expect(pbn, contains('[Contract "Pass"]'));
    expect(pbn, contains('[Score "NS +0"]'));
    expect(pbn, contains('[Auction "N"]\nPass Pass Pass Pass'));
    expect(pbn, isNot(contains('[Result ')));
    final match = RegExp(r'\[Deal "([^"]+)"\]').firstMatch(pbn);
    expect(match, isNotNull);
    expect(Deal.fromPbn(match!.group(1)!).toPbn(),
        Deal.fromPbn('N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
            'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8').toPbn());

    await session.nextBoard();
    expect(session.exportHistoryPbn(id), pbn);
    expect(await session.deleteHistory(id), true);
    expect(session.exportHistoryPbn(id), isNull);
  });

  test('A5.3 completed contract includes auction, declarer and 13-trick result',
      () async {
    final session = BridgeSession(
        historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await session.newGame();
    await session.submitCall(const Bid(1, Strain.notrump));
    var steps = 0;
    while (!session.finished && steps++ < 56) {
      final view = session.view!;
      expect(view.phase, Phase.play);
      expect(view.canAct, true);
      await session.submitCard(view.legalCards.first);
    }
    expect(session.finished, true);
    final pbn = session.exportHistoryPbn(session.completedHistory.single.id)!;
    expect(pbn, contains('[Contract "1NT"]'));
    expect(pbn, contains('[Declarer "N"]'));
    expect(pbn, matches(RegExp(r'\[Result "(?:[0-9]|1[0-3])"\]')));
    expect(pbn, contains('[Auction "N"]\n1NT Pass Pass Pass'));
    expect(pbn, contains('[Score "NS '));
    expect(session.view!.completedTricks, hasLength(13));
  });

  testWidgets('A5.3 clipboard export requires explicit four-hand consent',
      (tester) async {
    final session = BridgeSession(
        historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await _tap(tester, 'new_game');
    await _tap(tester, 'pass');
    final id = session.completedHistory.single.id;
    await _tap(tester, 'history_toggle');
    await _tap(tester, 'history_export_' + id);
    expect(find.text('PBN 含這副已完成牌局的四家完整手牌、叫牌與結果。確認後會複製到系統剪貼簿，其他應用程式可能讀取，請只分享給信任的人。'), findsOneWidget);
    expect(copied, isNull);
    await _tap(tester, 'history_export_cancel');
    expect(copied, isNull);
    await _tap(tester, 'history_export_' + id);
    await _tap(tester, 'history_export_confirm');
    expect(copied, contains('[Deal "N:'));
    expect(copied, contains('Pass Pass Pass Pass'));
    expect(find.text('已複製完整牌局 PBN 到剪貼簿'), findsOneWidget);
  });
}
