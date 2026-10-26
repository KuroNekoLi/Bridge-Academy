import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_bidding_box.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('A3.2 controlled bidding box submits selected level/strain',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.ensureVisible(find.byKey(const Key('new_game')));
    await tester.tap(find.byKey(const Key('new_game')));
    await tester.pumpAndSettle();

    expect(find.byType(BridgeBiddingBox), findsOneWidget);
    expect(find.byKey(const Key('pass')), findsOneWidget);
    expect(find.byKey(const Key('double')), findsOneWidget);
    expect(find.byKey(const Key('redouble')), findsOneWidget);
    final level = tester.widget<DropdownButton<int>>(
      find.byKey(const Key('bid_level')),
    );
    level.onChanged!(2);
    await tester.pump();
    final strain = tester.widget<DropdownButton<Strain>>(
      find.byKey(const Key('bid_strain')),
    );
    strain.onChanged!(Strain.spades);
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('make_bid')));
    await tester.tap(find.byKey(const Key('make_bid')));
    await tester.pumpAndSettle();
    expect(session.view!.auction.first.call.code, '2S');
    expect(session.view!.version, greaterThan(0));
  });

  testWidgets('A3.2 UI keeps invalid X rejection in Bridge Core',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.ensureVisible(find.byKey(const Key('new_game')));
    await tester.tap(find.byKey(const Key('new_game')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('double')));
    await tester.tap(find.byKey(const Key('double')));
    await tester.pumpAndSettle();
    expect(session.view!.version, 0);
    expect(find.byKey(const Key('error_message')), findsOneWidget);
  });
}
