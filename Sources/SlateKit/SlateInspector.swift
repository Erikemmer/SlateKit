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

/// What a star rating writes beside its stars.
///
/// An option rather than a change, because `SlateStarRating` has drawn the
/// number since 0.1.0 and two apps bind this package by tag: a host still on an
/// older pin must not find its rating row redrawn the day it raises that pin
/// for something else. `.value` is what every version through 0.2.1 drew, so it
/// is the default; `.unratedOnly` is 0.3.0's quieter reading, asked for.
public enum SlateStarLabel: Sendable, Equatable {
    /// `3/5` beside the stars, and `Unrated` at zero. The look through 0.2.1.
    case value
    /// Nothing beside the stars, except `Unrated` at zero – the one rating with
    /// no picture of its own. Introduced in 0.3.0.
    case unratedOnly
}

/// Five clickable stars and the value in words. Knows nothing but an `Int`, so
/// any app can rate anything with it.
public struct SlateStarRating: View {
    private let rating: Int
    let label: SlateStarLabel
    private let onChange: (Int) -> Void
    @FocusState private var focusedStar: Int?

    /// - Parameters:
    ///   - label: what is written beside the stars. Defaults to the reading
    ///     this control has always had; see `SlateStarLabel`.
    ///   - onChange: called with the star that was clicked. What a click on the
    ///     current rating means – clear it, or keep it – is the app's decision,
    ///     not this control's.
    public init(
        rating: Int, label: SlateStarLabel = .value, onChange: @escaping (Int) -> Void
    ) {
        self.rating = rating
        self.label = label
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
                .focused($focusedStar, equals: star)
                // …and, having reached them, sees where they are. A plain
                // button draws no ring of its own (0.4.0).
                .slateFocusRing(focusedStar == star)
                .help(Self.starHelp(star))
            }
            Spacer()
            if let text = Self.labelText(rating: rating, label: label) {
                Text(text)
                    .font(.caption).monospacedDigit().foregroundStyle(Slate.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "Rating", bundle: .module)))
        .accessibilityValue(Text(String(localized: "\(rating) of 5", bundle: .module)))
        // `children: .ignore` hides the five buttons, which is right — five
        // stops all called "3 stars (3)" is not how a rating should read — but
        // until 0.4.0 it left the control **readable and not settable**: the
        // value was announced and there was nothing left in the tree to press.
        // An adjustable action is the platform's answer to that, and it is the
        // one VoiceOver already has keys for (⌃⌥→, then ↑ and ↓).
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(Self.adjusted(rating, .increment))
            case .decrement: onChange(Self.adjusted(rating, .decrement))
            @unknown default: break
            }
        }
    }

    /// One step up or down, stopping at the ends. Lifted out of the closure so
    /// a test can check that it neither goes past five nor below nought — the
    /// two cases a person holding ↑ finds within a second.
    static func adjusted(_ rating: Int, _ direction: AccessibilityAdjustmentDirection) -> Int {
        switch direction {
        case .increment: return min(5, rating + 1)
        case .decrement: return max(0, rating - 1)
        @unknown default: return rating
        }
    }

    /// What goes beside the stars, or `nil` for nothing at all.
    ///
    /// Pulled out of the body because it is the whole of what `SlateStarLabel`
    /// decides, and a decision a test can read is worth more than one buried in
    /// a `ViewBuilder` that no test can reach.
    ///
    /// `.unratedOnly` keeps the word at zero on purpose: five drawn stars say
    /// "three are filled" perfectly well, but five *hollow* stars mean "not
    /// rated" only to somebody who has already learned that they do.
    static func labelText(rating: Int, label: SlateStarLabel) -> String? {
        if rating == 0 { return String(localized: "Unrated", bundle: .module) }
        switch label {
        case .value: return String(localized: "\(rating)/5", bundle: .module)
        case .unratedOnly: return nil
        }
    }

    /// "1 star (1)" / "3 stars (3)" – the full word per count, since German's
    /// plural of "Stern" ("Sterne") is not the singular plus an appended "s".
    private static func starHelp(_ star: Int) -> String {
        star == 1
            ? String(localized: "1 star (1)", bundle: .module)
            : String(localized: "\(star) stars (\(star))", bundle: .module)
    }
}

