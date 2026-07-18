import 'package:flutter/material.dart';

import '../models/avatar_config.dart';
import '../models/avatar_layer.dart';
import '../registry/asset_manifest.dart';
import '../registry/base_bodies.dart';
import '../theme/avatar_studio_theme.dart';
import 'placeholder_layer.dart';

/// Renders an [AvatarConfig] as a fixed-aspect-ratio stack of layer
/// images.
///
/// Contract:
///   - The widget always renders at [AvatarStudioTheme.canvasAspectRatio]
///     (2:3, matching 1024×1536 source PNGs). Parent widgets can scale
///     this freely — the avatar's proportions stay correct.
///   - Each layer is drawn with [Positioned.fill] so all layers align
///     to the same canvas. This only looks right if every source PNG
///     shares the same canvas size and anchor points (see
///     `assets/avatars/ANCHOR_SPEC.md`).
///   - Missing optional layers (null ID, or ID whose PNG is not bundled)
///     are skipped silently. Missing required layers (base body,
///     clothing) fall back to a colored [PlaceholderLayer] so the UI
///     never appears blank during V1 scaffold use.
///   - V2 layers ([AvatarLayer.faceDetail], [AvatarLayer.eyesEyebrows])
///     are never rendered, even if the config references them.
class AvatarRenderer extends StatefulWidget {
  const AvatarRenderer({
    super.key,
    required this.config,
    this.manifest,
    this.showPlaceholders = true,
  });

  /// The avatar to render. If null is passed, the [AvatarConfig.v1Default]
  /// is used.
  final AvatarConfig config;

  /// Optional pre-loaded asset manifest. When null, the renderer loads
  /// it on first build via [AssetManifest.load]. Pass a cached instance
  /// when rendering many avatars in one screen (e.g. a grid of presets).
  final AssetManifest? manifest;

  /// When true (default), missing layers are replaced by colored
  /// [PlaceholderLayer]s so the stack is visible during scaffold use.
  /// Set to false for production renders once all assets exist.
  final bool showPlaceholders;

  @override
  State<AvatarRenderer> createState() => _AvatarRendererState();
}

class _AvatarRendererState extends State<AvatarRenderer> {
  AssetManifest? _manifest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.manifest != null) {
      _manifest = widget.manifest;
      _loading = false;
    } else {
      _loadManifest();
    }
  }

  Future<void> _loadManifest() async {
    final m = await AssetManifest.load();
    if (!mounted) return;
    setState(() {
      _manifest = m;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AvatarStudioTheme.canvasAspectRatio,
      child: ClipRect(
        child: Container(
          color: const Color(0xFFE9ECF1),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _buildStack(_manifest!),
        ),
      ),
    );
  }

  Widget _buildStack(AssetManifest manifest) {
    final config = widget.config;
    final baseBody = baseBodyById(config.baseBodyId);
    final gender = baseBody?.gender;

    final children = <Widget>[];

    // 1. Base body — always rendered. Placeholder when PNG missing.
    final bodyPath = manifest.baseBodyPath(config.baseBodyId);
    if (bodyPath != null) {
      children.add(
        Positioned.fill(child: Image.asset(bodyPath, fit: BoxFit.contain)),
      );
    } else if (widget.showPlaceholders) {
      children.add(
        PlaceholderLayer(
          layer: AvatarLayer.baseBody,
          label: baseBody?.label ?? config.baseBodyId,
        ),
      );
    }

    // 2. Clothing — placeholder when missing.
    final clothingPath =
        manifest.resolveLayerPath(
          AvatarLayer.clothing,
          id: config.clothingId,
        ) ??
        manifest.defaultClothingPath(config.baseBodyId);
    if (clothingPath != null) {
      children.add(
        Positioned.fill(child: Image.asset(clothingPath, fit: BoxFit.contain)),
      );
    } else if (widget.showPlaceholders) {
      children.add(
        PlaceholderLayer(layer: AvatarLayer.clothing, label: config.clothingId),
      );
    }

    // 3. Face detail — V2, skipped.
    // (intentionally no-op)

    // 4. Hair — nullable, skipped when null.
    if (config.hairId != null) {
      final hairPath = manifest.resolveLayerPath(
        AvatarLayer.hair,
        id: config.hairId!,
        gender: gender,
      );
      if (hairPath != null) {
        children.add(
          Positioned.fill(child: Image.asset(hairPath, fit: BoxFit.contain)),
        );
      } else if (widget.showPlaceholders) {
        children.add(
          PlaceholderLayer(layer: AvatarLayer.hair, label: config.hairId!),
        );
      }
    }

    // 5. Facial hair — male only, nullable, skipped otherwise.
    if (config.facialHairId != null && baseBody?.supportsFacialHair == true) {
      final fhPath = manifest.resolveLayerPath(
        AvatarLayer.facialHair,
        id: config.facialHairId!,
      );
      if (fhPath != null) {
        children.add(
          Positioned.fill(child: Image.asset(fhPath, fit: BoxFit.contain)),
        );
      } else if (widget.showPlaceholders) {
        children.add(
          PlaceholderLayer(
            layer: AvatarLayer.facialHair,
            label: config.facialHairId!,
          ),
        );
      }
    }

    // 6. Eyes / eyebrows — V2, skipped.
    // (intentionally no-op)

    // 7. Earrings — nullable, skipped when null.
    if (config.earringsId != null) {
      final ePath = manifest.resolveLayerPath(
        AvatarLayer.earrings,
        id: config.earringsId!,
      );
      if (ePath != null) {
        children.add(
          Positioned.fill(child: Image.asset(ePath, fit: BoxFit.contain)),
        );
      } else if (widget.showPlaceholders) {
        children.add(
          PlaceholderLayer(
            layer: AvatarLayer.earrings,
            label: config.earringsId!,
          ),
        );
      }
    }

    // 8. Glasses — nullable, skipped when null.
    if (config.glassesId != null) {
      final gPath = manifest.resolveLayerPath(
        AvatarLayer.glasses,
        id: config.glassesId!,
      );
      if (gPath != null) {
        children.add(
          Positioned.fill(child: Image.asset(gPath, fit: BoxFit.contain)),
        );
      } else if (widget.showPlaceholders) {
        children.add(
          PlaceholderLayer(
            layer: AvatarLayer.glasses,
            label: config.glassesId!,
          ),
        );
      }
    }

    // 9. Accessories — multiple allowed, rendered in declared order.
    for (final accId in config.accessoryIds) {
      final aPath = manifest.resolveLayerPath(
        AvatarLayer.accessories,
        id: accId,
      );
      if (aPath != null) {
        children.add(
          Positioned.fill(child: Image.asset(aPath, fit: BoxFit.contain)),
        );
      } else if (widget.showPlaceholders) {
        children.add(
          PlaceholderLayer(layer: AvatarLayer.accessories, label: accId),
        );
      }
    }

    return Stack(fit: StackFit.expand, children: children);
  }
}
