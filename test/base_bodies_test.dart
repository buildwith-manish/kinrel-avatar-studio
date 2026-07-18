import 'package:flutter_test/flutter_test.dart';
import 'package:kinrel_avatar_studio/registry/base_bodies.dart';

void main() {
  group('BaseBodies catalog', () {
    test('has exactly 12 entries', () {
      expect(kBaseBodies.length, 12);
    });

    test('entries are ordered by age-ascending, male-then-female', () {
      final ids = kBaseBodies.map((b) => b.id).toList();
      expect(ids, [
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
      ]);
    });

    test('every entry has matching id == folderName', () {
      for (final b in kBaseBodies) {
        expect(b.folderName, b.id);
      }
    });

    test('male bodies support facial hair, female bodies do not', () {
      for (final b in kBaseBodies) {
        expect(b.supportsFacialHair, b.gender == Gender.male);
      }
    });

    test('baseBodyById finds existing and returns null for unknown', () {
      expect(baseBodyById('adult_male')?.label, 'Adult Male');
      expect(baseBodyById('nonexistent'), isNull);
      expect(baseBodyById(null), isNull);
    });
  });
}
