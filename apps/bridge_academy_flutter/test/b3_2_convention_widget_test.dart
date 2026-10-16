import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/conventions/convention_profile.dart';
import 'package:bridge_academy_flutter/src/widgets/bidding_convention_panel.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BidContext example({
  Seat dealer = Seat.north,
  Vulnerability vulnerability = Vulnerability.none,
  Call response = const Bid(2, Strain.clubs),
  Call interference = const Pass(),
}) => BidContext(
  dealer: dealer,
  viewer: dealer.partner,
  vulnerability: vulnerability,
  auction: [
    AuctionEntry(dealer, const Bid(1, Strain.notrump)),
    AuctionEntry(dealer.next, interference),
    AuctionEntry(dealer.partner, response),
  ],
);

Widget harness(BidContext context, {bool english = false}) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: BiddingConventionPanel(
        contextData: context, copy: AppCopy(english),
      ),
    )));

void main() {
  testWidgets('preview opt-in toggles UNKNOWN to Stayman with source', (tester) async {
    await tester.pumpWidget(harness(example()));
    expect(find.byKey(const Key('b3_convention_unknown')), findsOneWidget);
    expect(find.textContaining('Stayman'), findsNothing);
    expect(find.textContaining('BA-NATURAL-NT r1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('b3_preview_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b3_convention_unknown')), findsNothing);
    expect(find.textContaining('Stayman'), findsOneWidget);
    expect(find.textContaining('BA-NATURAL-NT r2'), findsOneWidget);
    expect(find.byKey(const Key('b3_rule_id')), findsOneWidget);
    expect(find.byKey(const Key('b3_source')), findsOneWidget);
    expect(find.byKey(const Key('b3_preview_only')), findsOneWidget);
    await tester.tap(find.byKey(const Key('b3_preview_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b3_convention_unknown')), findsOneWidget);
  });

  testWidgets('English Jacoby, and interference remains unknown', (tester) async {
    await tester.pumpWidget(harness(example(
      dealer: Seat.east,
      vulnerability: Vulnerability.ew,
      response: const Bid(2, Strain.diamonds),
    ), english: true));
    await tester.tap(find.byKey(const Key('b3_preview_toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Jacoby Transfer 2D'), findsOneWidget);
    expect(find.textContaining('not expert-reviewed'), findsOneWidget);
    await tester.pumpWidget(harness(example(
      dealer: Seat.east,
      response: const Bid(2, Strain.diamonds),
      interference: const DoubleCall(),
    ), english: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('b3_convention_unknown')), findsOneWidget);
  });

  testWidgets('narrow screen and large font keep preview interactive', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: harness(example(), english: true),
    ));
    await tester.tap(find.byKey(const Key('b3_preview_toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('b3_rule_id')), findsOneWidget);
  });
}
