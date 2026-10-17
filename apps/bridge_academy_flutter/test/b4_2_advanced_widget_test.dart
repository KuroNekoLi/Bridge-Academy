import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> press(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 170,
        scrollable: find.byType(Scrollable).last, maxScrolls: 30);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('B4.2 playable advanced lesson, retry and C3 consent', (tester) async {
    final store = MemoryLearnerStore();
    await tester.pumpWidget(MaterialApp(
      home: AcademyPage(isEnglish: false, learnerStore: store)));
    await tester.pumpAndSettle();
    expect(await store.read(), isNull);
    await press(tester, 'c3_enable');
    await press(tester, 'academy_open_b4.advanced-defense');
    expect(find.byKey(const Key('academy_question_b4.2.follow-led-suit')),
        findsOneWidget);
    await press(tester, 'academy_option_b');
    await press(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_incorrect')), findsOneWidget);
    await press(tester, 'academy_retry');
    await press(tester, 'academy_option_a');
    await press(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    expect((await store.read())!.completedCount, 1);
    expect((await store.read())!.skill('defense_rules').total, 2);
    await press(tester, 'academy_all_lessons');
    await press(tester, 'c3_show_progress');
    expect(find.textContaining('1 / 21'), findsOneWidget);
  });

  testWidgets('B4.2 advanced bilingual concept and narrow layout', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: AcademyPage(isEnglish: false, learnerStore: MemoryLearnerStore()),
    ));
    await tester.pumpAndSettle();
    await press(tester, 'academy_toggle_locale');
    expect(find.text('Choose a lesson'), findsOneWidget);
    await press(tester, 'academy_open_b4.advanced-agreements');
    expect(find.textContaining('These questions describe only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
