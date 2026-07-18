# ANCHOR SPEC — Avatar Canvas & Layer Alignment

> **Status:** V1 spec — pending first standardized PNGs.
> Once real assets are dropped in, measure and fill in the pixel anchors below.

## Canvas size

Every avatar PNG **MUST** be exactly:

| Property | Value |
| --- | --- |
| Width | `1024 px` |
| Height | `1536 px` |
| Aspect ratio | `2:3` (`0.6667`) |
| Color mode | RGBA (transparent background outside the figure) |
| Format | PNG-32 (lossless, full alpha) |

This ratio matches `AvatarStudioTheme.canvasAspectRatio` and is enforced by
the `AvatarRenderer` widget — every layer is drawn into a `Positioned.fill`
`Stack` of this aspect ratio.

## Anchor points (TODO — fill in after first standardized PNGs)

All layers must share the following fixed anchors so that, e.g., a hat PNG
drawn for `adult_male` sits correctly on top of the `adult_male` head, and a
pair of glasses PNG aligns with the eyes — without per-asset manual
positioning.

| Anchor | Y (px from top) | Notes |
| --- | --- | --- |
| Top of head | `_TBD_` | Top-most pixel of the head silhouette |
| Eye line | `_TBD_` | Vertical center of the eyes |
| Nose tip | `_TBD_` | Bottom of the nose |
| Mouth center | `_TBD_` | Vertical center of the lips |
| Chin | `_TBD_` | Bottom of the jaw |
| Shoulder line | `_TBD_` | Top of the shoulders |
| Waist | `_TBD_` | Narrowest part of the torso |
| Hip line | `_TBD_` | Top of the pelvis |
| Knee line | `_TBD_` | Vertical center of the knees |
| Ankle | `_TBD_` | Bottom of the feet (usually == canvas bottom margin) |
| Horizontal centerline | `X = 512` | Always the horizontal midpoint |

> When you place your first finalized base body PNG, measure the above Y
> values and update this table. Then make sure every other layer's PNG is
> authored to align with those same anchors.

## File naming convention

| Layer | Folder | Filename pattern |
| --- | --- | --- |
| Base body | `assets/avatars/base/<baseBodyId>/` | `body.png` |
| Default clothing (per body) | `assets/avatars/clothing/default/` | `<baseBodyId>_default.png` |
| Top | `assets/avatars/clothing/tops/` | `<top_id>.png` |
| Bottom | `assets/avatars/clothing/bottoms/` | `<bottom_id>.png` |
| Dress / Kurta | `assets/avatars/clothing/dresses_kurtas/` | `<dress_id>.png` |
| Hair (male) | `assets/avatars/hair/male/` | `<hair_id>.png` |
| Hair (female) | `assets/avatars/hair/female/` | `<hair_id>.png` |
| Facial hair | `assets/avatars/facial_hair/` | `<facial_hair_id>.png` |
| Eyes / Eyebrows (V2) | `assets/avatars/eyes_eyebrows/` | `<eyes_id>.png` |
| Glasses | `assets/avatars/glasses/` | `<glasses_id>.png` |
| Earrings | `assets/avatars/earrings/` | `<earrings_id>.png` |
| Accessories | `assets/avatars/accessories/` | `<accessory_id>.png` |

**Asset ID rules:**

- Lowercase ASCII, words separated by underscores (`_`).
- No file extensions in the ID — the runtime strips `.png` automatically.
- IDs are stored in `AvatarConfig` JSON and persisted to Supabase later,
  so they must be stable across versions. Never rename an existing asset
  file; deprecate and replace instead.

## Why this matters

The `AvatarRenderer` uses `Positioned.fill` + `BoxFit.contain` for every
layer. Two consequences:

1. **Canvas-size mismatches cause silent misalignment.** If one layer is
   1024×1536 and another is 1122×1402 (as in the initial raw uploads in
   `_raw_uploads/`), `BoxFit.contain` will scale each one independently
   to fit the 2:3 frame — and the head of one layer will not line up
   with the hat of another.
2. **Non-transparent backgrounds cause ugly stacking.** RGB (no alpha)
   PNGs will fully occlude lower layers. Always export RGBA with the
   area outside the figure set to alpha=0.

## Standardization checklist (run on every new PNG before committing)

- [ ] Canvas is exactly `1024 × 1536`.
- [ ] Color mode is RGBA (not RGB).
- [ ] Background outside the figure is fully transparent (alpha = 0).
- [ ] Head is centered horizontally on `X = 512`.
- [ ] Head top, eye line, mouth, etc. match the anchor table above.
- [ ] Filename follows the convention in the table above.
- [ ] No whitespace padding around the figure that breaks anchors.

A `scripts/check_assets.py` helper will be added in a follow-up to
automate this checklist (verify canvas size, mode, and that all PNGs
share the same anchor pixel positions).
