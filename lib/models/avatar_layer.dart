/// Defines every renderable layer in the avatar stack, in the exact order
/// they must be painted from bottom (first) to top (last).
///
/// Rendering contract:
///   Every layer is drawn into the same fixed-aspect canvas using
///   [Positioned.fill]. This only aligns correctly if every source PNG
///   shares the same canvas size (1024×1536) and the same anchor points
///   documented in `assets/avatars/ANCHOR_SPEC.md`.
///
/// V1 scope notes:
///   - [faceDetail] and [eyesEyebrows] are V2+ layers and are skipped
///     at runtime by [AvatarRenderer] — they exist here so the enum is
///     stable across versions and JSON configs stay forward-compatible.
enum AvatarLayer {
  /// Mannequin base: head, face, body, skin tone, default hairline.
  baseBody,

  /// Outfit layer (top + bottom as a single outfit, or dress/kurta).
  clothing,

  /// Optional face-detail overrides (V2 — skipped in V1).
  faceDetail,

  /// Hair layer (separate from base body's default hairline).
  hair,

  /// Facial hair (male only, conditionally rendered).
  facialHair,

  /// Eyes / eyebrows swap layer (V2 — skipped in V1).
  eyesEyebrows,

  /// Earrings.
  earrings,

  /// Glasses.
  glasses,

  /// Accessories (watch, necklace, hat, etc.). Multiple allowed.
  accessories,
}

/// Extension with metadata used by the editor UI and the renderer.
extension AvatarLayerX on AvatarLayer {
  /// Human-readable label shown in the editor's picker rows.
  String get label {
    switch (this) {
      case AvatarLayer.baseBody:
        return 'Base Body';
      case AvatarLayer.clothing:
        return 'Clothing';
      case AvatarLayer.faceDetail:
        return 'Face Detail';
      case AvatarLayer.hair:
        return 'Hair';
      case AvatarLayer.facialHair:
        return 'Facial Hair';
      case AvatarLayer.eyesEyebrows:
        return 'Eyes & Eyebrows';
      case AvatarLayer.earrings:
        return 'Earrings';
      case AvatarLayer.glasses:
        return 'Glasses';
      case AvatarLayer.accessories:
        return 'Accessories';
    }
  }

  /// Whether this layer supports multiple simultaneous selections
  /// (e.g. accessories: watch + necklace + hat at once).
  bool get allowsMultiple => this == AvatarLayer.accessories;

  /// Whether this layer is currently inactive in V1 and should be
  /// skipped by the renderer even if the config references it.
  bool get isV1Skipped =>
      this == AvatarLayer.faceDetail || this == AvatarLayer.eyesEyebrows;

  /// Stable string key used in JSON serialization. Keep these names
  /// stable across versions — they ARE the persistence contract.
  String get wireKey {
    switch (this) {
      case AvatarLayer.baseBody:
        return 'base_body';
      case AvatarLayer.clothing:
        return 'clothing';
      case AvatarLayer.faceDetail:
        return 'face_detail';
      case AvatarLayer.hair:
        return 'hair';
      case AvatarLayer.facialHair:
        return 'facial_hair';
      case AvatarLayer.eyesEyebrows:
        return 'eyes_eyebrows';
      case AvatarLayer.earrings:
        return 'earrings';
      case AvatarLayer.glasses:
        return 'glasses';
      case AvatarLayer.accessories:
        return 'accessories';
    }
  }

  /// Render order index (lower = painted first / bottom of stack).
  int get stackOrder => index;
}
