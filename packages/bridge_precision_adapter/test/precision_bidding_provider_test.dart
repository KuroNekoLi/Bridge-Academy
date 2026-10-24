import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';
import 'package:test/test.dart';

final class RecordingPrecisionTransport implements PrecisionBidTransport {
  Map<String, Object>? captured;
  Map<String, Object?> response = {
    'bid': '1C', 'provider': 'BBA_NATIVE_EPBOT',
    'profileId': PrecisionResearchCatalog.selectedProductProfileId,
    'revision': 1,
    'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
  };

  @override
  Future<Map<String, Object?>> bid(Map<String, Object> request) async {
    captured = request;
    return response;
  }
}

PlayerView seatView(Seat seat) => PlayerView.forSeat(
  GameState.start(Deal.suitPerSeat(), seat, Vulnerability.both), seat);

void main() {
  group('M3.3 Precision auction provider', () {
    test('only seat-view own cards reach native proposal', () async {
      final transport = RecordingPrecisionTransport();
      final policy = BbaPrecisionBiddingProvider(
        transport: transport, precisionSideIsNS: true,
        opponentModel: 'SAYC',
      );
      final result = await policy.choose(seatView(Seat.north));
      expect(result, isA<CallAction>());
      expect(result.actor, Seat.north);
      expect(result.code, 'B:N:1C');
      final sent = transport.captured!;
      expect(sent['seat'], 'N');
      expect(sent['dealer'], 'N');
      expect(sent['vul'], 'Both');
      expect(sent['opponentModel'], 'SAYC');
      expect(sent['profileId'],
          PrecisionResearchCatalog.selectedProductProfileId);
      expect(sent['cardSha256'],
          PrecisionResearchCatalog.selectedCardSha256);
      expect(sent['hand'], isA<String>());
      expect((sent['hand'] as String).replaceAll('.', '').length, 13);
      expect(sent.keys, isNot(contains('dummy')));
      expect(sent.keys, isNot(contains('deal')));
      expect(sent.keys, isNot(contains('hands')));
      expect(sent.keys, isNot(contains('pbn')));
      expect(() => sent['hand'] = 'EVIL', throwsUnsupportedError);
    });

    test('Precision EW proposal identifies east seat and 21GF opponents',
        () async {
      final transport = RecordingPrecisionTransport()
        ..response = {
          'bid': 'PASS', 'provider': 'BBA_NATIVE_EPBOT',
          'profileId': PrecisionResearchCatalog.selectedProductProfileId,
          'revision': 1,
          'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
        };
      final policy = BbaPrecisionBiddingProvider(
        transport: transport, precisionSideIsNS: false,
        opponentModel: '21GF',
      );
      final action = await policy.choose(seatView(Seat.east));
      expect(action.code, 'B:E:PASS');
      expect(transport.captured!['seat'], 'E');
      expect(transport.captured!['opponentModel'], '21GF');
    });

    test('mismatched partnership and unsupported opponent fail closed',
        () async {
      final transport = RecordingPrecisionTransport();
      final wrongSeat = BbaPrecisionBiddingProvider(
          transport: transport, precisionSideIsNS: false,
          opponentModel: 'SAYC');
      await expectLater(wrongSeat.choose(seatView(Seat.north)),
          throwsA(isA<PrecisionProviderException>()));
      expect(transport.captured, isNull);

      final badOpponent = BbaPrecisionBiddingProvider(
          transport: transport, precisionSideIsNS: true,
          opponentModel: 'PRECISION');
      await expectLater(badOpponent.choose(seatView(Seat.north)),
          throwsA(isA<PrecisionProviderException>()));
      expect(transport.captured, isNull);
    });

    test('changed card fingerprint or malformed bid is rejected', () async {
      final transport = RecordingPrecisionTransport();
      final policy = BbaPrecisionBiddingProvider(
          transport: transport, precisionSideIsNS: true,
          opponentModel: 'SAYC');
      transport.response = {...transport.response, 'cardSha256': 'bad'};
      await expectLater(policy.choose(seatView(Seat.north)),
          throwsA(isA<PrecisionProviderException>()));
      transport.response = {
        ...transport.response, 'cardSha256':
            PrecisionResearchCatalog.selectedCardSha256, 'bid': '8NT',
      };
      await expectLater(policy.choose(seatView(Seat.north)),
          throwsA(isA<PrecisionProviderException>()));
    });
  });

  group('M3.3 private loopback transport', () {
    test('rejects remote origin or query-embedded hand', () {
      for (final uri in [
        'http://example.com:18088/',
        'https://127.0.0.1:18088/',
        'http://localhost:18088/',
        'http://127.0.0.1:18088/?hand=SECRET',
      ]) {
        expect(
          () => BbaPrecisionLoopbackTransport(origin: Uri.parse(uri)),
          throwsArgumentError,
          reason: uri,
        );
      }
    });

    test('POST holds private hand in body, not URL, with strict response',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final captured = <String, Object?>{};
      server.listen((request) async {
        captured['url'] = request.uri.toString();
        captured['method'] = request.method;
        captured['request'] = jsonDecode(
            await utf8.decoder.bind(request).join());
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'bid': '1C', 'provider': 'BBA_NATIVE_EPBOT',
          'profileId': PrecisionResearchCatalog.selectedProductProfileId,
          'revision': 1,
          'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
        }));
        await request.response.close();
      });
      final transport = BbaPrecisionLoopbackTransport(
          origin: Uri.parse('http://127.0.0.1:${server.port}/'));
      try {
        final policy = BbaPrecisionBiddingProvider(
          transport: transport, precisionSideIsNS: true,
          opponentModel: 'SAYC',
        );
        final action = await policy.choose(seatView(Seat.north));
        expect(action.code, 'B:N:1C');
        expect(captured['method'], 'POST');
        expect(captured['url'], '/v1/precision/bid');
        expect(captured['url'].toString(), isNot(contains('hand')));
        expect((captured['request'] as Map)['hand'], isA<String>());
        expect((captured['request'] as Map).containsKey('deal'), false);
      } finally {
        transport.close();
        await server.close(force: true);
      }
    });
  });
}
