import 'package:flutter/material.dart';

/// Shared color palette for the Avatar Studio editor.
///
/// Neutral, high-contrast surface colors so the avatar preview (which
/// may itself be colorful) stays the visual focus. Tints are deliberately
/// muted to read as "tool UI" rather than "consumer branding".
class AvatarStudioTheme {
  AvatarStudioTheme._();

  static const Color seed = Color(0xFF4F6F8F);

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDEFF3);

  static const Color textPrimary = Color(0xFF1A1F2B);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textDisabled = Color(0xFFA8AEC0);

  static const Color selected = Color(0xFF2D6CDF);
  static const Color selectedSoft = Color(0xFFE3EDFD);
  static const Color divider = Color(0xFFE2E5EB);

  /// Fixed aspect ratio of the avatar canvas. All source PNGs MUST be
  /// 1024×1536 (2:3). The renderer uses this ratio so the avatar
  /// displays identically at thumbnail, editor, and profile sizes.
  static const double canvasAspectRatio = 1024.0 / 1536.0;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        primary: selected,
        secondary: selected,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      dividerColor: divider,
      cardTheme: const CardTheme(
        color: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: divider),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: selected,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}
