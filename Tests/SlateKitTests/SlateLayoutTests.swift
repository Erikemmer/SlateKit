import Foundation
import Testing

@testable import SlateKit

/// The two places in this package where something is actually calculated.
/// Everything else is declarative SwiftUI, which a unit test cannot judge –
/// that is what the screenshot comparison in the host app is for.
@Suite("Chips wrap like text")
struct SlateFlowLayoutTests {
    private func sizes(_ widths: [CGFloat], height: CGFloat = 20) -> [CGSize] {
        widths.map { CGSize(width: $0, height: height) }
    }

    @Test("chips that fit stay on one row")
    func oneRow() {
        let result = SlateFlowLayout.arrange(sizes: sizes([40, 40, 40]), maxWidth: 200, spacing: 6)
        #expect(result.origins.map(\.y) == [0, 0, 0])
        #expect(result.origins.map(\.x) == [0, 46, 92])
        #expect(result.size.height == 20)
    }

    @Test("a chip that would overflow starts the next row")
    func wraps() {
        let result = SlateFlowLayout.arrange(sizes: sizes([80, 80, 80]), maxWidth: 170, spacing: 6)
        #expect(result.origins.map(\.y) == [0, 0, 26])
        #expect(result.origins.map(\.x) == [0, 86, 0])
        #expect(result.size.height == 46)
    }

    /// Something wider than the column must not vanish or loop for ever; it
    /// takes a row of its own and overflows, which is visible and fixable.
    @Test("a chip wider than the column gets its own row")
    func oversized() {
        let result = SlateFlowLayout.arrange(sizes: sizes([40, 300]), maxWidth: 100, spacing: 6)
        #expect(result.origins.map(\.y) == [0, 26])
    }

    @Test("rows are as tall as their tallest chip")
    func rowHeight() {
        let mixed = [CGSize(width: 40, height: 20), CGSize(width: 40, height: 34)]
        #expect(SlateFlowLayout.arrange(sizes: mixed, maxWidth: 200, spacing: 6).size.height == 34)
    }

    @Test("no chips, no size")
    func empty() {
        let result = SlateFlowLayout.arrange(sizes: [], maxWidth: 200, spacing: 6)
        #expect(result.origins.isEmpty)
        #expect(result.size == .zero)
    }
}

@Suite("The shortcut sheet splits into two even columns")
struct SlateShortcutSheetTests {
    /// Lines, not groups: one group of nine beside one of three looks broken.
    @Test("the split counts lines, headings included")
    func balancesByLines() {
        // 9+1, 4+1, 5+1, 3+1 = 24 lines; half is 12, reached during the second group.
        #expect(SlateShortcutSheet.splitPoint(groupSizes: [9, 4, 5, 3]) == 2)
    }

    @Test("equal groups split down the middle")
    func evenGroups() {
        #expect(SlateShortcutSheet.splitPoint(groupSizes: [4, 4, 4, 4]) == 2)
    }

    @Test("one group stays in the left column")
    func singleGroup() {
        #expect(SlateShortcutSheet.splitPoint(groupSizes: [6]) == 1)
    }

    @Test("no groups, no split")
    func noGroups() {
        #expect(SlateShortcutSheet.splitPoint(groupSizes: []) == 0)
    }
}

@Suite("Swatches")
struct SlateSwatchTests {
    @Test("five label colours, all distinct")
    func distinct() {
        #expect(SlateSwatch.allCases.count == 5)
        #expect(Set(SlateSwatch.allCases.map(\.rawValue)).count == 5)
    }

    /// The raw values travel into XMP and other tools' vocabularies, so they
    /// are not free to be renamed.
    @Test("the names are the ones other tools use")
    func names() {
        #expect(SlateSwatch.allCases.map(\.rawValue) == ["red", "yellow", "green", "blue", "purple"])
    }
}
