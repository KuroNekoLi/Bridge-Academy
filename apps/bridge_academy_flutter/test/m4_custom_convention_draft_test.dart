import 'dart:convert';

import 'package:bridge_academy_flutter/src/conventions/custom_draft_page.dart';
import 'package:bridge_academy_flutter/src/conventions/custom_draft_store.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MemoryStore implements CustomDraftStorage {
  final saved = <String, CustomConventionArchive>{};

  @override
  Future<CustomConventionArchive> load(String id) async =>
      saved[id] ?? CustomConventionArchive.empty();

  @override
  Future<void> save(String id, CustomConventionArchive archive) async {
    saved[id] = CustomConventionArchive.fromJson(archive.toJson());
  }
}

void main() {
  testWidgets('M4.2 drafts remain engine-unverified across save and reopen',
      (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(
          isEnglish: false, storage: store),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_release_warning')), findsOneWidget);
    expect(find.byKey(const Key('m4_save')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('m4_save')));
    await tester.tap(find.byKey(const Key('m4_save')));
    await tester.pumpAndSettle();
    final revision2 = store.saved['BA-SAYC']!.latest!;
    expect(revision2.revision, 2);
    expect(revision2.runtimeSupport, 'ENGINE_UNVERIFIED');
    expect(revision2.isPlayableCustomSystem, isFalse);
    expect(revision2.rules.single.choice, '12_14');
    expect(find.byKey(const Key('m4_engine_status')), findsOneWidget);
    expect(find.textContaining('不可用於 AI 對局'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(
          isEnglish: true, storage: store),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Engine compatibility: unverified'),
        findsOneWidget);
    expect(find.textContaining('Draft revision: 2'), findsOneWidget);
    expect(store.saved['BA-SAYC']!.revisions.length, 2);
  });

  testWidgets('M4.2 accepts edit then remove with append-only revision links',
      (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(
          isEnglish: true, storage: store),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('m4_save')));
    await tester.tap(find.byKey(const Key('m4_save')));
    await tester.pumpAndSettle();

    final two = store.saved['BA-SAYC']!.latest!;
    await tester.ensureVisible(find.byKey(const Key('m4_remove')));
    await tester.tap(find.byKey(const Key('m4_remove')));
    await tester.pumpAndSettle();
    final three = store.saved['BA-SAYC']!.latest!;
    expect(three.revision, 3);
    expect(three.previousFingerprint, two.fingerprint);
    expect(three.rules, isEmpty);
    expect(three.runtimeSupport, 'UNCHANGED_BASE_ONLY');
    expect(store.saved['BA-SAYC']!.revisions, hasLength(3));
  });
  testWidgets('M4.4 preview is author-only and does not advertise AI support',
      (tester) async {
    final store = _MemoryStore();
    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(isEnglish: true, storage: store),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_preview_disclaimer')), findsOneWidget);
    expect(find.textContaining('not BEN/BBA evidence'), findsOneWidget);
    expect(find.byKey(const Key('m4_preview_meaning')), findsOneWidget);
    expect(find.textContaining('interpretation is unknown'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('m4_save')));
    await tester.ensureVisible(find.byKey(const Key('m4_save')));
    await tester.tap(find.byKey(const Key('m4_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_evidence_status')), findsOneWidget);
    expect(find.textContaining('No engine evidence'), findsOneWidget);
    expect(find.byKey(const Key('m4_preview_auction')), findsOneWidget);
    expect(find.text('1NT'), findsOneWidget);
    expect(find.text('12–14 HCP'), findsWidgets);
    expect(store.saved['BA-SAYC']!.latest!.isPlayableCustomSystem, false);
  });

  testWidgets('M4.5 clipboard import requires explicit consent and '
      'protects local divergent revisions', (tester) async {
    String? clipboard;
    final messenger = TestDefaultBinaryMessengerBinding.instance
        .defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': clipboard};
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(
        SystemChannels.platform, null));

    final base = CustomConventionDraft.create(
        id: 'local_sayc', label: 'My SAYC',
        base: ConventionCatalog.sayc);
    final next = base.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final local = CustomConventionArchive.empty().append(base);
    final imported = local.append(next);
    final store = _MemoryStore()..saved['BA-SAYC'] = local;
    clipboard = jsonEncode(imported.toJson());

    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(isEnglish: true, storage: store),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('m4_import')));
    await tester.tap(find.byKey(const Key('m4_import')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_import_confirm')), findsOneWidget);
    expect(store.saved['BA-SAYC']!.latest!.revision, 1);
    await tester.tap(find.byKey(const Key('m4_import_confirm')));
    await tester.pumpAndSettle();
    expect(store.saved['BA-SAYC']!.latest!.fingerprint, next.fingerprint);
    expect(store.saved['BA-SAYC']!.latest!.isPlayableCustomSystem, false);
    expect(find.textContaining('AI engine support remains unverified'),
        findsOneWidget);

    // A divergent chain cannot overwrite the imported history.
    final branched = local.append(base.withRule(CustomConventionRule(
        CustomRuleSlot.oneNotrumpOpening, '13_15')));
    clipboard = jsonEncode(branched.toJson());
    await tester.ensureVisible(find.byKey(const Key('m4_import')));
    await tester.tap(find.byKey(const Key('m4_import')));
    await tester.pumpAndSettle();
    expect(find.textContaining('older or divergent'), findsOneWidget);
    expect(store.saved['BA-SAYC']!.latest!.fingerprint, next.fingerprint);

    await tester.ensureVisible(find.byKey(const Key('m4_export')));
    await tester.tap(find.byKey(const Key('m4_export')));
    await tester.pumpAndSettle();
    expect(CustomConventionArchive.fromJson(jsonDecode(clipboard!))
        .latest!.fingerprint, next.fingerprint);
  });

  testWidgets('M4.6 version history clearly shows changed auction meaning '
      'without claiming engine support', (tester) async {
    final base = CustomConventionDraft.create(
      id: 'local_sayc', label: 'My SAYC',
      base: ConventionCatalog.sayc,
    );
    final two = base.withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final three = two.withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final four = three.withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '13_15'));
    final store = _MemoryStore()
      ..saved['BA-SAYC'] = CustomConventionArchive.empty()
          .append(base).append(two).append(three).append(four);
    await tester.pumpWidget(MaterialApp(
      home: CustomConventionDraftPage(isEnglish: true, storage: store),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_diff_heading')), findsOneWidget);
    expect(find.byKey(const Key('m4_diff_disclaimer')), findsOneWidget);
    expect(find.textContaining('not verified BEN or BBA'), findsOneWidget);
    expect(find.byKey(const Key('m4_diff_oneNotrumpOpening')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('m4_compare_from')));
    await tester.tap(find.byKey(const Key('m4_compare_from')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft revision: 2').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_diff_twoClubsOverOneNotrump')),
        findsOneWidget);
    final a = CustomConventionHistory.compare(store.saved['BA-SAYC']!,
        fromRevision: 2, toRevision: 4);
    expect(a.changes.map((c) => c.kind), contains(CustomRuleChangeKind.changed));
    expect(a.isEngineValidated, false);
    expect(store.saved['BA-SAYC']!.latest!.isPlayableCustomSystem, false);
  });

}
