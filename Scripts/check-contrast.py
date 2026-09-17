#!/usr/bin/env python3
"""WCAG 2.1 AA contrast check for SlateKit's palette.

Reads the actual RGB literals out of SlateTheme.swift — this never hand-copies
a colour, so it cannot silently go stale when the palette changes — and checks
every text/background pair the two apps built on this package really draw:
every `Slate.*` text colour on every `Slate.*` panel background, the primary
button's black-on-accent fill, the banner's white-on-tint fill, the active
sidebar row's tinted background, and the five label swatches used as
non-text graphical dots (WCAG 1.4.11, 3:1, not the 4.5:1 text threshold).

Usage: python3 Scripts/check-contrast.py
Exit code is 1 if any pair fails, so `make contrast` can gate on it.
"""

import re
import sys
from pathlib import Path

THEME_FILE = Path(__file__).resolve().parent.parent / "Sources" / "SlateKit" / "SlateTheme.swift"

AA_NORMAL = 4.5
AA_NONTEXT = 3.0


def parse_colors(source: str) -> dict[str, tuple[float, float, float]]:
    """Every `let name = Color(...)` and swatch `case name: return Color(...)` in the file."""
    colors: dict[str, tuple[float, float, float]] = {}

    let_pattern = re.compile(
        r"let\s+(\w+)\s*=\s*Color\("
        r"(?:red:\s*([\d.]+),\s*green:\s*([\d.]+),\s*blue:\s*([\d.]+)"
        r"|white:\s*([\d.]+))"
    )
    for m in let_pattern.finditer(source):
        name = m.group(1)
        if m.group(2) is not None:
            colors[name] = (float(m.group(2)), float(m.group(3)), float(m.group(4)))
        else:
            w = float(m.group(5))
            colors[name] = (w, w, w)

    case_pattern = re.compile(
        r"case\s+\.(\w+):\s*return\s*Color\(red:\s*([\d.]+),\s*green:\s*([\d.]+),\s*blue:\s*([\d.]+)\)"
    )
    for m in case_pattern.finditer(source):
        colors[f"swatch.{m.group(1)}"] = (float(m.group(2)), float(m.group(3)), float(m.group(4)))

    return colors


