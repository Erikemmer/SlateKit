import SwiftUI

/// One block of an inspector: a quiet capitalised heading and whatever belongs
/// under it, left-aligned with the spacing the rest of the column uses.
public struct SlateInspectorSection<Content: View>: View {
    private let title: String
    private let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Slate.textSecondary)
            content
        }
    }
}

/// A symbol and a value, for the rows of facts an inspector lists. Meant to sit
/// inside a `Grid`, so the values of neighbouring rows line up.
public struct SlateFactRow: View {
    private let symbol: String
    private let value: String

    public init(symbol: String, value: String) {
        self.symbol = symbol
        self.value = value
    }

    public var body: some View {
        GridRow {
            Image(systemName: symbol).foregroundStyle(Slate.textSecondary).frame(width: 18)
            Text(value).foregroundStyle(Slate.textPrimary).textSelection(.enabled)
                .gridColumnAlignment(.leading)
        }
        .font(.callout)
    }
}

/// A name on the left and its value on the right, filling the width.
public struct SlateValueRow: View {
    private let name: String
    private let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(name).lineLimit(1).truncationMode(.middle)
            Spacer()
            Text(value).foregroundStyle(Slate.textSecondary)
        }
        .font(.callout)
    }
}

/// Five clickable stars and the value in words. Knows nothing but an `Int`, so
/// any app can rate anything with it.
public struct SlateStarRating: View {
    private let rating: Int
    private let onChange: (Int) -> Void

    /// - Parameter onChange: called with the star that was clicked. What a
    ///   click on the current rating means – clear it, or keep it – is the
    ///   app's decision, not this control's.
    public init(rating: Int, onChange: @escaping (Int) -> Void) {
        self.rating = rating
        self.onChange = onChange
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    onChange(star)
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(star <= rating ? Slate.accent : Slate.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("\(star) star\(star == 1 ? "" : "s") (\(star))")
            }
            Spacer()
            Text(rating == 0 ? "Unrated" : "\(rating)/5")
                .font(.caption).monospacedDigit().foregroundStyle(Slate.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rating"))
        .accessibilityValue(Text("\(rating) of 5"))
    }
}

/// A removable chip, for keywords and anything else that comes in small named
/// pieces.
public struct SlateChip: View {
    private let text: String
    private let onRemove: (() -> Void)?

    public init(_ text: String, onRemove: (() -> Void)? = nil) {
        self.text = text
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(text)
            if let onRemove {
                Button(action: onRemove) { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .help("Remove")
            }
        }
        .font(.caption)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Slate.accent.opacity(0.22), in: Capsule())
        .foregroundStyle(Slate.textPrimary)
    }
}

/// A chip that offers something rather than stating it – a suggestion to click.
/// Quieter than `SlateChip` on purpose: it is not part of the record yet.
public struct SlateSuggestionChip: View {
    private let text: String
    private let action: () -> Void

    public init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    public var body: some View {
        Button(text, action: action)
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.white.opacity(0.06), in: Capsule())
            .foregroundStyle(Slate.textSecondary)
    }
}

/// Lays chips out in rows, wrapping like text.
public struct SlateWrappingChips<Item: Hashable, Content: View>: View {
    private let items: [Item]
    private let content: (Item) -> Content

    public init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    public var body: some View {
        SlateFlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { content($0) }
        }
    }
}

/// Minimal flow layout for chips; wraps subviews to the available width.
public struct SlateFlowLayout: Layout {
    public var spacing: CGFloat

    public init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    )
        -> CGSize
    {
        arrange(proposal: proposal, subviews: subviews).size
    }

    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        for (subview, origin) in zip(subviews, arrange(proposal: proposal, subviews: subviews).origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(
        proposal: ProposedViewSize, subviews: Subviews
    ) -> (
        size: CGSize, origins: [CGPoint]
    ) {
        Self.arrange(
            sizes: subviews.map { $0.sizeThatFits(.unspecified) }, maxWidth: proposal.width ?? .infinity,
            spacing: spacing)
    }

    /// The arithmetic on its own, so wrapping can be tested without a window.
    nonisolated static func arrange(
        sizes: [CGSize], maxWidth: CGFloat, spacing: CGFloat
    )
        -> (size: CGSize, origins: [CGPoint])
    {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for size in sizes {
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return (CGSize(width: width, height: y + rowHeight), origins)
    }
}
