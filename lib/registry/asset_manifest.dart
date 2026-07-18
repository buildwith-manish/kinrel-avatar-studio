import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

import '../models/avatar_layer.dart';
import 'base_bodies.dart';

/// Centralized lookup for avatar asset paths.
///
/// Why this exists:
///   The user's spec requires that "the code should read filenames
///   dynamically from each folder, not hardcode a fixed list". Flutter
///   bundles assets at build time and exposes them via the auto-generated
///   `AssetManifest.json`. This class loads that manifest once and
///   exposes folder-scoped queries so any new PNG dropped into an avatar
///   folder is automatically picked up after a rebuild — no code changes
///   needed.
///
/// Usage:
///   ```dart
///   final manifest = await AssetManifest.load();
///   final hairs = manifest.listIds(AvatarLayer.hair, gender: Gender.male);
///   final bodyPath = manifest.baseBodyPath('adult_male');
///   ```
class AssetManifest {
  AssetManifest._(this._entries);

  /// All asset paths declared in `pubspec.yaml`, indexed for fast prefix
  /// lookup. Each entry is a full asset path like
  /// `assets/avatars/hair/male/curly_black.png`.
  final Set<String> _entries;

  /// Loads the bundled `AssetManifest.json` produced by Flutter at build
  /// time. Safe to call multiple times — call sites should cache the
  /// returned instance.
  static Future<AssetManifest> load() async {
    final String raw = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
    final entries = decoded.keys.toSet();
    if (kDebugMode) {
      debugPrint('[AssetManifest] loaded ${entries.length} bundled assets');
    }
    return AssetManifest._(entries);
  }

  /// Returns the asset path for a base body's `body.png`, or null when
  /// the file is not bundled (yet). This lets the renderer fall back to
  /// a placeholder rectangle without crashing.
  String? baseBodyPath(String baseBodyId) {
    final path = 'assets/avatars/base/$baseBodyId/body.png';
    return _entries.contains(path) ? path : null;
  }

  /// Lists all asset IDs (filename without extension) available for a
  /// given layer. For gendered layers (hair, facial hair), pass [gender]
  /// to scope the search to the correct subfolder.
  ///
  /// Returns IDs in alphabetical order for stable picker ordering.
  List<String> listIds(AvatarLayer layer, {Gender? gender}) {
    final String prefix = _folderPrefix(layer, gender: gender);
    final matches = _entries
        .where((p) => p.startsWith(prefix) && p.toLowerCase().endsWith('.png'))
        .toList()
      ..sort();
    return matches.map(_idFromPath).where((id) => id.isNotEmpty).toList();
  }

  /// Resolves a single layer asset to its full asset path, or null if
  /// the ID is not present in the bundle. Used by [AvatarRenderer] to
  /// gracefully skip missing layers.
  String? resolveLayerPath(
    AvatarLayer layer, {
    required String id,
    Gender? gender,
  }) {
    final String prefix = _folderPrefix(layer, gender: gender);
    // Try common extensions in priority order.
    for (final ext in const ['.png', '.webp']) {
      final candidate = '$prefix$id$ext';
      if (_entries.contains(candidate)) return candidate;
    }
    return null;
  }

  /// Resolves a base-body's default clothing path, if any. V1 convention:
  ///   `assets/avatars/clothing/default/<baseBodyId>_default.png`
  /// Returns null when not present (renderer falls back to a placeholder).
  String? defaultClothingPath(String baseBodyId) {
    final path = 'assets/avatars/clothing/default/${baseBodyId}_default.png';
    return _entries.contains(path) ? path : null;
  }

  /// Folder prefix used to scope [listIds] and [resolveLayerPath] for a
  /// given layer + optional gender.
  ///
  /// Keep this mapping in sync with the folder structure documented in
  /// `assets/avatars/ANCHOR_SPEC.md` and declared in `pubspec.yaml`.
  static String _folderPrefix(AvatarLayer layer, {Gender? gender}) {
    switch (layer) {
      case AvatarLayer.baseBody:
        return 'assets/avatars/base/';
      case AvatarLayer.clothing:
        // V1: clothing is flat under `clothing/default/`. Future: sub-
        // categorize into tops/bottoms/dresses_kurtas with a category
        // prefix appended to the ID (e.g. "tops/hoodie_amber").
        return 'assets/avatars/clothing/default/';
      case AvatarLayer.faceDetail:
        return 'assets/avatars/face_detail/'; // V2
      case AvatarLayer.hair:
        final g = gender == Gender.female ? 'female' : 'male';
        return 'assets/avatars/hair/$g/';
      case AvatarLayer.facialHair:
        return 'assets/avatars/facial_hair/';
      case AvatarLayer.eyesEyebrows:
        return 'assets/avatars/eyes_eyebrows/'; // V2
      case AvatarLayer.earrings:
        return 'assets/avatars/earrings/';
      case AvatarLayer.glasses:
        return 'assets/avatars/glasses/';
      case AvatarLayer.accessories:
        return 'assets/avatars/accessories/';
    }
  }

  /// Extracts the asset ID (filename without extension) from a full
  /// asset path. Returns empty string when the path is not a file.
  static String _idFromPath(String path) {
    final slash = path.lastIndexOf('/');
    final filePart = slash >= 0 ? path.substring(slash + 1) : path;
    final dot = filePart.lastIndexOf('.');
    return dot >= 0 ? filePart.substring(0, dot) : filePart;
  }
}
