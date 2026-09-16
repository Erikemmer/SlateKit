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
    private let isSelected: Bool
    private let content: Content
    private let topLeading: TopLeading
    private let topTrailing: TopTrailing
    private let bottomLeading: BottomLeading

    public init(
        side: CGFloat,
        title: String,
        isSelected: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder topLeading: () -> TopLeading,
        @ViewBuilder topTrailing: () -> TopTrailing,
        @ViewBuilder bottomLeading: () -> BottomLeading
    ) {
        self.side = side
        self.title = title
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
    }
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
