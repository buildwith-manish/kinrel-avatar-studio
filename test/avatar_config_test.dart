import 'package:flutter_test/flutter_test.dart';
import 'package:kinrel_avatar_studio/models/avatar_config.dart';

void main() {
  group('AvatarConfig', () {
    test('v1Default has expected initial values', () {
      final c = AvatarConfig.v1Default();
      expect(c.baseBodyId, 'adult_male');
      expect(c.skinToneId, 'tone_1');
      expect(c.clothingId, 'default');
      expect(c.hairId, isNull);
      expect(c.facialHairId, isNull);
      expect(c.glassesId, isNull);
      expect(c.earringsId, isNull);
      expect(c.accessoryIds, isEmpty);
    });

    test('toJson includes schema envelope and omits null optionals', () {
      const c = AvatarConfig(
        baseBodyId: 'teen_female',
        skinToneId: 'tone_2',
        clothingId: 'hoodie_amber',
      );
      final json = c.toJson();
      expect(json['schema'], 'kinrel.avatar_config');
      expect(json['schema_version'], 1);
      expect(json['base_body'], 'teen_female');
      expect(json['skin_tone'], 'tone_2');
      expect(json['clothing'], 'hoodie_amber');
      expect(json.containsKey('hair'), isFalse);
      expect(json.containsKey('facial_hair'), isFalse);
      expect(json.containsKey('glasses'), isFalse);
      expect(json.containsKey('earrings'), isFalse);
      expect(json['accessories'], isEmpty);
    });

    test('toJson includes optionals when set', () {
      const c = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_3',
        clothingId: 'kurta_white',
        hairId: 'curly_black',
        facialHairId: 'beard_full',
        glassesId: 'round_black',
        earringsId: 'stud_gold',
        accessoryIds: ['watch_silver', 'hat_cap'],
      );
      final json = c.toJson();
      expect(json['hair'], 'curly_black');
      expect(json['facial_hair'], 'beard_full');
      expect(json['glasses'], 'round_black');
      expect(json['earrings'], 'stud_gold');
      expect(json['accessories'], ['watch_silver', 'hat_cap']);
    });

    test('fromJson round-trips toJson for a fully-populated config', () {
      const original = AvatarConfig(
        baseBodyId: 'elderly_female',
        skinToneId: 'tone_5',
        clothingId: 'sari_red',
        hairId: 'bun_grey',
        facialHairId: null,
        glassesId: 'cat_eye',
        earringsId: 'hoop_gold',
        accessoryIds: ['necklace_pearl'],
      );
      final roundTripped = AvatarConfig.fromJson(original.toJson());
      expect(roundTripped, original);
    });

    test('fromJson tolerates missing optional keys (forward compat)', () {
      final minimal = <String, dynamic>{
        'schema': 'kinrel.avatar_config',
        'schema_version': 1,
        'base_body': 'child_male',
        'skin_tone': 'tone_1',
        'clothing': 'default',
      };
      final c = AvatarConfig.fromJson(minimal);
      expect(c.baseBodyId, 'child_male');
      expect(c.hairId, isNull);
      expect(c.accessoryIds, isEmpty);
    });

    test('fromJson defaults missing required keys to v1 default', () {
      final empty = <String, dynamic>{};
      final c = AvatarConfig.fromJson(empty);
      expect(c.baseBodyId, 'adult_male');
      expect(c.skinToneId, 'tone_1');
      expect(c.clothingId, 'default');
    });

    test('copyWith preserves untouched fields and updates provided ones', () {
      const base = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        hairId: 'short_black',
      );
      final updated = base.copyWith(glassesId: 'aviator');
      expect(updated.baseBodyId, 'adult_male');
      expect(updated.clothingId, 'default');
      expect(updated.hairId, 'short_black');
      expect(updated.glassesId, 'aviator');
    });

    test('copyWith can explicitly set a nullable field to null', () {
      const base = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        hairId: 'short_black',
      );
      final cleared = base.copyWith(hairId: null);
      expect(cleared.hairId, isNull);
    });

    test('equality treats same field values as equal', () {
      const a = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        accessoryIds: ['watch_silver', 'hat_cap'],
      );
      const b = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        accessoryIds: ['watch_silver', 'hat_cap'],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equality is sensitive to accessory order', () {
      const a = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        accessoryIds: ['watch_silver', 'hat_cap'],
      );
      const b = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
        accessoryIds: ['hat_cap', 'watch_silver'],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
