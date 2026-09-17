# Changelog – SlateKit

The look of a slate-grey, Final-Cut-shaped desktop app, as reusable SwiftUI
parts. Shared by **Selector** (photo culling) and **Shelf** (eBook manager).

Both apps bind this package by **tag**, never by path, so a change here reaches
an app only when that app raises its pin. Which version each app is on is part
of the app's own history, not of this file.

## 0.3.0 — 2026-09-17

Four corrections, all of them to things the package drew louder or more
talkative than it should have. Three of them change what **Selector** looks like
as well as Shelf; Selector is pinned to 0.1.6 and keeps the old look until it
raises that pin.

### The package speaks English again

The German localisation added in 0.1.5 is removed: `Localizable.xcstrings`, the
`resources:` clause in `Package.swift`, and the eight `String(localized:)` calls.

Nine strings — the shortcut sheet's "Close", the star rating's help text,
VoiceOver label and value, and the chip's "Remove" — are all the text this
package draws rather than takes as a parameter. Localising them on their own
was a mistake of sequence. Shelf and Selector are both English until their own
Sprint 7, so on a German Mac those nine words would have appeared in German in
the middle of an otherwise English window: two languages in one inspector,
which is worse than one language that is not yet the user's.

**Localising is a decision about a whole app, taken for the whole app at once.**
It comes back when both apps localise together; the strings are in 0.1.5's tree
until then.

### `SlateStarRating` no longer writes the number beside the stars

Five drawn stars are the statement. A "3/5" next to them is the same sentence
in digits, and it is the digits that make a rating read as a field to be filled
in rather than as a value to be read.

`Unrated` stays. Zero is the one rating with no picture of its own: five hollow
stars mean "not rated" only to somebody who has already learned that they do.

The VoiceOver value (`3 of 5`) is unchanged — that reading is the whole of what
a screen reader gets, so it has to carry the number the eye takes from the
picture.

### `SlateChip` is grey, and its ✕ appears on hover

The chip has been `Slate.accent.opacity(0.22)` since 0.1.0. That colour has one
job in this palette — *selected*: the active sidebar row, the chosen grid cell,
a focused field's border — and eight tags wearing it make a window look as
though eight things were chosen. The chip is now the same neutral white lift a
field takes under the pointer (`Color.white.opacity(0.10)`), so a chip and a
field read as the same material.

The remove button is faded rather than removed when the pointer is elsewhere.
`if isHovered` would take it out of the layout, and a row of chips that each
grow a few points as the pointer crosses them re-flows *under* the pointer,
moving the ✕ away from the click that is coming. Opacity keeps the width fixed,
keeps the button in the accessibility tree, and keeps it clickable. It also
shows itself when it takes keyboard focus, so a keyboard-only user can still
reach it.

`Scripts/check-contrast.py` gained the pair that is actually drawn —
`textPrimary` on the chip fill, 8.63:1. The capsule's own edge against the
panel is 1.37:1 and is deliberately *not* held to WCAG 1.4.11's 3:1, with the
reason written where the check would have been: a tag is identified by the word
inside it, not by the capsule, and a fill light enough to reach 3:1 would be a
row of pale pills louder than the values around them. The old accent chip did
not reach 3:1 either.

### An empty field prompts in a label's colour

Every editable field carries `Slate.textPrimary`, and SwiftUI hands that colour
to the placeholder as well unless it is told otherwise. An empty inspector
therefore read as a filled one: a book with no publisher showed "Add publisher…"
in exactly the ink the next book's "Orbit" is written in.

`SlateEditableText` and `SlateTokenField` now pass a `prompt:` built in
`Slate.textSecondary` — the colour the name beside the field already wears, so a
prompt sits with the labels rather than with the values. The title argument
stays, because it is what the accessibility tree takes as the field's name.

## 0.2.1 — 2026-09-17

- The editable fields no longer look like a form: a field's background appears
  only while it is focused or under the pointer. Nine faintly filled boxes in a
  280-point column read as something to be completed; the same column with
  nothing at rest reads as values that happen to be editable.
- `SlateTokenField` gained a `help:` parameter. Handed in by the host with
  `.help()`, the entry field's help text reached every chip as well, so each one
  claimed "⏎ adds, ⌫ removes the last one" instead of its own "Remove science
  fiction". Found in the accessibility tree.

## 0.2.0 — 2026-09-17

- `SlateEditableRow`, `SlateEditableBlock` and `SlateTokenField`: editable
  inspector fields, sized like the `SlateValueRow` they replace. A field is
  finished by ⏎ or by losing focus — never per keystroke — and Escape puts the
  old value back.
- `SlateFieldNote` for the line under a field that says why a value was refused.
- `SlateShortcutLine` wraps its labels instead of squeezing them.

## 0.1.6 — 2026-09-16

- The star rating's accessibility value used a key the runtime never asks for.

## 0.1.5 — 2026-09-16

- German localisation for the package's own strings. **Removed again in 0.3.0**
  — see above for why.

## 0.1.4 — 2026-09-16

- The shortcut sheet sizes to its content instead of a fixed 560×480.

## 0.1.3 — 2026-09-16

- `SlateSidebarRow` gained an optional trailing `accessory` view builder, for a
  delete button. **It sits before `action`**, so a trailing closure at a call
  site written against 0.1.2 binds to the accessory instead. Two call sites in
  Shelf had to name `action:` when it raised its pin.

## 0.1.2 — 2026-09-16

- Keyboard focus and VoiceOver labels for the interactive pieces. `.plain`
  buttons opt out of the Tab order on macOS, so every one of them needed
  `.focusable()`.

## 0.1.1 — 2026-09-16

- Three colour pairs that failed WCAG AA. `Slate.deny` was lightened from
  (0.95, 0.30, 0.30), which read at 4.0:1 on a panel.

## 0.1.0 — 2026-09-15

- The palette, the metrics, and the shared views: welcome screen, sidebar, grid
  cell, inspector, status bar, overlay panel, shortcut sheet.
