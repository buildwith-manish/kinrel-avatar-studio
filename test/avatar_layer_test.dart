import 'package:flutter_test/flutter_test.dart';
import 'package:kinrel_avatar_studio/models/avatar_layer.dart';

void main() {
  group('AvatarLayer', () {
    test('has exactly 9 layers in the spec-required order', () {
      expect(AvatarLayer.values.length, 9);
      expect(AvatarLayer.values[0], AvatarLayer.baseBody);
      expect(AvatarLayer.values[1], AvatarLayer.clothing);
      expect(AvatarLayer.values[2], AvatarLayer.faceDetail);
      expect(AvatarLayer.values[3], AvatarLayer.hair);
      expect(AvatarLayer.values[4], AvatarLayer.facialHair);
      expect(AvatarLayer.values[5], AvatarLayer.eyesEyebrows);
      expect(AvatarLayer.values[6], AvatarLayer.earrings);
      expect(AvatarLayer.values[7], AvatarLayer.glasses);
      expect(AvatarLayer.values[8], AvatarLayer.accessories);
    });

    test('only accessories allow multiple selections', () {
      for (final l in AvatarLayer.values) {
        expect(l.allowsMultiple, l == AvatarLayer.accessories);
      }
    });

    test('V1-skipped layers are faceDetail and eyesEyebrows', () {
      expect(AvatarLayer.faceDetail.isV1Skipped, isTrue);
      expect(AvatarLayer.eyesEyebrows.isV1Skipped, isTrue);
      expect(AvatarLayer.baseBody.isV1Skipped, isFalse);
      expect(AvatarLayer.hair.isV1Skipped, isFalse);
    });

    test('wireKey is stable snake_case', () {
      expect(AvatarLayer.baseBody.wireKey, 'base_body');
      expect(AvatarLayer.facialHair.wireKey, 'facial_hair');
      expect(AvatarLayer.eyesEyebrows.wireKey, 'eyes_eyebrows');
    });

    test('every layer has a non-empty label', () {
      for (final l in AvatarLayer.values) {
        expect(l.label.isNotEmpty, isTrue);
      }
    });
  });
}
