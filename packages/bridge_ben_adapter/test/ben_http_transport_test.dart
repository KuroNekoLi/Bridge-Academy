import 'dart:async';
import 'dart:convert';
import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final origin = Uri.parse('http://127.0.0.1:8085');
  group('BEN HTTP transport with MockClient (NOT real BEN)', () {
    test('GET /bid sends encoded query and parses JSON', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/bid');
        expect(request.url.queryParameters['hand'], 'AKQ.JT9.876.5432');
        expect(request.url.queryParameters['ctx'], '1N-P');
        return http.Response(jsonEncode({'bid': 'PASS', 'who': 'NN'}), 200);
      });
      final transport = BenHttpTransport(baseUri: origin, client: client);
      final result = await transport.get('/bid',
          {'hand': 'AKQ.JT9.876.5432', 'ctx': '1N-P'});
      expect(result['bid'], 'PASS');
      transport.close();
    });

    test('HTTP failure redacts private hand from exception', () async {
      final client = MockClient((request) async =>
          http.Response('private content', 503));
      final transport = BenHttpTransport(baseUri: origin, client: client);
      try {
        await transport.get('/bid', {'hand': 'AKQ.JT9.876.5432'});
        fail('Expected failure');
      } on BenApiException catch (error) {
        expect(error.kind, 'http');
        expect(error.toString(), isNot(contains('AKQ.JT9.876.5432')));
        expect(error.toString(), isNot(contains('private content')));
      } finally {
        transport.close();
      }
    });

    test('malformed JSON, non-object and BEN error are rejected', () async {
      for (final response in ['not-json', '[]', '{"error":"private debug"}']) {
        final transport = BenHttpTransport(
            baseUri: origin,
            client: MockClient((request) async => http.Response(response, 200)));
        await expectLater(
          transport.get('/bid', {'hand': 'SECRET'}),
          throwsA(isA<BenApiException>()),
        );
        transport.close();
      }
    });

    test('request timeout yields sanitized exception', () async {
      final transport = BenHttpTransport(
        baseUri: origin,
        timeout: const Duration(milliseconds: 1),
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return http.Response('{"bid":"PASS"}', 200);
        }),
      );
      await expectLater(
        transport.get('/bid', {'hand': 'SECRET'}),
        throwsA(predicate((e) =>
            e is BenApiException && e.kind == 'timeout')),
      );
      transport.close();
    });

    test('unsupported route and invalid origin rejected early', () async {
      expect(
        () => BenHttpTransport(baseUri: Uri.parse('http://user:pass@host:80')),
        throwsArgumentError,
      );
      final transport = BenHttpTransport(
        baseUri: origin,
        client: MockClient((request) async => http.Response('{}', 200)),
      );
      await expectLater(
        transport.get('/autoplay', {'deal': 'PRIVATE'}),
        throwsA(isA<BenApiException>()),
      );
      transport.close();
    });
  });
}

