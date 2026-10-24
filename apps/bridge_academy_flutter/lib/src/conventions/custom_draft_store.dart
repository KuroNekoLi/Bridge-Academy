import 'dart:convert';

import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nonsecret personal card preferences stored only on this device/browser.
/// This is NOT a secure credential store, cross-device sync, or live AI config.
abstract interface class CustomDraftStorage {
  Future<CustomConventionArchive> load(String baseProfileId);
  Future<void> save(String baseProfileId, CustomConventionArchive archive);
}

final class SharedPrefsCustomDraftStorage implements CustomDraftStorage {
  static const _prefix = 'ba_custom_convention_local_v1_';

  @override
  Future<CustomConventionArchive> load(String baseProfileId) async {
    _checkBase(baseProfileId);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$baseProfileId');
    if (raw == null) return CustomConventionArchive.empty();
    // Corrupt or forged data intentionally fails closed instead of
    // silently resetting someone's existing convention card.
    return CustomConventionArchive.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> save(
      String baseProfileId, CustomConventionArchive archive) async {
    _checkBase(baseProfileId);
    if (archive.latest?.base.profileId != baseProfileId) {
      throw const FormatException('Wrong custom card base');
    }
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
        '$_prefix$baseProfileId', jsonEncode(archive.toJson()));
    if (!success) {
      throw StateError('Failed to persist convention card');
    }
  }

  static void _checkBase(String id) {
    if (id != 'BA-SAYC' && id != 'BA-21GF') {
      throw const FormatException('Invalid local convention base');
    }
  }
}
