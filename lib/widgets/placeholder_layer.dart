import 'package:flutter/material.dart';

import '../models/avatar_layer.dart';

/// A placeholder layer painted in place of a missing PNG asset.
///
/// V1 strategy (per spec):
///   "Working Flutter app that runs on Android emulator/device, showing
///    the editor screen with placeholder colored rectangles standing in
///    for each asset (since actual PNGs will be added after this scaffold
///    is built)."
///
/// Each layer gets a distinct, stable color so the user can visually
/// confirm the stack order is correct. When a real PNG is later dropped
/// into the corresponding asset folder, [AvatarRenderer] picks it up
/// automatically via [AssetManifest] and the placeholder disappears.
class PlaceholderLayer extends StatelessWidget {
  const PlaceholderLayer({super.key, required this.layer, this.label});

  final AvatarLayer layer;
  final String? label;

  /// Stable, distinguishable color per layer. Chosen so adjacent layers
  /// in the stack have visibly different hues.
  static Color colorFor(AvatarLayer layer) {
    switch (layer) {
      case AvatarLayer.baseBody:
        return const Color(0xFFF2C9A0); // skin peach
      case AvatarLayer.clothing:
        return const Color(0xFF7BA7D9); // denim blue
      case AvatarLayer.faceDetail:
        return const Color(0xFFE8B4D8); // soft pink (V2)
      case AvatarLayer.hair:
        return const Color(0xFF4A2C2A); // dark brown
      case AvatarLayer.facialHair:
        return const Color(0xFF6B4226); // medium brown
      case AvatarLayer.eyesEyebrows:
        return const Color(0xFF2E4057); // slate (V2)
      case AvatarLayer.earrings:
        return const Color(0xFFE0C36B); // gold
      case AvatarLayer.glasses:
        return const Color(0xFF37474F); // dark slate
      case AvatarLayer.accessories:
        return const Color(0xFF8E6E53); // leather brown
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(layer);
    return Positioned.fill(
      child: CustomPaint(
        painter: _PlaceholderPainter(color: color, label: label ?? layer.label),
      ),
    );
  }
}

class _PlaceholderPainter extends CustomPainter {
  _PlaceholderPainter({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    // Fill the entire canvas with a translucent version of the layer
    // color, so layered placeholders stack visibly without hiding
    // lower layers entirely.
    final paint = Paint()..color = color.withOpacity(0.55);
    canvas.drawRect(Offset.zero & size, paint);

    // Dashed border to make it obvious this is a placeholder.
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), borderPaint);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + dashWidth, size.height),
        borderPaint,
      );
      x += dashWidth + dashSpace;
    }
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashWidth), borderPaint);
      canvas.drawLine(
        Offset(size.width, y),
        Offset(size.width, y + dashWidth),
        borderPaint,
      );
      y += dashWidth + dashSpace;
    }

    // Centered label so the layer name is readable in screenshots.
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF1A1F2B),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PlaceholderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.label != label;
  }
}
