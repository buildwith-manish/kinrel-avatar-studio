import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_config.dart';

/// Local persistence layer for [AvatarConfig].
///
/// V1 strategy (per spec): "Add local storage (SharedPreferences or similar)
/// so a user's avatar choice survives app restart — still no backend needed
/// yet."
///
/// This class is the only thing that talks to SharedPreferences. The
/// editor and main entry point go through it, so swapping the persistence
/// backend to Supabase later means changing only this file (plus the
/// call sites that pass a userId).
///
/// Schema versioning:
///   The stored JSON includes `schema` and `schema_version` fields (see
///   [AvatarConfig.toJson]). On load, we tolerate any older schema_version
///   and let [AvatarConfig.fromJson] handle missing keys. If a future
///   version introduces a breaking schema change, bump the version and
///   add a migration step here before calling [AvatarConfig.fromJson].
class AvatarStorage {
  AvatarStorage._();

  /// SharedPreferences key under which the current avatar config JSON is
  /// stored. Namespaced with `kinrel.` to avoid collisions with other
  /// apps/libraries that might share a SharedPreferences instance.
  static const String _key = 'kinrel.avatar_config.v1';

  /// Loads the saved avatar config, or null if none has been saved yet
  /// (or if the stored JSON is corrupt / fails to deserialize).
  ///
  /// Never throws — corrupt prefs are logged in debug mode and treated
  /// as "no saved config", so the caller falls back to
  /// [AvatarConfig.v1Default].
  static Future<AvatarConfig?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        if (kDebugMode) {
          debugPrint('[AvatarStorage] stored JSON is not an object: $decoded');
        }
        return null;
      }
      return AvatarConfig.fromJson(decoded);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AvatarStorage] load failed: $e\n$st');
      }
      return null;
    }
  }

  /// Persists the given config. Returns true on success, false on failure
  /// (e.g. SharedPreferences unavailable on the platform).
  ///
  /// Never throws — callers can simply `await AvatarStorage.save(config)`
  /// without try/catch and check the bool result.
  static Future<bool> save(AvatarConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(config.toJson());
      final ok = await prefs.setString(_key, json);
      if (kDebugMode) {
        debugPrint('[AvatarStorage] saved (${ok ? "ok" : "FAIL"}): $json');
      }
      return ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AvatarStorage] save failed: $e\n$st');
      }
      return false;
    }
  }

  /// Clears the stored config. Useful for a "Reset to default" button or
  /// for testing.
  static Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AvatarStorage] clear failed: $e\n$st');
      }
      return false;
    }
  }

  /// Returns true if a config is currently stored. Cheaper than [load]
  /// when the caller only needs to know whether to show a "Reset saved
  /// avatar" affordance.
  static Future<bool> hasSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return raw != null && raw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
