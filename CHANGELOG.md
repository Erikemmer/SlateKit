# Changelog – SlateKit

The look of a slate-grey, Final-Cut-shaped desktop app, as reusable SwiftUI
parts. Shared by **Selector** (photo culling) and **Shelf** (eBook manager).

Both apps bind this package by **tag**, never by path, so a change here reaches
an app only when that app raises its pin. Which version each app is on is part
of the app's own history, not of this file.

## 0.5.1 — 2026-09-22

**What 0.5.0's `onDelete` should have used.** Live-tested against a real
window (not just the unit tests, which cannot exercise a key event at all):
⏎ and ␣ open the row exactly as 0.5.0 intended, but the Delete key did
nothing — `.onKeyPress(.delete)` never fires on macOS, because the key's
`keyDown` is claimed by AppKit's own key-binding machinery
(`deleteBackward:` and its relatives) before SwiftUI's `onKeyPress` sees
it. ⏎/␣ are unaffected because they are not text-editing selectors.
Switched to `.onDeleteCommand`, the dedicated SwiftUI hook for exactly this
key on macOS.

## 0.5.0 — 2026-09-22

**A recent-session row could be reached by Tab since 0.4.0 (it draws
`slateFocusRing` and is a real `Button`) but not opened from the keyboard —
0.4.0 gave `SlateSidebarRow` explicit ⏎/␣ handling and missed this row, the
same gap 0.4.1 was meant to close. Found live: reaching it by Tab and
pressing ⏎ did nothing; a `Button`'s own key handling cannot be assumed to
fire in every host, which is exactly why `SlateSidebarRow` needed its own
`.onKeyPress` rather than relying on it.**

- **`SlateRecentRow` answers to ⏎ and ␣ explicitly**, the same fix
  `SlateSidebarRow` got in 0.4.0, and both are consumed so a host's own ␣
  shortcut (a loupe zoom, say) does not also fire while the row is focused.
- **A new `onDelete` parameter** removes the entry on the Delete key, with no
  confirmation of its own — a host that wants one asks before calling it, the
  same division `SlateSidebarRow`'s own delete accessory already uses.
- **A new `label` parameter** replaces the raw `path` VoiceOver would
  otherwise read letter by letter, the same fallback shape as
  `SlateGridCell`'s: falls back to `name` alone when a host does not supply
  one. No appearance change; both parameters default to their old absence.

## 0.4.1 — 2026-09-19

What 0.4.0 should have included: four more things the accessibility tree was
not saying, all found by dumping the tree of a real window rather than by
reading the source. No appearance change, nothing behind an option.

- **A section heading says it is one.** `SlateSidebarSection` and
  `SlateInspectorSection` carry `.isHeader`, so VoiceOver's heading navigation
  moves from LIBRARY to SHELVES to TAGS instead of walking ninety-seven author
  rows to reach FORMATS.
- **A token field has a name.** `SlateTokenField` draws its placeholder through
  `prompt:`, and the title it also passes does not reach the tree that way: the
  field arrived with a help string and nothing else. It is labelled with its
  placeholder now — "Add tag… (T)".
- **An editable row stops saying its name twice.** 0.4.0 gave the field the
  row's name; the name drawn beside it is hidden now, so a reader hears
  "Publisher, Gollancz" rather than "Publisher" and then "Publisher, Gollancz".

## 0.4.0 — 2026-09-19

**Everything a keyboard or VoiceOver could not reach.** Nothing here is an
appearance change and nothing is behind an option: a control that announced
nothing now announces itself, and a control that drew no focus ring draws one
while it is focused. At rest every one of them looks exactly as it did on
0.3.1, which is what makes this safe to adopt without looking at a screenshot.

### Added — a sidebar row is a button, and says so

`SlateSidebarRow` has had a tap gesture, `.focusable` and ⏎/␣ handling since
0.2.0. What it never had was a **role**: the accessibility tree showed an
`AXImage` and two `AXStaticText` per row, no `AXButton`, no action. VoiceOver
read the words and offered nothing to do with them, so a whole sidebar — every
collection, every tag, every author — was unreachable to anyone not using a
mouse. The combined element now carries `.isButton` and a default action
(`AXPress`, what ⌃⌥␣ sends) whenever the row has an action at all.

### Added — a grid cell is one element with a name

A cell arrived as its picture, its caption and one static text per badge: four
separate stops with no relation to each other, read in **layout** order, which
put the picture's own SF Symbol name ("book.closed") and the badges before the
title. A grid of 5 000 books was 15 000 stops.

`SlateGridCell` is now a single element with `.isButton`, `.isSelected` when it
is, and a label. The new `label:` parameter is where a host says what the badges
mean — "Dune, Frank Herbert, read, DRM" — and it **defaults to the caption**, so
a host that passes nothing gets what the cell always said. `spokenLabel` is the
decision, lifted out of the body so a test can read it.

### Added — a name for a field that has its name beside it

`SlateEditableRow` draws "Publisher" on the left and the field on the right, and
the field's own accessibility name was its *placeholder*. A filled row announced
a value with nothing saying what it was the value of; an empty one announced the
prompt twice. The row hands its name down now (`SlateEditableText` takes an
`accessibilityLabel`).

### Added — a rating that can be set, not only read

