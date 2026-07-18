import 'package:flutter_test/flutter_test.dart';
import 'package:kinrel_avatar_studio/models/avatar_config.dart';
import 'package:kinrel_avatar_studio/registry/avatar_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for [AvatarStorage].
///
/// These tests use `SharedPreferences.setMockInitialValues({})` to provide
/// an in-memory SharedPreferences instance — required for unit testing
/// code that depends on the platform channel that SharedPreferences uses
/// to talk to Android/iOS.
void main() {
  setUp(() {
    // Empty map = no saved values. Each test starts with a clean slate.
    SharedPreferences.setMockInitialValues({});
  });

  group('AvatarStorage', () {
    test('load returns null when nothing is saved', () async {
      expect(await AvatarStorage.load(), isNull);
    });

    test('hasSavedConfig returns false when nothing is saved', () async {
      expect(await AvatarStorage.hasSavedConfig(), isFalse);
    });

    test('save persists the config and load round-trips it', () async {
      const original = AvatarConfig(
        baseBodyId: 'teen_female',
        skinToneId: 'tone_3',
        clothingId: 'default',
        hairId: 'long_straight',
        glassesId: 'round_black',
        accessoryIds: ['pendant_necklace'],
      );
      final savedOk = await AvatarStorage.save(original);
      expect(savedOk, isTrue);

      expect(await AvatarStorage.hasSavedConfig(), isTrue);

      final loaded = await AvatarStorage.load();
      expect(loaded, isNotNull);
      expect(loaded!.baseBodyId, 'teen_female');
      expect(loaded.skinToneId, 'tone_3');
      expect(loaded.clothingId, 'default');
      expect(loaded.hairId, 'long_straight');
      expect(loaded.glassesId, 'round_black');
      expect(loaded.accessoryIds, ['pendant_necklace']);
      // Full equality check — should round-trip exactly.
      expect(loaded, original);
    });

    test('save overwrites the previous saved config', () async {
      const first = AvatarConfig(
        baseBodyId: 'adult_male',
        skinToneId: 'tone_1',
        clothingId: 'default',
      );
      const second = AvatarConfig(
        baseBodyId: 'elderly_female',
        skinToneId: 'tone_5',
        clothingId: 'default',
        hairId: 'hair_bun',
      );
      await AvatarStorage.save(first);
      await AvatarStorage.save(second);

      final loaded = await AvatarStorage.load();
      expect(loaded!.baseBodyId, 'elderly_female');
      expect(loaded.hairId, 'hair_bun');
    });

    test('clear removes the saved config', () async {
      await AvatarStorage.save(AvatarConfig.v1Default());
      expect(await AvatarStorage.hasSavedConfig(), isTrue);

      final clearedOk = await AvatarStorage.clear();
      expect(clearedOk, isTrue);
      expect(await AvatarStorage.hasSavedConfig(), isFalse);
      expect(await AvatarStorage.load(), isNull);
    });

    test('clear is a no-op when nothing is saved (returns true)', () async {
      expect(await AvatarStorage.clear(), isTrue);
      expect(await AvatarStorage.load(), isNull);
    });

    test('v1Default round-trips through storage', () async {
      // Sanity check that the default config (used as initial editor state
      // and as the reset target) survives persistence without loss.
      final original = AvatarConfig.v1Default();
      await AvatarStorage.save(original);
      final loaded = await AvatarStorage.load();
      expect(loaded, original);
    });

    test(
      'load tolerates corrupt stored JSON (returns null, no throw)',
      () async {
        // Simulate a corrupt prefs entry by writing raw garbage under the
        // same key AvatarStorage uses.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('kinrel.avatar_config.v1', 'not valid json {{{');
        expect(await AvatarStorage.load(), isNull);
      },
    );

    test('load tolerates stored JSON that is not an object', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kinrel.avatar_config.v1', '"a plain string"');
      expect(await AvatarStorage.load(), isNull);
    });

    test('load tolerates stored JSON missing required keys', () async {
      // Forward-compat: a future schema might write a JSON missing some
      // V1 keys. The storage layer must not crash; fromJson defaults
      // missing required keys to v1Default values.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'kinrel.avatar_config.v1',
        '{"schema":"kinrel.avatar_config","schema_version":99}',
      );
      final loaded = await AvatarStorage.load();
      expect(loaded, isNotNull);
      expect(loaded!.baseBodyId, 'adult_male');
      expect(loaded.clothingId, 'default');
    });
  });
}
