import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('B4 entry opens real lesson route; wrong answer needs retry',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapKey(tester, 'academy_open');
    expect(find.byKey(const Key('academy_page')), findsOneWidget);
    expect(find.byKey(const Key('academy_lesson_list')), findsOneWidget);
    await tapKey(tester, 'academy_open_b4.cards-and-seats');
    expect(find.byKey(const Key('academy_question_b4.cards.count')),
        findsOneWidget);
    expect(tester.widget<FilledButton>(
        find.byKey(const Key('academy_submit'))).onPressed, isNull);

    await tapKey(tester, 'academy_option_a');
    await tapKey(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_incorrect')), findsOneWidget);
    expect(find.byKey(const Key('academy_explanation')), findsOneWidget);
    expect(find.byKey(const Key('academy_next')), findsNothing);

    await tapKey(tester, 'academy_retry');
    await tapKey(tester, 'academy_option_b');
    await tapKey(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    expect(find.byKey(const Key('academy_submit')), findsNothing);
    await tapKey(tester, 'academy_next');

    await tapKey(tester, 'academy_option_b');
    await tapKey(tester, 'academy_submit');
    await tapKey(tester, 'academy_next');

    await tapKey(tester, 'academy_option_c');
    await tapKey(tester, 'academy_submit');
    await tapKey(tester, 'academy_next');

    expect(find.byKey(const Key('academy_completion')), findsOneWidget);
    expect(find.textContaining('3 / 3'), findsOneWidget);
    await tapKey(tester, 'academy_to_catalog');
    expect(find.byKey(const Key('academy_progress_b4.cards-and-seats')),
        findsOneWidget);
    expect(find.textContaining('3 / 3'), findsOneWidget);

    // Reopening an already-completed lesson cannot inflate a set-based count.
    await tapKey(tester, 'academy_open_b4.cards-and-seats');
    await tapKey(tester, 'academy_all_lessons');
    expect(find.textContaining('3 / 3'), findsOneWidget);
    await tapKey(tester, 'academy_back');
    expect(find.byKey(const Key('academy_page')), findsNothing);
    expect(find.byKey(const Key('new_game')), findsOneWidget);
  });

  testWidgets('B4 English locale applies to both catalog and feedback',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AcademyPage(isEnglish: false),
    ));
    await tapKey(tester, 'academy_toggle_locale');
    expect(find.text('Choose your first lesson'), findsOneWidget);
    await tapKey(tester, 'academy_open_b4.cards-and-seats');
    expect(find.text('How many cards are in a standard bridge deck?'),
        findsOneWidget);
    await tapKey(tester, 'academy_option_a');
    await tapKey(tester, 'academy_submit');
    expect(find.text('Not quite'), findsOneWidget);
    expect(find.textContaining('Bridge uses no jokers'), findsOneWidget);
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('B4 responsive $width with 2x text has no layout exception',
        (tester) async {
      tester.view.physicalSize = Size(width, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const AcademyPage(isEnglish: true),
      ));
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'academy_open_b4.cards-and-seats');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'academy_option_b');
      await tapKey(tester, 'academy_submit');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    });
  }
}