`SlateStarRating` hides its five buttons behind `children: .ignore`, which is
right — five stops all called "3 stars (3)" is not how a rating reads — but it
left the control readable and **not settable**: nothing in the tree to press.
It takes an adjustable action now, the one VoiceOver already has keys for
(⌃⌥→, then ↑ and ↓). `SlateStarRating.adjusted(_:_:)` is the step, stopping at
five and at nought, with a test for both ends.

### Added — `SlateFocusRing`, and every hand-drawn control draws it

`.buttonStyle(.plain)` is how this package gets buttons that look like the rest
of it, and it is also how a button stops drawing a focus ring. A keyboard-only
user could Tab through an inspector and never see where they had landed. The
ring was drawn inline in `SlateSidebarRow` and nowhere else; it is now one
shape, `.slateFocusRing(_:)` and `.slateCapsuleFocusRing(_:)`, drawn by the
sidebar row, the five stars, a chip's ✕, a suggestion chip and a recent-library
row. `strokeBorder` rather than `stroke`, so it does not spill a point over the
neighbour above.

### Added — two decorative symbols stop announcing themselves

The folder in `SlateRecentRow` and the arrow in `SlateDropZone` are hidden from
the tree. The words beside them say the same thing; their SF Symbol names
("questionmark.folder", "arrow.down.doc") said it in none.

### Nothing was taken away

`SlateGridCell.init` gained a parameter with a default, which is the only API
change, and it is source-compatible. Selector's pin is 0.1.6 and Shelf's is
0.3.1; raising either to 0.4.0 changes what the window *says* and not what it
*looks like*.

## 0.3.1 — 2026-09-17

**Raising a pin from 0.1.6 to 0.3.1 changes nothing about how an app looks.**
0.3.0 did change it, in three places, and this release turns all three into
options that default to the older look. Nothing here is a new feature; it is
0.3.0 made safe to adopt.

### The three appearance changes are options now

A package two apps bind by tag has one obligation its own taste does not
override: an app that raises its pin for one fix must not find a second thing
redrawn on the way. `SlateChip` and `SlateStarRating` both existed at 0.1.6,
which is where Selector sits, so both keep their 0.1.6 look unless asked.

| what 0.3.0 changed | how to ask for it now | the default |
|---|---|---|
| chips grey instead of accent | `SlateChip(style: .neutral)` | `.accent`, the fill since 0.1.0 |
| the ✕ fades in under the pointer | `SlateChip(removeButton: .onHover)` | `.always`, as since 0.1.0 |
| no "3/5" beside the stars | `SlateStarRating(label: .unratedOnly)` | `.value`, as since 0.1.0 |

`SlateTokenField` takes `chipStyle:` and `chipRemoveButton:` and hands them
straight down, defaulting the way `SlateChip` itself does — a control that drew
a quieter chip than the host draws beside it would be the same surprise one
level further in. Shelf passes `.neutral` and `.onHover` at every call site and
looks exactly as it did on 0.3.0.

`Unrated` stays in both readings: zero is the one rating with no picture of its
own, and five hollow stars mean "not rated" only to somebody who has already
learned that they do.

The placeholder colour from 0.3.0 is **not** in that table, and deliberately.
`SlateEditableFields` arrived in 0.2.0, after 0.1.6, so no shipping app has ever
seen those fields look any other way. There is nothing to be compatible with.

`SlateChipStyle.fill`, `SlateChipRemoveButton.opacity` and
`SlateStarRating.labelText` are the decisions lifted out of the view bodies, so
a test can read a default that would otherwise be buried in a `ViewBuilder`.
Seven tests state them. `Scripts/check-contrast.py` checks both chip fills, since
both are now drawn at once by different apps: accent 6.91:1, neutral 8.63:1.

### The package speaks German again

0.3.0 removed the German localisation, reasoning that Shelf is English until its
own Sprint 7 and nine German words would sit oddly in an English window. That
was true about Shelf and beside the point about the package: **Selector ships
German**, and removing these strings does not spare Selector a mixed window — it
puts nine English words into its German one.

A package that two apps bind at different versions is precisely the thing that
lets them be at different points. `Resources/Localizable.xcstrings`, the
`resources:` clause and the eight `String(localized:)` call sites are back, all
nine keys with them.

`Unrated` is now **"Ohne Bewertung"** rather than 0.1.5's "Unbewertet":
"Unbewertet" reads as a verdict on the book, "Ohne Bewertung" states what is
missing, which is what an empty field is saying.

Three tests hold it there, each watched failing before it was kept: every key
has a German unit in state `translated`; every plain-literal `String(localized:)`
in the sources is a key the catalogue knows; and the four keys the compiler
builds out of an interpolation are spelled out, because renaming one of those
still compiles and falls back to English without a word.

The catalogue is read as a *file*, not through `Bundle.module` — a missing
translation still builds into a valid bundle and falls back at runtime silently,
so the bundle is the one place that cannot answer the question.

### Breaking

Nothing. Every initialiser gained parameters with defaults, and a call site
written against 0.1.6, 0.2.1 or 0.3.0 compiles unchanged. A call site on 0.3.0
that *wants* 0.3.0's look now has to say so — that is the one thing to check
when raising a pin from exactly 0.3.0, and only Shelf is on it.

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
