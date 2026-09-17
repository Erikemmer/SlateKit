import SwiftUI
import Testing

@testable import SlateKit

/// Two apps bind this package by tag, and they are not on the same one.
/// Selector sits on 0.1.6 and Shelf on 0.3.x, so every appearance 0.2.x and
/// 0.3.0 changed has to be reachable *and* has to stay off by default: raising
/// a pin for one fix must not redraw a window nobody asked about.
///
/// These are the defaults written down where a change to them fails a test
/// rather than a screenshot somebody happens to look at.
@MainActor
@Suite("An older pin keeps its old look")
struct SlateCompatibilityTests {
    @Test("a chip is accent-filled and shows its ✕, as it has since 0.1.0")
    func chipDefaults() {
        let chip = SlateChip("science fiction") {}
        #expect(chip.style == .accent)
        #expect(chip.removeButton == .always)
    }

    @Test("the token field's chips default the way a chip does")
    func tokenFieldDefaults() {
        let field = SlateTokenField(tokens: [], placeholder: "", onAdd: { _ in }, onRemove: { _ in })
        #expect(field.chipStyle == .accent)
        #expect(field.chipRemoveButton == .always)
    }

    @Test("a star rating writes the number beside itself, as it has since 0.1.0")
    func starDefaults() {
        #expect(SlateStarRating(rating: 3, onChange: { _ in }).label == .value)
    }

    @Test("the two fills are the two fills, and they are not each other")
    func chipFills() {
        #expect(SlateChipStyle.accent.fill == Slate.accent.opacity(0.22))
        #expect(SlateChipStyle.neutral.fill == Color.white.opacity(0.10))
        #expect(SlateChipStyle.accent.fill != SlateChipStyle.neutral.fill)
    }

    /// The ✕ stays in the layout and in the accessibility tree either way; only
    /// its opacity moves. A test of *visibility* would therefore be a test of
    /// the wrong thing.
    @Test("the ✕ is always drawn by default, and only under the pointer when asked")
    func removeButtonOpacity() {
        for hovered in [true, false] {
            for focused in [true, false] {
                #expect(
                    SlateChipRemoveButton.always.opacity(isHovered: hovered, isFocused: focused) == 1)
            }
        }
        #expect(SlateChipRemoveButton.onHover.opacity(isHovered: false, isFocused: false) == 0)
        #expect(SlateChipRemoveButton.onHover.opacity(isHovered: true, isFocused: false) == 1)
        #expect(SlateChipRemoveButton.onHover.opacity(isHovered: false, isFocused: true) == 1)
    }

    @Test("the number beside the stars is there by default and gone when asked")
    func starLabelText() {
        #expect(SlateStarRating.labelText(rating: 3, label: .value) == "3/5")
        #expect(SlateStarRating.labelText(rating: 3, label: .unratedOnly) == nil)
    }

    /// Zero is the one rating with no picture of its own: five hollow stars mean
    /// "not rated" only to somebody who has already learned that they do. Both
    /// readings keep the word, which is why `.unratedOnly` is named for what it
    /// keeps rather than for what it drops.
    @Test("an unrated rating says so in both readings")
    func unratedKeepsItsWord() {
        #expect(SlateStarRating.labelText(rating: 0, label: .value) == "Unrated")
        #expect(SlateStarRating.labelText(rating: 0, label: .unratedOnly) == "Unrated")
    }
}
