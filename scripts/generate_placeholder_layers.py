"""Generate placeholder PNGs for non-base-body avatar layers.

V1 strategy: the user's spec said "the code should read filenames dynamically
from each folder, not hardcode a fixed list". For the editor to actually
feel like an editor (per the user's instructions in this iteration), the
hair / glasses / accessories folders need at least a few PNGs in them.

This script generates programmatic placeholder PNGs that conform to the
ANCHOR_SPEC.md contract:
  - 1024 x 1536 RGBA
  - Transparent background outside the figure region
  - Head-top Y anchor ~31 px (so hair starts at the top of the head)
  - Head bottom ~Y=320 (typical adult head is ~1/7 of body height)
  - Eye line ~Y=180 (used for glasses positioning)
  - Neck/wrist positions for accessories

Each PNG is a clearly-programmatic shape (solid silhouette with a small
"PH" mark in the corner) so it's visually obvious these are placeholders
that the user will replace with real artwork later.

Run:
    python3 scripts/generate_placeholder_layers.py

Outputs into:
    assets/avatars/hair/male/*.png
    assets/avatars/hair/female/*.png
    assets/avatars/glasses/*.png
    assets/avatars/accessories/*.png
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "assets" / "avatars"

CANVAS_W, CANVAS_H = 1024, 1536
HEAD_TOP_Y = 31
HEAD_BOTTOM_Y = 320
EYE_LINE_Y = 180
NECK_Y = 340
HEAD_CENTER_X = CANVAS_W // 2
HEAD_WIDTH = 320  # typical head width at widest point

# Color palette — distinct per asset so they're visually identifiable
# in the editor even before real artwork is supplied.
PALETTE = {
    "black": (30, 30, 35, 255),
    "brown_dark": (60, 36, 28, 255),
    "brown_med": (95, 60, 40, 255),
    "brown_light": (140, 95, 60, 255),
    "blonde": (210, 175, 110, 255),
    "grey": (140, 140, 145, 255),
    "white": (240, 240, 240, 255),
    "red_auburn": (130, 60, 40, 255),
    "gold": (212, 175, 55, 255),
    "silver": (180, 180, 190, 255),
    "tortoise": (90, 50, 30, 255),
    "ink": (20, 20, 30, 255),
    "rose_gold": (183, 110, 110, 255),
    "leather": (94, 58, 32, 255),
}


def new_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    """Return a fresh transparent RGBA canvas + drawing context."""
    img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def stamp_placeholder_mark(draw: ImageDraw.ImageDraw, label: str) -> None:
    """Draw a tiny 'PH' marker in the top-left corner so it's obvious this
    is a programmatically-generated placeholder, not real artwork.
    """
    try:
        font = ImageFont.truetype(
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24
        )
    except Exception:
        font = ImageFont.load_default()
    # Small label tag
    draw.rectangle([(8, 8), (90, 38)], fill=(255, 255, 255, 200))
    draw.text((14, 11), f"PH:{label}", fill=(180, 0, 0, 255), font=font)


def draw_hair_cap(draw, cx, top_y, width, height, color, style="smooth"):
    """Draw a basic hair cap shape covering the top of the head."""
    left = cx - width // 2
    right = cx + width // 2
    bottom = top_y + height
    if style == "smooth":
        draw.ellipse([left, top_y, right, bottom], fill=color)
    elif style == "pointed":
        # Triangle-ish peak at top
        draw.polygon(
            [(cx, top_y - 20), (left, bottom), (right, bottom)], fill=color
        )
        draw.ellipse([left, top_y, right, bottom], fill=color)
    elif style == "wavy":
        # Multiple overlapping ellipses for a wavy look
        for i in range(5):
            offset = (i - 2) * (width // 6)
            draw.ellipse(
                [cx + offset - 60, top_y, cx + offset + 60, bottom + 20],
                fill=color,
            )


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG")
    print(f"  wrote {path.relative_to(REPO_ROOT)}  ({img.size[0]}x{img.size[1]} {img.mode})")


# ============================================================================
# MALE HAIR — 10 styles
# ============================================================================

def gen_male_hair() -> None:
    print("Generating male hair...")
    out = ASSETS / "hair" / "male"
    styles = [
        # (id, color, style_hint, description)
        ("short_cropped", PALETTE["black"], "short cap, close to scalp"),
        ("short_side_part", PALETTE["brown_dark"], "side-parted, neat"),
        ("buzz_cut", PALETTE["brown_med"], "very short, stubble-like"),
        ("medium_swept", PALETTE["brown_dark"], "medium length, swept side"),
        ("curly_short", PALETTE["black"], "short curly top"),
        ("fade_high", PALETTE["brown_dark"], "high fade, longer top"),
        ("spiky", PALETTE["brown_med"], "spiky textured top"),
        ("wavy_medium", PALETTE["brown_light"], "wavy medium length"),
        ("man_bun", PALETTE["brown_dark"], "top knot with sides short"),
        ("clean_shaven", PALETTE["grey"], "very minimal, almost bald"),
    ]
    for hair_id, color, desc in styles:
        img, draw = new_canvas()
        # Hair cap covering top of head
        top = HEAD_TOP_Y - 5  # slight overhang above head top
        if hair_id == "buzz_cut":
            # Very thin layer
            draw.ellipse(
                [HEAD_CENTER_X - 170, top, HEAD_CENTER_X + 170, top + 80],
                fill=color,
            )
        elif hair_id == "clean_shaven":
            # Almost nothing — just slight shading
            draw.ellipse(
                [HEAD_CENTER_X - 165, top, HEAD_CENTER_X + 165, top + 50],
                fill=(*color[:3], 120),
            )
        elif hair_id == "spiky":
            # Triangle spikes on top
            for i in range(7):
                x = HEAD_CENTER_X - 150 + i * 50
                draw.polygon(
                    [(x, top + 80), (x + 25, top - 15), (x + 50, top + 80)],
                    fill=color,
                )
            draw.ellipse(
                [HEAD_CENTER_X - 170, top + 60, HEAD_CENTER_X + 170, top + 140],
                fill=color,
            )
        elif hair_id == "man_bun":
            # Short sides + bun on top
            draw.ellipse(
                [HEAD_CENTER_X - 170, top, HEAD_CENTER_X + 170, top + 80],
                fill=color,
            )
            draw.ellipse(
                [HEAD_CENTER_X - 50, top - 60, HEAD_CENTER_X + 50, top + 40],
                fill=color,
            )
        elif hair_id == "medium_swept" or hair_id == "wavy_medium":
            # Longer, swept to one side
            draw.ellipse(
                [HEAD_CENTER_X - 180, top, HEAD_CENTER_X + 180, top + 160],
                fill=color,
            )
            # Sweep diagonal
            draw.polygon(
                [
                    (HEAD_CENTER_X - 180, top + 60),
                    (HEAD_CENTER_X - 220, top + 200),
                    (HEAD_CENTER_X - 100, top + 180),
                    (HEAD_CENTER_X + 180, top + 80),
                ],
                fill=color,
            )
        elif hair_id == "curly_short":
            # Cluster of small circles for curly look
            for i in range(8):
                for j in range(3):
                    cx = HEAD_CENTER_X - 160 + i * 45
                    cy = top + 20 + j * 40
                    r = 35
                    draw.ellipse(
                        [cx - r, cy - r, cx + r, cy + r], fill=color
                    )
        else:
            # Default short cap
            draw.ellipse(
                [HEAD_CENTER_X - 170, top, HEAD_CENTER_X + 170, top + 120],
                fill=color,
            )
            # Side coverage
            draw.rectangle(
                [HEAD_CENTER_X - 170, top + 60, HEAD_CENTER_X - 130, top + 180],
                fill=color,
            )
            draw.rectangle(
                [HEAD_CENTER_X + 130, top + 60, HEAD_CENTER_X + 170, top + 180],
                fill=color,
            )
        stamp_placeholder_mark(draw, hair_id)
        save_png(img, out / f"{hair_id}.png")


# ============================================================================
# FEMALE HAIR — 10 styles
# ============================================================================

def gen_female_hair() -> None:
    print("Generating female hair...")
    out = ASSETS / "hair" / "female"
    styles = [
        ("long_straight", PALETTE["brown_dark"], "long straight down"),
        ("long_wavy", PALETTE["brown_light"], "long wavy"),
        ("shoulder_bob", PALETTE["black"], "shoulder-length bob"),
        ("pixie_cut", PALETTE["brown_med"], "short pixie"),
        ("ponytail", PALETTE["brown_dark"], "ponytail to one side"),
        ("hair_bun", PALETTE["black"], "bun on top"),
        ("long_braids", PALETTE["brown_dark"], "two long braids"),
        ("curly_volume", PALETTE["black"], "voluminous curly"),
        ("middle_part_long", PALETTE["brown_light"], "middle-parted long"),
        ("half_updo", PALETTE["blonde"], "half up, half down"),
    ]
    for hair_id, color, desc in styles:
        img, draw = new_canvas()
        top = HEAD_TOP_Y - 5
        if hair_id == "pixie_cut":
            # Very short, just a cap with slight side coverage
            draw.ellipse(
                [HEAD_CENTER_X - 175, top, HEAD_CENTER_X + 175, top + 100],
                fill=color,
            )
        elif hair_id in ("long_straight", "middle_part_long"):
            # Long flow down past shoulders
            draw.ellipse(
                [HEAD_CENTER_X - 200, top, HEAD_CENTER_X + 200, top + 130],
                fill=color,
            )
            # Long sides flowing down
            draw.rectangle(
                [HEAD_CENTER_X - 220, top + 80, HEAD_CENTER_X - 130, 900],
                fill=color,
            )
            draw.rectangle(
                [HEAD_CENTER_X + 130, top + 80, HEAD_CENTER_X + 220, 900],
                fill=color,
            )
            if hair_id == "middle_part_long":
                # Middle part — triangle gap at top
                draw.polygon(
                    [
                        (HEAD_CENTER_X - 30, top + 5),
                        (HEAD_CENTER_X, top + 100),
                        (HEAD_CENTER_X + 30, top + 5),
                    ],
                    fill=(0, 0, 0, 0),
                )
        elif hair_id == "long_wavy":
            # Wavy long — overlapping ellipses down the sides
            draw.ellipse(
                [HEAD_CENTER_X - 200, top, HEAD_CENTER_X + 200, top + 130],
                fill=color,
            )
            for i in range(8):
                y = top + 100 + i * 80
                # Left wavy strand
                draw.ellipse(
                    [HEAD_CENTER_X - 230, y, HEAD_CENTER_X - 130, y + 80],
                    fill=color,
                )
                # Right wavy strand
                draw.ellipse(
                    [HEAD_CENTER_X + 130, y, HEAD_CENTER_X + 230, y + 80],
                    fill=color,
                )
        elif hair_id == "shoulder_bob":
            # Bob — ends at shoulder
            draw.ellipse(
                [HEAD_CENTER_X - 195, top, HEAD_CENTER_X + 195, top + 130],
                fill=color,
            )
            draw.rectangle(
                [HEAD_CENTER_X - 195, top + 80, HEAD_CENTER_X - 130, 420],
                fill=color,
            )
            draw.rectangle(
                [HEAD_CENTER_X + 130, top + 80, HEAD_CENTER_X + 195, 420],
                fill=color,
            )
        elif hair_id == "ponytail":
            # Cap + ponytail sweeping to one side
            draw.ellipse(
                [HEAD_CENTER_X - 175, top, HEAD_CENTER_X + 175, top + 120],
                fill=color,
            )
            # Ponytail off the right side
            draw.polygon(
                [
                    (HEAD_CENTER_X + 130, top + 60),
                    (HEAD_CENTER_X + 400, top + 250),
                    (HEAD_CENTER_X + 350, top + 400),
                    (HEAD_CENTER_X + 100, top + 200),
                ],
                fill=color,
            )
        elif hair_id == "hair_bun":
            # Cap + bun on top
            draw.ellipse(
                [HEAD_CENTER_X - 175, top, HEAD_CENTER_X + 175, top + 120],
                fill=color,
            )
            draw.ellipse(
                [HEAD_CENTER_X - 70, top - 80, HEAD_CENTER_X + 70, top + 60],
                fill=color,
            )
        elif hair_id == "long_braids":
            # Two braids hanging down
            draw.ellipse(
                [HEAD_CENTER_X - 195, top, HEAD_CENTER_X + 195, top + 130],
                fill=color,
            )
            for side in (-1, 1):
                bx = HEAD_CENTER_X + side * 160
                for i in range(10):
                    y = top + 130 + i * 70
                    draw.ellipse(
                        [bx - 35, y, bx + 35, y + 60], fill=color
                    )
        elif hair_id == "curly_volume":
            # Voluminous curly — many circles around the head
            for angle_step in range(0, 360, 18):
                import math
                rad = math.radians(angle_step)
                # Only top half + sides
                if 0 <= angle_step <= 180:
                    r = 220
                    cx = int(HEAD_CENTER_X + r * math.cos(rad))
                    cy = int(top + 80 + r * math.sin(rad) * 0.9)
                    draw.ellipse(
                        [cx - 50, cy - 50, cx + 50, cy + 50], fill=color
                    )
            # Volume on top
            for i in range(5):
                for j in range(2):
                    cx = HEAD_CENTER_X - 150 + i * 75
                    cy = top + 20 + j * 50
                    draw.ellipse(
                        [cx - 50, cy - 50, cx + 50, cy + 50], fill=color
                    )
        elif hair_id == "half_updo":
            # Top portion pulled back, bottom loose
            draw.ellipse(
                [HEAD_CENTER_X - 195, top, HEAD_CENTER_X + 195, top + 130],
                fill=color,
            )
            # Top bun (smaller)
            draw.ellipse(
                [HEAD_CENTER_X - 50, top - 50, HEAD_CENTER_X + 50, top + 30],
                fill=color,
            )
            # Loose sides
            draw.rectangle(
                [HEAD_CENTER_X - 215, top + 80, HEAD_CENTER_X - 130, 700],
                fill=color,
            )
            draw.rectangle(
                [HEAD_CENTER_X + 130, top + 80, HEAD_CENTER_X + 215, 700],
                fill=color,
            )
        stamp_placeholder_mark(draw, hair_id)
        save_png(img, out / f"{hair_id}.png")


# ============================================================================
# GLASSES — 4 styles
# ============================================================================

def gen_glasses() -> None:
    print("Generating glasses...")
    out = ASSETS / "glasses"
    styles = [
        ("round_black", PALETTE["ink"], "round black frames"),
        ("square_black", PALETTE["ink"], "square black frames"),
        ("aviator_gold", PALETTE["gold"], "aviator gold frames"),
        ("cat_eye", PALETTE["rose_gold"], "cat-eye frames (female)"),
    ]
    # Glasses sit at eye line. Two lenses + bridge + temple arms.
    eye_y = EYE_LINE_Y
    lens_w = 100
    lens_h = 70
    left_cx = HEAD_CENTER_X - 90
    right_cx = HEAD_CENTER_X + 90
    for glasses_id, color, desc in styles:
        img, draw = new_canvas()
        if glasses_id == "round_black":
            for cx in (left_cx, right_cx):
                draw.ellipse(
                    [cx - 50, eye_y - 50, cx + 50, eye_y + 50],
                    outline=color, width=8,
                )
        elif glasses_id == "square_black":
            for cx in (left_cx, right_cx):
                draw.rounded_rectangle(
                    [cx - 55, eye_y - 45, cx + 55, eye_y + 45],
                    radius=8, outline=color, width=8,
                )
        elif glasses_id == "aviator_gold":
            for cx in (left_cx, right_cx):
                # Teardrop shape: ellipse with pointed bottom
                draw.ellipse(
                    [cx - 55, eye_y - 40, cx + 55, eye_y + 60],
                    outline=color, width=6,
                )
        elif glasses_id == "cat_eye":
            for cx in (left_cx, right_cx):
                # Cat-eye: rectangle with upturned outer corners
                draw.polygon(
                    [
                        (cx - 55, eye_y + 30),
                        (cx - 60, eye_y - 35),
                        (cx + 50, eye_y - 45),
                        (cx + 65, eye_y - 50),  # upturned corner
                        (cx + 55, eye_y + 30),
                    ],
                    outline=color, width=6,
                )
        # Bridge between lenses
        draw.line(
            [(left_cx + 50, eye_y), (right_cx - 50, eye_y)],
            fill=color, width=8,
        )
        # Temple arms extending to ears (head sides)
        draw.line(
            [(left_cx - 50, eye_y), (HEAD_CENTER_X - 220, eye_y + 20)],
            fill=color, width=6,
        )
        draw.line(
            [(right_cx + 50, eye_y), (HEAD_CENTER_X + 220, eye_y + 20)],
            fill=color, width=6,
        )
        stamp_placeholder_mark(draw, glasses_id)
        save_png(img, out / f"{glasses_id}.png")


# ============================================================================
# ACCESSORIES — 2 styles (watch + necklace)
# ============================================================================

def gen_accessories() -> None:
    print("Generating accessories...")
    out = ASSETS / "accessories"

    # 1. Wrist watch — positioned at left wrist (typical avatar right hand
    # hangs at side, wrist around Y=1100, X=300)
    img, draw = new_canvas()
    watch_color = PALETTE["silver"]
    strap_color = PALETTE["leather"]
    # Strap (two horizontal bars)
    cx, cy = 280, 1100
    draw.rectangle([cx - 60, cy - 30, cx + 60, cy + 30], fill=strap_color)
    # Watch face (circle)
    draw.ellipse(
        [cx - 35, cy - 35, cx + 35, cy + 35], fill=watch_color
    )
    # Watch hands
    draw.line([(cx, cy), (cx, cy - 20)], fill=PALETTE["ink"], width=3)
    draw.line([(cx, cy), (cx + 15, cy + 5)], fill=PALETTE["ink"], width=3)
    # Hour markers
    for i in range(12):
        import math
        rad = math.radians(i * 30 - 90)
        mx = int(cx + 25 * math.cos(rad))
        my = int(cy + 25 * math.sin(rad))
        draw.ellipse([mx - 2, my - 2, mx + 2, my + 2], fill=PALETTE["ink"])
    stamp_placeholder_mark(draw, "wrist_watch")
    save_png(img, out / "wrist_watch.png")

    # 2. Pendant necklace — positioned at neck/collarbone
    img, draw = new_canvas()
    chain_color = PALETTE["gold"]
    pendant_color = PALETTE["gold"]
    # Chain — curved arc from one shoulder to the other, dipping at the neck
    chain_top_y = NECK_Y + 20
    chain_dip_y = NECK_Y + 120
    draw.arc(
        [HEAD_CENTER_X - 220, chain_top_y, HEAD_CENTER_X + 220, chain_dip_y + 80],
        start=0, end=180, fill=chain_color, width=4,
    )
    # Pendant at the dip
    px, py = HEAD_CENTER_X, chain_dip_y + 60
    draw.ellipse(
        [px - 25, py - 35, px + 25, py + 35], fill=pendant_color,
    )
    # Small inner detail on pendant
    draw.ellipse(
        [px - 12, py - 20, px + 12, py + 20],
        outline=PALETTE["silver"], width=2,
    )
    stamp_placeholder_mark(draw, "pendant_necklace")
    save_png(img, out / "pendant_necklace.png")


def main() -> None:
    print(f"Generating placeholder avatar layers under {ASSETS.relative_to(REPO_ROOT)}/")
    print(f"Canvas contract: {CANVAS_W}x{CANVAS_H} RGBA, head_top_y={HEAD_TOP_Y}")
    print("-" * 70)
    gen_male_hair()
    gen_female_hair()
    gen_glasses()
    gen_accessories()
    print("-" * 70)
    print("Done. Run `python3 scripts/check_assets.py --strict` to verify.")


if __name__ == "__main__":
    main()
