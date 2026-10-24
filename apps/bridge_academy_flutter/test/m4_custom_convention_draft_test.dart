import 'package:bridge_academy_flutter/src/conventions/custom_draft_page.dart';
import 'package:bridge_academy_flutter/src/conventions/custom_draft_store.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/material.dart';
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
    await tester.tap(find.byKey(const Key('m4_save')));
    await tester.pumpAndSettle();

    final two = store.saved['BA-SAYC']!.latest!;
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
    await tester.tap(find.byKey(const Key('m4_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('m4_evidence_status')), findsOneWidget);
    expect(find.textContaining('No engine evidence'), findsOneWidget);
    expect(find.byKey(const Key('m4_preview_auction')), findsOneWidget);
    expect(find.text('1NT'), findsOneWidget);
    expect(find.text('12–14 HCP'), findsWidgets);
    expect(store.saved['BA-SAYC']!.latest!.isPlayableCustomSystem, false);
  });

}
