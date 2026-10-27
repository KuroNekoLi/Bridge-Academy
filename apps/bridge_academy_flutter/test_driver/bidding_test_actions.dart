import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Existing end-to-end journeys now perform the actual two-step bidding UI.
/// The fixture's default opening is explicitly 1NT; no product defaults or
/// hidden controls are retained to satisfy old tests.
Future<void> tapBiddingAware(
  WidgetTester tester,
  Finder target,
  String key,
) async {
  if (key == 'make_bid' &&
      tester.widget<FilledButton>(target).onPressed == null) {
    final choice = find.byKey(const Key('bid_1NT'));
    await tester.ensureVisible(choice);
    expect(tester.widget<OutlinedButton>(choice).onPressed, isNotNull);
    await tester.tap(choice);
    await tester.pump();
    await tester.ensureVisible(target);
  }
  final special = {'pass', 'double', 'redouble'}.contains(key);
  if (special && tester.widget<OutlinedButton>(target).onPressed == null) {
    return;
  }
  await tester.tap(target);
  await tester.pump();
  if (special) {
    final confirm = find.byKey(const Key('make_bid'));
    await tester.ensureVisible(confirm);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pump();
  }
}
