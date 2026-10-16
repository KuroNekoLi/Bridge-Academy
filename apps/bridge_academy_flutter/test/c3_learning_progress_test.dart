import 'dart:convert';

import 'package:bridge_academy_flutter/src/academy/academy_catalog.dart';
import 'package:bridge_academy_flutter/src/academy/academy_models.dart';
import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_progress.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_store.dart';
import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final sample = AcademyCatalog.validated().first;
final question = sample.questions.first;

AcademyAnswer answer(String option) => AcademyAnswer(
  lessonId: sample.lessonId, questionId: question.questionId,
  schemaVersion: sample.schemaVersion, skillTag: question.skillTag,
  selectedOptionId: option,
);

LearnerAttempt attempt(String id, bool correct) => LearnerAttempt(
  id: id, timestampUtc: DateTime.utc(2026, 10, 16),
  answer: answer(correct ? question.correctOptionId :
      question.options.firstWhere((x) => x.optionId != question.correctOptionId).optionId),
  correct: correct,
);

class _Records implements AtomicArchiveRecordStore {
  Map<String, dynamic>? value;
  @override
  Future<Map<String, dynamic>?> readRecord() async =>
      value == null ? null : Map.of(value!);
  @override
  Future<void> replaceRecord(Map<String, dynamic> record) async {
    value = Map.of(record);
  }
  @override
  Future<void> clearRecord() async { value = null; }
}
class _Keys implements ArchiveEncryptionKeyProvider {
  @override
  Future<List<int>> loadOrCreateKey() async => List.filled(32, 7);
}

void main() {
  test('C3 counts attempts, unique completed questions and empty samples', () {
    final ledger = LearnerProgress();
    expect(ledger.accuracy, isNull);
    expect(ledger.skill(sample.skillTag).accuracy, isNull);
    expect(ledger.record(attempt('a', false)), isTrue);
    expect(ledger.completedCount, 0);
    expect(ledger.record(attempt('b', true)), isTrue);
    expect(ledger.record(attempt('c', true)), isTrue);
    expect(ledger.record(attempt('c', true)), isFalse);
    expect(ledger.total, 3);
    expect(ledger.completedCount, 1);
    expect(ledger.correct, 2);
    expect(ledger.skill(sample.skillTag).total, 3);
    expect(ledger.accuracy, closeTo(2 / 3, 0.00001));
    ledger.savingEnabled = false;
    final restored = LearnerProgress.fromJson(jsonDecode(jsonEncode(ledger.toJson())));
    expect(restored.savingEnabled, false);
    expect(LearnerProgress.fromJson({
      'v': 1, 'items': [attempt('legacy', true).toJson()],
    }).savingEnabled, true);
    expect(LearnerProgress.fromJson(jsonDecode(jsonEncode(ledger.toJson()))).toJson(),
      ledger.toJson());
  });
  test('C3 rejects unknown versions, duplicate IDs and malformed dates', () {
    final raw = LearnerProgress([attempt('a', false)]).toJson();
    expect(() => LearnerProgress.fromJson({...raw, 'v': 3}), throwsFormatException);
    expect(() => LearnerProgress.fromJson({
      'v': 1, 'items': [attempt('a', true).toJson(), attempt('a', false).toJson()],
    }), throwsFormatException);
    expect(() => LearnerAttempt.fromJson({
      ...attempt('x', true).toJson(), 'utc': 'invalid',
    }), throwsFormatException);
  });
  test('C3 encrypts separate ledger, fails closed after tampering, deletes', () async {
    final records = _Records();
    final store = EncryptedLearnerStore(records: records, keys: _Keys());
    expect(await store.read(), isNull);
    await store.write(LearnerProgress([attempt('a', false), attempt('b', true)]));
    expect(records.value.toString(), isNot(contains(question.questionId)));
    expect((await store.read())!.completedCount, 1);
    records.value!['mac'] = base64Encode(List.filled(16, 0));
    await expectLater(store.read(), throwsA(anything));
    await store.clear();
    expect(await store.read(), isNull);
  });
  testWidgets('C3 opt in, submit, dashboard and delete', (tester) async {
    final store = MemoryLearnerStore();
    await tester.pumpWidget(MaterialApp(
      home: AcademyPage(isEnglish: true, learnerStore: store)));
    await tester.pumpAndSettle();
    expect(await store.read(), isNull);
    final enable = find.byKey(const Key('c3_enable'));
    await tester.ensureVisible(enable);
    await tester.tap(enable);
    await tester.pumpAndSettle();
    expect(await store.read(), isNotNull);
    final open = find.byKey(Key('academy_open_${sample.lessonId}'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    final option = find.byKey(Key('academy_option_${question.correctOptionId}'));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    final submit = find.byKey(const Key('academy_submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect((await store.read())!.completedCount, 1);
    final back = find.byKey(const Key('academy_all_lessons'));
    if (back.evaluate().isEmpty) {
      await tester.scrollUntilVisible(back, 160,
        scrollable: find.byType(Scrollable).last, maxScrolls: 20);
    }
    await tester.ensureVisible(back);
    await tester.pumpAndSettle();
    await tester.tap(back);
    await tester.pumpAndSettle();
    final show = find.byKey(const Key('c3_show_progress'));
    await tester.ensureVisible(show);
    await tester.tap(show);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_dashboard')), findsOneWidget);
    expect(find.textContaining('1 / 9'), findsOneWidget);
    final toggle = find.byKey(const Key('c3_toggle_saving'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect((await store.read())!.savingEnabled, false);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect((await store.read())!.savingEnabled, true);
    final remove = find.byKey(const Key('c3_delete'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all learning history').last);
    await tester.pumpAndSettle();
    expect(await store.read(), isNull);
  });

  testWidgets('C3 restarts with persisted state and switches language safely',
      (tester) async {
    final store = MemoryLearnerStore();
    await store.write(LearnerProgress([attempt('persisted', true)]));
    await tester.pumpWidget(MaterialApp(
      home: AcademyPage(isEnglish: false, learnerStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_enable')), findsNothing);
    final progress = find.byKey(const Key('c3_show_progress'));
    await tester.ensureVisible(progress);
    await tester.tap(progress);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 / 9'), findsOneWidget);
    expect(find.textContaining('100%'), findsWidgets);
    await tester.tap(find.byKey(const Key('academy_toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.text('Learning progress'), findsOneWidget);
    expect((await store.read())!.completedCount, 1);
  });

  testWidgets('C3 opt-out questions do not write history',
      (tester) async {
    final store = MemoryLearnerStore();
    await tester.pumpWidget(MaterialApp(
      home: AcademyPage(isEnglish: true, learnerStore: store)));
    await tester.pumpAndSettle();
    final open = find.byKey(Key('academy_open_${sample.lessonId}'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    final choice = find.byKey(Key('academy_option_${question.correctOptionId}'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('academy_submit'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    expect(await store.read(), isNull);
  });
}
