import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard;

import '../models/avatar_config.dart';
import '../models/avatar_layer.dart';
import '../registry/asset_manifest.dart';
import '../registry/base_bodies.dart';
import '../theme/avatar_studio_theme.dart';
import 'avatar_renderer.dart';
import 'layer_option_picker.dart';

/// Top-level V1 editor screen.
///
/// Layout:
///   ┌──────────────────────────────────────────┐
///   │  [Avatar preview — fixed 2:3 aspect]     │  ← large preview
///   │                                          │
///   ├──────────────────────────────────────────┤
///   │  Layer: Base Body   [chip][chip][chip]…  │  ← horizontal picker
///   │  Layer: Clothing    [chip][chip][chip]…  │
///   │  Layer: Hair        [None][chip][chip]…  │
///   │  Layer: Glasses     [None][chip][chip]…  │
///   │  Layer: Accessories [chip][chip][chip]…  │
///   ├──────────────────────────────────────────┤
///   │  Skin tone (V1 placeholder dropdown)     │
///   ├──────────────────────────────────────────┤
///   │              [ Save Avatar ]             │  ← prints JSON
///   └──────────────────────────────────────────┘
///
/// Tapping any option produces an immutable [AvatarConfig.copyWith] update
/// and the preview re-renders live. Save prints the JSON to console
/// (V1 — no backend yet).
class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key, this.initialConfig});

  final AvatarConfig? initialConfig;

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  late AvatarConfig _config;
  AssetManifest? _manifest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? AvatarConfig.v1Default();
    _initManifest();
  }

  Future<void> _initManifest() async {
    // Touch the AssetManifest.json bundle so we fail loudly here if the
    // pubspec.yaml assets section is mis-configured, rather than silently
    // showing all-placeholder avatars.
    try {
      await rootBundle.loadString('AssetManifest.json');
    } catch (e) {
      debugPrint('[AvatarEditorScreen] AssetManifest.json not available yet '
          '(run `flutter pub get` and rebuild): $e');
    }
    final m = await AssetManifest.load();
    if (!mounted) return;
    setState(() {
      _manifest = m;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinrel Avatar Studio'),
        centerTitle: true,
        backgroundColor: AvatarStudioTheme.surfaceRaised,
        foregroundColor: AvatarStudioTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
      bottomNavigationBar: _buildSaveBar(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final manifest = _manifest!;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        _buildPreview(theme),
        const SizedBox(height: 8),
        _buildLayerSection(theme, manifest),
        const Divider(height: 32),
        _buildSkinToneRow(theme),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AvatarStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AvatarStudioTheme.divider),
        ),
        child: Column(
          children: [
            AvatarRenderer(
              config: _config,
              manifest: _manifest,
            ),
            const SizedBox(height: 8),
            Text(
              _config.baseBodyId.replaceAll('_', ' ').toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: AvatarStudioTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerSection(ThemeData theme, AssetManifest manifest) {
    final baseBody = baseBodyById(_config.baseBodyId);
    final gender = baseBody?.gender;

    // Build pickers in stack order.
    final pickers = <Widget>[
      _buildBaseBodyPicker(theme),
      _buildClothingPicker(theme, manifest),
      // Face detail (V2) — not shown.
      _buildHairPicker(theme, manifest, gender),
      if (baseBody?.supportsFacialHair ?? false)
        _buildFacialHairPicker(theme, manifest),
      // Eyes/eyebrows (V2) — not shown.
      _buildEarringsPicker(theme, manifest),
      _buildGlassesPicker(theme, manifest),
      _buildAccessoriesPicker(theme, manifest),
    ];

    return Column(children: pickers);
  }

  // -- Base body picker (12 options, "None" not allowed) --------------------

  Widget _buildBaseBodyPicker(ThemeData theme) {
    final options = kBaseBodies
        .map((b) => LayerOption(
              id: b.id,
              label: b.label.split(' ').first,
              sublabel: b.ageRange,
              swatch: _colorForBaseBody(b),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.baseBody,
      options: options,
      selectedId: _config.baseBodyId,
      allowNone: false,
      onSelected: (id) {
        if (id == null) return;
        final newBody = baseBodyById(id);
        setState(() {
          _config = _config.copyWith(
            baseBodyId: id,
            // Drop incompatible selections when switching bodies.
            facialHairId:
                newBody?.supportsFacialHair == true ? _config.facialHairId : null,
            hairId: _config.hairId, // hair folder is gendered; let it stay,
            // the renderer will fall back to placeholder if the gendered
            // folder doesn't contain it.
          );
        });
      },
    );
  }

  // -- Clothing picker ------------------------------------------------------

  Widget _buildClothingPicker(ThemeData theme, AssetManifest manifest) {
    final ids = manifest.listIds(AvatarLayer.clothing);
    // Always offer the synthetic "default" clothing option even if the
    // folder is empty, so the user can fall back to the default-outfit
    // convention documented in ANCHOR_SPEC.md.
    final allIds = <String>{'default', ...ids}.toList();
    final options = allIds
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: AvatarStudioTheme.selected.withOpacity(0.4),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.clothing,
      options: options,
      selectedId: _config.clothingId,
      allowNone: false,
      onSelected: (id) {
        if (id == null) return;
        setState(() => _config = _config.copyWith(clothingId: id));
      },
    );
  }

  // -- Hair picker (gendered folder) ---------------------------------------

  Widget _buildHairPicker(
      ThemeData theme, AssetManifest manifest, Gender? gender) {
    final ids = manifest.listIds(AvatarLayer.hair, gender: gender);
    final options = ids
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: PlaceholderLayer.colorFor(AvatarLayer.hair),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.hair,
      options: options,
      selectedId: _config.hairId,
      allowNone: true,
      onSelected: (id) =>
          setState(() => _config = _config.copyWith(hairId: id)),
    );
  }

  // -- Facial hair picker (male only) --------------------------------------

  Widget _buildFacialHairPicker(ThemeData theme, AssetManifest manifest) {
    final ids = manifest.listIds(AvatarLayer.facialHair);
    final options = ids
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: PlaceholderLayer.colorFor(AvatarLayer.facialHair),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.facialHair,
      options: options,
      selectedId: _config.facialHairId,
      allowNone: true,
      onSelected: (id) =>
          setState(() => _config = _config.copyWith(facialHairId: id)),
    );
  }

  // -- Earrings picker -----------------------------------------------------

  Widget _buildEarringsPicker(ThemeData theme, AssetManifest manifest) {
    final ids = manifest.listIds(AvatarLayer.earrings);
    final options = ids
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: PlaceholderLayer.colorFor(AvatarLayer.earrings),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.earrings,
      options: options,
      selectedId: _config.earringsId,
      allowNone: true,
      onSelected: (id) =>
          setState(() => _config = _config.copyWith(earringsId: id)),
    );
  }

  // -- Glasses picker ------------------------------------------------------

  Widget _buildGlassesPicker(ThemeData theme, AssetManifest manifest) {
    final ids = manifest.listIds(AvatarLayer.glasses);
    final options = ids
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: PlaceholderLayer.colorFor(AvatarLayer.glasses),
            ))
        .toList();
    return LayerOptionPicker(
      layer: AvatarLayer.glasses,
      options: options,
      selectedId: _config.glassesId,
      allowNone: true,
      onSelected: (id) =>
          setState(() => _config = _config.copyWith(glassesId: id)),
    );
  }

  // -- Accessories picker (multi-select) -----------------------------------
  // V1: single-select for simplicity. Multi-select hook is in the data
  // model (accessoryIds: List<String>) — the editor can be upgraded
  // later without changing persistence.

  Widget _buildAccessoriesPicker(ThemeData theme, AssetManifest manifest) {
    final ids = manifest.listIds(AvatarLayer.accessories);
    final options = ids
        .map((id) => LayerOption(
              id: id,
              label: _humanize(id),
              swatch: PlaceholderLayer.colorFor(AvatarLayer.accessories),
            ))
        .toList();
    final String? selectedAccessory =
        _config.accessoryIds.isEmpty ? null : _config.accessoryIds.first;
    return LayerOptionPicker(
      layer: AvatarLayer.accessories,
      options: options,
      selectedId: selectedAccessory,
      allowNone: true,
      onSelected: (id) {
        setState(() {
          _config = _config.copyWith(
            accessoryIds: id == null ? const [] : [id],
          );
        });
      },
    );
  }

  // -- Skin tone (V1 placeholder, non-functional) --------------------------

  Widget _buildSkinToneRow(ThemeData theme) {
    final tones = <String>['tone_1', 'tone_2', 'tone_3', 'tone_4', 'tone_5'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Skin Tone',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AvatarStudioTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AvatarStudioTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'V1 placeholder — non-functional',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AvatarStudioTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: tones.map((t) {
              final selected = _config.skinToneId == t;
              return GestureDetector(
                onTap: () =>
                    setState(() => _config = _config.copyWith(skinToneId: t)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorForSkinTone(t),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AvatarStudioTheme.selected
                          : Colors.black.withOpacity(0.1),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -- Save bar ------------------------------------------------------------

  Widget _buildSaveBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AvatarStudioTheme.surfaceRaised,
          border: Border(top: BorderSide(color: AvatarStudioTheme.divider)),
        ),
        child: FilledButton.icon(
          onPressed: _onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Avatar (print JSON)'),
        ),
      ),
    );
  }

  void _onSave() {
    final json = _config.toJson();
    final pretty = const JsonEncoder.withIndent('  ').convert(json);
    // V1: print to console only. V2 will persist to Supabase.
    // ignore: avoid_print
    print('===== AvatarConfig JSON =====\n$pretty\n=============================');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Avatar JSON printed to console'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: pretty));
          },
        ),
      ),
    );
  }

  // -- Helpers -------------------------------------------------------------

  String _humanize(String id) {
    return id
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _colorForBaseBody(BaseBody b) {
    // Distinct hues per age band; warm vs cool per gender.
    final ageTint = <String, Color>{
      '5-9': const Color(0xFFFFD9A8),
      '10-12': const Color(0xFFFFC78A),
      '13-17': const Color(0xFFE6A572),
      '20-45': const Color(0xFFC77D4F),
      '46-59': const Color(0xFF8E5A3A),
      '60+': const Color(0xFF6B4528),
    };
    final base = ageTint[b.ageRange] ?? Colors.grey;
    return b.gender == Gender.female
        ? Color.lerp(base, Colors.pink, 0.15)!
        : base;
  }

  Color _colorForSkinTone(String id) {
    final map = <String, Color>{
      'tone_1': const Color(0xFFFFDBAC),
      'tone_2': const Color(0xFFF1C27D),
      'tone_3': const Color(0xFFE0AC69),
      'tone_4': const Color(0xFFC68642),
      'tone_5': const Color(0xFF8D5524),
    };
    return map[id] ?? Colors.grey;
  }
}
