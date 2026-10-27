import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_auction_grid.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_bidding_box.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('M2-F66 matrix selects without submission; confirm sends once', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.ensureVisible(find.byKey(const Key('new_game')));
    await tester.tap(find.byKey(const Key('new_game')));
    await tester.pumpAndSettle();
    expect(find.byType(BridgeBiddingBox), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('double'))).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('redouble')))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('make_bid'))).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('bid_2S')));
    await tester.tap(find.byKey(const Key('bid_2S')));
    await tester.pump();
    expect(session.view!.version, 0);
    await tester.ensureVisible(find.byKey(const Key('make_bid')));
    await tester.tap(find.byKey(const Key('make_bid')));
    await tester.pumpAndSettle();
    expect(session.view!.auction.first.call.code, '2S');
    expect(
      session.view!.auction
          .where((e) => e.seat == session.view!.viewer && e.call.code == '2S')
          .length,
      1,
    );
  });

  testWidgets('M2-F66 selection expires, waiting locks, high levels fold', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var state = GameState.start(
      Deal.shuffled(seed: 66),
      Seat.north,
      Vulnerability.none,
    );
    var sent = 0;
    Future<void> render({
      bool enabled = true,
      double scale = 1,
      Seat? viewer,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
              child: BridgeBiddingBox(
                copy: const AppCopy(true),
                view: PlayerView.forSeat(
                  state,
                  viewer ?? state.turn ?? Seat.north,
                ),
                canSubmit: enabled,
                onSubmitCall: (_) => sent++,
              ),
            ),
          ),
        ),
      ),
    );
    await render(viewer: Seat.east);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('pass'))).onPressed,
      isNull,
    );
    await render();
    await tester.tap(find.byKey(const Key('bid_1C')));
    await tester.pump();
    await render(enabled: false);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('pass'))).onPressed,
      isNull,
    );
    await render();
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('make_bid'))).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('bid_more_levels')));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bid_7NT')), findsOneWidget);
    state = BridgeGame.apply(
      state,
      CallAction(state.turn!, const Bid(7, Strain.notrump)),
    );
    await render();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bid_1C')), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('bid_7NT'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('double'))).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('double')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('make_bid')));
    await tester.pump();
    expect(sent, 1);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('make_bid'))).onPressed,
      isNull,
    );
    await render(scale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'M2-F67 dealer padding, pending seat, public inspector and latest row',
    (tester) async {
      for (final dealer in Seat.values) {
        var state = GameState.start(
          Deal.shuffled(seed: 67),
          dealer,
          Vulnerability.none,
        );
        for (final strain in Strain.values.take(4)) {
          state = BridgeGame.apply(
            state,
            CallAction(state.turn!, Bid(1, strain)),
          );
        }
        Future<void> render() => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: BridgeAuctionGrid(
                  copy: const AppCopy(false),
                  view: PlayerView.forSeat(state, dealer),
                ),
              ),
            ),
          ),
        );
        await render();
        await tester.pumpAndSettle();
        final first = tester.getCenter(find.byKey(const Key('auction_call_0')));
        final header = tester.getCenter(
          find.byKey(Key('auction_header_${dealer.letter}')),
        );
        expect((first.dx - header.dx).abs(), lessThan(1));
        expect(
          find.byKey(Key('auction_pending_${state.turn!.letter}')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('auction_call_0')));
        await tester.pumpAndSettle();
        expect(find.text('尚未提供此叫品的已驗證說明。'), findsOneWidget);
        await tester.tap(find.text('關閉'));
        await tester.pumpAndSettle();
        for (var level = 2; level <= 7; level++) {
          for (final strain in Strain.values) {
            state = BridgeGame.apply(
              state,
              CallAction(state.turn!, Bid(level, strain)),
            );
          }
        }
        await render();
        await tester.pumpAndSettle();
        expect(
          find.byKey(Key('auction_call_${state.auction.length - 1}')),
          findsOneWidget,
        );
        final controller = tester
            .widget<ListView>(find.byKey(const Key('auction_rows')))
            .controller!;
        expect(controller.offset, controller.position.maxScrollExtent);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
