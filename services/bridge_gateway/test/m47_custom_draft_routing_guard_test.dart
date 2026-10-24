import 'dart:convert';
import 'dart:io';

import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

Future<({int status, Map<String, dynamic> result})> request(
    int port, Map<String, Object?> body) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/v1/sessions/anonymous'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(body));
    final res = await req.close();
    return (
      status: res.statusCode,
      result: jsonDecode(await utf8.decoder.bind(res).join())
          as Map<String, dynamic>,
    );
  } finally {
    client.close(force: true);
  }
}

void main() {
  test('M4.7 Gateways reject local convention IDs and forged engine approvals',
      () async {
    final draft = CustomConventionDraft.create(
      id: 'local_sayc',
      label: 'My SAYC',
      base: ConventionCatalog.sayc,
    ).withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '13_15',
    ));
    final server = BridgeGatewayService(
      backend: const UnavailableDecisionBackend(),
    );
    final port = await server.start();
    try {
      for (final forged in <Map<String, Object?>>[
        {'northSouth': draft.id, 'eastWest': 'BA-SAYC'},
        {'northSouth': 'BA-21GF', 'eastWest': draft.id},
        {
          'northSouth': draft.id,
          'eastWest': 'BA-SAYC',
          'fingerprint': draft.fingerprint,
          'runtimeSupport': 'SUPPORTED',
        },
        {
          'northSouth': 'BA-SAYC', 'eastWest': 'BA-21GF',
          'customDraft': draft.toJson(),
        },
      ]) {
        final result = await request(port, {
          'version': 1, 'game_systems': forged,
        });
        expect(result.status, 400);
        expect(result.result['error'], isA<Map>());
        expect(result.result.containsKey('access_token'), false);
      }
      expect(ConventionCatalog.resolve(draft.id, draft.revision), isNull);
      expect(draft.isPlayableCustomSystem, false);
    } finally {
      await server.close();
    }
  });

  test('M4.7 imported archive cannot turn into trusted game profile', () {
    final first = CustomConventionDraft.create(
        id: 'local_21gf', label: 'My 2/1',
        base: ConventionCatalog.twoOverOne);
    final second = first.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final archive = CustomConventionArchive.empty()
        .append(first).append(second);
    final restored = CustomConventionArchive.fromJson(archive.toJson());
    expect(restored.latest!.isPlayableCustomSystem, false);
    expect(CustomConventionReviewer.assess(restored.latest!)
        .canUseAsAiSystem, false);
    expect(() => PartnershipSystem.fromTrustedJson({
      ...ConventionCatalog.twoOverOne.toJson(),
      'profileId': restored.latest!.id,
      'revision': restored.latest!.revision,
      'profileFingerprint': restored.latest!.fingerprint,
    }), throwsFormatException);
  });
}
