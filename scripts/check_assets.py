"""Validate avatar PNG assets against the contract in ANCHOR_SPEC.md.

Exits non-zero when any PNG violates the contract:
  - Canvas size != 1024x1536
  - Color mode != RGBA
  - File is fully transparent (no visible figure)
  - Head-top Y or feet-bottom Y outside +/-15 px tolerance

Usage:
    python3 scripts/check_assets.py
    python3 scripts/check_assets.py --strict   # treat warnings as errors
"""
import argparse
import sys
from pathlib import Path
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / 'assets' / 'avatars'

EXPECTED_SIZE = (1024, 1536)
EXPECTED_MODE = 'RGBA'

# Measured anchor targets (per ANCHOR_SPEC.md appendix).
HEAD_TOP_TARGET = 31
FEET_BOTTOM_TARGET = 1507
TOLERANCE_PX = 15


def check_png(path: Path) -> list[str]:
    """Return a list of violation messages. Empty list = pass."""
    issues: list[str] = []
    try:
        im = Image.open(path)
    except Exception as e:
        return [f'unreadable: {e}']

    if im.size != EXPECTED_SIZE:
        issues.append(f'size {im.size} != {EXPECTED_SIZE}')
    if im.mode != EXPECTED_MODE:
        issues.append(f'mode {im.mode} != {EXPECTED_MODE}')

    # Anchor check -- only meaningful for RGBA PNGs.
    if im.mode == 'RGBA':
        alpha = im.split()[-1]
        bbox = alpha.getbbox()
        if bbox is None:
            issues.append('fully transparent (no visible figure)')
        else:
            left, upper, right, lower = bbox
            if abs(upper - HEAD_TOP_TARGET) > TOLERANCE_PX:
                issues.append(
                    f'head_top_y={upper} (target {HEAD_TOP_TARGET}, '
                    f'+/-{TOLERANCE_PX} px tolerance)'
                )
            if abs(lower - FEET_BOTTOM_TARGET) > TOLERANCE_PX:
                issues.append(
                    f'feet_bottom_y={lower} (target {FEET_BOTTOM_TARGET}, '
                    f'+/-{TOLERANCE_PX} px tolerance)'
                )
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--strict', action='store_true',
                        help='treat warnings (out-of-tolerance anchors) as errors')
    args = parser.parse_args()

    if not ASSETS.exists():
        print(f'ERROR: assets directory not found at {ASSETS}', file=sys.stderr)
        return 2

    pngs = sorted(ASSETS.rglob('*.png'))
    if not pngs:
        print(f'ERROR: no PNG files found under {ASSETS}', file=sys.stderr)
        return 2

    print(f'Checking {len(pngs)} PNG file(s) under {ASSETS.relative_to(REPO_ROOT)}/')
    print(f'Contract: size={EXPECTED_SIZE}, mode={EXPECTED_MODE}, '
          f'head_top_y={HEAD_TOP_TARGET}+/-{TOLERANCE_PX}, '
          f'feet_bottom_y={FEET_BOTTOM_TARGET}+/-{TOLERANCE_PX}')
    print('-' * 80)

    passes = 0
    fails = 0
    for png in pngs:
        rel = png.relative_to(REPO_ROOT)
        issues = check_png(png)
        if not issues:
            print(f'  PASS  {rel}')
            passes += 1
        else:
            is_hard = any(
                'size' in i or 'mode' in i or 'transparent' in i
                for i in issues
            )
            level = 'FAIL' if (args.strict or is_hard) else 'WARN'
            print(f'  {level}  {rel}')
            for issue in issues:
                print(f'         - {issue}')
            if level == 'FAIL':
                fails += 1

    print('-' * 80)
    warns = len(pngs) - passes - fails
    print(f'Summary: {passes} passed, {fails} failed, {warns} warnings')
    return 0 if fails == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
