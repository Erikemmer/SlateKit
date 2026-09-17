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
///
/// `label` names what the fact *is* ("Camera", "Focal length") for VoiceOver
/// only — the symbol is decorative on screen (the surrounding facts and the
/// value's own shape usually say enough), and its own SF Symbol name would
/// often say the wrong thing anyway: "circle.lefthalf.filled" reads as
/// "circle left half filled", not "lens".
public struct SlateFactRow: View {
    private let symbol: String
    private let label: String
    private let value: String

    public init(symbol: String, label: String, value: String) {
        self.symbol = symbol
        self.label = label
        self.value = value
    }

    public var body: some View {
        GridRow {
            Image(systemName: symbol).foregroundStyle(Slate.textSecondary).frame(width: 18)
                .accessibilityHidden(true)
            Text(value).foregroundStyle(Slate.textPrimary).textSelection(.enabled)
                .gridColumnAlignment(.leading)
        }
        .font(.callout)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
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
        // "report.jpg, 16 MB" rather than VoiceOver reading two unrelated
        // texts back to back with no indication they belong together.
        .accessibilityElement(children: .combine)
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
                // `.plain` opts a button out of the Tab order on macOS; without
                // this a keyboard-only user cannot reach these stars at all.
                .focusable()
                .help(Self.starHelp(star))
            }
            Spacer()
            // Only when there is nothing to see. Five drawn stars already say
            // "three of them are filled", and a "3/5" beside them is that same
            // fact written a second time – the copy that makes a rating row
            // read as a form field rather than as a picture. An *empty* rating
            // is the one case with no picture of its own: five hollow stars
            // mean "not rated" only to someone who has already learned that
            // they do, so that case keeps its word.
            if rating == 0 {
                Text("Unrated")
                    .font(.caption)
                    .foregroundStyle(Slate.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rating"))
        .accessibilityValue(Text("\(rating) of 5"))
    }

    /// "1 star (1)" / "3 stars (3)" – the full word per count, since German's
    /// plural of "Stern" ("Sterne") is not the singular plus an appended "s".
    private static func starHelp(_ star: Int) -> String {
        star == 1
            ? "1 star (1)"
            : "\(star) stars (\(star))"
    }
}

/// A removable chip, for keywords and anything else that comes in small named
/// pieces.
///
/// **Grey, not accent.** The accent is this palette's one loud colour and it
/// means *selected* – the active sidebar row, the chosen cell, the focused
/// field's border. A tag is not a selection; it is a value the book happens to
/// carry, and a column of eight of them in the selection colour makes the
/// window look as though eight things were chosen. The chip is therefore the
/// same neutral lift a field gets under the pointer.
public struct SlateChip: View {
    private let text: String
    private let onRemove: (() -> Void)?

    public init(_ text: String, onRemove: (() -> Void)? = nil) {
        self.text = text
        self.onRemove = onRemove
    }

    @State private var isHovered = false
    @FocusState private var isRemoveFocused: Bool

    public var body: some View {
        HStack(spacing: 4) {
            Text(text)
            if let onRemove {
                Button(action: onRemove) { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .focusable()
                    .focused($isRemoveFocused)
                    .help("Remove")
                    .accessibilityLabel("Remove \(text)")
                    // Faded, not removed. `if isHovered` would take the button
                    // out of the layout, and a row of chips that each grow a
                    // few points as the pointer crosses them re-flows under the
                    // pointer – the ✕ moves away from the click that is coming.
                    // Opacity keeps the width fixed, keeps the button in the
                    // accessibility tree, and keeps it clickable, which is what
                    // makes "hover then click" one movement instead of two.
                    .opacity(isHovered || isRemoveFocused ? 1 : 0)
            }
        }
        .font(.caption)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Self.background, in: Capsule())
        .foregroundStyle(Slate.textPrimary)
        .onHover { isHovered = $0 }
    }

    /// The same white lift a field takes under the pointer, so a chip and a
    /// field read as the same material.
    static let background = Color.white.opacity(0.10)
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
            .focusable()
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
