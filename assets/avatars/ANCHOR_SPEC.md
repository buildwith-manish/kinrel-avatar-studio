# ANCHOR SPEC — Avatar Canvas & Layer Alignment

> **Status:** V1 — measured against the 12 standardized base body PNGs
> (commit `feat: replace placeholder base bodies with standardized artwork`).
> Anchor values below are empirical, derived from alpha-channel bounding-box
> scans of all 12 base bodies. See the per-body measurement table at the
> bottom of this file for the raw numbers.

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

## Anchor points (measured)

All layers must share the following fixed anchors so that, e.g., a hat PNG
drawn for `adult_male` sits correctly on top of the `adult_male` head, and a
pair of glasses PNG aligns with the eyes — without per-asset manual
positioning.

| Anchor | Y (px from top) | Notes |
| --- | --- | --- |
| Top of head | `~31 px` (range 21–43 across 12 bodies) | Top-most pixel of the head silhouette |
| Eye line | `_TBD_` | Vertical center of the eyes — measure when first glasses PNG is authored |
| Nose tip | `_TBD_` | Bottom of the nose — measure when first face-detail PNG is authored |
| Mouth center | `_TBD_` | Vertical center of the lips — measure when first face-detail PNG is authored |
| Chin | `_TBD_` | Bottom of the jaw |
| Shoulder line | `_TBD_` | Top of the shoulders |
| Waist | `_TBD_` | Narrowest part of the torso |
| Hip line | `_TBD_` | Top of the pelvis |
| Knee line | `_TBD_` | Vertical center of the knees |
| Ankle / feet bottom | `~1507 px` (range 1496–1513 across 12 bodies) | Bottom-most pixel of the feet |
| Horizontal centerline | `X = 512` | Always the horizontal midpoint (canvas center) |

### Tolerance

- Head-top Y: target `31 px`, tolerance `±15 px` (current measured spread is `22 px` — within tolerance).
- Feet-bottom Y: target `1507 px`, tolerance `±15 px` (current measured spread is `17 px` — within tolerance).
- Future face-feature anchors (eye line, mouth, etc.) should target `±10 px`
  since they are smaller features and misalignment is more visible.

> The remaining `_TBD_` rows will be filled in when the first PNG that
> depends on each anchor is authored (e.g. the first glasses PNG forces
> us to commit to an exact eye-line Y).

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
   1024×1536 and another is 1122×1402, `BoxFit.contain` will scale each one
   independently to fit the 2:3 frame — and the head of one layer will not
   line up with the hat of another.
2. **Non-transparent backgrounds cause ugly stacking.** RGB (no alpha) PNGs
   will fully occlude lower layers. Always export RGBA with the area outside
   the figure set to alpha=0.

## Standardization checklist (run on every new PNG before committing)

- [ ] Canvas is exactly `1024 × 1536`.
- [ ] Color mode is RGBA (not RGB).
- [ ] Background outside the figure is fully transparent (alpha = 0).
- [ ] Head is centered horizontally on `X = 512`.
- [ ] Head top, eye line, mouth, etc. match the anchor table above.
- [ ] Filename follows the convention in the table above.
- [ ] No whitespace padding around the figure that breaks anchors.

A `scripts/check_assets.py` helper is included to automate this checklist —
run `python3 scripts/check_assets.py` from the repo root to verify every
PNG under `assets/avatars/` meets the canvas, mode, and anchor contract.
Use `--strict` to fail on out-of-tolerance anchors (treats warnings as
errors).

---

## Appendix: measured anchors per base body (V1)

Measured by `scripts/measure_anchors.py` against the alpha-channel
bounding box of each `base/<id>/body.png`. These are the source of truth
for the anchor values in the table above.

| Body ID | Head top Y | Feet bottom Y | Left X | Right X |
| --- | --- | --- | --- | --- |
| adult_female | 31 | 1505 | 146 | 748 |
| adult_male | 31 | 1513 | 158 | 774 |
| child_female | 32 | 1510 | 103 | 788 |
| child_male | 32 | 1509 | 157 | 732 |
| elderly_female | 29 | 1504 | 118 | 734 |
| elderly_male | 21 | 1509 | 115 | 779 |
| middle_female | 43 | 1496 | 132 | 716 |
| middle_male | 30 | 1512 | 123 | 767 |
| preteen_female | 31 | 1510 | 148 | 742 |
| preteen_male | 32 | 1499 | 149 | 753 |
| teen_female | 31 | 1504 | 152 | 736 |
| teen_male | 30 | 1508 | 143 | 745 |
| **min** | **21** | **1496** | **103** | **716** |
| **max** | **43** | **1513** | **158** | **788** |
| **mean** | **31.1** | **1506.6** | **135.3** | **755.3** |

**Observations:**

- All 12 PNGs are exactly `1024×1536` RGBA — canvas contract honored.
- Head-top spread is `22 px` (within `±15 px` of the `31 px` target, but
  only barely — `elderly_male` at `21 px` and `middle_female` at `43 px`
  are the outliers). Consider tightening on the next art pass.
- Feet-bottom spread is `17 px` (within `±15 px` of the `1507 px` target).
- Horizontal centering is **not yet consistent** — `left_x` ranges from
  `103` to `158` and `right_x` from `716` to `788`, so the horizontal
  midpoint of the figure drifts by ~30 px across bodies. This is
  acceptable for V1 (base body is the only populated layer) but will
  need tightening before glasses / hats are authored.
