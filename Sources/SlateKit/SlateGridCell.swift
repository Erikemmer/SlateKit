import SwiftUI

/// A square tile with a caption under it: the shape of a thumbnail in a grid or
/// a strip, with the selection frame drawn on top of everything else.
///
/// The three badge corners are separate builders rather than one, because their
/// order matters: each is laid against the framed square, and the selection
/// stroke goes over all of them. Pass `EmptyView()` for the corners an app does
/// not use.
public struct SlateGridCell<
    Content: View, TopLeading: View, TopTrailing: View, BottomLeading: View
>: View {
    private let side: CGFloat
    private let title: String
    let label: String?
    private let isSelected: Bool
    private let content: Content
    private let topLeading: TopLeading
    private let topTrailing: TopTrailing
    private let bottomLeading: BottomLeading

    /// - Parameters:
    ///   - label: what the whole cell is *called*, for a reader who cannot see
    ///     it. The cell is one accessibility element since 0.4.0, so this is
    ///     the one chance to say what the badges mean — "Dune, Frank Herbert,
    ///     read, DRM" — and the badges themselves are hidden behind it. It
    ///     defaults to the caption, which is what the cell said before there
    ///     was anything better to say.
    public init(
        side: CGFloat,
        title: String,
        label: String? = nil,
        isSelected: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder topLeading: () -> TopLeading,
        @ViewBuilder topTrailing: () -> TopTrailing,
        @ViewBuilder bottomLeading: () -> BottomLeading
    ) {
        self.side = side
        self.title = title
        self.label = label
        self.isSelected = isSelected
        self.content = content()
        self.topLeading = topLeading()
        self.topTrailing = topTrailing()
        self.bottomLeading = bottomLeading()
    }

    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: Slate.cornerRadius).fill(Slate.contentBackground)
                content
            }
            .frame(width: side, height: side)
            .overlay(alignment: .topTrailing) { topTrailing.padding(4) }
            .overlay(alignment: .topLeading) { topLeading.padding(4) }
            .overlay(alignment: .bottomLeading) { bottomLeading.padding(4) }
            .overlay {
                RoundedRectangle(cornerRadius: Slate.cornerRadius)
                    .stroke(isSelected ? Slate.accent : .clear, lineWidth: 2)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(isSelected ? Slate.textPrimary : Slate.textSecondary)
                .lineLimit(1)
        }
        .frame(width: side)
        // **One element, not four.** Until 0.4.0 a cell arrived in the
        // accessibility tree as its picture, its caption and one static text
        // per badge, each a separate stop with no relation to the others and
        // no role. A grid of 5 000 books was 15 000 stops, read in layout
        // order — which put the picture's own SF Symbol name ("book.closed")
        // and the badges *before* the title. Ignoring the children and saying
        // the whole thing once puts the name first and the badges where the
        // host chose to put them in the sentence.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// What the cell is called when it cannot be seen. Lifted out of the body
    /// so a test can read it: a `ViewBuilder` is not somewhere a decision can
    /// be checked.
    var spokenLabel: String { label ?? title }
}

/// A small dark plate for badges that sit on top of a thumbnail, so they stay
/// readable whatever the picture underneath is doing.
public struct SlateBadgePlate<Content: View>: View {
    private let horizontalPadding: CGFloat
    private let content: Content

    public init(horizontalPadding: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }

    public var body: some View {
        content
            .font(.caption2.weight(.bold))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 1)
            .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 3))
    }
}