/// How a chip is filled.
///
/// An option rather than a change. `SlateChip` has been drawn in the accent
/// since 0.1.0, and Selector draws its own tags with it; a host that raises its
/// pin for an unrelated fix must not find its tag row recoloured on the way.
/// `.accent` is therefore what the parameter defaults to, and `.neutral` is
/// 0.3.0's reading, asked for.
public enum SlateChipStyle: Sendable, Equatable {
    /// `Slate.accent.opacity(0.22)`. The fill through 0.2.1.
    case accent
    /// The same neutral white lift a field takes under the pointer, so a chip
    /// and a field read as the same material. The accent is this palette's one
    /// loud colour and it means *selected* – the active sidebar row, the chosen
    /// cell, a focused field's border. A tag is not a selection, and a column
    /// of eight of them in the selection colour makes a window look as though
    /// eight things were chosen. Introduced in 0.3.0.
    case neutral

    /// The capsule's fill. A function of the case rather than a stored colour,
    /// so the decision can be read by a test without a window.
    var fill: Color {
        switch self {
        case .accent: return Slate.accent.opacity(0.22)
        case .neutral: return Color.white.opacity(0.10)
        }
    }
}

/// When a chip's ✕ is visible.
public enum SlateChipRemoveButton: Sendable, Equatable {
    /// Drawn whenever the chip can be removed at all. The behaviour through
    /// 0.2.1, and the default.
    case always
    /// Faded in under the pointer, or when it takes keyboard focus. Faded and
    /// not *added*: `if isHovered` would take the button out of the layout, and
    /// a row of chips that each grow a few points as the pointer crosses them
    /// re-flows *under* the pointer, moving the ✕ away from the click that is
    /// coming. Opacity keeps the width fixed, keeps the button in the
    /// accessibility tree, and keeps it clickable throughout, which is what
    /// makes "hover then click" one movement instead of two.
    /// Introduced in 0.3.0.
    case onHover

    /// The button's opacity, given what the pointer and the keyboard are doing.
    func opacity(isHovered: Bool, isFocused: Bool) -> Double {
        switch self {
        case .always: return 1
        case .onHover: return isHovered || isFocused ? 1 : 0
        }
    }
}

/// A removable chip, for keywords and anything else that comes in small named
/// pieces.
public struct SlateChip: View {
    private let text: String
    let style: SlateChipStyle
    let removeButton: SlateChipRemoveButton
    private let onRemove: (() -> Void)?

    /// - Parameters:
    ///   - style: how the capsule is filled. Defaults to the fill this chip has
    ///     always had; see `SlateChipStyle`.
    ///   - removeButton: when the ✕ is visible. Defaults to the behaviour this
    ///     chip has always had; see `SlateChipRemoveButton`.
    public init(
        _ text: String,
        style: SlateChipStyle = .accent,
        removeButton: SlateChipRemoveButton = .always,
        onRemove: (() -> Void)? = nil
    ) {
        self.text = text
        self.style = style
        self.removeButton = removeButton
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
                    .slateFocusRing(isRemoveFocused, cornerRadius: 8)
                    .help(String(localized: "Remove", bundle: .module))
                    .accessibilityLabel(String(localized: "Remove \(text)", bundle: .module))
                    .opacity(removeButton.opacity(isHovered: isHovered, isFocused: isRemoveFocused))
            }
        }
        .font(.caption)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(style.fill, in: Capsule())
        .foregroundStyle(Slate.textPrimary)
        .onHover { isHovered = $0 }
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

    @FocusState private var isFocused: Bool

    public var body: some View {
        Button(text, action: action)
            .buttonStyle(.plain)
            .focusable()
            .focused($isFocused)
            .font(.caption)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.white.opacity(0.06), in: Capsule())
            .foregroundStyle(Slate.textSecondary)
            .slateCapsuleFocusRing(isFocused)
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
