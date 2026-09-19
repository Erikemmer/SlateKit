import SwiftUI

/// The ring that says where the keyboard is.
///
/// Every control in this package that is drawn by hand — a star, a chip's ✕, a
/// sidebar row, a recent-library row — uses `.buttonStyle(.plain)` or is not a
/// `Button` at all, and neither draws a focus ring of its own. A keyboard-only
/// user could Tab through a whole inspector and never see where they had
/// landed; the sidebar row was the only place in the package that drew one, and
/// it drew it inline.
///
/// So the ring is one shape in one place, and the rule for it is one rule:
/// **anything focusable draws it while it is focused, and nothing at rest
/// changes.** A control that is not focused looks exactly as it did before this
/// existed, which is what keeps it safe for a host to raise its pin.
///
/// `strokeBorder` rather than `stroke`: a stroke straddles the shape's edge and
/// spills a point outside it, which in a tightly packed row overlaps the
/// neighbour above. The border is drawn inside.
public struct SlateFocusRing: ViewModifier {
    private let isFocused: Bool
    private let cornerRadius: CGFloat

    public init(isFocused: Bool, cornerRadius: CGFloat = Slate.cornerRadius) {
        self.isFocused = isFocused
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Slate.accent, lineWidth: 2)
            }
        }
    }
}

/// The same ring, drawn round a capsule — a chip, a suggestion.
public struct SlateCapsuleFocusRing: ViewModifier {
    private let isFocused: Bool

    public init(isFocused: Bool) {
        self.isFocused = isFocused
    }

    public func body(content: Content) -> some View {
        content.overlay { if isFocused { Capsule().strokeBorder(Slate.accent, lineWidth: 2) } }
    }
}

extension View {
    /// Draws the focus ring while `isFocused`, and nothing otherwise.
    public func slateFocusRing(
        _ isFocused: Bool, cornerRadius: CGFloat = Slate.cornerRadius
    )
        -> some View
    {
        modifier(SlateFocusRing(isFocused: isFocused, cornerRadius: cornerRadius))
    }

    /// The capsule-shaped version, for chips.
    public func slateCapsuleFocusRing(_ isFocused: Bool) -> some View {
        modifier(SlateCapsuleFocusRing(isFocused: isFocused))
    }
}