def luminance(rgb: tuple[float, float, float]) -> float:
    def lin(c: float) -> float:
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(c1: tuple[float, float, float], c2: tuple[float, float, float]) -> float:
    l1, l2 = luminance(c1), luminance(c2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def composite(fg: tuple[float, float, float], bg: tuple[float, float, float], alpha: float):
    return tuple(fg[i] * alpha + bg[i] * (1 - alpha) for i in range(3))


def main() -> int:
    source = THEME_FILE.read_text()
    colors = parse_colors(source)

    required = [
        "windowBackground", "panelBackground", "contentBackground",
        "textPrimary", "textSecondary", "accent", "affirm", "deny",
        "swatch.red", "swatch.yellow", "swatch.green", "swatch.blue", "swatch.purple",
    ]
    missing = [name for name in required if name not in colors]
    if missing:
        print(f"error: SlateTheme.swift no longer defines {missing} — update this script's pairing list")
        return 2

    backgrounds = {k: colors[k] for k in ("windowBackground", "panelBackground", "contentBackground")}
    text_colors = {
        "textPrimary": colors["textPrimary"],
        "textSecondary": colors["textSecondary"],
        "accent (as text)": colors["accent"],
        "affirm (as text)": colors["affirm"],
        "deny (as text)": colors["deny"],
    }
    black, white = (0.0, 0.0, 0.0), (1.0, 1.0, 1.0)

    rows: list[tuple[str, float, float]] = []

    # Every text colour Selector actually draws on every panel background.
    for tname, tcolor in text_colors.items():
        for bname, bcolor in backgrounds.items():
            rows.append((f"{tname} on {bname}", contrast(tcolor, bcolor), AA_NORMAL))

    # SlatePrimaryButton: black text on the accent fill (SlateWelcome.swift).
    rows.append(("black text on accent (SlatePrimaryButton fill)", contrast(black, colors["accent"]), AA_NORMAL))

    # SlateBanner: fixed black text (all three tints are light enough that white
    # failed WCAG AA once composited — as low as 1.9:1 on accent) on tint at
    # 90% opacity, composited over contentBackground (SlateStatusBar.swift).
    for tname in ("deny", "affirm", "accent"):
        bg = composite(colors[tname], backgrounds["contentBackground"], 0.9)
        rows.append((f"black text on {tname}@90% (SlateBanner, over contentBackground)", contrast(black, bg), AA_NORMAL))

    # Active sidebar row: accent at 18% opacity over panelBackground. The title
    # (always textPrimary) and the count (textPrimary once active, textSecondary
    # otherwise — the same switch SlateGridCell uses) on top
    # (SlateSidebar.swift SlateSidebarRow isActive state).
    active_row_bg = composite(colors["accent"], backgrounds["panelBackground"], 0.18)
    rows.append(("textPrimary on active sidebar row (title, or count once active)",
                  contrast(colors["textPrimary"], active_row_bg), AA_NORMAL))
    rows.append(("textSecondary on inactive sidebar row's own background (count, row not active)",
                  contrast(colors["textSecondary"], backgrounds["panelBackground"]), AA_NORMAL))

    # SlateChip, both fills. The chip is drawn accent-tinted by default and grey
    # when a host asks for `.neutral`, and 0.3.1 made that a choice rather than a
    # change precisely so both are in use at once: Selector draws the accent one,
    # Shelf the grey one. Both are therefore checked — a pair that only one of
    # two apps draws is still a pair somebody reads.
    chip_accent_bg = composite(colors["accent"], backgrounds["panelBackground"], 0.22)
    rows.append(("textPrimary on SlateChip .accent (accent@22% over panelBackground)",
                  contrast(colors["textPrimary"], chip_accent_bg), AA_NORMAL))
    chip_bg = composite(white, backgrounds["panelBackground"], 0.10)
    rows.append(("textPrimary on SlateChip .neutral (white@10% over panelBackground)",
                  contrast(colors["textPrimary"], chip_bg), AA_NORMAL))
    # The capsule's own edge against the panel is 1.37:1 and is deliberately not
    # tested at WCAG 1.4.11's 3:1. That rule covers a boundary you need in order
    # to *identify* a component; a tag is identified by the word inside it, which
    # is the pair above. The capsule groups the word with its ✕ and separates one
    # tag from the next — spacing would do as much — and a fill light enough to
    # reach 3:1 here would be a row of pale pills shouting louder than the
    # values around them. The old accent-tinted chip did not reach 3:1 either.

    # Label swatches as non-text graphical dots (sidebar icon, grid badge) — 3:1, not 4.5:1.
    for sname in ("red", "yellow", "green", "blue", "purple"):
        for bname in ("panelBackground", "contentBackground"):
            rows.append((f"swatch.{sname} dot on {bname}", contrast(colors[f"swatch.{sname}"], backgrounds[bname]), AA_NONTEXT))

    width = max(len(label) for label, _, _ in rows)
    print(f"{'Pair':<{width}} {'Ratio':>7}  {'Needs':>6}  Result")
    print("-" * (width + 28))
    failures = []
    for label, ratio, threshold in rows:
        ok = ratio >= threshold
        print(f"{label:<{width}} {ratio:>6.2f}:1  {threshold:>5.1f}:1  {'PASS' if ok else 'FAIL'}")
        if not ok:
            failures.append((label, ratio, threshold))

    print()
    if failures:
        print(f"{len(failures)} pair(s) fail WCAG AA:")
        for label, ratio, threshold in failures:
            print(f"  - {label}: {ratio:.2f}:1 (needs {threshold:.1f}:1)")
        return 1
    print("All pairs pass WCAG AA.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
