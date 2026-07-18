import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinrel_avatar_studio/models/avatar_config.dart';
import 'package:kinrel_avatar_studio/models/avatar_layer.dart';
import 'package:kinrel_avatar_studio/registry/base_bodies.dart';
import 'package:kinrel_avatar_studio/widgets/placeholder_layer.dart';

/// Tests for the V1 standardized-artwork integration.
///
/// These tests verify the contract that:
///   1. All 12 base bodies are cataloged (no regression after rename).
///   2. The `AvatarLayer` stack order matches the spec.
///   3. The placeholder fallback colors are stable (used when a PNG
///      is missing — important for future layers like glasses/hats
///      that don't have artwork yet).
///   4. `AvatarConfig.v1Default()` selects a body that has a real PNG.
void main() {
  group('Standardized base bodies integration', () {
    test('all 12 base bodies have stable IDs matching on-disk folders', () {
      // The IDs below are the persistence contract — they appear in
      // saved AvatarConfig JSON and must never change without a
      // migration. If this test fails, you have renamed a body ID
      // and broken saved-avatar compatibility.
      final expectedIds = {
        'child_male',
        'child_female',
        'preteen_male',
        'preteen_female',
        'teen_male',
        'teen_female',
        'adult_male',
        'adult_female',
        'middle_male',
        'middle_female',
        'elderly_male',
        'elderly_female',
      };
      final actualIds = kBaseBodies.map((b) => b.id).toSet();
      expect(actualIds, expectedIds);
    });

    test('every base body ID is non-empty and snake_case', () {
      for (final b in kBaseBodies) {
        expect(b.id.isNotEmpty, isTrue, reason: '${b.label} has empty id');
        expect(RegExp(r'^[a-z]+_[a-z]+$').hasMatch(b.id), isTrue,
            reason: '${b.label} id "${b.id}" is not snake_case');
      }
    });

    test('v1Default selects adult_male which has a real PNG on disk', () {
      // The default config must point at a body that ships with a
      // real body.png so the editor's first paint shows artwork, not
      // a placeholder rectangle.
      final defaultConfig = AvatarConfig.v1Default();
      expect(defaultConfig.baseBodyId, 'adult_male');
      // The actual PNG presence is verified by the renderer at runtime
      // via AssetManifest; here we just confirm the ID is one of the
      // 12 cataloged bodies.
      expect(baseBodyById(defaultConfig.baseBodyId), isNotNull);
    });

    test('placeholder colors are stable per layer (fallback contract)', () {
      // When a real PNG is missing, the renderer falls back to
      // PlaceholderLayer.colorFor(layer). These colors must stay
      // stable across versions because users may screenshot the
      // editor and reference specific colors when reporting bugs.
      expect(PlaceholderLayer.colorFor(AvatarLayer.baseBody),
          const Color(0xFFF2C9A0));
      expect(PlaceholderLayer.colorFor(AvatarLayer.clothing),
          const Color(0xFF7BA7D9));
      expect(PlaceholderLayer.colorFor(AvatarLayer.hair),
          const Color(0xFF4A2C2A));
      expect(PlaceholderLayer.colorFor(AvatarLayer.facialHair),
          const Color(0xFF6B4226));
      expect(PlaceholderLayer.colorFor(AvatarLayer.earrings),
          const Color(0xFFE0C36B));
      expect(PlaceholderLayer.colorFor(AvatarLayer.glasses),
          const Color(0xFF37474F));
      expect(PlaceholderLayer.colorFor(AvatarLayer.accessories),
          const Color(0xFF8E6E53));
    });

    test('V1 renderer skips V2 layers even if config references them', () {
      // A saved config from a future version might contain a face_detail
      // or eyes_eyebrows ID. The V1 renderer must silently ignore it
      // rather than crash. This is enforced by AvatarLayer.isV1Skipped.
      expect(AvatarLayer.faceDetail.isV1Skipped, isTrue);
      expect(AvatarLayer.eyesEyebrows.isV1Skipped, isTrue);
      // All other layers must NOT be skipped.
      for (final l in AvatarLayer.values) {
        if (l == AvatarLayer.faceDetail || l == AvatarLayer.eyesEyebrows) {
          continue;
        }
        expect(l.isV1Skipped, isFalse, reason: '${l.name} should not be V1-skipped');
      }
    });

    test('switching base body to female clears facial hair selection', () {
      // AvatarEditorScreen enforces this on body change — here we
      // replicate the same copyWith logic to lock in the contract.
      final male = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        facialHairId: 'beard_full',
      );
      // Simulate switching to a female body — facial hair must be dropped.
      final female = male.copyWith(
        baseBodyId: 'adult_female',
        facialHairId: baseBodyById('adult_female')!.supportsFacialHair
            ? male.facialHairId
            : null,
      );
      expect(female.baseBodyId, 'adult_female');
      expect(female.facialHairId, isNull);
    });
  });
}
