# V1 Decision: Clothing is Baked Into the Base Body

> **Status:** Final for V1. Revisit in V2 once the hair / glasses / accessories
> pipeline is stable.

## Context

The 12 standardized base body PNGs supplied for V1 (`assets/avatars/base/<id>/body.png`)
each depict a fully-dressed figure:

| Body ID | Visible outfit (baked in) |
| --- | --- |
| child_male | yellow t-shirt, brown shorts, orange sneakers |
| child_female | orange dress with floral embroidery, beige leggings |
| preteen_male | brown hoodie, dark jeans, sneakers |
| preteen_female | orange tunic with white embroidery, beige pants |
| teen_male | orange t-shirt, khaki cargo shorts |
| teen_female | beige cropped sweater, blue jeans, orange sneakers |
| adult_male | brown polo shirt, khaki pants |
| adult_female | orange kurta with white trim, beige pants |
| middle_male | brown button-up shirt, khaki pants |
| middle_female | beige kurta, brown dupatta, matching pants |
| elderly_male | beige kurta, brown vest, matching pants, brown sandals |
| elderly_female | cream sari with red floral border, beige cardigan |

The outfit is part of the body artwork — it is not a separate swap layer.

## Decision

**For V1, keep clothing baked into the base body. Do not build a separate
clothing swap layer system.**

Reasons:

1. **Time.** Splitting clothing into a true swap layer would require:
   - Re-authoring all 12 base bodies as naked mannequins (no clothing).
   - Authoring a separate outfit PNG per body × per style combination.
   - Updating the `AvatarRenderer` to clip clothing to the body silhouette
     (otherwise the mannequin's limbs would show through transparent areas
     of the clothing PNG).
   - Updating the editor to support category-based clothing pickers
     (tops, bottoms, dresses/kurtas) instead of the flat single-row picker
     currently in place.

   That is a significant art + engineering investment for V1.

2. **Spec alignment.** The original V1 spec defined the clothing layer but
   explicitly said `placeholder rectangles standing in for each asset` was
   acceptable. We have something better than placeholders — we have real
   (baked-in) outfits — so the V1 user experience is already better than
   the spec's minimum bar.

3. **Forward compatibility.** The `AvatarConfig.clothingId` field still
   exists and round-trips through JSON. V1 always sets it to `"default"`.
   When V2 introduces a real clothing layer, the field is already in the
   persistence contract — no schema migration needed.

## Implementation in V1

The clothing picker in `AvatarEditorScreen` is still rendered, but:

- It only offers the synthetic `"default"` option (plus any PNGs the user
  later drops into `assets/avatars/clothing/default/`).
- The `"default"` chip carries a `"Baked into body"` sublabel to make the
  V1 limitation visible in the UI.
- Selecting `"default"` is a no-op for rendering — the `AvatarRenderer`
  still draws only the base body PNG (which contains the outfit).

The `AvatarRenderer` does still look up the clothing path and would render
it if a real PNG existed at `assets/avatars/clothing/default/<id>.png`,
so the plumbing is in place for V2 — only the artwork and the editor UX
need updating.

## V2 migration plan (when we tackle this)

1. Re-author 12 base body PNGs as unclothed mannequins (skin-tone body
   only, no outfit). Keep the same canvas size and anchor contract.
2. Author the first outfit set — one default outfit per body, saved as
   `clothing/default/<baseBodyId>_default.png` (matches the convention
   documented in `ANCHOR_SPEC.md`).
3. Add category pickers to the editor:
   - Tops (`clothing/tops/<id>.png`)
   - Bottoms (`clothing/bottoms/<id>.png`)
   - Dresses / Kurtas (`clothing/dresses_kurtas/<id>.png`) — for outfits
     that are a single garment (sari, kurta, dress).
4. Extend `AvatarConfig` with optional `topId`, `bottomId`, `dressId`
   fields (or a single `outfitId` that resolves to one of the three
   categories). Keep `clothingId` as a deprecated alias for backward
   compatibility with V1 saved configs.
5. Update `AvatarRenderer` to optionally apply a body-clipping mask to
   the clothing layer so the mannequin's limbs don't show through
   transparent regions of the clothing PNG.

## Why document this?

Decisions like this are easy to forget three months from now. When a
new contributor asks "why isn't there a clothing picker?" or "why does
selecting an outfit do nothing?", this doc is the answer.
