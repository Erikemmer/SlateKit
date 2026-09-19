import SwiftUI
import Testing

@testable import SlateKit

/// What 0.4.0 added, stated where a change to it fails rather than waits for
/// somebody to turn VoiceOver on.
///
/// Most of accessibility is a tree, and a tree needs a window — that is what
/// `Scripts/ax-dump.swift` in the host apps is for. What *can* be checked here
/// is the handful of decisions the views make before they draw: what a cell is
/// called when nobody said, and where a rating stops when it is stepped.
@MainActor
@Suite("What a reader who cannot see the window is told")
struct SlateAccessibilityTests {
    @Test("a cell nobody labelled is called by its caption")
    func gridCellFallsBackToItsTitle() {
        let cell = SlateGridCell(
            side: 120, title: "Dune", isSelected: false, content: { EmptyView() },
            topLeading: { EmptyView() }, topTrailing: { EmptyView() }, bottomLeading: { EmptyView() })
        #expect(cell.label == nil)
        #expect(cell.spokenLabel == "Dune")
    }

    /// The badges are drawn over the picture and hidden from the tree, so the
    /// label is the only place their meaning can survive. A host that passes
    /// one gets exactly what it passed.
    @Test("a cell that was given a label says that, badges and all")
    func gridCellUsesTheLabelItWasGiven() {
        let cell = SlateGridCell(
            side: 120, title: "Dune", label: "Dune, Frank Herbert, read, DRM", isSelected: true,
            content: { EmptyView() }, topLeading: { EmptyView() }, topTrailing: { EmptyView() },
            bottomLeading: { EmptyView() })
        #expect(cell.spokenLabel == "Dune, Frank Herbert, read, DRM")
    }

    @Test("stepping the rating stops at five and at nought")
    func ratingStepsWithinItsRange() {
        #expect(SlateStarRating.adjusted(3, .increment) == 4)
        #expect(SlateStarRating.adjusted(3, .decrement) == 2)
        #expect(SlateStarRating.adjusted(5, .increment) == 5)
        #expect(SlateStarRating.adjusted(0, .decrement) == 0)
    }
}
