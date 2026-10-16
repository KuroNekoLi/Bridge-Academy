import 'dart:async';
import 'dart:convert';

import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _privateHand = 'AKQ.JT9.876.5432';
const _validBid = {
  'hand': _privateHand,
  'seat': 'N',
  'dealer': 'E',
  'vul': 'NS',
  'ctx': '1N-P',
};

void main() {
  group('A4.1 HTTPS Gateway POST (MockClient, NOT live BEN)', () {
    test('POST JSON body; URL never exposes private hand or bearer token',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://bridge.example/v1/ai/decision');
        expect(request.url.query, isEmpty);
        expect(request.followRedirects, isFalse);
        expect(request.headers['authorization'], 'Bearer short_lived_token');
        expect(request.headers['cache-control'], 'no-store');
        expect(request.headers['content-type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['version'], 1);
        expect(body['route'], 'bid');
        expect((body['input'] as Map)['hand'], _privateHand);
        expect(body['input'], isNot(contains('deal')));
        return http.Response('{"version":1,"decision":{"bid":"PASS"}}', 200);
      });
      final transport = BenGatewayTransport(
        baseUri: Uri.parse('https://bridge.example'),
        accessTokenProvider: () async => 'short_lived_token',
        client: client,
      );
      final decision = await transport.get('/bid', _validBid);
      expect(decision['bid'], 'PASS');
      transport.close();
    });

    test('refuses untrusted origin, embedded credentials and paths', () {
      for (final raw in [
        'http://bridge.example',
        'https://u:p@bridge.example',
        'https://bridge.example/v1',
        'https://bridge.example/?hand=secret',
        'https://bridge.example/#token',
      ]) {
        expect(
          () => BenGatewayTransport(
            baseUri: Uri.parse(raw),
            accessTokenProvider: () async => 'session-token',
          ),
          throwsArgumentError,
          reason: raw,
        );
      }
    });

    test('rejects unallowed fields and early dummy without token or network',
        () async {
      var called = false;
      final gateway = BenGatewayTransport(
        baseUri: Uri.parse('https://bridge.example'),
        accessTokenProvider: () async {
          called = true;
          return 'token';
        },
        client: MockClient((request) async {
          fail('Network request must not be attempted');
        }),
      );
      for (final args in [
        {..._validBid, 'deal': 'SECRET_FOUR_HANDS'},
        {..._validBid, 'dummy': 'UNEXPOSED'},
      ]) {
        await expectLater(gateway.get('/bid', args),
            throwsA(isA<BenApiException>()));
      }
      await expectLater(gateway.get('/autoplay', _validBid),
          throwsA(isA<BenApiException>()));
      expect(called, isFalse);
      gateway.close();
    });

    test('missing/failed credential rejects before sending', () async {
      for (final provider in <GatewayAccessTokenProvider>[
        () async => null,
        () async => '',
        () async => 'injected\r\nheader',
        () async => throw StateError('sensitive_token'),
      ]) {
        final gateway = BenGatewayTransport(
          baseUri: Uri.parse('https://bridge.example'),
          accessTokenProvider: provider,
          client: MockClient((request) async {
            fail('No request before authentication');
          }),
        );
        await expectLater(
          gateway.get('/bid', _validBid),
          throwsA(predicate((e) => e is BenApiException && e.kind == 'auth')),
        );
        gateway.close();
      }
    });

    test('plays use only already-exposed dummy information', () async {
      final gateway = BenGatewayTransport(
        baseUri: Uri.parse('https://bridge.example'),
        accessTokenProvider: () async => 'token',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['route'], 'play');
          expect((body['input'] as Map)['dummy'], 'T9.876.5432.AKQ');
          expect((body['input'] as Map)['played'], 'D2');
          return http.Response('{"version":1,"decision":{"card":"S2"}}', 200);
        }),
      );
      final result = await gateway.get('/play',
          {..._validBid, 'dummy': 'T9.876.5432.AKQ', 'played': 'D2'});
      expect(result['card'], 'S2');
      gateway.close();
    });

    test('errors redact response body, hand, token and do not retry', () async {
      for (final status in [401, 403, 429, 503, 302]) {
        var calls = 0;
        final gateway = BenGatewayTransport(
          baseUri: Uri.parse('https://bridge.example'),
          accessTokenProvider: () async => 'private_session_token',
          client: MockClient((request) async {
            calls++;
            return http.Response(
              'PRIVATE SERVER LOG $_privateHand private_session_token',
              status,
              headers: status == 302
                  ? {'location': 'https://attacker.example/'}
                  : const <String, String>{},
            );
          }),
        );
        try {
          await gateway.get('/bid', _validBid);
          fail('Expected sanitized error');
        } on BenApiException catch (e) {
          expect(e.toString(), isNot(contains(_privateHand)));
          expect(e.toString(), isNot(contains('private_session_token')));
          expect(e.toString(), isNot(contains('PRIVATE SERVER LOG')));
          expect(e.kind, status == 429 ? 'rate_limit' :
              (status == 401 || status == 403 ? 'auth' : 'http'));
        } finally {
          expect(calls, 1);
          gateway.close();
        }
      }
    });

    test('invalid, wrong-version, oversize replies fail closed', () async {
      for (final response in [
        '{',
        '{"version":2,"decision":{"bid":"PASS"}}',
        '{"version":1,"decision":{"unknown":"PASS"}}',
        '{"version":1,"decision":{"error":"private"}}',
        '{"version":1,"decision":{"bid":"PASS","debug":"${List.filled(40000, 'x').join()}"}}',
      ]) {
        final gateway = BenGatewayTransport(
          baseUri: Uri.parse('https://bridge.example'),
          accessTokenProvider: () async => 'token',
          client: MockClient((request) async => http.Response(response, 200)),
        );
        await expectLater(gateway.get('/bid', _validBid),
            throwsA(isA<BenApiException>()));
        gateway.close();
      }
    });

    test('timeout is bounded and sanitized', () async {
      final gateway = BenGatewayTransport(
        baseUri: Uri.parse('https://bridge.example'),
        accessTokenProvider: () async => 'token',
        timeout: const Duration(milliseconds: 5),
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return http.Response('{"version":1,"decision":{"bid":"PASS"}}', 200);
        }),
      );
      await expectLater(gateway.get('/bid', _validBid),
          throwsA(predicate((e) =>
              e is BenApiException && e.kind == 'timeout')));
      gateway.close();
    });
  });
}
