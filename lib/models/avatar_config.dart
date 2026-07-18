import 'package:flutter/foundation.dart';

import 'avatar_layer.dart';

/// Immutable snapshot of a user's avatar selections.
///
/// Stores only selected asset **IDs** (filenames without extension),
/// never the resolved file paths or the images themselves. This keeps
/// the model:
///   - Tiny and serializable (will live in a `jsonb` column on the
///     Person/User table when merged into Kinrel's Supabase backend).
///   - Backend-agnostic — same JSON works for local state, remote
///     persistence, and import/export.
///   - Resolution-independent — the actual asset paths are looked up
///     at render time via [AssetManifest], so renaming or relocating
///     a PNG file does not break saved configs as long as the ID stays
///     stable.
///
/// Stability contract:
///   The JSON shape produced by [toJson] is the persistence contract.
///   Add new optional fields only — never rename or remove existing
///   ones — so older saved avatars keep loading in newer builds.
@immutable
class AvatarConfig {
  /// Base body ID, e.g. `"adult_male"`. Corresponds to a folder name
  /// under `assets/avatars/base/<baseBodyId>/body.png`.
  final String baseBodyId;

  /// Skin tone variant ID, e.g. `"tone_3"`. V1 placeholder only — the
  /// tone-tinting pipeline is not implemented yet, this field is
  /// round-tripped through JSON but does not change rendering.
  final String skinToneId;

  /// Clothing outfit ID, e.g. `"hoodie_amber"`. Resolved by
  /// [AssetManifest] to a PNG in `assets/avatars/clothing/...`.
  final String clothingId;

  /// Hair ID, e.g. `"curly_black"`. Nullable — when null, no hair
  /// layer is rendered (base body's default hairline remains visible).
  final String? hairId;

  /// Facial hair ID, e.g. `"beard_full"`. Nullable + male only.
  /// The renderer skips this layer silently if the base body is female.
  final String? facialHairId;

  /// Glasses ID. Nullable.
  final String? glassesId;

  /// Earrings ID. Nullable.
  final String? earringsId;

  /// Accessories (watch, necklace, hat, etc.). Multiple allowed —
  /// rendered in declared order, above all other layers.
  final List<String> accessoryIds;

  const AvatarConfig({
    required this.baseBodyId,
    required this.skinToneId,
    required this.clothingId,
    this.hairId,
    this.facialHairId,
    this.glassesId,
    this.earringsId,
    this.accessoryIds = const [],
  });

