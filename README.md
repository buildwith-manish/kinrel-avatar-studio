# Kinrel Avatar Studio

> A modular, layer-based avatar creation system for the **Kinrel** app.
> This is the standalone V1 scaffold — self-contained, no Kinrel backend
> dependency. Will be merged into the main Kinrel repo later as an
> `avatar_studio` package/module.

## Status

**V1 scaffold.** Working editor UI with placeholder rendering for any
layer whose PNG assets are not yet supplied. Drop real PNGs into the
asset folders (per [`assets/avatars/ANCHOR_SPEC.md`](assets/avatars/ANCHOR_SPEC.md))
and they will be picked up automatically on the next build — no code
changes required.

---

## What V1 includes

- ✅ `AvatarLayer` enum with 9 layers in the spec-required render order
  (bottom → top): base body, clothing, face-detail (V2), hair, facial
  hair, eyes/eyebrows (V2), earrings, glasses, accessories.
- ✅ `AvatarConfig` immutable data model with `toJson()` / `fromJson()`
  — backend-agnostic, ready to drop into a Supabase `jsonb` column later.
- ✅ `AvatarRenderer` widget — fixed 2:3 aspect, `Positioned.fill` stack,
  graceful fallback to colored placeholder rectangles when an asset is
  missing.
- ✅ `AvatarEditorScreen` — live preview + horizontal pickers per layer
  + Save button that prints the resulting `AvatarConfig` JSON to console.
- ✅ 12-body age/gender selector (child → elderly × male/female).
- ✅ Dynamic asset discovery via `AssetManifest.json` — add a PNG, rebuild,
  it shows up in the picker. No hardcoded asset lists.
- ✅ Tests for `AvatarConfig` round-trip, `AvatarLayer` ordering, and
  the base-body catalog.

## What V1 explicitly does NOT include (per spec)

- ❌ MediaPipe / selfie-based auto-detection (V2).
- ❌ Eyes / eyebrows / nose / mouth swappable layers (V3).
- ❌ Skin-tone tinting / recoloring logic (V1 has a non-functional
  placeholder dropdown).
- ❌ Backend / Supabase integration — local state only.
- ❌ Animations or expressions.

---

## Project structure

```
kinrel-avatar-studio/
├── lib/
│   ├── main.dart                          # V1 demo entry point
│   ├── avatar_studio.dart                 # public API barrel
│   ├── models/
│   │   ├── avatar_config.dart             # AvatarConfig + toJson/fromJson
│   │   └── avatar_layer.dart              # AvatarLayer enum + extensions
│   ├── registry/
│   │   ├── asset_manifest.dart            # dynamic asset discovery
│   │   └── base_bodies.dart               # 12-body catalog
│   ├── widgets/
│   │   ├── avatar_renderer.dart           # layered Stack renderer
│   │   ├── avatar_editor_screen.dart      # V1 editor UI
│   │   ├── layer_option_picker.dart       # horizontal picker row
│   │   └── placeholder_layer.dart         # colored rectangle fallback
│   └── theme/
│       └── avatar_studio_theme.dart
├── assets/
│   └── avatars/
│       ├── ANCHOR_SPEC.md                 # canvas + anchor contract
│       ├── base/<12 bodies>/body.png      # 12 base body slots
│       ├── clothing/{default,tops,bottoms,dresses_kurtas}/
│       ├── hair/{male,female}/
│       ├── facial_hair/
│       ├── eyes_eyebrows/                 # V2 placeholder
│       ├── glasses/
│       ├── earrings/
│       ├── accessories/
│       └── _raw_uploads/                  # 12 unsorted reference PNGs
├── test/
│   ├── avatar_config_test.dart
│   ├── avatar_layer_test.dart
│   └── base_bodies_test.dart
├── pubspec.yaml
├── analysis_options.yaml
└── README.md  (you are here)
```

---

## Getting started

### Prerequisites

- Flutter `>=3.19.0` (Dart `>=3.3.0`)
- Android Studio / VS Code / command-line Flutter tooling

### Run

```bash
# 1. Clone
git clone https://github.com/buildwith-manish/kinrel-avatar-studio.git
cd kinrel-avatar-studio

# 2. Generate platform folders (the scaffold ships without android/ios/
#    web/ folders so the repo stays lean and Flutter-version-agnostic).
flutter create --org com.kinrel --project-name kinrel_avatar_studio .

# 3. Install dependencies
flutter pub get

# 4. Run on a device or emulator
flutter run
```

You should see the editor screen with:

- A 2:3 preview pane showing stacked colored placeholder rectangles
  (one per layer that doesn't have a real PNG yet).
- Horizontal picker rows for: Base Body, Clothing, Hair, Facial Hair
  (male bodies only), Earrings, Glasses, Accessories.
- A non-functional Skin Tone selector (V1 placeholder).
- A **Save Avatar (print JSON)** button that prints the `AvatarConfig`
  JSON to the console and offers a Copy-to-clipboard action.

### Test

```bash
flutter test
```

---

## Adding real PNG assets

1. Author / standardize your PNGs against
   [`ANCHOR_SPEC.md`](assets/avatars/ANCHOR_SPEC.md) — every PNG **must**
   be `1024×1536`, RGBA, transparent background, with the documented
   anchor points.

2. Drop them into the right folder using the naming convention from
   `ANCHOR_SPEC.md`. Example:

   ```
   assets/avatars/base/adult_male/body.png
   assets/avatars/hair/male/short_black.png
   assets/avatars/glasses/round_black.png
   ```

3. Re-run `flutter run` (or hot-restart — `AssetManifest.json` is
   regenerated on every build). The new options appear in the picker
   automatically, and the renderer swaps the placeholder rectangle for
   the real PNG.

4. Once a base body has its real PNG, the corresponding folder's
   `.gitkeep` file can be deleted (it's only there to preserve empty
   folder structure in git).

### About `_raw_uploads/`

The 12 PNGs in `assets/avatars/_raw_uploads/` are the **unprocessed**
reference images supplied at scaffold time. They are NOT yet standardized:

- 10 of them are `1024×1536`, but 2 are `1122×1402`.
- All are RGB (no transparency) — they will visually occlude lower
  layers if used as-is.

Once you process them (resize / add transparency / align anchors), move
each one to the correct `base/<baseBodyId>/body.png` path. The folder
is declared in `pubspec.yaml` for convenience but is **not** loaded by
the renderer.

---

## Merging into the main Kinrel app (later)

This scaffold is intentionally self-contained so it can be lifted into
the main Kinrel repo as a path or git submodule. Recommended approach:

1. Move this folder to `<kinrel>/packages/avatar_studio/`.
2. Update the Kinrel app's `pubspec.yaml`:
   ```yaml
   dependencies:
     avatar_studio:
       path: packages/avatar_studio
   ```
3. Replace `lib/main.dart` with a direct import of `AvatarEditorScreen`
   from your app's navigation graph:
   ```dart
   import 'package:avatar_studio/avatar_studio.dart';
   ```
4. Wire `AvatarConfig.toJson()` into your Supabase Person/User table's
   `avatar_config jsonb` column.

The `AvatarConfig` JSON shape is the persistence contract — add new
optional fields only, never rename or remove existing keys.

---

## License

Proprietary — Kinrel. All rights reserved.
