import 'package:bridge_academy_flutter/src/conventions/auction_coach_page.dart';
import 'package:bridge_academy_flutter/src/conventions/custom_draft_store.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _StoredDraft implements CustomDraftStorage {
  _StoredDraft(this.value);
  final CustomConventionArchive value;

  @override
  Future<CustomConventionArchive> load(String baseProfileId) async {
    if (baseProfileId != 'BA-SAYC') return CustomConventionArchive.empty();
    return value;
  }

  @override
  Future<void> save(
      String baseProfileId, CustomConventionArchive archive) async {
    throw UnimplementedError('Coach cannot edit a user draft');
  }
}

void main() {
  testWidgets('M5.1 public-only default coach never invents a best bid',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AuctionCoachPage(isEnglish: false),
    ));
    expect(find.byKey(const Key('m5_disclaimer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('m5_explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m5_results')), findsOneWidget);
    expect(find.byKey(const Key('m5_no_recommendations')), findsOneWidget);
    expect(find.byKey(const Key('m5_entry_0')), findsOneWidget);
    expect(find.byKey(const Key('m5_entry_1')), findsOneWidget);
    expect(find.byKey(const Key('m5_entry_2')), findsOneWidget);
    expect(find.textContaining('經審核證據'), findsWidgets);
    expect(find.byKey(const Key('m5_game_fingerprint')), findsOneWidget);
    expect(find.byKey(const Key('m5_draft_disclaimer')), findsNothing);
  });

  testWidgets('M5.2 saved local SAYC meanings appear ONLY as author intent',
      (tester) async {
    final first = CustomConventionDraft.create(
      id: 'coach_sayc', label: 'My SAYC',
      base: ConventionCatalog.sayc,
    );
    final next = first.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final archive = CustomConventionArchive.empty()
        .append(first).append(next);
    await tester.pumpWidget(MaterialApp(
      home: AuctionCoachPage(
        isEnglish: true,
        storage: _StoredDraft(archive),
      ),
    ));
    await tester.ensureVisible(find.byKey(const Key('m5_local_draft')));
    await tester.tap(find.byKey(const Key('m5_local_draft')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('m5_explain')));
    await tester.tap(find.byKey(const Key('m5_explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m5_draft_disclaimer')), findsOneWidget);
    expect(find.textContaining('Author-specified meaning'), findsOneWidget);
    expect(find.textContaining('Stayman'), findsOneWidget);
    expect(find.byKey(const Key('m5_no_recommendations')), findsOneWidget);
    expect(find.byKey(const Key('m5_error')), findsNothing);
  });

  testWidgets('M5 coach rejects nonpublic control characters and fake hands',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AuctionCoachPage(isEnglish: true),
    ));
    await tester.enterText(find.byKey(const Key('m5_public_auction')),
        '1NT P HAND_AKQ');
    await tester.ensureVisible(find.byKey(const Key('m5_explain')));
    await tester.tap(find.byKey(const Key('m5_explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m5_error')), findsOneWidget);
    expect(find.byKey(const Key('m5_results')), findsNothing);
  });
  testWidgets('M5.3 finished-game public snapshot retains dealer and '
      'trusted NS/EW profile fingerprints', (tester) async {
    final pinned = GameSystems(
        northSouth: ConventionCatalog.sayc,
        eastWest: ConventionCatalog.twoOverOne);
    await tester.pumpWidget(MaterialApp(
      home: AuctionCoachPage(
        isEnglish: true,
        initialSystems: pinned,
        initialDealer: 'E',
        initialCalls: const ['1NT', 'PASS', '2C', 'P'],
      ),
    ));
    final input = tester.widget<TextField>(
        find.byKey(const Key('m5_public_auction')));
    expect(input.controller!.text, '1NT PASS 2C P');
    final ns = tester.widget<DropdownButton<PartnershipSystem>>(
        find.byKey(const Key('m5_ns')));
    final ew = tester.widget<DropdownButton<PartnershipSystem>>(
        find.byKey(const Key('m5_ew')));
    expect(ns.value, ConventionCatalog.sayc);
    expect(ew.value, ConventionCatalog.twoOverOne);
    await tester.ensureVisible(find.byKey(const Key('m5_explain')));
    await tester.tap(find.byKey(const Key('m5_explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m5_entry_3')), findsOneWidget);
    expect(find.byKey(const Key('m5_error')), findsNothing);
    expect(find.byKey(const Key('m5_draft_disclaimer')), findsNothing);
    expect(find.byKey(const Key('m5_no_recommendations')), findsOneWidget);
  });

  testWidgets('M5.3 historical legacy Gateway is displayed as unverified, '
      'never silently relabeled SAYC', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuctionCoachPage(
        isEnglish: true,
        initialSystems: GameSystems.legacyUnverified(),
        initialDealer: 'N',
        initialCalls: const ['P', 'P', 'P', 'P'],
      ),
    ));
    final ns = tester.widget<DropdownButton<PartnershipSystem>>(
        find.byKey(const Key('m5_ns')));
    expect(ns.value, ConventionCatalog.legacyUnverified);
    await tester.ensureVisible(find.byKey(const Key('m5_explain')));
    await tester.tap(find.byKey(const Key('m5_explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m5_entry_3')), findsOneWidget);
    expect(find.textContaining('LEGACY_UNVERIFIED'), findsWidgets);
    expect(find.byKey(const Key('m5_no_recommendations')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