  /// V1 default config — adult male, default skin tone, default
  /// clothing, no optional layers. Used as the editor's initial state.
  factory AvatarConfig.v1Default() => const AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        hairId: null,
        facialHairId: null,
        glassesId: null,
        earringsId: null,
        accessoryIds: [],
      );

  /// Returns a copy with the given fields replaced. Used by the editor
  /// to produce immutable updates on each selection change.
  AvatarConfig copyWith({
    String? baseBodyId,
    String? skinToneId,
    String? clothingId,
    Object? hairId = _sentinel,
    Object? facialHairId = _sentinel,
    Object? glassesId = _sentinel,
    Object? earringsId = _sentinel,
    List<String>? accessoryIds,
  }) {
    return AvatarConfig(
      baseBodyId: baseBodyId ?? this.baseBodyId,
      skinToneId: skinToneId ?? this.skinToneId,
      clothingId: clothingId ?? this.clothingId,
      hairId: identical(hairId, _sentinel) ? this.hairId : hairId as String?,
      facialHairId: identical(facialHairId, _sentinel)
          ? this.facialHairId
          : facialHairId as String?,
      glassesId: identical(glassesId, _sentinel)
          ? this.glassesId
          : glassesId as String?,
      earringsId: identical(earringsId, _sentinel)
          ? this.earringsId
          : earringsId as String?,
      accessoryIds: accessoryIds ?? this.accessoryIds,
    );
  }

  /// Serialization for Supabase `jsonb` persistence.
  ///
  /// Shape:
  /// ```json
  /// {
  ///   "schema": "kinrel.avatar_config",
  ///   "schema_version": 1,
  ///   "base_body": "adult_male",
  ///   "skin_tone": "tone_1",
  ///   "clothing": "hoodie_amber",
  ///   "hair": "curly_black",          // omitted when null
  ///   "facial_hair": "beard_full",    // omitted when null
  ///   "glasses": "round_black",       // omitted when null
  ///   "earrings": "stud_gold",        // omitted when null
  ///   "accessories": ["watch_silver", "hat_cap"]
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'schema': 'kinrel.avatar_config',
      'schema_version': 1,
      AvatarLayer.baseBody.wireKey: baseBodyId,
      'skin_tone': skinToneId,
      AvatarLayer.clothing.wireKey: clothingId,
      AvatarLayer.accessories.wireKey: List<String>.from(accessoryIds),
    };
    if (hairId != null) json[AvatarLayer.hair.wireKey] = hairId;
    if (facialHairId != null) {
      json[AvatarLayer.facialHair.wireKey] = facialHairId;
    }
    if (glassesId != null) json[AvatarLayer.glasses.wireKey] = glassesId;
    if (earringsId != null) json[AvatarLayer.earrings.wireKey] = earringsId;
    return json;
  }

  /// Deserialization. Tolerant of missing keys (so older saves load
  /// cleanly when new optional layers are added in future versions).
  factory AvatarConfig.fromJson(Map<String, dynamic> json) {
    return AvatarConfig(
      baseBodyId: json[AvatarLayer.baseBody.wireKey] as String? ?? 'adult_male',
      skinToneId: json['skin_tone'] as String? ?? 'tone_1',
      clothingId: json[AvatarLayer.clothing.wireKey] as String? ?? 'default',
      hairId: json[AvatarLayer.hair.wireKey] as String?,
      facialHairId: json[AvatarLayer.facialHair.wireKey] as String?,
      glassesId: json[AvatarLayer.glasses.wireKey] as String?,
      earringsId: json[AvatarLayer.earrings.wireKey] as String?,
      accessoryIds: (json[AvatarLayer.accessories.wireKey] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Convenience: returns the selected ID for a given layer, or null
  /// when the layer is optional and unselected. For [AvatarLayer.accessories]
  /// (which allows multiple), returns the first ID or null if empty.
  String? idFor(AvatarLayer layer) {
    switch (layer) {
      case AvatarLayer.baseBody:
        return baseBodyId;
      case AvatarLayer.clothing:
        return clothingId;
      case AvatarLayer.faceDetail:
        return null; // V2
      case AvatarLayer.hair:
        return hairId;
      case AvatarLayer.facialHair:
        return facialHairId;
      case AvatarLayer.eyesEyebrows:
        return null; // V2
      case AvatarLayer.earrings:
        return earringsId;
      case AvatarLayer.glasses:
        return glassesId;
      case AvatarLayer.accessories:
        return accessoryIds.isEmpty ? null : accessoryIds.first;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AvatarConfig) return false;
    return baseBodyId == other.baseBodyId &&
        skinToneId == other.skinToneId &&
        clothingId == other.clothingId &&
        hairId == other.hairId &&
        facialHairId == other.facialHairId &&
        glassesId == other.glassesId &&
        earringsId == other.earringsId &&
        listEquals(accessoryIds, other.accessoryIds);
  }

  @override
  int get hashCode => Object.hash(
        baseBodyId,
        skinToneId,
        clothingId,
        hairId,
        facialHairId,
        glassesId,
        earringsId,
        Object.hashAll(accessoryIds),
      );

  @override
  String toString() => 'AvatarConfig(${toJson()})';
}

/// Sentinel used by [AvatarConfig.copyWith] to distinguish "not provided"
/// from "explicitly set to null" for nullable fields.
const Object _sentinel = Object();
